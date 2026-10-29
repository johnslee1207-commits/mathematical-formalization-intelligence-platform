# Mathematical Formalization Intelligence Platform — 开发汇总

## 总体状态

截至 M6 评审交接包完成，M0–M6 的契约、验证器、负例和回放证据均已落盘。当前 Lean 工具链为 `leanprover/lean4:v4.35.0`，M6 readiness 为 `ready`。

## 阶段结果

| 阶段 | 主要内容 | 结果 |
| --- | --- | --- |
| M0 | 10 题 Lean/Mathlib 基准、负例、数据层注册和独立契约检查 | PASS |
| M1 | 扩展至 10 题、负例回放、CI profile、哈希证据 | PASS |
| M2 | M0/M1 跨阶段证据索引、元数据规范化、损坏门禁、CI 绑定、readiness | PASS |
| M3 | 5 题新增 Lean 基准、独立 lineage、源码/负例损坏测试、跨阶段绑定 | PASS |
| M4 | M0–M3 suite manifest、独立选择器、suite 负例、确定性 suite 回放 | PASS |
| M5 | M0–M4 provenance manifest、可复现 handoff、工具链和报告哈希验证 | PASS |
| M6 | M0–M5 外部评审包、评审清单、独立校验、临时变更负例、readiness | PASS |

## 核心工程能力

- Lean/Mathlib 证明与负例分离，证明源不承担验收策略。
- 基准清单、阶段契约、数据层注册表和本机 profile 分离。
- 所有阶段报告绑定 manifest、证明源、负例源、注册表和工具链哈希。
- 通过临时 fixture 验证错误 benchmark ID、错误哈希、错误 schema、源码变更、负例变更、缺失路径和 suite 变更会被拒绝。
- 回放入口按阶段提供：`scripts/replay_m0.ps1` 至 `scripts/replay_m6.ps1`。
- M0–M6 的 readiness、provenance、suite 和 review 报告位于 `reports/`。

## 关键交付物

- 数据层注册：`manifests/data_layers/registry.json`
- M2 跨阶段索引：`reports/m2_evidence_index.json`
- M3 基准：`benchmarks/m3_benchmark_05.json`
- M4 suite：`benchmarks/m4_suite_manifest.json`
- M5 provenance：`benchmarks/m5_provenance_manifest.json`
- M6 review manifest：`benchmarks/m6_review_manifest.json`
- M6 review evidence：`reports/m6_review_report.json`
- M6 readiness：`reports/m6_readiness_report.json`

## 主要提交链

`a2d6beb` M0 基准建立 → `55102d6` M1 完成 → `6cb54aa` M2 readiness → `782d50e` M3 验证门禁完成 → `1304cc3` M4 证据绑定 → `65f956e` M5 provenance handoff → `3691fef` M6 契约启动。

## 当前限制

- 本机与 CI profile 的实际工具路径不同，报告明确记录 profile scope；不可将本机报告误当作跨机器复现证明。
- GitHub 远端提交需要单独授权；本次阶段完成仅形成并验证本地提交，不自动 push。
