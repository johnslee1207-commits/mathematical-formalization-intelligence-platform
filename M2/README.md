# M2 — Cross-phase evidence index and benchmark normalization

M2 在已完成的 M0/M1 基础上，建立跨阶段证据链和统一元数据门禁。

## 阶段目标

- 统一 M0/M1 的 benchmark、acceptance、replay 证据字段。
- 让报告中的 benchmark ID、源文件哈希、工具链和回放状态可机器追溯。
- 用临时损坏 fixture 验证门禁确实拒绝不一致证据。
- 为下一阶段扩展题库建立 readiness gate。

## 当前状态

- 状态：started
- 契约：M2/phase_contract.json
- 独立契约检查：scripts/check_m2_contract.ps1
- 基准元数据检查：scripts/check_m2_metadata.ps1
- 损坏证据负例：scripts/test_m2_corruption.ps1
- CI 证据绑定：scripts/check_m2_ci_binding.ps1
- readiness gate：scripts/check_m2_readiness.ps1
- 后续回放入口：scripts/replay_m2.ps1
- 证据索引：reports/m2_evidence_index.json
- 回放报告：reports/m2_replay_report.json

