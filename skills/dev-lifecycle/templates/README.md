# 产物模板索引

Agent 生成产物时**参考**对应模板的章节结构，勿从记忆编造。路径：`dev-plan/<YYYYMM>/<YYYYMMDD>/<YYYYMMDDHHmmss>_<type>_<detail>/`

> **模板 ≠ 路径真理**：模板内 `<PREFIX>` 须按 [plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md) 结合实际 `<plan-dir>` 深度计算，**禁止**照抄 `../../`。

---

## 模板清单

| 文件 | 产物 | Phase | 须 PREFIX 的外链 |
|------|------|-------|-----------------|
| [00-pre-flight-check-report.md](00-pre-flight-check-report.md) | 门禁报告（首个回复） | 前置 | — |
| [project-config.md](project-config.md) | `project-config.md` | Phase 1 前 | — |
| [01-proposal.md](01-proposal.md) | `1.proposal.md` | Phase 1 | openspec/changes/* |
| [02-plan.md](02-plan.md) | `2.plan.md` | Phase 2 | TDD 计划、tasks.md |
| [03-dev.md](03-dev.md) | `3.dev.md` | Phase 3 | TDD 计划（头部） |
| [03-1-backend-test-remarks.md](03-1-backend-test-remarks.md) | 测试备注规范 | Phase 4 | — |
| [04-test-case.md](04-test-case.md) | `4.test-case.md` | Phase 4 | TDD 计划（头部） |
| [05-lint-report.md](05-lint-report.md) | `5.lint-report.md` | Phase 5 | — |
| [06-docs-update.md](06-docs-update.md) | `6.docs-update.md` | Phase 6 | — |
| [07-acceptance.md](07-acceptance.md) | `7.acceptance.md`（14 章硬性） | Phase 7 | openspec/*、TDD 计划 |

---

## 通用规则

1. **时间戳**：`YYYY-MM-DD HH:mm:ss` 须 Shell 获取
2. **超链接**：相对**当前 Markdown 文件**；跨根目录链接见 [plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md)；写入前 `Test-Path` 校验
3. **project-config**：复制模板 → 按 [exploration.md](../phases/exploration.md) 探索填写 → 有效性校验

> 旧版单文件索引见 [templates.md](../templates.md)（已迁移）
