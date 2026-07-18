# Armhf remote Docker contract

Abstract roles only. No hostnames, usernames, IPs, or live endpoints in git.

## What agents need

- armv7 jobs run on the **ARM64 self-hosted runner** (JS actions / checkout).
- Image build / smoke / push use a **remote native armhf Docker daemon** via `DOCKER_HOST`.
- Value comes from GitHub Actions repository variable **`ARMHF_DOCKER_HOST`** → workflow input `docker_host` → job env `DOCKER_HOST`.
- Wiring: `make-multi-arch-image.yml` passes `docker_host: ${{ vars.ARMHF_DOCKER_HOST }}` on armv7 jobs only.

## Variable format (placeholders only)

GitHub → **Settings → Secrets and variables → Actions → Variables** → `ARMHF_DOCKER_HOST`.

| Form | Pattern | Notes |
|------|---------|--------|
| Preferred | `ssh://<user>@<host>` | `<host>` = SSH config Host alias or name resolvable **from the ARM64 runner** |
| With port | `ssh://<user>@<host>:<port>` | Non-default SSH port |

Docker’s `DOCKER_HOST` SSH scheme is documented by Docker; keep the value **out of git**.

## Failure modes

| Condition | What happens |
|-----------|----------------|
| Variable empty / unset | `DOCKER_HOST` empty → Docker uses the **local** daemon on the ARM64 runner. That is **not** native armhf; arm/v7 builds are wrong or slow (emulation). Fix: set the variable. |
| Variable set, SSH/Docker broken | Preflight / build fails (SSH or daemon). Fix on the runner, not by committing endpoints. |

## Operator setup (not in this repo)

Lives only on the runners:

- Passwordless, non-interactive SSH (`BatchMode=yes`, key auth).
- Optional `~/.ssh/config` Host alias + `IdentityFile` / `Hostname`.
- Remote user can access the Docker socket (e.g. `docker` group).

Agents must **not** invent or commit real values. Document format and contracts only.
