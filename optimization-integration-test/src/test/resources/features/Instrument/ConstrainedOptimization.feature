Feature: Constrained optimization at Instrument Level

  Background:
    Given I upload dimensions "BaileysDimensions.csv"
    Given I upload calendar "BaileysCalendar.csv"
    Given I upload model "BaileysModel.csv"
    Given I upload media cost "BaileysMediaCost.csv"
    Given I upload secondary kpi params "BaileysSecondaryKpiWeeklyMetrics.csv" and setup secondary kpi "BaileysMarketKpiFormula.csv"
    Given I setup tertiary kpi "Net Profit" with first secondary kpi
    Given I upload previous year spend "BaileysHistoricalSpend.csv"
    Given I upload current year plan "BaileysPlanPeriodSpend.csv"

    # passing
  Scenario: Portfolio optimization for baileys with Portfolio level constraint
    Given I set the min portfolio constraint "-20" % and max portfolio constraint "20" %
    Given I fetch the optimization payload
    Given I fetch and store the actual scenario details
    When I run optimization for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized portfolio spend is within min "-20" % and max "20" % range
    And I assert optimized selected kpi's mroi to be equal for all instruments across markets

    # failing - passing
  Scenario: Portfolio optimization for baileys with Market Level Constraint
    Given I set the min market constraint "-20" % and max market constraint "40" %
    Given I fetch the optimization payload
    Given I fetch and store the actual scenario details
    When I run optimization for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized market spends greater than zero
    Then I assert optimized market spend is within min "-20" % and max "40" % range
    And I assert optimized selected kpi mroi to be equal for all instruments for each market

    # failing - passing
  Scenario: Portfolio optimization for baileys with Instrument Level Constraints for few instruments and with Market Level Constraint
    Given I set the min market constraint "-20" % and max market constraint "40" %
    Given I set the min instrument constraint "-20" % and max instrument constraint "40" % for first "3" instruments
    Given I fetch the optimization payload
    Given I fetch and store the actual scenario details
    When I run optimization for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized market spends greater than zero
    Then I assert optimized market spend is within min "-20" % and max "40" % range
    Then I assert optimized instrument spends to be within the given range
    Then I assert optimized selected kpi's mroi to be equal for the instruments with spends not on the min-max extremes and MROI not equal to zero
    Then I run unconstrained optimization if any of the instrument has zero MROI or instrument spend is zero
    Then I assert optimized spend of instruments with zero MROI to equal optimized instrument spends in unconstrained optimization
    And I increase/decrease the min/max spend of the constrained instruments by "10" % with optimised spends in the min-max extremes and I assert the net profit returns of optimized scenario to be greater

    # passed
  Scenario: Portfolio optimization for baileys with Instrument Level Constraints for few instruments
    Given I set the min instrument constraint "-20" % and max instrument constraint "40" % for first "3" instruments
    Given I fetch the optimization payload
    Given I fetch and store the actual scenario details
    When I run optimization for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized market spends greater than zero
    Then I assert optimized instrument spends to be within the given range
    Then I assert optimized selected kpi's mroi to be equal for the instruments with spends not on the min-max extremes and MROI not equal to zero
    Then I assert that all Instruments contain either Zero MROI or the aggregated spend is at the extremes there is no when there is no BranGeo Constraint
    Then I assert optimized net profit mroi to be zero for unconstrained instruments
    Then I run unconstrained optimization if any of the instrument has zero MROI or instrument spend is zero
    And I assert optimized spend of instruments with zero MROI to equal optimized instrument spends in unconstrained optimization

    # failing - passing
  Scenario: Portfolio optimization for baileys with Portfolio level constraint and Market level constraint
    Given I set the min portfolio constraint "-20" % and max portfolio constraint "20" %
    Given I set the min market constraint "-10" % and max market constraint "20" %
    Given I fetch the optimization payload
    Given I fetch and store the actual scenario details
    When I run optimization for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized portfolio spend is within min "-20" % and max "20" % range
    Then I assert optimized market spends greater than zero
    Then I assert optimized market spend is within min "-10" % and max "20" % range
    And I assert optimized selected kpi mroi to be equal for all instruments for each market


    # passing
  Scenario: Portfolio optimization for baileys with Portfolio level constraint, Market level constraint and Instrument level constraint
    Given I set the min portfolio constraint "-30" % and max portfolio constraint "30" %
    Given I set the min market constraint "-20" % and max market constraint "20" %
    Given I set the min instrument constraint "-5" % and max instrument constraint "5" % for all instruments
    Given I fetch the optimization payload
    Given I fetch and store the actual scenario details
    When I run optimization for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized portfolio spend is within min "-30" % and max "30" % range
    Then I assert optimized market spends greater than zero
    Then I assert optimized market spend is within min "-20" % and max "20" % range
    Then I assert optimized instrument spends to be within the given range


    # passed
  Scenario: Portfolio optimization for baileys with Portfolio level constraint and Instrument level constraint
    Given I set the min portfolio constraint "-20" % and max portfolio constraint "20" %
    Given I set the min instrument constraint "-5" % and max instrument constraint "5" % for all instruments
    Given I fetch the optimization payload
    Given I fetch and store the actual scenario details
    When I run optimization for the scenario
    And I updated the scenario with optimized spends
    And I fetch and store optimized scenario details
    Then I assert optimized portfolio spend greater than zero
    Then I assert optimized portfolio spend is within min "-20" % and max "20" % range
    Then I assert optimized instrument spends to be within the given range