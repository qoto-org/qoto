# frozen_string_literal: true

class Api::V1::MarkersController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:statuses' }, only: [:index]
  before_action -> { doorkeeper_authorize! :write, :'write:statuses' }, except: [:index]

  before_action :require_user!

  def index
    @markers = current_user.markers.where(timeline: Array(params[:timeline]))
    render json: @markers, each_serializer: REST::MarkerSerializer
  end

  def create
    @marker = current_user.markers.find_or_initialize_by(timeline: resource_params[:timeline])
    @marker.update!(resource_params)

    render json: @marker, serializer: REST::MarkerSerializer
  rescue ActiveRecord::StaleObjectError
    render json: { error: 'Conflict during update, please try again' }, status: 409
  end

  private

  def resource_params
    params.permit(:timeline, :last_read_id)
  end
end
