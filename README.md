# iac

Infrastructure-as-Code using **Terraform** + **Terragrunt**, designed for **multicloud**,
with local emulator testing via **floci-gcp** and change-aware **plan/apply CI/CD** on
GitHub Actions.

## Layout

```
.
├── modules/                  # Local modules, versioned in this repo, cloud-specific by nature
│   ├── gcs-bucket/           # (GCP today; an `aws/` or `azure/` cloud adds its own modules)
│   └── network/
├── env/                      # Deployable units, grouped first by cloud, then by environment
│   ├── _envcommon/           # Shared per-component config (DRY includes), reused across clouds
│   │                         # as long as the underlying module/provider is shared (all GCP-based
│   │                         # today). A cloud needing divergent config gets its own _envcommon.
│   ├── local/                # Flat "cloud": floci-gcp emulator, no environment split
│   │   ├── root.hcl          # local state backend + google provider pointed at the emulator
│   │   ├── env.hcl
│   │   └── gcs-bucket/
│   └── gcp/
│       ├── root.hcl          # GCS remote state + real google provider generation
│       ├── sandbox/
│       │   ├── env.hcl       # project_id / region / environment
│       │   ├── network/
│       │   ├── gcs-bucket/
│       │   └── external-bucket/  # Consumes a module from an EXTERNAL repo
│       ├── tst/
│       └── prd/
├── scripts/                  # Change detection + run wrappers used by make and CI
│   ├── changed-units.sh
│   └── tg-run.sh
├── test/                     # floci-gcp emulator + `terraform test` suites
└── .github/workflows/        # test (PR) · plan (PR) · apply (main)
```

**Multicloud shape:** each cloud is a top-level directory under `env/` with its own
`root.hcl` (state backend + provider wiring, which necessarily differs per cloud) and,
below that, one directory per environment. Adding a cloud means adding `env/<cloud>/root.hcl`
plus its environment directories and, if the modules differ, a `modules/<cloud-specific>/`
tree — the scripts, Makefile, and workflows below need no changes to pick it up.

**Environments today:** `env/local` (floci-gcp emulator, dev-only) and, on GCP,
`env/gcp/{sandbox,tst,prd}`, each backed by its own GCP project. `env/local` has no
`network` unit yet — floci-gcp's Compute Engine/VPC emulation isn't confirmed, so that
module is only exercised against `test/` and real GCP for now.

## Prerequisites

- Terraform `1.14.5`, Terragrunt `0.72.6` (pinned in `.tool-versions` — `asdf install`)
- Docker (for `floci-gcp`, used by both `env/local` and `test/`)
- A GCS bucket per GCP project named `<project_id>-tfstate` for remote state

## Modules: local *or* external

Units declare where their module comes from in `env/_envcommon/*.hcl`:

- **Local** (this repo) — `modules/gcs-bucket`, `modules/network`:
  ```hcl
  terraform { source = "${get_repo_root()}/modules/gcs-bucket" }
  ```
- **External** (another repo), pinned to an immutable ref — see `_envcommon/external-bucket.hcl`:
  ```hcl
  terraform {
    source = "git::https://github.com/org/modules.git//path?ref=v1.2.3"
  }
  ```
  Private repos work the same way over SSH (`git::ssh://git@github.com/...`).

## Change detection

CI does **not** plan/apply everything on every change. `scripts/changed-units.sh` diffs a
PR (or a merge) against a base ref and prints the affected Terragrunt units for one
environment; `scripts/tg-run.sh` then runs `terragrunt run-all` scoped to exactly those
units (`--terragrunt-strict-include`), preserving dependency order and no-op'ing when
nothing changed.

An environment is identified as a path relative to `env/`, e.g. `local`, `gcp/sandbox`,
`gcp/tst`, `gcp/prd` — adding a cloud just adds new valid paths, nothing to update.

Blast-radius rules (conservative by design — infra safety over minimal plans):

| Changed path | Affected units |
| --- | --- |
| `env/<env_path>/<unit>/**` | that single unit |
| `env/_envcommon/<component>.hcl` | the `<component>` unit in the env (any cloud) |
| the cloud's `root.hcl` (nearest ancestor of `env/<env_path>`) | every unit in that environment |
| `modules/**`, `.tool-versions` | every unit in the env |

```bash
make changes ENV=gcp/tst            # list changed units for one env
make changes-all                    # list changed units across all envs (all clouds)
BASE=origin/release make changes    # diff against a different base ref
```

## Common tasks

```bash
make fmt                  # format tf + hcl
make validate             # CI-parity formatting check
make test                 # infra tests against floci-gcp
make plan  ENV=local       # plan only changed units in one env
make apply ENV=gcp/prd     # apply only changed units in one env
make plan-all              # plan changed units across every env (all clouds)
```

`ENV` defaults to `gcp/sandbox` and `BASE` to `origin/main`.

## Testing (floci-gcp)

`make test` boots the [floci-gcp](https://github.com/floci-io/floci-gcp) emulator on
`localhost:4588`, points the google provider at it, and runs native `terraform test`
suites that apply real resources and assert on outputs — no cloud account required.
See [`test/README.md`](test/README.md).

`env/local` uses the same emulator for interactive `terragrunt plan/apply` iteration
(as opposed to `test/`'s automated `terraform test` suites): start it with
`docker compose -f test/docker-compose.yml up -d`, then `make plan ENV=local`.

## CI/CD

| Workflow | Trigger | Does |
| --- | --- | --- |
| `test` | PR | `fmt`/`hclfmt` checks + floci-gcp infra tests |
| `plan` | PR touching `env/**`, `modules/**`, `scripts/**` | Detects changed units per env, plans only those, posts a per-env PR comment |
| `apply` | push to `main` | Diffs the merged range, applies only changed units, `gcp/sandbox` → `gcp/tst` → `gcp/prd` |

Both `plan` and `apply` matrix over the real-cloud environments (`gcp/sandbox`, `gcp/tst`,
`gcp/prd` today); `env/local` is a developer convenience and is not deployed by CI. An
environment with no changes is skipped entirely (no auth, no run).

Auth uses **Workload Identity Federation** (no static keys). Configure once:

- Repo variable `GCP_WORKLOAD_IDENTITY_PROVIDER` — the WIF provider resource name.
- Repo variables `GCP_SANDBOX_DEPLOYER_SA` / `GCP_TST_DEPLOYER_SA` / `GCP_PRD_DEPLOYER_SA` —
  deployer service account emails per environment.
- GitHub Environments `sandbox`, `tst`, `production`; add required reviewers to
  `production` so prd applies pause for manual approval.

A future non-GCP cloud follows the same pattern: its own `<CLOUD>_WORKLOAD_IDENTITY_PROVIDER`
(or equivalent) and `<CLOUD>_<ENV>_DEPLOYER_*` variables, plus new matrix entries in
`plan.yml`/`apply.yml`.
