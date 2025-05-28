-- Data Explorations Covid 19 in ASEAN and World
-- Deaths Table
select *
from PortfolioProject..CovidDeaths
order by 3,4;

-- Total Cases vs Total Deaths
-- Showing what percentage of death caused by covid in indonesia
select location, date, total_cases, total_deaths, 
	round((NULLIF(CONVERT(int, total_deaths), 0)/total_cases)*100, 4) as death_percentage
from PortfolioProject..CovidDeaths
where location = 'indonesia'
order by 1,2;

-- Total Cases vs Population
-- Showing what percentage of population got covid
select location, date, total_cases, population, (total_cases/population)*100 as case_percentage
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2;

-- Showing country with the highest infections rate compared to population
select location, population, max(total_cases) as case_count, max((total_cases/population))*100 as case_percentage
from PortfolioProject..CovidDeaths
where continent is not null
group by location, population
order by case_percentage desc;

-- Showing country with the highest death count
select location, max(cast(total_deaths as int)) as death_count
from PortfolioProject..CovidDeaths
group by location
order by death_count desc;

-- Total case and death per day in ASEAN
select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
	round(sum(NULLIF(CONVERT(int, new_deaths), 0))/sum(new_cases)*100,2) as death_percentage
from PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1,2;

-- Vaccination Table
select *
from PortfolioProject..CovidVaccinations
order by 3,4;

-- Total GDP per capita by country in ASEAN
select a.location, 
	max(cast(b.gdp_per_capita as float)) as total_gdp
from PortfolioProject..CovidDeaths as a
join PortfolioProject..CovidVaccinations as b
	on a.iso_code = b.iso_code
	and a.date = b.date
where a.continent is not null
group by a.location
order by 2 desc

-- Population vs Vaccination per day in ASEAN
select a.location, a.date, a.population, b.new_vaccinations,
sum(cast(b.new_vaccinations as float)) over(partition by a.location order by a.location, a.date) as rolling_vaccination
from PortfolioProject..CovidDeaths as a
join PortfolioProject..CovidVaccinations as b
	on a.iso_code = b.iso_code
	and a.date = b.date
where a.continent is not null
order by 1,2

-- using CTE for percentage of vaccination per day in ASEAN
WITH vac_cte (location, date, population, new_vaccinations, rolling_vaccination)
as
(
select a.location, a.date, a.population, b.new_vaccinations,
sum(convert(float, b.new_vaccinations)) over(partition by a.location order by a.location, a.date) as rolling_vaccination
from PortfolioProject..CovidDeaths as a
join PortfolioProject..CovidVaccinations as b
	on a.iso_code = b.iso_code
	and a.date = b.date
where a.continent is not null
)
select *, round((rolling_vaccination/population)*100, 4) as percentage_vaccination
from vac_cte
order by 1,2

-- Total Vaccination in ASEAN by country
select a.location, a.population,
	max(cast(b.total_vaccinations as float)) as total_vaccine
from PortfolioProject..CovidDeaths as a
join PortfolioProject..CovidVaccinations as b
	on a.iso_code = b.iso_code
	and a.date = b.date
where a.continent is not null
group by a.location, a.population
order by 3 desc

-- Using CTE for Total Vaccination in ASEAN vs World
WITH total_vac_cte (continent, location, population, total_vaccine)
as
(
select a.continent, a.location, a.population,
	max(cast(b.total_vaccinations as float)) as total_vaccine
from PortfolioProject..CovidDeaths as a
join PortfolioProject..CovidVaccinations as b
	on a.iso_code = b.iso_code
	and a.date = b.date
group by a.continent, a.location, a.population
)
select continent, sum(total_vaccine) as total_vaccine2
from total_vac_cte
group by continent

-- TEMP Table
drop table #PopVac
create table #PopVac
(
location varchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccination numeric
)

insert into #PopVac
select a.location, a.date, a.population, b.new_vaccinations,
sum(convert(float, b.new_vaccinations)) over(partition by a.location order by a.location, a.date) as rolling_vaccination
from PortfolioProject..CovidDeaths as a
join PortfolioProject..CovidVaccinations as b
	on a.iso_code = b.iso_code
	and a.date = b.date
where a.continent is not null
order by 1,2

select *, round((rolling_vaccination/population)*100, 4) as percentage_vaccination
from #PopVac
order by 1,2

-- Create view for visualization
drop view PeopleVaccinationPercentage
create view PeopleVaccinationPercentage as
select a.location, a.date, a.population, b.new_vaccinations,
sum(convert(float, b.new_vaccinations)) over(partition by a.location order by a.location, a.date) as rolling_vaccination
from PortfolioProject..CovidDeaths as a
join PortfolioProject..CovidVaccinations as b
	on a.iso_code = b.iso_code
	and a.date = b.date
where a.continent is not null

select *
from PortfolioProject..PeopleVaccinationPercentage