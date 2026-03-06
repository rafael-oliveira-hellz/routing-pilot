# 04 - Contexto OptimizationEngine

## Responsabilidade

Gerar rota otimizada e ETA-base usando heurísticas híbridas com execução paralela.
Suporta rotas de 1000+ pontos via clusterização + solve paralelo.

---

## Por que cada algoritmo e otimização

### TSP (Traveling Salesman Problem)

O problema é: visitar N pontos exatamente uma vez com custo total mínimo. TSP é **NP-difícil**: não existe algoritmo exato em tempo polinomial (a menos que P = NP). Para 100–1000+ pontos, usamos **heurísticas com garantia de qualidade** e **otimização local** para chegar perto do ótimo em tempo aceitável.

---

### Por que Kruskal (MST)?

- **Papel**: Gerar uma **Minimum Spanning Tree (MST)** do grafo completo dos pontos.
- **Por que MST**: No TSP métrico, o custo da MST é **limite inferior** do custo do tour ótimo. O algoritmo de **Christofides** usa a MST como base para construir um tour com garantia 3/2 do ótimo.
- **Por que Kruskal e não Prim**: Kruskal ordena todas as arestas uma vez (O(E log E) = O(n² log n)) e usa Union-Find para evitar ciclos. Em grafos **densos** (completo, E = n²), Kruskal é simples de implementar e competitivo; Prim com heap seria O(n² log n) também. Kruskal facilita “escolher as arestas mais baratas em ordem”, que é exatamente o que a MST precisa.
- **Complexidade**: O(n² log n) para grafo completo — aceitável até 1000+ pontos.

---

### Por que Edmonds Blossom (matching perfeito de mínimo custo)?

- **Papel**: No Christofides, após a MST, os vértices de **grau ímpar** precisam ser “pareados” com arestas de custo mínimo, para que o grafo fique **euleriano** (todo vértice com grau par) e possamos extrair um tour.
- **Por que matching perfeito**: Um **minimum weight perfect matching** nos vértices ímpares garante que o tour construído pelo Christofides fique dentro do **fator 3/2** do ótimo. Um matching guloso (greedy) não dá essa garantia e pode ser bem pior na prática.
- **Por que Edmonds Blossom (Blossom V / Kolmogorov)**: É o algoritmo **exato** para matching perfeito de mínimo custo em grafos gerais. Usar uma biblioteca (ex.: JGraphT `KolmogorovMinimumWeightPerfectMatching`) evita bugs e aproveita “shrinking” real de blossoms, com desempenho muito melhor que implementações ingênuas O(n³).
- **Alternativa evitada**: Matching guloso — mais rápido por iteração, mas qualidade pior e sem garantia 3/2.

---

### Por que Christofides?

- **Papel**: Produzir um **tour** (ciclo que visita todos os pontos) a partir da MST + matching.
- **Por que Christofides**: É o algoritmo clássico de **aproximação 3/2** para TSP métrico: o custo do tour é no máximo 1,5 vezes o custo do tour ótimo. Combina MST + matching mínimo nos ímpares + extração de ciclo euleriano + atalhos, com custo total O(n³) na prática (dominado pelo matching).
- **Garantia**: 3/2-approx em grafos que respeitam desigualdade triangular (ex.: distâncias reais em estrada/reta).
- **Alternativas**: Nearest Neighbor, 2-opt sozinho — não têm garantia 3/2; Held-Karp é exato mas O(n² 2^n), inviável para n grande.

---

### Por que 2-opt?

- **Papel**: **Otimização local** do tour: trocar dois trechos do percurso (quebrar duas arestas e religar de outra forma) se isso **reduzir** a distância total.
- **Por que 2-opt**: Simples, O(n²) por varredura, e em prática reduz bem o custo do tour gerado pelo Christofides (que é 3/2-approx mas ainda pode ter “cruzamentos” que 2-opt remove). Não melhora a **garantia** teórica 3/2, mas melhora o resultado **na prática**.
- **Por que não só 2-opt**: 2-opt sozinho (ex.: a partir de um tour aleatório) pode ficar preso em ótimos locais ruins; por isso usamos Christofides para ter um **bom ponto de partida** e 2-opt para **refinar**.
- **Or-opt / 3-opt**: Podem refinar ainda mais, com custo O(n³); 2-opt é o melhor custo-benefício para o pipeline.

---

### Por que VRPClusterer (K-means / clusterização)?

- **Papel**: Para **1000+ pontos**, resolver um único TSP com Christofides + 2-opt fica pesado (tempo e memória). **Particionar** os pontos em clusters (ex.: por proximidade geográfica) permite resolver **vários TSPs menores** em paralelo e depois **juntar** as rotas.
- **Por que clusterização**: Reduz o tamanho de cada subproblema (ex.: até ~150 pontos por cluster), mantendo a garantia de qualidade dentro de cada cluster e permitindo **paralelismo** (ForkJoinPool).
- **Por que K-means (ou similar)**: Agrupa pontos “próximos” no plano, o que tende a gerar clusters espacialmente coerentes e rotas que fazem sentido (menos cruzamentos entre clusters). É heurística, mas barata e eficaz para nosso cenário.

---

### Por que ForkJoinPool (paralelo)?

- **Papel**: Executar a resolução do TSP (Christofides + 2-opt) em **vários clusters ao mesmo tempo**, em múltiplos núcleos.
- **Por que paralelo**: Cada cluster é independente; paralelizar reduz o **tempo total** (quase linear no número de núcleos, até saturar memória/I/O). Para 1000 pontos em 7 clusters, em vez de ~7 × T (tempo de um cluster), temos ~T + overhead.
- **Por que ForkJoinPool**: Modelo de “dividir e conquistar” adequado a tarefas recursivas/em árvore (cada cluster = uma tarefa). Integra bem com o ecossistema Java (parallel streams, RecursiveTask) e escala com o número de núcleos sem precisar configurar filas manualmente.

---

### Resumo da cadeia

| Etapa | Algoritmo | Por que |
|-------|-----------|--------|
| 1 | **Kruskal** | MST como base com custo mínimo; entrada do Christofides. |
| 2 | **Edmonds Blossom** | Matching ótimo nos ímpares; garante aproximação 3/2. |
| 3 | **Christofides** | Tour 3/2-approx a partir da MST + matching. |
| 4 | **2-opt** | Refino local do tour; remove cruzamentos e melhora o custo na prática. |
| 5 | **VRPClusterer** | Divide 1000+ pontos em subproblemas menores e espacialmente coerentes. |
| 6 | **ForkJoinPool** | Resolve vários clusters em paralelo; reduz tempo total. |

---

## Aggregate Root: `RouteOptimization`

## Entidades

| Tabela | Campos principais | Notas |
|--------|-------------------|-------|
| `route_optimization` | id, route_request_id, status, created_at | Job de otimização |
| `route_result` | id, optimization_id, total_distance_meters, total_duration_seconds | Resultado consolidado |
| `route_segment` | id, result_id, from_point, to_point, distance_meters, travel_time_seconds, path_geometry | Segmento detalhado |
| `route_waypoint` | id, result_id, location, sequence_order | Sequência final |
| `optimization_run` | id, optimization_id, algorithm_version, solver_name, started_at, finished_at | Auditoria/trace |

## Pipeline de otimização (1000+ pontos)

```text
Request (1000 pontos)
    │
    ▼
┌─────────────────┐
│ 1. Clusterização│  K-means com limite por cluster (150-200 pts)
│    VRPClusterer  │
└────────┬────────┘
         │ clusters[]
         ▼
┌─────────────────────────────┐
│ 2. ForkJoinPool (parallel)  │
│    Para cada cluster:       │
│    ┌────────────────────┐   │
│    │ a) Kruskal MST     │   │  O(n² log n)
│    │ b) Edmonds Blossom │   │  O(n³) prático ~O(n²)
│    │ c) Christofides    │   │  3/2-approx
│    │ d) 2-Opt local     │   │  O(n²) × iters
│    └────────────────────┘   │
└────────────┬────────────────┘
             │ rotas por cluster
             ▼
┌──────────────────────┐
│ 3. Merge + stitch    │  Conectar fronteiras de clusters
│ 4. 2-Opt global leve │  Refinamento final
└──────────────────────┘
             │
             ▼
      RouteResult persistido
```

## Orçamento de tempo (time budget)

| Pontos | Budget | Clusters | Threads |
|--------|--------|----------|---------|
| ≤ 300 | 2 s | 1 (direto) | 1 |
| 301-700 | 4 s | 3-5 | cores/2 |
| 701-1000 | 6 s | 5-7 | cores |
| 1000+ | 10 s | ceil(n/150) | cores |

---

## Rede viária real: não passar em cima de prédios, mão única, sem ruas sem saída

### Problema

Entre dois pontos A e B a rota deve:

- **Não passar em cima de prédios** — seguir apenas vias (ruas, avenidas).
- **Respeitar mão única** — não “entrar” no sentido contrário.
- **Evitar uso indevido de ruas sem saída** — só entrar em dead-end se for destino/parada; não usar como atalho de passagem.

Isso exige rotear sobre a **rede viária** (grafo de ruas), não em linha reta (Haversine).

### Abordagem: sem APIs comerciais, no máximo dados e APIs públicas

- **Não usar** APIs comerciais (Google, HERE, etc.).
- **Usar**:
  - **Dados públicos**: OpenStreetMap (OSM) — licença aberta, exportações por região (ex.: Geofabrik, BBBike).
  - **Motor de roteamento auto-hospedado**: software open-source que lê OSM e calcula rotas na rede viária, respeitando mão única, restrições de giro e geometria das vias (logo, sem “cortar” prédios).

### Motor escolhido: GraphHopper

| Recurso | Uso |
|---------|-----|
| **Matrix API** | Distância e/ou duração entre N×M pontos → alimenta o TSP (Christofides + 2-opt). |
| **Routing API** | Rota (geometry), distância e duração entre dois pontos → cada segmento final. |

- GraphHopper (Java, open-source, auto-hospedado): lê OSM (.pbf), constrói o grafo de vias. Integra bem ao stack Java; suporta one-way, turn costs, perfis (car, bike, foot). O grafo é **direcionado** — sem contramão; ruas sem saída só são usadas quando o destino está nelas.


### Estratégia de máxima otimização (ambas as fases com GraphHopper)

Usamos as duas fases com o motor de rede para melhor qualidade da sequência e da geometria:

1. **Fase 1 — Otimização (TSP) com matriz na rede**  
   - Obter do **GraphHopper** a **matriz de distância** (e/ou duração) entre todos os pontos do cluster (ou da rota, se pequena).  
   - Alimentar **Christofides + 2-opt** com essa matriz (em vez de Haversine). Assim a ordem de visitas reflete custo **real na estrada** (viadutos, mão única, contornos), não linha reta.  
   - **Cache 3 níveis**: L1 in-process (TTL 5 min), L2 Redis (TTL 15 min, compartilhado entre instâncias), L3 pré-computado para depots/pontos fixos (TTL 24 h, rebuild semanal). Ver doc 04B seção 5.2.  
   - **Escala**: para clusters grandes, a matrix pode ser limitada a um subconjunto ou usar apenas amostras; documentar limite máximo de pontos por request da Matrix API do GraphHopper.

2. **Fase 2 — Roteamento na rede (obrigatório)**  
   - Para cada par consecutivo (waypoint_i → waypoint_i+1) da **sequência já otimizada**:  
     - Chamar o **GraphHopper** (Routing API) com origem e destino.  
     - Obter: polyline/geometry da rota, distância em metros, duração em segundos.  
   - Persistir em `route_segment` (path_geometry, distance_meters, travel_time_seconds).  
   - O trajeto final fica 100% **sobre a rede viária**: sem prédios, mão única respeitada, sem dead-end como atalho.

**Fluxo resumido**: Pontos → GraphHopper Matrix → Christofides + 2-opt (ordem) → GraphHopper Route por par consecutivo → segmentos persistidos.

### Dados OSM, GraphHopper e S3

- **Fonte**: [OpenStreetMap](https://www.openstreetmap.org) — dados abertos.
- **Downloads**: extrações por região em .pbf (ex.: [Geofabrik](https://download.geofabrik.de/), [BBBike](https://download.bbbike.org/osm/)). Preferir extract por **país ou sub-região** (ex.: Brasil no Geofabrik) quando a operação não for global — download e import no GraphHopper bem mais rápidos.

#### Armazenamento em S3 + grafo pré-processado

O `.osm.pbf` é lido **uma única vez** para construir o grafo CH (Contraction Hierarchies). Depois, todas as queries rodam sobre o **grafo em memória** — o `.pbf` não é mais acessado. Por isso, ele pode ficar no S3 sem impacto em runtime.

Melhor ainda: o GraphHopper, após processar o `.pbf`, gera uma **pasta com o grafo CH pré-computado** (arquivos binários, ~1-2 GB para o Brasil). Armazenar esse grafo no S3 evita rebuild a cada startup.

**Pipeline de atualização (semanal, GitHub Actions)**:

```yaml
# .github/workflows/graphhopper-build.yml
name: Build GraphHopper Graph

on:
  schedule:
    - cron: '0 4 * * 0'   # todo domingo às 04:00 UTC
  workflow_dispatch:       # permite rodar manualmente

env:
  GEOFABRIK_URL: https://download.geofabrik.de/south-america/brazil-latest.osm.pbf
  S3_BUCKET: routing-data
  S3_PREFIX: graphhopper
  GH_VERSION: '9.1'       # versão do GraphHopper (manter alinhada com pom.xml)

jobs:
  build-graph:
    runs-on: ubuntu-latest
    timeout-minutes: 30

    steps:
      - name: Checkout (config e profiles)
        uses: actions/checkout@v4
        with:
          sparse-checkout: |
            infra/graphhopper

      - name: Setup Java 25
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '25'

      - name: Download .osm.pbf do Geofabrik
        run: |
          mkdir -p /tmp/gh-work
          curl -L -o /tmp/gh-work/brazil.osm.pbf "$GEOFABRIK_URL"
          ls -lh /tmp/gh-work/brazil.osm.pbf

      - name: Download GraphHopper CLI
        run: |
          curl -L -o /tmp/gh-work/graphhopper.jar \
            "https://repo1.maven.org/maven2/com/graphhopper/graphhopper-web/${GH_VERSION}/graphhopper-web-${GH_VERSION}.jar"

      - name: Build grafo CH (import)
        run: |
          cd /tmp/gh-work
          java -Xmx4g -jar graphhopper.jar import \
            --datareader.file=brazil.osm.pbf \
            --graph.location=./graph-cache \
            --profiles=car \
            --graph.encoded_values=road_class,road_environment,max_speed,surface \
            --prepare.ch.profiles=car
          echo "Grafo gerado:"
          du -sh ./graph-cache

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ vars.AWS_REGION }}

      - name: Upload grafo para S3 (versionado por data)
        run: |
          DATE=$(date +%Y-%m-%d)
          aws s3 sync /tmp/gh-work/graph-cache/ \
            "s3://${S3_BUCKET}/${S3_PREFIX}/brazil-${DATE}/" \
            --delete
          # Atualizar o "latest" pointer
          aws s3 sync /tmp/gh-work/graph-cache/ \
            "s3://${S3_BUCKET}/${S3_PREFIX}/brazil-latest/" \
            --delete
          echo "Upload concluído: s3://${S3_BUCKET}/${S3_PREFIX}/brazil-${DATE}/"

      - name: Cleanup
        if: always()
        run: rm -rf /tmp/gh-work
```

**O que o workflow faz**:
1. Roda todo **domingo às 04:00 UTC** (ou manualmente via `workflow_dispatch`).
2. Baixa o `.osm.pbf` do Brasil do Geofabrik (~1.5 GB).
3. Roda o import do GraphHopper (gera grafo CH com perfil `car`).
4. Faz upload do grafo para S3 com **versionamento por data** (ex.: `brazil-2026-03-02/`) e atualiza o ponteiro `brazil-latest/`.
5. Limpa os arquivos temporários.

**Secrets e variáveis necessários no GitHub**:
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` — credenciais IAM com permissão de escrita no bucket S3.
- `AWS_REGION` (variável) — região do bucket (ex.: `sa-east-1`).

**Startup de cada instância do routing-engine**:

```text
1. Download do grafo CH de s3://routing-data/graphhopper/brazil-latest/ (~1-2 GB, ~15-30 s)
2. GraphHopper carrega o grafo em memória (load, sem rebuild)
3. Instância pronta para queries
```

**Comparação de tempo de startup**:

| Estratégia | Tempo de startup |
|-----------|-----------------|
| .pbf local + rebuild do grafo | ~3-10 min |
| .pbf no S3 + rebuild do grafo | ~4-11 min |
| **Grafo CH pré-processado no S3 (GitHub Actions)** | **~30-90 s** |

**Vantagens**:
- Startup rápido → novas instâncias sobem em ~1 min (ideal para auto-scaling).
- Rebuild feito **uma vez por semana** no GitHub Actions, não em cada instância.
- `.pbf` cru nunca toca produção — só o grafo processado.
- Versionamento via S3 keys (ex.: `brazil-2026-03-02/`) para rollback.
- `workflow_dispatch` permite rebuild manual (ex.: quando Geofabrik publica correção urgente).

### Resumo

| Exigência | Como é atendida |
|-----------|------------------|
| Não passar em cima de prédios | Rota calculada no **grafo de vias** (OSM) pelo GraphHopper. |
| Não ir na contramão | Grafo direcionado no GraphHopper; só arestas permitidas. |
| Não usar dead-end como atalho | Topologia do grafo; dead-end só quando destino está nela. |
| Máxima otimização da ordem | **Matriz de distância na rede** (GraphHopper Matrix) alimenta Christofides + 2-opt. |
| Geometria e ETA por segmento | **Roteamento por par** (GraphHopper Routing) → path_geometry, distance_meters, travel_time_seconds. |
| Sem API comercial | Dados OSM (públicos) + GraphHopper **auto-hospedado** (open-source). |
| Enriquecimento (nomes, POIs, velocidade) | **PostGIS** com dados OSM importados via osm2pgsql. Ver [doc 04C](./04C-Base-Geografica-PostGIS.md). |

---

## Integração com incidentes

- Antes de gerar rota, consultar incidentes ativos no bounding box.
- Incidentes com severidade HIGH/CRITICAL adicionam penalidade ao segmento afetado.
- Segmentos penalizados ficam mais "caros" na MST → rota tende a evitá-los.

## Warm-start

- Se a rota anterior tiver `routeVersion >= 1`, usar sequência como ponto de partida.
- 2-Opt converge mais rápido com warm-start.
- Reuso de matriz de distância cacheada (TTL 5 min).

## Eventos de saída

- `RouteRecalculatedEvent` (rota nova + ETA base)
- `OptimizationFailedEvent` (timeout ou erro)

## Métricas

- `optimization_duration_ms`
- `clusters_count`
- `two_opt_iterations`
- `route_distance_delta_percent` (vs. rota anterior)
- `warm_start_reuse_rate`

---

## Análise de performance

Ver **[doc 04B - Análise de Performance e Otimização Máxima](./04B-Analise-Performance-Otimizacao.md)** para:
- Complexidade rigorosa de cada componente (Kruskal, Blossom, Christofides, 2-opt, GraphHopper Matrix/Routing)
- Memória e pressão de GC por request e sob carga (1000 veículos)
- Ranking de gargalos (CPU vs memória vs GC vs I/O)
- Modelo matemático com curvas de tempo (com/sem clusterização)
- Configuração JVM recomendada (ZGC, heap, TLAB)
- Otimizações priorizadas por sprint
