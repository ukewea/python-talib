# AGENTS.md

Agent map for **python-talib**: multi-arch Docker images (Python + TA-Lib + NumPy + Pandas).  
This file is a **table of contents**, not an encyclopedia ([harness engineering](https://openai.com/index/harness-engineering/): short map, progressive disclosure, repo as system of record).

**Out of scope:** this is an **image packaging** repo, not a Python library API product.

**Living doc:** change bases / platforms / pins / smoke / runner contracts → update this map and linked `docs/agent/*` in the **same PR** only if the *process* changed—not to restate version numbers that belong in YAML/Dockerfile.

## Source of truth

| Topic | Read first (do not invent from memory or this map) |
|-------|-----------------------------------------------------|
| Build recipe (`/venv`, TA-Lib install) | `Dockerfile` |
| **Which Ubuntu base, `expected_python`, platform, runner** each job uses | **`.github/workflows/make-multi-arch-image.yml`** |
| Build / smoke / push steps | `.github/workflows/build-image.yaml` |
| Multi-arch manifests + tags | `.github/workflows/create-manifest.yaml` |
| Deeper agent docs | `docs/agent/` (index below) |

**Version policy for markdown:** do **not** hardcode Ubuntu tags (e.g. `ubuntu:YY.MM`) or Python major.minor (e.g. `3.xx`) in `AGENTS.md` / `docs/agent/*`. Open `make-multi-arch-image.yml` for each Python line’s `base_image` and `expected_python`, and keep those fields consistent across the three arch jobs + matching manifest job. Dockerfile `ARG BASE_IMAGE` default is only the local-default; CI overrides it per job.

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
| armv7 remote Docker contract, variable format, failure modes | [`docs/agent/armhf-remote-docker.md`](docs/agent/armhf-remote-docker.md) |
| What to verify before finishing | [`docs/agent/definition-of-done.md`](docs/agent/definition-of-done.md) |
| Human pull/run/compose | `README.md` |

## Repository snapshot (stable facts only)

- **Image contents:** Python runtime, TA-Lib, NumPy, Pandas under `/venv` (PEP 668).
- **Architectures:** `linux/amd64`, `linux/arm64`, `linux/arm/v7` (see workflow `platforms`).
- **Orchestration:** explicit jobs per Python × arch (not `strategy.matrix`).
- **Triggers:** schedule every 2 months on the 15th; `workflow_dispatch`; push disabled (commented).
- **Runners (abstract):** amd64 = GitHub-hosted `ubuntu-latest`; arm64/armv7 jobs use `['self-hosted', 'Linux', 'ARM64']`; armv7 Docker via `vars.ARMHF_DOCKER_HOST` (see armhf doc).
- **Python lines:** multiple product lines (e.g. py312 / py313 job prefixes)—each has its own `base_image` + `expected_python` in the YAML. Discover current values there.

## Commands (patterns — fill values from YAML)

```bash
# 1) Read make-multi-arch-image.yml for the line you care about:
#    base_image: "ubuntu:…"
#    expected_python: "…"
#
# 2) Local build
docker build --build-arg BASE_IMAGE=<base_image from YAML> -t python-talib:<line> .

# 3) Smoke (match CI contract in build-image.yaml)
docker run --rm -e EXPECTED_PYTHON=<expected_python from YAML> python-talib:<line> /venv/bin/python -c "
import os, sys
majmin = f'{sys.version_info.major}.{sys.version_info.minor}'
assert majmin == os.environ['EXPECTED_PYTHON'], (majmin, os.environ['EXPECTED_PYTHON'])
import pandas as pd, talib, numpy as np
assert talib.SMA(np.array([1.,2.,3.]), timeperiod=2) is not None
print('All good!', sys.version.split()[0])
"

docker run --rm -it python-talib:<line> /venv/bin/python
```

CI: every `build-image.yaml` call must pass `expected_python` consistent with that job’s base image (asserted in smoke).

## Workflow graph

```
make-multi-arch-image.yml
  ├── build-image.yaml   (per arch × Python line; smoke; push single-arch)
  └── create-manifest.yaml  (multi-arch tags after digests exist)
```

## Common tasks (short)

**Add a Python line:** three arch jobs (identical `base_image` + `expected_python`) + matching manifest `base_image` + update this map only if process changed. Values live in YAML. See definition-of-done.

**Bump TA-Lib:** follow [`docs/agent/talib-pins.md`](docs/agent/talib-pins.md) (C ARG **and** both pip pins in `Dockerfile`).

**Change platforms/runners:** edit explicit jobs in `make-multi-arch-image.yml`; keep armv7 on ARM64 labels + `docker_host` var; update docs only for process/contract changes.

## PR / commit rules

- Never commit real `ssh://…` values, hosts, or usernames.
- Constitution applies to commit messages and PR bodies.
- Prefer: local `docker build` + smoke using **YAML-sourced** `BASE_IMAGE` / `EXPECTED_PYTHON`; multi-arch needs CI/self-hosted.
- Do not reintroduce Ubuntu/Python version tables into markdown “for convenience.”
- Do not claim multi-arch green without CI (or explicit human acknowledgment).

## Security (image contents)

- Official Ubuntu bases; TA-Lib from upstream GitHub releases; `/venv` isolation.
- Infra/agent safety: **Constitution** above.
