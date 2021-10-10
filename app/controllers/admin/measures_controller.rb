# frozen_string_literal: true

module Admin
  class MeasuresController < BaseController
    before_action :set_measures

    def index
      render json: @measures, each_serializer: REST::Admin::MeasureSerializer
    end

    private

    def set_measures
      @measures = Admin::Measure.retrieve(params[:keys], params[:start_at], params[:end_at])
    end
  end
end
