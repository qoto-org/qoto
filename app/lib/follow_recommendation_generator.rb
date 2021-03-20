# frozen_string_literal

class FollowRecommendationGenerator
  TIME_TOLERANCE = 30.days.freeze

  def get(limit)
    (most_interactions(limit / 2 + limit % 2) + most_followers(limit / 2)).uniq.shuffle
  end

  private

  def most_interactions(limit)
    Account.find_by_sql([<<-SQL.squish, min_id: Mastodon::Snowflake.id_at(TIME_TOLERANCE.ago), limit: limit])
      SELECT accounts.*,
             sum(reblogs_count + favourites_count) AS total_interactions
      FROM status_stats
      INNER JOIN statuses ON statuses.id = status_stats.status_id
      INNER JOIN accounts ON accounts.id = statuses.account_id
      WHERE statuses.id > :min_id
        AND accounts.suspended_at IS NULL
        AND accounts.moved_to_account_id IS NULL
        AND accounts.silenced_at IS NULL
      GROUP BY accounts.id
      ORDER BY total_interactions DESC
      LIMIT :limit
    SQL
  end

  def most_followers(limit)
    Account.find_by_sql([<<-SQL.squish, min_time: TIME_TOLERANCE.ago, limit: limit])
      WITH endorsements AS (
        SELECT
          target_account_id,
          count(*) AS rank
        FROM account_pins
        GROUP BY target_account_id
      )
      SELECT
        accounts.*,
        trunc(((count(follows.id) / (1.0 + count(follows.id))) * ((coalesce(endorsements.rank, 0) + 1) / (coalesce(endorsements.rank, 0) + 2.0))), 2) AS rank
      FROM follows
      INNER JOIN accounts ON accounts.id = follows.target_account_id
      INNER JOIN users ON users.account_id = follows.target_account_id
      LEFT JOIN endorsements ON endorsements.target_account_id = follows.target_account_id
      WHERE users.current_sign_in_at >= :min_time
        AND accounts.suspended_at IS NULL
        AND accounts.moved_to_account_id IS NULL
        AND accounts.silenced_at IS NULL
      GROUP BY accounts.id, endorsements.rank
      ORDER BY rank DESC
      LIMIT :limit
    SQL
  end
end
