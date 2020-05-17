# frozen_string_literal: true

class Api::V1::Accounts::DeliveriesController < Api::BaseController
  before_action -> { doorkeeper_authorize! :write, :'write:accounts' }
  before_action :require_user!

  def create
    devices.each do |device_params|
      device = Device.find_by(account_id: device_params[:account_id], device_id: device_params[:device_id])

      next if device.nil?

      device.encrypted_messages.create!(from_account: current_account, type: device_params[:type], body: device_params[:body])
    end

    render_empty
  end

  private

  def resource_params
    params.permit(device: [:account_id, :device_id, :type, :body])
  end

  def devices
    Array(resource_params[:device])
  end
end
