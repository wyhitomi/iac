# Infrastructure tests (floci-gcp)

Tests run real Terraform provider calls against [floci-gcp](https://github.com/floci-io/floci-gcp),
a free local GCP emulator, so they need **no cloud account, credentials, or spend**.

## Layout

| Path | Purpose |
| --- | --- |
| `docker-compose.yml` | Runs the floci-gcp emulator on `localhost:4588`. |
| `floci/` | A Terraform fixture wiring a module to the emulator's endpoints. |
| `floci/tests/*.tftest.hcl` | Native `terraform test` suites (apply + assert + auto-destroy). |
| `run.sh` | Boots the emulator, runs the suite, tears it down. |

## Run locally

```bash
./test/run.sh
```

Requires Docker and Terraform ≥ 1.6. The same script runs in CI (see
`.github/workflows/test.yml`).

## How the emulator is wired in

The google provider in `floci/main.tf` overrides its service endpoints
(e.g. `storage_custom_endpoint`) to point at `http://localhost:4588`, and uses a
static fake token so it never reaches for real credentials. To cover more services,
add the relevant `*_custom_endpoint` override and a new `*.tftest.hcl` file.
