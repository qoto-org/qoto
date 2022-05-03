SELECT t0.* FROM (
  SELECT DISTINCT ON (account_id)
    *
  FROM trends_trending_statuses
  ORDER BY account_id, score DESC
) AS t0
ORDER BY t0.score DESC
