package data;

import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.jayway.restassured.response.Response;
import helper.DataHelper;
import model.MarketDetail;

import static com.jayway.restassured.RestAssured.given;

@Singleton
public class Market {

    private final SimulationApi simulationApi;
    private final DataHelper dataHelper;

    @Inject
    public Market(SimulationApi simulationApi) {
        this.simulationApi = simulationApi;
        this.dataHelper = new DataHelper();
    }

    public MarketDetail fetchDetails(String scenarioId, String marketId, String kpiId) {
        simulationApi.loadProperties();
        Response response = given()
                .header("username", "servicetest")
                .contentType("application/json")
                .when()
                .get(String.format("/api/scenario/%s/campaigns?marketId=%s", scenarioId, marketId));

        String marketDetailString = response.getBody().asString();
        response.then().assertThat().statusCode(200);
        return dataHelper.getMarketDetail(marketDetailString, kpiId);
    }
}
