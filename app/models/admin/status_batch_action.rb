# frozen_string_literal: true

class Admin::StatusBatchAction
  include ActiveModel::Model
  include AccountableConcern
  include Authorization

  attr_accessor :current_account, :target_account,
                :type, :status_ids, :report_id

  def save!
    process_action!
  end

  private

  def statuses
    Status.with_discarded.where(id: status_ids)
  end

  def process_action!
    case type
    when 'delete'
      handle_delete!
    end
  end

  def handle_delete!
    return if status_ids.empty?

    Status.transaction do
      statuses.each { |status| authorize(status, :destroy?) }
      statuses.discard_all
      statuses.each { |status| log_action(:destroy, status) }

      if with_report?
        report.resolve!(current_account)
        log_action(:resolve, report)
      end
    end

    UserMailer.statuses_deleted(target_account.user, status_ids).deliver_later!
  end

  def report
    @report ||= Report.find(report_id) if report_id.present?
  end

  def with_report?
    !report.nil?
  end
end
