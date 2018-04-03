
FinalOptimize <- function(optimizeAtActivity, AllMeasure, payload, spend, startDate, endDate, tailInScenarioId, kpiId){
  # Computations Start
  optimizeAtActivity <- ifelse(is.null(optimizeAtActivity),F,as.logical(optimizeAtActivity))
  ConstPortfolio <- createPortfolioConstraints(payload);
  ConstMarket <- createMarketConstraints(payload);
  ConstMarketInst <- createInstrumentConstraints(payload);
  KPIFormula <- getKpiFormula(unique(AllMeasure[,.(market_id=ReceivingMarketId)]), kpiId)
  Runner <- OptimizationRunner$new()
  # Constraint <- NULL
  if(optimizeAtActivity) {
      ConstMarketInstActivity <- createActivityConstraints(payload);
      Constraint <- MarketInstrumentActivityConstraint$new()
      Constraint$init(AllMeasure, ConstPortfolio, ConstMarket, ConstMarketInst, ConstMarketInstActivity, startDate, endDate, spend)
    }
  else {
      Constraint <- MarketInstrumentConstraint$new()
      Constraint$init(AllMeasure, ConstPortfolio, ConstMarket, ConstMarketInst, startDate, endDate)
   }
  OptimizeResult <- Runner$Optimize(Constraint, startDate, endDate, KPIFormula)
  Finalwts <- OptimizeResult$Finalwts
  SourceFactors <- OptimizeResult$SourceFactorsWithDropScopeConstraint
  AllMeasure <- OptimizeResult$AllMeasure
  FinalSpend <- formatToOptimizationResult(AllMeasure, SourceFactors, Finalwts, tailInScenarioId, startDate, endDate, spend)
  return(FinalSpend)
}
