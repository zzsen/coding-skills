# Phase 4: 测试补充与执行

> **产物**：`<plan-dir>/4.test-case.md` + **新增/更新的自动化测试代码** + `<plan-dir>/test-results/`
> **定位**：Phase 3 TDD Wave 已写部分测试；本 Phase **补缺口自动化用例** → **跑全量** → **再** 汇总文档。
> **禁止**：只生成 `4.test-case.md` 罗列「手动待测」而不写 `*_test.go` / `*.test.ts`；不跑 `run-tests` 即宣称完成。

---

## 流程概览

```
§一 门禁（不可自行跳过，须 AskUserQuestion）
  ↓
§二 基线：run-tests.ps1（全量 go test + vitest）
  ↓
§三 缺口分析（TDD 计划 + tasks.md + 本次变更代码）
  ↓
§四 补充自动化测试（*_test.go / *.test.ts，按 03-1 备注规范）
  ↓
§五 跑全量测试用例至通过
  ↓
§六 生成 4.test-case.md（以实际执行结果为准）
  ↓
Phase 5
```

| 阶段 | 章节 | 关键动作 |
|------|------|----------|
| 准入 | §一 | 用户未跳过；Lint 本 Phase 不跑 |
| 基线执行 | §二 | **`run-tests.ps1`** 首个 Shell（全量，非单包手敲） |
| 补测 | §三–§四 | 对照 TDD/tasks **编写**自动化测试 |
| 全量复跑 | §五 | 循环 **`run-tests`** 直至 `TESTS: pass` |
| 文档 | §六 | `4.test-case.md` 反映**真实**用例与覆盖率 |

---

## 一、门禁

| 规则 | 说明 |
|------|------|
| **不可自行跳过** | 须 AskUserQuestion 由用户决定 |
| 跳过时 | 仍生成 `4.test-case.md`，记录原因与确认 |
| Lint | 本阶段不跑，统一 Phase 5 |

---

## 二、基线测试执行（硬性，Phase 4 首个 Shell）

**必须**在项目根执行（禁止只手敲单包 `go test` 代替）：

```powershell
& <skill_root>/scripts/run-tests.ps1 -PlanDir <plan-dir>
```

```bash
bash <skill_root>/scripts/run-tests.sh <plan-dir>
```

- 产出：`<plan-dir>/test-results/backend-go-test.log`、`frontend-vitest.log`、`test-counts.json`
- stdout：`TESTS: pass` 或 `TESTS: fail`
- **禁止**：未跑上述脚本即填写 `4.test-case.md` 的「执行结果」

---

## 三、缺口分析

对照以下来源，列出**尚未被自动化覆盖**的 P0 场景：

| 来源 | 用途 |
|------|------|
| `docs/superpowers/plans/*-tdd.md` | Wave / Task 要求的测试点 |
| `openspec/changes/<name>/tasks.md` | 验收相关任务 |
| Phase 3 变更文件列表（`3.dev.md`） | 本次新增/修改的 service、controller、组件 |
| 基线 `run-tests` 日志 | 失败项、0 case 模块 |

**新功能增量**（本次 plan 引入的后端 service/controller、前端关键组件）：**须有**对应自动化测试文件，**不得**仅用「手动 API / 手动 E2E」行代替。

---

## 四、补充自动化测试（硬性）

1. **编写/更新**测试代码（非只写文档）：
   - 后端：`backend/**/*_test.go`，备注见 [03-1-backend-test-remarks.md](../templates/03-1-backend-test-remarks.md)
   - 前端：有 vitest 时补 `*.test.ts` / `*.spec.ts`（关键组件/ composable）
2. 覆盖：**正常路径 + 异常/边界**（对照 §三 缺口表）
3. 单测优先；集成/API 测可用 httptest / 项目既有测试基建
4. **禁止**：在 `4.test-case.md` 新增大量「⬜ 待测」手动行，却不新增任何 `*_test.go` / `*.test.ts`

> 手动 E2E / 联调用例可记入 `4.test-case.md` **附录**，**不能**作为 Phase 4 唯一交付。

---

## 五、跑全量测试用例至通过

> **硬性**：补测后须跑**全量**测试并**循环至通过**；禁止只跑单包 / 部分用例后进入 Phase 5。

1. 补测完成后 **立即** 执行 §二 `run-tests`（全量 backend + frontend，禁止手敲单包 `go test` / `vitest` 某文件代替）
2. stdout 须为 **`TESTS: pass`**；若为 `TESTS: fail` → 按 §七 定位并修复 → **再次全量** `run-tests`
3. **循环**步骤 2，直至 stdout 输出 `TESTS: pass`（每次失败累加 `test_fail_count`）
4. 通过后记录覆盖率于 `4.test-case.md` §2；后端 service 层目标参考 project-config（通常 ≥80%，未达标须在 §4 说明原因与计划）
5. 进入 Phase 5 条件：**必须**已达成 `TESTS: pass`；仅用户 AskUserQuestion 确认跳过时例外（须在 `4.test-case.md` 记录原因）

---

## 六、生成 4.test-case.md

模板：[04-test-case.md](../templates/04-test-case.md)（结构示例；TDD 外链 PREFIX 见 [plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md)）。

| 章节 | 要求 |
|------|------|
| §1 用例清单 | **§1.1 / §1.4 须对应磁盘上真实测试文件与方法**；禁止虚构未实现的「自动化」行 |
| §2 覆盖率 | 来自 `run-tests` / `go tool cover`，非估算 |
| §3 执行结果 | 粘贴或引用 `test-results/*.log` 摘要 |
| 手动用例 | 可放 §1.2/§1.3，须标「手动」，且不能替代 §四 自动化补测 |

---

## 七、测试失败修复

```
失败 → 根因在测试代码？ → 是：修测试 → 重跑 run-tests
                    → 否：修业务代码 → 重跑 run-tests
```

| 类型 | 修复对象 |
|------|---------|
| 测试代码问题 | `*_test.go` / `*.test.ts` |
| 业务代码问题 | 业务代码 |
| 两者都有 | 业务 + 测试 |

每次失败累加 `test_fail_count`。

---

## 八、Phase 5 回退再入

Lint 修复回退本 Phase 时：

1. 评估 Lint 修复影响：业务逻辑变 → 可能新增/改用例；仅风格 → 通常不需要
2. 如需 → 更新测试 + `4.test-case.md`
3. **运行全部** `run-tests`（不可只跑部分）
4. 通过 → 回 Phase 5；失败 → §七

---

## 九、质量门禁

→ [checklist.md](../checklist.md) § Phase 4
