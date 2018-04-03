Feature: Constrained optimization on selected kpi Activity Level

  Background:
    Given I upload dimensions "BarlandHammerDimensions.csv"
    Given I upload calendar "BarlandHammerCalendar.csv"
    Given I upload model "BarlandHammerCurves.csv"
    Given I upload media cost "BarlandHammerMediaCost.csv"
    Given I upload secondary kpi params "BarlandHammerParams.csv" and setup secondary kpi "BarlandHammerWithMultipleKpiFormula.csv"
    Given I setup tertiary kpi "Net Profit" with first secondary kpi
    Given I upload previous year spend "BarlandHammerPreviousSpend.csv"
    Given I upload current year plan "BarlandHammerCurrentSpend.csv"

    # passed
#  @sanityTest
  Scenario: Portfolio optimization for bolt hammer on selected kpi
    Given I set kpi id to optimize as "SecondaryKpi"
    Given I set the min portfolio constraint "-20" % and max portfolio constraint "20" %
    Given I fetch the optimization payload
    Given I fetch and store the actual scenario details
    When I run optimization at activity level for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend is within min "-20.01" % and max "20.01" % range
    Then I assert optimized market spends greater than zero
    And I assert sum of optimized selected kpi's returns of all markets to be greater than that of actual scenario