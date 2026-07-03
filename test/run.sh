#!/usr/bin/env bash
# Run the infra test suite against a local floci-gcp emulator.
#
#   ./test/run.sh
#
# Brings up floci-gcp via docker compose, runs `terraform test`, and tears the
# emulator down afterwards regardless of the test outcome.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
FIXTURE_DIR="${SCRIPT_DIR}/floci"

compose() { docker compose -f "${COMPOSE_FILE}" "$@"; }

cleanup() {
  echo "==> Tearing down floci-gcp"
  compose down --volumes --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "==> Starting floci-gcp emulator"
compose up -d --wait

echo "==> Running terraform test"
terraform -chdir="${FIXTURE_DIR}" init -backend=false -input=false >/dev/null
terraform -chdir="${FIXTURE_DIR}" test

echo "==> Tests passed"
