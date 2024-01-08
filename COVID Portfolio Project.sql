Select *
From PortfolioProjectCovidData..CovidDeaths
WHERE Continent is not null
Order by 3,4

Select *
From PortfolioProjectCovidData..CovidVaccinations
Order by 3,4

--Select Data that we are going to be using

Select Location, date, total_cases,new_cases, total_deaths, population
From PortfolioProjectCovidData..CovidDeaths
Order by 1,2

--Likelihood of dying if you contract coivd in your country. First Looking at Total Cases vs Total Deaths. The perc of people who are dying who actually reported being infected

Select Location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float,total_cases),0))*100 as DeathPercentage
From PortfolioProjectCovidData..CovidDeaths
WHERE Location like '%states%'
Order by 1,2


--Looking at the Total Cases vs Population
--Shows what percentage of population got Covid

Select Location, date, population, total_cases, (CONVERT(float, total_cases) / NULLIF(CONVERT(float,population),0))*100 as PercentagePopulationInfected
From PortfolioProjectCovidData..CovidDeaths
WHERE Location like '%states%'
Order by 1,2

--Looking at Countries with the Highest Infection Rate compared to Population

Select Location, population, Max(total_cases) as HighestInfectionCount, Max((CONVERT(float, total_cases) / NULLIF(CONVERT(float,population),0)))*100 as PercentagePopulationInfected
From PortfolioProjectCovidData..CovidDeaths
--WHERE Location like '%states%'
Group By Location, population
Order by PercentagePopulationInfected desc

--Showing Countries with Highest death count per Population

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProjectCovidData..CovidDeaths
--WHERE Location like '%states%'
WHERE continent is not null
Group By Location
Order by TotalDeathCount desc

--Showing Continents with the Highest Death Count per population

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProjectCovidData..CovidDeaths
--WHERE Location like '%states%'
WHERE continent is not null
Group By continent
Order by TotalDeathCount desc

-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, Sum(new_deaths) as total_deaths, Sum(new_deaths)/Sum(new_cases)*100 as DeathPercentage
From PortfolioProjectCovidData..CovidDeaths
Where continent is not null
--Group by date
order by 1,2

--Looking at Total Population vs Vaccinations
--First, join CovidDeaths and CovidVaccinations table. Confirm all is joining correctly.
	
Select *
From PortfolioProjectCovidData..CovidDeaths dea
Join PortfolioProjectCovidData..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date 

--Second, 
--Total amount of people in the world that have been vaccinated

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioProjectCovidData..CovidDeaths dea
Join PortfolioProjectCovidData..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date 
Where dea.continent is not null
order by 2,3

--Creating a column to reflect rolling count of total vaccinations. Using Partition by and windows function

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as RollingPeopleVaccinated
From PortfolioProjectCovidData..CovidDeaths dea
Join PortfolioProjectCovidData..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date 
Where dea.continent is not null
order by 2,3

-- Taking the previous set, let's look at the MAX RollingPeopleVaccinated per location to see how many people per country have been vaccinated. 
-- Need to create CTE or a temp table

-- CTE

With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as RollingPeopleVaccinated
From PortfolioProjectCovidData..CovidDeaths dea
Join PortfolioProjectCovidData..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date 
Where dea.continent is not null
--order by 2,3
)

Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- TEMP TABLE

DROP Table if exists #PercentOfPopulationVaccinated
Create Table #PercentOfPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population float,
new_vaccinations numeric,
RollingPeopleVaccinated nvarchar(255)
)

Insert into #PercentOfPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as RollingPeopleVaccinated
From PortfolioProjectCovidData..CovidDeaths dea
Join PortfolioProjectCovidData..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date 
Where dea.continent is not null
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentOfPopulationVaccinated

	
--CREATING VIEW to store data for later visualizations

USE PortfolioProjectCovidData
Go
Create View PercentOfPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location,
	dea.date) as RollingPeopleVaccinated
From PortfolioProjectCovidData..CovidDeaths dea
Join PortfolioProjectCovidData..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date 
Where dea.continent is not null
--order by 2,3

Select*
From PercentOfPopulationVaccinated
