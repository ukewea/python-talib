# Armhf remote Docker contract

Abstract roles only. No hostnames, usernames, IPs, or live endpoints in git.

## What agents need

- armv7 jobs run on a **self-hosted Linux orchestrator** labeled **`armhf-delegate`** (JS actions / checkout + Docker **client** only; no local arm/v7 Docker required).
- **Host CPU arch of the orchestrator does not matter** (amd64 or arm64 both fine). The build runs on the remote armhf daemon.
- arm64 native builds run on a **different** runner labeled **`arm64-native`** (that role *does* need aarch64 + local Docker).
- Image build / smoke / push for armv7 use a **remote native armhf Docker daemon** via `DOCKER_HOST`.
- Value comes from GitHub Actions repository variable **`ARMHF_DOCKER_HOST`** → workflow input `docker_host` → job env `DOCKER_HOST`.
- Wiring: `build-python-line.yaml` passes `docker_host: ${{ vars.ARMHF_DOCKER_HOST }}` on the armv7 job only.

## Runner labels (exclusive roles)

`runs-on` is AND of all labels. Use **disjoint** custom labels so jobs never land on the wrong machine:

| Role | Labels (exact set used in YAML) | What runs there |
|------|----------------------------------|-----------------|
| arm64 native build | `self-hosted`, `Linux`, `ARM64`, **`arm64-native`** | Local Docker `linux/arm64` (host must be aarch64) |
| armhf orchestration | `self-hosted`, `Linux`, **`armhf-delegate`** | Checkout + client Docker over SSH to armhf (any Linux arch) |

Do **not** put both `arm64-native` and `armhf-delegate` on the same runner if the goal is parallel CI.

Do **not** require `ARM64` on armhf-delegate jobs: that would force the orchestrator onto aarch64 hosts only, with no benefit for delegated builds.

If both runners only shared broad labels (e.g. `self-hosted` + `Linux` alone), GitHub would load-balance both job types onto either host.

## Variable format (placeholders only)

GitHub → **Settings → Secrets and variables → Actions → Variables** → `ARMHF_DOCKER_HOST`.

| Form | Pattern | Notes |
|------|---------|--------|
| Preferred | `ssh://<user>@<host>` | `<host>` = SSH config Host alias or name resolvable **from the armhf-delegate runner** |
| With port | `ssh://<user>@<host>:<port>` | Non-default SSH port |

Docker’s `DOCKER_HOST` SSH scheme is documented by Docker; keep the value **out of git**.

## Failure modes

| Condition | What happens |
|-----------|----------------|
| Variable empty / unset | `DOCKER_HOST` empty → Docker uses the **local** daemon on the orchestrator. That is **not** native armhf; arm/v7 builds are wrong or slow (emulation). Fix: set the variable. |
| Variable set, SSH/Docker broken | Preflight / build fails (SSH or daemon). Fix on the **armhf-delegate** runner and remote armhf host, not by committing endpoints. |
| No online runner with `armhf-delegate` | armv7 jobs sit queued (“Waiting for a runner…”). Register or start the orchestrator runner. |
| No online runner with `arm64-native` | arm64 jobs queue the same way. |
| Only one armhf Docker host | armv7 Python lines still serialize on the **remote daemon**; splitting runners only parallelizes arm64 vs armhf orchestration, not multiple armv7 builds against one daemon. |

## Operator setup (not in this repo)

### Existing arm64-native runner

1. Ensure labels include **`arm64-native`** (plus the usual `self-hosted` / `Linux` / `ARM64`).
2. Remove **`armhf-delegate`** if it was ever added.
3. Local Docker must be able to build/push `linux/arm64` (native).

How to add a label on an already-registered runner (GitHub UI or reconfigure):

- **UI:** Repo/org → **Settings → Actions → Runners** → select runner → edit labels → add `arm64-native`.
- **Config:** stop the runner service, re-run `./config.sh` with `--labels`, or edit `.runner` / reconfigure per GitHub’s self-hosted runner docs.

### New armhf-delegate runner (any Linux host)

Hardware/role: a Linux machine with a Node-capable GHA runner (x64 or arm64 package — **not** armhf). It only needs:

- GitHub Actions runner binary matching the host arch
- Docker **client** (CLI) that can use `DOCKER_HOST=ssh://…`
- Non-interactive SSH to the armhf Docker host
- Network path to GitHub + the armhf host

It does **not** need a local arm/v7 daemon or a local Docker daemon used for the build (client-only is enough if `DOCKER_HOST` points remote).

#### 1) Prerequisites on the orchestrator host

```bash
uname -m   # x86_64 or aarch64 both OK

# Docker CLI present
docker version

# SSH key auth, no password prompts
ssh -o BatchMode=yes -o ConnectTimeout=10 <user>@<armhf-host> 'docker info >/dev/null && uname -m'
# expect armv7l (or equivalent) on the remote
```

Optional `~/.ssh/config` (on the **orchestrator**, not in git):

```sshconfig
Host <armhf-alias>
  HostName <resolvable-name-or-ip>
  User <user>
  IdentityFile ~/.ssh/<key>
  IdentitiesOnly yes
```

Then `ARMHF_DOCKER_HOST` can be `ssh://<user>@<armhf-alias>` (or omit user if it matches).

#### 2) Register the runner

Create a registration token: GitHub → repo (or org) → **Settings → Actions → Runners → New self-hosted runner** → Linux / (x64 or ARM64 matching the host).

On the host (paths/names are local; do not commit them):

```bash
mkdir -p ~/actions-runner-armhf-delegate && cd ~/actions-runner-armhf-delegate
# Download the matching Linux runner package from the GitHub “New runner” page.

./config.sh --url https://github.com/<owner>/<repo> \
  --token <registration-token> \
  --name <runner-name> \
  --labels self-hosted,Linux,armhf-delegate \
  --work _work

# Install + start as a service (recommended)
sudo ./svc.sh install
sudo ./svc.sh start
```

Labels **required by YAML:** `self-hosted`, `Linux`, **`armhf-delegate`**.  
Do **not** add **`arm64-native`**. Extra labels (e.g. `ARM64` if the host happens to be aarch64) are optional and not required by the job.

#### 3) Repo variable

Confirm `ARMHF_DOCKER_HOST` is set and reachable **from this runner** (SSH config / keys may differ from other runners).

#### 4) Smoke before full CI

On the orchestrator host as the runner user:

```bash
export DOCKER_HOST="$ARMHF_DOCKER_HOST"   # same value as the repo variable; do not commit
docker version
docker info --format '{{.Architecture}}'   # arm / armv7*
```

Then `workflow_dispatch` the multi-arch workflow and confirm:

- arm64 jobs → runner with `arm64-native`
- armv7 jobs → runner with `armhf-delegate`
- both can run **at the same time**

### Armhf Docker host (unchanged role)

- Native armhf / armv7l Docker daemon
- Runner user on the **orchestrator** can use the socket (e.g. remote user in `docker` group)
- No GHA runner required on the armhf host (and armhf Node 20 end-of-life makes that undesirable)

Agents must **not** invent or commit real values. Document format and contracts only.
