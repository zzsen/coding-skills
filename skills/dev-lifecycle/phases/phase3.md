# Phase 3: 按 Wave 实施（TDD → 收尾 Apply）

> **产物**：`<plan-dir>/3.dev.md` + 代码 + Wave/tasks 状态同步 + `2.plan.md` 镜像
> **权威**：`docs/superpowers/plans/*-tdd.md`
> **主路径（阶段 A）**：Read/调用 Superpowers **`executing-plans`**，按 TDD 计划 **Wave 1…N** 完成初步开发。
> **收尾（阶段 B）**：**全部 Wave ✅ 之后**，若 `tasks.md` 仍有未勾选项，**才** **`/opsx:apply`** 或 **`openspec-apply-change`**。
>
> **禁止**：Phase 3 入口直接 `/opsx:apply` 或 `openspec-apply-change` 代替 Wave TDD（`openspec-apply-change` Skill 写「开始实现」时，dev-lifecycle **仍以本节为准**）。
>
> **worktree（git 必做）**：Phase 2 已创建隔离 worktree。本节所有源码/测试/文档的 Edit/Write、测试/lint/构建，一律在 worktree 路径 `<git-root>/.worktrees/<branch>` 内进行；`3.dev.md` 报告仍写主工作树 `<plan-dir>/`。非 git 项目跳过，在主工作树按 change 目录隔离。

---

## 一、总体流程

```
读取 2.plan.md → 定位 TDD 计划
  → Read/调用 executing-plans Skill
  → Wave 1 → … → Wave N（TDD 循环，按 Skill 纪律）
      每 Wave 完成：勾选 TDD Step + tasks.md → 更新 Wave 汇总 → 同步 2.plan.md → 追加 3.dev.md
  → 全部 Wave ✅ → /opsx:apply 或 openspec-apply-change（处理 tasks 剩余项）
  → Phase 4
```

---

## 二、Wave 实施（阶段 A — Phase 3 主路径）

> **进入 Phase 3 时只做本阶段**，**不得**此时调用 `/opsx:apply` 或 `openspec-apply-change`。Apply 见 **§三（阶段 B）**。
>
> **进入本阶段前**：Read/调用 Superpowers **`executing-plans`** Skill。**禁止**不读 Skill 直接按 TDD 文件或 `tasks.md` 自由编码。

1. 从 `2.plan.md` 打开 TDD 计划
2. 找 Wave 汇总表第一个非 `✅ 已完成` 的 Wave
3. 标为 `🔄 进行中`（TDD 计划 + `2.plan.md`）
4. **TDD 循环**（每 Task）：失败测试 → 实现 → 通过 → 重构；TodoWrite 追踪
5. **Wave 完成**（顺序见 `02-tdd-plan-wave-tracking.mdc` §三）：
   - 本 Wave 测试全通过
   - TDD 计划正文：本 Wave 范围内所有 Step `- [ ]` → `- [x]`
   - 勾选 `tasks.md` 对应项
   - TDD「Wave 汇总」→ `✅ 已完成`；`2.plan.md` 镜像同步
   - `3.dev.md` 追加记录（时间 Shell 获取）
6. 重复至全部 Wave `✅`

### 开发顺序参考

| 层级 | 顺序 |
|------|------|
| 后端 | Entity → Repository → Service → Handler → 路由 |
| 前端 | API → 类型 → 组件/页面 → 路由 |

---

## 三、OpenSpec Apply（阶段 B — 全部 Wave ✅ 之后）

> **前置**：§二 **全部 Wave** 已 `✅ 已完成`。**禁止**在仍有进行中/未完成 Wave 时调用 apply。

全部 Wave ✅ 后检查 `tasks.md` 未勾选项：

- **有剩余** → **必须** **`/opsx:apply`** 或 Read/调用 **`openspec-apply-change`** Skill，逐项实现并勾选
- **无剩余** → 跳过，进 Phase 4

**禁止**：不调用 apply 工具，手动改代码并勾选 tasks。

apply 期间：每项完成后跑相关测试，禁止扩大范围。

**Wave / tasks 同步检查**：

```powershell
& <skill_root>/scripts/check-wave-sync.ps1 -PlanDir <plan-dir>
& <skill_root>/scripts/check-tasks-sync.ps1 -ChangeName <name> -PlanDir <plan-dir>
```

---

## 四、3.dev.md 要求

结构见 [03-dev.md](../templates/03-dev.md)（**结构示例**）。每轮/Wave 追加：

- Wave 编号与 Task 范围
- 开始/完成时间（Shell）
- 变更文件列表
- 勾选的 OpenSpec tasks 编号

**超链接**：头部 TDD 计划链接须按 [plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md) 计算 PREFIX；同目录 `[2.plan.md](2.plan.md)` 无需 PREFIX。

---

## 五、验收后反馈 → 回退本 Phase

> 已存在 `7.acceptance.md` 时，**任何**相关修改请求 = 验收后反馈。

```
用户反馈 → 评估：新 Wave 还是修补？
  ├─ 大范围 → 视情况回 propose / writing-plans
  └─ Bug/小修 → 3.dev.md 新轮次 + TDD 修复
→ Phase 4 → 5 → 6 → 7
```

**禁止**：直接改代码后只给总结；以「小 Bug」跳过阶段。

---

## 六、联动 Skill

| 领域 | Skill | 要点 |
|------|-------|------|
| **Wave 实施（必须）** | **`executing-plans`** | 按 Wave TDD 纪律执行 |
| 后端 | golang-expert | 分层、Swagger、%w |
| 前端 | frontend-expert | Composition API + TS |
| 数据库 | dba-expert | 非空字段、索引 |

---

## 七、质量门禁

→ [checklist.md](../checklist.md) § Phase 3
