package com.example.routing.engine.optimization;

import java.util.List;

public interface SpanningTreeMaker {
    ResultDTO getTree(List<Coordinate> coordinates);
}
