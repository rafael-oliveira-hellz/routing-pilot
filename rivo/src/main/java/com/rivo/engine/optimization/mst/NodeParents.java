package com.rivo.engine.optimization.mst;

import com.rivo.engine.optimization.model.Coordinate;
import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class NodeParents {
    private Coordinate parent;
    private int rank;

    public NodeParents(Coordinate parent, int rank) {
        this.parent = parent;
        this.rank = rank;
    }
}


