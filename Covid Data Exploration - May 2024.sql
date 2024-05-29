-- General Querying and Finding out the Percentage of People Vaccinated Over Time against Population 

-- Checking the death rate of the infected in Canada, datediff of 7 because cases and deaths were updated weekly
SELECT Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS infection_death_percentage
FROM covidproject.coviddeaths
WHERE Location = 'Canada' AND MOD(DATEDIFF(DATE, '2020-01-05'),7) = 0
ORDER BY 1,2
;

-- Rate of infection against population of Canada
SELECT Location, Date, Population, total_cases, (total_cases/population)*100 AS infection_percentage
FROM covidproject.coviddeaths
WHERE Location = 'Canada' AND MOD(DATEDIFF(DATE, '2020-01-05'),7) = 0
ORDER BY 1,2
;

-- Checking countries with the highest infection counts around the world
SELECT Location, Population, MAX(CAST(total_cases AS unsigned)) AS max_infection_count
FROM covidproject.coviddeaths
WHERE Continent != '' -- Empty string value in the dataset
GROUP BY Location, Population
ORDER BY max_infection_count DESC
;

-- Countries with the Highest Percentage of Infection Compared to Population
SELECT Location, Population, MAX(CAST(total_cases AS unsigned)) AS max_infection_count, MAX(CAST(total_cases AS UNSIGNED)/population)*100 AS percentage_population_infected
FROM covidproject.coviddeaths
WHERE Continent != ''
GROUP BY Location, Population
ORDER BY percentage_population_infected DESC
;

-- Countries with the Highest Death Count
SELECT Location, MAX(CAST(total_deaths AS UNSIGNED)) AS max_death_count
FROM covidproject.coviddeaths
WHERE Continent != ''
GROUP BY Location
ORDER BY max_death_count DESC
;

-- Countries with Highest Death Count Percentage
SELECT Location, Population, MAX(CAST(total_cases AS UNSIGNED)) AS max_infection_count, MAX(CAST(total_deaths AS UNSIGNED)) AS max_death_count, MAX(CAST(total_deaths AS UNSIGNED)/total_cases)*100 AS max_death_per_case_percent
FROM covidproject.coviddeaths
WHERE Continent != ''
GROUP BY Location, Population
ORDER BY max_death_per_case_percent DESC
;

-- Max Death Count for Continents
SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS max_death_count
FROM covidproject.coviddeaths
WHERE Continent = '' AND Location NOT LIKE '%income'
GROUP BY location
ORDER BY max_death_count DESC
;

-- Global Numbers for daily cases to deaths ratio, weekly updates
SELECT Date, SUM(new_cases) AS Daily_total_cases, SUM(new_deaths) AS Daily_total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS Daily_death_percentage
FROM covidproject.coviddeaths
WHERE Continent != '' AND MOD(DATEDIFF(DATE, '2020-01-05'),7) = 0
GROUP BY Date
ORDER BY 1,2
LIMIT 1, 226
;

-- World Value for Cases to Death Ratio
SELECT SUM(new_cases) AS Daily_total_cases, SUM(new_deaths) AS Daily_total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS Daily_death_percentage
FROM covidproject.coviddeaths
WHERE Continent != '' AND MOD(DATEDIFF(DATE, '2020-01-05'),7) = 0
-- GROUP BY Date
ORDER BY 1,2
;

-- From here, we start looking at Vaccinations
-- Total Population vs Vaccinations with a Rolling Count
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.date) AS Rolling_People_Vaccinated
FROM covidproject.coviddeaths dea
JOIN covidproject.covidvaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent != ''
ORDER BY 2,3
;

-- CTE to Calculate Population vs Vaccination
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.date) AS Rolling_People_Vaccinated
FROM covidproject.coviddeaths dea
JOIN covidproject.covidvaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent != ''
ORDER BY 2,3
)
SELECT *, (Rolling_People_Vaccinated/population)*100 AS Percent_Population_Vaccinated
FROM PopvsVac
;

-- Same but Temp Table Format
DROP TABLE IF EXISTS percentpopulationvaccinated;
CREATE TEMPORARY TABLE percentpopulationvaccinated
(
continent varchar(255),
Location varchar(255),
Date datetime,
Population BIGINT,
New_vaccinations BIGINT,
Rolling_People_Vaccinated BIGINT
)
;
INSERT INTO percentpopulationvaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, @new_vacc := IF(vac.new_vaccinations = '' OR vac.new_vaccinations IS NULL, 0, CAST(vac.new_vaccinations AS UNSIGNED)) AS New_vaccinations,
    SUM(@new_vacc) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
-- @new_vacc was defined to get around the Incorrect integer error because of empty strings in the data
FROM covidproject.coviddeaths dea
JOIN covidproject.covidvaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent != ''
-- WHERE New_Vaccinations != 0 -- Just to filter out
-- ORDER BY 2,3
;
SELECT *, (Rolling_People_Vaccinated/population)*100 AS Percent_Population_Vaccinated
FROM percentpopulationvaccinated
;

-- Creating Views to Store Data for Visualizations
CREATE VIEW percentpopulationvaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.date) AS Rolling_People_Vaccinated
FROM covidproject.coviddeaths dea
JOIN covidproject.covidvaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent != ''
-- ORDER BY 2,3
;

SELECT * 
FROM covidproject.percentpopulationvaccinated
;