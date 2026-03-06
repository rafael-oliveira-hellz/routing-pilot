package com.example.routing.domain.model;

public record RegionTile(int zoomLevel, long tileX, long tileY) {

    public static RegionTile fromGeoPoint(GeoPoint p, int zoom) {
        long n = 1L << zoom;
        long x = (long) ((p.longitude() + 180.0) / 360.0 * n);
        double latRad = Math.toRadians(p.latitude());
        long y = (long) ((1.0 - Math.log(Math.tan(latRad) + 1.0 / Math.cos(latRad)) / Math.PI) / 2.0 * n);
        return new RegionTile(zoom, x, y);
    }
}
