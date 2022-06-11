# frozen_string_literal: true

class ReportNotePolicy < ApplicationPolicy
  def create?
    role.can?(:manage_reports)
  end

  def destroy?
    owner?
  end

  private

  def owner?
    record.account_id == current_account&.id
  end
end
