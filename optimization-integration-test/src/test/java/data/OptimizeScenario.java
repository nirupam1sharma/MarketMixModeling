package data;

import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.jayway.restassured.http.ContentType;
import com.jayway.restassured.response.Response;

import static com.jayway.restassured.RestAssured.given;

@Singleton
public class OptimizeScenario {

    private final OptimizationApi optimizationApi;

    @Inject
    public OptimizeScenario(OptimizationApi optimizationApi) {
        this.optimizationApi = optimizationApi;
    }

    public String optimize(String scenarioDetails) {
        optimizationApi.loadProperties();
        Response modelResponse = given()
                .contentType(ContentType.JSON)
                .body(scenarioDetails)
                .when()
                .post("custom/scenario/optimize");

        modelResponse.then().assertThat().statusCode(200);

        return modelResponse.getBody().asString();
    }
}
