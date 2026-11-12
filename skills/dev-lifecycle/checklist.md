# 各阶段质量门禁检查清单

Agent 每阶段完成时逐项核对。环境相关项见 [preparation.md](phases/preparation.md)、[SKILL.md](SKILL.md) §一。

---

## 通用

### 环境与门禁

- [ ] `preflight` 已作为首个 Shell 执行；`gate-cache: valid`（.preflight-last-run 距今 ≤ 7 天）则复用缓存，否则已全量执行且通过后刷新时间戳，门禁 §1 引用其输出
- [ ] [00-pre-flight-check-report.md](templates/00-pre-flight-check-report.md) 结论「可以写文件」
- [ ] Rules 已检查/恢复（preflight 内含 restore-rules）
- [ ] Shell **`environment-ready: True`**（非仅 `openspec-ready`）
- [ ] OpenSpec + Superpowers 环境均已补全（非手写替代）
- [ ] 环境未就绪时仅环境 AskUserQuestion（#1a/#1b/#2），未与 Phase AskUserQuestion 混搭

### 计划目录

- [ ] `dev-plan/<YYYYMM>/<YYYYMMDD>/<YYYYMMDDHHmmss>_<type>_<detail>/` 已创建
- [ ] `lint-results/` 已创建

### 时间与编号

- [ ] 产物含「生成时间」「最后更新」（Shell 获取）
- [ ] 修改时保留原「生成时间」，刷新「最后更新」
- [ ] 任务编号 `T-{YYYYMMDD}-{序号}` 一致（1/2/3/7.proposal/plan/dev/acceptance）

### 项目配置

- [ ] `project-config.md` 有效（`validate-project-config` 通过）
- [ ] 探索未扫 [exploration.md](phases/exploration.md) §一黑名单

---

## Phase 1: OpenSpec Propose

**Explore**（新功能）：

- [ ] 已调用 **`/opsx:explore`** 或 **`openspec-explore`**（非纯会话 Explore）
- [ ] **对话正文**已完整输出 §2.1（1）–（6）（含 `## （1）`…`## （6）`、对比表、≥2 方案小节）
- [ ] **未**出现「下面给出 §2.1」类空承诺即 AskUserQuestion
- [ ] **未**把方案详情只写在 AskUserQuestion 选项里
- [ ] phase1.md §2.2 自检 6 项均已满足
- [ ] 新功能：≥2 备选方案，**每方案含思路 / 架构 / 优缺点 / 成本**
- [ ] 新功能：**方案对比表**已在对话正文输出
- [ ] 新功能：**推荐方案及理由**已在对话正文输出（AskUserQuestion 前）
- [ ] 新功能：Explore AskUserQuestion 用户**明确**确认选定方案（跳过 ≠ 确认）
- [ ] **未**在 §2.1 对话正文输出前调用 `init-plan-dir` / Write `openspec/**`
- [ ] 已有功能变更：可跳过 Explore（记录理由）

**产物**：

- [ ] **`/opsx:propose`** 或 **`openspec-propose`** 已执行（**禁止**手写 openspec/changes）
- [ ] `openspec/changes/<name>/` 含 proposal / design / tasks
- [ ] `1.proposal.md` 为索引，含可点击超链接（PREFIX 见 [plan-dir-link-prefix.md](reference/plan-dir-link-prefix.md)）
- [ ] 超链接目标文件/目录已 `Test-Path` 校验存在

**确认**：

- [ ] AskUserQuestion 用户确认方案（未确认不得 Phase 2）

---

## Phase 2: writing-plans

- [ ] 硬门禁 5 项 + `gate-phase2` 脚本通过（AskUserQuestion 确认仍须会话验证）
- [ ] **`writing-plans`** Skill 已调用并生成 TDD 计划（**禁止**手写替代）
- [ ] TDD 含「Wave 汇总」（`02-tdd-plan-wave-tracking.mdc`）
- [ ] `2.plan.md` 含超链接 + Wave 镜像表（TDD / tasks 外链 PREFIX 正确，已 Test-Path）
- [ ] Task 可映射 `tasks.md`；无 TBD 占位符
- [ ] AskUserQuestion 用户确认计划

---

## Phase 3: Wave 开发

- [ ] 按 Wave 顺序 TDD 实施
- [ ] Wave 状态：进行中/完成 + `2.plan.md` 同步
- [ ] TDD 计划本 Wave 范围内 Step 勾选框已 `- [x]`（Wave ✅ 时不得残留 `- [ ]`）
- [ ] `tasks.md` 对应项已勾选
- [ ] **`executing-plans`** Skill 已 Read/调用，**全部 Wave ✅** 后才进入 apply
- [ ] **未**在 Wave 未完成时调用 `/opsx:apply` 或 `openspec-apply-change`
- [ ] 全部 Wave ✅ 后 **`/opsx:apply`** 或 **`openspec-apply-change`** 已处理剩余 tasks（无剩余可跳过）
- [ ] `3.dev.md` 按轮次追加，含 Shell 时间戳；TDD 头部外链 PREFIX 正确

**验收后反馈**：

- [ ] 有 `7.acceptance.md` 时修改请求 = 场景 A
- [ ] 回退时完整走 Phase 4→5→6→7

**代码**：

- [ ] 后端：分层、Swagger、%w、路由
- [ ] 前端：API 层、Composition API、无 any

---

## Phase 4: 测试补充与执行

- [ ] 未自行跳过；跳过须 AskUserQuestion + 记录原因
- [ ] **首个 Shell**：`run-tests.ps1` / `run-tests.sh`（全量），产出 `test-results/` 与 `TESTS: pass|fail`
- [ ] **已补充自动化测试代码**（`*_test.go` / `*.test.ts`），非仅 `4.test-case.md` 手动行
- [ ] 新功能增量（本次 plan 的 service/controller/关键组件）有对应自动化用例
- [ ] 补测后 **循环全量** `run-tests` 直至 `TESTS: pass`（或用户 AskUserQuestion 确认跳过并记录）
- [ ] `4.test-case.md`：§1 自动化行对应磁盘真实测试；§2 覆盖率来自 `run-tests`；§3 引用 `test-results/*.log`
- [ ] TDD 头部外链 PREFIX 正确；后端备注符合 [03-1-backend-test-remarks.md](templates/03-1-backend-test-remarks.md)
- [ ] 失败已累加 `test_fail_count` 并修复后重跑

---

## Phase 5: Lint

- [ ] 各子目录 × 检测项均有 `.log`
- [ ] `lint-counts.json` 无 `-1`，errors 全 `0`，`passed: true`
- [ ] `5.lint-report.md` 总体 ✅
- [ ] ReadLints 无新增问题
- [ ] 修复后强制回退 Phase 4，连续通过方可 Phase 6

---

## Phase 6: 文档

- [ ] AskUserQuestion 确认更新范围
- [ ] 仅更新确认项；跳过项已记录
- [ ] `6.docs-update.md` 已生成

---

## Phase 7: 验收

**联动更新**（生成 7 之前）：

- [ ] `3.dev.md` / `2.plan.md` / `1.proposal.md` 已同步

**归档**（验收通过后）：

- [ ] **`/opsx:archive`** 或 **`openspec-archive-change`** 已执行（**禁止**仅手动 mv）
- [ ] `1.proposal.md` 链接指向 archive
- [ ] `7.acceptance.md` 含 14 章节（不可改编号）；OpenSpec/TDD 外链 PREFIX 正确

**确认**：

- [ ] AskUserQuestion 验收结果

---

## Hotfix 简化

符合 [01-openspec-workflow.mdc](reference/01-openspec-workflow.mdc) 可跳过 Phase 1/2；否则仍须 OpenSpec **`/opsx:propose`** + Superpowers **`writing-plans`**（见 [mandatory-tooling.md](reference/mandatory-tooling.md)）。仍需：

- [ ] 计划目录（`fix` 类型）
- [ ] Phase 3 代码 + Phase 4 测试 + Phase 5 Lint
- [ ] Phase 6（如有影响）+ Phase 7 简化验收
