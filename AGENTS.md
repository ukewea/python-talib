# AGENTS.md

Agent map for **python-talib**: multi-arch Docker images (Python + TA-Lib + NumPy + Pandas).  
This file is a **table of contents**, not an encyclopedia ([harness engineering](https://openai.com/index/harness-engineering/): short map, progressive disclosure, repo as system of record).

**Out of scope:** this is an **image packaging** repo, not a Python library API product.

**Living doc:** change bases / platforms / pins / smoke / runner contracts → update this map and linked `docs/agent/*` in the **same PR** only if the *process* changed—not to restate version numbers that belong in YAML/Dockerfile.

## Source of truth

| Topic | Read first (do not invent from memory or this map) |
|-------|-----------------------------------------------------|
| Build recipe (`/venv`, TA-Lib install) | `Dockerfile` |
| **Which Ubuntu base / `expected_python` each Python line uses** | **`.github/workflows/make-multi-arch-image.yml`** (`matrix.include`) |
| **Arch platforms, runner labels, armhf `docker_host`** | **`.github/workflows/build-python-line.yaml`** |
| Build / smoke / push steps | `.github/workflows/build-image.yaml` |
| Multi-arch manifests + tags | `.github/workflows/create-manifest.yaml` |
| Deeper agent docs | `docs/agent/` (index below) |

**Version policy for markdown:** do **not** hardcode Ubuntu tags (e.g. `ubuntu:YY.MM`) or Python major.minor (e.g. `3.xx`) in `AGENTS.md` / `docs/agent/*`. Open `make-multi-arch-image.yml` `matrix.include` for each Python line’s `base_image` / `expected_python` / `python_version`. Arch runners live in `build-python-line.yaml`. Dockerfile `ARG BASE_IMAGE` default is only the local-default; CI overrides it per line.

If narrative and YAML disagree, **YAML/Dockerfile win** — then fix the docs (without reintroducing version tables here).

## Constitution (mandatory)

Overrides convenience. Applies to edits, commits, PRs, issues, comments, and log helpers.

1. **No concrete infrastructure identifiers** in git or public text: hostnames, FQDNs, SSH aliases, IPs, VPN endpoints, lab usernames/paths, inventory names that map 1:1 to machines.
2. **Abstract roles OK:** e.g. “ARM64 self-hosted runner”, “armhf Docker host”, “orchestration → remote Docker”.
3. **Ask the human** before writing anything that might include (1).
4. **Config out of git:** machine endpoints live in Actions variables/secrets or runner `~/.ssh/config`. Document **formats**, never live values (e.g. `ARMHF_DOCKER_HOST`).
5. **Redact logs:** do not echo host URLs; “is set” is enough.
6. **History:** leaked secrets/hosts → fix tree **and** plan history rewrite with human approval.

## Map → deeper docs

| Need | Go to |
|------|--------|
| TA-Lib C vs pip pins; how to bump | [`docs/agent/talib-pins.md`](docs/agent/talib-pins.md) |
| armv7 remote Docker + dual ARM runner labels (`arm64-native` / `armhf-delegate`) | [`docs/agent/armhf-remote-docker.md`](docs/agent/armhf-remote-docker.md) |
| What to verify before finishing | [`docs/agent/definition-of-done.md`](docs/agent/definition-of-done.md) |
| Human pull/run/compose | `README.md` |

## Repository snapshot (stable facts only)

- **Image contents:** Python runtime, TA-Lib, NumPy, Pandas under `/venv` (PEP 668).
- **Architectures:** `linux/amd64`, `linux/arm64`, `linux/arm/v7` (see workflow `platforms`).
- **Orchestration:** explicit jobs per Python × arch (not `strategy.matrix`).
- **Triggers:** schedule every 2 months on the 15th; `workflow_dispatch`; push disabled (commented).
- **Runners (abstract):** amd64 = GitHub-hosted `ubuntu-latest`; arm64 native = `['self-hosted', 'Linux', 'ARM64', 'arm64-native']`; armv7 orchestration = `['self-hosted', 'Linux', 'armhf-delegate']` (host arch irrelevant — only checkout + Docker client) + remote Docker via `vars.ARMHF_DOCKER_HOST` (see armhf doc). Exclusive role labels so native arm64 and armhf orchestration do not share one queue.
- **Python lines:** multiple product lines (job prefixes like `py312` / `py313` / `py314`)—each has its own `base_image` + `expected_python` in the YAML. Discover current values there.

## Commands (patterns — fill values from YAML)

```bash
# 1) Read make-multi-arch-image.yml for the line you care about:
#    base_image: "ubuntu:…"
#    expected_python: "…"
#
# 2) Local build
docker build --build-arg BASE_IMAGE=<base_image from YAML> -t python-talib:<line> .

# 3) Smoke (match CI: scripts/smoke_test.py via stdin — works with remote DOCKER_HOST)
docker run --rm -i -e EXPECTED_PYTHON=<expected_python from YAML> python-talib:<line> \
  /venv/bin/python - < scripts/smoke_test.py

docker run --rm -it python-talib:<line> /venv/bin/python
```

CI: every `build-image.yaml` call must pass `expected_python` consistent with that job’s base image.
Smoke asserts Python major.minor, SMA, and ACCBANDS / AVGDEV / IMI usability.

## Workflow graph

```
make-multi-arch-image.yml   (matrix of Python lines only — pins live in that file)
verify-py314.yml            (manual: same line workflow, py314 pins + arch/manifest toggles)
  └── build-python-line.yaml  (amd64 + arm64 + armv7 + optional manifest once)
        ├── build-image.yaml      (per arch; smoke via scripts/smoke_test.py; push)
        └── create-manifest.yaml  (multi-arch tags after digests exist)
```

**Add a Python line:** one `matrix.include` row in `make-multi-arch-image.yml` (and Dockerfile support).  
**Change runner/arch wiring:** edit `build-python-line.yaml` only.

## Common tasks (short)

**Add a Python line:** three arch jobs (identical `base_image` + `expected_python`) + matching manifest `base_image` + update this map only if process changed. Values live in YAML. See definition-of-done.

**Bump TA-Lib:** follow [`docs/agent/talib-pins.md`](docs/agent/talib-pins.md) (C ARG **and** both pip pins in `Dockerfile`).

**Change platforms/runners:** edit `build-python-line.yaml`; keep arm64 on `arm64-native`, armv7 on `armhf-delegate` + `docker_host` var; update docs only for process/contract changes.

## PR / commit rules

- Never commit real `ssh://…` values, hosts, or usernames.
- Constitution applies to commit messages and PR bodies.
- Prefer: local `docker build` + smoke using **YAML-sourced** `BASE_IMAGE` / `EXPECTED_PYTHON`; multi-arch needs CI/self-hosted.
- Do not reintroduce Ubuntu/Python version tables into markdown “for convenience.”
- Do not claim multi-arch green without CI (or explicit human acknowledgment).

## Security (image contents)

- Official Ubuntu bases; TA-Lib from upstream GitHub releases; `/venv` isolation.
- Infra/agent safety: **Constitution** above.
