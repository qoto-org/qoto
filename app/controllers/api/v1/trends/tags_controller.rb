# frozen_string_literal: true

class Api::V1::Trends::TagsController < Api::BaseController
  before_action :set_tags

  def index
    render json: @tags, each_serializer: REST::TagSerializer
  end

  private

  def set_tags
    @tags = Trends.tags.get(limit_param(10))
  end
end
