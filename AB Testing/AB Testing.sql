--xlsx files are imported to MS SQL Server

--Counting the Users in Groups: Entered but not converted, entered and converted, and converted but not entered
SELECT
  COUNT(CASE WHEN e.user_id is not null
               AND c.user_id is null THEN 1
			   ELSE NULL END) as users_entered_but_not_converted,
  COUNT(CASE WHEN e.user_id is not null
               AND c.user_id is not null THEN 1
			   ELSE NULL END) as users_entered_and_converted,
  COUNT(CASE WHEN e.user_id is null
               AND c.user_id is not null THEN 1
			   ELSE NULL END) as users_converted_and_not_entered
FROM ab_test_entrants e
OUTER JOIN ab_test_conversions c ON e.user_id=c.user_id

--Days from AB Test Entry to Conversion
SELECT
  DATEDIFF(day, CONVERT(date, e.ab_test_entrant_date), CONVERT(date, c.conversion_date)) as days_from_entry_to_conversion,
  COUNT(*) as num_entrants
FROM dbo.ab_test_entrants e
LEFT JOIN dbo.ab_test_conversions c ON e.user_id = c.user_id
GROUP BY DATEDIFF(day, CONVERT(date, e.ab_test_entrant_date), CONVERT(date, c.conversion_date))

--AB Test Entrants and Conversions by Version
SELECT
  e.ab_test_version,
  COUNT(e.user_id) as ab_test_entrants,
  COUNT(c.user_id) as ab_test_conversions
FROM dbo.ab_test_entrants e
LEFT JOIN dbo.ab_test_conversions c ON e.user_id = c.user_id
GROUP BY e.ab_test_version

--Conversion Rate by Version
SELECT
  e.ab_test_version,
  CONVERT(float, COUNT(c.user_id)) / COUNT(e.user_id) as conversion_rate
FROM ab_test_entrants e
LEFT JOIN ab_test_conversions c ON e.user_id = c.user_id
GROUP BY e.ab_test_version

--Conversion Rate with Confidence Intervals by Version (Using the Adjusted Wald Method)
WITH conversion_rate_standard_error as
(SELECT
  ab_test_version,
  ab_test_entrants_number,
  ab_test_conversions_number,
  conversion_rate,
  sqrt(conversion_rate * (1 - conversion_rate) / ab_test_entrants_number) as standard_error
FROM
  (
  SELECT
    ab_test_version,
    ab_test_entrants_number,
    ab_test_conversions_number,
    CONVERT(float, (ab_test_conversions_number + 1.92) / (ab_test_entrants_number + 3.84)) as conversion_rate
  FROM
    (
    SELECT
      e.ab_test_version,
      COUNT(e.user_id) as ab_test_entrants_number,
      COUNT(c.user_id) as ab_test_conversions_number
    FROM ab_test_entrants e
    LEFT JOIN ab_test_conversions c ON e.user_id = c.user_id
    GROUP BY e.ab_test_version
    ) ab_test_conversions
  ) ab_test_conversion_rates
)
SELECT
  ab_test_version,
  ab_test_entrants_number,
  ab_test_conversions_number,
  conversion_rate - standard_error * 1.96 as conversion_rate_low,
  conversion_rate,
  conversion_rate + standard_error * 1.96 as conversion_rate_high
FROM conversion_rate_standard_error
