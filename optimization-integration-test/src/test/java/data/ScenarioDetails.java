package data;

import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.jayway.restassured.response.Response;
import model.OptimizationContainer;
import org.json.simple.parser.ParseException;

import static com.jayway.restassured.RestAssured.given;
import static java.lang.String.format;

@Singleton
public class ScenarioDetails {

    private final SimulationApi simulationApi;

    @Inject
    public ScenarioDetails(SimulationApi simulationApi){
        this.simulationApi = simulationApi;
    }

    public String fetch(String scenarioId, String kpiId) throws ParseException {
        simulationApi.loadProperties();
        String constraints = given()
                .header("username", "servicetest")
                .contentType("application/json")
                .get(format("api/scenarios/%s/constraints", scenarioId)).getBody().asString();

        Response response = given()
                .header("username", "servicetest")
                .contentType("application/json")
                .body(format("{\"kpiId\":\"%s\", \"constraintDetail\":%s}", kpiId, constraints))
                .when()
                .get(format("/dev/scenarios/%s", scenarioId));

        String scenarioDetails = response.getBody().asString();
        response.then().assertThat().statusCode(200);
        return scenarioDetails;
    }

    public String fetchConstraints(String scenarioId) {
        simulationApi.loadProperties();
        Response response = given()
                .header("username", "servicetest")
                .contentType("application/json")
                .get(format("api/scenarios/%s/constraints", scenarioId));

        String constraints = response.getBody().asString();
        response.then().assertThat().statusCode(200);
        return constraints;

    }
    
}
