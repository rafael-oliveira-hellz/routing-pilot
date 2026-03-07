# Mapa: nomes de ruas, semáforos, radar e trânsito

## O que o app já faz

### Nomes de ruas
- As **tiles do OpenStreetMap** já trazem nomes de ruas. O app usa `initialZoom: 14` (e 13 na lista de incidentes), em que os rótulos aparecem.
- Nenhuma configuração extra: basta manter o zoom em 13–16 para os nomes ficarem legíveis.

### Radar (BLITZ)
- Incidentes do tipo **BLITZ** são exibidos no mapa com:
  - Ícone de radar (`Icons.radar`)
  - **Efeito pulsante** (animação de escala) no marcador
- Aparecem no **mapa da rota**, na tela **Em rota** e na **lista de incidentes** (mapa e lista).

### Trânsito intenso
- Se o backend enviar no resultado da rota o campo **`trafficLevel`** por segmento (`RouteSegmentDto.trafficLevel = "HEAVY"`), o app pinta o **trecho correspondente da polyline em vermelho**.
- Segmentos sem `HEAVY` continuam em azul.
- Backend: em cada item de `segments[]` no GET do resultado da rota, incluir por exemplo `"trafficLevel": "HEAVY"` quando o trecho tiver trânsito intenso. **Por enquanto**, o backend deve definir `trafficLevel` com base nos incidentes reportados pelos usuários (ex.: segmentos afetados por HEAVY_TRAFFIC ou severidade alta); futuramente pode vir de provedor de trânsito.

## O que falta (dados do backend)

### Semáforos
- Para mostrar **semáforos** no mapa, o app precisa de uma lista de pontos (lat/lon) ou de um endpoint de POIs (ex.: `/api/v1/pois?lat=&lon=&radius=&type=TRAFFIC_LIGHT`).
- Quando o backend expor isso, basta o app consumir e desenhar uma camada de marcadores (ex.: ícone de semáforo) no mesmo estilo dos incidentes.

### Resumo para o backend
| Dado              | Onde / como o app usa                          | Backend |
|-------------------|-------------------------------------------------|---------|
| Nomes de ruas     | Já vêm nas tiles OSM (zoom 13–16)               | Nada    |
| Radar (BLITZ)     | Incidentes tipo BLITZ com marcador pulsante     | Já cobre (incidentes) |
| Trânsito intenso  | Segmentos da rota em vermelho                   | Enviar `trafficLevel: "HEAVY"` em `segments[]` (por enquanto com base em incidentes reportados) |
| Semáforos         | Marcadores no mapa                              | Definir POIs ou endpoint (ex. tipo TRAFFIC_LIGHT) |

**Lista completa de pendencias do backend em formato sprint/TODO:** ver [BACKEND-PENDENCIAS-SPRINTS.md](BACKEND-PENDENCIAS-SPRINTS.md).
