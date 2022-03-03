# frozen_string_literal: true

class FamiliarFollowersPresenter
  class Result < ActiveModelSerializers::Model
    attributes :id, :accounts

    def initialize(id, accounts)
      @id       = id
      @accounts = accounts
    end
  end

  def initialize(account_ids, current_account_id)
    @account_ids        = account_ids.map { |a| a.is_a?(Account) ? a.id : a.to_i }
    @current_account_id = current_account_id
  end

  def accounts
    map = Follow.includes(account: :account_stat).where(target_account_id: @account_ids).where(account_id: Follow.where(account_id: @current_account_id).select(:target_account_id)).group_by(&:target_account_id)
    @account_ids.map { |account_id| Result.new(account_id, map[account_id].map(&:account)) }
  end
end
