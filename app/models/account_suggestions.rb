# frozen_string_literal: true

class AccountSuggestions
  class Suggestion < ActiveModelSerializers::Model
    attributes :account, :source
  end

  class StaffPicks
    def self.get(account, limit)
      return [] unless Setting.bootstrap_timeline_accounts.present?

      usernames_and_domains = begin
        Setting.bootstrap_timeline_accounts.split(',').map do |str|
          username, domain = str.strip.gsub(/\A@/, '').split('@', 2)
          domain           = nil if TagManager.instance.local_domain?(domain)

          next if username.blank?

          [username, domain]
        end.compact
      end

      accounts = Account.searchable
                        .followable_by(account)
                        .not_excluded_by_account(account)
                        .not_domain_blocked_by_account(account)
                        .where.not(id: account.id)
                        .where(usernames_and_domains.map { |(username, domain)| Arel::Nodes::Grouping.new(Account.arel_table[:username].lower.eq(username.downcase).and(Account.arel_table[:domain].lower.eq(domain&.downcase))) }.reduce(:or))
                        .limit(limit)
                        .index_by { |target_account| [target_account.username, target_account.domain] }

      usernames_and_domains.map { |x| accounts[x] }.compact
    end
  end

  def self.get(account, limit)
    suggestions = StaffPicks.get(account, limit).map { |target_account| Suggestion.new(account: target_account, source: :staff) }
    suggestions.concat(PotentialFriendshipTracker.get(account, limit - suggestions.size, suggestions.map { |suggestion| suggestion.account.id }).map { |target_account| Suggestion.new(account: target_account, source: :past_interaction) }) if suggestions.size < limit
    suggestions.concat(FollowRecommendation.get(account, limit - suggestions.size, suggestions.map { |suggestion| suggestion.account.id }).map { |target_account| Suggestion.new(account: target_account, source: :global) }) if suggestions.size < limit
    suggestions
  end

  def self.remove(account, target_account_id)
    PotentialFriendshipTracker.remove(account.id, target_account_id)
  end
end
