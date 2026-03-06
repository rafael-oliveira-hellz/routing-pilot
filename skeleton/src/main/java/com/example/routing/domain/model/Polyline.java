package com.example.routing.domain.model;

import java.util.List;

public record Polyline(
    String encoded,
    List<double[]> points
) {}
