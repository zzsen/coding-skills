# 项目上下文安全探索策略

> **门禁「可以」后** Read 本文件（[SKILL.md](../SKILL.md) §1.3 第 3 步）。
> **禁止**在 Shell preflight 之前或环境未就绪时读取。
>
> **目标**：不全量扫描仓库的前提下获取足够上下文。
> **权威**：本章 §1 为 Skill **全局**黑名单，**不可**由 `project-config` 覆盖。

---

## 一、全局黑名单（§1.1）

按**目录名**匹配，作用于仓库**任意层级**：

| 目录名 | 原因 |
|--------|------|
| `node_modules/` | 依赖体积极大 |
| `.git/` | 无业务价值 |
| `.vscode/`、`.idea/` | IDE 配置 |
| `dist/`、`build/`、`.output/` | 构建产物 |
| `vendor/` | Go vendoring |
| `.venv/`、`venv/` | Python 虚拟环境 |
| `.turbo/`、`.next/`、`.nuxt/` | 前端缓存/产物 |
| `coverage/` | 覆盖率产物 |
| `dev-plan/` | 生命周期产物 |
| `.worktrees/` | worktree 隔离目录（并行开发副本，勿扫） |
| `.cursor/` | Agent 配置（读 Skill 用定点 `Read`） |

等效：`**/node_modules/**`、`**/.git/**` 等。工具不支持 exclude 时，**不得**用宽 glob，改白名单或定点 `Read`。

**维护**：仅在本表增删；会话追加忽略记入门禁报告 §3，持久生效须编辑本表。

---

## 二、禁止工具模式（门禁通过前同样生效）

| 禁止 | 替代 |
|------|------|
| `Glob **/*`、`Glob *`（含仓库根、子项目根） | §三白名单 glob 或定点 `Read` |
| `Glob backend/**`、`Glob frontend/**` | `backend/**/*.go`、`frontend/src/**` |
| 无路径 `Grep`、并行大范围扫描 | 限定 `backend/`、`frontend/src/` |
| `@backend` / `@frontend` 后 `Glob **/*` | 按白名单定点读取 |
| `Get-ChildItem -Recurse` 未排除 §一目录 | `-Depth N` + 路径过滤 |

**Shell 排除示例**：

```powershell
$ignore = 'node_modules|\.git|vendor|[/\\]\.venv[/\\]|[/\\]venv[/\\]|dist|build|\.vscode|dev-plan|\.worktrees|\.cursor'
Get-ChildItem -Path "d:\repo\frontend\src" -Recurse -File |
  Where-Object { $_.FullName -notmatch $ignore }
```

---

## 三、白名单探索路径

> 推荐先运行 `safe-list-files` 获取允许路径，再定点 `Read`：

```powershell
& <skill_root>/scripts/safe-list-files.ps1 -Scope all
```

```bash
bash <skill_root>/scripts/safe-list-files.sh --scope all
```

### 3.1 必读（优先 `Read`）

| 文件 | 用途 |
|------|------|
| `backend/go.mod` | 模块名、依赖 |
| `frontend/package.json` | 项目名、脚本 |
| `backend/conf/config.default.yml`（或同类） | 服务配置 |
| `templates/project-config.md` | 配置模板 |

### 3.2 后端

- 允许：`Glob backend/**/*.go`；按层 `Read` router/controller/service/models
- 禁止：`Glob backend/**`、`backend/vendor/**`

### 3.3 前端

- 允许：`Glob frontend/src/**`；`Read` package.json、vite.config.*、tsconfig.*
- 禁止：`Glob frontend/**`、对 `frontend/` 根递归

### 3.4 其他子项目

- 允许：`package.json`、`src/**`（或等价源码目录）
- 禁止：子项目根递归

---

## 四、project-config 生成

1. 复制 [templates/project-config.md](../templates/project-config.md) → `project-config.md`
2. 运行 `detect-repos` 探测仓库布局 → 填 §1「仓库类型」与「仓库列表」（single / multi / none，及每仓库相对路径 + 默认分支）
3. 按 §三白名单探索（`safe-list-files`），填写其余 `{{占位符}}`
4. 补充 §6 文档映射、§8 特殊约定
5. 运行 `validate-project-config` 通过 → 方可 Propose

**仓库探测**：

```bash
bash <skill_root>/scripts/detect-repos.sh
```

```powershell
& <skill_root>/scripts/detect-repos.ps1
```

输出 `REPO_TYPE: single|multi|none` + 每仓库 `repo: <相对路径>|<base>|<绝对路径>`，据此填 §1。

---

## 五、Explore 阶段（新功能）

> **权威**：[phase1.md](phase1.md) 文首 **Explore 铁律** + §2.0.5–§2.2。本节仅摘要。

**A 调研** → **B 对话正文 §2.1（1）–（6）** → **C AskUserQuestion** → `/opsx:propose`

**典型违规（禁止）**：

- 「下面给出 §2.1」+ 无六节正文 → `AskUserQuestion`
- 方案详情只写在 `AskUserQuestion` 选项里
- `openspec-explore`「无强制产出」**不能**作为跳过 §2.1 的理由

调用 `AskUserQuestion` 前须通过 phase1.md §2.2 **自检表 6 项**。

---

## 六、探索完成声明

```markdown
### 探索完成
- 已读关键文件：<列表>
- 未扫描 §一黑名单目录：✅
- project-config 校验：✅ / ❌
```
