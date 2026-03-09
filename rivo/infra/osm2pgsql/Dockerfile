FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        lua-dkjson \
        osm2pgsql \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["osm2pgsql"]
