# M3 — Benchmark expansion and verifier isolation

M3 在 M2 readiness gate 通过后启动，目标是扩展 Lean/Mathlib 基准，同时保持题目元数据、证明源、负例和验收证据彼此独立可验证。

- 契约：`M3/phase_contract.json`
- 独立契约检查：`scripts/check_m3_contract.ps1`
- 后续回放入口：`scripts/replay_m3.ps1`
- 验收入口：`scripts/verify_m3.ps1`
- 确定性回放：`scripts/replay_m3.ps1`

M3 的证明代码、基准数据和报告必须遵守 `manifests/data_layers/registry.json` 的分类边界。
