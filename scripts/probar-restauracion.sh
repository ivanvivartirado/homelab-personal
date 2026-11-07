#!/bin/bash
# Prueba que la última copia se puede restaurar de verdad.
# Levanta un MariaDB desechable con la misma versión, carga el volcado y cuenta las tablas.
# Comprueba también que la copia lleva la base de Uptime Kuma y la configuración de WireGuard.
set -euo pipefail

BASE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$BASE"

# shellcheck source=/dev/null
source scripts/backup.env
export RESTIC_REPOSITORY RESTIC_PASSWORD_FILE

TMP="$(mktemp -d)"
PRUEBA=nexus-prueba-restauracion
limpiar() {
  docker rm -f "$PRUEBA" >/dev/null 2>&1 || true
  rm -rf "$TMP"
}
trap limpiar EXIT

echo "== $(date '+%F %T') Prueba de restauración"
restic snapshots --tag nexus --latest 1

# 1. Los archivos que no pueden faltar
for f in "data/uptime-kuma/kuma.db" "wireguard/config/wg_confs/wg0.conf"; do
  if restic ls latest --tag nexus "$BASE/$(dirname "$f")" | grep -q "/$(basename "$f")$"; then
    echo "OK  $f"
  else
    echo "FALTA  $f" >&2
    exit 1
  fi
done

# 2. El volcado de MariaDB se carga en una base limpia
restic dump latest --tag nexus "$BASE/backups/mariadb.sql" > "$TMP/mariadb.sql"
IMAGEN="$(docker inspect mariadb_homelab --format '{{.Config.Image}}')"
docker run -d --name "$PRUEBA" -e MARIADB_ROOT_PASSWORD=prueba "$IMAGEN" >/dev/null

# Espera al servidor definitivo: el de arranque inicial no escucha por TCP
for _ in $(seq 60); do
  if docker exec "$PRUEBA" mariadb -uroot -pprueba -h127.0.0.1 --protocol=tcp -e 'SELECT 1' >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

docker exec -i "$PRUEBA" mariadb -uroot -pprueba -h127.0.0.1 --protocol=tcp < "$TMP/mariadb.sql"
TABLAS="$(docker exec "$PRUEBA" mariadb -uroot -pprueba -h127.0.0.1 --protocol=tcp -N -e \
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema NOT IN ('information_schema','performance_schema','mysql','sys')")"

if [ "$TABLAS" -gt 0 ]; then
  echo "OK  MariaDB restaurada con $TABLAS tablas ($IMAGEN)"
else
  echo "FALLO  el volcado no tiene tablas" >&2
  exit 1
fi

echo "== $(date '+%F %T') La copia se restaura bien"
