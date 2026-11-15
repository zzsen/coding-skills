# project-config 模板

> **产物路径**：`.dev-lifecycle/project-config.md`
> **规则**：[exploration.md](../phases/exploration.md) §四 · [phase1.md](../phases/phase1.md)
>
> **流程**：复制模板 → 白名单探索填占位符 → 补充 §6/§8 → 有效性校验 → 方可 Propose

---

```markdown
# 项目配置（project-config.md）

> 生成时间：{{GENERATED_AT}}
> 最后更新：{{UPDATED_AT}}
> 校验指纹：`go.mod module={{GO_MODULE}}` | `package.json name={{PKG_NAME}}`

---

## 1. 项目基本信息

| 项目 | 内容 |
|------|------|
| 项目名称 | {{PROJECT_NAME}} |
| 仓库标识 | {{GO_MODULE}} / {{PKG_NAME}} |
| 项目类型 | {{MONO_OR_POLY}} |
| 主要语言 | {{LANGUAGES}} |
| 框架 | {{FRAMEWORKS}} |
| 包管理 | {{PACKAGE_MANAGERS}} |
| 仓库类型 | {{REPO_TYPE}}（single / multi / none，由 `detect-repos` 探测） |

### 仓库列表（`detect-repos` 生成，供 Phase 3 worktree 定位受影响仓库）

| 相对路径 | 默认分支 |
|---------|---------|
| {{REPO_1_PATH}} | {{REPO_1_BASE}} |
| {{REPO_2_PATH}} | {{REPO_2_BASE}} |

---

## 2. 目录结构概要

\`\`\`text
{{PROJECT_ROOT}}/
├── backend/         # {{BACKEND_DESC}}
├── frontend/        # {{FRONTEND_DESC}}
├── openspec/        # OpenSpec changes / specs / archive
├── docs/            # 项目文档
│   └── superpowers/plans/  # Superpowers TDD 计划
├── dev-plan/        # 开发生命周期产物索引
├── .worktrees/      # worktree 隔离目录（并行开发，自动 gitignore）
└── ...
\`\`\`

---

## 3. 技术栈与依赖

### 核心依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| {{DEP_1}} | {{VER_1}} | {{USE_1}} |

### 已有基础设施

| 设施 | 位置 | 说明 |
|------|------|------|
| 配置管理 | {{CONFIG_PATH}} | {{CONFIG_DESC}} |
| 缓存 | {{CACHE_PATH}} | {{CACHE_DESC}} |
| 日志 | {{LOG_PATH}} | {{LOG_DESC}} |

---

## 4. 编码风格

| 维度 | 约定 |
|------|------|
| 后端分层 | {{BACKEND_LAYERS}} |
| 前端分层 | {{FRONTEND_LAYERS}} |
| 命名约定 | {{NAMING}} |
| 测试风格 | {{TEST_STYLE}} |

---

## 5. 服务映射表

> Phase 7 验收时根据变更文件判断需重启的服务。

| 变更路径 | 影响的服务 | 启动命令 | 端口 |
|----------|-----------|---------|------|
| `backend/**` | {{BACKEND_SERVICE}} | {{BACKEND_CMD}} | {{BACKEND_PORT}} |
| `frontend/src/**` | {{FRONTEND_SERVICE}} | {{FRONTEND_CMD}} | {{FRONTEND_PORT}} |

---

## 6. 文档路径映射

| 变更维度 | 触发条件 | 对应文档位置 |
|---------|---------|-------------|
| {{TRIGGER_1}} | {{CONDITION_1}} | {{DOC_PATH_1}} |

---

## 7. 探索约定（硬性）

> **全局扫描黑名单与白名单**以 [phases/exploration.md](../phases/exploration.md) 为唯一权威（§1.1 全局忽略、§3 白名单、§2 禁止 `Glob **/*`）。本节仅记录**本项目**探索范围摘要，不维护独立忽略列表。

| 规则 | 说明 |
|------|------|
| 全局忽略 | 继承 exploration.md §1.1（Skill 级，不可在项目内覆盖） |
| 前端探索范围 | `frontend/src/`、`frontend/package.json`、`frontend/vite.config.*` |
| 后端探索范围 | `backend/**/*.go` 或按层 Read；不扫 `vendor/` |
| 禁止工具模式 | 禁止 `Glob **/*` / 子项目根递归（见 exploration.md §2） |

---

## 8. 特殊约定

1. {{CONVENTION_1}}
2. {{CONVENTION_2}}
```

---

## 有效性校验（生成后必须全部通过）

| # | 校验项 | 方法 |
|---|--------|------|
| 1 | `{{GO_MODULE}}` 与 `backend/go.mod` 的 `module` 一致 | 读 go.mod |
| 2 | `{{PKG_NAME}}` 与 `frontend/package.json` 的 `name` 一致 | 读 package.json |
| 3 | 服务映射表路径与仓库实际目录匹配 | 抽样核对 |
| 4 | 无未替换的 `{{占位符}}` | 全文搜索 `{{` |
| 5 | §7 探索约定已填写 | 非空；且未重复维护忽略列表（忽略以 exploration.md 为准） |
| 6 | 仓库类型为 single / multi / none；single/multi 时仓库列表非空 | 读 §1 仓库类型与仓库列表 |

任一失败 → **判定 project-config 无效**，禁止进入 Propose，须重新探索生成。
