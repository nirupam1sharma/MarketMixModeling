package data;

import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.jayway.restassured.response.Response;
import helper.DataHelper;

import static com.jayway.restassured.RestAssured.given;
import static java.lang.String.*;

@Singleton
public class Kpis {

    private final SimulationApi simulationApi;
    private final DataHelper dataHelper;

    @Inject
    public Kpis(SimulationApi simulationApi){
        this.simulationApi = simulationApi;
        this.dataHelper = new DataHelper();
    }

    public String getKpiId(String kpiName) {
        simulationApi.loadProperties();
        Response response = given()
                .header("username", "servicetest")
                .contentType("application/json")
                .when()
                .get(format("/api/kpis?types=secondary,tertiary"));

        String kpisString = response.getBody().asString();
        String kpiId = dataHelper.getKpiId(kpisString, kpiName);
        response.then().assertThat().statusCode(200);
        return kpiId;
    }
}
