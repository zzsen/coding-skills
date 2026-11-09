# 1.proposal.md 模板 — OpenSpec 索引（结构示例）

> **Phase 1** · [phase1.md](../phases/phase1.md) §四 · 超链接规则 [plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md)
> 权威在 `openspec/changes/<change-name>/`；本文件仅索引 + 超链接。归档后链接改 `openspec/archive/<date>-<name>/`。
>
> ⚠️ 下方 `<PREFIX>` 须按 [plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md) 计算，**禁止**照抄 `../../`。

```markdown
# <功能名称> — OpenSpec 方案索引

> 一句话描述该功能
> 生成时间：YYYY-MM-DD HH:mm:ss
> 最后更新：YYYY-MM-DD HH:mm:ss
> OpenSpec 变更：[openspec/changes/<change-name>/](<PREFIX>openspec/changes/<change-name>/)
> OpenSpec 状态：进行中 / 已归档 → openspec/archive/<date>-<change-name>/

---

## 1. 方案摘要

（2–5 句话，摘自 OpenSpec proposal.md，不复制全文）

---

## 2. OpenSpec 产物索引

| 产物 | 说明 | 链接 |
|------|------|------|
| proposal.md | 背景、目标、范围 | [proposal.md](<PREFIX>openspec/changes/<change-name>/proposal.md) |
| design.md | 架构、接口、数据流 | [design.md](<PREFIX>openspec/changes/<change-name>/design.md) |
| tasks.md | 原子任务清单 | [tasks.md](<PREFIX>openspec/changes/<change-name>/tasks.md) |
| specs/ | 能力/接口规格 | [specs/…](<PREFIX>openspec/changes/<change-name>/specs/<capability>/spec.md) |

> `<PREFIX>` = 从 `1.proposal.md` 所在目录到项目根的 N 个 `../`（默认 `init-plan-dir` 四段目录 → `../../../../`）

---

## 3. 关键决策

| 决策 | 说明 |
|------|------|
| xxx | yyy |

---

## 4. 任务概览

- OpenSpec 任务总数：N（P0: X / P1: Y）
- 详见 [tasks.md](<PREFIX>openspec/changes/<change-name>/tasks.md)
```

> 多子系统场景由 OpenSpec `specs/` 目录拆分，**不再**使用 `1.N.proposal.md` 子方案文件。
