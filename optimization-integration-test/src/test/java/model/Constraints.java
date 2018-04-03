package model;

import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
public abstract class Constraints {
    Double maxSpend = null;
    Double minSpend = null;
    Double spend = null;
    String maxConstraint = null;
    String minConstraint = null;
    String name = null;
    Long id = null;
}
