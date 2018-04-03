Feature: Unconstrained optimization at Instrument Level

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
  @sanityTest
  Scenario: Portfolio optimization for bolt hammer
    Given I fetch the unconstrained optimization payload
    And I fetch and store the actual scenario details
    When I run optimization for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    And I assert optimized selected kpi's mroi to be zero at instrument level
    And I assert optimized selected kpi's returns to be greater than that of actual scenario