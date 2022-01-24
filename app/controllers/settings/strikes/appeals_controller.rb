# frozen_string_literal: true

class Settings::Strikes::AppealsController < Settings::BaseController
  skip_before_action :require_functional!

  before_action :set_strike

  def create
  end

  private

  def set_strike
    @strike = current_account.strikes.find(params[:strike_id])
  end
end
