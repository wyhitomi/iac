# iac

Infrastructure-as-Code for GCP using **Terraform** + **Terragrunt**, with local emulator
testing via **floci-gcp** and **change-aware plan/apply CI/CD** on GitHub Actions.

## Layout

```
.
├── root.hcl                 # DRY root: remote state (GCS) + provider generation
├── modules/                 # Local modules, versioned in this repo
│   ├── gcs-bucket/
│   └── network/
├── live/                    # Deployable units, one dir per environment
│   ├── _envcommon/          # Shared per-component config (DRY includes)
│   ├── sandbox/
│   │   ├── env.hcl          # project_id / region / environment
│   │   ├── network/
│   │   ├── gcs-bucket/
│   │   └── external-bucket/ # Consumes a module from an EXTERNAL repo
│   ├── test/
│   └── prd/
├── scripts/                 # Change detection + run wrappers used by make and CI
│   ├── changed-units.sh
│   └── tg-run.sh
├── test/                    # floci-gcp emulator + `terraform test` suites
└── .github/workflows/       # test (PR) · plan (PR) · apply (main)
```

Environments: **`sandbox`** → **`test`** → **`prd`**, each backed by its own GCP project.

## Prerequisites

- Terraform `1.14.5`, Terragrunt `0.72.6` (pinned in `.tool-versions` — `asdf install`)
- Docker (for `floci-gcp` tests)
- A GCS bucket per project named `<project_id>-tfstate` for remote state

## Modules: local *or* external

Units declare where their module comes from in `live/_envcommon/*.hcl`:

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

CI does **not** plan/apply everything on every change. `scripts/changed-units.sh`
diffs a PR (or a merge) against a base ref and prints the affected Terragrunt units for
one environment; `scripts/tg-run.sh` then runs `terragrunt run-all` scoped to exactly
those units (`--terragrunt-strict-include`), preserving dependency order and no-op'ing
when nothing changed.

Blast-radius rules (conservative by design — infra safety over minimal plans):

| Changed path | Affected units |
| --- | --- |
| `live/<env>/<unit>/**` | that single unit |
| `live/_envcommon/<component>.hcl` | the `<component>` unit in the env |
| `modules/**` | every unit in the env (shared modules are high blast radius) |
| `root.hcl`, `.tool-versions` | every unit in the env |

```bash
make changes ENV=test              # list changed units for one env
make changes-all                   # list changed units across all envs
BASE=origin/release make changes   # diff against a different base ref
```

## Common tasks

```bash
make fmt                 # format tf + hcl
make validate            # CI-parity formatting check
make test                # infra tests against floci-gcp
make plan  ENV=sandbox   # plan only changed units in one env
make apply ENV=prd       # apply only changed units in one env
make plan-all            # plan changed units across sandbox, test, prd
```

`ENV` defaults to `sandbox` and `BASE` to `origin/main`.

## Testing (floci-gcp)

`make test` boots the [floci-gcp](https://github.com/floci-io/floci-gcp) emulator on
`localhost:4588`, points the google provider at it, and runs native `terraform test`
suites that apply real resources and assert on outputs — no cloud account required.
See [`test/README.md`](test/README.md).

## CI/CD

| Workflow | Trigger | Does |
| --- | --- | --- |
| `test` | PR | `fmt`/`hclfmt` checks + floci-gcp infra tests |
| `plan` | PR touching `live/**`, `modules/**`, `scripts/**` | Detects changed units per env, plans only those, posts a per-env PR comment |
| `apply` | push to `main` | Diffs the merged range, applies only changed units, `sandbox` → `test` → `prd` |

Both `plan` and `apply` run a matrix over `sandbox`, `test`, and `prd`; an environment
with no changes is skipped.

Auth uses **Workload Identity Federation** (no static keys). Configure once:

- Repo variable `GCP_WORKLOAD_IDENTITY_PROVIDER` — the WIF provider resource name.
- Repo variables `SANDBOX_DEPLOYER_SA` / `TEST_DEPLOYER_SA` / `PRD_DEPLOYER_SA` — deployer
  service account emails per environment.
- GitHub Environments `sandbox`, `test`, `production`; add required reviewers to
  `production` so prd applies pause for manual approval.
