package step_definitions;


import cucumber.api.java.Before;
import util.Properties;

public class TestSetup {

    @Before
    public void setup() throws Throwable {
        Properties.load();
    }
}