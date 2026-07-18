# Definition of done (agent checks)

After changing code in this repository, validate as much as the change type allows.

## Always

1. Prefer reading `Dockerfile` and `.github/workflows/*.yml` over memory or markdown.
2. **Do not hardcode Ubuntu tags or Python major.minor in `AGENTS.md` / `docs/agent/*`.** Discover `base_image` and `expected_python` from `make-multi-arch-image.yml`.
3. If **process** changes (how jobs are structured, smoke contract shape, armhf variable name, constitution): update root `AGENTS.md` and `docs/agent/*` in the same change. Version bumps that only change YAML values need **no** version re-listing in markdown.
4. No concrete infrastructure identifiers in commits, PRs, logs helpers, or docs (see Constitution in `AGENTS.md`).

## Dockerfile or package pins changed

1. Diff `TALIB_C_VERSION` and both `pip install TA-Lib==…` lines deliberately.
2. Update `docs/agent/talib-pins.md` if the table would be wrong.
3. Local build + smoke when Docker is available (see `AGENTS.md` commands). Multi-arch still needs CI.

## Workflow / base image / `expected_python` changed

1. For each Python line: all three arch jobs share the same `base_image` and `expected_python` (values only in YAML).
2. Matching manifest job uses the **same** `base_image` (tag naming + build must not drift).
3. Smoke still asserts Python major.minor (from `expected_python` input) then TA-Lib/numpy/pandas.
4. Do not paste the new Ubuntu/Python numbers into markdown tables “for convenience.”

## Docs-only change

1. Still re-read workflows if claiming versions or bases.
2. Keep `AGENTS.md` short (map); put long operator detail under `docs/agent/`.
