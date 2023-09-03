/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


SELECT *
FROM Portfolio..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 3,4

SELECT *
FROM Portfolio..CovidVaccinations
ORDER BY 3,4

-- Select Data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
WHERE continent is NOT NULL
FROM Portfolio..CovidDeaths
ORDER BY 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths,(total_deaths/total_cases)*100 AS DeathPercentage
FROM Portfolio..CovidDeaths
WHERE location like 'India'
and continent is NOT NULL
ORDER BY 1,2


-- Looking at the Total Cases vs Population
--Shows what percentage of population infected with Covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM Portfolio..CovidDeaths
WHERE location like 'India' 
and continent is NOT NULL
ORDER BY 1,2

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM Portfolio..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM Portfolio..CovidDeaths
--WHERE location like 'India'
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


--Showing Countries with Highest Death Count Per Population

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM Portfolio..CovidDeaths
--WHERE location like 'India'
WHERE continent is NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM Portfolio..CovidDeaths
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM Portfolio..CovidDeaths
WHERE continent is NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Global Numbers

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM Portfolio..CovidDeaths
WHERE continent is NOT NULL
GROUP BY date
ORDER BY 1,2


SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM Portfolio..CovidDeaths
WHERE continent is NOT NULL
--GROUP BY date
ORDER BY 1,2


--Looking at Total Population vs Vaccinations


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date 
WHERE dea.continent is NOT NULL 
ORDER BY 2,3

-- Shows Percentage of Population that has recieved at least one Covid Vaccine


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date)
as RollingPeopleVaccinated
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date 
WHERE dea.continent is NOT NULL 
ORDER BY 2,3

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date)
as RollingPeopleVaccinated
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date 
WHERE dea.continent is NOT NULL 

)

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)


INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date)
as RollingPeopleVaccinated
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date 
--WHERE dea.continent is NOT NULL 

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE View PercentPopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date)
as RollingPeopleVaccinated
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccinations vac
	ON dea.location = vac.location and dea.date = vac.date 
WHERE dea.continent is NOT NULL

SELECT *
FROM PercentPopulationVaccinated