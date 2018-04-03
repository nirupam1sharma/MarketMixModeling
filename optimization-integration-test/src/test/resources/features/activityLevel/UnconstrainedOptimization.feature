Feature: Unconstrained optimization at Activity Level

  Background:
    Given I upload dimensions "BarlandHammerDimensions.csv"
    Given I upload calendar "BarlandHammerCalendar.csv"
    Given I upload model "BarlandHammerCurves.csv"
    Given I upload media cost "BarlandHammerMediaCost.csv"
    Given I upload secondary kpi params "BarlandHammerParams.csv" and setup secondary kpi "BarlandHammerWithMultipleKpiFormula.csv"
    Given I setup tertiary kpi "Net Profit" with first secondary kpi
    Given I upload previous year spend "BarlandHammerPreviousSpend.csv"
    Given I upload current year plan "BarlandHammerCurrentSpend.csv"

# Optimization when secondary kpi equal to primary kpi fails
#  Scenario: Portfolio optimization for bolt hammer with zero spend instrument and primary KPI
#    Given I create secondary kpi which is equal to primary kpi
#    Given I upload previous year spend "BaileysHistoricalSpend.csv"
#    Given I upload current year plan "BaileysPlanPeriodZeroSpendInstru.csv"
#    Given I fetch the unconstrained optimization payload
#    And I fetch and store the actual scenario details
#    When I run optimization at activity level for the scenario
#    And I updated the scenario with optimized spends
#    And I fetch and store optimized scenario details
#    Then I assert optimized portfolio spend greater than zero
#    And I assert optimized selected kpi's mroi to be zero at instrument level
#    And I assert optimized selected kpi's returns to be greater than that of actual scenario

  # passed
  Scenario: Portfolio optimization for bolt hammer by de-selecting some activities
    Given I fetch the unconstrained optimization payload
    And I fetch and store the actual scenario details
    And I deselect activity with name "Activity 17"
    When I run optimization at activity level for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    And I assert optimized spend for "Activity 17" to be unchanged
