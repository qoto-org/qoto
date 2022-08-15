# frozen_string_literal: true

module Admin
  class AbuseMetricsController < BaseController
    def index
      authorize :dashboard, :index?
    end
  end
end
