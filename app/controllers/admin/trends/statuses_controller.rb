# frozen_string_literal: true

class Admin::Trends::StatusesController < Admin::BaseController
  def index
    authorize :status, :index?

    @locales  = Trends::TrendingStatus.pluck('distinct language')
    @ranks    = filtered_ranks
    @statuses = filtered_statuses.page(params[:page])
    @form     = Trends::StatusBatch.new
  end

  def batch
    @form = Trends::StatusBatch.new(trends_status_batch_params.merge(current_account: current_account, action: action_from_button))
    @form.save
  rescue ActionController::ParameterMissing
    flash[:alert] = I18n.t('admin.accounts.no_account_selected')
  ensure
    redirect_to admin_trends_statuses_path(filter_params)
  end

  private

  def filtered_statuses
    Trends::StatusFilter.new(filter_params.with_defaults(trending: 'all')).results.includes(:account, :media_attachments, :active_mentions)
  end

  def filter_params
    params.slice(:page, *Trends::StatusFilter::KEYS).permit(:page, *Trends::StatusFilter::KEYS)
  end

  def trends_status_batch_params
    params.require(:trends_status_batch).permit(:action, status_ids: [])
  end

  def filtered_ranks
    scope = Trends::TrendingStatus.allowed
    scope = scope.where(language: params[:locale]) if params[:locale].present?
    scope.pluck(Arel.sql('id, ROW_NUMBER() OVER(ORDER BY score DESC) AS rank')).to_h
  end

  def action_from_button
    if params[:approve]
      'approve'
    elsif params[:approve_accounts]
      'approve_accounts'
    elsif params[:reject]
      'reject'
    elsif params[:reject_accounts]
      'reject_accounts'
    end
  end
end
