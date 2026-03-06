# Dados locais (GraphHopper) — desenvolvimento

Esta pasta é usada **apenas em modo local** (`routing.graphhopper.local: true`).

## O que colocar aqui

| Item | Descrição |
|------|-----------|
| **`brazil-latest.osm.pbf`** | Extract OSM do Brasil (Geofabrik). Na primeira subida, o GraphHopper importa esse arquivo e gera o grafo. |
| **`graph-cache/`** | Pasta criada automaticamente pelo GraphHopper após a primeira importação. Contém o grafo pré-processado (Contraction Hierarchies). Nas próximas subidas o app carrega daqui em vez de reimportar o PBF. |

## Como obter o PBF

1. Acesse [Geofabrik — South America](https://download.geofabrik.de/south-america.html).
2. Baixe **Brazil** → `brazil-latest.osm.pbf`.
3. Coloque o arquivo nesta pasta como:  
   `skeleton/data/brazil-latest.osm.pbf`

Ou use outra região e configure no `application.yml`:

```yaml
routing:
  graphhopper:
    osm-file: data/sua-regiao-latest.osm.pbf
    graph-location: data/graph-cache
```

## Observações

- **Não versionar** `*.osm.pbf` nem `graph-cache/` no Git (arquivos grandes). O `.gitignore` deve ignorar `data/*.pbf` e `data/graph-cache/`.
- Em produção (AWS), o app usa o grafo pré-processado no S3; esta pasta não é usada.
