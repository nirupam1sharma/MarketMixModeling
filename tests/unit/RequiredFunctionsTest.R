library(testthat)
library(jsonlite)
library(data.table)
library(parallel)
library(RPostgreSQL)

source("src/optimization/Initialization.R")
source("src/optimization/CommonRequiredFunctions.R")
source("src/helpers/DatabaseHelper.R")

config <- fromJSON("./config.json")

context("RequiredFunctions")

test_that("mergingTables should merge two data tables based on common keys", {
  dataTable1 <- as.data.table(fromJSON('{"scenarioId" : 13, "brandGeoId" : 1}'))
  dataTable2 <- as.data.table(fromJSON('{"brandGeoId" : 1, "activityId" : 13}'))
  expectedOutput <- as.data.table(fromJSON('{"brandGeoId" : 1, "scenarioId" : 13, "activityId" : 13}'))

  output <- mergingTables(dataTable1, dataTable2)

  expect_true(all.equal(output, expectedOutput, check.attributes=FALSE))
})

test_that("merge media cost at activity level based on common keys", {
  dataTable1 <- as.data.table(fromJSON('{"ScenarioId" : 13, "MarketId" : 1, "InstrumentId" : 1, "GrowthDriver" : 12, "GrowthDriverName" : "ALL", "Activity" : 235, "ActivityName" : "Activity 7", "Investment" : 2001.1, "Week" : 186, "IsInScope": true}'))
  dataTable2 <- as.data.table(fromJSON('[{"ScenarioId" : 13, "MarketId" : 1, "InstrumentId" : 1, "GrowthDriverName" : "ALL", "ActivityName" : "Activity 7", "Week" : 186, "Cost" : 89},{"MarketId" : 1, "InstrumentId" : 1, "GrowthDriverName" : "Default", "ActivityName" : "Default", "Week" : 186, "Cost" : 90}]'))
  expectedOutput <- as.data.table(fromJSON('{"ScenarioId" : 13, "MarketId" : 1, "InstrumentId" : 1, "GrowthDriverName" : "ALL", "ActivityName" : "Activity 7", "Week" : 186, "GrowthDriver" : 12, "Activity" : 235, "Investment" : 2001.1, "IsInScope": true, "Cost" : 89}'))

  output <- mergingWithMediaCostData(dataTable1, dataTable2)
  expect_true(all.equal(output, expectedOutput, check.attributes=FALSE))
})

test_that("merge media cost at activity level, populate default media costs for missing entries", {
  spendDt <- as.data.table(fromJSON('{"ScenarioId" : 13, "MarketId" : 1, "InstrumentId" : 1, "GrowthDriver" : 12, "GrowthDriverName" : "ALL", "Activity" : 235, "ActivityName" : "Activity 7", "Investment" : 2001.1, "Week" : 186, "IsInScope": true}'))
  mediaCostDt <- as.data.table(fromJSON('[{"ScenarioId" : 13, "MarketId" : 1, "InstrumentId" : 1, "GrowthDriverName" : "ALL", "ActivityName" : "Activity 7", "Week" : 187, "Cost" : 89},{"MarketId" : 1, "InstrumentId" : 1, "GrowthDriverName" : "Default", "ActivityName" : "Default", "Week" : 186, "Cost" : 90}]'))
  expectedOutput <- as.data.table(fromJSON('{"ScenarioId" : 13, "MarketId" : 1, "InstrumentId" : 1, "GrowthDriverName" : "ALL", "ActivityName" : "Activity 7", "Week" : 186, "GrowthDriver" : 12, "Activity" : 235, "Investment" : 2001.1, "IsInScope": true, "Cost" : 90}'))

  output <- mergingWithMediaCostData(spendDt, mediaCostDt)
  expect_true(all.equal(output, expectedOutput, check.attributes=FALSE))
})

test_that("merge media cost at activity level, populate corresponding media costs values", {
  spendDt <- as.data.table(fromJSON('[{"ScenarioId" : 13, "MarketId" : 1, "InstrumentId" : 1, "GrowthDriver" : 12, "GrowthDriverName" : "ALL", "Activity" : 235, "ActivityName" : "Activity 7", "Investment" : 2001.1, "Week" : 186, "IsInScope": true}, {"ScenarioId" : 13, "MarketId" : 1, "InstrumentId" : 1, "GrowthDriver" : 12, "GrowthDriverName" : "ALL", "Activity" : 235, "ActivityName" : "Activity 7", "Investment" : 2001.1, "Week" : 187, "IsInScope": true}]'))
  mediaCostDt <- as.data.table(fromJSON('[{"ScenarioId" : 13, "MarketId" : 1, "InstrumentId" : 1, "GrowthDriverName" : "ALL", "ActivityName" : "Activity 7", "Week" : 187, "Cost" : 89},{"ScenarioId" : 13, "MarketId" : 1, "InstrumentId" : 1, "GrowthDriverName" : "Default", "ActivityName" : "Default", "Week" : 187, "Cost" : 100}, {"ScenarioId" : 13, "MarketId" : 1, "InstrumentId" : 1, "GrowthDriverName" : "ALL", "ActivityName" : "Activity 6", "Week" : 186, "Cost" : 200},  {"ScenarioId" : 13, "MarketId" : 1, "InstrumentId" : 1, "GrowthDriverName" : "Default", "ActivityName" : "Default", "Week" : 186, "Cost" : 90}]'))
  expectedOutput <- as.data.table(fromJSON('[{"ScenarioId" : 13, "MarketId" : 1, "InstrumentId" : 1, "GrowthDriverName" : "ALL", "ActivityName" : "Activity 7", "Week" : 187, "GrowthDriver" : 12, "Activity" : 235, "Investment" : 2001.1, "IsInScope": true, "Cost" : 89}, {"ScenarioId" : 13, "MarketId" : 1, "InstrumentId" : 1, "GrowthDriverName" : "ALL", "ActivityName" : "Activity 7", "Week" : 186, "GrowthDriver" : 12, "Activity" : 235, "Investment" : 2001.1, "IsInScope": true, "Cost" : 90}]'))

  output <- mergingWithMediaCostData(spendDt, mediaCostDt)
  expect_true(all.equal(output, expectedOutput, check.attributes=FALSE))
})

test_that("merge media cost at activity level, with two campaigns", {
  spendDt <- as.data.table(fromJSON('[{"ScenarioId":13,"MarketId":1,"InstrumentId":1,"GrowthDriver":12,"GrowthDriverName":"ALL","Activity":235,"ActivityName":"Activity 7","Investment":2001.1,"Week":186, "IsInScope": true},{"ScenarioId":13,"MarketId":1,"InstrumentId":1,"GrowthDriver":12,"GrowthDriverName":"ALL","Activity":235,"ActivityName":"Activity 7","Investment":2001.1,"Week":187, "IsInScope": true},{"ScenarioId":13,"MarketId":1,"InstrumentId":1,"GrowthDriver":15,"GrowthDriverName":"NEW","Activity":335,"ActivityName":"Activity NEW","Investment":2001.1,"Week":187, "IsInScope": true},{"ScenarioId":13,"MarketId":1,"InstrumentId":1,"GrowthDriver":15,"GrowthDriverName":"NEW","Activity":336,"ActivityName":"Activity TWO","Investment":1001.1,"Week":187, "IsInScope": true},{"ScenarioId":13,"MarketId":1,"InstrumentId":1,"GrowthDriver":15,"GrowthDriverName":"NEW","Activity":336,"ActivityName":"Activity TWO","Investment":1001.1,"Week":188, "IsInScope": true}]'))
  mediaCostDt <- as.data.table(fromJSON('[{"ScenarioId":13,"MarketId":1,"InstrumentId":1,"GrowthDriverName":"ALL","ActivityName":"Activity 7","Week":187,"Cost":89},{"ScenarioId":13,"MarketId":1,"InstrumentId":1,"GrowthDriverName":"Default","ActivityName":"Default","Week":187,"Cost":100},{"ScenarioId":13,"MarketId":1,"InstrumentId":1,"GrowthDriverName":"ALL","ActivityName":"Activity 6","Week":186,"Cost":200},{"ScenarioId":13,"MarketId":1,"InstrumentId":1,"GrowthDriverName":"Default","ActivityName":"Default","Week":186,"Cost":90},{"ScenarioId":13,"MarketId":1,"InstrumentId":1,"GrowthDriverName":"NEW","ActivityName":"Activity NEW","Week":187,"Cost":50},{"ScenarioId":13,"MarketId":1,"InstrumentId":1,"GrowthDriverName":"NEW","ActivityName":"Activity TWO","Week":187,"Cost":60},{"ScenarioId":13,"MarketId":1,"InstrumentId":1,"GrowthDriverName":"Default","ActivityName":"Default","Week":188,"Cost":100}]'))
  expectedOutput <- as.data.table(fromJSON('[{"ScenarioId":13,"MarketId":1,"InstrumentId":1,"GrowthDriverName":"ALL","ActivityName":"Activity 7","Week":187,"GrowthDriver":12,"Activity":235,"Investment":2001.1,"IsInScope": true,"Cost":89},{"ScenarioId":13,"MarketId":1,"InstrumentId":1,"GrowthDriverName":"ALL","ActivityName":"Activity 7","Week":186,"GrowthDriver":12,"Activity":235,"Investment":2001.1,"IsInScope": true,"Cost":90},{"ScenarioId":13,"MarketId":1,"InstrumentId":1,"GrowthDriverName":"NEW","ActivityName":"Activity NEW","Week":187,"GrowthDriver":15,"Activity":335,"Investment":2001.1,"IsInScope": true,"Cost":50},{"ScenarioId":13,"MarketId":1,"InstrumentId":1,"GrowthDriverName":"NEW","ActivityName":"Activity TWO","Week":187,"GrowthDriver":15,"Activity":336,"Investment":1001.1,"IsInScope": true,"Cost":60},{"ScenarioId":13,"MarketId":1,"InstrumentId":1,"GrowthDriverName":"NEW","ActivityName":"Activity TWO","Week":188,"GrowthDriver":15,"Activity":336,"Investment":1001.1,"IsInScope": true,"Cost":100}]'), order(c("GrowthDriver","Activity","Week")))
  
  output <- mergingWithMediaCostData(spendDt, mediaCostDt)
  setkey(expectedOutput, "GrowthDriver", "Activity", "Week")
  setkey(output, "GrowthDriver", "Activity", "Week")
  expectedOutput$rn <- NULL
  expect_true(all.equal(output, expectedOutput, check.attributes=FALSE))
})

test_that("mergingTables should return null if there are no common columns", {
  dataTable1 <- as.data.table(fromJSON('{"scenarioId" : 13, "brandGeoId" : 1}'))
  dataTable2 <- as.data.table(fromJSON('{"activityId" : 13}'))

  output <- mergingTables(dataTable1, dataTable2)

  expect_true((is.null(output)))
})

test_that("getNetProfitFormula should return the net profit formula from the database", {
  dummyConnection <- 'Connection'
  kpiQueryForSecondaryKpis <- "select market_id, kpis.id as kpi_id, name as kpi_name, kpi_types.type as kpi_type, formula from kpis join market_kpi_formula on kpis.id = market_kpi_formula.destination_kpi_id join kpi_types on kpis.kpi_type = kpi_types.id order by market_id"
  kpiResultForSecondaryKpis <- data.table(market_id=c("1","2", "1"), kpi_id=c("1", "2", "2"), kpi_name=c("secondary KPI1", "secondary KPI2", "secondary KPI2"), kpi_type=c("Secondary Kpi", "Secondary Kpi",  "Secondary Kpi"), formula=c("Price*Future_Efficiency", "Future_Efficiency", "Future_Efficiency"))
  kpiQueryForTertiaryKpis <- "select kpis.id as kpi_id, name as kpi_name, kpi_types.type as kpi_type, formula from kpis join tertiary_kpi_formula on kpis.id = tertiary_kpi_formula.kpi_id join kpi_types on kpis.kpi_type = kpi_types.id"
  kpiResultForTertiaryKpis <- data.table(kpi_id=c("3"), kpi_name=c("Net Profit"), kpi_type=c("Tertiary Kpi"), formula=c("secondary KPI2-AttributedInvestment"))

  with_mock(
    `connectToDatabase` = function(config)dummyConnection,
    `disconnectFromDatabase` = function(dummyConnection) TRUE,
     #TODO: Fix the issue of same result returned by both the below queries when test is run

    `RPostgreSQL::dbGetQuery` = function(dummyConnection, kpiQuery) {
      if (kpiQuery == kpiQueryForSecondaryKpis) {
        return(kpiResultForSecondaryKpis)
      } else {
        return(kpiResultForTertiaryKpis)
      }},
    netProfitFormula <- getKpiFormula(data.table('market_id' = c("1", "2")), kpiId <- "3")
  )
  expect_equal(netProfitFormula$formula, rep("Future_Efficiency-AttributedInvestment", 2))

})

test_that("getNetProfitFormula should return NA when no data is present in DB", {
  dummyConnection <- 'Connection'
  emptyList <- list()
  kpiQueryForSecondaryKpis <- "select market_id, kpis.id as kpi_id, name as kpi_name, kpi_types.type as kpi_type, formula from kpis join market_kpi_formula on kpis.id = market_kpi_formula.destination_kpi_id join kpi_types on kpis.kpi_type = kpi_types.id order by market_id"
  kpiQueryForTertiaryKpis <- "select kpis.id as kpi_id, name as kpi_name, kpi_types.type as kpi_type, formula from kpis join tertiary_kpi_formula on kpis.id = tertiary_kpi_formula.kpi_id join kpi_types on kpis.kpi_type = kpi_types.id"
  
  with_mock(
    `connectToDatabase` = function(config)dummyConnection,
    `disconnectFromDatabase` = function(dummyConnection) TRUE,
    `RPostgreSQL::dbGetQuery` = function(dummyConnection, kpiQueryForSecondaryKpis) emptyList,
    `RPostgreSQL::dbGetQuery` = function(dummyConnection, kpiQueryForTertiaryKpis) emptyList,
    netProfitFormula <- getKpiFormula(data.table('market_id' = c("1")), kpiId <- 2)
  )
  expect_true((is.null(netProfitFormula)))

})