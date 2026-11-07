#!/bin/bash
# Copia de seguridad de Nexus Node con restic.
# Guarda un volcado de MariaDB y los datos de los servicios, y borra las copias viejas.
# Se lanza desde el cron de root (ver README).
set -euo pipefail

BASE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$BASE"

# RESTIC_REPOSITORY y RESTIC_PASSWORD_FILE
# shellcheck source=/dev/null
source scripts/backup.env
export RESTIC_REPOSITORY RESTIC_PASSWORD_FILE

echo "== $(date '+%F %T') Copia de Nexus Node"

# 1. Volcado de MariaDB (sin las bases del sistema)
mkdir -p backups
# shellcheck disable=SC2016  # la variable se expande dentro del contenedor
mapfile -t BASES < <(docker exec mariadb_homelab sh -c 'mariadb -uroot -p"$MYSQL_ROOT_PASSWORD" -N -e "SHOW DATABASES"' \
  | grep -Ev '^(information_schema|performance_schema|mysql|sys)$')
# shellcheck disable=SC2016
docker exec mariadb_homelab sh -c 'mariadb-dump -uroot -p"$MYSQL_ROOT_PASSWORD" --single-transaction --routines --events --databases "$@"' \
  sh "${BASES[@]}" > backups/mariadb.sql
echo "Volcado de MariaDB: ${BASES[*]} ($(du -h backups/mariadb.sql | cut -f1))"

# 2. Uptime Kuma usa SQLite: se para un momento para copiar la base sin que esté a medias
docker compose stop uptime-kuma
trap 'docker compose start uptime-kuma' EXIT

restic backup --tag nexus \
  "$BASE/backups" \
  "$BASE/data/uptime-kuma" \
  "$BASE/data/dozzle" \
  "$BASE/wireguard/config" \
  "$BASE/fail2ban/data/jail.d" \
  "$BASE/.env" \
  "$BASE/scripts/.env"

docker compose start uptime-kuma
trap - EXIT

# 3. Una copia por día de la última semana, una por semana del último mes y una por mes de medio año
restic forget --tag nexus --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
restic check

echo "== $(date '+%F %T') Copia terminada"
