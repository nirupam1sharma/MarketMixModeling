package builder;

import com.google.inject.Inject;
import cucumber.runtime.java.guice.ScenarioScoped;
import data.Market;
import model.MarketDetail;
import model.InstrumentDetail;
import model.OptimizationContainer;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@ScenarioScoped
public class MarketDetailsBuilder {

    private final Market market;
    private final OptimizationContainer optimizationContainer;

    @Inject
    public MarketDetailsBuilder(Market market, OptimizationContainer optimizationContainer) {
        this.market = market;
        this.optimizationContainer = optimizationContainer;
    }

    public Map<String, MarketDetail> build() throws ParseException {
        List<String> marketIds = optimizationContainer.getMarketIds();
        String kpiId = optimizationContainer.getKpiIdToOptimize();
        String scenarioId = optimizationContainer.getScenarioId();
        return marketIds.stream().map(market1 ->
                this.market.fetchDetails(scenarioId, market1, kpiId))
                .collect(Collectors.toMap(MarketDetail::getId, marketDetail -> marketDetail));
    }

    public static Map<String, MarketDetail> build(String optimizationResult) throws ParseException {
        Map<String, MarketDetail> marketDetailMap = new HashMap<>();
        JSONParser jsonParser = new JSONParser();
        JSONArray spends = (JSONArray) jsonParser.parse(optimizationResult);
        spends.forEach(spendEntry -> {
            JSONObject spendObj = (JSONObject) spendEntry;
            String marketId = spendObj.get("marketId").toString();
            String instrumentId = spendObj.get("instrumentId").toString();
            Double weeklySpends = Double.valueOf(spendObj.get("weeklySpends").toString());
            if(!marketDetailMap.containsKey(marketId)) {
                marketDetailMap.put(marketId, new MarketDetail(marketId));
            }
            MarketDetail marketDetail = marketDetailMap.get(marketId);
            if(!marketDetail.getInstrumentDetails().containsKey(instrumentId)) {
                marketDetail.getInstrumentDetails().put(instrumentId, new InstrumentDetail(instrumentId));
            }
            InstrumentDetail instrumentDetail = marketDetail.getInstrumentDetails().get(instrumentId);
            instrumentDetail.addToAggregatedSpend(weeklySpends);
        });
        marketDetailMap.values().stream().forEach(MarketDetail::aggregateInstrumentSpend);
        return marketDetailMap;
    }
}
