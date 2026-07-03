#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# changed-units.sh — list the Terragrunt units in one environment affected by a diff.
#
#   scripts/changed-units.sh <env> [base_ref]
#
#   <env>       sandbox | test | prd
#   base_ref    git ref/SHA to diff HEAD against (default: $BASE_REF or origin/main)
#
# Prints one repo-relative unit directory per line (e.g. `live/sandbox/network`), sorted.
# Prints nothing (exit 0) when the environment has no affected units.
#
# Blast-radius rules (deliberately conservative — infra safety over minimal plans):
#   root.hcl, .tool-versions           -> every unit in the environment
#   modules/**                         -> every unit in the environment (shared, high blast radius)
#   live/_envcommon/<component>.hcl    -> the <component> unit in the environment
#   live/<env>/<unit>/**               -> that specific unit (nearest ancestor holding terragrunt.hcl)
#   live/<other-env>/**                -> ignored for this environment
# ---------------------------------------------------------------------------------------------------------------------
set -euo pipefail

ENV="${1:?usage: changed-units.sh <env> [base_ref]}"
BASE="${2:-${BASE_REF:-origin/main}}"

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

if [[ ! -d "live/${ENV}" ]]; then
  echo "changed-units.sh: unknown environment '${ENV}' (no live/${ENV})" >&2
  exit 2
fi

# Resolve the diff. Prefer merge-base (three-dot) against a real ref; fall back sanely
# for CI push events where BASE may be a bare SHA or the zero-SHA of a new branch.
resolve_changed() {
  if git rev-parse --verify --quiet "${BASE}^{commit}" >/dev/null; then
    git diff --name-only "${BASE}...HEAD"
  elif git rev-parse --verify --quiet "HEAD~1" >/dev/null; then
    # Unresolvable base (e.g. all-zero SHA): compare against the previous commit.
    git diff --name-only "HEAD~1" HEAD
  else
    # First commit in history: treat every tracked file as changed.
    git ls-files
  fi
}

# Find the nearest ancestor directory of $1 that contains a terragrunt.hcl, bounded to live/$ENV.
nearest_unit() {
  local dir; dir="$(dirname "$1")"
  while [[ "$dir" == live/${ENV}/* || "$dir" == "live/${ENV}" ]]; do
    [[ -f "${dir}/terragrunt.hcl" ]] && { printf '%s\n' "$dir"; return; }
    dir="$(dirname "$dir")"
  done
}

# Emit every unit in the environment.
all_units() {
  find "live/${ENV}" -mindepth 1 -maxdepth 2 -name terragrunt.hcl -printf '%h\n'
}

declare -A units=()
add() { [[ -n "${1:-}" && -f "${1}/terragrunt.hcl" ]] && units["$1"]=1; }

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  case "$f" in
    root.hcl|.tool-versions|modules/*)
      while IFS= read -r u; do add "$u"; done < <(all_units)
      ;;
    live/_envcommon/*.hcl)
      comp="$(basename "$f" .hcl)"
      add "live/${ENV}/${comp}"
      ;;
    live/${ENV}/*)
      add "$(nearest_unit "$f")"
      ;;
    *) : ;; # other environments / unrelated files
  esac
done < <(resolve_changed)

[[ ${#units[@]} -eq 0 ]] && exit 0
printf '%s\n' "${!units[@]}" | sort
