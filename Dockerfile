# easy-stock backend container.
#
# The Go toolchain is not present in the local Docker registry, so the backend
# is cross-compiled on the host (statically linked, CGO_ENABLED=0) and shipped
# into a small alpine image.
FROM alpine:latest

RUN apk add --no-cache ca-certificates tini && \
    mkdir -p /app/data && \
    chown nobody:nogroup /app/data

WORKDIR /app

COPY --chown=nobody:nobody build/easy-stock-backend /app/easy-stock-backend
COPY --chown=nobody:nobody backend /app/backend
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

USER nobody

# Data lives in /app/data: databases, logs and the Hermes/Codex runtime state.
# A host volume may be mounted here; the entrypoint fixes up ownership.
ENV HOME=/app/data \
    DATA_DIR=/app/data \
    A_STOCK_ADDR="0.0.0.0:20081" \
    A_STOCK_HERMES_HOME=/app/data/hermes-home \
    A_STOCK_CODEX_HOME=/app/data/codex-home \
    A_STOCK_MASTERY_CACHE=/app/data/trading-mastery

EXPOSE 20081

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["/app/easy-stock-backend"]