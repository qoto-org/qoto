# frozen_string_literal: true

class REST::Admin::MeasureSerializer < ActiveModel::Serializer
  attributes :key, :total, :previous_total, :data
end
