library(plyr)
library(parallel)
library(data.table)
library(dplyr)
library(rgenoud)
library(RPostgreSQL)
library(tidyjson)

CommaSeparatedValues <- function(ColName, collapse=",")
{
  Keys <- paste(as.character(ColName), collapse = collapse)
  return(list(Keys = Keys))
}

calculatePenalty <- function(PortfolioPF, InScopeOptimizedBudget, MaxInScopeBudget, MinInScopeBudget){
  return(PortfolioPF*(min(0,(InScopeOptimizedBudget-MinInScopeBudget),na.rm=TRUE)^2 + max(0,(InScopeOptimizedBudget - MaxInScopeBudget),na.rm=TRUE)^2))
}

mergingTables <- function(dataA, dataB) {
  commonColumns <- intersect(names(dataA), names(dataB))
  if(length(commonColumns)!=0L)
    return (data.table:::merge.data.table(dataA, dataB,
                                          by = c(commonColumns),
                                          all.x = TRUE,
                                          allow.cartesian = TRUE)
    )
}

mergingWithMediaCostData <- function(spendDt, mediaCostDt) {
  dt <- mergingTables(spendDt, mediaCostDt)
  dt2 <- (data.table:::merge.data.table(dt[is.na(Cost)], mediaCostDt[ActivityName == 'Default' & GrowthDriverName == 'Default'],
                                        by = c("MarketId", "InstrumentId", "Week"),
                                        all.x = TRUE,
                                        allow.cartesian = TRUE))
  dt3 <- dt2[, .(MarketId, InstrumentId, Week, GrowthDriverName.x, ActivityName.x, ScenarioId.x, GrowthDriver, Activity, IsInScope, Investment, Cost.y)]
  setnames(dt3, old = c('ScenarioId.x', 'GrowthDriverName.x', 'ActivityName.x', 'Cost.y'), new = c('ScenarioId', 'GrowthDriverName', 'ActivityName', 'Cost'))
  dt4 <- rbind(dt[!is.na(Cost)], dt3)
  return (dt4)
}

OptEngine <- function(MAX_POPULATION_SIZE, debugLevel, unif_seed, int_seed, NoWorkers, SourceFactors, wg, sv, MaxorMin, Objfunction, limit)
{
  cl <- makeCluster(NoWorkers)
  clusterCall(cl, function() {
    require(data.table)
    require(DataCombine)
    require(reshape)
  })
  clusterExport(cl, c(FunctionsToCopyToAllClusters, 'mergingTables', 'calculatePenalty'))
  
  num_factors <- nrow(SourceFactors)
  pop_size <- num_factors * as.numeric(config[['Pop_Size_Factor']])
  if (pop_size > MAX_POPULATION_SIZE)
  {
    pop_size <- MAX_POPULATION_SIZE
  }
  
  OptOutput <- genoud(
    Objfunction,
    nvars = num_factors,
    max = MaxorMin,
    pop.size = pop_size,
    max.generations = as.numeric(config[['max_generations']]),
    wait.generations = wg,
    hard.generation.limit = TRUE,
    starting.values = sv,
    MemoryMatrix = TRUE,
    Domains = limit,
    default.domains = NULL,
    solution.tolerance = as.numeric(config[['Tol']]),
    gr = NULL,
    boundary.enforcement = 2,
    lexical = FALSE,
    gradient.check = FALSE,
    BFGS = TRUE,
    data.type.int = FALSE,
    hessian = FALSE,
    unif.seed = unif_seed,
    int.seed = int_seed,
    print.level = as.numeric(config["GenoudPrintLevel"]),
    project.path = config[["GenoudProjectFilePath"]],
    P1 = as.numeric(config[['PM1']]),
    P2 = as.numeric(config[['PM2']]),
    P3 = as.numeric(config[['PM3']]),
    P4 = as.numeric(config[['PM4']]),
    P5 = as.numeric(config[['PM5']]),
    P6 = as.numeric(config[['PM6']]),
    P7 = as.numeric(config[['PM7']]),
    P8 = as.numeric(config[['PM8']]),
    P9 = as.numeric(config[['PM9']]),
    P9mix = NULL,
    BFGSburnin = 0,
    BFGSfn = NULL,
    BFGShelp = NULL,
    #control=list(abstol = 10000, reltol =10000),
    optim.method = "L-BFGS-B",
    #"BFGS",L-BFGS-B
    transform = FALSE,
    debug = debugLevel,
    cluster = cl,
    balance = TRUE
  )
  stopCluster(cl)
  return(OptOutput$par)
}

getPayload <- function(scenarioId){
  con <- connectToDatabaseWith(config["optimizationDbName"], config["optimization_host"], config["dbPort"], config["dbUsername"], config["dbPassword"])
  query <- "select payload::text from optimization where scenario_id=$1"
  payloadDF <- dbGetQuery(con, query, c(scenarioId))
  disconnectFromDatabase(con)
  return(payloadDF)
}
saveOptimizationResult <- function(scenarioId, optimizationResult, message, status){
  con <- connectToDatabaseWith(config["optimizationDbName"], config["optimization_host"], config["dbPort"], config["dbUsername"], config["dbPassword"])
  query <- "UPDATE optimization SET optimization_result=$1, message=$2, status=$3 WHERE scenario_id=$4"
  dbSendQuery(con, query, c(optimizationResult, message, status, scenarioId))
  disconnectFromDatabase(con)
}


expandTertiaryKpiFormula <- function(market_id_arg, formula, kpiFormulaDetails){
  secondaryKpi <- unlist(strsplit(formula, "-"))[1]
  secondaryKpiFormula <- kpiFormulaDetails[market_id == market_id_arg][kpi_name == secondaryKpi]$formula
  return(gsub(secondaryKpi, secondaryKpiFormula, formula))
}

getKpiFormula <- function(marketIds, kpiId){
  con <- connectToDatabase(config)
  secondaryKpiFormulaDetails <- data.table(dbGetQuery(con, "select market_id, kpis.id as kpi_id, name as kpi_name, kpi_types.type as kpi_type, formula from kpis join market_kpi_formula on kpis.id = market_kpi_formula.destination_kpi_id join kpi_types on kpis.kpi_type = kpi_types.id order by market_id"))
  tertiaryKpiFormula <- data.table(dbGetQuery(con,"select kpis.id as kpi_id, name as kpi_name, kpi_types.type as kpi_type, formula from kpis join tertiary_kpi_formula on kpis.id = tertiary_kpi_formula.kpi_id join kpi_types on kpis.kpi_type = kpi_types.id"))
  if(nrow(secondaryKpiFormulaDetails) == 0) {
    return(NULL);
  }
  tertiaryKpiFormulaWithMarket <- data.table(marketIds, tertiaryKpiFormula)
  kpiFormulaDetails <- rbind(secondaryKpiFormulaDetails, tertiaryKpiFormulaWithMarket)
  disconnectFromDatabase(con)
  selectedKpiFormulaDetails <- kpiFormulaDetails[kpi_id == kpiId]
  return(selectedKpiFormulaDetails[kpi_type == 'Tertiary Kpi',
                                   formula:=expandTertiaryKpiFormula(market_id, formula, kpiFormulaDetails),
                                   by=1:nrow(selectedKpiFormulaDetails)])
}

calculatePF <- function(PrecisionInBudget, Min_InscopeBudget, Max_InscopeBudget, ROI)
{
  PF <- ifelse(is.na(Min_InscopeBudget)==FALSE,
               abs(ROI)/((Min_InscopeBudget * PrecisionInBudget + 1)^2 - (Min_InscopeBudget * PrecisionInBudget)^2),
               ifelse(is.na(Max_InscopeBudget)==FALSE,
                      abs(ROI)/((Max_InscopeBudget * PrecisionInBudget + 1)^2 - (Max_InscopeBudget * PrecisionInBudget)^2),0))
  return(PF)
}

OptSpends <- function(AllMeasure, SourceFactors, wgts, StartDate, EndDate){
  require(data.table)
  require(DataCombine)
  require(reshape)
  
  OptimizedWts <- data.frame(SourceFactors,wgts)
  OptData <- data.table:::merge.data.table(AllMeasure,OptimizedWts,by=intersect(names(AllMeasure), names(OptimizedWts)),all=FALSE)
  AllData <- OptData[, c("OptInvestment","PressureUnit") :=
                       list(ifelse(StartDate <= Week & Week <= EndDate, Investment * wgts,Investment),
                            ifelse(StartDate <= Week & Week <= EndDate, PressureUnit * wgts,PressureUnit))]
  AllData$AttributedInvestment <- AllData$OptInvestment/AllData$XEffectf
  InscopeData <- data.table:::subset.data.table(AllData,StartDate <= Week & Week <= EndDate)
  return(InscopeData)
}

calculateAdjustedBudget <- function(AttributedInvestment, MinInscopeBudget, MaxInscopeBudget){
  return(
    ifelse(abs(AttributedInvestment - MinInscopeBudget) < abs(AttributedInvestment - MaxInscopeBudget),
           MinInscopeBudget,
           MaxInscopeBudget
    ))
}

calculateStartingValues <- function(PortfolioMax, MarketDetails) {
  marketDetailsAccumulator <- data.table()
  if(!is.na(PortfolioMax)) {
    setorder(MarketDetails, MarketSpend)
    i <- nrow(MarketDetails)
    while (i > 0) {
      marketEntry <- MarketDetails[i, ]
      if(!is.na(marketEntry$MarketMax)) {
        if (marketEntry$MarketMax > PortfolioMax) {
          marketEntry$StartingValue <- PortfolioMax/marketEntry$MarketSpend
        } else {
          marketEntry$StartingValue <- marketEntry$MarketMax/marketEntry$MarketSpend
          PortfolioMax <- PortfolioMax - marketEntry$MarketMax
        }
      } else {
        marketEntry$StartingValue <- PortfolioMax/marketEntry$MarketSpend
      }
      marketDetailsAccumulator <- rbind(marketDetailsAccumulator, marketEntry)
      i <- i - 1
    }
  } else {
    MarketDetails$StartingValue <- ifelse(!is.na(MarketDetails$MarketMax),MarketDetails$MarketMax/MarketDetails$MarketSpend,1)
    marketDetailsAccumulator <- MarketDetails
  }
  setorder(marketDetailsAccumulator, MarketId)
  return(marketDetailsAccumulator[,c("MarketId","StartingValue"), with=FALSE])
}
