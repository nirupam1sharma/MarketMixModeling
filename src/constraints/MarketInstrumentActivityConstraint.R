

MarketInstrumentActivityConstraint = setRefClass('MarketInstrumentActivityConstraint',
                                         fields=list(Min_InscopeBudget = "numeric", Max_InscopeBudget = "numeric",
                                                     PortfolioLevelROI = "numeric", MarketInscopeAndROI = "data.table",
                                                     InstrumentInscopeAndROI = "data.table",
                                                     PortfolioPF = "numeric"),
                                         contains=list("BaseConstraint"),
methods=list(

  init = function(AllMeasure, ConstPortfolio, ConstBrGeo, ConstBrGeoInst, ConstMarketInstActivity, StartDate, EndDate, Spend){
    SourceBased <<- c(MarketInstrument, SourceActivity)
    SourceFactors <- getSourceFactors(StartDate, EndDate, Spend)
    names(ConstBrGeo) <- c("MarketId", "MarketMin", "MarketMax", "MarketSpend", "MarketImpact")
    names(ConstBrGeoInst) <- c("MarketId", "InstrumentId", "InstrumentImpact", "InstrumentSpend", "InstrumentMin", "InstrumentMax")
    AllMeasure$Attributed_Investment <- AllMeasure$Investment/AllMeasure$XEffectf
    
    CurrentInscopeWithTailInActivities <- AllMeasure[Week >= StartDate & Week <= EndDate,.(Investment=sum(Attributed_Investment,na.rm = TRUE)),by=SourceBased]
    CurrentInscope <- data.table:::merge.data.table(SourceFactors, CurrentInscopeWithTailInActivities, by=c("Activity"), all.x=T)
    CurrentInscope <- CurrentInscope[, .(MarketId.x, InstrumentId.x, Activity,Investment)]
    setnames(CurrentInscope, old = c('MarketId.x'), new = c('MarketId'))
    setnames(CurrentInscope, old = c('InstrumentId.x'), new = c('InstrumentId'))
    
    CurrentInscopeWithInstrumentConst <- mergingTables(CurrentInscope,ConstBrGeoInst)
    CurrentInscopeWithMarketConst <- mergingTables(CurrentInscopeWithInstrumentConst, ConstBrGeo)
    CurrentInscopeWithConst <- mergingTables(CurrentInscopeWithMarketConst, ConstMarketInstActivity)
    
    CurrentInscopeWithConst$DropScope <- ifelse((!is.na(CurrentInscopeWithConst$Max) & !is.na(CurrentInscopeWithConst$Min) &
                                                   CurrentInscopeWithConst$Max==CurrentInscopeWithConst$Min),1,0)
    FixedBudgetCases <- data.table:::subset.data.table(CurrentInscopeWithConst,select = c(SourceBased,'DropScope'))
    OCurrentInscopeWithConst <- CurrentInscopeWithConst[order(DropScope),]
    OAllMeasure <- mergingTables(AllMeasure,FixedBudgetCases)
    #setting dropscope as 0 for tail in activities
    OAllMeasure$DropScope[is.na(OAllMeasure$DropScope)] <- 0
    All.Measure <- data.table:::subset.data.table(OAllMeasure,DropScope==0)
    # All.Measure[StartDate <= Week & Week <= EndDate,.SD,.SDcols=SourceBased]
    SourceFactorsWithDropScopeConstraint <- unique.data.frame(intersect(All.Measure[,.SD,.SDcols=SourceBased], SourceFactors))
    #SourceFactorsWithDropScopeConstraint <- unique(All.Measure[,.SD,.SDcols=SourceBased])
    setorderv(SourceFactorsWithDropScopeConstraint, SourceBased)
    AdjustedSpend <- OCurrentInscopeWithConst[DropScope==1,.(Investment=sum(Max,na.rm = TRUE))]
    
    MarketLevelFixedSpend <- OCurrentInscopeWithConst[DropScope==1,.(FixedInvestment=sum(Max,na.rm = TRUE)),by=MarketId]
    InstrumentLevelFixedSpend <- OCurrentInscopeWithConst[DropScope==1,.(FixedInvestment=sum(Max,na.rm = TRUE)),by=c("MarketId","InstrumentId")]
    
    CurrentInscopeWithConst <- CurrentInscopeWithConst[DropScope==0]
    
    lb <- ifelse(is.na(CurrentInscopeWithConst$Min),LowerLimit,CurrentInscopeWithConst$Min/CurrentInscopeWithConst$Investment)
    
    findUpperBoundFor <- function(row) { 
      row$ub <- ifelse(!is.na(row$Max), 
                       row$Max/row$Investment, 
                       ifelse(!is.na(row$InstrumentMax), 
                              row$InstrumentMax/row$Investment,
                              ifelse(!is.na(row$MarketMax), 
                                     row$MarketMax/row$Investment,
                                     ifelse(!is.na(ConstPortfolio$Max), 
                                            ConstPortfolio$Max/row$Investment, 
                                            UpperLimit
                                     )
                              )
                       )
      )
    }
    
    CurrentInscopeWithUpperLimits <- ddply(CurrentInscopeWithConst, .(MarketId,InstrumentId,Activity,Investment,Max,MarketMax,InstrumentMax), findUpperBoundFor)
    ub <- CurrentInscopeWithUpperLimits$V1
    limit <- as.matrix(data.frame(lb,ub))
    
    Min_InscopeBudget <- ConstPortfolio$Min
    Max_InscopeBudget <- ConstPortfolio$Max
    
    MarketInscopeBudgetWithFixedSpend <- mergingTables(ConstBrGeo, MarketLevelFixedSpend)
    MarketInscopeBudgetWithFixedSpend$FixedInvestment[is.na(MarketInscopeBudgetWithFixedSpend$FixedInvestment)] <- 0
    
    MarketInstrumentInscopeBudgetWithFixedSpend <- mergingTables(ConstBrGeoInst, InstrumentLevelFixedSpend)
    MarketInstrumentInscopeBudgetWithFixedSpend$FixedInvestment[is.na(MarketInstrumentInscopeBudgetWithFixedSpend$FixedInvestment)] <- 0
    
    if(nrow(AdjustedSpend) > 0) {
      Min_InscopeBudget <- Min_InscopeBudget  - AdjustedSpend$Investment
      Max_InscopeBudget <- Max_InscopeBudget - AdjustedSpend$Investment
    }
    
    
    MarketInscopeBudgetWithFixedSpend$MarketMax <- MarketInscopeBudgetWithFixedSpend$MarketMax - MarketInscopeBudgetWithFixedSpend$FixedInvestment
    MarketInscopeBudgetWithFixedSpend$MarketMin <- MarketInscopeBudgetWithFixedSpend$MarketMin - MarketInscopeBudgetWithFixedSpend$FixedInvestment
    
    MarketInstrumentInscopeBudgetWithFixedSpend$InstrumentMax <- MarketInstrumentInscopeBudgetWithFixedSpend$InstrumentMax - MarketInstrumentInscopeBudgetWithFixedSpend$FixedInvestment
    MarketInstrumentInscopeBudgetWithFixedSpend$InstrumentMin <- MarketInstrumentInscopeBudgetWithFixedSpend$InstrumentMin - MarketInstrumentInscopeBudgetWithFixedSpend$FixedInvestment
    
    PortfolioLevelROI <- sum(CurrentInscopeWithConst$Impact,na.rm = TRUE)/sum(CurrentInscopeWithConst$Spend,na.rm = TRUE)
    MarketInscopeBudgetWithFixedSpend$ROI <- MarketInscopeBudgetWithFixedSpend$MarketImpact / MarketInscopeBudgetWithFixedSpend$MarketSpend
    MarketInstrumentInscopeBudgetWithFixedSpend$ROI <- MarketInstrumentInscopeBudgetWithFixedSpend$InstrumentImpact / MarketInstrumentInscopeBudgetWithFixedSpend$InstrumentSpend
    
    marketWithStartingValue <- calculateStartingValues(Max_InscopeBudget, MarketInscopeBudgetWithFixedSpend)
    SourceFactorsWithStartingValue <- mergingTables(SourceFactorsWithDropScopeConstraint, marketWithStartingValue)
    setorderv(SourceFactorsWithStartingValue, c('MarketId', 'InstrumentId', 'Activity'))
    
    AllMeasure <- data.table:::subset.data.table(OAllMeasure,DropScope==0)
    
  
    # Set it to class fields
    MarketInscopeAndROI <<- MarketInscopeBudgetWithFixedSpend[,c("MarketId", "MarketMax", "MarketMin", "ROI"), with=FALSE]
    InstrumentInscopeAndROI <<- MarketInstrumentInscopeBudgetWithFixedSpend[,c("MarketId","InstrumentId", "InstrumentMax", "InstrumentMin", "ROI"), with=FALSE]
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
    
      for(i in 1:length(StartingValue)){
        if(StartingValue[i] <= lb[i]){
          StartingValue[i] = lb[i]
        }else if(StartingValue[i] >= ub[i]){
          StartingValue[i] = ub[i]
        }
      }
    },

  getSourceFactors = function(StartDate, EndDate, Spend){
    return(unique.data.frame(Spend[Week >= StartDate & Week <= EndDate & IsInScope == TRUE,.SD,.SDcols=SourceBased]))
  },

  getSecondStartingValue = function(FirstCutOutput) {
    OptInscopeScenario <- OptSpends(AllMeasure, SourceFactorsWithDropScopeConstraint, FirstCutOutput, StartDate, EndDate)
    
    # calculate starting value for all markets, NOT DONE
    PortfolioAdjustedBudget <- calculateAdjustedBudget(sum(OptInscopeScenario$AttributedInvestment), Min_InscopeBudget, Max_InscopeBudget)
    
    MarketOptInscopeScenario <- aggregate(OptInscopeScenario$AttributedInvestment, by=list(MarketId=OptInscopeScenario$MarketId), FUN=sum)
    MarketInstOptInscopeScenario <- aggregate(OptInscopeScenario$AttributedInvestment, by=list(MarketId=OptInscopeScenario$MarketId,InstrumentId=OptInscopeScenario$InstrumentId), FUN=sum)
    
    MarketOptSpendAndInscope <- (data.table:::merge.data.table(MarketOptInscopeScenario, MarketInscopeAndROI,
                                                               by = c("MarketId"),
                                                               all.x = TRUE))
    MarketInstOptSpendAndInscope <- (data.table:::merge.data.table(MarketInstOptInscopeScenario, InstrumentInscopeAndROI,
                                                                   by = c("MarketId", "InstrumentId"),
                                                                   all.x = TRUE))
    MarketOptSpendAndInscope <- MarketOptSpendAndInscope[, .(MarketId, MarketMax, MarketMin, x)]
    MarketInstOptSpendAndInscope <- MarketInstOptSpendAndInscope[, .(MarketId, InstrumentId, InstrumentMax, InstrumentMin, x)]
    setnames(MarketOptSpendAndInscope, old = c('x'), new = c('MarketSpend'))
    setnames(MarketInstOptSpendAndInscope, old = c('x'), new = c('InstrumentSpend'))
    
    marketWithStartingValue <- calculateStartingValues(Max_InscopeBudget, MarketOptSpendAndInscope)
    
    SourceFactorsCopyWithBudget <- mergingTables(SourceFactorsWithDropScopeConstraint, marketWithStartingValue)
    SourceFactorsCopyWithBudget$FirstCutOutput <- FirstCutOutput
    
    setorderv(SourceFactorsCopyWithBudget, SourceBased)
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
    
    InstrumentInscopeAndROI$PF <<- calculatePF(precision, InstrumentInscopeAndROI$InstrumentMin, InstrumentInscopeAndROI$InstrumentMax, InstrumentInscopeAndROI$ROI)
  },

  getComputePenaltyLambda = function() {
    return (
      function(AllDataWithOptimisedKpi){

         MarketInscopeAndROIAndPFAndOptimizedSpend <- mergingTables(MarketInscopeAndROI, AllDataWithOptimisedKpi[Week >= StartDate & Week <= EndDate, .(InScopeOptBudget=sum(AttributedInvestment, na.rm = TRUE)), by=MarketId])
        InstrumentInscopeAndROIAndPFAndOptimizedSpend <- mergingTables(InstrumentInscopeAndROI, AllDataWithOptimisedKpi[Week >= StartDate & Week <= EndDate, .(InScopeOptBudget=sum(AttributedInvestment, na.rm = TRUE)), by=c("MarketId", "InstrumentId")])
        MarketInscopeAndROIAndPFAndOptimizedSpend$Penalty <- calculatePenalty(MarketInscopeAndROIAndPFAndOptimizedSpend$PF,
                                                                              MarketInscopeAndROIAndPFAndOptimizedSpend$InScopeOptBudget,
                                                                              MarketInscopeAndROIAndPFAndOptimizedSpend$MarketMax,
                                                                              MarketInscopeAndROIAndPFAndOptimizedSpend$MarketMin
        )
        InstrumentInscopeAndROIAndPFAndOptimizedSpend$Penalty <- calculatePenalty(InstrumentInscopeAndROIAndPFAndOptimizedSpend$PF,
                                                                                  InstrumentInscopeAndROIAndPFAndOptimizedSpend$InScopeOptBudget,
                                                                                  InstrumentInscopeAndROIAndPFAndOptimizedSpend$InstrumentMax,
                                                                                  InstrumentInscopeAndROIAndPFAndOptimizedSpend$InstrumentMin
        )
        PortfolioLevelPenalty <- calculatePenalty(PortfolioPF, sum(MarketInscopeAndROIAndPFAndOptimizedSpend$InScopeOptBudget, na.rm = TRUE), Max_InscopeBudget, Min_InscopeBudget)
        TotalPenalty <- PortfolioLevelPenalty + sum(MarketInscopeAndROIAndPFAndOptimizedSpend$Penalty) + sum(InstrumentInscopeAndROIAndPFAndOptimizedSpend$Penalty)

        return (TotalPenalty)
      })

  },
  
  getFixedBudgetFinalWts = function() {
    val <- OCurrentInscopeWithConst[DropScope==1, .(MarketId, InstrumentId, Activity, Finalwts=Max/Investment)]
    return (val)
  }
  
  ))
