# iac

Infrastructure-as-Code for GCP using **Terraform** + **Terragrunt**, with local emulator
testing via **floci-gcp** and **plan/apply CI/CD** on GitHub Actions.

## Layout

```
.
├── root.hcl                 # DRY root: remote state (GCS) + provider generation
├── modules/                 # Local modules, versioned in this repo
│   ├── gcs-bucket/
│   └── network/
├── live/                    # Deployable units, one dir per environment
│   ├── _envcommon/          # Shared per-component config (DRY includes)
│   ├── dev/
│   │   ├── env.hcl          # project_id / region / environment
│   │   ├── network/
│   │   ├── gcs-bucket/
│   │   └── external-bucket/ # Consumes a module from an EXTERNAL repo
│   └── prod/
├── test/                    # floci-gcp emulator + `terraform test` suites
└── .github/workflows/       # test (PR) · plan (PR) · apply (main)
```

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

## Common tasks

```bash
make fmt          # format tf + hcl
make validate     # CI-parity formatting check
make test         # infra tests against floci-gcp
make plan  ENV=dev
make apply ENV=prod
```

## Testing (floci-gcp)

`make test` boots the [floci-gcp](https://github.com/floci-io/floci-gcp) emulator on
`localhost:4588`, points the google provider at it, and runs native `terraform test`
suites that apply real resources and assert on outputs — no cloud account required.
See [`test/README.md`](test/README.md).

## CI/CD

| Workflow | Trigger | Does |
| --- | --- | --- |
| `test` | PR | `fmt`/`hclfmt` checks + floci-gcp infra tests |
| `plan` | PR touching `live/**`, `modules/**` | `terragrunt run-all plan` per env, posted as a PR comment |
| `apply` | push to `main` | `terragrunt run-all apply`, `dev` then `prod` |

Auth uses **Workload Identity Federation** (no static keys). Configure once:

- Repo variable `GCP_WORKLOAD_IDENTITY_PROVIDER` — the WIF provider resource name.
- Repo variables `DEV_DEPLOYER_SA` / `PROD_DEPLOYER_SA` — deployer service account emails.
- GitHub Environments `development` and `production`; add required reviewers to
  `production` so prod applies pause for manual approval.
