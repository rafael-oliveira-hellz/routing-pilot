-- Pendência app (mapa): trânsito por segmento. Por enquanto preencher com base em incidentes (HEAVY_TRAFFIC ou severidade alta).
-- Valores: 'HEAVY' (trecho com trânsito intenso), 'NORMAL' ou NULL (fluido).
ALTER TABLE route_segment ADD COLUMN IF NOT EXISTS traffic_level VARCHAR(20);
COMMENT ON COLUMN route_segment.traffic_level IS 'HEAVY = trânsito intenso (ex.: incidentes HEAVY_TRAFFIC). NORMAL ou NULL = fluido. Consumido pelo app para pintar segmentos em vermelho no mapa.';
