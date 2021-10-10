# frozen_string_literal: true

module Admin
  class RetentionController < BaseController
    before_action :set_cohorts

    def index
      render json: @cohorts, each_serializer: REST::Admin::CohortSerializer
    end

    private

    def set_cohorts
      @cohorts = Admin::Retention.new(30.days.ago.utc, Time.now.utc).cohorts
    end
  end
end
