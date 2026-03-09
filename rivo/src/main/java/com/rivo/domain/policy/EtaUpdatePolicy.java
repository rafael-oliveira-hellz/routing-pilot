package com.rivo.domain.policy;

import com.rivo.domain.model.EtaState;
import com.rivo.domain.model.RouteProgress;
import com.rivo.engine.eta.EtaEngine;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;

@Component
@RequiredArgsConstructor
public class EtaUpdatePolicy {

    private final EtaEngine etaEngine;

    /** speedMps = velocidade reportada pelo ve??culo (LocationUpdatedEvent.speedMps). Obrigat??ria para o ETA. */
    public EtaState computeNewEta(EtaState current, RouteProgress progress,
                                  double speedMps, double trafficFactor,
                                  double incidentFactor, Instant now) {
        return etaEngine.update(current, progress, speedMps,
                                trafficFactor, incidentFactor, now);
    }
}


