package model;

import lombok.Getter;
import lombok.Setter;

import java.util.HashMap;
import java.util.Map;

@Setter
@Getter
public class MarketConstraints extends Constraints {
    public MarketConstraints() {
        instrumentsConstraint = new HashMap<>();
    }

    private Map<String, InstrumentConstraints> instrumentsConstraint;
}
