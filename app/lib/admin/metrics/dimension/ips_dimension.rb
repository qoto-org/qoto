# frozen_string_literal: true

class Admin::Metrics::Dimension::IPsDimension < Admin::Metrics::Dimension::BaseDimension
  def key
    'ips'
  end

  protected

  def perform_query
    sql = <<-SQL.squish
      SELECT sign_up_ip, count(*) AS value
      FROM users
      WHERE created_at BETWEEN $1 AND $2
      GROUP BY sign_up_ip
      ORDER BY count(*) DESC
      LIMIT $3
    SQL

    rows = ActiveRecord::Base.connection.select_all(sql, nil, [[nil, @start_at], [nil, @end_at], [nil, @limit]])

    rows.map { |row| { key: row['sign_up_ip'], human_key: row['sign_up_ip'], value: row['value'].to_s } }
  end
end
