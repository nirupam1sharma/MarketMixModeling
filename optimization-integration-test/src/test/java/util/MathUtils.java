package util;

public class MathUtils {

    public static boolean isBetween(Double value, Double min, Double max) {
        return value <= max && value >= min;
    }
}
