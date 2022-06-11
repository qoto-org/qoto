# frozen_string_literal: true

class AccountModerationNotePolicy < ApplicationPolicy
  def create?
    can?(:manage_reports)
  end

  def destroy?
    owner?
  end

  private

  def owner?
    record.account_id == current_account&.id
  end
end
