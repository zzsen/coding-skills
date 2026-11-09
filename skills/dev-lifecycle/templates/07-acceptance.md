# 7.acceptance.md 模板 — 验收报告（结构示例）

> **Phase 7** · [phase7.md](../phases/phase7.md)
> **硬性**：以下 14 个章节，编号与标题不可更改、合并或省略。
>
> ⚠️ OpenSpec / TDD 外链须用 `<PREFIX>`，见 [plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md)。

```markdown
# 验收报告: <功能名称>

> 生成时间：YYYY-MM-DD HH:mm:ss
> 最后更新：YYYY-MM-DD HH:mm:ss

---

## 1. 基本信息

| 项目 | 内容 |
|------|------|
| 计划目录 | dev-plan/... |
| OpenSpec 变更 | [openspec/changes/<change-name>/](<PREFIX>openspec/changes/<change-name>/) |
| TDD 计划 | [docs/superpowers/plans/YYYY-MM-DD-<feature>-tdd.md](<PREFIX>docs/superpowers/plans/YYYY-MM-DD-<feature>-tdd.md) |
| 变更类型 | feat / fix / refactor |
| 开发周期 | YYYY-MM-DD ~ YYYY-MM-DD |
| 涉及模块 | xxx |

---

## 2. 方案摘要

（来自 OpenSpec [proposal.md](<PREFIX>openspec/changes/<change-name>/proposal.md)，附链接）

---

## 3. 开发耗时统计

### 各阶段耗时

| 阶段 | 开始时间 | 结束时间 | 耗时 |
|------|---------|---------|------|
| Phase 1 | | | |
| **总计** | | | |

### 各 Wave 耗时

| Wave | 开始时间 | 结束时间 | 耗时 |
|------|---------|---------|------|
| Wave 1 | | | |
| **总计** | | | |

---

## 4. 开发计划执行情况

（来自 TDD 计划 Wave 汇总 + OpenSpec [tasks.md](<PREFIX>openspec/changes/<change-name>/tasks.md) 勾选状态）

| Wave | 状态 | 对应 OpenSpec tasks |
|------|------|---------------------|
| Wave 1 | ✅ 已完成 | 1.1–1.3 |
| Wave 2 | ✅ 已完成 | 2.1–2.4 |
| **tasks.md 剩余** | ✅ 已由 /opsx:apply 完成 | — |

---

## 5. 质量过程统计

| 阶段 | 失败次数 | 说明 |
|------|---------|------|
| Phase 3: 构建失败 | 0 | |
| Phase 4: 测试失败 | 0 | |
| Phase 5: Lint 失败 | 0 | |

---

## 6. Lint 检测结果

| 检测项 | 状态 | 错误数 |
|--------|------|--------|
| xxx | ✅ | 0 |

---

## 7. 测试用例与覆盖率

| 类型 | 总数 | 通过 | 通过率 |
|------|------|------|--------|
| 后端 | x | x | 100% |

---

## 8. 文档更新统计

| 指标 | 数量 |
|------|------|
| 新增 | 0 |
| 更新 | 0 |
| 跳过 | 0 |

---

## 9. 需要重启的服务

（根据 project-config.md 服务映射表生成，或标注"不适用"/"无需重启"）

---

## 10. 需要执行的 SQL

（来自 OpenSpec design.md / specs/，或标注"无数据库变更"）

---

## 11. API 变更清单

| 方法 | 路径 | 说明 | 状态 |
|------|------|------|------|
| POST | /api/v1/xxx | xxx | 新增 |

---

## 12. 前端页面清单

| 页面 | 路由 | 状态 |
|------|------|------|
| xxx | /xxx | ✅ |

---

## 13. 遗留问题

| # | 问题 | 优先级 | 计划 |
|---|------|--------|------|
| 无 | - | - | - |

---

## 14. 产物清单

| 产物 | 文件 | 状态 |
|------|------|------|
| OpenSpec 索引 | [1.proposal.md](1.proposal.md) | ✅ |
| OpenSpec 变更 | [openspec/changes/<change-name>/](<PREFIX>openspec/changes/<change-name>/) | ✅ / 已归档 |
| TDD 计划索引 | [2.plan.md](2.plan.md) | ✅ |
| TDD 实施计划 | [docs/superpowers/plans/*-tdd.md](<PREFIX>docs/superpowers/plans/YYYY-MM-DD-<feature>-tdd.md) | ✅ |
| 开发记录 | [3.dev.md](3.dev.md) | ✅ |
| Lint 日志 | lint-results/*.log | ✅ |
| Lint 解析 | lint-results/lint-counts.json | ✅ |
| Lint 报告 | [5.lint-report.md](5.lint-report.md) | ✅ |
| 测试汇总 | [4.test-case.md](4.test-case.md) | ✅ |
| 文档更新 | [6.docs-update.md](6.docs-update.md) | ✅ |
| 验收报告 | [7.acceptance.md](7.acceptance.md) | ✅ |
```
