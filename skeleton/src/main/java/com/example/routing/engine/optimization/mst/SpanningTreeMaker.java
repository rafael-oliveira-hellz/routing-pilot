package com.example.routing.engine.optimization.mst;

import com.example.routing.engine.optimization.model.Coordinate;

import java.util.List;

public interface SpanningTreeMaker {
    ResultDTO getTree(List<Coordinate> coordinates);
}
