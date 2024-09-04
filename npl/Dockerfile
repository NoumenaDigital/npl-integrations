FROM ghcr.io/noumenadigital/packages/engine:2024.2.1

LABEL org.opencontainers.image.source = "https://github.com/noumenadigital/npl-integrations"

ENV ENGINE_NPL_MIGRATION_DIRECTORY_PATH="/npl"

COPY src/main/yaml /npl/yaml
COPY src/main/npl  /npl/npl-1.0
