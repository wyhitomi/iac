#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# changed-units.sh — list the Terragrunt units in one environment affected by a diff.
#
#   scripts/changed-units.sh <env_path> [base_ref]
#
#   <env_path>  path relative to env/, e.g. `local`, `gcp/sandbox`, `gcp/tst`, `gcp/prd`
#               (a future cloud just adds a new subtree, e.g. `aws/sandbox` — nothing here
#               is hardcoded to a specific cloud name)
#   base_ref    git ref/SHA to diff HEAD against (default: $BASE_REF or origin/main)
#
# Prints one repo-relative unit directory per line (e.g. `env/gcp/sandbox/network`), sorted.
# Prints nothing (exit 0) when the environment has no affected units.
#
# Blast-radius rules (deliberately conservative — infra safety over minimal plans):
#   modules/**, .tool-versions           -> every unit in the environment
#   the cloud's root.hcl (nearest         -> every unit in the environment (backend/provider
#     ancestor of env/<env_path>)            wiring changed for the whole cloud)
#   env/_envcommon/<component>.hcl       -> the <component> unit in the environment (shared
#                                            across every cloud, so high blast radius but
#                                            scoped to that one component)
#   env/<env_path>/<unit>/**             -> that specific unit
#   env/<other_env_path>/**              -> ignored for this environment
# ---------------------------------------------------------------------------------------------------------------------
set -euo pipefail

ENV_PATH="${1:?usage: changed-units.sh <env_path> [base_ref]}"
BASE="${2:-${BASE_REF:-origin/main}}"

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

if [[ ! -d "env/${ENV_PATH}" ]]; then
  echo "changed-units.sh: unknown environment 'env/${ENV_PATH}'" >&2
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

# The root.hcl that governs this environment: nearest ancestor of env/<env_path> that has one.
# For `env/gcp/sandbox` that's `env/gcp/root.hcl`; for `env/local` (flat, one env per cloud)
# it's `env/local/root.hcl` itself.
nearest_root() {
  local dir="env/${ENV_PATH}"
  while [[ "$dir" == env* ]]; do
    [[ -f "${dir}/root.hcl" ]] && { printf '%s\n' "${dir}/root.hcl"; return; }
    [[ "$dir" == "env" ]] && return
    dir="$(dirname "$dir")"
  done
}

# Find the nearest ancestor directory of $1 that contains a terragrunt.hcl, bounded to env/<env_path>.
nearest_unit() {
  local dir; dir="$(dirname "$1")"
  while [[ "$dir" == env/${ENV_PATH}/* || "$dir" == "env/${ENV_PATH}" ]]; do
    [[ -f "${dir}/terragrunt.hcl" ]] && { printf '%s\n' "$dir"; return; }
    dir="$(dirname "$dir")"
  done
}

# Emit every unit in the environment.
all_units() {
  find "env/${ENV_PATH}" -mindepth 1 -maxdepth 2 -name terragrunt.hcl -printf '%h\n'
}

declare -A units=()
add() { [[ -n "${1:-}" && -f "${1}/terragrunt.hcl" ]] && units["$1"]=1; }
fan_out_all() { while IFS= read -r u; do add "$u"; done < <(all_units); }

root_file="$(nearest_root)"

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if [[ "$f" == ".tool-versions" || "$f" == modules/* ]]; then
    fan_out_all
  elif [[ -n "$root_file" && "$f" == "$root_file" ]]; then
    fan_out_all
  elif [[ "$f" == env/_envcommon/*.hcl ]]; then
    comp="$(basename "$f" .hcl)"
    add "env/${ENV_PATH}/${comp}"
  elif [[ "$f" == env/${ENV_PATH}/* ]]; then
    add "$(nearest_unit "$f")"
  fi
  # else: belongs to another env_path or is unrelated — ignore.
done < <(resolve_changed)

[[ ${#units[@]} -eq 0 ]] && exit 0
printf '%s\n' "${!units[@]}" | sort
