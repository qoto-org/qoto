# frozen_string_literal: true

class Api::V1::Keys::QueriesController < Api::BaseController
  before_action -> { doorkeeper_authorize! :write, :'write:accounts' }
  before_action :require_user!
  before_action :set_accounts

  # TODO: Pack this into a service instead of relying on ActiveRecord
  # so that remote lookups can be supported in the future

  def create
    render json: @accounts, each_serializer: REST::DevicesSerializer
  end

  private

  def set_accounts
    @accounts = Account.local.where(id: account_ids).includes(:devices)
  end

  def account_ids
    Array(params[:id]).map(&:to_i)
  end
end
