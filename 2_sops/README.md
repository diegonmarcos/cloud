# 2_sops — where sops work happens

A working directory, not a repo group. The repo symlinks at this repo's root
and the one under `2_vault/` point out to clones; this directory holds real
files.

Encrypted material and the tooling that touches it live in their own repos and
stay there — moving either would break the ship pipeline that consumes them.
What belongs here is the *operating* surface: the commands you run, the
runbooks for rotation and re-keying, and anything that spans repos and so has
no natural home in one of them.

## Where the pieces actually are

| what | where | note |
|---|---|---|
| age recipients + creation rules | `cloud/.sops.yaml` | one recipient today: `age1u575hx…qxtd7pq` |
| encrypted secrets | `2_vault/vault/A1_Cloud-secrets/*.secrets` | per-service |
| keys, providers, OCI | `2_vault/vault/A0_keys/` | `keys/`, `providers/`, `oci/` |
| decrypt during deploy | `cloud/1_cicd/src/scripts/cloud-ship-nix-homemanager-step-secrets-decrypt.sh` | |
| per-repo secret shipping | `…/cloud-ship-repo-secrets.sh`, `…/cloud-ship-ci-builder-secrets.sh` | |
| coverage audit | `…/1_cicd/src/ops/audit-credentials-coverage.sh` | |

Those paths are written as they appear from **this** repo, so they resolve
through the symlinks once the relevant repos are cloned
(`./clone.sh vault cloud`). A path that does not resolve means you have not
cloned that repo yet — not that it moved.

## What sops encrypts

Four `creation_rules` patterns in `.sops.yaml`, all to the same age recipient:

```
secrets.yaml            per-service secrets
secrets_backup.yaml     backup copies
jwks_key.yaml           JWKS signing keys
terraform.tfstate.enc   tfstate, encrypted so it can live in a public repo
```

## Deliberately NOT here

- **No keys, no decrypted material.** Ever. This directory is committed to a
  public repo; `2_vault/` is the private one, and it stays the only place
  secrets live.
- **No copies of the ship scripts.** They are consumed by the pipeline from
  `9_others/`, and a second copy here would be the same drift trap that let
  vault's `.mcp.json` fall behind cloud's.
