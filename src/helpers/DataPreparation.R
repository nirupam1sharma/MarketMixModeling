#==========================================#
# Read Input Variables (probably from DB) #
#==========================================#

GetMediaCosts <- function(con) {
  MediaCost <-
    data.table(
      dbGetQuery(
        con,
        "SELECT
        mc.market_id AS marketId,
        mc.instrument_id AS instrumentId,
        mc.campaign_name as campaignName,
        mc.activity_name as activityName,
        mc.week AS Week,
        mc.cost AS Cost
        FROM market_media_costs mc;"
      )
      )
  names(MediaCost) <- c("MarketId", "InstrumentId", "GrowthDriverName", "ActivityName", "Week", "Cost")
  return (MediaCost)
}

GetCurveParameters <- function(con) {
  CurveParameter <- data.table(
    dbGetQuery(
      con,
      "SELECT
      gm.id AS marketId,
      i.id AS instrumentId,
      c.carryover AS carryover,
      c.lag AS lag,
      rm.id AS ReceivingMarketId,
      ff.name AS functionalFormName,
      c.a AS CoefficientA,
      c.b AS CoefficientB,
      c.c AS CoefficientC,
      c.id AS RelationId
      FROM
      markets gm,
      markets rm,
      functional_forms ff,
      instruments i,
      market_instruments mi,
      curves c
      WHERE c.functional_form_id = ff.id
      AND mi.id = c.giving_market_instrument_id
      AND gm.id = mi.market_id
      AND i.id = mi.instrument_id
      AND rm.id = c.receiving_market_id;"
    )
    )
  names(CurveParameter) <-
    c(
      "MarketId",
      "InstrumentId",
      "Carryover",
      "Lag",
      "ReceivingMarketId",
      "functionalFormName",
      "CoefficientA",
      "CoefficientB",
      "CoefficientC",
      "RelationId"
    )
  return (CurveParameter)
}

GetSecondaryKPIs <- function(con) {
  SecondaryKPIs <-
    data.table(
      dbGetQuery(
        con,
        "SELECT
        skm.name AS variable,
        skp.week AS week,
        skp.value AS value,
        skp.curve_id AS relationId
        FROM
        market_relation_level_secondary_kpi_metrics_weekly_values skp,
        secondary_kpi_metrics skm
        WHERE skp.metrics_id = skm.id;"
      )
      )
  names(SecondaryKPIs) <- c("Variable", "Week", "Value", "RelationId")
  SecondaryKPIs$Variable <- gsub("\\s+", "_", SecondaryKPIs$Variable)
  return (SecondaryKPIs)
}

DataPrep <- function(Spend, StartDate, MediaCost, CurveParameter, SecondaryKPIs) {
  SourceDestinationBased <- c(MarketInstrument, DestinationBased)
  # Establish DB Connection and get the details
  # Opt data preparation start here:
  # Ask why this.
  SecondaryKPIMetrics <-
    dcast.data.table(
      data = SecondaryKPIs,
      ... ~ Variable,
      fun.aggregate = sum,
      drop = TRUE,
      value.var = "Value"
    )
  
  CurrentScenarioID <- unique(data.table:::subset.data.table(Spend,StartDate <= Week)$ScenarioId)
  TailinScenarioID <- unique(data.table:::subset.data.table(Spend,StartDate > Week)$ScenarioId)
  MediaCost <- MediaCost[, c("ScenarioId") := list(ifelse(Week >= StartDate,CurrentScenarioID,TailinScenarioID))]
  SpendWithMediaCostActivityLevel <- mergingWithMediaCostData(Spend, MediaCost)
  MediaCost[, c("ScenarioId"):=NULL]
  
  SpendWithMediaCostActivityLevel[, c("GrowthDriverName","ActivityName"):=NULL] 
  SpendWithMediaCostActivityLevel[, c("PressureUnit") := list(Investment / Cost)]
  
  MediaCost <- MediaCost[ActivityName == 'Default' & GrowthDriverName == 'Default']
  MediaCost[, c("GrowthDriverName","ActivityName"):=NULL]
  
  temp <- names(SpendWithMediaCostActivityLevel)[!names(SpendWithMediaCostActivityLevel) %in% c("Week","Cost","Investment","PressureUnit", "IsInScope")]
  SpendWithMediaCostActivityLevelWithOutWeekInvestment <- CommaSeparatedValues(temp)
  SpendWithMediaCostActivityLevelDimension <- eval(parse(text=paste0("SpendWithMediaCostActivityLevel %>% ",
                                                                     " distinct(",SpendWithMediaCostActivityLevelWithOutWeekInvestment,") %>% ",
                                                                     " select(",SpendWithMediaCostActivityLevelWithOutWeekInvestment,") %>% as.data.table()")))
  
  
  tempSpendMediaCost <- mergingTables(SpendWithMediaCostActivityLevelDimension, MediaCost)
  dt2 <- (data.table:::merge.data.table(tempSpendMediaCost, SpendWithMediaCostActivityLevel,
                                        by = c("Activity", "GrowthDriver", "MarketId", "InstrumentId", "Week", "ScenarioId"),
                                        all.x = TRUE,
                                        all.y = TRUE,
                                        allow.cartesian = TRUE))
  
  SpendMediaCost <- dt2[, .(MarketId, InstrumentId, Activity, GrowthDriver, Week, ScenarioId, Cost.y, Investment, PressureUnit, IsInScope)]
  setnames(SpendMediaCost, old = c('Cost.y'), new = c('Cost'))
  
  SpendMediaCost$Cost[is.na(SpendMediaCost$Cost)] <- 0
  SpendMediaCost$Investment[is.na(SpendMediaCost$Investment)] <- 0
  SpendMediaCost$PressureUnit[is.na(SpendMediaCost$PressureUnit)] <- 0
  
  setkey(SpendMediaCost, Activity)
  setkey(SpendWithMediaCostActivityLevel, Activity)
  SpendMediaCost <- SpendMediaCost[SpendWithMediaCostActivityLevel, allow.cartesian=TRUE]
  SpendMediaCost <- SpendMediaCost[, .(MarketId, InstrumentId, Activity, GrowthDriver, Week, ScenarioId, Cost, Investment, PressureUnit, i.IsInScope)]
  setnames(SpendMediaCost, old = c('i.IsInScope'), new = c('IsInScope'))
  setkey(SpendMediaCost, Activity, Week)
  SpendMediaCost <- unique(SpendMediaCost)
  
  SpendCurves <- mergingTables(SpendMediaCost,CurveParameter)
  AllMeasure <- mergingTables(SpendCurves,SecondaryKPIMetrics)
  
  SourceDestinationBasedColumnSelectorWithColonCombination<-paste0("AllMeasure$",SourceDestinationBased,collapse=",':',")
  AllMeasure$Key<-eval(parse(text=paste0('paste0(',SourceDestinationBasedColumnSelectorWithColonCombination,')')))
  AllMeasure$CoefficientC[is.na(AllMeasure$CoefficientC)] <- 0
  AllMeasure <- na.omit(AllMeasure)
  
  XeffectDt <- AllMeasure %>% group_by(MarketId, InstrumentId, Week) %>% summarise(XEffectf =  n()/n_distinct(Activity)) %>% select(MarketId, InstrumentId, Week, XEffectf) %>% as.data.table()
  AllMeasure <- data.table:::merge.data.table(AllMeasure, XeffectDt, by = c("MarketId", "InstrumentId", "Week"))
  return(AllMeasure)
}