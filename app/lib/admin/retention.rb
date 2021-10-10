# frozen_string_literal: true

class Admin::Retention
  class Cohort < ActiveModelSerializers::Model
    attributes :cohort_date, :data
  end

  class CohortData < ActiveModelSerializers::Model
    attributes :date, :retention_percent, :value
  end

  def initialize(start_at, end_at)
    @start_at = start_at
    @end_at   = end_at
  end

  def cohorts
    sql = <<-SQL.squish
      SELECT axis.*, (
        WITH new_users AS (
          SELECT users.id
          FROM users
          WHERE date_trunc('day', users.created_at)::date = axis.cohort_period
        ),
        retained_users AS (
          SELECT users.id
          FROM users
          INNER JOIN new_users on new_users.id = users.id
          WHERE date_trunc('day', users.current_sign_in_at) >= axis.retention_period
        )
        SELECT ARRAY[count(*), 100 * (count(*) + 1)::float / (SELECT count(*) + 1 FROM new_users)] AS retention_percent
        FROM retained_users
      )
      FROM (
        WITH cohort_periods AS (
          SELECT generate_series($1::timestamp, $2::timestamp, '1 day') AS cohort_period
        ),
        retention_periods AS (
          SELECT cohort_period AS retention_period FROM cohort_periods
        )
        SELECT *
        FROM cohort_periods, retention_periods
        WHERE retention_period >= cohort_period
      ) as axis
    SQL

    rows = ActiveRecord::Base.connection.select_all(sql, nil, [[nil, @start_at], [nil, @end_at]])

    cohorts = []

    rows.each do |row|
      last_cohort = cohorts.last

      if last_cohort.nil? || last_cohort.cohort_date != row['cohort_period']
        last_cohort = Cohort.new(cohort_date: row['cohort_period'], data: [])
        cohorts << last_cohort
      end

      value, percent = row['retention_percent'].delete('{}').split(',')

      last_cohort.data << CohortData.new(date: row['retention_period'], retention_percent: percent.to_f, value: value.to_i)
    end

    cohorts
  end
end
