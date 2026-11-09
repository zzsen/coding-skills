# Phase 5: Lint 检测

> **产物**：`lint-results/*.log` + `lint-counts.json` + `5.lint-report.md`

---

## 一、执行步骤

1. **运行脚本**（推荐）：

```powershell
& <skill_root>/scripts/run-lint.ps1 -PlanDir <plan-dir>
```

```bash
bash <skill_root>/scripts/run-lint.sh <plan-dir>
```

2. 读 `5.lint-report.md` 确认错误
3. 修复 → 重跑至通过
4. `ReadLints` 二次确认已编辑文件

---

## 二、项目类型识别

| 类型 | 识别特征 |
|------|---------|
| Go | `go.mod` |
| Vue/TS 前端 | `package.json` 含 `vue` |
| TS (Node) | `package.json` + `tsconfig.json`，无 `vue` |
| JS (Node) | `package.json`，无 `tsconfig` |
| Python | `pyproject.toml` / `setup.py` / `requirements.txt` |
| Rust | `Cargo.toml` |
| Java Maven | `pom.xml` |
| Java Gradle | `build.gradle` / `build.gradle.kts` |

**跳过**：`node_modules/`、`.git/`、`dist/`、`build/`、`dev-plan/`、`.cursor/`、`scripts/`、`docker/`。

---

## 三、Lint 规则表

| 类型 | 检测项 | 工具 | Fallback | 日志命名 |
|------|-------|------|----------|---------|
| Go | Lint | golangci-lint | go vet | `<dir>-golangci-lint.log` |
| Vue/TS | ESLint | eslint | — | `<dir>-eslint.log` |
| Vue/TS | 类型 | **vue-tsc -b** | — | `<dir>-vue-tsc.log` |
| Vue/TS | 构建 | Vite | — | `<dir>-build.log` |
| TS Node | ESLint / tsc / build | eslint / tsc | — | 同上模式 |
| JS Node | ESLint | eslint | — | `<dir>-eslint.log` |
| Python | Lint / 类型 | ruff / mypy | flake8→pylint / pyright | `<dir>-ruff.log` 等 |
| Rust | clippy / build | cargo | — | `<dir>-clippy.log` |
| Java | checkstyle / compile | mvn / gradle | — | `<dir>-checkstyle.log` |

> Vue/TS **必须** `npx vue-tsc -b --noEmit`。`go build` 不能替代 golangci-lint。

---

## 四、手动执行（无脚本时）

```bash
SEPARATOR=">>>>>>>>>> LINT RUN @ $(date '+%Y-%m-%d %H:%M:%S') <<<<<<<<<<"
echo "$SEPARATOR" >> <plan-dir>/lint-results/<dir>-<工具>.log
cd <dir> && <命令> 2>&1 | tee -a ../<plan-dir>/lint-results/<dir>-<工具>.log
node <skill_root>/scripts/parse-lint-results.js <plan-dir>
```

基于 `lint-counts.json` 生成 [05-lint-report.md](../templates/05-lint-report.md)。

---

## 五、零错误要求

- **全局零错误**（含历史遗留）
- **禁止**：以存量为由跳过；只查新文件；改配置绕过；跳过 Phase 4 回退

---

## 六、Phase 4 ↔ 5 循环

```
Phase 5 发现错误 → 修复
  → 强制回退 Phase 4
  → 评估是否新增用例 → 跑全部测试
  → 通过 → 回 Phase 5
  → 连续通过 → Phase 6
```

累加：`lint_fail_count`、`test_fail_count`。

### lint-counts.json 含义

| 值 | 含义 | 行为 |
|----|------|------|
| `-1` | 未执行 | 补执行 |
| `0` | 无错误 | 通过 |
| `>0` | N 个错误 | 修复重跑 |

---

## 七、完成判定

1. 各子目录检测项均有 `.log`
2. `lint-counts.json` 存在且 `passed: true`
3. `5.lint-report.md` 存在

---

## 八、质量门禁

→ [checklist.md](../checklist.md) § Phase 5
