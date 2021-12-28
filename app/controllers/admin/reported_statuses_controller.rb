# frozen_string_literal: true

module Admin
  class ReportedStatusesController < BaseController
    before_action :set_report

    def create
      @status_batch_action = Admin::StatusBatchAction.new(admin_status_batch_action_params.merge(current_account: current_account, target_account: @report.target_account, type: action_from_button, report_id: @report.id))
      @status_batch_action.save!
    rescue ActionController::ParameterMissing
      flash[:alert] = I18n.t('admin.statuses.no_status_selected')
    ensure
      redirect_to admin_report_path(@report)
    end

    private

    def admin_status_batch_action_params
      params.require(:admin_status_batch_action).permit(status_ids: [])
    end

    def action_from_button
      if params[:delete]
        'delete'
      end
    end

    def set_report
      @report = Report.find(params[:report_id])
    end
  end
end
