formatToOptimizationResult <- function(AllMeasure, SourceFactors, wts, tailInScenarioId, StartDate, EndDate, Spend)
{
  FinalizedWts <- data.frame(SourceFactors, wts)
  columnsForSpendInstrumentLevelTable <- names(Spend)[!names(Spend) %in% c("GrowthDriver", "GrowthDriverName", "Activity", "ActivityName", "Investment", "IsInScope")]
  SpendInstrumentLevel <- Spend[,lapply(.SD,sum,na.rm=TRUE),by=columnsForSpendInstrumentLevelTable,.SDcols='Investment']
  
  FinalOptData <-
    data.table:::merge.data.table(SpendInstrumentLevel, FinalizedWts, by =
                                    intersect(names(AllMeasure), names(FinalizedWts)))
  
  data.table::setnames(
    FinalOptData,
    old = c('Investment'),
    new = c('Current_Investment')
  )
  FinalOptData <- data.table:::subset.data.table(FinalOptData,StartDate <= Week & Week <= EndDate)
  FinalOptData[, OptInvestment := Current_Investment * wts]
  currentScenarioSpend <- data.table:::subset.data.table(Spend,StartDate <= Week & Week <= EndDate)
  OptSpendData <- data.table:::merge.data.table(currentScenarioSpend,
                                                FinalOptData,
                                                by = intersect(names(currentScenarioSpend), names(FinalOptData)),
                                                all = TRUE, allow.cartesian = TRUE)
  
  ActivityLevelOptSpend <-
    OptSpendData[, ActLvlOptSpend := ifelse(Current_Investment == 0, 0, ifelse(IsInScope == FALSE, Investment, OptInvestment * (Investment / Current_Investment)))]
  ActivityLevelOptSpend[, c("Investment", "OptInvestment", "Current_Investment", "wts", "ActivityName", "GrowthDriverName", "IsInScope") := NULL]
  data.table::setnames(
    ActivityLevelOptSpend,
    old = c('ActLvlOptSpend'),
    new = c('Investment')
  )
  if(length(tailInScenarioId) != 0)  {
    ActivityLevelOptSpend <- ActivityLevelOptSpend[ActivityLevelOptSpend$ScenarioId != tailInScenarioId]
  }
  ActivityLevelOptSpend$Week <- ActivityLevelOptSpend$Week - StartDate
  
  names(ActivityLevelOptSpend) <-
    c(
      "scenarioId",
      "marketId",
      "instrumentId",
      "weekNo",
      "campaignId",
      "activityId",
      "weeklySpends"
    )
  return(ActivityLevelOptSpend)
}