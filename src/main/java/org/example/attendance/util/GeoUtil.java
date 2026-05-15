package org.example.attendance.util;

import java.math.BigDecimal;

public class GeoUtil {

    private static final double EARTH_RADIUS_METERS = 6_371_000.0;

    public static int haversineDistance(BigDecimal lat1, BigDecimal lon1,
                                        BigDecimal lat2, BigDecimal lon2) {
        double dLat = Math.toRadians(lat2.doubleValue() - lat1.doubleValue());
        double dLon = Math.toRadians(lon2.doubleValue() - lon1.doubleValue());
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1.doubleValue()))
                * Math.cos(Math.toRadians(lat2.doubleValue()))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return (int) (EARTH_RADIUS_METERS * c);
    }

    private GeoUtil() {}
}
