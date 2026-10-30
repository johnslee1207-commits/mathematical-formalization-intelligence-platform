# M7 — Number theory benchmark expansion

M7 adds a real-domain number theory slice after the M6 review handoff, with separate theorem data, proof source, negative corpus and evidence gates.

The deterministic replay binds the M7 acceptance evidence to the M6 readiness hash, the locked Lean toolchain, the local environment profile, the CI workflow entry point, and `scripts/replay_m7.ps1`. The independent binding report is `reports/m7_evidence_binding_report.json`; readiness is recorded in `reports/m7_readiness_report.json`.
