# 4.test-case.md 模板 — 测试用例汇总（结构示例）

> **Phase 4** · [phase4.md](../phases/phase4.md)
>
> ⚠️ **先**补写自动化测试并跑 `run-tests`，**再**填本文档；禁止只写手动「待测」表即完成 Phase 4。
>
> ⚠️ TDD 外链须用 `<PREFIX>`，见 [plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md)。

```markdown
# 测试用例汇总: <功能名称>

> 生成时间：YYYY-MM-DD HH:mm:ss
> 最后更新：YYYY-MM-DD HH:mm:ss
> 关联计划：[2.plan.md](2.plan.md) → [TDD 计划](<PREFIX>docs/superpowers/plans/YYYY-MM-DD-<feature>-tdd.md)

---

## 1. 测试用例清单

### 后端测试

| # | 测试文件 | 测试方法 | 测试内容 | 类型 | 是否通过 |
|---|----------|----------|----------|------|----------|
| 1 | `service/xxx_test.go` | `TestXxx_Create` | xxx | 单元测试 | ✅ |

### 前端测试

| # | 测试文件 | 测试方法 | 测试内容 | 类型 | 是否通过 |
|---|----------|----------|----------|------|----------|
| 1 | `components/Xxx.test.ts` | `渲染数据` | xxx | 组件测试 | ✅ |

---

## 2. 覆盖率统计

| 模块 | 覆盖率 | 达标（≥80%） |
|------|--------|-------------|
| 后端 service 层 | 85% | ✅ |

---

## 3. 测试执行结果

（引用 `<plan-dir>/test-results/backend-go-test.log`、`frontend-vitest.log` 摘要；须来自 `run-tests` 全量执行）

---

## 4. 未覆盖项说明

| 模块 | 未覆盖原因 | 计划 |
|------|-----------|------|
| xxx | xxx | 后续补充 |

---

## 5. 测试命令汇总

\`\`\`bash
# 后端
cd backend && go test -v ./...
cd backend && go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out

# 前端
cd frontend && npx vitest run
cd frontend && npx vitest run --coverage
\`\`\`
```
