# 入口门禁检查报告模板

> [SKILL.md](../SKILL.md) §1.1 **步骤 2** Read 本文件（**须晚于** Shell preflight）。
> 在**首个回复**完整输出下方模板块。
> §1 须依据 **preflight / check-env** 输出填写，禁止猜测 ✅/❌。

---

## 一、输出时机与禁止项

### 1.1 何时输出

完成 **Shell preflight**（内置门禁缓存：`.preflight-last-run` 距今 ≤ 7 天时输出 `gate-cache: valid` 并直接跳过全量检查）并 Read `preparation.md` 后，**首个回复**必须输出本报告。

### 1.1a 缓存命中（preflight 输出 `gate-cache: valid`）

`.dev-lifecycle/.preflight-last-run` **仅在门禁通过时写入**，故标记存在且未超期即代表上次门禁通过。
此时门禁报告「检查时间」处标注 **「缓存命中，上次门禁通过于 <时间>（N 天前）」**，
§1 各检查项填 ✅（依据即 preflight 输出的 `environment-ready: True（缓存）`），§5 门禁结论为「可以」。
`gate-cache` 为 `stale` / `missing` / `malformed` 时 preflight 已自动全量执行，按其实际输出填写。

### 1.2 环境未就绪时

| 必须 | 禁止 |
|------|------|
| 输出 §1 环境检查 + §5 门禁结论「不可以」 | 填写 §2~§4 的 Phase 路径细节（标「待环境就绪」或省略） |
| **仅**发起环境 AskUserQuestion（#1a / #1b / #2） | Phase AskUserQuestion（Explore 确认、Phase 1→2 等） |
| 停止，等待用户补环境 | 「下一步做什么」「开始 Phase 1」等续航选项 |

### 1.3 门禁通过前禁止

| 类别 | 禁止 |
|------|------|
| **写产物** | `dev-plan/**`、`openspec/**`、`.dev-lifecycle/project-config.md`、规则 / 命令目录（恢复与官方 init 除外） |
| **探索仓库** | Glob/Grep 全量扫描（`exploration.md` 须门禁通过后再读） |
| **手写替代** | OpenSpec / Superpowers 未就绪时手写等价流程 |

---

## 二、输出模板（复制到回复，逐项填写）

```markdown
## 🔒 dev-lifecycle 入口门禁检查报告

> 检查时间：YYYY-MM-DD HH:mm:ss（Shell preflight 输出；缓存命中时为 .preflight-last-run 的上次通过时间，须标注「缓存命中」）
> 用户诉求：<一句话复述>
### 1. 环境检查

| 检查项 | 状态 | 说明 |
|--------|------|------|
| Agent | — | Shell 首行 `agent:`（claude-code / cursor / codex） |
| 常驻规则 | ✅ / ⚠️ / ➖ | Shell：`rules-kind` + `rules-ok`。**信息项，不参与门禁**：`mdc` 缺失已由 preflight 自动恢复；`memory-file` 仅提示；`none` 填 ➖ |
| OpenSpec CLI 全局安装 | ✅ / ❌ | Shell：`openspec-cli-installed`；版本行 `openspec-cli` |
| OpenSpec 目录 `openspec/` | ✅ / ❌ | Shell：路径 `openspec` True/False；缺失须 preflight ensure-openspec 已 init |
| OpenSpec `openspec list` | ✅ / ❌ | Shell：`openspec-list-ok` |
| OpenSpec 汇总 | ✅ / ❌ | Shell：`openspec-ready` |
| Superpowers `writing-plans` | ✅ / ❌ | Shell：`writing-plans:` 命中路径 |
| Superpowers `executing-plans` | ✅ / ❌ | Shell：`executing-plans:` 命中路径 |
| Superpowers 汇总 | ✅ / ❌ | Shell：`superpowers_ready` |
| 门禁汇总 | ✅ / ❌ | Shell：`environment-ready` = OpenSpec ∧ Superpowers（**False 则禁止 Phase 1~7**） |
| `writing-plans` Skill（会话） | ✅ / ❌ | 新会话后可用 Skill 列表 |
| project-config.md 存在 | ✅ / ❌ / ⬜ | Shell：`.dev-lifecycle/project-config.md` True/False；有效性门禁通过后再校验 |

> ⚠️ **不得**把「常驻规则 ⚠️」写成门禁不通过的理由 —— 它不参与 `environment-ready`。

### 2. 需求类型与 Phase 路径（仅门禁「可以」后填写）

| 项目 | 内容 |
|------|------|
| 判定场景 | 场景 A/B/C/D/E / Hotfix / **环境未就绪—跳过** |
| 需求类型 | 新功能 / 已有功能变更 / Hotfix / 验收后反馈 |
| 当前应执行 Phase | Phase N / **—** |
| 是否允许写文件 / 进入 Phase | ⛔ 禁止 / ✅ 允许 | **仅**当 `environment-ready: True` |

### 3. 项目探索策略（仅门禁「可以」后）

| 项目 | 内容 |
|------|------|
| 允许扫描范围 | exploration.md §3 白名单 |
| 已忽略目录 | exploration.md §1.1 黑名单 |

### 4. 计划目录（Phase 1+ 且门禁通过后）

| 项目 | 内容 |
|------|------|
| 计划目录 | `dev-plan/.../` 或 ⬜ 待创建 |
| lint-results/ | ✅ / ⬜ |

### 5. 门禁结论

- [ ] `environment-ready: True`（Shell preflight 输出）
- [ ] **可以** / **不可以** 进入 Phase 1~7 及写产物
```

---

## 三、阻断条件（任一条 → 结论「不可以」）

| # | 条件 |
|---|------|
| 0 | 未执行 Shell preflight，或 §1 未引用其输出（缓存命中时引用 `gate-cache: valid` / `environment-ready: True（缓存）` 与上次通过时间） |
| ~~1~~ | ~~Rules 缺失~~ —— **已废除**：常驻规则为 agent 可选项，缺失**不**构成阻断 |
| 2a | `openspec-cli-installed: False` |
| 2b | `openspec-list-ok: False`，或路径 `openspec` 仍为 False（CLI 已装但自动 init 失败 / list 失败） |
| 3a | `superpowers_ready: False`（`writing-plans` / `executing-plans` 未齐） |
| 3b | `environment-ready: False`（**含禁止进入 Phase 1**，不仅是 Phase 2） |
| 4 | `project-config.md` 无效且尚未按模板生成（门禁通过后项） |
| 5 | 新功能未经 Explore 与用户确认即拟 Propose |
| 6 | Phase 1 Explore **对话正文**未输出 §2.1（1）–（6）即 AskUserQuestion |
| 7 | 正文仅「下面给出 §2.1」或方案详情仅在 AskUserQuestion 选项中 |
| 8 | 调研轮次仅 Tool Call、无 §2.1 对话正文即 Propose / init-plan-dir |
| 9 | AskUserQuestion 被跳过即视为用户确认推荐方案 |
| 10 | Phase 1 Propose 未经用户确认即拟进入 Phase 2 |

---

## 四、AskUserQuestion 触发（环境 vs Phase 分离）

| 类型 | 条件 | 处理方式 |
|------|------|----------|
| **环境 #1a** | CLI 未安装 | preparation.md §5.2 |
| **环境 #1b** | 项目未 init | preparation.md §5.3 |
| **环境 #2** | Superpowers 未就绪 | preparation.md §5.4 |
| Phase 1 Explore | 新功能：**对话正文**已输出 §2.1（1）–（6） | 见 [phase1.md](../phases/phase1.md) 文首 **Explore 铁律** + §2.2 自检 |
| Phase 1→2 | Propose 产物完成 | **门禁通过后**单独 AskUserQuestion 确认方案 |
| Phase 2→3 | 计划完成 | **门禁通过后**单独 AskUserQuestion |

**硬性**：环境 ❌ 的同一回复内，**不得**出现上表 Phase 行对应的 AskUserQuestion。
