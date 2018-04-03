Feature: Constrained optimization with fixed budget constraints at Instrument Level

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
  Scenario: Portfolio optimization for bolt hammer with fixed budget
    Given I set the min portfolio constraint "0" % and max portfolio constraint "0" %
    Given I fetch the optimization payload
    Given I fetch and store the actual scenario details
    When I run optimization for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized portfolio spend is within min "0" % and max "0" % range
    And I assert optimized selected kpi's mroi to be equal for all instruments across markets

    # passed - fast
  @sanityTest
  Scenario: Portfolio optimization for bolt hammer with fixed budget and different Instrument Level Constraints
    Given I set the min portfolio constraint "0" % and max portfolio constraint "0" %
    Given I set the min instrument constraint "-10" % and max instrument constraint "10" % for first "1" instruments and min instrument constraint "-30" % and max instrument constraint "30" % for remaining instruments
    Given I fetch the optimization payload
    Given I fetch and store the actual scenario details
    When I run optimization for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized instrument spends to be within the given range
    And I assert optimized selected kpi's mroi to be equal for the instruments with spends not on the min-max extremes and MROI not equal to zero

    # passed
  Scenario: Portfolio optimization for bolt hammer having fixed budget Constraint for few instruments
    Given I set the min instrument constraint "10" % and max instrument constraint "10" % for first "1" instruments
    Given I fetch the optimization payload
    Given I fetch and store the actual scenario details
    When I run optimization for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized market spends greater than zero
    And I assert that optimized instrument spend to be "10" % of actual spend

    # passed
  @sanityTest
  Scenario: Portfolio optimization for bolt hammer having fixed budget Constraint for few instruments and fixed budget at market level
    Given I set the min market constraint "0" % and max market constraint "0" %
    Given I set the min instrument constraint "10" % and max instrument constraint "10" % for first "1" instruments
    Given I fetch the optimization payload
    Given I fetch and store the actual scenario details
    When I run optimization for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized market spends greater than zero
    Then I assert optimized market spend is within min "0" % and max "0" % range
    And I assert that optimized instrument spend to be "10" % of actual spend