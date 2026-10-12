#!/usr/bin/env bash
set -euo pipefail
: "${PG_CONTAINER:?Set a run-, attempt- and job-owned container name}"
case "$PG_CONTAINER" in vod-ci-*) ;; *) echo 'Refusing a non-CI container name' >&2; exit 1 ;; esac
case "${1:-}" in
  start)
    : "${GITHUB_ENV:?}"
    if docker inspect --type container "$HOSTNAME" >/dev/null 2>&1; then
      network_args=(--network "container:$HOSTNAME")
      pg_port=5432
    else
      network_args=(-p 127.0.0.1::5432)
      pg_port=''
    fi
    docker run -d --name "$PG_CONTAINER" --label "vod.ci-owner=$PG_CONTAINER" "${network_args[@]}" \
      -e POSTGRES_USER=vod_test -e POSTGRES_PASSWORD=vod_test -e POSTGRES_DB=vod_test postgres:16
    for _attempt in $(seq 1 60); do
      if docker exec "$PG_CONTAINER" pg_isready -h 127.0.0.1 -U vod_test -d vod_test; then break; fi
      sleep 1
    done
    docker exec "$PG_CONTAINER" pg_isready -h 127.0.0.1 -U vod_test -d vod_test
    if [ -z "$pg_port" ]; then
      binding=$(docker port "$PG_CONTAINER" 5432/tcp)
      pg_port=${binding##*:}
    fi
    [[ "$pg_port" =~ ^[0-9]+$ ]]
    for key in DB_DSN TEST_PG_DSN; do
      printf '%s=postgres://vod_test:vod_test@127.0.0.1:%s/vod_test?sslmode=disable\n' "$key" "$pg_port" >> "$GITHUB_ENV"
    done
    ;;
  seed-e2e)
    owner=$(docker inspect -f '{{index .Config.Labels "vod.ci-owner"}}' "$PG_CONTAINER")
    test "$owner" = "$PG_CONTAINER"
    docker exec -i "$PG_CONTAINER" psql --no-psqlrc -v ON_ERROR_STOP=1 -U vod_test -d vod_test \
      < "$(dirname "${BASH_SOURCE[0]}")/ci-e2e-fixtures.sql"
    ;;
  stop)
    if docker inspect "$PG_CONTAINER" >/dev/null 2>&1; then
      owner=$(docker inspect -f '{{index .Config.Labels "vod.ci-owner"}}' "$PG_CONTAINER")
      test "$owner" = "$PG_CONTAINER"
      docker rm -f "$PG_CONTAINER"
    fi
    ;;
  *) echo 'Usage: ci-postgres.sh start|seed-e2e|stop' >&2; exit 2 ;;
esac
