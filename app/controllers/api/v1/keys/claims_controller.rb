# frozen_string_literal: true

class Api::V1::Keys::ClaimsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :write, :'write:accounts' }
  before_action :require_user!

  def create
    keys_map = {}

    device_ids.each do |fq_device_id|
      acct, device_id = fq_device_id.split(':')
      account         = Account.find_remote(*acct.split('@')) # FIXME: Handle local domain

      next if account.nil?

      device = account.devices.find_by(device_id: device_id)

      next if device.nil?

      one_time_key = device.one_time_keys.order(Arel.sql('random()')).first

      next if one_time_key.nil?

      keys_map[fq_device_id] = one_time_key.key

      one_time_key.destroy!
    end

    render json: keys_map
  end

  private

  def resource_params
    params.permit(:device_id)
  end

  def device_ids
    Array(resource_params[:device_id])
  end
end
