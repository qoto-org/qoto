# frozen_string_literal: true

class Admin::Metrics::Dimension::EmailDomainsDimension < Admin::Metrics::Dimension::BaseDimension
  def key
    'email_domains'
  end

  protected

  def perform_query
    sql = <<-SQL.squish
      SELECT split_part(email, '@', 2) AS domain, count(*) AS value
      FROM users
      WHERE created_at BETWEEN $1 AND $2
      GROUP BY split_part(email, '@', 2)
      ORDER BY count(*) DESC
      LIMIT $3
    SQL

    rows = ActiveRecord::Base.connection.select_all(sql, nil, [[nil, @start_at], [nil, @end_at], [nil, @limit]])

    rows.map { |row| { key: row['domain'], human_key: row['domain'], value: row['value'].to_s } }
  end
end
