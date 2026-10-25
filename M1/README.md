# M1 — Benchmark expansion and portable replay

M1 在 M0 的 Lean 4/Mathlib 验收基线之上，扩展形式化题目和负例覆盖，并保持数据、程序、环境和运行时证据的边界。

## 当前阶段

- 状态：in_progress
- 契约：`M1/phase_contract.json`
- 独立契约检查：`scripts/check_m1_contract.ps1`
- 后续验收入口：`scripts/replay_m1.ps1`
- 当前实现：5 个正例、2 个负例已进入首个 proof slice。
- M1 回放：`scripts/replay_m1.ps1`

## 阶段门

1. 先完成至少 5 个新增基准案例及至少 2 个独立负例。
2. 独立契约检查必须能在不执行 `lake build` 的情况下发现结构错误。
3. M1 专用回放必须固定工具链、输入哈希和数据层登记。
4. 所有 M1 变更只发生在本工程内；不修改 AetherOS、Cognisphere、cognisphere-db。

