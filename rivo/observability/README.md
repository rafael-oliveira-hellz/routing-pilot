# Observability

Este diretorio versiona os artefatos operacionais minimos do backend:

- `prometheus/prometheus.yml`: scrape do actuator Prometheus do app.
- `prometheus/alerts/rivo-alerts.yml`: alertas para 5xx, 429, latencia de otimizacao, DLQ e queda de throughput.
- `grafana/dashboards/rivo-overview.json`: dashboard base de operacao.
- `grafana/provisioning/*`: provisionamento automatico do datasource e do dashboard.

## Subir localmente

Com o app rodando em `localhost:8080`, execute:

```powershell
docker compose --profile observability up -d prometheus grafana
```

Acesse:

- Grafana: `http://localhost:3000`
- Prometheus: `http://localhost:9090`

Credenciais padrao do Grafana no compose local:

- usuario: `admin`
- senha: `admin`