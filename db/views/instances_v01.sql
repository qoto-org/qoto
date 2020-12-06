SELECT domain
FROM accounts
WHERE domain IS NOT NULL
GROUP BY domain
UNION
SELECT domain
FROM domain_blocks
UNION
SELECT domain
FROM domain_allows
