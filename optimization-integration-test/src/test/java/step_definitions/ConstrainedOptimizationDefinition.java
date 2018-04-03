package step_definitions;


import builder.MarketDetailsBuilder;
import com.google.inject.Inject;
import cucumber.api.java.en.And;
import cucumber.api.java.en.Given;
import cucumber.api.java.en.Then;
import cucumber.runtime.java.guice.ScenarioScoped;
import data.Kpis;
import data.OptimizeScenario;
import data.ScenarioDetails;
import helper.ConstrainedOptimizationHelper;
import model.*;
import org.apache.commons.lang3.tuple.Pair;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;
import org.junit.Assert;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static java.util.Objects.isNull;
import static java.util.stream.Collectors.toList;
import static org.apache.commons.math3.util.Precision.*;
import static org.hamcrest.Matchers.both;
import static org.hamcrest.Matchers.lessThanOrEqualTo;
import static org.hamcrest.core.Is.is;
import static org.hamcrest.number.OrderingComparison.greaterThanOrEqualTo;
import static org.junit.Assert.assertThat;

@ScenarioScoped
public class ConstrainedOptimizationDefinition {
    private final JSONParser parser;
    private final OptimizeScenario optimizeScenario;
    private final ConstrainedOptimizationHelper constrainedOptimizationHelper;
    private final Kpis kpis;
    private OptimizationContainer optimizationContainer;
    private ScenarioDetails scenarioDetails;
    private UnconstrainedOptimizationContainer unconstrainedOptimizationContainer;
    private JSONObject scenarioToBeOptimized;

    @Inject
    public ConstrainedOptimizationDefinition(OptimizationContainer optimizationContainer,
                                             ScenarioDetails scenarioDetails,
                                             OptimizeScenario optimizeScenario,
                                             UnconstrainedOptimizationContainer unconstrainedOptimizationContainer,
                                             ConstrainedOptimizationHelper constrainedOptimizationHelper,
                                             Kpis kpis) {
        this.optimizationContainer = optimizationContainer;
        this.scenarioDetails = scenarioDetails;
        this.unconstrainedOptimizationContainer = unconstrainedOptimizationContainer;
        this.optimizeScenario = optimizeScenario;
        this.constrainedOptimizationHelper = constrainedOptimizationHelper;
        this.kpis = kpis;
        this.parser = new JSONParser();
    }

    @Given("^I set the min portfolio constraint \"(\\S*)\" % and max portfolio constraint \"(\\S*)\" %$")
    public void buildConstrainedOptimizationPayloadWithPortfolioConstraints(String minConstraint, String maxConstraint) throws Throwable {
        JSONObject portfolioDetails = (JSONObject) ((JSONObject) parser
                .parse(scenarioDetails.fetchConstraints(optimizationContainer.getScenarioId()))).get("portfolioDetails");

        constrainedOptimizationHelper.setPortfolioLevelConstraints(minConstraint, maxConstraint, portfolioDetails,
                getScenarioToBeOptimized());
    }

    @Given("^I fetch the optimization payload$")
    public void iFetchTheOptimizationPayload() throws Throwable {
        optimizationContainer.setOptimizationPayload(getScenarioToBeOptimized().toJSONString());
        PortfolioConstraints constraints = constrainedOptimizationHelper.getConstraintDetails(getScenarioToBeOptimized().toJSONString());
        optimizationContainer.setOptimizationConstraints(constraints);
    }

    @Given("^I set the min market constraint \"(\\S*)\" % and max market constraint \"(\\S*)\" %$")
    public void iFetchTheOptimizationPayloadWithMinMarketConstraintAndMaxMarketConstraint(String minConstraint,
                                                                                          String maxConstraint) throws Throwable {
        JSONArray marketConstraints = (JSONArray) ((JSONObject) parser
                .parse(scenarioDetails.fetchConstraints(optimizationContainer.getScenarioId()))).get
                ("marketDetails");

        constrainedOptimizationHelper.setMarketConstraints(minConstraint, maxConstraint, marketConstraints, getScenarioToBeOptimized());
    }

    @Given("^I set the min instrument constraint \"(\\S*)\" % and max instrument constraint \"(\\S*)\" % for all instruments$")
    public void iSetTheMinInstrumentConstraintAndMaxInstrumentConstraintForAllInstruments(String minConstraint, String maxConstraint) throws Throwable {
        JSONObject scenarioConstraints = (JSONObject) parser
                .parse(scenarioDetails.fetchConstraints(optimizationContainer.getScenarioId()));

        JSONArray marketsConstraint = (JSONArray) scenarioConstraints.get("marketDetails");
        JSONArray marketsDetail = (JSONArray)
                ((JSONObject) getScenarioToBeOptimized().get("currentScenario")).get("markets");

        constrainedOptimizationHelper.setInstrumentLevelConstraintForAllInstruments(minConstraint, maxConstraint,
                marketsConstraint, marketsDetail);
    }

    @Given("^I set the min instrument constraint \"(\\S*)\" % and max instrument constraint \"(\\S*)\" % for first \"" +
            "(\\S*)\" instruments$")
    public void iFetchTheOptimizationPayloadWithMinInstrumentConstraintAndMaxInstrumentConstraintForInstruments
            (String minConstraint, String maxConstraint, String noOfInstruments) throws Throwable {
        JSONArray marketsConstraint = (JSONArray) ((JSONObject) parser
                .parse(scenarioDetails.fetchConstraints(optimizationContainer.getScenarioId()))).get("marketDetails");

        JSONArray marketsDetail = (JSONArray)
                ((JSONObject) getScenarioToBeOptimized().get("currentScenario")).get("markets");

        constrainedOptimizationHelper.setInstrumentLevelConstraintForInstruments(minConstraint, maxConstraint, noOfInstruments,
                marketsConstraint, marketsDetail);
    }

    @Given("^I set the min instrument constraint \"" +
            "(\\S*)\" % and max instrument constraint \"(\\S*)\" % for first \"(\\S*)\" instruments and min " +
            "instrument constraint \"(\\S*)\" % and max instrument constraint \"(\\S*)\" % for remaining instruments$")
    public void
    iFetchTheOptimizationPayloadWithFixedBudgetPortfolioLevelAndMinInstrumentConstraintAndMaxInstrumentConstraintForSomeInstrumentsAndMinAndMaxForRemainingInstruments(String minConstraint1, String maxConstraint1, String noOfInstruments, String minConstraint2, String maxConstraint2) throws Throwable {
        JSONObject scenarioConstraints = (JSONObject) parser
                .parse(scenarioDetails.fetchConstraints(optimizationContainer.getScenarioId()));
        JSONArray marketsConstraint = (JSONArray) scenarioConstraints.get("marketDetails");
        JSONArray marketsDetail = (JSONArray)
                ((JSONObject) getScenarioToBeOptimized().get("currentScenario")).get("markets");

        constrainedOptimizationHelper.setInstrumentLevelConstraintForInstruments(minConstraint1, maxConstraint1,
                noOfInstruments, minConstraint2, maxConstraint2, marketsConstraint, marketsDetail);
    }

    @Then("^I assert optimized portfolio spend is within min \"(\\S*)\" % and max \"(\\S*)\" % range$")
    public void assertThatOptimizedPortfolioSpendIsWithinMinAndMaxRange(String minConstraint, String maxConstraint) throws Throwable {
        Map<String, MarketDetail> optimizedScenarioDetails = optimizationContainer.getOptimizedScenarioDetails();
        Double optimizedScenarioTotalSpends = optimizationContainer.getTotalSpend(optimizedScenarioDetails.values());
        Map<String, MarketDetail> actualScenarioDetails = optimizationContainer.getActualScenarioDetails();
        Double actualScenarioTotalSpends = optimizationContainer.getTotalSpend(actualScenarioDetails.values());
        System.out.println("Actual Total Spend:" + actualScenarioTotalSpends);
        System.out.println("Optimized Total Spend:" + optimizedScenarioTotalSpends);

        Double minPercentage = Double.valueOf(minConstraint);
        Double maxPercentage = Double.valueOf(maxConstraint);
        minPercentage = minPercentage == 0d ? -1 : minPercentage;
        maxPercentage = maxPercentage == 0d ? 1 : maxPercentage;
        Double minAllowedSpend = actualScenarioTotalSpends + actualScenarioTotalSpends * minPercentage * 0.01;
        Double maxAllowedSpend = actualScenarioTotalSpends + actualScenarioTotalSpends * maxPercentage * 0.01;
        assertThat(round(optimizedScenarioTotalSpends, 3),
                is(both(greaterThanOrEqualTo(round(minAllowedSpend, 3))).
                        and(lessThanOrEqualTo(round(maxAllowedSpend, 3))))
        );
    }

    @Then("^I assert optimized market spend is within min \"(\\S*)\" % and max \"(\\S*)\" % range$")
    public void assertThatOptimizedMarketSpendIsWithinMinAndMaxRange(String minConstraint, String maxConstraint)
            throws Throwable {
        Map<String, MarketDetail> optimizedScenarioDetails = optimizationContainer.getOptimizedScenarioDetails();
        Double minPercentage = Double.valueOf(minConstraint);
        Double maxPercentage = Double.valueOf(maxConstraint);
        Double updatedMinPercentage = minPercentage == 0d ? -0.01 : minPercentage;
        Double updatedMaxPercentage = maxPercentage == 0d ? 0.01 : maxPercentage;
        optimizedScenarioDetails.entrySet().forEach(marketDetail -> {
            Double optimizedScenarioMarketSpends = marketDetail.getValue().getAggregatedSpend();
            Double actualScenarioMarketSpends = optimizationContainer.getActualScenarioDetails()
                    .get(marketDetail.getKey())
                    .getAggregatedSpend();

            Double minAllowedSpend = actualScenarioMarketSpends + actualScenarioMarketSpends * updatedMinPercentage * 0.01;
            Double maxAllowedSpend = actualScenarioMarketSpends + actualScenarioMarketSpends * updatedMaxPercentage * 0.01;

            Assert.assertTrue(
                    optimizedScenarioMarketSpends.toString(),
                    maxAllowedSpend > optimizedScenarioMarketSpends
                            && optimizedScenarioMarketSpends > minAllowedSpend
            );
        });
    }

    @And("^I assert optimized selected kpi mroi to be equal for all instruments for each market$")
    public void iAssertOptimizedNetProfitMroiToBeEqualForAllInstrumentsAndMarkets() throws Throwable {
        Map<String, MarketDetail> optimizedScenarioDetails = optimizationContainer.getOptimizedScenarioDetails();
        for (MarketDetail marketDetail : optimizedScenarioDetails.values()) {
            List<Double> allInstrumentNetProfitMroi = marketDetail.getInstrumentDetails().values().stream()
                    .filter(instrumentDetail -> instrumentDetail.getAggregatedSpend() > 0)
                    .map(InstrumentDetail::getSelectedKpiMarginalRoi)
                    .collect(toList());
            Double expectedMroi = allInstrumentNetProfitMroi.get(0);
            allInstrumentNetProfitMroi.forEach(mRoi -> Assert.assertEquals(mRoi, expectedMroi, 0.001));
        }
    }

    @And("^I assert optimized selected kpi's mroi to be equal for all instruments across markets$")
    public void iAssertOptimizedSelectedKpisMroiToBeEqualForAllInstrumentsAcrossMarkets() throws Throwable {
        Map<String, MarketDetail> optimizedScenarioDetails = optimizationContainer.getOptimizedScenarioDetails();
        List<Double> allInstrumentNetProfitMroi = new ArrayList<>();
        for (MarketDetail marketDetail : optimizedScenarioDetails.values()) {
            allInstrumentNetProfitMroi.addAll(marketDetail.getInstrumentDetails().values().stream()
                    .filter(instrumentDetail -> instrumentDetail.getAggregatedSpend() > 0)
                    .map(InstrumentDetail::getSelectedKpiMarginalRoi)
                    .collect(toList()));
        }

        Double expectedMroi = allInstrumentNetProfitMroi.get(0);
         allInstrumentNetProfitMroi.forEach(mRoi -> Assert.assertEquals(mRoi, expectedMroi, 0.001));
    }

    @Then("^I assert optimized market spends greater than zero$")
    public void iAssertOptimizedMarketSpendGreaterThanZero() throws Throwable {
        Map<String, MarketDetail> optimizedScenarioDetails = optimizationContainer.getOptimizedScenarioDetails();
        for (MarketDetail marketDetail : optimizedScenarioDetails.values()) {
            Double aggregatedMarketSpend = marketDetail.getAggregatedSpend();
            Assert.assertTrue(aggregatedMarketSpend.toString(), aggregatedMarketSpend > 0);
        }
    }

    @Then("^I assert optimized selected kpi's mroi to be equal for the instruments with spends not on the min-max extremes and MROI not equal to zero$")
    public void iAssertOptimizedNetProfitMroiToBeEqualForTheInstrumentsWithSpendsNotOnTheMinMaxExtremes() throws Throwable {
        Map<String, MarketDetail> optimizedScenarioDetails = optimizationContainer.getOptimizedScenarioDetails();
        PortfolioConstraints optimizationConstraints = optimizationContainer.getOptimizationConstraints();

        Map<String, MarketConstraints> marketConstraints = optimizationConstraints.getMarketConstraints();


        marketConstraints.entrySet().stream()
                .forEach(marketConstraint -> {
                    MarketDetail optimizedScenarioMarketDetail = optimizedScenarioDetails.get(marketConstraint.getKey());
                    Map<String, InstrumentDetail> instrumentsDetailsInOptimizedScenario =
                            optimizedScenarioMarketDetail.getInstrumentDetails();

                    List<String> filteredInstrumentIds =
                            marketConstraint.getValue().getInstrumentsConstraint().entrySet().stream()
                                    .filter(instrumentConstraint ->
                                    {
                                        InstrumentDetail instrumentDetail = instrumentsDetailsInOptimizedScenario.get(instrumentConstraint.getKey());
                                        return !constrainedOptimizationHelper
                                                .isInstrumentSpendAtExtremesOrMROIIsZero(instrumentConstraint, instrumentDetail);
                                    })
                                    .map(Map.Entry::getKey)
                                    .collect(Collectors.toList());

                    List<InstrumentDetail> filteredInstrumentDetails = instrumentsDetailsInOptimizedScenario.entrySet().stream()
                            .filter(instrumentDetails -> filteredInstrumentIds.contains(instrumentDetails.getKey()))
                            .map(Map.Entry::getValue)
                            .collect(Collectors.toList());

                    constrainedOptimizationHelper.assertAllInstrumentsToHaveEqualMROI(filteredInstrumentDetails);
                });
    }

    @Then("^I assert optimized instrument spends to be within the given range$")
    public void iAssertOptimizedSpendToBeWithinTheGivenRange() throws Throwable {
        Map<String, MarketDetail> optimizedScenarioDetails = optimizationContainer.getOptimizedScenarioDetails();
        PortfolioConstraints optimizationConstraints = optimizationContainer.getOptimizationConstraints();

        Map<String, MarketConstraints> marketConstraints = optimizationConstraints.getMarketConstraints();
        marketConstraints.entrySet().stream()
                .filter(marketConstraint -> marketConstraint.getValue().getId() != null)
                .forEach(marketConstraint -> {
                    MarketDetail optimizedScenarioMarketDetail = optimizedScenarioDetails.get(marketConstraint.getKey());
                    Map<String, InstrumentDetail> instrumentDetails = optimizedScenarioMarketDetail.getInstrumentDetails();

                    marketConstraint.getValue().getInstrumentsConstraint().entrySet().stream()
                            .filter(instrumentConstraint -> instrumentConstraint.getValue().getId() != null)
                            .forEach(instrumentConstraint -> {
                                InstrumentDetail instrumentDetail = instrumentDetails.get(instrumentConstraint.getKey());
                                InstrumentConstraints constraints = instrumentConstraint.getValue();

                                constrainedOptimizationHelper.assertEveryInstrumentSpendWithinMinMaxRange(instrumentDetail, constraints);
                            });
                });
    }

    @Then("^I assert optimized net profit mroi for all instruments with constraints and with optimized spends not on the min-max extremes to be equal$")
    public void iAssertOptimizedNetProfitMroiForTheInstrumentsWithConstraintsAndOptimizedSpendNotOnTheMinMaxExtremes() throws Throwable {
        Map<String, MarketDetail> optimizedScenarioDetails = optimizationContainer.getOptimizedScenarioDetails();
        String optimizationPayload = optimizationContainer.getOptimizationPayload();
        PortfolioConstraints optimizationConstraints = optimizationContainer.getOptimizationConstraints();

        JSONArray marketDetails = (JSONArray) ((JSONObject) ((JSONObject) parser.parse(optimizationPayload)).get
                ("currentScenario")).get("markets");
        marketDetails.forEach(market -> {
            JSONArray instruments = (JSONArray) ((JSONObject) market).get("instruments");
            List<Long> instrumentIdsWithConstraints = constrainedOptimizationHelper.getInstrumentIdsWithConstraints(instruments);

            String marketId = ((JSONObject) market).get("id").toString();
            MarketDetail optimizedScenarioMarketDetail = optimizedScenarioDetails.get(marketId);

            JSONArray instrumentsWithConstraints = new JSONArray();

            ((JSONArray) ((JSONObject) market)
                    .get("instruments"))
                    .forEach(instrument -> {
                        if (instrumentIdsWithConstraints.contains(((JSONObject) instrument).get("id")))
                            instrumentsWithConstraints.add(instrument);
                    });

            Map<String, InstrumentDetail> instrumentsDetailsInOptimizedScenarioMap =
                    optimizedScenarioMarketDetail.getInstrumentDetails()
                            .entrySet()
                            .stream()
                            .filter(map -> instrumentIdsWithConstraints.contains(Long.valueOf(map.getKey())))
                            .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));

            List<InstrumentDetail> filteredInstrumentDetails =
                    constrainedOptimizationHelper.getInstrumentsWhoseSpendsNotAtTheExtremesAndWithNonZeroMROI(
                            instrumentsWithConstraints,
                            instrumentsDetailsInOptimizedScenarioMap);

            constrainedOptimizationHelper.assertAllInstrumentsToHaveEqualMROI(filteredInstrumentDetails);
        });
    }

    @And("^I assert optimized net profit mroi to be zero for unconstrained instruments$")
    public void iAssertOptimizedNetProfitMroiToBeZeroForUnconstrainedInstruments() throws Throwable {
        Map<String, MarketDetail> optimizedScenarioDetails = optimizationContainer.getOptimizedScenarioDetails();
        String optimizationPayload = optimizationContainer.getOptimizationPayload();
        JSONArray marketDetails = (JSONArray) ((JSONObject) ((JSONObject) parser.parse(optimizationPayload)).get
                ("currentScenario")).get("markets");
        marketDetails.forEach(market -> {
            JSONArray instruments = (JSONArray) ((JSONObject) market).get("instruments");
            List<Long> instrumentIdsWithConstraints = constrainedOptimizationHelper.getInstrumentIdsWithConstraints(instruments);
            String marketId = ((JSONObject) market).get("id").toString();
            MarketDetail optimizedScenarioMarketDetail = optimizedScenarioDetails.get(marketId);

            Map<String, InstrumentDetail> instrumentsDetails = optimizedScenarioMarketDetail.getInstrumentDetails();

            List<InstrumentDetail> instrumentDetails = instrumentsDetails.entrySet().stream()
                    .filter(map -> !instrumentIdsWithConstraints.contains(Long.valueOf(map.getKey())))
                    .map(Map.Entry::getValue)
                    .collect(Collectors.toList());
            instrumentDetails
                    .stream()
                    .forEach(instrumentDetail ->
                            Assert.assertTrue(instrumentDetail.getSelectedKpiMarginalRoi().equals(0) ||
                                    (instrumentDetail.getAggregatedSpend().equals(0d))));
        });
    }

    @Then("^I run unconstrained optimization if any of the instrument has zero MROI or instrument spend is zero$")
    public void iRunUnconstrainedOptimization() throws ParseException {
        String optimizationPayload = scenarioDetails.fetch(optimizationContainer.getScenarioId(),
                optimizationContainer.getKpiIdToOptimize());

        Collection<MarketDetail> optimizedMarketDetails = optimizationContainer.getOptimizedScenarioDetails().values();
        boolean shouldRunUnConstraintOptimization = optimizedMarketDetails.stream()
                .anyMatch(branGeo ->
                        branGeo.getInstrumentDetails()
                                .values().stream()
                                .anyMatch(instrument ->
                                        instrument.getSelectedKpiMarginalRoi().equals(0d)
                                                || instrument.getAggregatedSpend().equals(0d)));


        if (!shouldRunUnConstraintOptimization)
            return;

        String optimizedSpends = optimizeScenario.optimize(optimizationPayload);
        optimizedSpends = optimizedSpends.replaceAll("Successfully finished Optimization for ScenarioId: [0-9]+", "");

        Map<String, MarketDetail> marketDetails = MarketDetailsBuilder.build(optimizedSpends);
        unconstrainedOptimizationContainer.setOptimizedScenarioDetails(marketDetails);
    }

    @Then("^I assert optimized spend of instruments with zero MROI to equal optimized instrument spends in unconstrained optimization$")
    public void iAssertOptimizedSpendOfInstrumentsWithZeroMROIToEqualOptimizedInstrumentSpendsInUnconstrainedOptimization() throws Throwable {
        Collection<MarketDetail> optimizedMarketDetails = optimizationContainer.getOptimizedScenarioDetails().values();
        boolean shouldRunUnConstraintOptimization = optimizedMarketDetails.stream()
                .anyMatch(branGeo ->
                        branGeo.getInstrumentDetails()
                                .values().stream()
                                .anyMatch(instrument ->
                                        instrument.getSelectedKpiMarginalRoi().equals(0d)
                                                || instrument.getAggregatedSpend().equals(0d)));


        if (!shouldRunUnConstraintOptimization)
            return;

        Map<String, MarketDetail> unConstrainedOptimisationScenarioDetails = unconstrainedOptimizationContainer
                .getOptimizedScenarioDetails();

        optimizedMarketDetails.stream().forEach(marketDetail -> {
            Map<String, InstrumentDetail> instrumentDetailsFromUnconstrainedOptimization =
                    unConstrainedOptimisationScenarioDetails.get(marketDetail.getId()).getInstrumentDetails();
            List<InstrumentDetail> instrumentWithZeroMROIs = marketDetail.getInstrumentDetails().values().stream()
                    .filter(instrumentDetail -> instrumentDetail.getSelectedKpiMarginalRoi().equals(0d) ||
                            instrumentDetail.getAggregatedSpend().equals(0d))
                    .collect(Collectors.toList());

            instrumentWithZeroMROIs.forEach(instrumentDetail -> {
                Double aggregatedInstrumentSpend =
                        instrumentDetailsFromUnconstrainedOptimization.get(instrumentDetail.getId()).getAggregatedSpend();
                Assert.assertEquals(aggregatedInstrumentSpend, instrumentDetail.getAggregatedSpend(), 0d);
            });
        });
    }

    @And("^I increase/decrease the min/max spend of the constrained instruments by \"(\\S*)\" % with optimised " +
            "spends in the min-max extremes and I assert the net profit returns of optimized scenario to be greater$")
    public void iIncreaseDecreaseTheMinMaxSpendOfTheInstrumentsByWithOptimisedSpendsInTheMinMaxExtremes(String deltaPercentage) throws Throwable {
        Map<String, MarketDetail> optimizedScenarioDetails = optimizationContainer.getOptimizedScenarioDetails();
        PortfolioConstraints optimizationConstraints = optimizationContainer.getOptimizationConstraints();

        Map<String, MarketConstraints> marketConstraints = optimizationConstraints.getMarketConstraints();

        marketConstraints.entrySet().stream()
                .filter(marketConstraint -> marketConstraint.getValue().getId() != null)
                .forEach(marketConstraint -> {
                    String marketId = marketConstraint.getKey();
                    MarketDetail marketInOptimizedScenario = optimizedScenarioDetails.get(marketId);
                    Map<String, InstrumentDetail> instrumentsInOptimizedScenario =
                            marketInOptimizedScenario.getInstrumentDetails();

                    marketConstraint.getValue().getInstrumentsConstraint().entrySet().stream()
                            .filter(instrumentConstraint -> {
                                InstrumentDetail instrumentDetail = instrumentsInOptimizedScenario.get(instrumentConstraint.getKey());
                                return instrumentConstraint.getValue().getId() != null
                                        && constrainedOptimizationHelper
                                        .isInstrumentSpendMinOrMax(instrumentDetail, instrumentConstraint.getValue());

                            })
                            .forEach(instrumentConstraint -> {
                                String instrumentId = instrumentConstraint.getKey();
                                InstrumentConstraints constraints = instrumentConstraint.getValue();
                                Double actualScenarioSpend = constraints.getSpend();
                                InstrumentDetail instrumentDetail = instrumentsInOptimizedScenario.get(instrumentId);
                                Pair<Double, Double> minMaxSpends =
                                        constrainedOptimizationHelper.getMinMaxSpendBasedOnMinMaxConstraint(constraints);
                                Double optimizedSpend = (double) Math.round(instrumentDetail.getAggregatedSpend());

                                if (optimizedSpend.equals(minMaxSpends.getLeft()))
                                    actualScenarioSpend = minMaxSpends.getLeft() + (actualScenarioSpend * Double.valueOf(deltaPercentage) * 0.01);
                                else if (optimizedSpend.equals(minMaxSpends.getRight()))
                                    actualScenarioSpend = minMaxSpends.getRight() - (actualScenarioSpend * Double.valueOf(deltaPercentage) * 0.01);

                                Double updatedNetProfitReturns = constrainedOptimizationHelper.getUpdatedNetProfitReturns(
                                        optimizationContainer.getScenarioId(),
                                        marketId,
                                        instrumentId,
                                        actualScenarioSpend,
                                        optimizationContainer.getKpiIdToOptimize());

                                Double optimizedNetProfitReturns = marketInOptimizedScenario
                                        .getInstrumentDetails().get(instrumentId).getSelectedKpiReturns();

                                Assert.assertTrue(optimizedNetProfitReturns > updatedNetProfitReturns);
                            });
                });
    }

    @Then("^I assert that all Instruments contain either Zero MROI or the aggregated spend is at the extremes there is no when there is no BranGeo Constraint$")
    public void iAssertThatThereIsNoNonZeroMROIForInstrumentLevelConstraint() throws Throwable {
        Map<String, MarketDetail> optimizedScenarioDetails = optimizationContainer.getOptimizedScenarioDetails();
        Map<String, MarketConstraints> marketConstraints =
                optimizationContainer.getOptimizationConstraints().getMarketConstraints();

        marketConstraints.entrySet().stream()
                .filter(marketConstraint -> marketConstraint.getValue().getId() == null)
                .forEach(marketConstraint -> {
                    Map<String, InstrumentDetail> instrumentDetails =
                            optimizedScenarioDetails.get(marketConstraint.getKey()).getInstrumentDetails();
                    Map<String, InstrumentConstraints> instrumentsConstraint =
                            marketConstraint.getValue().getInstrumentsConstraint();

                    boolean isInstrumentsWithNonZeroMROIAndSpendNotInExtremesArePresent = instrumentsConstraint.entrySet().stream()
                            .anyMatch(instrumentConstraint -> {
                                InstrumentDetail instrumentDetail = instrumentDetails.get(instrumentConstraint.getKey());
                                return !constrainedOptimizationHelper
                                        .isInstrumentSpendAtExtremesOrMROIIsZero(instrumentConstraint, instrumentDetail);
                            });

                    Assert.assertFalse(isInstrumentsWithNonZeroMROIAndSpendNotInExtremesArePresent);
                });
    }

    @And("^I assert that optimized instrument spend to be \"([^\"]*)\" % of actual spend$")
    public void iAssertThatOptimizedInstrumentSpendToBeOfActualSpend(String fixedBudgetPercentage) throws Throwable {
        Map<String, MarketDetail> optimizedScenarioDetails = optimizationContainer.getOptimizedScenarioDetails();
        PortfolioConstraints optimizationConstraints = optimizationContainer.getOptimizationConstraints();

        Map<String, MarketConstraints> marketConstraints = optimizationConstraints.getMarketConstraints();
        marketConstraints.entrySet().stream()
                .forEach(marketConstraint -> {
                    MarketDetail optimizedScenarioMarketDetail = optimizedScenarioDetails.get(marketConstraint.getKey());
                    Map<String, InstrumentDetail> instrumentDetails = optimizedScenarioMarketDetail.getInstrumentDetails();

                    marketConstraint.getValue().getInstrumentsConstraint().entrySet().stream()
                            .filter(instrumentConstraint -> instrumentConstraint.getValue().getId() != null)
                            .forEach(instrumentConstraint -> {
                                InstrumentDetail instrumentDetail = instrumentDetails.get(instrumentConstraint.getKey());
                                InstrumentConstraints constraints = instrumentConstraint.getValue();

                                Long originalSpend = Math.round(constraints.getSpend());
                                Double minExpectedSpend = (double) Math.round(
                                        originalSpend + originalSpend * (Double.valueOf(fixedBudgetPercentage)-0.01) * 0.01);
                                Double maxExpectedSpend = (double) Math.round(
                                        originalSpend + originalSpend * (Double.valueOf(fixedBudgetPercentage)+0.01) * 0.01);

                                Double actualSpend = (double) Math.round(instrumentDetail.getAggregatedSpend());
                                assertThat(actualSpend,
                                        is(both(greaterThanOrEqualTo(minExpectedSpend)).
                                                and(lessThanOrEqualTo(maxExpectedSpend))));
                            });
                });
    }

    private JSONObject getScenarioToBeOptimized() throws ParseException {
        if (isNull(this.scenarioToBeOptimized)) {
            this.scenarioToBeOptimized = (JSONObject) parser.parse(this.scenarioDetails
                    .fetch(optimizationContainer.getScenarioId(),
                            optimizationContainer.getKpiIdToOptimize()));
        }
        return scenarioToBeOptimized;
    }

    @Given("^I set kpi id to optimize as \"([^\"]*)\"$")
    public void iSetKpiIdToOptimizeAs(String kpiName) throws Throwable {
        String kpiIdToOptimize = kpis.getKpiId(kpiName);
        optimizationContainer.setKpiIdToOptimize(kpiIdToOptimize);
        setKpIdToOptimize(getScenarioToBeOptimized(), kpiIdToOptimize);
    }

    public void setKpIdToOptimize(JSONObject scenarioToBeOptimized, String kpiIdToOptimize) {
        scenarioToBeOptimized.put("kpiId", kpiIdToOptimize);
    }
}
