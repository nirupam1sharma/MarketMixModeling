Feature: Unconstrained optimization at Instrument Level

  Background:
    Given I upload dimensions "BaileysDimensions.csv"
    Given I upload calendar "BaileysCalendar.csv"
    Given I upload model "BaileysModel.csv"
    Given I upload media cost "BaileysMediaCost.csv"
    Given I upload secondary kpi params "BaileysSecondaryKpiWeeklyMetrics.csv" and setup secondary kpi "BaileysMarketKpiFormula.csv"
    Given I setup tertiary kpi "Net Profit" with first secondary kpi


    # passed
  Scenario: Portfolio optimization for baileys
    Given I upload previous year spend "BaileysHistoricalSpend.csv"
    Given I upload current year plan "BaileysPlanPeriodSpend.csv"
    Given I fetch the unconstrained optimization payload
    And I fetch and store the actual scenario details
    When I run optimization for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    And I assert optimized selected kpi's mroi to be zero at instrument level
    And I assert optimized selected kpi's returns to be greater than that of actual scenario

#Optimization fails when Primary Kpi is equal to Secondary Kpi
#  Scenario: Portfolio optimization for baileys with zero spend instrument and primary KPI
#    Given I create secondary kpi which is equal to primary kpi
#    Given I upload previous year spend "BaileysHistoricalSpend.csv"
#    Given I upload current year plan "BaileysPlanPeriodZeroSpendInstru.csv"
#    Given I fetch the unconstrained optimization payload
#    And I fetch and store the actual scenario details
#    When I run optimization for the scenario
#    And I updated the scenario with optimized spends
#    And I fetch and store optimized scenario details
#    Then I assert optimized portfolio spend greater than zero
#    And I assert optimized selected kpi's mroi to be zero at instrument level
#    And I assert optimized selected kpi's returns to be greater than that of actual scenario

  # passed
  Scenario: Portfolio optimization for baileys by de-selecting some activities
    Given I upload previous year spend "BaileysHistoricalSpend.csv"
    Given I upload current year plan "BaileysPlanPeriodSpend.csv"
    Given I fetch the unconstrained optimization payload
    And I fetch and store the actual scenario details
    And I deselect activity with name "Activity 17"
    When I run optimization for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    #And I assert optimized selected kpi's mroi to be zero at instrument level
    #And I assert optimized selected kpi's returns to be greater than that of actual scenario
    And I assert optimized spend for "Activity 17" to be unchanged
