package model;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.HashMap;
import java.util.Map;

@Getter
@AllArgsConstructor
@NoArgsConstructor
public class MarketDetail {
    private String id;
    private Double aggregatedSpend;
    private Double selectedKpiMarginalRoi;
    private Double selectedKpiReturns;
    private Double selectedKpiRoi;
    private Map<String, InstrumentDetail> instrumentDetails;

    public MarketDetail(String marketId) {
        this.id = marketId;
        this.aggregatedSpend = 0d;
        this.instrumentDetails = new HashMap<>();
    }

    public void aggregateInstrumentSpend() {
       aggregatedSpend =
               instrumentDetails.values().stream().mapToDouble(InstrumentDetail::getAggregatedSpend).sum();
    }
}
