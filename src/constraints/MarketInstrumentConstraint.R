

MarketInstrumentConstraint = setRefClass('MarketInstrumentConstraint',
                                         fields=list(MarketInscopeAndROI = "data.table", Min_InscopeBudget = "numeric", Max_InscopeBudget = "numeric",
                                                     PortfolioLevelROI = "numeric", PortfolioPF = "numeric"),
                                         contains=list("BaseConstraint"),
methods=list(

  init = function(AllMeasure, ConstPortfolio, ConstMarket, ConstMarketInst, StartDate, EndDate){
    SourceBased <<- c(MarketInstrument)
    names(ConstMarket) <- c("MarketId", "MarketMin", "MarketMax", "MarketSpend", "MarketImpact")
    AllMeasure$Attributed_Investment <- AllMeasure$Investment/AllMeasure$XEffectf
    CurrentInscope <- AllMeasure[Week >= StartDate & Week <= EndDate,.(Investment=sum(Attributed_Investment,na.rm = TRUE)),by=SourceBased]
    CurrentInscopeWithMarketInstrumentConst <- mergingTables(CurrentInscope,ConstMarketInst)
    CurrentInscopeWithConst <- mergingTables(CurrentInscopeWithMarketInstrumentConst, ConstMarket)

    CurrentInscopeWithConst$DropScope <- ifelse((!is.na(CurrentInscopeWithConst$Max) & !is.na(CurrentInscopeWithConst$Min) &
                                               CurrentInscopeWithConst$Max==CurrentInscopeWithConst$Min),1,0)
    FixedBudgetCases <- data.table:::subset.data.table(CurrentInscopeWithConst,select = c(SourceBased,'DropScope'))
    OCurrentInscopeWithConst <- CurrentInscopeWithConst[order(DropScope),]
    OAllMeasure <- mergingTables(AllMeasure,FixedBudgetCases)
    All.Measure <- data.table:::subset.data.table(OAllMeasure,DropScope==0)
    SourceFactorsWithDropScopeConstraint <- unique(All.Measure[,.SD,.SDcols=SourceBased])
    AdjustedSpend <- OCurrentInscopeWithConst[DropScope==1,.(Investment=sum(Max,na.rm = TRUE))]
    MarketLevelFixedSpend <- OCurrentInscopeWithConst[DropScope==1,.(FixedInvestment=sum(Max,na.rm = TRUE)),by=MarketId]
    CurrentInscopeWithConst <- CurrentInscopeWithConst[DropScope==0]
    CurrentInscopeWithConstWithFixedSpend <- mergingTables(CurrentInscopeWithConst, MarketLevelFixedSpend)
    CurrentInscopeWithConstWithFixedSpend$FixedInvestment[is.na(CurrentInscopeWithConstWithFixedSpend$FixedInvestment)] <- 0
    
    lb <- ifelse(is.na(CurrentInscopeWithConst$Min),LowerLimit,CurrentInscopeWithConst$Min/CurrentInscopeWithConst$Investment)
    CurrentInscopeWithUpperLimits <- ddply(CurrentInscopeWithConstWithFixedSpend, .(MarketId,InstrumentId,Investment,Max,MarketMax), function(row) {

      row$ub <- ifelse(!is.na(row$Max),
                       row$Max/row$Investment,
                       ifelse(!is.na(row$MarketMax),
                              (row$MarketMax-row$FixedInvestment)/row$Investment,
                              ifelse(!is.na(ConstPortfolio$Max),
                                     (ConstPortfolio$Max - ifelse(nrow(AdjustedSpend) == 0, 0, AdjustedSpend$Investment))/row$Investment,
                                     UpperLimit
                              )
                       )
      )
    })
    ub <- CurrentInscopeWithUpperLimits$V1

    limit <- as.matrix(data.frame(lb,ub))

    Min_InscopeBudget <- ConstPortfolio$Min
    Max_InscopeBudget <- ConstPortfolio$Max

    MarketInscopeBudgetWithFixedSpend <- mergingTables(ConstMarket, MarketLevelFixedSpend)
    MarketInscopeBudgetWithFixedSpend$FixedInvestment[is.na(MarketInscopeBudgetWithFixedSpend$FixedInvestment)] <- 0

    if(nrow(AdjustedSpend) > 0) {
      Min_InscopeBudget <- Min_InscopeBudget  - AdjustedSpend$Investment
      Max_InscopeBudget <- Max_InscopeBudget - AdjustedSpend$Investment
    }


    MarketInscopeBudgetWithFixedSpend$MarketMax <- MarketInscopeBudgetWithFixedSpend$MarketMax - MarketInscopeBudgetWithFixedSpend$FixedInvestment
    MarketInscopeBudgetWithFixedSpend$MarketMin <- MarketInscopeBudgetWithFixedSpend$MarketMin - MarketInscopeBudgetWithFixedSpend$FixedInvestment

    PortfolioLevelROI <- sum(CurrentInscopeWithConst$Impact,na.rm = TRUE)/sum(CurrentInscopeWithConst$Spend,na.rm = TRUE)
    MarketInscopeBudgetWithFixedSpend$ROI <- MarketInscopeBudgetWithFixedSpend$MarketImpact / MarketInscopeBudgetWithFixedSpend$MarketSpend

    marketWithStartingValue <- calculateStartingValues(Max_InscopeBudget, MarketInscopeBudgetWithFixedSpend)
    SourceFactorsWithStartingValue <- mergingTables(SourceFactorsWithDropScopeConstraint, marketWithStartingValue)
    setorderv(SourceFactorsWithStartingValue, c('MarketId', 'InstrumentId'))

    AllMeasure <- data.table:::subset.data.table(OAllMeasure,DropScope==0)


  # Set it to class fields
    MarketInscopeAndROI <<- MarketInscopeBudgetWithFixedSpend[,c("MarketId", "MarketMax", "MarketMin", "ROI"), with=FALSE]
    Min_InscopeBudget <<- as.numeric(Min_InscopeBudget)
    Max_InscopeBudget <<- as.numeric(Max_InscopeBudget)
    PortfolioLevelROI <<- as.numeric(PortfolioLevelROI)
    lb <<- as.numeric(lb)
    ub <<- as.numeric(ub)
    limit <<- limit
    StartingValue <<- SourceFactorsWithStartingValue$StartingValue
    OCurrentInscopeWithConst <<- OCurrentInscopeWithConst
    AllMeasure <<- AllMeasure
    SourceFactorsWithDropScopeConstraint <<- SourceFactorsWithDropScopeConstraint
    StartDate <<- StartDate
    EndDate <<- EndDate
    computePF(PrecisionInBudget1)
    },

  getSecondStartingValue = function(FirstCutOutput) {
    OptInscopeScenario <- OptSpends(AllMeasure, SourceFactorsWithDropScopeConstraint, FirstCutOutput, StartDate, EndDate)
    MarketOptInscopeScenario <- aggregate(OptInscopeScenario$AttributedInvestment, by=list(MarketId=OptInscopeScenario$MarketId), FUN=sum)

    MarketOptSpendAndInscope <- (data.table:::merge.data.table(MarketOptInscopeScenario, MarketInscopeAndROI,
                                                               by = c("MarketId"),
                                                               all.x = TRUE))
    MarketOptSpendAndInscope <- MarketOptSpendAndInscope[, .(MarketId, MarketMax, MarketMin, x)]
    setnames(MarketOptSpendAndInscope, old = c('x'), new = c('MarketSpend'))

    marketWithStartingValue <- calculateStartingValues(Max_InscopeBudget, MarketOptSpendAndInscope)
    SourceFactorsCopyWithBudget <- mergingTables(SourceFactorsWithDropScopeConstraint, marketWithStartingValue)
    SourceFactorsCopyWithBudget$FirstCutOutput <- FirstCutOutput
    setorderv(SourceFactorsCopyWithBudget, c('MarketId', 'InstrumentId'))
    SecondStartingValue <- ifelse(SourceFactorsCopyWithBudget$StartingValue==1, SourceFactorsCopyWithBudget$FirstCutOutput, SourceFactorsCopyWithBudget$StartingValue)
    for(i in 1:length(SecondStartingValue)){
      if(SecondStartingValue[i] <= lb[i]){
        SecondStartingValue[i] = lb[i]
      }else if(SecondStartingValue[i] >= ub[i]){
        SecondStartingValue[i] = ub[i]
      }
    }

    return(SecondStartingValue)
  },

  computePF = function(precision) {
    PortfolioPF <<- calculatePF(precision, Min_InscopeBudget, Max_InscopeBudget, PortfolioLevelROI)
    MarketInscopeAndROI$PF <<- calculatePF(precision, MarketInscopeAndROI$MarketMin, MarketInscopeAndROI$MarketMax, MarketInscopeAndROI$ROI)
  },

  getComputePenaltyLambda = function() {
    return (
      function(AllDataWithOptimisedKpi){
        MarketInscopeAndROIAndPFAndOptimizedSpend <- mergingTables(MarketInscopeAndROI, AllDataWithOptimisedKpi[Week >= StartDate & Week <= EndDate, .(InScopeOptBudget=sum(AttributedInvestment, na.rm = TRUE)), by=MarketId])
        MarketInscopeAndROIAndPFAndOptimizedSpend$Penalty <- calculatePenalty(MarketInscopeAndROIAndPFAndOptimizedSpend$PF,
                                                                              MarketInscopeAndROIAndPFAndOptimizedSpend$InScopeOptBudget,
                                                                              MarketInscopeAndROIAndPFAndOptimizedSpend$MarketMax,
                                                                              MarketInscopeAndROIAndPFAndOptimizedSpend$MarketMin
        )
        PortfolioLevelPenalty <- calculatePenalty(PortfolioPF, sum(MarketInscopeAndROIAndPFAndOptimizedSpend$InScopeOptBudget, na.rm = TRUE), Max_InscopeBudget, Min_InscopeBudget)
        TotalPenalty <- PortfolioLevelPenalty + sum(MarketInscopeAndROIAndPFAndOptimizedSpend$Penalty)
        return (TotalPenalty)
      })

  },
  
  getFixedBudgetFinalWts = function() {
    val <- OCurrentInscopeWithConst[DropScope==1, .(MarketId, InstrumentId, Finalwts=Max/Investment)]
    return (val)
  }
  
  ))