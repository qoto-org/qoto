# frozen_string_literal: true

class Api::V1::Trends::StatusesController < Api::BaseController
  before_action :set_statuses

  def index
    render json: @statuses, each_serializer: REST::StatusSerializer
  end

  private

  def set_statuses
    @statuses = begin
      if Setting.trends
        cache_collection(Trends.statuses.get(true, limit_param(DEFAULT_STATUSES_LIMIT)), Status)
      else
        []
      end
    end
  end
end
