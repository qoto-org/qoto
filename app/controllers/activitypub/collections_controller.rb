# frozen_string_literal: true

class ActivityPub::CollectionsController < ActivityPub::BaseController
  include SignatureAuthentication
  include AccountOwnedConcern

  before_action :require_signature!, if: :authorized_fetch_mode?
  before_action :set_size
  before_action :set_statuses
  before_action :set_cache_headers

  def show
    expires_in 3.minutes, public: current_account.nil?
    render_with_cache json: collection_presenter, content_type: 'application/activity+json', serializer: ActivityPub::CollectionSerializer, adapter: ActivityPub::Adapter, skip_activities: true
  end

  private

  def set_statuses
    @statuses = scope_for_collection
    @statuses = cache_collection(@statuses, Status)
  end

  def set_size
    case params[:id]
    when 'featured'
      @size = @account.pinned_statuses.count
    else
      not_found
    end
  end

  def scope_for_collection
    case params[:id]
    when 'featured'
      return Status.none if !current_account.nil? && (@account.blocking?(current_account) || (!current_account.domain.nil? && @account.domain_blocking?(current_account.domain)))

      @account.pinned_statuses
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def collection_presenter
    ActivityPub::CollectionPresenter.new(
      id: account_collection_url(@account, params[:id]),
      type: :ordered,
      size: @size,
      items: @statuses
    )
  end
end
