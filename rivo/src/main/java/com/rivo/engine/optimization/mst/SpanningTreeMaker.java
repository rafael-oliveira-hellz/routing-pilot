package com.rivo.engine.optimization.mst;

import com.rivo.engine.optimization.model.Coordinate;

import java.util.List;

public interface SpanningTreeMaker {
    ResultDTO getTree(List<Coordinate> coordinates);
}


