--First look at the data
SELECT *
FROM athlete_events
LIMIT 10;

--There are NA values instead of null values at csv file. When importing table to DB Browsers, columns value became 'NA
UPDATE athlete_events
SET Age= NULL
WHERE Age ="NA";

UPDATE athlete_events
SET Height = NULL
WHERE Height ="NA";

UPDATE athlete_events
SET Weight = NULL
WHERE Weight ="NA";

UPDATE athlete_events
SET Medal= NULL
WHERE Medal="NA";

--Age Distribution for Checking Outliers
SELECT Age, COUNT(DISTINCT ID) as Age_Counted
FROM athlete_events
WHERE Age IS NOT NULL
GROUP BY Age
ORDER BY Age;

--Sports which has athletes aged over 60
SELECT Sport, Count(DISTINCT ID) as Number_of_athletes
FROM athlete_events
WHERE Age > 60
GROUP BY Sport
ORDER BY Number_of_athletes DESC;

SELECT *
FROM athlete_events
WHERE Age > 60 AND Sport = "Fencing";

--Height Distribution for Checking Outliers
SELECT Height, COUNT(ID) as Height_Counted
FROM athlete_events
WHERE Height IS NOT NULL
GROUP BY Height
ORDER BY Height;

--Controlling Maximum and Minimum Height Values
SELECT *
FROM athlete_events
WHERE Height = 127 OR Height = 226;

--Weight Distribution for Checking Outliers
SELECT Weight, COUNT(DISTINCT ID) as Weight_Counted
FROM athlete_events
WHERE Weight IS NOT NULL
GROUP BY Weight
ORDER BY Weight;

SELECT *
FROM athlete_events
WHERE Weight = 25 OR Weight = 214;

--Checking other columns for null values
SELECT *
FROM athlete_events
WHERE
  Name IS NULL or
  Sex IS NULL or
  Team IS NULL or
  NOC IS NULL or
  Games IS NULL or
  Year IS NULL or
  Season IS NULL or
  City IS NULL or
  Sport IS NULL or
  Event IS NULL;

--Remove Duplicates
WITH RowNumCTE AS(
SELECT *,
  ROW_NUMBER() OVER (
  PARTITION BY Name, Age, Sex, Team, NOC, Games, Year, Season, Sport, Event
  ORDER BY ID) as row_num
FROM athlete_events
)
SELECT *
FROM RowNumCTE
WHERE row_num = 1
ORDER BY ID;

--Save the querry as CSV named athlete_events_clean at DB Browser
ALTER TABLE athlete_events_clean DROP COLUMN row_num;


--Checking the tables after join
SELECT *
FROM athlete_events_clean A
LEFT JOIN noc_regions N ON A.NOC=N.NOC
WHERE Region IS NULL;

--Singapore's NOC code is "SIN" in noc_regions. Singapore changed their NOC code as "SGP" instead of "SIN" in 2016
UPDATE noc_regions
SET NOC = "SGP"
WHERE region = "Singapore";

/*Number of athletes for regions*/
SELECT COUNT(DISTINCT A.ID) as Number_of_athletes, N.region
FROM athlete_events_clean A
LEFT JOIN noc_regions N
ON A.NOC=N.NOC
GROUP BY N.region
ORDER BY Number_of_athletes DESC;

--Number of athletes for Summer years
SELECT COUNT(DISTINCT ID) as Number_of_athletes, Year
FROM athlete_events_clean
WHERE Season = "Summer"
GROUP BY Year
ORDER BY Year;

--Number of athletes for genders
SELECT COUNT(DISTINCT ID) as Number_of_athletes, Sex
FROM athlete_events_clean
GROUP BY Sex;

--Number of events, minimum number of  participated athletes, maximum number of participated athletes for Summer and Winter seasons
SELECT Season, COUNT(Year) as Number_of_events, MIN(Number_of_athletes) AS Min_athletes, MAX(Number_of_athletes) AS Max_athletes, AVG(Number_of_athletes) AS avg_athletes
FROM
(
  SELECT COUNT(DISTINCT ID) as Number_of_athletes, Year, Season
  FROM athlete_events_clean
  GROUP BY Year, Season
) count_ath
GROUP BY Season;

--Median number of participated athletes for Summer and Winter seasons
SELECT Season, Year as Median_year,
Number_of_athletes as Median_athlete
FROM
  (
  SELECT COUNT(DISTINCT ID) as Number_of_athletes, Year, Season
  FROM athlete_events_clean
  WHERE Season = "Summer"
  GROUP BY Year
  ) count_ath
ORDER BY Median_athlete
LIMIT 1
OFFSET (SELECT COUNT(*)
        FROM
          (
          SELECT COUNT(DISTINCT ID) as Number_of_athletes, Year, Season
          FROM athlete_events_clean
          WHERE Season = "Summer"
          GROUP BY Year
          ) offset_temp1
        ) / 2;

SELECT Season, Year as Median_year,
Number_of_athletes as Median_athlete
FROM
  (
  SELECT COUNT(DISTINCT ID) as Number_of_athletes, Year, Season
  FROM athlete_events_clean
  WHERE Season = "Winter"
  GROUP BY Year
  ) count_ath
ORDER BY Median_athlete
LIMIT 1
OFFSET (SELECT COUNT(*)
        FROM
          (
          SELECT COUNT(DISTINCT ID) as Number_of_athletes, Year, Season
          FROM athlete_events_clean
          WHERE Season = "Winter"
          GROUP BY Year
          ) offset_temp1
        ) / 2;

--Mode number of participated athletes for Summer and Winter seasons
SELECT Season, Number_of_athletes, COUNT(*)
FROM
(
  SELECT COUNT(DISTINCT ID) as Number_of_athletes, Year, Season
  FROM athlete_events_clean
  GROUP BY Year, Season
) count_ath
GROUP BY Season, Number_of_athletes
ORDER BY COUNT(*) DESC;

--The percentile range values of number of participated athletes for Summer and Winter seasons
SELECT DISTINCT LAST_VALUE(Number_of_Athletes) OVER (Partition by Season, prcnt) as Last_val, Season,
(CASE WHEN Prcnt=1 THEN '%25' WHEN Prcnt=2 THEN '%50' WHEN Prcnt=3 THEN '%75' ELSE '%100' END) as Pct
FROM(
  SELECT Season, Year, Number_of_athletes, ntile(4) OVER(Partition by Season Order by Number_of_Athletes) as Prcnt
  FROM (
    SELECT
    COUNT(DISTINCT ID) as Number_of_athletes,
    Year,
    Season
    FROM athlete_events_clean
    GROUP BY Year, Season) percent_temp
  ) ntile_temp;

--Minimum age, maximum age and mean age of athletes for Summer and Winter seasons
SELECT Season, COUNT(*) as Number_of_athletes, MIN(Age) AS Min_age, MAX(age) AS Max_age, AVG(age) AS Avg_age
FROM
  (
  SELECT DISTINCT ID, Name, Sex, Age, Year, Season
  FROM athlete_events_clean
) athlete_temp
GROUP BY Season;

--Median age for seasons
SELECT Season, Age as Median_age
FROM
  (
    SELECT DISTINCT ID, Name, Sex, Age, Year, Season
    FROM athlete_events_clean
    WHERE Age IS NOT NULL AND Season = "Summer"
  ) age_temp
ORDER BY Age
LIMIT 1
OFFSET (SELECT COUNT(*)
        FROM
          (
          SELECT DISTINCT ID, Name, Sex, Age, Year, Season
          FROM athlete_events_clean
          WHERE Age IS NOT NULL AND Season = "Summer"
          ) offset_temp1
        ) / 2;

SELECT Season, Age as Median_age
FROM
  (
  SELECT DISTINCT ID, Name, Sex, Age, Year, Season
  FROM athlete_events_clean
  WHERE Age IS NOT NULL AND Season = "Winter"
  ) age_temp
ORDER BY Age
LIMIT 1
OFFSET (SELECT COUNT(*)
        FROM
          (
          SELECT DISTINCT ID, Name, Sex, Age, Year, Season
          FROM athlete_events_clean
          WHERE Age IS NOT NULL AND Season = "Winter"
          ) offset_temp1
        ) / 2;

--Mode age for seasons
SELECT Season, Mode_age
FROM
  (
  SELECT Season, Age as Mode_age,
  ROW_NUMBER() OVER (PARTITION BY Season ORDER BY Number_of_Athletes DESC) as Row_num
  FROM
    (
    SELECT COUNT(DISTINCT ID) as Number_of_athletes, Age, Year, Season
    FROM athlete_events_clean
    WHERE AGE IS NOT NULL
    GROUP BY Season, Year, Age
    ) age
  ) age_row
WHERE (Season="Summer" and row_num = 1 ) or (Season="Winter" and row_num= 1);

--The percentile range ages of athletes for Summer and Winter seasons
SELECT DISTINCT LAST_VALUE(Age) OVER (Partition by Season, Prcnt) as Last_val, Season,
(CASE WHEN Prcnt=1 THEN '%25' WHEN Prcnt=2 THEN '%50' WHEN Prcnt=3 THEN '%75' ELSE '%100' END) as Pct
FROM
  (
  SELECT Season, Year, Age, ntile(4) OVER(Partition by Season Order by Age) as Prcnt
  FROM
    (
    SELECT
    DISTINCT ID,
    Name,
    Sex,
    Age,
    Year,
    Season
    FROM athlete_events_clean
    WHERE AGE IS NOT NULL
    ) as percent_temp
  ) as ntile_temp;

--The numbers of participated athletes and winner athletes for noc_regions
SELECT
  sum(temp_table.number_of_athletes) as Num_athletes_region,
  COALESCE(sum(temp_win_table.number_of_winner_athletes),0) as Num_winner_athletes_region,
  temp_table.region
FROM
  (
  SELECT COUNT(DISTINCT A.ID) as Number_of_athletes, A.Season, A.Year, N.region
  FROM athlete_events_clean A
  LEFT JOIN noc_regions N
  ON A.NOC=N.NOC
  GROUP BY A.Season, A.Year, N.region
  ) as temp_table
LEFT JOIN
  (
  SELECT COUNT(DISTINCT A.ID) as Number_of_winner_athletes, A.Season, A.Year, N.region
  FROM athlete_events_clean A
  LEFT JOIN noc_regions N
  ON A.NOC=N.NOC
  WHERE Medal IS NOT NULL
  GROUP BY A.Season, A.Year, N.region
  ) as temp_win_table ON temp_table.region=temp_win_table.region AND temp_table.year=temp_win_table.year AND temp_table.season=temp_win_table.season
GROUP BY temp_table.region;
