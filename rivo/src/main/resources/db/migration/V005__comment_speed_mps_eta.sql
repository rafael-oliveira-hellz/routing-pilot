-- Documentar que speed_mps é a velocidade reportada pelo veículo (m/s), obrigatória para o cálculo do ETA (EWMA).
COMMENT ON COLUMN live_position.speed_mps IS 'Velocidade reportada pelo veículo (m/s). Obrigatória para cálculo do ETA (EWMA e remainingSeconds).';
