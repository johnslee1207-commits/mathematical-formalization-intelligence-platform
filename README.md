# Mathematical Formalization Intelligence Platform — M0

本目录是 M0 的独立 Lean 4/Mathlib 验收工程，位于 E 盘，不修改 AetherOS、Cognisphere 或 cognisphere-db。

## 已锁定环境

- Lean：4.35.0
- Elan：4.2.4，工具链目录：`E:\\tools\\elan`
- Mathlib：`v4.35.0`，提交由 `lake-manifest.json` 锁定
- 基准入口：`M0/Benchmark.lean`

## 验证

在新 PowerShell 窗口中运行：

```powershell
Set-Location E:\\Projects\\mathematical-formalization-intelligence-platform
.\\scripts\\verify_m0.ps1
```

成功标准是 `lake build` 返回 0，并看到 `Build completed successfully`。首次运行可能需要从 Mathlib 官方缓存下载预编译文件。

重放验收：

```powershell
.\\scripts\\replay_m0.ps1
```

重放会校验基准数量、数据层登记、Lean 构建，以及基准、证明源文件和锁定工具链的输入哈希，并生成 `reports/m0_replay_report.json`。

## 后续阶段 M1

M1 已启动，目标是扩展基准集和负例覆盖，同时保持可重放证据。阶段契约位于 `M1/phase_contract.json`，可先运行 `scripts/check_m1_contract.ps1`。

官方安装参考：

- https://lean-lang.org/install/manual/
- https://leanprover-community.github.io/install/project
