package helper;

import com.google.inject.Inject;
import cucumber.runtime.java.guice.ScenarioScoped;
import data.UpdateScenario;
import model.*;
import org.apache.commons.lang3.tuple.ImmutablePair;
import org.apache.commons.lang3.tuple.Pair;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;
import org.junit.Assert;
import util.MathUtils;

import java.text.DecimalFormat;
import java.util.*;
import java.util.stream.Collectors;

@ScenarioScoped
public class ConstrainedOptimizationHelper {

    private final UpdateScenario updateScenario;
    private final DataHelper dataHelper;
    private final JSONParser parser;

    @Inject
    ConstrainedOptimizationHelper(UpdateScenario updateScenario) {
        this.updateScenario = updateScenario;
        this.dataHelper = new DataHelper();
        this.parser = new JSONParser();
    }

    public List<Long> getInstrumentIdsWithConstraints(JSONArray instruments) {
        List<Long> instrumentIdsWithConstraint = new ArrayList<>();
        instruments.forEach(instrument -> {
            JSONObject instrumentDetail = (JSONObject) instrument;
            Object instrumentConstraint = instrumentDetail.get("instrumentConstraints");
            if (instrumentConstraint != null)
                instrumentIdsWithConstraint.add((long) instrumentDetail.get("id"));
        });
        return instrumentIdsWithConstraint;
    }

    public void setPortfolioLevelConstraints(String minConstraint, String maxConstraint, JSONObject portfolioDetails,
                                        JSONObject scenarioToBeOptimized) {
        Double aggregatedSpend = Double.valueOf(portfolioDetails.get("spend").toString());
        Double minSpend = aggregatedSpend + aggregatedSpend * Double.valueOf(minConstraint) * 0.01;
        Double maxSpend = aggregatedSpend + aggregatedSpend * Double.valueOf(maxConstraint) * 0.01;

        ((JSONObject)((JSONObject) scenarioToBeOptimized.get("currentScenario")).get("portFolioConstraints"))
                .put("minSpend", minSpend);
        ((JSONObject)((JSONObject) scenarioToBeOptimized.get("currentScenario")).get("portFolioConstraints"))
                .put("maxSpend", maxSpend);
    }

    public void setMarketConstraints(String minConstraint, String maxConstraint, JSONArray marketConstraints,
                                     JSONObject scenarioToBeOptimized) {
        JSONArray marketsDetail = (JSONArray) (
                (JSONObject) scenarioToBeOptimized.get("currentScenario")
        ).get("markets");

        marketConstraints.forEach(marketConstraint -> {
            JSONObject marketConstraintJson = (JSONObject) marketConstraint;
            Double aggregatedSpend = Double.valueOf(marketConstraintJson.get("spend").toString());
            Double minSpend = aggregatedSpend + aggregatedSpend * Double.valueOf(minConstraint) * 0.01;
            Double maxSpend = aggregatedSpend + aggregatedSpend * Double.valueOf(maxConstraint) * 0.01;
            marketConstraintJson.put("minSpend", minSpend);
            marketConstraintJson.put("maxSpend", maxSpend);
            long marketConstraintId = (long) marketConstraintJson.get("id");

            JSONObject market = (JSONObject) marketsDetail
                    .stream()
                    .filter(marketDetail -> {
                        long marketDetailId = (long) ((JSONObject) marketDetail).get("id");
                        return marketDetailId == marketConstraintId;
                    }).findFirst().get();

            market.put("marketConstraints", marketConstraintJson);
        });
    }

    public void assertAllInstrumentsToHaveEqualMROI(List<InstrumentDetail> instrumentDetails) {
        if (instrumentDetails.isEmpty())
            return;
        Double expectedMroi = instrumentDetails.get(0).getSelectedKpiMarginalRoi();
        instrumentDetails.forEach(instrumentDetail ->
                Assert.assertEquals(expectedMroi, instrumentDetail.getSelectedKpiMarginalRoi(), 0.0001));
    }

    public boolean isInstrumentSpendMinOrMax(Map<String, Pair<Double, Double>> instrumentMinAndMaxSpendsMap,
                                             InstrumentDetail instrumentDetail) {
        if (!instrumentMinAndMaxSpendsMap.containsKey(instrumentDetail.getId())) {
            return false;
        }
        Pair<Double, Double> minMaxSpends = instrumentMinAndMaxSpendsMap.get(instrumentDetail.getId());
        Double aggregatedSpend = (double) Math.round(instrumentDetail.getAggregatedSpend() * 100d) / 100d;
        double minSpend = (double) Math.round(minMaxSpends.getLeft() * 100d) / 100d;
        double maxSpend = (double) Math.round(minMaxSpends.getRight() * 100d) / 100d;
        return aggregatedSpend.equals(minSpend) || aggregatedSpend.equals(
                maxSpend);
    }

    public boolean isInstrumentSpendMinOrMax(
            InstrumentDetail instrumentDetail,
            InstrumentConstraints constraints) {
        Double aggregatedSpend = (double) Math.round(instrumentDetail.getAggregatedSpend() * 100d) / 100d;
        Pair<Double, Double> minMaxSpend = getMinMaxSpendBasedOnMinMaxConstraint(constraints);
        Pair<Double, Double> minMaxSpendWithDeviation = getMinMaxSpendBasedOnMinMaxConstraintWithDeviation(constraints);
        return MathUtils.isBetween(aggregatedSpend, minMaxSpendWithDeviation.getLeft(), minMaxSpend.getLeft())
                || MathUtils.isBetween(aggregatedSpend, minMaxSpend.getRight(), minMaxSpendWithDeviation.getRight());
    }

    public void assertEveryInstrumentSpendWithinMinMaxRange(
            InstrumentDetail instrumentDetail,
            InstrumentConstraints constraints) {
        Double aggregatedSpend = (double) Math.round(instrumentDetail.getAggregatedSpend() * 100d) / 100d;
        Pair<Double, Double> minMaxSpend = getMinMaxSpendBasedOnMinMaxConstraint(constraints);
        Assert.assertTrue(aggregatedSpend >= minMaxSpend.getLeft() && aggregatedSpend <= minMaxSpend.getRight());
    }

    public Pair<Double, Double> getMinMaxSpendBasedOnMinMaxConstraintWithDeviation(Constraints constraints) {
        double deviation = constraints.getSpend() * 0.0001;
        double minSpend = (double) Math.round((constraints.getMinSpend() - deviation)* 100d) / 100d;
        double maxSpend = (double) Math.round((constraints.getMaxSpend() + deviation)* 100d) / 100d;
        return new ImmutablePair<>(minSpend, maxSpend);
    }

    public Pair<Double, Double> getMinMaxSpendBasedOnMinMaxConstraint(Constraints constraints) {
        double minSpend = (double) Math.round((constraints.getMinSpend())* 100d) / 100d;
        double maxSpend = (double) Math.round((constraints.getMaxSpend())* 100d) / 100d;
        return new ImmutablePair<>(minSpend, maxSpend);
    }

    private void setInstrumentLevelConstraint(String minConstraint, String maxConstraint,
                                              JSONArray instrumentLevelConstraints,
                                              JSONArray marketInstrumentDetails) {
        marketInstrumentDetails.forEach(marketInstrument -> {
            long instrumentId = (long) ((JSONObject) marketInstrument).get("id");
            JSONObject instrument = (JSONObject) instrumentLevelConstraints.stream().filter(instrumentConstraint -> {
                long instrumentConstraintId = (long) ((JSONObject) instrumentConstraint).get("id");
                return instrumentConstraintId == instrumentId;
            }).findFirst().get();
            Double aggregatedSpend = Double.valueOf(instrument.get("spend").toString());
            Double minSpend = aggregatedSpend + aggregatedSpend * Double.valueOf(minConstraint) * 0.01;
            Double maxSpend = aggregatedSpend + aggregatedSpend * Double.valueOf(maxConstraint) * 0.01;
            instrument.put("minSpend", minSpend);
            instrument.put("maxSpend", maxSpend);

            ((JSONObject) marketInstrument).put("instrumentConstraints", instrument);
        });
    }

    public Map<String, Pair<Double, Double>> getInstrumentMinAndMaxSpendsMap(JSONArray instrumentDetails) {
        Map<String, Pair<Double, Double>> instrumentMinAndMaxSpends = new HashMap<>();

        instrumentDetails.forEach(instrumentDetail -> {
            JSONObject instrumentDetailObj = (JSONObject) instrumentDetail;
            String instrumentId = instrumentDetailObj.get("id").toString();
            JSONObject instrumentConstraints = (JSONObject) instrumentDetailObj.getOrDefault("instrumentConstraints", "");

            if (instrumentDetailObj.get("instrumentConstraints") != null) {
                Double minSpend = Double.valueOf(instrumentConstraints.get("minSpend").toString());
                Double maxSpend = Double.valueOf(instrumentConstraints.get("maxSpend").toString());
                instrumentMinAndMaxSpends.put(instrumentId, new ImmutablePair<>(minSpend, maxSpend));
            }
        });
        return instrumentMinAndMaxSpends;
    }

    public void setInstrumentLevelConstraintForInstruments(String minConstraint, String maxConstraint, String
            noOfInstrument, JSONArray marketConstraints, JSONArray marketsDetail) {
        marketConstraints.forEach(marketConstraint -> {
            JSONArray instrumentConstraints = (JSONArray) ((JSONObject) marketConstraint).get("childConstraints");
            JSONArray marketInstrumentsDetail = (JSONArray)
                    ((JSONObject) marketsDetail.stream().filter(marketDetails -> {
                        long marketDetailId = (long) ((JSONObject) marketDetails).get("id");
                        long marketConstraintId = (long) ((JSONObject) marketConstraint).get("id");
                        return marketConstraintId == marketDetailId;
                    }).findFirst().get()).get("instruments");

            JSONArray marketInstruments = new JSONArray();

            for(int i=0; i < Integer.parseInt(noOfInstrument); i++) {
                marketInstruments.add(marketInstrumentsDetail.get(i));
            }

            setInstrumentLevelConstraint(minConstraint, maxConstraint, instrumentConstraints, marketInstruments);
        });
    }

    public void setInstrumentLevelConstraintForAllInstruments(String minConstraint, String maxConstraint,
                                                                     JSONArray marketConstraints,
                                                                     JSONArray marketsDetail) {
        marketConstraints.forEach(marketConstraint -> {
            JSONArray instrumentConstraints = (JSONArray) ((JSONObject) marketConstraint).get("childConstraints");
            JSONArray marketInstrumentsDetail = (JSONArray)
                    ((JSONObject) marketsDetail.stream().filter(marketDetails -> {
                        long marketDetailId = (long) ((JSONObject) marketDetails).get("id");
                        long marketConstraintId = (long) ((JSONObject) marketConstraint).get("id");
                        return marketConstraintId == marketDetailId;
                    }).findFirst().get()).get("instruments");

            setInstrumentLevelConstraint(minConstraint, maxConstraint, instrumentConstraints, marketInstrumentsDetail);
        });
    }

    public void setInstrumentLevelConstraintForInstruments(String minConstraint1, String maxConstraint1, String noOfInstruments, String minConstraint2, String maxConstraint2, JSONArray marketConstraints, JSONArray marketsDetail) {
        marketConstraints.forEach(marketConstraint -> {
            JSONArray instrumentConstraints = (JSONArray) ((JSONObject) marketConstraint).get("childConstraints");
            JSONArray marketInstrumentsDetail = (JSONArray)
                    ((JSONObject) marketsDetail.stream().filter(marketDetails -> {
                        long marketDetailId = (long) ((JSONObject) marketDetails).get("id");
                        long marketConstraintId = (long) ((JSONObject) marketConstraint).get("id");
                        return marketConstraintId == marketDetailId;
                    }).findFirst().get()).get("instruments");

            JSONArray marketFirstSetOfInstruments = new JSONArray();

            for(int i=0; i< Integer.parseInt(noOfInstruments); i++) {
                marketFirstSetOfInstruments.add(marketInstrumentsDetail.get(i));
            }

            setInstrumentLevelConstraint(minConstraint1, maxConstraint1, instrumentConstraints, marketFirstSetOfInstruments);
            JSONArray remainingInstruments = new JSONArray();
            remainingInstruments.addAll((Collection) marketInstrumentsDetail.stream().filter(instrumentDetails ->
                    !marketFirstSetOfInstruments.contains(instrumentDetails)).collect(Collectors.toSet()));
            setInstrumentLevelConstraint(minConstraint2, maxConstraint2, instrumentConstraints, remainingInstruments);
        });
    }

    public List<InstrumentDetail> getInstrumentsWhoseSpendsNotAtTheExtremesAndWithNonZeroMROI(
            JSONArray instrumentDetailsFromOptimizationPayload,
            Map<String, InstrumentDetail> instrumentDetailWithConstraintsMap) {

        Map<String, Pair<Double, Double>> instrumentMinAndMaxSpendsMap =
                getInstrumentMinAndMaxSpendsMap(instrumentDetailsFromOptimizationPayload);

        return instrumentDetailWithConstraintsMap.values().stream()
                .filter(instrumentDetail ->
                        !isInstrumentSpendMinOrMax(instrumentMinAndMaxSpendsMap, instrumentDetail) &&
                                (!(isInstrumentMROIOrSpendIsZero(instrumentDetail))))
                .collect(Collectors.toList());
    }

    public Double getUpdatedNetProfitReturns(String scenarioId, String marketId, String instrumentId, Double actualScenarioSpend, String kpiId) {
        String response = updateScenario.updateInstrumentSpend(scenarioId, marketId, instrumentId, actualScenarioSpend);
        JSONObject instrumentObj = dataHelper.parseToJsonObject(response);
        Map<String, InstrumentDetail> instrumentsDetail = dataHelper.getInstrumentsDetails(kpiId, instrumentObj);
        return instrumentsDetail.get(instrumentId).getSelectedKpiReturns();
    }

    public PortfolioConstraints getConstraintDetails(String optimizationPayload) throws ParseException {
        JSONObject currentScenario = (JSONObject)
                ((JSONObject) parser.parse(optimizationPayload)).get("currentScenario");
        JSONObject portfolioConstraintPayload = (JSONObject) currentScenario.get("portFolioConstraints");
        JSONArray markets = (JSONArray) currentScenario.get("markets");

        PortfolioConstraints portfolioConstraints = new PortfolioConstraints();
        Long currentScenarioId = (Long) currentScenario.get("scenarioId");
        portfolioConstraints.setId(currentScenarioId);
        setConstraints(portfolioConstraintPayload, portfolioConstraints);

        Map<String, MarketConstraints> marketConstraintsMap = new HashMap<>();
        markets.forEach(market -> {
            JSONObject marketPayload = (JSONObject) market;
            JSONObject marketConstraintsPayload = (JSONObject) marketPayload.get("marketConstraints");
            String marketId = marketPayload.get("id").toString();

            MarketConstraints marketConstraints = new MarketConstraints();
            setConstraints(marketConstraintsPayload, marketConstraints);
            marketConstraintsMap.put(marketId, marketConstraints);

            JSONArray instruments = (JSONArray) marketPayload.get("instruments");
            Map<String, InstrumentConstraints> instrumentConstraintsMap = new HashMap<>();
            instruments.forEach(instrument -> {
                JSONObject instrumentPayload = (JSONObject) instrument;
                JSONObject instrumentConstraintsPayload = (JSONObject) instrumentPayload.get("instrumentConstraints");
                InstrumentConstraints instrumentConstraints = new InstrumentConstraints();
                String instrumentId = instrumentPayload.get("id").toString();
                setConstraints(instrumentConstraintsPayload, instrumentConstraints);
                instrumentConstraintsMap.put(instrumentId, instrumentConstraints);

                Map<String, ActivityConstraints> activityConstraintsMap = new HashMap<>();
                JSONArray campaigns = (JSONArray) instrumentPayload.get("campaigns");
                campaigns.forEach(campaign -> {
                    JSONArray activities = (JSONArray) ((JSONObject) campaign).get("activities");
                    activities.forEach(activity -> {
                        JSONObject activityPayload = (JSONObject) activity;
                        JSONObject activityConstraintsPayload = (JSONObject) activityPayload.get("activityConstraints");
                        ActivityConstraints activityConstraints = new ActivityConstraints();
                        String activityId = activityPayload.get("activityId").toString();
                        setConstraints(activityConstraintsPayload, activityConstraints);
                        activityConstraintsMap.put(activityId, activityConstraints);
                    });
                });
                instrumentConstraints.setActivityConstraints(activityConstraintsMap);
            });
            marketConstraints.setInstrumentsConstraint(instrumentConstraintsMap);
        });
        portfolioConstraints.setMarketConstraints(marketConstraintsMap);
        return portfolioConstraints;
    }

    public boolean isInstrumentSpendAtExtremesOrMROIIsZero(Map.Entry<String, InstrumentConstraints> instrumentConstraint,
                                                           InstrumentDetail instrumentDetail) {
        return ((instrumentConstraint.getValue().getId() != null &&
                isInstrumentSpendMinOrMax(instrumentDetail, instrumentConstraint.getValue()))
                || isInstrumentMROIOrSpendIsZero(instrumentDetail));
    }

    private boolean isInstrumentMROIOrSpendIsZero(InstrumentDetail instrumentDetail) {
        DecimalFormat formatter = new DecimalFormat("#0.####");
        Double netProfitMarginalRoi = Math.abs(
                Double.valueOf(formatter.format(instrumentDetail.getSelectedKpiMarginalRoi())));
        return (netProfitMarginalRoi.equals(0d)
                || instrumentDetail.getAggregatedSpend().equals(0d));
    }

    private void setConstraints(JSONObject constraintPayload, Constraints constraints) {
        if (constraintPayload != null) {
            constraints.setMaxSpend((Double) constraintPayload.get("maxSpend"));
            constraints.setMinSpend((Double) constraintPayload.get("minSpend"));
            constraints.setSpend((Double) constraintPayload.get("spend"));
            constraints.setMaxConstraint((String) constraintPayload.get("maxConstraint"));
            constraints.setMinConstraint((String) constraintPayload.get("minConstraint"));
            constraints.setName((String) constraintPayload.get("name"));
            constraints.setId((Long) constraintPayload.get("id"));
        }
    }
}
