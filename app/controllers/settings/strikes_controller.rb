# frozen_string_literal: true

class Settings::StrikesController < Settings::BaseController
  skip_before_action :require_functional!

  before_action :set_strike

  def show
    @statuses = @strike.statuses.with_includes
    @appeal = @strike.build_appeal
  end

  private

  def set_strike
    @strike = current_account.strikes.find(params[:id])
  end
end
