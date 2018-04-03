package model;

import lombok.Getter;
import lombok.Setter;

import java.util.HashMap;
import java.util.Map;

@Setter
@Getter
public class PortfolioConstraints extends Constraints {
    public PortfolioConstraints() {
        marketConstraints = new HashMap<>();
    }

    private Map<String, MarketConstraints> marketConstraints;
}
