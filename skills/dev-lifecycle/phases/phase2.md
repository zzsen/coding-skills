# Phase 2: TDD 计划（writing-plans）

> **产物**：`<plan-dir>/2.plan.md`（索引）+ `docs/superpowers/plans/YYYY-MM-DD-<feature>-tdd.md`
> **权威**：Superpowers TDD 计划文件
> **强制工具**：[mandatory-tooling.md](../reference/mandatory-tooling.md) — **必须** Read/调用 **`writing-plans`** Skill，**禁止**手写 TDD 替代。

---

## 一、硬门禁（缺任一项 → 禁止本 Phase）

| # | 条件 | 验证 |
|---|------|------|
| 1 | Shell 0.5 + 门禁报告已输出 | 会话可见 |
| 2 | `1.proposal.md` 存在 | Read / Test-Path |
| 3 | `openspec/changes/<name>/proposal.md` 存在 | Test-Path |
| 4 | 同目录 `design.md`、`tasks.md` 存在 | Test-Path |
| 5 | 用户 **AskUserQuestion 确认** Phase 1 | 会话记录 |

❌ → 回到 [phase1.md](phase1.md) 或 [preparation.md](preparation.md)；**不得**调用 `writing-plans`。

**脚本验证**（项目根目录）：

```powershell
& <skill_root>/scripts/gate-phase2.ps1 -PlanDir <plan-dir> -ChangeName <change-name>
```

```bash
bash <skill_root>/scripts/gate-phase2.sh --plan-dir <plan-dir> --change-name <change-name>
```

| 禁止 | 替代 |
|------|------|
| 因「制定开发计划」跳过 Phase 1 | 完整 Phase 1 → 确认 → Phase 2 |
| `writing-plans` 不可用时手写 TDD | [preparation.md](preparation.md) 补 Superpowers；**禁止**手写 `docs/superpowers/plans/` 凑合 |
| 不读 `writing-plans` 直接写 TDD 文件 | **必须** Read/调用 **`writing-plans`** Skill |
| 照抄模板 `../../` 作为 TDD / OpenSpec 超链接 | 按 [plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md) 计算 PREFIX |

---

## 二、执行 writing-plans（硬性）

> **必须** Read/调用 Superpowers **`writing-plans`** Skill（Reload 后可用 Skill 列表须含该项）。**禁止**不读 Skill 直接手写 `docs/superpowers/plans/*-tdd.md`。

### 执行前

1. Superpowers 环境已就绪（[preparation.md](preparation.md)）
2. 读取：`1.proposal.md`、`openspec/changes/<name>/` 下 proposal / design / tasks / specs

### Agent 须

1. TDD Task/Wave **映射** `tasks.md` 原子任务编号
2. 保存：`docs/superpowers/plans/YYYY-MM-DD-<feature>-tdd.md`（日期 Shell 获取）
3. 含「**Wave 汇总**」章节（`.cursor/rules/02-tdd-plan-wave-tracking.mdc`）
4. 每步 Red → Green → Refactor，含测试代码与运行命令
5. 完成 writing-plans 自检（Spec coverage、Placeholder scan、Type consistency）

**执行后**：生成 `2.plan.md` 索引。

> **模板定位**：[02-plan.md](../templates/02-plan.md) 仅提供**章节结构示例**；TDD / tasks 超链接须按 [plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md) 计算 PREFIX。

---

## 三、2.plan.md 要求

| 章节 | 要求 |
|------|------|
| TDD 计划链接 | 超链接至 `docs/superpowers/plans/*-tdd.md`（**PREFIX + 根相对路径**） |
| OpenSpec 关联 | 链接 `1.proposal.md`（同目录）、`tasks.md`（PREFIX + openspec） |
| Wave 概览表 | TDD「Wave 汇总」镜像，Phase 3 须同步 |
| 任务映射表 | tasks ↔ Wave/Task |

**超链接**：遵循 [plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md)；写入前 `Test-Path` 校验 TDD 文件与 tasks.md 存在。

---

## 四、Wave 同步义务

- `2.plan.md` Wave 表为 TDD 计划**只读镜像**
- Phase 3 更新 TDD Wave 状态与 Step 勾选后**必须同步** `2.plan.md`
- 禁止 TDD 已 `✅ 已完成` 而 `2.plan.md` 仍 `⬜ 未开始`
- 禁止 Wave 已 `✅` 而 TDD 计划内对应 Step 仍为 `- [ ]`（见 `02-tdd-plan-wave-tracking.mdc` §三）

---

## 五、用户确认（硬性）

```
问题："TDD 计划已生成，请审阅 2.plan.md 及 docs/superpowers/plans/*-tdd.md 后选择："
选项：
  - ✅ 确认计划，开始开发（Phase 3）
  - ✏️ 需要调整
  - ❌ 计划不合理，重新制定
```

---

## 六、worktree 隔离（进入 Phase 3 前，git 必做）

> **非 git 项目跳过本节**（降级为单工作树，按 change 目录隔离）。

用户「✅ 确认计划，开始开发」后、进入 Phase 3 前：

1. 把 openspec（changes / specs）+ TDD 计划 **commit 到当前（源）分支**（worktree 是干净 checkout，不 commit 带不过去）。
2. **AskUserQuestion 只确认源分支**（默认当前分支）；分支名 `{feature|fix}-<change-name>` 自动，**无需用户确认**。
3. 运行 `worktree-create --change-name <name> --kind feature|fix --base-branch <源分支>` → 创建 `.worktrees/<branch>`、登记 `.dev-lifecycle/worktrees.tsv`、自动把 `.worktrees/` 写进 `.gitignore`。
4. 记录 worktree 绝对路径 `<git-root>/.worktrees/<branch>`，**Phase 3~6 源码/测试/文档改动只在该路径内进行**。

**铁律**：主工作树**禁止** checkout/switch 到 change 分支；**禁止** `git checkout -b` / `git switch -c` 为 change 建分支——一律走 `worktree-create`。

---

## 七、质量门禁

→ [checklist.md](../checklist.md) § Phase 2
