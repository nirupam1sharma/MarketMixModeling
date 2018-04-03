package helper;

import model.ActivityDetail;
import model.MarketDetail;
import model.InstrumentDetail;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class DataHelper {

    public Double getTotalSpendForActivity(Map<String, MarketDetail> scenarioDetails, String activityName) {
        for (MarketDetail marketDetail : scenarioDetails.values()) {
            Map<String, InstrumentDetail> instrumentDetails = marketDetail.getInstrumentDetails();
            for (InstrumentDetail instrumentDetail : instrumentDetails.values()) {
                List<ActivityDetail> activityDetails = instrumentDetail.getActivityDetails();
                for (ActivityDetail activityDetail : activityDetails) {
                    if (activityDetail.getName().equals(activityName))
                        return activityDetail.getTotalSpends();
                }
            }
        }
        return 0.0D;
    }

    public MarketDetail getMarketDetail(String marketDetail, String kpiId) {
        JSONObject marketDetailObj = parseToJsonObject(marketDetail);

        Map<String, InstrumentDetail> allInstrumentDetails = getInstrumentsDetails(kpiId, marketDetailObj);
        JSONObject netProfitKpiDetails = getKpiDetails(kpiId, (JSONArray) marketDetailObj.get
                ("aggregatedImpacts"));
        Double marketMRoi = getMarginalRoi(netProfitKpiDetails);
        Double marketReturns = getReturns(netProfitKpiDetails);
        String marketId = marketDetailObj.get("marketId").toString();
        return new MarketDetail(marketId, getAggregatedWorkingSpends(marketDetailObj), marketMRoi, marketReturns,
                getRoi(netProfitKpiDetails), allInstrumentDetails);
    }

    public Map<String, InstrumentDetail> getInstrumentsDetails(String kpiId, JSONObject marketDetailObj) {
        JSONArray instrumentDetails = (JSONArray) marketDetailObj.get("instrumentDetails");
        Map<String, InstrumentDetail> allInstrumentDetails = new HashMap<>();
        instrumentDetails.forEach(instrumentDetailObj -> {
            JSONObject instrumentDetail = (JSONObject) instrumentDetailObj;
            Double aggregatedSpend = getAggregatedWorkingSpends(instrumentDetail);
            JSONArray aggregatedImpacts = (JSONArray) instrumentDetail.get("aggregatedImpacts");
            String instrId = instrumentDetail.get("id").toString();
            JSONObject kpiDetails = getKpiDetails(kpiId, aggregatedImpacts);
            List<ActivityDetail> activityDetails = getActivityDetails((JSONArray) instrumentDetail.get("activityDetails"));
            allInstrumentDetails.put(instrId, new InstrumentDetail(instrId, aggregatedSpend, getMarginalRoi
                    (kpiDetails), getReturns(kpiDetails), getRoi(kpiDetails), activityDetails));
        });
        return allInstrumentDetails;
    }

    private List<ActivityDetail> getActivityDetails(JSONArray activityDetails) {
        ArrayList<ActivityDetail> details = new ArrayList<>();
        activityDetails.forEach(x -> {
            JSONObject activityDetail = (JSONObject) x;
            JSONObject activity = (JSONObject) activityDetail.get("activity");
            Long id = (Long) activity.get("activityId");
            String name = (String) activity.get("name");
            Double totalSpends = (Double) activity.get("totalSpends");
            details.add(new ActivityDetail(id, name, totalSpends));
        });
        return details;
    }

    private Double getReturns(JSONObject kpiDetails) {
        return Double.valueOf(kpiDetails.get("returns").toString());
    }

    private Double getAggregatedWorkingSpends(JSONObject jsonObject) {
        JSONObject aggregatedSpends = (JSONObject) jsonObject.get("aggregatedSpends");
        return Double.valueOf(aggregatedSpends.get("workingSpends").toString());
    }

    private Double getMarginalRoi(JSONObject kpiDetails) {
        return Double.valueOf(kpiDetails.get("marginalROI").toString());
    }

    private Double getRoi(JSONObject kpiDetails) {
        return Double.valueOf(kpiDetails.get("roiWithTotalSpends").toString());
    }

    private JSONObject getKpiDetails(String kpiId, JSONArray aggregatedImpacts) {
        return (JSONObject) aggregatedImpacts.stream().filter(x -> ((JSONObject) x).get("kpiId")
                .toString().equals(kpiId)).findFirst().get();
    }

    public String getKpiId(String kpisString, String kpiName) {
        JSONArray kpis = parseToJsonArray(kpisString);
        JSONObject kpi = (JSONObject) kpis.stream()
                .filter(kpiObj -> ((JSONObject)kpiObj).get("name").toString().equals(kpiName))
                .findFirst().get();
        return kpi.get("id").toString();
    }

    public JSONObject parseToJsonObject(String string) {
        try {
            return  (JSONObject) new JSONParser().parse(string);
        } catch (ParseException e) {
            return null;
        }
    }

    public JSONArray parseToJsonArray(String string) {
        try {
            return  (JSONArray) new JSONParser().parse(string);
        } catch (ParseException e) {
            return null;
        }
    }
}
