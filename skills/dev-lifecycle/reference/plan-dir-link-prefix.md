# plan-dir 产物超链接 PREFIX 规则

> **适用范围**：`<plan-dir>/` 下所有 Markdown 产物（`1.proposal.md` ~ `7.acceptance.md`）中，指向**项目根下**路径的超链接（`openspec/`、`docs/superpowers/plans/` 等）。
>
> **模板定位**：`templates/*.md` 仅提供章节结构；链接中的 `<PREFIX>` 须按本节计算，**禁止**照抄历史模板中的 `../../`。

---

## 一、解析规则

Markdown 链接相对**当前 `.md` 文件所在目录**解析（不是「计划目录」抽象概念，也不是模板占位路径）。

| 链接类型 | 写法 | 示例 |
|----------|------|------|
| **同 plan-dir 互链** | 仅文件名 | `[2.plan.md](2.plan.md)` |
| **项目根下资源** | `{PREFIX}` + 根相对路径 | `[tasks.md](<PREFIX>openspec/changes/<name>/tasks.md)` |

---

## 二、PREFIX 计算步骤（硬性）

| 步骤 | 动作 |
|------|------|
| 1. 确认 `<plan-dir>` | `init-plan-dir` 输出，或当前任务已有目录，如 `dev-plan/202607/20260702/20260702224002_feat_xxx/` |
| 2. 计算层级 **N** | 统计 `<plan-dir>` 相对**项目根**的目录段数（不含文件名）：`dev-plan` / `YYYYMM` / `YYYYMMDD` / `YYYYMMDDHHmmss_<type>_<detail>` → 默认 **N = 4**；结构不同按**实际段数**重算 |
| 3. 构造 PREFIX | N 个 `../` 拼接；N=4 → `../../../../` |
| 4. 拼接目标 | `{PREFIX}` + 项目根相对路径（见 §三） |
| 5. 校验存在 | 项目根 `Test-Path`（或等价 Shell）确认目标文件/目录存在 |

---

## 三、常用目标路径

| 目标 | 项目根相对路径 |
|------|----------------|
| OpenSpec 目录 | `openspec/changes/<change-name>/` |
| OpenSpec 文件 | `openspec/changes/<change-name>/proposal.md`（design / tasks 同理） |
| OpenSpec specs | `openspec/changes/<change-name>/specs/<capability>/spec.md` |
| OpenSpec 归档 | `openspec/archive/<YYYY-MM-DD>-<change-name>/`（Phase 7 后） |
| TDD 计划 | `docs/superpowers/plans/YYYY-MM-DD-<feature>-tdd.md` |

**示例**（N=4）：

```markdown
[proposal.md](../../../../openspec/changes/my-feature/proposal.md)
[YYYY-MM-DD-my-feature-tdd.md](../../../../docs/superpowers/plans/2026-07-02-my-feature-tdd.md)
```

---

## 四、禁止项

| 禁止 | 原因 |
|------|------|
| 照抄模板中 `../../` | 默认 2 层与 `init-plan-dir` 四段目录不一致 |
| 使用绝对路径（`d:\...`） | 不可移植 |
| 链接指向不存在的文件 | 须与实际产物一致 |

---

## 五、归档后链接（Phase 7）

[update-proposal-links](../scripts/update-proposal-links.ps1) 将正文中的 `openspec/changes/<name>` 替换为 `openspec/archive/<date>-<name>`；**PREFIX 不变**，仅替换根下路径段。

---

## 六、各 Phase 引用

| Phase | 产物 | 须 PREFIX 的链接 |
|-------|------|----------------|
| 1 | `1.proposal.md` | openspec/changes/* |
| 2 | `2.plan.md` | docs/superpowers/plans/*-tdd.md、openspec/changes/*/tasks.md |
| 3 | `3.dev.md` | docs/superpowers/plans/*-tdd.md（头部关联） |
| 4 | `4.test-case.md` | docs/superpowers/plans/*-tdd.md（头部关联） |
| 7 | `7.acceptance.md` | openspec/*、docs/superpowers/plans/* |

Phase 5 / 6 产物通常无跨根外链，同目录引用即可。
