-- COVID-19 Data Exploration: Dataset from https://ourworldindata.org/covid-deaths
-- skills used: joins, common table expressions (CTE), temp tables, agg functions, convert data types, create views



Select *
From PortfolioProject..CovidDeaths
where continent is not null		-- explanation for this line is provided in the upcoming section
order by 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--order by 3,4


-- select data that we are going to use

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1,2


-- Total cases vs Total deaths: shows the likelihood of dying in india 

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage 
from PortfolioProject..CovidDeaths
where location like 'India'
and continent is not null
order by 1,2


-- Total cases vs Population: shows percentage of population with covid

select location, date, total_cases, population, (total_cases/population)*100 as PopulationInfectedPercent 
from PortfolioProject..CovidDeaths
--where location like 'India'
order by 1,2


-- Countries with highest infection rate compared to population

select location, MAX(total_cases) as HighestInfectionCount, population, MAX((total_cases/population))*100 as PopulationInfectedPercent 
from PortfolioProject..CovidDeaths
--where location like 'India'
group by location, population
order by PopulationInfectedPercent desc


-- Countries with highest death rates per population (convert the data type of total_cases since it is a varchar)
-- remove the continent grouping error (check the error by exploring the table)

select location, MAX(CONVERT(int,total_deaths)) as DeathCount
from PortfolioProject..CovidDeaths
--where location like 'India'
where continent is not null
group by location
order by DeathCount desc


-- Breaking things down by continent

select location, MAX(CONVERT(int,total_deaths)) as DeathCount
from PortfolioProject..CovidDeaths
--where location like 'India'
where continent is null
group by location
order by DeathCount desc


-- global level evaluation

-- total new cases
select SUM(new_cases) as TotalNewCases, SUM(cast(new_deaths as int)) as TotalNewDeaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as GlobalDeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

-- grouped by date

select date, SUM(new_cases) as TotalNewCases, SUM(cast(new_deaths as int)) as TotalNewDeaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as GlobalDeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1,2


-- joining covid_deaths and covid_vaccinations table to extract total population vs vaccinations
-- we can see that it took almost an year (30 Jan 2020 - 15 Jan 2021) for india to get their first vaccine

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int))
over (partition by dea.location order by dea.location, dea.date) as rolling_vacc_count
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- and dea.location = 'India'
order by 2,3



-- in the above section we can't use the alias name to calculate the percentage of maximum vac per population
-- so we create a Common Table Expression (CTE) so we can perform the required calculations

with POPvsVAC (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinationCount)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int))
over (partition by dea.location order by dea.location, dea.date) as rolling_vacc_count
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- and dea.location = 'India'
-- order by 2,3
)
select *, (RollingVaccinationCount/Population)*100 as VaccinationPercentage
from POPvsVAC


-- same thing but with temp table :)

DROP Table if exists PercPplVacc		-- jus so we can alter it any time
CREATE Table PercPplVacc
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingVaccinationCount numeric
)

Insert into PercPplVacc
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int))
over (partition by dea.location order by dea.location, dea.date) as rolling_vacc_count
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- and dea.location = 'India'
-- order by 2,3

Select *, (RollingVaccinationCount/Population)*100 as VaccinationPercentage
from PercPplVacc


-- creating a view so we can later use it in Tableau

Create View PercentagePeopleVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int))
over (partition by dea.location order by dea.location, dea.date) as rolling_vacc_count
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- and dea.location = 'India'
-- order by 2,3


select *
from PercentagePeopleVaccinated