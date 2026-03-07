-- Extensões necessárias (PostGIS + trigram para buscas por nome)
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Schema para dados geográficos do OSM
CREATE SCHEMA IF NOT EXISTS geo;
