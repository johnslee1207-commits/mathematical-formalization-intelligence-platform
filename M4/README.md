# M4 — Benchmark suite selection and phase orchestration

M4 使用数据化 suite manifest 选择已经通过 readiness 的 M0–M3 阶段，并验证跨阶段证据哈希与回放状态。

- 契约：`M4/phase_contract.json`
- 独立检查：`scripts/check_m4_contract.ps1`
- 后续回放：`scripts/replay_m4.ps1`
- suite manifest：`benchmarks/m4_suite_manifest.json`
- 证据绑定：`scripts/check_m4_evidence.ps1`
