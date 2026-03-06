# 04B - Análise de Performance e Otimização Máxima

> Documento técnico profundo: complexidade algorítmica, memória, GC, CPU, gargalos,
> modelagem para 1000 veículos simultâneos com 1000+ pontos cada.
> Referência: [doc 04](./04-Contexto-OptimizationEngine.md), [doc 04A](./04A-Codigo-Algoritmos-Otimizacao.md), [doc 12](./12-Escalabilidade-Performance.md).

---

## 1. O que exatamente estamos usando

### Stack algorítmica real (não heurística pura)

| Componente | Implementação | Classe | Garantia |
|------------|--------------|--------|----------|
| MST | **Kruskal real** (Union-Find + sort de arestas) | `KruskalSpanningTree` | Exato |
| Matching | **Edmonds Blossom V real** (JGraphT `KolmogorovMinimumWeightPerfectMatching`) | `ChristofidesRefactored` | Exato |
| Tour | **Christofides real** (MST + Blossom + Euler + atalhos) | `ChristofidesRefactored` | 3/2-approx |
| Refinamento local | **2-opt** (first-improvement, convergência completa) | `TwoOptOptimizer` | Heurístico |
| Clusterização | **K-means** (20 iterações, seed fixa 42) | `VRPClusterer` | Heurístico |
| Paralelismo | **ForkJoinPool** (RecursiveTask, parallelStream) | `ParallelRouteEngine`, `HybridRouteStrategy` | N/A |
| Distância (TSP) | **GraphHopper Matrix API** (distância na rede viária real) | A implementar (Sprint 3) | Exato na rede |
| Geometria (segmento) | **GraphHopper Routing API** (polyline na rede) | A implementar (Sprint 3) | Exato na rede |

**Conclusão**: estamos usando **Christofides real com Blossom real**, não um matching guloso. Isso garante a aproximação 3/2 mas tem custo computacional maior que heurísticas puras.

---

## 2. Complexidade por componente (análise rigorosa)

### 2.1 Kruskal MST

| Métrica | Fórmula | Notas |
|---------|---------|-------|
| **Arestas geradas** | E = n(n-1)/2 | Grafo completo |
| **Sort** | O(E log E) = O(n² log n) | Dominante |
| **Union-Find** | O(E × α(n)) ≈ O(n²) | α(n) ≤ 5 para n prático |
| **Total tempo** | **O(n² log n)** | |
| **Memória** | O(n²) | Lista de arestas: n²/2 objetos `CoordinatesWithDistance` |

**Memória concreta por cluster** (n = 150):
- Arestas: 150×149/2 = 11.175 objetos
- Cada `CoordinatesWithDistance`: ~80 bytes (3 refs + 1 double)
- Total arestas: ~870 KB
- Nós (Coordinate): 150 × ~120 bytes = ~18 KB
- **Total Kruskal: ~900 KB por cluster**

### 2.2 Edmonds Blossom V (JGraphT)

| Métrica | Fórmula | Notas |
|---------|---------|-------|
| **Vértices ímpares** | |V_odd| ≤ n | Tipicamente ~n/2 |
| **Grafo do matching** | E_odd = |V_odd|² / 2 | Completo entre ímpares |
| **Blossom V teórico** | O(\|V_odd\|³) | Pior caso |
| **Blossom V prático** | **~O(\|V_odd\|² × log)** | JGraphT otimizado com dual variables + PQ |
| **Memória** | O(\|V_odd\|²) | Grafo JGraphT interno |

**Memória concreta** (n = 150, ~75 vértices ímpares):
- Grafo JGraphT: ~75² / 2 = 2.812 arestas internas
- Overhead JGraphT por aresta: ~160 bytes (edge object + weight + maps)
- **Total Blossom: ~450 KB + overhead interno ~200 KB = ~650 KB**

**ALERTA**: Blossom V é o **gargalo computacional** do pipeline. Para n = 150 (cluster), |V_odd| ≈ 75 → ~75³ = 421.875 operações no pior caso. Para n = 300 sem clusterização, |V_odd| ≈ 150 → ~3.375.000 operações. Cresce **cubicamente** com o tamanho do cluster.

### 2.3 Christofides (completo)

| Etapa | Complexidade | Memória |
|-------|-------------|---------|
| MST (Kruskal) | O(n² log n) | O(n²) |
| Matching (Blossom) | O(n³) pior / O(n²) prático | O(n²) |
| Euler circuit | O(n) | O(n) |
| Atalhos (shortcutting) | O(n) | O(n) |
| DFS (buildFinalSequence) | O(n) | O(n) |
| **Total** | **O(n³)** pior / **O(n² log n)** prático | **O(n²)** |

### 2.4 2-opt

| Métrica | Fórmula | Notas |
|---------|---------|-------|
| **Uma varredura** | O(n²) | 2 loops aninhados |
| **Iterações** | k (tipicamente 3-15) | First-improvement, converge rápido a partir de Christofides |
| **Total** | **O(k × n²)** | k pequeno com warm-start |
| **Memória** | O(n) | In-place, só a lista de waypoints |

**Warm-start**: quando partimos de um tour Christofides (já bom), 2-opt converge em ~3-5 iterações. Sem Christofides (tour aleatório), pode demorar 10-50 iterações.

### 2.5 VRPClusterer (K-means)

| Métrica | Fórmula | Notas |
|---------|---------|-------|
| **Iterações** | 20 (fixo no código) | Hardcoded |
| **Por iteração** | O(n × k) | k = ceil(n/150) |
| **Total** | **O(20 × n × k)** = O(n²/150) | Linear na prática |
| **Memória** | O(n + k) | Listas de clusters |

### 2.6 GraphHopper Matrix API

| Métrica | Fórmula | Notas |
|---------|---------|-------|
| **Pares** | n × n (ou n × (n-1)/2 simétrico) | Para cada cluster |
| **Tempo por par** | ~0.5-2 ms (CH/contraction hierarchies) | GraphHopper com CH ativado |
| **Total (n = 150)** | 150² / 2 = 11.250 pares × ~1 ms = **~11 s** | **GARGALO POTENCIAL** |
| **Total (batch mode)** | GraphHopper Matrix aceita batch → ~2-5 s para 150 pontos | Latência de rede interna |

**ALERTA**: A Matrix API pode ser o **novo gargalo** quando usamos distância na rede real em vez de Haversine. Mitigações abaixo.

### 2.7 GraphHopper Routing API (por segmento)

| Métrica | Fórmula | Notas |
|---------|---------|-------|
| **Chamadas** | n - 1 | Um por par consecutivo na sequência final |
| **Tempo por chamada** | ~1-5 ms (com CH) | GraphHopper local, sem rede |
| **Total (n = 1000)** | 999 × ~3 ms = **~3 s** | Paralelizável |

---

## 3. Modelo de custo composto (pipeline completo)

### 3.1 Para um cluster de tamanho c

```
T_cluster(c) = T_matrix(c) + T_kruskal(c) + T_blossom(c) + T_2opt(c)
```

| c | T_matrix | T_kruskal | T_blossom | T_2opt | **T_cluster** |
|---|----------|-----------|-----------|--------|---------------|
| 50 | ~0.5 s | ~1 ms | ~3 ms | ~5 ms | **~0.5 s** |
| 100 | ~2 s | ~5 ms | ~15 ms | ~20 ms | **~2 s** |
| 150 | ~4 s | ~12 ms | ~50 ms | ~45 ms | **~4.1 s** |
| 200 | ~7 s | ~20 ms | ~120 ms | ~80 ms | **~7.2 s** |
| 300 | ~15 s | ~45 ms | ~350 ms | ~180 ms | **~15.6 s** |

> **SUPERADO**: com as otimizações da seção 5.2 e 5.3 (paralelo + k-nearest + Blossom esparso), os tempos caem drasticamente. Ver tabelas revisadas na seção 5.3.1.

### 3.2 Para rota completa de N pontos (com clusterização + paralelismo)

```
k = ceil(N / c)           -- número de clusters
p = min(k, cores)         -- threads paralelas
T_total(N) = T_cluster(c) × ceil(k / p) + T_stitch + T_2opt_global + T_routing_final
```

| N | c | k | p (8 cores) | T_cluster | T_parallel | T_routing | **T_total** |
|---|---|---|-------------|-----------|------------|-----------|-------------|
| 100 | 100 | 1 | 1 | ~2 s | ~2 s | ~0.3 s | **~2.3 s** |
| 300 | 150 | 2 | 2 | ~4 s | ~4 s | ~0.9 s | **~5 s** |
| 500 | 150 | 4 | 4 | ~4 s | ~4 s | ~1.5 s | **~5.5 s** |
| 700 | 150 | 5 | 5 | ~4 s | ~4 s | ~2.1 s | **~6.1 s** |
| 1000 | 150 | 7 | 7 | ~4 s | ~4 s | ~3 s | **~7 s** |
| 1500 | 150 | 10 | 8 | ~4 s | ~8 s | ~4.5 s | **~12.5 s** |
| 2000 | 150 | 14 | 8 | ~4 s | ~8 s | ~6 s | **~14 s** |

**Comportamento**: com clusterização, T_total cresce **linearmente** (não cubicamente) com N, porque cada cluster tem tamanho fixo c. O paralelismo limita o crescimento ao teto de ceil(k/p).

### 3.3 Curva de complexidade efetiva

```
Sem clusterização:   T(N) ≈ α × N³            (Blossom domina)
Com clusterização:   T(N) ≈ β × ceil(N/c)     (linear, com teto paralelo)
Com cluster + GH:    T(N) ≈ γ × c² + δ × N    (matrix domina por cluster + routing linear)
```

Onde:
- α ≈ 1.5 × 10⁻⁸ s (coeficiente Blossom por operação)
- β ≈ 4.1 s (tempo de um cluster de 150 pontos com GraphHopper)
- γ ≈ 1.8 × 10⁻⁴ s (coeficiente da matrix por par)
- δ ≈ 3 × 10⁻³ s (coeficiente do routing final por segmento)

---

## 4. Análise de memória e GC

### 4.1 Memória por request (um job de otimização)

| Componente | n = 150 (1 cluster) | n = 1000 (7 clusters, pico) |
|------------|---------------------|------------------------------|
| Coordinates | 18 KB | 120 KB |
| Graph (arestas Kruskal) | 870 KB | 870 KB × 7 = **6 MB** (paralelo) |
| Grafo JGraphT (Blossom) | 650 KB | 650 KB × 7 = **4.5 MB** (paralelo) |
| Tour (WaypointSequence) | 12 KB | 80 KB |
| GraphHopper Matrix (cache) | ~180 KB (doubles) | ~180 KB × 7 = **1.3 MB** |
| Routing API results | ~50 KB | ~500 KB |
| **Total pico por request** | **~1.7 MB** | **~12.5 MB** |

### 4.2 Pressão de GC

| Fator | Impacto | Mitigação |
|-------|---------|-----------|
| **Alocação massiva de objetos curtos** | Graph cria n²/2 objetos `CoordinatesWithDistance` por cluster, depois descartados → pressão no Young Gen | Pool de objetos ou usar arrays primitivos (double[][]) para a matriz |
| **JGraphT Blossom** | Cria muitos objetos internos (blossoms, dual variables, PQ nodes) → churn no Eden | Inevitável; dimensionar Young Gen adequadamente |
| **Paralelo (7 clusters)** | 7 threads alocando simultaneamente → maior pressão no TLAB | Aumentar TLAB size (-XX:TLABSize=512k) |
| **Strings e UUIDs** | Coordinate carrega String name + UUID id → retenção desnecessária no engine | Usar IDs int internos no engine, mapear de/para UUID na entrada/saída |
| **Listas temporárias** | Muitas ArrayList intermediárias em K-means, merge, etc. | Pré-alocar com capacidade estimada |

### 4.3 Estimativa de heap sob carga (1000 veículos simultâneos)

```
Cenário: 1000 veículos, 3% recalculando simultaneamente = 30 jobs concorrentes
Memória por job (pico): ~12.5 MB
Jobs concorrentes: 30
Memória de jobs: 30 × 12.5 MB = ~375 MB

+ GraphHopper grafo em memória (Brasil .pbf): ~2-4 GB
+ Estado do serviço (Spring, Redis client, NATS client): ~200 MB
+ Overhead JVM (metaspace, stacks, buffers): ~300 MB

Total estimado do routing-engine: ~3-5 GB de heap
```

### 4.4 Configuração JVM recomendada (routing-engine)

```bash
java \
  -Xms4g -Xmx6g \
  -XX:+UseZGC \
  -XX:TLABSize=512k \
  -XX:MaxGCPauseMillis=10 \
  -XX:+UseStringDeduplication \
  -XX:ConcGCThreads=4 \
  -XX:ParallelGCThreads=8 \
  -XX:MetaspaceSize=256m \
  -XX:MaxMetaspaceSize=512m \
  -jar routing-engine.jar
```

**Por que ZGC**:
- Pausas < 10 ms mesmo com heap de 6 GB.
- Ideal para workloads com alocação alta e curta (nosso caso: muitos objetos por job, descartados logo).
- Java 25 tem ZGC generacional maduro.

**Alternativa (G1GC)**:
```bash
-XX:+UseG1GC -XX:MaxGCPauseMillis=50 -XX:G1HeapRegionSize=4m
```
Pausas um pouco maiores (~30-50 ms), mas menor overhead de CPU que ZGC.

### 4.5 Infraestrutura: S3 + grafo pré-processado

O `.osm.pbf` é lido uma vez no startup para gerar o grafo CH. Depois, queries usam só a memória. O `.pbf` pode ficar no S3 sem impacto em runtime.

**Estratégia ideal**: armazenar no S3 o **grafo CH pré-processado** (não o .pbf cru). Isso elimina o rebuild (~3-10 min) de cada instância.

| Métrica | .pbf + rebuild | Grafo pré-processado do S3 |
|---------|---------------|---------------------------|
| Tempo de startup | ~3-10 min | **~30-90 s** |
| CPU no startup | Alta (rebuild CH) | Baixa (só load) |
| Disco na instância | ~3.5 GB (.pbf + grafo) | ~2 GB (só grafo) |
| Impacto em runtime | Nenhum | Nenhum |
| Auto-scaling | Lento (10 min por instância) | **Rápido (~1 min)** |

**Pipeline**: CI/CD baixa .pbf → roda import offline → upload do grafo para S3 → instâncias baixam e carregam. Ver detalhes no [doc 04 seção "Armazenamento em S3 + grafo pré-processado"](./04-Contexto-OptimizationEngine.md).

---

## 5. Análise de gargalos: CPU vs Memória vs GC vs I/O

### 5.1 Ranking de gargalos por fase

| # | Gargalo | Fase | Impacto | Probabilidade |
|---|---------|------|---------|---------------|
| 1 | **GraphHopper Matrix API** | Fase 1 | Alto — domina o tempo de cada cluster | Alta |
| 2 | **Blossom V (matching)** | Christofides | Médio — O(n³) mas n ≤ 150 com clusterização | Média (controlado) |
| 3 | **GC (Young Gen churn)** | Kruskal + Blossom paralelo | Médio — muitos objetos temporários | Média |
| 4 | **Memória (GraphHopper grafo)** | Startup | Alto — 2-4 GB para o grafo do Brasil | Baixa (dimensionar heap) |
| 5 | **ForkJoinPool starvation** | Paralelismo | Baixo — se GraphHopper também usa FJP internamente, contenção | Baixa |
| 6 | **I/O disco** | Routing API | Baixo — GraphHopper em memória, sem disco durante query | Muito baixa |

### 5.2 Gargalo #1: GraphHopper Matrix — SOLUÇÕES DE PERFORMANCE MÁXIMA

**Problema**: Matrix API calcula c²/2 rotas na rede para montar a matriz de distância. Para c = 150: 11.175 pares.

#### Solução A — Matriz paralela com GraphHopper embarcado + CH (OBRIGATÓRIA)

GraphHopper embarcado (mesma JVM, sem HTTP) com **Contraction Hierarchies** (CH) reduz cada query point-to-point a **~5-50 μs** (microsegundos, não milissegundos). CH pré-computa atalhos no grafo e responde sem Dijkstra completo.

Paralelizar a computação da matriz: os 11.175 pares são **independentes** — dividir entre as threads do ForkJoinPool.

```
Sem otimização (GH HTTP, serial):    11.175 × 1 ms    = ~11 s    ❌
GH embarcado (serial):               11.175 × 0.05 ms = ~560 ms
GH embarcado (8 threads paralelo):   11.175 / 8 × 0.05 ms = ~70 ms  ✅
```

**Implementação**: `ParallelDistanceMatrix` — divide os pares em chunks, cada thread calcula um bloco da `double[][]`, resultado zero-copy.

```java
public class ParallelDistanceMatrix {
    private final GraphHopper hopper;
    private final ForkJoinPool pool;

    public double[][] compute(List<Coordinate> points) {
        int n = points.size();
        double[][] matrix = new double[n][n];
        // upper triangle only (symmetric for distance, asymmetric for duration)
        pool.submit(() -> IntStream.range(0, n).parallel().forEach(i -> {
            for (int j = i + 1; j < n; j++) {
                GHResponse resp = hopper.route(new GHRequest(
                    points.get(i).lat(), points.get(i).lon(),
                    points.get(j).lat(), points.get(j).lon()));
                double dist = resp.getBest().getDistance();
                matrix[i][j] = dist;
                matrix[j][i] = dist; // simétrica para distância
            }
        })).join();
        return matrix;
    }
}
```

#### Solução B — Grafo esparso k-nearest (RECOMENDADA para cluster > 100)

Para MST (Kruskal/Prim), **não precisamos de todas as n²/2 arestas**. As arestas da MST são quase sempre entre pontos **geograficamente próximos**. Podemos:

1. Ordenar pontos por Haversine (O(1) cada) e computar os **k vizinhos mais próximos** de cada ponto.
2. Chamar GraphHopper **só para esses k×n pares** (distância na rede).
3. Construir MST no grafo esparso (se desconexo, adicionar arestas sob demanda).

| k | Pares GH (n=150) | vs. completo (11.175) | Tempo (paralelo, 8 cores) |
|---|-------------------|----------------------|---------------------------|
| 10 | 1.500 | **87% menos** | ~9 ms |
| 15 | 2.250 | **80% menos** | ~14 ms |
| 20 | 3.000 | **73% menos** | ~19 ms |

**Trade-off**: se k for pequeno demais, o grafo pode ser desconexo e a MST não cobre todos os pontos. Solução: começar com k = 15; se grafo desconexo, dobrar k para os componentes desconexos e repetir.

Para o **matching (Blossom)**, também usar k-nearest entre vértices ímpares (k = 10 é suficiente).

#### Solução C — Cache de matriz multinível (OBRIGATÓRIA)

| Nível | Storage | TTL | Conteúdo | Hit rate esperado |
|-------|---------|-----|----------|-------------------|
| **L1** | `ConcurrentHashMap` in-process | 5 min | Matriz completa do cluster recém-calculado | ~60% (recálculos rápidos do mesmo veículo) |
| **L2** | Redis (compartilhado entre instâncias) | 15 min | Matriz por hash do conjunto de point IDs | ~25% (outro veículo com pontos parecidos, ou outra instância) |
| **L3** | Redis ou S3 (pré-computado, background job) | 24 h | Distâncias depot↔parada (pontos fixos: CDs, filiais, garagens) | ~15% (toda rota começa/termina num depot) |

**Por que 3 níveis e não 2:**

- **L1** é volátil (per-instance, morre no restart) mas ultra-rápido (~0 ms). Cobre recálculos por desvio/incidente do **mesmo veículo** (pontos quase idênticos).
- **L2** sobrevive a restarts e é compartilhado entre instâncias — se a instância 1 calculou a matriz para um conjunto de pontos, a instância 2 pode reusar. Útil quando **múltiplos veículos** passam pela mesma região.
- **L3** é o diferencial: depots (CDs, filiais, garagens) são **pontos fixos** que aparecem em toda rota como origem ou destino. As distâncias depot→parada e parada→depot mudam apenas quando o grafo OSM muda (~semanal). Pré-computar em background job (ex.: cron semanal após rebuild do grafo) e armazenar com TTL longo **elimina ~15% das queries GH de cada request**.

Chave do cache L1/L2: `SHA256(sorted(point_ids))` → `double[][]` serializada.
Chave do cache L3: `(depot_id, point_id)` → `(distance_m, duration_s)`.

Em recálculos (desvio, incidente), a maioria dos pontos é a mesma — hit no L1. Para rotas novas, L3 garante que pelo menos as distâncias do depot estão prontas.

#### Solução D — Prim em vez de Kruskal (evita materializar todas as arestas)

Kruskal precisa de **todas** as arestas ordenadas. Prim com priority queue precisa apenas manter "a aresta mais barata de cada vértice fora da árvore para dentro da árvore" — **não precisa materializar n²/2 arestas**.

Com Prim lazy:
- Iterar n vezes (um por vértice adicionado à MST).
- A cada passo, computar distância (GH, ~0.05 ms) do novo vértice para os vértices ainda fora da árvore.
- Total: n × (n/2 em média) = n²/2 distâncias, **mas sem alocar a lista inteira** — zero GC extra.

Com Prim + k-nearest: computar distâncias apenas para os k vizinhos próximos, adiando o cálculo de vizinhos distantes. Total: ~k×n distâncias.

#### Resultado combinado (A + B + C)

| Técnica | T_matrix (c=150, 8 cores) |
|---------|--------------------------|
| Baseline (GH HTTP, serial) | ~11 s |
| GH embarcado + CH (serial) | ~560 ms |
| + paralelo (8 threads) | ~70 ms |
| + k-nearest (k=15) | ~14 ms |
| + cache L1 hit | ~0 ms |
| **Cenário típico (miss + paralelo + k-nearest)** | **~14-70 ms** |

**T_matrix deixa de ser gargalo.** O gargalo passa a ser Blossom V (~50 ms) ou 2-opt (~45 ms).

---

### 5.3 Gargalo #2: Blossom V — SOLUÇÕES DE PERFORMANCE MÁXIMA

**Problema**: matching perfeito de mínimo custo nos vértices ímpares da MST. JGraphT `KolmogorovMinimumWeightPerfectMatching` é O(|V_odd|³) no pior caso.

Para cluster de 150 pontos: |V_odd| ≈ 75 → 75³ = 421.875 operações. Na prática ~50-120 ms com JGraphT.

#### Solução A — Grafo esparso de matching (RECOMENDADA)

Em vez de construir o grafo **completo** entre os 75 vértices ímpares (2.812 arestas), construir apenas com os **k vizinhos mais próximos** de cada vértice ímpar:

| k | Arestas | vs. completo (2.812) | T_blossom estimado |
|---|---------|---------------------|-------------------|
| 5 | ~188 | **93% menos** | ~3-8 ms |
| 7 | ~263 | **91% menos** | ~5-12 ms |
| 10 | ~375 | **87% menos** | ~8-20 ms |

Blossom V em grafo esparso é **drasticamente** mais rápido porque:
- Menos arestas para considerar em cada pivoting.
- Menos blossoms para criar/shrink.
- A complexidade efetiva cai de O(|V|³) para ~O(|V| × k × log|V|).

**Risco**: se k for muito pequeno, pode não existir matching perfeito no grafo esparso. Solução: começar com k = 7; se Blossom falhar (exceção), adicionar arestas (dobrar k) e repetir. Na prática geográfica, k = 7 é quase sempre suficiente.

```java
private DefaultUndirectedWeightedGraph<Coordinate, DefaultWeightedEdge> buildSparseOddGraph(
        List<ChristofidesVertex> oddVertices, int k) {
    var graph = new DefaultUndirectedWeightedGraph<>(DefaultWeightedEdge.class);
    oddVertices.forEach(v -> graph.addVertex(v.getCoordinates()));

    for (ChristofidesVertex v : oddVertices) {
        List<ChristofidesVertex> nearest = oddVertices.stream()
            .filter(u -> !u.equals(v))
            .sorted(Comparator.comparingDouble(u ->
                DistanceCalculator.haversineMeters(v.getCoordinates(), u.getCoordinates())))
            .limit(k)
            .toList();

        for (ChristofidesVertex u : nearest) {
            if (graph.getEdge(v.getCoordinates(), u.getCoordinates()) == null) {
                var e = graph.addEdge(v.getCoordinates(), u.getCoordinates());
                if (e != null) graph.setEdgeWeight(e, distanceMatrix[indexOf(v)][indexOf(u)]);
            }
        }
    }
    return graph;
}
```

#### Solução B — Cluster cap adaptativo (OBRIGATÓRIA)

| Contexto | Cluster size c | |V_odd| esperado | T_blossom (completo) | T_blossom (k=7 esparso) |
|----------|---------------|-----------------|---------------------|------------------------|
| Urbano denso (SP centro) | 80 | ~40 | ~8 ms | ~2 ms |
| Suburbano | 120 | ~60 | ~30 ms | ~6 ms |
| Rodovia (pontos espalhados) | 150 | ~75 | ~50 ms | ~10 ms |
| Misto | 100 (default seguro) | ~50 | ~15 ms | ~4 ms |

Usar **cluster cap adaptativo** baseado na **densidade de pontos** (pontos por km²):
- Densidade alta (> 50 pts/km²): c = 80
- Densidade média (10-50 pts/km²): c = 120
- Densidade baixa (< 10 pts/km²): c = 150

Mais clusters → mais stitching, mas cada Blossom é muito mais rápido (efeito cúbico).

#### Solução C — Timeout + fallback escalonado (OBRIGATÓRIA)

Se Blossom demorar mais que o esperado, escalar para alternativa mais rápida:

```
T_blossom < 100 ms   → OK, usar resultado Blossom (exato, garantia 3/2)
T_blossom > 100 ms   → Cancelar, tentar Blossom com grafo esparso (k=5)
T_blossom > 200 ms   → Cancelar, usar matching guloso (nearest-neighbor matching)
```

**Matching guloso (nearest-neighbor)**:
```java
public static List<Pair<Coordinate, Coordinate>> greedyMatching(List<ChristofidesVertex> oddVerts) {
    List<Pair<Coordinate, Coordinate>> pairs = new ArrayList<>();
    Set<UUID> matched = new HashSet<>();
    List<ChristofidesVertex> sorted = new ArrayList<>(oddVerts);

    for (ChristofidesVertex v : sorted) {
        if (matched.contains(v.getId())) continue;
        ChristofidesVertex nearest = sorted.stream()
            .filter(u -> !matched.contains(u.getId()) && !u.equals(v))
            .min(Comparator.comparingDouble(u ->
                DistanceCalculator.haversineMeters(v.getCoordinates(), u.getCoordinates())))
            .orElse(null);
        if (nearest != null) {
            pairs.add(Pair.of(v.getCoordinates(), nearest.getCoordinates()));
            matched.add(v.getId());
            matched.add(nearest.getId());
        }
    }
    return pairs;
}
```

Guloso é O(n²), sem risco de explosão. Qualidade ~10-30% pior que Blossom, mas acontece raramente (só se Blossom estourar o timeout).

#### Solução D — Reduzir |V_odd| antes do matching

Após a MST, se houver dois vértices ímpares adjacentes na árvore, adicionar uma aresta duplicada entre eles (custo = distância). Isso torna ambos pares, **removendo-os** do conjunto ímpar.

Repetir guloso para pares adjacentes até não ter mais adjacentes ímpares. Depois rodar Blossom nos restantes.

Na prática, isso reduz |V_odd| em ~20-40%, tornando Blossom muito mais rápido.

#### Resultado combinado (A + B + C + D)

| Técnica | T_blossom (c=150) | T_blossom (c=100) |
|---------|-------------------|-------------------|
| Baseline (completo, JGraphT) | ~50-120 ms | ~15-40 ms |
| + grafo esparso (k=7) | ~10-25 ms | ~4-10 ms |
| + redução de |V_odd| (adjacentes) | ~5-15 ms | ~2-6 ms |
| + cluster adaptativo (c=100 default) | N/A | **~2-6 ms** |
| **Cenário típico** | **~5-15 ms** | **~2-6 ms** |

**Blossom V deixa de ser gargalo.** Controlado em < 15 ms por cluster.

---

### 5.3.1 Tabelas de tempo REVISADAS (com todas as otimizações)

#### Custo por cluster (GH embarcado + paralelo + k-nearest + Blossom esparso)

```
T_cluster(c) = T_matrix(c) + T_kruskal(c) + T_blossom(c) + T_2opt(c)
```

| c | T_matrix (k=15, 8t) | T_kruskal | T_blossom (k=7 esparso) | T_2opt | **T_cluster** |
|---|----------------------|-----------|------------------------|--------|---------------|
| 50 | ~3 ms | ~1 ms | ~1 ms | ~5 ms | **~10 ms** |
| 80 | ~6 ms | ~3 ms | ~2 ms | ~13 ms | **~24 ms** |
| 100 | ~9 ms | ~5 ms | ~4 ms | ~20 ms | **~38 ms** |
| 120 | ~12 ms | ~7 ms | ~6 ms | ~29 ms | **~54 ms** |
| 150 | ~14 ms | ~12 ms | ~10 ms | ~45 ms | **~81 ms** |

#### Rota completa (c=100 default, 8 cores)

| N | Clusters | Rounds | T_cluster (paralelo) | T_routing | **T_total** |
|---|----------|--------|---------------------|-----------|-------------|
| 50 | 1 | 1 | ~10 ms | ~10 ms | **~20 ms** |
| 100 | 1 | 1 | ~38 ms | ~20 ms | **~58 ms** |
| 200 | 2 | 1 | ~38 ms | ~40 ms | **~78 ms** |
| 300 | 3 | 1 | ~38 ms | ~60 ms | **~98 ms** |
| 500 | 5 | 1 | ~38 ms | ~100 ms | **~138 ms** |
| 700 | 7 | 1 | ~38 ms | ~140 ms | **~178 ms** |
| 1000 | 10 | 2 | ~76 ms | ~200 ms | **~276 ms** |
| 1500 | 15 | 2 | ~76 ms | ~300 ms | **~376 ms** |
| 2000 | 20 | 3 | ~114 ms | ~400 ms | **~514 ms** |
| 5000 | 50 | 7 | ~266 ms | ~1000 ms | **~1.3 s** |

**Comparação com versão anterior (sem otimizações agressivas)**:

| N | ANTES | DEPOIS | Speedup |
|---|-------|--------|---------|
| 100 | ~1.5 s | **~58 ms** | **26×** |
| 500 | ~1.6 s | **~138 ms** | **12×** |
| 1000 | ~1.7 s | **~276 ms** | **6×** |
| 2000 | ~3.4 s | **~514 ms** | **7×** |
| 5000 | ~8.5 s | **~1.3 s** | **7×** |

O routing final (GH Routing API por segmento) passa a ser o **componente mais lento** do pipeline (e também paralelizável).

### 5.4 Gargalo #3: GC

**Problema**: Kruskal cria n²/2 objetos `CoordinatesWithDistance` por cluster; 7 clusters em paralelo = ~78k objetos de ~80 bytes = ~6 MB alocados e descartados rapidamente.

**Mitigações**:

| Mitigação | Redução | Complexidade |
|-----------|---------|--------------|
| **ZGC** (pausas < 10 ms) | GC quase transparente | Configuração JVM |
| **Reusar arrays** em vez de List<CoordinatesWithDistance> para o Graph | Evita boxing e GC de objetos | Refatoração média |
| **double[][]** para a matriz de distância | Sem objetos, sem GC | Refatoração em Graph + Kruskal |
| **Pré-alocar listas com capacidade** | Menos resizing de ArrayList | Trivial |

---

## 6. Modelagem: 1000 veículos simultâneos

### 6.1 Padrão de carga

```
1000 veículos × 10 GPS updates/s = 10.000 eventos/s

Distribuição:
  - 95% → Hot path (ETA update only, ~10 ms/evt)     = 9.500/s
  - 2%  → Warm path (incidentes, ~15 ms/evt)          = 200/s
  - 3%  → Cold path (recálculo de rota)               = 300/s

Recálculos simultâneos máximo (burst):
  - ~30 jobs ao mesmo tempo (cada um ~7 s para 1000 pontos)
  - Throughput necessário: 300/60 = ~5 recálculos/s sustentado
```

### 6.2 Dimensionamento do routing-engine

| Variável | Cálculo | Resultado |
|----------|---------|-----------|
| Tempo por recálculo (1000 pts, otimizado) | ~276 ms (paralelo + k-nearest + Blossom esparso) | 0.28 s |
| Tempo por recálculo (1000 pts, baseline) | ~1.7 s (GH embarcado + CH, sem k-nearest) | 1.7 s |
| Throughput por instância (otimizado) | ~28 jobs/s | ~28 jobs/s |
| Throughput por instância (baseline) | ~5 jobs/s | ~5 jobs/s |
| Instâncias para 5 jobs/s (otimizado) | 1 | **1 instância** |
| Instâncias para burst (30 jobs, otimizado) | ceil(30 / 28) | **2 instâncias** |
| Memória por instância | ~5 GB (GH grafo + heap) | 5 GB |
| CPU por instância | 8 vCPU (saturar ForkJoinPool) | 8 vCPU |

### 6.3 Recursos totais (routing-engine cluster, otimizado)

| Recurso | Por instância | × 2 instâncias | Total |
|---------|---------------|----------------|-------|
| CPU | 8 vCPU | 16 vCPU | 16 vCPU |
| RAM | 6 GB heap + 1 GB off-heap | 14 GB | 14 GB |
| Disco (GH grafo) | ~2 GB (Brasil .pbf processado) | 4 GB | 4 GB |
| Disco (OSM .pbf) | ~1.5 GB (download) | Compartilhado | 1.5 GB |

### 6.4 Latência P50 / P95 / P99

| Percentil | Latência (1000 pts) | Fator dominante |
|-----------|---------------------|-----------------|
| P50 | ~200 ms | Matrix paralelo + Christofides esparso + 2-opt |
| P95 | ~400 ms | Cluster desbalanceado + Blossom fallback |
| P99 | ~800 ms | GC pause + cache miss + retry Blossom esparso |

### 6.5 Cenários de stress

| Cenário | Impacto | Mitigação |
|---------|---------|-----------|
| **Burst de 100 recálculos** (acidente grande) | Fila cresce, latência sobe para ~30 s | Bounded queue + priority (veículos próximos ao acidente primeiro) |
| **GC stop-the-world > 100 ms** | Job em andamento tem latência extra | ZGC (max 10 ms pause), ou isolar GraphHopper em processo separado |
| **GraphHopper grafo stale** (OSM desatualizado) | Rotas evitam vias novas | Rebuild semanal com rolling restart |
| **Cluster desbalanceado** (300 pontos num cluster) | Blossom > 1 s | Cap de cluster em 200, split dinâmico |
| **OOM por muitos jobs paralelos** | JVM crash | Circuit breaker + bounded concurrency (max 4 jobs por instância) |

---

## 7. Otimizações recomendadas (por prioridade)

### 7.1 Prioridade CRÍTICA (Sprint 3 — diferença de 26× no throughput)

| # | Otimização | Ganho | Esforço |
|---|-----------|-------|---------|
| 1 | **GraphHopper embarcado** (mesma JVM, sem HTTP) + **CH** | ~200× vs Dijkstra HTTP | Médio |
| 2 | **Matriz paralela** (`ParallelDistanceMatrix`, 8 threads) | ~8× na fase matrix | Baixo |
| 3 | **k-nearest grafo esparso** (k=15 para matrix, k=7 para Blossom) | ~87-93% menos queries GH e arestas Blossom | Médio |
| 4 | **Blossom em grafo esparso** (k=7 vizinhos por vértice ímpar) | ~50 ms → ~10 ms | Baixo |
| 5 | **double[][]** para matriz (zero objetos, zero GC) | ~60% menos GC pressure | Médio |
| 6 | **Cache multinível 3 níveis** (L1 in-process, L2 Redis, L3 pré-computado depots) | ~0 ms em recálculos | Baixo-Médio |
| 7 | **ZGC** + bounded concurrency (Semaphore) | Pausas < 10 ms + sem OOM | Config |

### 7.2 Prioridade ALTA (Sprint 7 — refinamento)

| # | Otimização | Ganho | Esforço |
|---|-----------|-------|---------|
| 8 | **Timeout + fallback escalonado** Blossom (100 ms → esparso → guloso) | Elimina risco de explosão | Baixo |
| 9 | **Cluster cap adaptativo** por densidade geográfica (80-150) | Blossom mais rápido em áreas densas | Médio |
| 10 | **Redução de |V_odd|** pré-matching (pares adjacentes na MST) | ~20-40% menos vértices no Blossom | Médio |
| 11 | **Prim lazy** em vez de Kruskal (evita materializar n²/2 arestas) | ~60% menos memória na fase MST | Médio |
| 12 | **Routing API paralelo** (parallelStream para segmentos finais) | T_routing ~50 ms em vez de ~200 ms | Baixo |
| 13 | **Pré-computar distâncias de/para depots** (background job) | Cache quente, ~0 ms para depots | Baixo |

### 7.3 Prioridade MÉDIA (futuro)

| # | Otimização | Ganho | Esforço |
|---|-----------|-------|---------|
| 14 | **IDs int internos** em vez de UUID no engine | HashMap ~2× mais rápido | Refatoração grande |
| 15 | **Or-opt** além do 2-opt | ~5-10% melhor qualidade de rota | Médio |
| 16 | **Lin-Kernighan** em vez de 2-opt | ~10-15% melhor qualidade, mais lento | Alto |
| 17 | **Valhalla (value types)** quando disponível no Java | Menos boxing, menos GC | Futuro |
| 18 | **GraalVM native-image** para GraphHopper | Startup mais rápido | Alto |

---

## 8. Monitoramento de performance (métricas a coletar)

### 8.1 Métricas por job

| Métrica | Tag | Alerta se |
|---------|-----|-----------|
| `optimization.duration.ms` | algorithm=christofides | P95 > 10 s |
| `optimization.matrix.duration.ms` | source=graphhopper | P95 > 5 s |
| `optimization.blossom.duration.ms` | | > 500 ms |
| `optimization.twoopt.iterations` | | > 20 (convergência lenta) |
| `optimization.twoopt.improvement.pct` | | < 1% (já estava bom) |
| `optimization.cluster.count` | | > 15 (rota muito grande) |
| `optimization.cluster.max_size` | | > 200 (rebalancear) |
| `optimization.memory.peak.mb` | | > 500 MB |

### 8.2 Métricas de sistema

| Métrica | Alerta se |
|---------|-----------|
| `jvm.gc.pause.ms` (ZGC) | P99 > 15 ms |
| `jvm.gc.allocation.rate.mb_s` | > 500 MB/s sustentado |
| `jvm.heap.used.pct` | > 80% |
| `jvm.threads.live` (ForkJoinPool) | > 2× cores |
| `routing.jobs.concurrent` | > max_concurrent_jobs config |
| `routing.jobs.queued` | > 50 (backpressure) |
| `graphhopper.query.duration.ms` | P95 > 5 ms |

---

## 9. Comparativo: com e sem cada otimização

### 9.1 Impacto de remover clusterização (N = 1000)

| Métrica | Com cluster (c=150) | Sem cluster |
|---------|---------------------|-------------|
| T_blossom | ~50 ms × 7 parallel = ~50 ms | **~1.5 s** (n=1000, |V_odd|≈500) |
| T_matrix | ~1.1 s × 7 parallel = ~1.1 s | **~500 s** (500k pares) |
| T_2opt | ~45 ms × 7 parallel = ~45 ms | **~2 s** (n²=10⁶) |
| Memória pico | ~12.5 MB | **~400 MB** (500k arestas) |
| **T_total** | **~7 s** | **~504 s** ❌ |

**Conclusão**: sem clusterização, **inviável** para n > 300. A clusterização é o fator mais crítico de escala.

### 9.2 Impacto de usar Haversine vs GraphHopper Matrix

| Métrica | Haversine | GH Matrix (embarcado) | GH Matrix (HTTP) |
|---------|-----------|----------------------|-------------------|
| T_matrix por cluster | ~0 ms (inline) | ~1.1 s | ~4 s |
| Qualidade da ordem | Boa (ignora mão única/viadutos) | **Ótima** (custo real) | **Ótima** |
| T_total (1000 pts) | ~4 s | ~7 s | ~10 s |
| Rota passa em contramão? | Sim (na sequência) | Não | Não |

**Trade-off**: GH Matrix adiciona ~3 s ao total mas garante que a **ordem** dos waypoints reflete custo real na estrada.

### 9.3 Impacto de trocar Blossom por matching guloso

| Métrica | Blossom V (exato) | Matching guloso |
|---------|-------------------|-----------------|
| Garantia | 3/2-approx | Sem garantia |
| Qualidade prática | ~1.1-1.2× ótimo | ~1.3-1.8× ótimo |
| Tempo (n=150) | ~50-120 ms | ~5-10 ms |
| Risco de explosão | Sim (n > 300) | Não |

**Recomendação**: manter Blossom como padrão, com **fallback para guloso** se Blossom > 500 ms (timeout por cluster).

---

## 10. Decisões de design e trade-offs explícitos

| Decisão | Alternativa | Por que escolhemos |
|---------|-------------|-------------------|
| Cluster fixo c = 150 | Cluster dinâmico | Simplicidade; 150 mantém Blossom < 120 ms e Matrix < 1.5 s |
| Christofides + Blossom real | Christofides + matching guloso | Garantia 3/2; controlamos n via cluster |
| 2-opt (não 3-opt/LK) | Lin-Kernighan | 2-opt O(n²) é suficiente pós-Christofides; LK é O(n² log n) com ganho marginal |
| GraphHopper embarcado | OSRM via HTTP | Mesma JVM = sem latência de rede; Java = integração natural |
| K-means (seed fixa 42) | K-means++ / DBSCAN | Simples, reprodutível, bom o suficiente para clusters geográficos |
| ZGC | G1GC | Pausas < 10 ms críticas para jobs de 7 s (qualquer pausa > 100 ms é perceptível) |
| Cache de matriz (TTL 5 min) | Sem cache | Recálculos frequentes (desvio, incidente) → reuso alto |
| Bounded concurrency (4 jobs/instância) | Sem limite | Evita OOM e GC storm; circuit breaker complementa |

---

## 11. Modelo matemático: interpolação para estimativas

### Fórmula geral (tempo de um request) — COM otimizações agressivas

```
T(N) = T_kmeans(N) + ceil(N / c) / min(ceil(N / c), p) × T_solve(c) + (N - 1) × T_route_segment

Onde (otimizado):
  T_kmeans(N) ≈ 0.02 × N ms               (K-means, O(N))
  T_solve(c) ≈ T_matrix(c) + T_mst(c) + T_blossom(c) + T_2opt(c)
  T_matrix(c) ≈ k × c / p × t_gh          (k=15 vizinhos, p=8 threads, t_gh ≈ 0.05 ms CH embarcado)
  T_mst(c) ≈ 0.0005 × c² ms               (sort + Union-Find no grafo esparso)
  T_blossom(c) ≈ 0.001 × c × k_odd ms     (k_odd=7, grafo esparso)
  T_2opt(c) ≈ 5 × 0.002 × c² ms           (5 iterações, O(n²))
  T_route_segment ≈ 0.05 ms                (GH embarcado, CH, paralelo)

Simplificando para c = 100, p = 8:
  T_matrix(100) ≈ 15 × 100 / 8 × 0.05 ≈ 9 ms
  T_mst(100) ≈ 5 ms
  T_blossom(100) ≈ 4 ms
  T_2opt(100) ≈ 20 ms
  T_solve(100) ≈ 38 ms
  T(N) ≈ 0.02N + ceil(N/100)/min(ceil(N/100), 8) × 38 + 0.05(N-1) ms
```

### Tabela de referência rápida (OTIMIZADO)

| N | Clusters | Rounds (8 cores) | T_solve (paralelo) | T_routing (paralelo) | **T_total** |
|---|----------|-------------------|---------------------|---------------------|-------------|
| 50 | 1 | 1 | ~10 ms | ~2.5 ms | **~13 ms** |
| 100 | 1 | 1 | ~38 ms | ~5 ms | **~43 ms** |
| 200 | 2 | 1 | ~38 ms | ~10 ms | **~48 ms** |
| 300 | 3 | 1 | ~38 ms | ~15 ms | **~53 ms** |
| 500 | 5 | 1 | ~38 ms | ~25 ms | **~63 ms** |
| 700 | 7 | 1 | ~38 ms | ~35 ms | **~73 ms** |
| 1000 | 10 | 2 | ~76 ms | ~50 ms | **~126 ms** |
| 1500 | 15 | 2 | ~76 ms | ~75 ms | **~151 ms** |
| 2000 | 20 | 3 | ~114 ms | ~100 ms | **~214 ms** |
| 3000 | 30 | 4 | ~152 ms | ~150 ms | **~302 ms** |
| 5000 | 50 | 7 | ~266 ms | ~250 ms | **~516 ms** |

### Comparação: antes vs depois

| N | Baseline (GH embarcado, sem otimizações) | **Otimizado** | Speedup |
|---|------------------------------------------|---------------|---------|
| 100 | ~1.5 s | **~43 ms** | **35×** |
| 500 | ~1.6 s | **~63 ms** | **25×** |
| 1000 | ~1.7 s | **~126 ms** | **13×** |
| 2000 | ~3.4 s | **~214 ms** | **16×** |
| 5000 | ~8.5 s | **~516 ms** | **16×** |

### Interpretação

- **Até 700 pontos**: 1 round de paralelismo, **< 100 ms**.
- **1000 pontos**: 2 rounds, **~126 ms**. Imperceptível para o usuário.
- **5000 pontos**: ~500 ms. Ainda sub-segundo.
- **Componente mais lento**: T_routing (segmentos finais) e T_2opt passam a dominar.
- **Sem clusterização**: crescimento **cúbico** → para N = 1000, T ≈ 500+ s. Inviável.

---

## 12. Checklist de otimização por sprint

### Sprint 3 (Motor de otimização — performance máxima)
- [ ] Integrar GraphHopper como **dependência embarcada** (Maven, mesma JVM)
- [ ] Configurar **Contraction Hierarchies** (CH) para perfil `car`
- [ ] Implementar `ParallelDistanceMatrix` (k-nearest + paralelo + double[][])
- [ ] Implementar grafo esparso para Blossom (k=7 vizinhos por vértice ímpar)
- [ ] Implementar `GraphHopperSegmentRouter` (geometry por par, parallelStream)
- [ ] Cache multinível 3 níveis: L1 `ConcurrentHashMap` (TTL 5 min) + L2 Redis (TTL 15 min) + L3 pré-computado depots/pontos fixos (TTL 24 h, rebuild semanal com OSM)
- [ ] Configurar **ZGC** na JVM do routing-engine
- [ ] Bounded concurrency: `Semaphore(maxConcurrentJobs)` no `ParallelRouteEngine`
- [ ] Métricas: `optimization.duration.ms`, `matrix.duration.ms`, `blossom.duration.ms`
- [ ] Benchmark: 100, 500, 1000 pontos — target < 130 ms para 1000 pts

### Sprint 7 (Escalabilidade e refinamento)
- [ ] Timeout + fallback escalonado Blossom (100 ms → esparso k=5 → guloso)
- [ ] Cluster cap adaptativo por densidade geográfica (80-150)
- [ ] Redução de |V_odd| pré-matching (pares adjacentes na MST)
- [ ] Prim lazy (evita materializar n²/2 arestas, menos GC)
- [ ] Pré-computar distâncias de/para depots (background job)
- [ ] Testes de carga: 30 jobs concorrentes, medir GC pause e latência P95/P99
- [ ] Alertas: P95 > 400 ms, heap > 80%, GC pause > 15 ms
