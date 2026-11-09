# Phase 1: OpenSpec Propose

> **产物**：`<plan-dir>/1.proposal.md`（索引）+ `openspec/changes/<change-name>/`
> **权威**：`proposal.md`、`design.md`、`tasks.md`、`specs/`

## ⛔ Explore 铁律（新功能，优先于一切续航 AskUserQuestion）

命中 dev-lifecycle 且为**新功能**时，调研（Tool Call）结束后 **必须先** 在 **对话正文** 写全 **§2.1（1）–（6）**，**然后** 才可 `AskUserQuestion` 选定方案。

**一律禁止**（违规 = 流程失败）：

1. 正文只有「下面给出 §2.1 / Explore 结论」→ 直接 `AskUserQuestion`
2. 把方案详情写在 `AskUserQuestion` **选项**里代替正文
3. 调研轮结束后，下一轮 **无 §2.1 六节正文** 就 `AskUserQuestion` 或 Propose

`openspec-explore` 的「无固定步骤」**不适用**于本节交付要求。调用前自检见 **§2.2**；流程与结构见 **§2.0.5–§2.1**。

---

## 流程概览

```
§一 门禁检查
  ↓
§二 调研（/opsx:explore + 白名单 Read）→ **对话正文 §2.1（1）–（6）** → AskUserQuestion 选定方案
  ↓
§三 /opsx:propose（或 openspec-propose）→ 生成 OpenSpec 变更目录
  ↓
§四 生成 1.proposal.md（按实际 plan-dir 计算超链接）
  ↓
§五 AskUserQuestion 确认 Propose 产物
  ↓
§六 质量门禁 → Phase 2
```

| 阶段 | 章节 | 关键动作 |
|------|------|----------|
| 准入 | §一 | `environment-ready: True`、project-config 有效 |
| 方案探索 | §二 | **`/opsx:explore`** 或 **`openspec-explore`** → 调研 → **对话正文 §2.1** → AskUserQuestion（§2.0.5） |
| 方案落地 | §三 | **`/opsx:propose`** 或 **`openspec-propose`** |
| 索引编写 | §四 | `1.proposal.md` + [PREFIX 规则](../reference/plan-dir-link-prefix.md) |
| 用户确认 | §五 | Propose 后 AskUserQuestion（与 §2.2 **分开**） |
| 质量检查 | §六 | [checklist.md](../checklist.md) § Phase 1 |

---

## 一、门禁与禁止项

> **与 Superpowers 互斥**：本 Phase **禁止 Read / 调用 `brainstorming` Skill**。
> **强制工具**：[mandatory-tooling.md](../reference/mandatory-tooling.md) — Explore / Propose **必须** OpenSpec command 或 Skill，**禁止**纯会话 Explore 或手写 `openspec/changes/`。

### 1.1 禁止项

| 禁止 | 替代 |
|------|------|
| **Read / 调用 `brainstorming` Skill** | **`/opsx:explore`** 或 **`openspec-explore`** → **`/opsx:propose`** |
| 纯会话 Explore 不调用 OpenSpec 工具 | **`/opsx:explore`** 或 Read **`openspec-explore`** |
| OpenSpec 未就绪时手写 `openspec/changes/` | `openspec init` + **`/opsx:propose`** 或 **`openspec-propose`** |
| 新功能跳过 Explore 直接 Propose | 先 **`/opsx:explore`** + 用户确认 |
| 未确认方案进入 Phase 2 | Explore / Propose 后**分别** AskUserQuestion 确认 |
| Explore 仅列方案名、无对比与推荐即 AskUserQuestion | 须先完整输出 §2.1（1）–（6） |
| 调研轮次仅 Tool Call、无 §2.1 正文即 AskUserQuestion / Propose | 须先 **Explore 交付回复**（§2.0.5） |
| 口头「下面将输出方案」但未在同轮正文写出 §2.1 | 交付回复须含完整 §2.1，禁止空承诺 |
| AskUserQuestion 被跳过即视为用户确认推荐方案 | 跳过 ≠ 确认；须重发 §2.1 + 再次 AskUserQuestion |
| §2.1 交付回复同轮调用 init-plan-dir / Write openspec | 用户确认方案**后**方可写产物 |
| 照抄模板 `../../` 作为 OpenSpec 超链接 | 须按 [plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md) 计算 PREFIX |

### 1.2 执行前检查

| # | 条件 |
|---|------|
| 1 | 门禁报告结论「可以写文件」且 Shell **`environment-ready: True`** |
| 2 | [preparation.md](preparation.md) OpenSpec **与** Superpowers 环境均已就绪（**禁止**「OpenSpec 就绪即可进 Phase 1」） |
| 3 | `project-config.md` 有效 |
| 4 | **新功能**：已调用 **`/opsx:explore`**（或 **`openspec-explore`**）；**对话正文**已输出 §2.1（1）–（6）；Explore AskUserQuestion 已确认 |

---

## 二、Explore 分流（新功能）

| 需求类型 | 先 Explore | 说明 |
|----------|-----------|------|
| **新功能** | **是** | **`/opsx:explore`** 或 **`openspec-explore`** → 整理输出方案对比 → AskUserQuestion → Propose |
| **已有功能变更** | 否 | 可直接 **`/opsx:propose`**（跳过 §2.1–2.2，进入 §三） |

**Explore 必须调用 OpenSpec 工具**（见 [mandatory-tooling.md](../reference/mandatory-tooling.md)）。调研结束后，**下一则面向用户的回复**（或同一则回复的正文部分）**必须**完整写出 §2.1（1）–（6），**然后**才可 AskUserQuestion；**禁止**仅有 Tool Call 或口头承诺「下面输出方案」。

### 2.0 调用 OpenSpec Explore（新功能，硬性）

在 **Explore 调研阶段**，**必须**执行以下之一（可与白名单 `Read` / `Grep` 并行，但不可替代）：

| 方式 | 说明 |
|------|------|
| 聊天输入 **`/opsx:explore`** | OpenSpec 官方命令 |
| Read/调用 **`openspec-explore`** Skill | `<agent-skills-dir>/openspec-explore/SKILL.md` |

**禁止**：不调用上述工具，仅在会话中「口头 Explore」。

### 2.0.5 Explore 交付流程（硬性 STOP）

> 调研（Tool Call）完成 ≠ Explore 完成。完成标志：**对话正文写出 §2.1（1）–（6）** → AskUserQuestion **明确**选定 → 方可 Propose。

| 阶段 | 动作 | 允许 | 禁止 |
|:----:|------|------|------|
| **A** | 调研 | `/opsx:explore`、`openspec-explore`、白名单 `Read`/`Grep` | `init-plan-dir`；Write `dev-plan/**`、`openspec/**`；`/opsx:propose`；`writing-plans` |
| **B** | 交付 | 在 **对话正文**完整写出 §2.1（1）–（6）（用户不展开 Tool 可读全文） | 仅 Tool Call；「下面将输出…」；详情只放 AskUserQuestion 选项或 `openspec/explore/*.md` |
| **C** | 确认 | 阶段 B 完成后 **单独** §2.2 AskUserQuestion | 省略 B；与门禁/续航 AskUserQuestion 混搭 |
| **D** | Propose | 阶段 C 用户**明确**选定后 | 跳过 C；**AskUserQuestion 被跳过仍继续** |

**顺序**：A 可单独一轮；若上一轮仅 A，**下一轮必须 B**；B 与 C 可同条回复（**先完整 §2.1 正文，后 `AskUserQuestion`**）。**跳过 / 未选 ≠ 确认** → 重发 §2.1 正文 → 再次 AskUserQuestion。

> **与 `openspec-explore` 冲突时**：该 Skill 写「无固定步骤、无强制产出」——**dev-lifecycle Phase 1 新功能以本节为准**，Explore 交付 **必须** 输出 §2.1 六节正文，**不得**以其为由跳过。

#### 典型违规（截图级，一律禁止）

| 违规表现 | 正确做法 |
|----------|----------|
| 正文仅一句「下面给出 §2.1 / Explore 结论」即 `AskUserQuestion` | **同条回复**内先写全 §2.1（1）–（6），**末尾**再 `AskUserQuestion` |
| 方案详情只写在 `AskUserQuestion` 选项里（如「方案 B：扩展 GlobalSearch…」） | 详情在正文 §2.1（3）（4）；选项 **仅** 短标签（「采用推荐方案 A」） |
| 调研轮全是 Tool Call，下一轮直接 `AskUserQuestion` | 下一轮 **必须先** 输出 §2.1 正文，**禁止** 无正文 AskUserQuestion |

### 2.1 对话正文结构（阶段 B，AskUserQuestion 前）

须在对话正文中按序写出下列 **6 节**（`## （N）…` 标题）：

| 节 | 内容要求 |
|:--:|----------|
| **（1）问题陈述** | 解决什么问题、为谁、成功标准（2–4 句） |
| **（2）关键约束** | 性能 / 兼容 / 安全 / 工期 / 技术栈 / 架构约束（条目化） |
| **（3）备选方案详情** | **≥ 2** 个独立小节；每方案含：**名称**、**核心思路**（3–5 句）、**架构/模块**（可 Mermaid）、**关键接口/数据流**、**优点**（≥2）、**缺点**（≥2）、**实现成本**、**风险点** |
| **（4）方案对比表** | 横向对比全部方案：实现复杂度、与现有代码契合度、性能/扩展性、可维护性、交付风险、综合推荐度 |
| **（5）推荐方案** | 推荐项 + **≥3 条理由**（引用（2）（4））+ 每个非推荐方案至少 1 句为何不选 |
| **（6）风险与待确认项** | 仍不确定、需用户拍板的点（如有） |

> **禁止**：只写「方案 A/B」一行带过；禁止未写 §2.1 即 AskUserQuestion / Propose。

### 2.2 用户确认（AskUserQuestion）

#### 调用前自检（全部 ✅ 后才允许 `AskUserQuestion`）

| # | 检查项 |
|---|--------|
| 1 | 对话正文（非 Tool 结果）含标题 `## （1）` … `## （6）` **共 6 节** |
| 2 | `## （3）` 下 **≥2** 个方案小节（如 `### 方案 A`） |
| 3 | `## （4）` 含 **Markdown 对比表**（≥3 行数据） |
| 4 | `## （5）` 写明推荐方案 + ≥3 条理由 |
| 5 | **未**用「下面将输出 / 下面给出 §2.1」代替正文 |
| 6 | 方案详情 **不在** `AskUserQuestion` 选项正文中 |

任一项 ❌ → **禁止** `AskUserQuestion`；先补全 §2.1 正文。

**触发条件**（全部满足后调用 `AskUserQuestion`）：§2.1（1）–（6）已在对话正文输出（§2.0.5 阶段 B）；阶段 A 已结束；未与门禁 / 续航 AskUserQuestion 混搭。

**禁止**：§2.1 之前发起方案选定 `AskUserQuestion`；用「结束会话 / 下一步续航」替代本节；**禁止** Session Continuation 续航 AskUserQuestion 抢先于本节（Explore 未交付 §2.1 前不得发任何非环境 AskUserQuestion）。

**提问模板**：

```
问题："已输出 N 个备选方案及对比，推荐【方案 X】。请选择："
选项（仅短标签，不写方案详情）：
  - ✅ 采用推荐方案，继续 /opsx:propose
  - 🔀 选用方案 B（名称即可，详情见上文 §2.1）
  - 🔀 选用方案 C（名称即可，详情见上文 §2.1）
  - ✏️ 需要补充信息 / 合并方案后再定
  - ⏸️ 暂停 Explore，稍后继续
```

**分支处理**：

| 用户选择 | Agent 行为 |
|----------|-----------|
| ✅ 采用推荐 | 记录选定方案 → 执行 §三 Propose（design.md 须体现该方案） |
| 🔀 选用其他 | 记录用户选定方案 → Propose 时以该方案为准 |
| ✏️ 补充 / 合并 | 补充 Explore 输出 → 更新对比与推荐 → **再次** AskUserQuestion |
| ⏸️ 暂停 | 停止，不写 OpenSpec 产物 |

**可选持久化**：`openspec/explore/<topic>.md`（不可替代 §2.1 对话正文）。

---

## 三、执行 Propose（`/opsx:propose` 或 `openspec-propose`）

> **前置**：§2.0.5 阶段 C 用户已**明确选定**方案（非跳过、非未选）。**禁止**在输出 §2.1 对话正文之前创建 `dev-plan` 目录或写入 `openspec/changes/`。

**必须**使用以下之一（禁止手写 `openspec/changes/`）：

| 方式 | 说明 |
|------|------|
| 聊天 **`/opsx:propose`** | 别名 `/opsx-propose` |
| Read/调用 **`openspec-propose`** Skill | `<agent-skills-dir>/openspec-propose/SKILL.md` |

**Agent 须完成**：

| # | 动作 |
|---|------|
| 1 | 确定 `<change-name>`（kebab-case） |
| 2 | 在 `openspec/changes/<change-name>/` 生成下表产物 |
| 3 | 按需联动 dba / golang / frontend / ui-interaction / pressure-test expert |

**OpenSpec 产物**：

| 文件 | 内容 |
|------|------|
| `proposal.md` | 背景、目标、范围、不做什么 |
| `design.md` | 架构、接口、数据流（体现 Explore **用户选定**方案） |
| `tasks.md` | 可勾选原子任务（≤ 半天/项） |
| `specs/` | 能力/接口规格（如涉及） |

**执行后**：生成 `1.proposal.md` 索引（摘要 + 超链接，不复制全文）。

> **模板定位**：[01-proposal.md](../templates/01-proposal.md) 仅提供**章节结构示例**；超链接须按 [plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md) 计算 PREFIX。

**project-config 无效时**：复制 [templates/project-config.md](../templates/project-config.md) → 按 [exploration.md](exploration.md) 探索填写 → 通过有效性校验。

---

## 四、1.proposal.md 要求

### 4.1 章节内容

| 章节 | 要求 |
|------|------|
| OpenSpec 变更目录 | 项目根相对路径 `openspec/changes/<change-name>/`（元信息 + 可点击链接） |
| 产物索引表 | 超链接指向 proposal / design / tasks / specs |
| 方案摘要 | 2–5 句（摘自 proposal，非全文） |
| 关键决策 | design.md 要点 |
| 任务概览 | tasks 数量与 P0 项，附链接 |

### 4.2 超链接计算（硬性，禁止照抄模板）

完整规则见 **[plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md)**（全 Phase 通用）。Phase 1 须链接的目标：

| 目标 | 项目根相对路径 |
|------|----------------|
| OpenSpec 目录 | `openspec/changes/<change-name>/` |
| OpenSpec 文件 | `openspec/changes/<change-name>/proposal.md`（design / tasks 同理） |
| specs | `openspec/changes/<change-name>/specs/<capability>/spec.md` |

**示例**（默认 N=4，`PREFIX=../../../../`）：

```markdown
| proposal.md | … | [proposal.md](../../../../openspec/changes/torrent-search-plaza/proposal.md) |
| specs/      | … | [specs/torrent-search/spec.md](../../../../openspec/changes/torrent-search-plaza/specs/torrent-search/spec.md) |
```

### 4.3 归档后链接

Phase 7 归档完成后，由 [update-proposal-links](../scripts/update-proposal-links.ps1) 将正文中的 `openspec/changes/<name>` 替换为 `openspec/archive/<date>-<name>`；**PREFIX 不变**（见 plan-dir-link-prefix §五）。

---

## 五、Propose 后用户确认（硬性）

> 本节为 **`/opsx:propose` 产物生成后** 的确认；与 §2.2 Explore 方案选择 **分开**，不得合并为一次 AskUserQuestion。

**提问模板**：

```
问题："OpenSpec 方案已生成，请审阅 1.proposal.md 及 openspec/changes/<change-name>/ 后选择："
选项：
  - ✅ 确认方案，继续 Phase 2
  - ✏️ 需要修改
  - ❌ 方案不可行，重新设计
```

修改 → 更新 OpenSpec + 同步 `1.proposal.md` → 再次确认。**未确认不得进入 Phase 2。**

---

## 六、质量门禁

→ [checklist.md](../checklist.md) § Phase 1
