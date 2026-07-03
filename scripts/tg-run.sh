#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# tg-run.sh — run `terragrunt run-all <action>` scoped to only the changed units of one environment.
#
#   scripts/tg-run.sh <plan|apply> <env> [base_ref]
#
# Uses scripts/changed-units.sh to discover affected units, then restricts the run-all queue to
# those units with --terragrunt-strict-include, preserving inter-unit dependency ordering.
# Exits 0 (no-op) when the environment has no changes.
# ---------------------------------------------------------------------------------------------------------------------
set -euo pipefail

ACTION="${1:?usage: tg-run.sh <plan|apply> <env> [base_ref]}"
ENV="${2:?usage: tg-run.sh <plan|apply> <env> [base_ref]}"
BASE="${3:-${BASE_REF:-origin/main}}"

case "$ACTION" in plan|apply) ;; *) echo "tg-run.sh: action must be plan or apply" >&2; exit 2 ;; esac

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

mapfile -t units < <("${ROOT}/scripts/changed-units.sh" "$ENV" "$BASE")

if [[ ${#units[@]} -eq 0 ]]; then
  echo "==> [${ENV}] no changed units vs ${BASE}; skipping ${ACTION}."
  exit 0
fi

echo "==> [${ENV}] changed units to ${ACTION}:"
printf '      %s\n' "${units[@]}"

include_args=()
for u in "${units[@]}"; do
  include_args+=(--terragrunt-queue-include-dir "${u#live/${ENV}/}")
done

cd "live/${ENV}"
exec terragrunt run-all "$ACTION" \
  --terragrunt-non-interactive \
  --terragrunt-strict-include \
  "${include_args[@]}"
