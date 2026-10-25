# M0 Project Instructions

- `benchmarks/` contains benchmark contract data; do not duplicate its policy fields in scripts.
- `M0/` contains Lean executable proofs and negative checks.
- `reports/` is runtime-generated evidence and should not be treated as source truth.
- `manifests/data_layers/registry.json` classifies persistent project paths.
- `config/local/m0_environment.json` owns machine-specific Lean/Elan paths.
- Use `scripts/verify_m0.ps1` as the acceptance entry point.
- Use `scripts/replay_m0.ps1` to verify that the locked benchmark and data-layer registry replay successfully.
- Keep the Lean toolchain and Mathlib revisions locked by `lean-toolchain` and `lake-manifest.json`.
