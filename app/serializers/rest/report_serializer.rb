# frozen_string_literal: true

class REST::ReportSerializer < ActiveModel::Serializer
  attributes :id, :action_taken, :action_taken_at, :category, :comment,
             :forwarded, :created_at, :status_ids, :rule_ids

  has_one :target_account, serializer: REST::AccountSerializer

  has_many :statuses, serializer: REST::StatusSerializer
  has_many :rules, serializer: REST::RuleSerializer

  def id
    object.id.to_s
  end

  def statuses
    object.statuses.with_includes
  end
end
