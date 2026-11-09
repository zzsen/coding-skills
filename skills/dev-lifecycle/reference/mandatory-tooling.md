# 强制工具与 Skill 规范（禁止手写替代）

> **硬性**：下列阶段 **必须** 通过官方 **OpenSpec 命令** 或 **OpenSpec Skill** / **Superpowers Skill** 执行；**禁止** Agent 手写等价产物、跳过工具直接写文件、或用其他 Skill 替代。

---

## 一、OpenSpec 四阶段（explore → propose → apply → archive）

| 阶段 | dev-lifecycle 对应 | **必须**使用（二选一） | **禁止** |
|------|-------------------|------------------------|----------|
| **Explore** | Phase 1 新功能（AskUserQuestion 前） | 聊天 **`/opsx:explore`** 或 Read/调用 **`openspec-explore`** Skill | 纯会话 Explore 不调用 OpenSpec；`brainstorming`；手写 `openspec/explore/` 替代工具；**调研结束未在对话正文输出 §2.1 即 AskUserQuestion/Propose** |
| **Propose** | Phase 1 `/opsx:propose` | **`/opsx:propose`** 或 **`openspec-propose`** Skill | 手写 `openspec/changes/` 下 proposal/design/tasks/specs；自编 `opsx-*.md` |
| **Apply** | Phase 3 **阶段 B**（全部 Wave ✅ 后，`tasks.md` 剩余项） | **`/opsx:apply`** 或 **`openspec-apply-change`** Skill | Phase 3 **入口**直接 apply 代替 TDD；不跑 apply 却手动勾 tasks |
| **Archive** | Phase 7 验收通过后 | **`/opsx:archive`** 或 **`openspec-archive-change`** Skill | 仅 Shell `mv` 归档、不跑 archive 命令/Skill |

**OpenSpec Skill 路径**（`openspec init --tools <agent-slug>` 后）：

- `<agent-skills-dir>/openspec-explore/SKILL.md`
- `<agent-skills-dir>/openspec-propose/SKILL.md`
- `<agent-skills-dir>/openspec-apply-change/SKILL.md`
- `<agent-skills-dir>/openspec-archive-change/SKILL.md`

**命令别名**：`/opsx-propose`、`/opsx-apply`、`/opsx-archive` 等与 `/opsx:*` 等价。

---

## 二、Superpowers 两阶段（writing-plans → executing-plans）

| 阶段 | dev-lifecycle 对应 | **必须**使用 | **禁止** |
|------|-------------------|-------------|----------|
| **writing-plans** | Phase 2 | Read/调用 Superpowers **`writing-plans`** Skill | 手写 `docs/superpowers/plans/*-tdd.md` 替代；未过 Phase 1 即调用 |
| **executing-plans** | Phase 3 **阶段 A**（Wave TDD 主开发） | Read/调用 Superpowers **`executing-plans`** Skill | Phase 3 入口直接 `apply`；不读 Skill 自由编码；跳过 Wave 纪律 |

**前置**：`superpowers_ready: True`；Reload 后 Agent 可用 Skill 列表含 `writing-plans`、`executing-plans`。

---

## 三、与 dev-lifecycle 流程的结合

```
Phase 1 新功能：
  /opsx:explore 或 openspec-explore
    → 回复中输出方案详情 + 对比 + 推荐（基于 explore 产出整理）
    → AskUserQuestion 选定
  /opsx:propose 或 openspec-propose
    → 1.proposal.md 索引

Phase 2：
  writing-plans Skill → docs/superpowers/plans/*-tdd.md + 2.plan.md

Phase 3（顺序固定，不可对调）：
  阶段 A：executing-plans Skill → Wave 1…N（TDD 主开发）→ 全部 Wave ✅
  阶段 B：/opsx:apply 或 openspec-apply-change（仅 tasks.md 剩余项；无剩余可跳过）

Phase 7 验收通过：
  /opsx:archive 或 openspec-archive-change
    → update-proposal-links
```

---

## 四、仍允许的手写/脚本（非替代）

| 允许 | 说明 |
|------|------|
| `dev-plan/**` 索引产物 | `1.proposal.md` ~ `7.acceptance.md` 由 dev-lifecycle 模板生成，**不**替代 OpenSpec/Superpowers 权威产物 |
| `init-plan-dir`、`gate-phase*` 等 | dev-lifecycle 编排脚本 |
| 同 plan-dir 互链、`project-config.md` | 非 OpenSpec/Superpowers 核心流程 |

---

## 五、违规判定

| 违规 | 处理 |
|------|------|
| 未调用 OpenSpec 工具即写入 `openspec/changes/` | **停止**，补跑对应 command/Skill |
| 未调用 writing-plans 即写 TDD 计划 | **停止**，回 Phase 2 |
| Wave 实施未读 executing-plans | **停止**，补读 Skill 后按 Wave 继续 |
| Phase 3 入口直接 apply 代替 TDD | **停止**，改走 executing-plans 阶段 A |
| 验收通过未 `/opsx:archive` | **禁止**宣称交付完成 |

---

## 六、环境未就绪

| 缺失 | 行为 |
|------|------|
| OpenSpec CLI / list 失败 | 环境 AskUserQuestion #1a/#1b；**禁止**手写 openspec 凑合 |
| Superpowers 未就绪 | 环境 AskUserQuestion #2；**禁止**手写 TDD 凑合 |

详见 [preparation.md](../phases/preparation.md)。
