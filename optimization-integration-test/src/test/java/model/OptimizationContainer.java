package model;

import cucumber.runtime.java.guice.ScenarioScoped;
import lombok.Getter;
import lombok.Setter;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import java.util.*;

@ScenarioScoped
@Setter
@Getter
public class OptimizationContainer {
    private String optimizedSpends;
    private String scenarioId;
    private String kpiIdToOptimize;
    private String optimizationPayload;
    private boolean optimizeAtActivity;
    private PortfolioConstraints optimizationConstraints;
    private Map<String, MarketDetail> actualScenarioDetails;
    private Map<String, MarketDetail> optimizedScenarioDetails;

    public List<String> getMarketIds() throws ParseException {
        JSONObject scenarioDetailsObj = (JSONObject) new JSONParser().parse(optimizationPayload);
        JSONObject currentScenario = (JSONObject) scenarioDetailsObj.get("currentScenario");
        JSONArray markets = (JSONArray) currentScenario.get("markets");
        List<String> marketIds = new ArrayList<>();
        for (int i = 0; i < markets.size(); i++) {
            marketIds.add(((JSONObject) markets.get(i)).get("id").toString());
        }
        return marketIds;
    }

    public Double getTotalSpend(Collection<MarketDetail> marketDetails) {
        return marketDetails.stream().mapToDouble(MarketDetail::getAggregatedSpend).sum();
    }
}
