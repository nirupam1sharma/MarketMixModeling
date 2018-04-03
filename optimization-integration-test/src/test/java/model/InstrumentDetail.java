package model;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Getter
@AllArgsConstructor
@NoArgsConstructor
public class InstrumentDetail {
    private String id;
    private Double aggregatedSpend;
    private Double selectedKpiMarginalRoi;
    private Double selectedKpiReturns;
    private Double selectedKpiRoi;
    private List<ActivityDetail> activityDetails;

    public InstrumentDetail(String instrumentId) {
        this.id = instrumentId;
        this.aggregatedSpend = 0d;
        this.activityDetails = new ArrayList<>();

    }

    public void addToAggregatedSpend(Double spend) {
        this.aggregatedSpend += spend;
    }
}

