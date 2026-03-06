package com.example.routing.domain.model;

public record AlgorithmConfig(
    String algorithmVersion,
    String solverName,
    int clusterSize,
    boolean twoOptEnabled
) {}
