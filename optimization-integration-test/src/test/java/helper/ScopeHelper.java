package helper;


import cucumber.runtime.java.guice.ScenarioScoped;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;

@ScenarioScoped
public class ScopeHelper {

    public void excludeActivity(String activityName, JSONObject scenarioToBeOptimized) {
        JSONObject currentScenario = (JSONObject) scenarioToBeOptimized.get("currentScenario");
        JSONArray markets = (JSONArray) currentScenario.get("markets");
        markets.forEach(x -> {
            JSONObject market = (JSONObject) x;
            JSONArray instruments = (JSONArray) market.get("instruments");
            instruments.forEach(y -> {
                JSONObject instrument = (JSONObject) y;
                JSONArray campaigns = (JSONArray) instrument.get("campaigns");
                campaigns.forEach(z -> {
                    JSONObject campaign = (JSONObject) z;
                    JSONArray activities = (JSONArray) campaign.get("activities");
                    activities.forEach(x1 -> {
                        JSONObject activity = (JSONObject) x1;
                        String name = (String) activity.get("name");
                        if (name.equals(activityName)) {
                            activity.put("isInScope", "false");
                            return;
                        }
                    });
                });
            });
        });
    }


}
