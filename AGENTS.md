# M0 Project Instructions

- `benchmarks/` contains benchmark contract data; do not duplicate its policy fields in scripts.
- `M0/` contains Lean executable proofs and negative checks.
- `reports/` is runtime-generated evidence and should not be treated as source truth.
- `manifests/data_layers/registry.json` classifies persistent project paths.
- `config/local/m0_environment.json` owns machine-specific Lean/Elan paths.
- Use `scripts/verify_m0.ps1` as the acceptance entry point.
- Use `scripts/check_m0_contract.ps1` as the independent benchmark/data-layer contract verifier.
- Use `scripts/check_m1_contract.ps1` to validate the started M1 phase contract before adding M1 proof code.
- Use `scripts/check_m2_contract.ps1` to validate the M2 evidence-index phase contract before implementation.
- Use `scripts/check_m2_metadata.ps1` to validate the common M0/M1 benchmark metadata contract.
- Use `scripts/test_m2_corruption.ps1` to validate M2 corruption and unregistered-path rejection.
- Use `scripts/check_m2_ci_binding.ps1` to validate replay reports against the CI workflow and environment profiles.
- Use `scripts/check_m2_readiness.ps1` to produce the machine-checkable M2 readiness report.
- Use `scripts/check_m3_contract.ps1` to validate the M3 benchmark-expansion contract before adding M3 proof code.
- Use `scripts/check_m4_contract.ps1` to validate the M4 suite-selection contract before orchestration work.
- Use `scripts/replay_m4.ps1` to validate the selected phase suite and emit M4 readiness evidence.
- Use `scripts/replay_m0.ps1` to verify that the locked benchmark and data-layer registry replay successfully.
- Keep the Lean toolchain and Mathlib revisions locked by `lean-toolchain` and `lake-manifest.json`.
