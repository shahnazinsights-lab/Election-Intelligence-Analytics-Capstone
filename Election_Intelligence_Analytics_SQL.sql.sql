-- Election Intelligence Analytics: A Data Analytics Capstone

-- SQL Analysis

-- Select Database
create database company;
USE company;

/* Observation:
The company database was selected to perform SQL analysis on the imported election datasets.
*/

-- Step 1: Create the final constituency table from e1
CREATE TABLE constituency AS
SELECT DISTINCT
ac_number,
constituency,
district,
region,
reserved
FROM e1;

/* Observation:
A master constituency table was created from e1, containing one record per constituency.
*/

-- Step 2: Create the final election_results table by combining e2 and e3
CREATE TABLE election_results AS
SELECT
2021 AS election_year,
ac_number,
candidate,
party,
votes,
turnout,
reserved,
region FROM e2
UNION ALL
SELECT
2026 AS election_year,
ac_number,
candidate,
party,
votes,
turnout,
reserved,
region FROM e3;

/* Observation
The election_results table was created by combining the 2021 and 2026 election datasets into a single table.
An election_year column was added to distinguish records from each election year, enabling efficient
year-wise analysis and comparisons.
*/

-- Step:3 Data Validation

-- 3.1 Verify Total Records
SELECT COUNT(*) AS total_constituencies
FROM constituency;
SELECT COUNT(*) AS total_records
FROM election_results;

/* Observation:
The record count confirms that the data was successfully loaded into both tables
*/

-- 3.2 Preview the Data
SELECT * FROM constituency LIMIT 5;
SELECT * FROM election_results LIMIT 5;

/* Observation:
The first five records were reviewed to verify the structure and contents of the tables.
*/

-- 3.3 Count Unique Constituencies
SELECT COUNT(DISTINCT constituency) AS total_constituencies
FROM constituency;

/* Observation:
Calculated the total number of unique constituencies
*/

-- 3.4 Count Unique Districts
SELECT COUNT(DISTINCT district) AS total_districts
FROM constituency;

/* Observation:
Identified the number of districts represented in the dataset.
*/

-- 3.5 Count Unique Political Parties
SELECT COUNT(DISTINCT party) AS total_parties
FROM election_results;

/* Observation:
Calculated the total number of political parties that contested the elections.
*/

-- 3.6 Count Unique Candidates
SELECT COUNT(DISTINCT candidate) AS total_candidates
FROM election_results;

/* Observation:
Calculated the number of unique candidates.
*/

-- 3.7 Data Validation — Party Standardization Check
SELECT party, COUNT(*) AS party_count
FROM election_results
GROUP BY party
ORDER BY party;

/*Observation:
This validation check identifies all unique political parties and their record counts.
It helps detect inconsistent party names caused by spelling differences, duplicate naming formats, or data entry errors.
Standardized party names ensure accurate party-wise election analysis.
*/

-- 3.8 Data Validation — Turnout 
SELECT 
    COUNT(*) AS total_rows,
    COUNT(turnout) AS non_null_turnout,
    COUNT(*) - COUNT(turnout) AS null_turnout
FROM election_results
WHERE election_year = 2026;

/*Observation:
The 2026 election data contains 4,257 records. All 4,257 records contain a stored value in the `turnout` column,
 with no SQL NULL values.
*/

-- 3.9 Turnout Zero-Value Check
SELECT 
    COUNT(*) AS total_rows,
    COUNT(turnout) AS non_null_turnout,
    SUM(turnout IS NULL) AS null_values,
    SUM(turnout = 0) AS zero_values
FROM election_results
WHERE election_year = 2026;

/*Observation:
The validation shows that all 4,257 records have a turnout value of 0. Although there are no SQL NULL values,
 the turnout field does not contain meaningful percentage values for the 2026 records and requires further
 investigation before turnout-based analysis.
*/

-- 3.10 Turnout Value Preview
SELECT 
    election_year,
    turnout
FROM election_results
WHERE election_year = 2026
LIMIT 10;

/*Observation:
The preview confirms that the turnout values for the 2026 records are stored as 0. 
Therefore, turnout-based visualizations should not be interpreted until the source of these zero values 
is verified.
*/

-- Step:4 Business Analysis

-- 4.1 Party-wise Total Votes
SELECT party, SUM(votes) AS total_votes FROM election_results
GROUP BY party ORDER BY total_votes DESC;

/* Observation:
Shows the total votes secured by each political party.
*/

-- 4.2 Party-wise Seat Count
WITH winners AS
(SELECT *, ROW_NUMBER() OVER (PARTITION BY election_year, ac_number
ORDER BY votes DESC) AS rn
FROM election_results)
SELECT election_year, party, COUNT(*) AS seats_won
FROM winners
WHERE rn = 1
GROUP BY election_year, party
ORDER BY election_year, seats_won DESC;

/* Observation:
Displays the number of constituencies won by each political party in each election year
*/

-- 4.3 Election Year-wise Party Participation
SELECT election_year,
COUNT(DISTINCT party) AS total_parties
FROM election_results
GROUP BY election_year;

/* Observation:
Displays the number of political parties that participated in each election year.
*/

-- 4.4 Top 10 Candidates by Votes
SELECT candidate, party, election_year, votes
FROM election_results
ORDER BY votes DESC LIMIT 10;

/* Observation:
Identifies the candidates who received the highest number of votes
*/

-- 4.5 Region-wise Seat Count by Party
WITH Winners AS (
    SELECT
        election_year,
        ac_number,
        region,
        party,
        ROW_NUMBER() OVER (
            PARTITION BY election_year, ac_number
            ORDER BY votes DESC) AS rn
    FROM election_results)
SELECT
    election_year,
    region,
    party,
    COUNT(*) AS seats_won
FROM Winners
WHERE rn = 1
GROUP BY election_year, region, party
ORDER BY election_year, region, seats_won DESC;

/* Observation:
Shows the number of constituencies won by each political party
across different regions
*/

-- 4.6 Top Party in Each Region
WITH party_votes AS
(SELECT
        e.election_year,
        c.region,
        e.party,
        SUM(e.votes) AS total_votes,
        DENSE_RANK() OVER (
            PARTITION BY e.election_year, c.region
            ORDER BY SUM(e.votes) DESC) AS rank_no FROM election_results e
    JOIN constituency c
        ON e.ac_number = c.ac_number
    GROUP BY
        e.election_year,
        c.region,
        e.party)
SELECT
    election_year,
    region,
    party,
    total_votes
FROM party_votes
WHERE rank_no = 1
ORDER BY election_year, region;

/* Observation:
Determined the top-performing political party in each region based
on the highest total votes received.
*/

-- 4.7 District-wise Winning Party
WITH Winners AS (
    SELECT er.election_year,
        c.district,
        er.party,
        ROW_NUMBER() OVER (
            PARTITION BY er.election_year, er.ac_number
            ORDER BY er.votes DESC) AS rn
    FROM election_results er
    JOIN constituency c
        ON er.ac_number = c.ac_number)
SELECT
    election_year,
    district,
    party,
    COUNT(*) AS seats_won
FROM Winners
WHERE rn = 1
GROUP BY
    election_year,
    district,
    party
ORDER BY
    election_year,
    district,
    seats_won DESC;

/* Observation:
Identified the number of seats won by each political party in every district to evaluate district-level
electoral performance
*/

-- 4.8 Reserved Constituency Winner Analysis
WITH Winners AS (
    SELECT er.election_year,
        er.reserved,
        er.party,
        ROW_NUMBER() OVER (
            PARTITION BY er.election_year, er.ac_number
            ORDER BY er.votes DESC) AS rn
    FROM election_results er)
SELECT
    election_year,
    reserved,
    party,
    COUNT(*) AS seats_won
FROM Winners
WHERE rn = 1
GROUP BY
    election_year,
    reserved,
    party
ORDER BY
    election_year,
    reserved,
    seats_won DESC;

/* Observation:
Analyzed party-wise seat wins across General and Reserved constituencies to compare
electoral performance based on
constituency reservation categories.
*/

-- 4.9 Reserved Category Validation
SELECT DISTINCT reserved
FROM election_results;

/*Observation:
This validation identifies all available reservation categories in the election dataset.
It confirms whether reserved constituency classifications are correctly recorded.
Accurate reservation categories support reliable analysis of SC/ST and general constituency representation.
*/

-- 4.10 Average Voter Turnout by Region
SELECT
    e.election_year,
    c.region,
    ROUND(AVG(e.turnout), 2) AS average_turnout
FROM election_results e
JOIN constituency c
    ON e.ac_number = c.ac_number
GROUP BY
    e.election_year,
    c.region
ORDER BY
    e.election_year,
    average_turnout DESC;
/* Observation:
Shows regional differences in voter turnout.
*/
-- 4.11 Average Voter Turnout by Election Year
SELECT election_year, ROUND(AVG(turnout),2) AS average_turnout
FROM election_results
GROUP BY election_year;

/* Observation:
Compares the average voter turnout across election years.
*/

-- 4.12 Turnout Validation Check
SELECT *
FROM election_results
WHERE turnout < 0 OR turnout > 100;

/*Observation:
This check validates that voter turnout values are within the acceptable range of 0% to 100%.
Any returned records indicate incorrect or invalid turnout data that requires correction before analysis.
Ensuring valid turnout values improves the accuracy of voter participation insights.
*/

-- Step:5 SQL Analysis

-- 5.1 Largest Victory Margin
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY election_year, ac_number
            ORDER BY votes DESC) AS rn
    FROM election_results),
margins AS (
SELECT w.election_year,w.ac_number,w.candidate,w.party,w.votes -
        (SELECT votes FROM ranked r
		WHERE r.election_year = w.election_year
		AND r.ac_number = w.ac_number
		AND r.rn = 2) AS victory_margin
    FROM ranked w WHERE rn = 1)
SELECT
    election_year,ac_number,candidate,party,victory_margin
FROM margins
ORDER BY victory_margin DESC LIMIT 10;

/* Observation:
Lists the top 10 constituencies with the largest winning margins.
*/

-- 5.2. Closest Contests
WITH ranked AS
(SELECT *, ROW_NUMBER() OVER ( PARTITION BY election_year, ac_number
	ORDER BY votes DESC) AS rn FROM election_results),
margins AS
(SELECT w.election_year,w.ac_number,w.candidate,w.party,w.votes -
        (SELECT votes FROM ranked r
		WHERE r.election_year = w.election_year
		AND r.ac_number = w.ac_number
		AND r.rn = 2) AS victory_margin FROM ranked w
    WHERE rn = 1)
SELECT election_year,ac_number,candidate,party,victory_margin
FROM margins
ORDER BY victory_margin ASC LIMIT 10;

/* Observation:
Identifies the 10 closest electoral contests based on the smallest victory margins.
*/


/* SQL Conclusion
Observation:
The SQL analysis transformed raw election data into meaningful business insights by evaluating party performance,
candidate performance, voter turnout, regional trends, district-level outcomes, and constituency-level election results.
The generated insights provide a strong analytical foundation for further exploratory data analysis (EDA), visualization,
and business reporting using Python
*/