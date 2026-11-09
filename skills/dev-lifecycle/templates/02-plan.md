# 2.plan.md 模板 — TDD 计划索引（结构示例）

> **Phase 2** · [phase2.md](../phases/phase2.md)
> 权威在 `docs/superpowers/plans/*-tdd.md`；Wave 概览表为镜像，Phase 3 须同步。
>
> ⚠️ 下方 `<PREFIX>` 须按 [plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md) 计算，**禁止**照抄 `../../`。

```markdown
# 开发计划: <功能名称> — TDD 索引

> 关联方案：[1.proposal.md](1.proposal.md)
> 生成时间：YYYY-MM-DD HH:mm:ss
> 最后更新：YYYY-MM-DD HH:mm:ss

---

## 1. TDD 计划链接

| 产物 | 链接 |
|------|------|
| TDD 实施计划 | [YYYY-MM-DD-<feature>-tdd.md](<PREFIX>docs/superpowers/plans/YYYY-MM-DD-<feature>-tdd.md) |
| OpenSpec 任务 | [tasks.md](<PREFIX>openspec/changes/<change-name>/tasks.md) |

> `<PREFIX>` = 从 `2.plan.md` 所在目录到项目根的 N 个 `../`（默认四段 plan-dir → `../../../../`）

---

## 2. Wave 概览（镜像，与 TDD 计划同步）

> 完成 Wave 后须同步更新本表与 TDD 计划「Wave 汇总」。

| Wave | 基本信息 | 完成情况 |
|------|----------|----------|
| Wave 1 | <范围 + 对应 tasks 编号> | ⬜ 未开始 |
| Wave 2 | <...> | ⬜ 未开始 |

---

## 3. 任务映射（OpenSpec ↔ TDD）

| OpenSpec tasks | TDD Wave / Task | 说明 |
|----------------|-----------------|------|
| 1.1 | Wave 1 / Task 1 | xxx |
| 1.2 | Wave 1 / Task 2 | xxx |
```
