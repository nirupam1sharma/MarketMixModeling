GetOptimisedSpendsAndPressureUnitsFromGenoudWeights <- function(SourceFactors, wgts, AllMeasure, StartDate, EndDate) {
  # wgts <- rep(2,nrow(SourceFactors))
  OptimizedWts <- data.frame(SourceFactors,wgts)
  OptData <- mergingTables(AllMeasure, OptimizedWts)
  OptData$wgts[is.na(OptData$wgts)] <- 1

  # MCT-752 IsInScope == true is not needed @ activity level, since the above line set wgts to 1 for excluded activity.
  AllData <- OptData[, c("OptInvestment","PressureUnit") :=
                      list(ifelse((StartDate <= Week & Week <= EndDate) & IsInScope == TRUE, Investment * wgts,Investment),
                            ifelse((StartDate <= Week & Week <= EndDate) & IsInScope == TRUE, PressureUnit * wgts,PressureUnit))]

  columnsForSpendInstrumentLevelTable <- names(AllData)[!names(AllData) %in% c("GrowthDriver", "ScenarioId", "Attributed_Investment", "Activity", "Investment", "OptInvestment", "PressureUnit", "Cost", "IsInScope","wgts")]
  AllData <- AllData[,lapply(.SD,sum,na.rm=TRUE),by=columnsForSpendInstrumentLevelTable,.SDcols=c('Investment', 'OptInvestment', 'Attributed_Investment', 'PressureUnit')]
  AllData <- AllData[order(Key,Week),]
  return(AllData)
}
