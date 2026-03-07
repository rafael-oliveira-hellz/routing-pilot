package com.example.routing.api.rest;

import com.example.routing.application.port.out.PoiQueryPort;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/pois")
@RequiredArgsConstructor
public class PoiController {

    private final PoiQueryPort poiQueryPort;

    /**
     * POIs por tipo em área (lat, lon, radius em metros). Ex.: type=TRAFFIC_LIGHT para semáforos.
     */
    @GetMapping
    public ResponseEntity<List<PoiResponse>> list(
            @RequestParam double lat,
            @RequestParam double lon,
            @RequestParam(defaultValue = "1000") double radius,
            @RequestParam(required = false, defaultValue = "TRAFFIC_LIGHT") String type) {
        List<PoiQueryPort.PoiDto> pois = poiQueryPort.findByLocationAndType(lat, lon, radius, type);
        List<PoiResponse> body = pois.stream()
                .map(p -> new PoiResponse(p.id(), p.lat(), p.lon(), p.type()))
                .toList();
        return ResponseEntity.ok(body);
    }

    public record PoiResponse(String id, double lat, double lon, String type) {}
}
