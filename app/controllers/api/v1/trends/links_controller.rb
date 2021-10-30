# frozen_string_literal: true

class Api::V1::Trends::LinksController < Api::BaseController
  before_action :set_links

  def index
    render json: @links, each_serializer: REST::PreviewCardSerializer
  end

  private

  def set_links
    @links = Trends.links.get(limit_param(10))
  end
end
