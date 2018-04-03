package model;

import lombok.Getter;
import lombok.Setter;

import java.util.HashMap;
import java.util.Map;

@Setter
@Getter
public class InstrumentConstraints extends Constraints {
    public InstrumentConstraints() {
        activityConstraints = new HashMap<>();
    }

    private Map<String, ActivityConstraints> activityConstraints;
}
