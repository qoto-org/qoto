# frozen_string_literal: true

class ActivityPub::CollectionsController < ActivityPub::BaseController
  include SignatureVerification
  include AccountOwnedConcern

  before_action :require_signature!, if: :authorized_fetch_mode?
  before_action :set_size
  before_action :set_statuses
  before_action :set_featured_tags
  before_action :set_endorsed_accounts
  before_action :set_cache_headers

  def show
    expires_in 3.minutes, public: public_fetch_mode?
    render_with_cache json: collection_presenter, content_type: 'application/activity+json', serializer: ActivityPub::CollectionSerializer, adapter: ActivityPub::Adapter
  end

  private

  def set_statuses
    @statuses = scope_for_collection
    @statuses = cache_collection(@statuses, Status)
  end

  def set_featured_tags
    @featured_tags = @account.featured_tags
  end

  def set_endorsed_accounts
    @endorsed_accounts = @account.endorsed_accounts
  end

  def set_size
    case params[:id]
    when 'featured'
      @account.pinned_statuses.count + @account.featured_tags.count + @account.account_pins.count
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def scope_for_collection
    case params[:id]
    when 'featured'
      @account.statuses.permitted_for(@account, signed_request_account).tap do |scope|
        scope.merge!(@account.pinned_statuses)
      end
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def collection_presenter
    ActivityPub::CollectionPresenter.new(
      id: account_collection_url(@account, params[:id]),
      type: :ordered,
      size: @size,
      items: @statuses + @featured_tags + @endorsed_accounts
    )
  end
end
