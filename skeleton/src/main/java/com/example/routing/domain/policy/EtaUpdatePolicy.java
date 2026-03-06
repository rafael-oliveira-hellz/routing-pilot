package com.example.routing.domain.policy;

import com.example.routing.domain.model.EtaState;
import com.example.routing.domain.model.RouteProgress;
import com.example.routing.engine.eta.EtaEngine;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;

@Component
@RequiredArgsConstructor
public class EtaUpdatePolicy {

    private final EtaEngine etaEngine;

    /** speedMps = velocidade reportada pelo veículo (LocationUpdatedEvent.speedMps). Obrigatória para o ETA. */
    public EtaState computeNewEta(EtaState current, RouteProgress progress,
                                  double speedMps, double trafficFactor,
                                  double incidentFactor, Instant now) {
        return etaEngine.update(current, progress, speedMps,
                                trafficFactor, incidentFactor, now);
    }
}
