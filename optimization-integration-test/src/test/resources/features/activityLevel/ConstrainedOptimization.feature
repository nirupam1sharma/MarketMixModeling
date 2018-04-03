Feature: Constrained optimization at Activity Level

  Background:
    Given I upload dimensions "BarlandHammerDimensions.csv"
    Given I upload calendar "BarlandHammerCalendar.csv"
    Given I upload model "BarlandHammerCurves.csv"
    Given I upload media cost "BarlandHammerMediaCost.csv"
    Given I upload secondary kpi params "BarlandHammerParams.csv" and setup secondary kpi "BarlandHammerWithMultipleKpiFormula.csv"
    Given I setup tertiary kpi "Net Profit" with first secondary kpi
    Given I upload previous year spend "BarlandHammerPreviousSpend.csv"
    Given I upload current year plan "BarlandHammerCurrentSpend.csv"

    # failing - passed
  Scenario: Portfolio optimization for bolt hammer with Instrument Level Constraints for few instruments and with Market Level Constraint
    Given I set the min market constraint "-20" % and max market constraint "40" %
    Given I set the min instrument constraint "-20" % and max instrument constraint "40" % for first "2" instruments
    Given I fetch the optimization payload
    Given I fetch and store the actual scenario details
    When I run optimization at activity level for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized market spends greater than zero
    Then I assert optimized market spend is within min "-20" % and max "40" % range
    Then I assert optimized instrument spends to be within the given range
    Then I run unconstrained optimization if any of the instrument has zero MROI or instrument spend is zero
    Then I assert optimized spend of instruments with zero MROI to equal optimized instrument spends in unconstrained optimization
    And I increase/decrease the min/max spend of the constrained instruments by "10" % with optimised spends in the min-max extremes and I assert the net profit returns of optimized scenario to be greater

    # passed
  Scenario: Portfolio optimization for bolt hammer with Instrument Level Constraints for few instruments
    Given I set the min instrument constraint "-20" % and max instrument constraint "40" % for first "2" instruments
    Given I fetch the optimization payload
    Given I fetch and store the actual scenario details
    When I run optimization at activity level for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized market spends greater than zero
    Then I assert optimized instrument spends to be within the given range
    Then I assert optimized net profit mroi to be zero for unconstrained instruments
    Then I run unconstrained optimization if any of the instrument has zero MROI or instrument spend is zero
    And I assert optimized spend of instruments with zero MROI to equal optimized instrument spends in unconstrained optimization

    #  passed
  Scenario: Portfolio optimization for bolt hammer with Portfolio level constraint and Market level constraint
    Given I set the min portfolio constraint "-20" % and max portfolio constraint "20" %
    Given I set the min market constraint "-10" % and max market constraint "20" %
    Given I fetch the optimization payload
    Given I fetch and store the actual scenario details
    When I run optimization at activity level for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized portfolio spend is within min "-20" % and max "20" % range
    Then I assert optimized market spends greater than zero
    And I assert optimized market spend is within min "-10.01" % and max "20.01" % range

    #  failing
  Scenario: Portfolio optimization for bolt hammer with Portfolio level constraint, Market level constraint and Instrument level constraint
    Given I set the min portfolio constraint "-30" % and max portfolio constraint "30" %
    Given I set the min market constraint "-20" % and max market constraint "20" %
    Given I set the min instrument constraint "-5" % and max instrument constraint "5" % for all instruments
    Given I fetch the optimization payload
    Given I fetch and store the actual scenario details
    When I run optimization at activity level for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized portfolio spend is within min "-30" % and max "30" % range
    Then I assert optimized market spends greater than zero
    Then I assert optimized market spend is within min "-20" % and max "20" % range
    Then I assert optimized instrument spends to be within the given range

    # failing - passing
  Scenario: Portfolio optimization for bolt hammer with Portfolio level constraint and Instrument level constraint
    Given I set the min portfolio constraint "-20" % and max portfolio constraint "20" %
    Given I set the min instrument constraint "-5" % and max instrument constraint "5" % for all instruments
    Given I fetch the optimization payload
    Given I fetch and store the actual scenario details
    When I run optimization at activity level for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized portfolio spend is within min "-20" % and max "20" % range
    Then I assert optimized instrument spends to be within the given range