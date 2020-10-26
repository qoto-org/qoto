# frozen_string_literal: true
# == Schema Information
#
# Table name: statuses
#
#  id                     :bigint(8)        not null, primary key
#  uri                    :string
#  text                   :text             default(""), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  in_reply_to_id         :bigint(8)
#  reblog_of_id           :bigint(8)
#  url                    :string
#  sensitive              :boolean          default(FALSE), not null
#  visibility             :integer          default("public"), not null
#  spoiler_text           :text             default(""), not null
#  reply                  :boolean          default(FALSE), not null
#  language               :string
#  conversation_id        :bigint(8)
#  local                  :boolean
#  account_id             :bigint(8)        not null
#  application_id         :bigint(8)
#  in_reply_to_account_id :bigint(8)
#  poll_id                :bigint(8)
#  quote_id               :bigint(8)
#  deleted_at             :datetime
#  expires_at             :datetime
#  expires_action         :integer          default("delete"), not null
#  local_only             :boolean
#  content_type           :string
#

class Status < ApplicationRecord
  before_destroy :unlink_from_conversations

  include Discard::Model
  include Paginable
  include Cacheable
  include StatusThreadingConcern
  include RateLimitable
  include Expireable
  include Redisable

  rate_limit by: :account, family: :statuses

  self.discard_column = :deleted_at

  # If `override_timestamps` is set at creation time, Snowflake ID creation
  # will be based on current time instead of `created_at`
  attr_accessor :override_timestamps

  attr_accessor :circle

  update_index('statuses#status', :proper)

  enum visibility: [:public, :unlisted, :private, :direct, :limited], _suffix: :visibility
  enum expires_action: [:delete, :hint], _prefix: :expires

  belongs_to :application, class_name: 'Doorkeeper::Application', optional: true

  belongs_to :account, inverse_of: :statuses
  belongs_to :in_reply_to_account, foreign_key: 'in_reply_to_account_id', class_name: 'Account', optional: true
  belongs_to :conversation, optional: true, inverse_of: :statuses
  belongs_to :preloadable_poll, class_name: 'Poll', foreign_key: 'poll_id', optional: true

  has_one :owned_conversation, class_name: 'Conversation', foreign_key: 'parent_status_id', inverse_of: :parent_status

  belongs_to :thread, foreign_key: 'in_reply_to_id', class_name: 'Status', inverse_of: :replies, optional: true
  belongs_to :reblog, foreign_key: 'reblog_of_id', class_name: 'Status', inverse_of: :reblogs, optional: true
  belongs_to :quote, foreign_key: 'quote_id', class_name: 'Status', inverse_of: :quoted, optional: true

  has_many :favourites, inverse_of: :status, dependent: :destroy
  has_many :bookmarks, inverse_of: :status, dependent: :destroy
  has_many :reblogs, foreign_key: 'reblog_of_id', class_name: 'Status', inverse_of: :reblog, dependent: :destroy
  has_many :replies, foreign_key: 'in_reply_to_id', class_name: 'Status', inverse_of: :thread
  has_many :mentions, dependent: :destroy, inverse_of: :status
  has_many :active_mentions, -> { active }, class_name: 'Mention', inverse_of: :status
  has_many :media_attachments, dependent: :nullify
  has_many :quoted, foreign_key: 'quote_id', class_name: 'Status', inverse_of: :quote, dependent: :nullify
  has_many :capability_tokens, class_name: 'StatusCapabilityToken', inverse_of: :status, dependent: :destroy

  has_and_belongs_to_many :tags
  has_and_belongs_to_many :preview_cards

  has_one :notification, as: :activity, dependent: :destroy
  has_one :status_stat, inverse_of: :status
  has_one :poll, inverse_of: :status, dependent: :destroy

  validates :uri, uniqueness: true, presence: true, unless: :local?
  validates :text, presence: true, unless: -> { with_media? || reblog? }
  validates_with StatusLengthValidator
  validates_with DisallowedHashtagsValidator
  validates :reblog, uniqueness: { scope: :account }, if: :reblog?
  validates :visibility, exclusion: { in: %w(direct limited) }, if: :reblog?
  validates :quote_visibility, inclusion: { in: %w(public unlisted) }, if: :quote?
  validates_with ExpiresValidator, on: :create, if: :local?
  validates :content_type, inclusion: { in: %w(text/plain text/markdown) }, allow_nil: true

  accepts_nested_attributes_for :poll

  default_scope { recent.kept.not_expired }

  scope :recent, -> { reorder(id: :desc) }
  scope :remote, -> { where(local: false).where.not(uri: nil) }
  scope :local,  -> { where(local: true).or(where(uri: nil)) }

  scope :not_expired, -> { where(statuses: {expires_at: nil} ).or(where('statuses.expires_at >= ?', Time.now.utc)) }
  scope :include_expired, ->(account = nil) {
    if account.nil?
      unscoped.recent.kept
    else
      unscoped.recent.kept.where(<<-SQL, account_id: account.id, current_utc: Time.now.utc)
        (
          statuses.expires_at IS NULL
        ) OR
        NOT (
          statuses.account_id != :account_id
          AND NOT EXISTS (
            SELECT *
            FROM bookmarks b
            WHERE b.status_id = statuses.id
            AND b.account_id = :account_id
          )
          AND NOT EXISTS (
            SELECT *
            FROM favourites f
            WHERE f.status_id = statuses.id
            AND f.account_id = :account_id
          )
          AND statuses.expires_at IS NOT NULL
          AND statuses.expires_at < :current_utc
        )
        SQL
    end
  }

  scope :with_accounts, ->(ids) { where(id: ids).includes(:account) }
  scope :without_replies, -> { where('statuses.reply = FALSE OR statuses.in_reply_to_account_id = statuses.account_id') }
  scope :without_reblogs, -> { where('statuses.reblog_of_id IS NULL') }
  scope :without_local_only, -> { where(local_only: [false, nil]) }
  scope :with_public_visibility, -> { where(visibility: :public) }
  scope :tagged_with, ->(tag_ids) { joins(:statuses_tags).where(statuses_tags: { tag_id: tag_ids }) }
  scope :in_chosen_languages, ->(account) { where(language: nil).or where(language: account.chosen_languages) }
  scope :mentioned_with, ->(account) { joins(:mentions).where(mentions: { account_id: account }) }
  scope :excluding_silenced_accounts, -> { left_outer_joins(:account).where(accounts: { silenced_at: nil }) }
  scope :including_silenced_accounts, -> { left_outer_joins(:account).where.not(accounts: { silenced_at: nil }) }
  scope :not_excluded_by_account, ->(account) { where.not(account_id: account.excluded_from_timeline_account_ids) }
  scope :not_domain_blocked_by_account, ->(account) { account.excluded_from_timeline_domains.blank? ? left_outer_joins(:account) : left_outer_joins(:account).where('accounts.domain IS NULL OR accounts.domain NOT IN (?)', account.excluded_from_timeline_domains) }
  scope :tagged_with_all, ->(tag_ids) {
    Array(tag_ids).reduce(self) do |result, id|
      result.joins("INNER JOIN statuses_tags t#{id} ON t#{id}.status_id = statuses.id AND t#{id}.tag_id = #{id}")
    end
  }
  scope :tagged_with_none, ->(tag_ids) {
    Array(tag_ids).reduce(self) do |result, id|
      result.joins("LEFT OUTER JOIN statuses_tags t#{id} ON t#{id}.status_id = statuses.id AND t#{id}.tag_id = #{id}")
            .where("t#{id}.tag_id IS NULL")
    end
  }

  cache_associated :application,
                   :media_attachments,
                   :conversation,
                   :status_stat,
                   :tags,
                   :preview_cards,
                   :preloadable_poll,
                   account: :account_stat,
                   active_mentions: { account: :account_stat },
                   reblog: [
                     :application,
                     :tags,
                     :preview_cards,
                     :media_attachments,
                     :conversation,
                     :status_stat,
                     :preloadable_poll,
                     account: :account_stat,
                     active_mentions: { account: :account_stat },
                   ],
                   thread: { account: :account_stat }

  delegate :domain, to: :account, prefix: true

  REAL_TIME_WINDOW = 6.hours

  def searchable_by(preloaded = nil)
    ids = []

    ids << account_id if local?

    if preloaded.nil?
      ids += mentions.where(account: Account.local, silent: false).pluck(:account_id)
      ids += favourites.where(account: Account.local).pluck(:account_id)
      ids += reblogs.where(account: Account.local).pluck(:account_id)
      ids += bookmarks.where(account: Account.local).pluck(:account_id)
    else
      ids += preloaded.mentions[id] || []
      ids += preloaded.favourites[id] || []
      ids += preloaded.reblogs[id] || []
      ids += preloaded.bookmarks[id] || []
    end

    ids.uniq
  end

  def reply?
    !in_reply_to_id.nil? || attributes['reply']
  end

  def local?
    attributes['local'] || uri.nil?
  end

  def local_only?
    local_only
  end

  def reblog?
    !reblog_of_id.nil?
  end

  def quote?
    !quote_id.nil? && quote
  end

  def quote_visibility
    quote&.visibility
  end

  def mentioning?(source_account_id)
    source_account_id = source_account_id.id if source_account_id.is_a?(Account)

    mentions.where(account_id: source_account_id).exists?
  end

  def within_realtime_window?
    created_at >= REAL_TIME_WINDOW.ago
  end

  def verb
    if destroyed?
      :delete
    else
      reblog? ? :share : :post
    end
  end

  def object_type
    reply? ? :comment : :note
  end

  def proper
    reblog? ? reblog : self
  end

  def content
    proper.text
  end

  def target
    reblog
  end

  def preview_card
    preview_cards.first
  end

  def hidden?
    !distributable?
  end

  def distributable?
    public_visibility? || unlisted_visibility?
  end

  def sign?
    distributable? || limited_visibility?
  end

  def with_media?
    media_attachments.any?
  end

  def non_sensitive_with_media?
    !sensitive? && with_media?
  end

  def reported?
    @reported ||= Report.where(target_account: account).unresolved.where('? = ANY(status_ids)', id).exists?
  end

  def emojis
    return @emojis if defined?(@emojis)

    fields  = [spoiler_text, text]
    fields += preloadable_poll.options unless preloadable_poll.nil?

    @emojis = CustomEmoji.from_text(fields.join(' '), account.domain) + (quote? ? CustomEmoji.from_text([quote.spoiler_text, quote.text].join(' '), quote.account.domain) : [])
  end

  def index_text
    @index_text ||= [spoiler_text, Formatter.instance.plaintext(self)].concat(media_attachments.map(&:description)).concat(preloadable_poll ? preloadable_poll.options : []).concat(quote? ? ["QT: [#{quote.url || ActivityPub::TagManager.instance.url_for(quote)}]"] : []).filter(&:present?).join("\n\n")
  end

  def mark_for_mass_destruction!
    @marked_for_mass_destruction = true
  end

  def marked_for_mass_destruction?
    @marked_for_mass_destruction
  end

  def replies_count
    status_stat&.replies_count || 0
  end

  def reblogs_count
    status_stat&.reblogs_count || 0
  end

  def favourites_count
    status_stat&.favourites_count || 0
  end

  def increment_count!(key)
    update_status_stat!(key => public_send(key) + 1)
  end

  def decrement_count!(key)
    update_status_stat!(key => [public_send(key) - 1, 0].max)
  end

  after_create_commit  :increment_counter_caches
  after_destroy_commit :decrement_counter_caches

  after_create_commit :store_uri, if: :local?
  after_create_commit :update_statistics, if: :local?

  around_create Mastodon::Snowflake::Callbacks

  before_create :set_locality

  before_validation :prepare_contents, on: :create, if: :local?
  before_validation :set_reblog, on: :create
  before_validation :set_visibility, on: :create
  before_validation :set_conversation, on: :create
  before_validation :set_local, on: :create

  after_create :set_poll_id
  after_create :set_circle

  class << self
    def selectable_visibilities
      visibilities.keys - %w(direct limited)
    end

    def selectable_content_types
      %w(text/plain text/markdown)
    end

    def as_public_timeline(account = nil, local_only = false)
      query = timeline_scope(local_only).without_replies

      apply_timeline_filters(query, account, [:local, true].include?(local_only))
    end

    def favourites_map(status_ids, account_id)
      Favourite.select('status_id').where(status_id: status_ids).where(account_id: account_id).each_with_object({}) { |f, h| h[f.status_id] = true }
    end

    def bookmarks_map(status_ids, account_id)
      Bookmark.select('status_id').where(status_id: status_ids).where(account_id: account_id).map { |f| [f.status_id, true] }.to_h
    end

    def reblogs_map(status_ids, account_id)
      unscoped.select('reblog_of_id').where(reblog_of_id: status_ids).where(account_id: account_id).each_with_object({}) { |s, h| h[s.reblog_of_id] = true }
    end

    def mutes_map(conversation_ids, account_id)
      ConversationMute.select('conversation_id').where(conversation_id: conversation_ids).where(account_id: account_id).each_with_object({}) { |m, h| h[m.conversation_id] = true }
    end

    def pins_map(status_ids, account_id)
      StatusPin.select('status_id').where(status_id: status_ids).where(account_id: account_id).each_with_object({}) { |p, h| h[p.status_id] = true }
    end

    def reload_stale_associations!(cached_items)
      account_ids = []

      cached_items.each do |item|
        account_ids << item.account_id
        account_ids << item.reblog.account_id if item.reblog?
      end

      account_ids.uniq!

      return if account_ids.empty?

      accounts = Account.where(id: account_ids).includes(:account_stat).each_with_object({}) { |a, h| h[a.id] = a }

      cached_items.each do |item|
        item.account = accounts[item.account_id]
        item.reblog.account = accounts[item.reblog.account_id] if item.reblog?
      end
    end

    def permitted_for(target_account, account)
      visibility = [:public, :unlisted]

      if account.nil?
        where(visibility: visibility).without_local_only
      elsif target_account.blocking?(account) || (account.domain.present? && target_account.domain_blocking?(account.domain)) # get rid of blocked peeps
        none
      elsif account.id == target_account.id # author can see own stuff
        all
      else
        # followers can see followers-only stuff, but also things they are mentioned in.
        # non-followers can see everything that isn't private/direct, but can see stuff they are mentioned in.
        visibility.push(:private) if account.following?(target_account)

        scope = left_outer_joins(:reblog)

        scope.where(visibility: visibility)
             .or(scope.where(id: account.mentions.select(:status_id)))
             .merge(scope.where(reblog_of_id: nil).or(scope.where.not(reblogs_statuses: { account_id: account.excluded_from_timeline_account_ids })))
      end
    end

    def from_text(text)
      return [] if text.blank?

      text.scan(FetchLinkCardService::URL_PATTERN).map(&:first).uniq.map do |url|
        status = begin
          if TagManager.instance.local_url?(url)
            ActivityPub::TagManager.instance.uri_to_resource(url, Status)
          else
            EntityCache.instance.status(url)
          end
        end
        status&.distributable? ? status : nil
      end.compact
    end

    private

    def timeline_scope(scope = false)
      starting_scope = case scope
                       when :local, true
                         Status.local
                       when :remote
                         Status.remote
                       else
                         Status
                       end

      starting_scope
        .with_public_visibility
        .without_reblogs
    end

    def apply_timeline_filters(query, account, local_only)
      if account.nil?
        filter_timeline_default(query)
      else
        filter_timeline_for_account(query, account, local_only)
      end
    end

    def filter_timeline_for_account(query, account, local_only)
      query = query.not_excluded_by_account(account)
      query = query.not_domain_blocked_by_account(account) unless local_only
      query = query.in_chosen_languages(account) if account.chosen_languages.present?
      query.merge(account_silencing_filter(account))
    end

    def filter_timeline_default(query)
      query.without_local_only.excluding_silenced_accounts
    end

    def account_silencing_filter(account)
      if account.silenced?
        including_myself = left_outer_joins(:account).where(account_id: account.id).references(:accounts)
        excluding_silenced_accounts.or(including_myself)
      else
        excluding_silenced_accounts
      end
    end
  end

  def status_stat
    super || build_status_stat
  end

  def update_status_stat!(attrs)
    return if marked_for_destruction? || destroyed?

    status_stat.update(attrs)
  end

  def store_uri
    update_column(:uri, ActivityPub::TagManager.instance.uri_for(self)) if uri.nil?
  end

  def prepare_contents
    text&.strip!
    spoiler_text&.strip!
  end

  def set_reblog
    self.reblog = reblog.reblog if reblog? && reblog.reblog?
  end

  def set_poll_id
    update_column(:poll_id, poll.id) unless poll.nil?
  end

  def set_visibility
    self.visibility = reblog.visibility if reblog? && visibility.nil?
    self.visibility = (account.locked? ? :private : :public) if visibility.nil?
    self.sensitive  = false if sensitive.nil?
  end

  def set_conversation
    self.thread = thread.reblog if thread&.reblog?

    self.reply = !(in_reply_to_id.nil? && thread.nil?) unless reply

    if reply? && !thread.nil?
      self.in_reply_to_account_id = carried_over_reply_to_account_id
    end

    if conversation_id.nil?
      if reply? && !thread.nil? && circle.nil?
        self.conversation_id = thread.conversation_id
      else
        build_owned_conversation
      end
    end
  end

  def set_circle
    redis.setex(circle_id_key, 3.days.seconds, circle.id) if circle.present?
  end

  def circle_id_key
    "statuses/#{id}/circle_id"
  end

  def carried_over_reply_to_account_id
    if thread.account_id == account_id && thread.reply?
      thread.in_reply_to_account_id
    else
      thread.account_id
    end
  end

  def set_local
    self.local = account.local?
  end

  def set_locality
    self.local_only = reblog.local_only if reblog?
  end

  def update_statistics
    return unless distributable?

    ActivityTracker.increment('activity:statuses:local')
  end

  def increment_counter_caches
    return if direct_visibility?

    account&.increment_count!(:statuses_count)
    reblog&.increment_count!(:reblogs_count) if reblog?
    thread&.increment_count!(:replies_count) if in_reply_to_id.present? && distributable?
  end

  def decrement_counter_caches
    return if direct_visibility? || marked_for_mass_destruction?

    account&.decrement_count!(:statuses_count)
    reblog&.decrement_count!(:reblogs_count) if reblog?
    thread&.decrement_count!(:replies_count) if in_reply_to_id.present? && distributable?
  end

  def unlink_from_conversations
    return unless direct_visibility?

    mentioned_accounts = mentions.includes(:account).map(&:account)
    inbox_owners       = mentioned_accounts.select(&:local?) + (account.local? ? [account] : [])

    inbox_owners.each do |inbox_owner|
      AccountConversation.remove_status(inbox_owner, self)
    end
  end
end
