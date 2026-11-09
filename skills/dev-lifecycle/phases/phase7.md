# Phase 7: 验收与 OpenSpec 归档

> **产物**：`<plan-dir>/7.acceptance.md`
> **验收通过后**：**必须** **`/opsx:archive`** 或 **`openspec-archive-change`** → 更新 `1.proposal.md` 链接
> **强制工具**：[mandatory-tooling.md](../reference/mandatory-tooling.md)

---

## 一、执行步骤

1. 读取前序产物：`1.proposal.md`、`openspec/changes/<name>/`、`2.plan.md`、TDD 计划、`3.dev.md` ~ `6.docs-update.md`
2. 读 `project-config.md` 服务映射表
3. 汇总：功能完成、耗时、质量指标、失败统计
4. 整理：重启服务清单、待执行 SQL、API 变更、遗留问题
5. **联动更新**前序产物（见 §三）
6. 生成 [07-acceptance.md](../templates/07-acceptance.md)（**14 章节硬性**；OpenSpec/TDD 外链 PREFIX 见 [plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md)）
7. **AskUserQuestion** 用户验收

---

## 二、用户验收与归档

```
问题："7.acceptance.md 已生成，请审阅后选择："
选项：
  - ✅ 验收通过，交付完成
  - ❌ 验收不通过（补充反馈）
```

### 验收通过 → 必须 Archive

**必须**使用以下之一（禁止仅 Shell 移动目录）：

| 方式 | 说明 |
|------|------|
| 聊天 **`/opsx:archive`** | 别名 `/opsx-archive` |
| Read/调用 **`openspec-archive-change`** Skill | `<agent-skills-dir>/openspec-archive-change/SKILL.md` |

归档效果：

1. `openspec/changes/<name>/` → `openspec/archive/<YYYY-MM-DD>-<name>/`（日期 Shell 获取）
2. 合入 `openspec/specs/`（按 OpenSpec 规范）
3. README/CHANGELOG 记录（如有惯例）

### 归档后更新链接

`1.proposal.md` 中 OpenSpec 链接从 `changes/` 改为 `archive/<date>-<name>/`（**PREFIX 不变**，见 [plan-dir-link-prefix.md](../reference/plan-dir-link-prefix.md) §五）：

```markdown
<!-- 归档前 --> [proposal.md](../../../../openspec/changes/user-management/proposal.md)
<!-- 归档后 --> [proposal.md](../../../../openspec/archive/2026-07-01-user-management/proposal.md)
```

同步：`1.proposal.md` 头部状态、`2.plan.md` tasks 链接、`7.acceptance.md` 产物清单。保留「生成时间」，更新「最后更新」。

**归档链接脚本**：

```powershell
& <skill_root>/scripts/update-proposal-links.ps1 -PlanDir <plan-dir> -ChangeName <name> -ArchiveDate YYYY-MM-DD
```

```bash
bash <skill_root>/scripts/update-proposal-links.sh --plan-dir <plan-dir> --change-name <name> --archive-date YYYY-MM-DD
```

**验收前检查**：

```powershell
& <skill_root>/scripts/gate-phase7.ps1 -PlanDir <plan-dir>
```

---

## 三、验收联动更新（生成 7 之前）

1. `3.dev.md` 最新轮次完成时间
2. `2.plan.md` Wave 表与 TDD 计划一致
3. `1.proposal.md` 任务/状态摘要（如有）
4. 以上「最后更新」同步刷新

> 归档链接在**用户确认验收通过后**更新，不在生成报告时提前改。

---

## 四、7.acceptance.md 14 章节（不可改）

完整模板：[07-acceptance.md](../templates/07-acceptance.md)

```
1. 基本信息    8. 文档更新统计
2. 方案摘要    9. 需要重启的服务
3. 开发耗时   10. 需要执行的 SQL
4. 计划执行   11. API 变更清单
5. 质量统计   12. 前端页面清单
6. Lint 结果  13. 遗留问题
7. 测试覆盖率 14. 产物清单（含归档路径）
```

---

## 五、质量门禁

→ [checklist.md](../checklist.md) § Phase 7
