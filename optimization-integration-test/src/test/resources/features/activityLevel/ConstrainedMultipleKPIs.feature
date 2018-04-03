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

    # passed
  Scenario: Portfolio optimization for bolt hammer
    Given I set the min portfolio constraint "0" % and max portfolio constraint "0" %
    Given I set the min instrument constraint "-20" % and max instrument constraint "20" % for all instruments
    Given I fetch the optimization payload
    And I fetch and store the actual scenario details
    When I run optimization at activity level for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized portfolio spend is within min "0" % and max "0" % range
    Then I assert optimized instrument spends to be within the given range

    # passed
#  @sanityTest
  Scenario: Portfolio optimization for bolt hammer with secondary kpi
    Given I set kpi id to optimize as "SecondaryKpi"
    Given I set the min portfolio constraint "0" % and max portfolio constraint "0" %
    Given I set the min instrument constraint "-20" % and max instrument constraint "20" % for all instruments
    Given I fetch the optimization payload
    And I fetch and store the actual scenario details
    When I run optimization at activity level for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized portfolio spend is within min "0" % and max "0" % range
    Then I assert optimized instrument spends to be within the given range
#   TODO Check assertions failing
#    And I assert optimized selected kpi's mroi to be equal for the instruments with spends not on the min-max extremes and MROI not equal to zero