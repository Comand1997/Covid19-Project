select *
from [Portfolio Project]..coviddeaths
order by 3, 4

select *
from [Portfolio Project]..covidvaccinations
order by 3, 4

-- Let's select the data that we are going to use
select location, date, total_cases, new_cases, total_deaths, population
from [Portfolio Project]..coviddeaths
order by location, date


--There's some null values because there weren't cases nor deaths at the begining of the pandemic in most countries. Let's fix it.
select 
	location, 
	date, 
	isnull(total_cases,0) as total_cases, 
	isnull(total_deaths,0) as total_deaths
from [Portfolio Project]..coviddeaths
order by location, date

-- Now let's compare the number of cases vs number of deaths.
select 
	location, 
	date,
	population,
	ISNULL(total_cases, 0) as total_cases,
    ISNULL(total_deaths, 0) as total_deaths,
    ISNULL((TRY_CONVERT(float, total_deaths) / TRY_CONVERT(float, total_cases)) * 100, 0) AS death_rate
from [Portfolio Project]..coviddeaths
where location like '%spain%' -- look for specific locations, like Spain
order by location, date

-- total_cases vs population
select 
	location, 
	date,
	Population,
	ISNULL(total_cases, 0) as total_cases,
    ISNULL(total_deaths, 0) as total_deaths,
    ISNULL((TRY_CONVERT(float, total_deaths) / TRY_CONVERT(float, total_cases)) * 100, 0) AS death_rate,
	ISNULL((TRY_CONVERT(float, total_cases) / TRY_CONVERT(float, Population)) * 100, 0) AS cases_per_population
from [Portfolio Project]..coviddeaths
where location like '%spain%' -- look for specific locations, like Spain
order by location, date

-- Looking at countries with the highest infection rate compared to population

select 
	location,
	Population,
	MAX(total_cases) as Highest_infection_count,
	MAX((TRY_CONVERT(float, total_cases) / TRY_CONVERT(float, Population)) * 100) AS percent_infected
from [Portfolio Project]..coviddeaths
--where location like '%spain%' -- look for specific locations, like Spain
Group by location, population
order by percent_infected desc

--Showing Countries with Highest Death Count per Population

select 
	location,
	ISNULL(MAX(CAST(total_deaths as int)),0) as Death_count -- countries with null values equals to zero
from [Portfolio Project]..coviddeaths
where continent is not null -- to avoid locations with a null value in continent
Group by location
order by Death_count desc

-- showing deaths by CONTINENT

select 
	continent,
	MAX(CAST(total_deaths as int)) as Death_count
from [Portfolio Project]..coviddeaths
where continent is not null -- to avoid locations with a null value in continent
Group by continent
order by Death_count desc


-- global numbers

select 
--	date,
	SUM(ISNULL(new_cases, 0)) AS total_cases,
    SUM(ISNULL(new_deaths, 0)) AS total_deaths,
	ISNULL((TRY_CONVERT(float, SUM(new_deaths)) / NULLIF(TRY_CONVERT(float, SUM(new_cases)), 0)) * 100, 0) AS death_rate
    --ISNULL((TRY_CONVERT(float, total_deaths) / TRY_CONVERT(float, total_cases)) * 100, 0) AS death_rate,
	--ISNULL((TRY_CONVERT(float, total_cases) / TRY_CONVERT(float, Population)) * 100, 0) AS cases_per_population
from [Portfolio Project]..coviddeaths
--where location like '%spain%' -- look for specific locations, like Spain
where continent is not null
--group by date
--order by date


-- Looking at Total Population vs Vaccinations

select 
	d.continent,
	d.location,
	d.date,
	d.population,
	ISNULL(v.new_vaccinations,0) as new_vaccinations,
    SUM(ISNULL(CONVERT(bigint, v.new_vaccinations),0)) OVER (PARTITION BY d.location ORDER BY d.date) AS cumulative_vaccinations
	-- calculates a cumulative sum of new vaccinations
from [Portfolio Project]..covidvaccinations v
join [Portfolio Project]..coviddeaths d
	on d.location = v.location
	AND CONVERT(DATETIME, d.date, 120) = CONVERT(DATETIME, v.date, 120) -- Adjust the format code as needed
where d.continent is not null
order by d.location, d.date


--CTE
With PopvsVac AS (
select 
	d.continent,
	d.location,
	d.date,
	d.population,
	ISNULL(v.new_vaccinations,0) as new_vaccinations,
    SUM(ISNULL(CONVERT(bigint, v.new_vaccinations),0)) OVER (PARTITION BY d.location ORDER BY d.date) AS cumulative_vaccinations
	-- calculates a cumulative sum of new vaccinations
from [Portfolio Project]..covidvaccinations v
join [Portfolio Project]..coviddeaths d
	on d.location = v.location
	AND CONVERT(DATETIME, d.date, 120) = CONVERT(DATETIME, v.date, 120) -- Adjust the format code as needed
where d.continent is not null
--order by d.location, d.date
)

select
    continent,
    location,
    date,
    population,
    new_vaccinations,
    cumulative_vaccinations,
    (cumulative_vaccinations / population) * 100 AS vaccination_rate
from PopvsVac
order by location, date

-- TEMP TABLE

Drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
cumulative_vaccinations numeric
)

Insert into #PercentPopulationVaccinated
select 
	d.continent,
	d.location,
	d.date,
	d.population,
	ISNULL(v.new_vaccinations,0) as new_vaccinations,
    SUM(ISNULL(CONVERT(bigint, v.new_vaccinations),0)) OVER (PARTITION BY d.location ORDER BY d.date) AS cumulative_vaccinations
	-- calculates a cumulative sum of new vaccinations
from [Portfolio Project]..covidvaccinations v
join [Portfolio Project]..coviddeaths d
	on d.location = v.location
	AND CONVERT(DATETIME, d.date, 120) = CONVERT(DATETIME, v.date, 120) -- Adjust the format code as needed
--where d.continent is not null
--order by d.location, d.date

select
    continent,
    location,
    date,
    population,
    new_vaccinations,
    cumulative_vaccinations,
    (cumulative_vaccinations / population) * 100 AS vaccination_rate
from #PercentPopulationVaccinated
order by location, date

-- Creating View to store data for later visualizations

create view PercentPopulationVaccinated as
select 
	d.continent,
	d.location,
	d.date,
	d.population,
	ISNULL(v.new_vaccinations,0) as new_vaccinations,
    SUM(ISNULL(CONVERT(bigint, v.new_vaccinations),0)) OVER (PARTITION BY d.location ORDER BY d.date) AS cumulative_vaccinations
	-- calculates a cumulative sum of new vaccinations
from [Portfolio Project]..covidvaccinations v
join [Portfolio Project]..coviddeaths d
	on d.location = v.location
	AND CONVERT(DATETIME, d.date, 120) = CONVERT(DATETIME, v.date, 120) -- Adjust the format code as needed
where d.continent is not null
-- order by d.location, d.date

drop view if exists PercentPopulationVaccinated

select *
from PercentPopulationVaccinated

-- Queries used for Tableau visualization

--1 

select 
	SUM(ISNULL(new_cases, 0)) AS total_cases,
    SUM(ISNULL(new_deaths, 0)) AS total_deaths,
	ISNULL((TRY_CONVERT(float, SUM(new_deaths)) / NULLIF(TRY_CONVERT(float, SUM(new_cases)), 0)) * 100, 0) AS death_rate
from [Portfolio Project]..coviddeaths
where continent is not null
order by 1,2

--2
-- We need to take these out as they are not included in the above queries and want to stay consistent. 
-- European Union is part of Europe.
-- We don't need income-based locations in this case.

select
	location,
	SUM(ISNULL(cast(new_deaths as int), 0)) as total_deaths
from [Portfolio Project]..coviddeaths
where continent is null
and location not in ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
Group by location
order by total_deaths desc

--3
-- retrieve information about different locations' infection statistics.

select 
	location,
	population,
	coalesce(SUM(new_cases),0) as Highest_infection_count,
	coalesce((sum(new_cases)/population),0) * 100 as percentage_infected
from [Portfolio Project]..coviddeaths
where location not in ('World', 'European Union', 'Europe', 'Oceania','South America', 'North America',
'Africa', 'Asia','International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income') 
-- avoid counts from entire continents or income-based regions
Group by location, population
order by percentage_infected desc


--4

select
	location,
	population,
	date,
	coalesce(MAX(total_cases),0) as Highest_Infection_day,
	coalesce(MAX((total_cases/population)),0) *100 as percentage_infected
from [Portfolio Project]..coviddeaths
where location not in ('World', 'European Union', 'Europe', 'Oceania','South America', 'North America',
'Africa', 'Asia','International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income') 
Group by location, population, date
order by percentage_infected desc

