# frozen_string_literal: true

class REST::Admin::CohortSerializer < ActiveModel::Serializer
  attributes :cohort_date

  class CohortDataSerializer < ActiveModel::Serializer
    attributes :date, :retention_percent, :value

    def date
      object.date.iso8601
    end
  end

  has_many :data, serializer: CohortDataSerializer

  def cohort_date
    object.cohort_date.iso8601
  end
end
