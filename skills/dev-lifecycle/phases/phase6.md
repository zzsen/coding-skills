# Phase 6: 文档更新

> **产物**：`<plan-dir>/6.docs-update.md`

---

## 一、门禁

> **任何文档更新/新增前必须 AskUserQuestion 确认**。未经确认直接更新 = 违规。

---

## 二、执行步骤

1. 扫描本次变更文件
2. 读 `project-config.md`「文档路径映射」
3. 分析文档影响，生成建议清单
4. **AskUserQuestion** 展示清单，用户选择执行项
5. 仅更新用户确认项
6. 生成 [06-docs-update.md](../templates/06-docs-update.md)（含跳过项）

### AskUserQuestion 示例

```
问题："本次开发涉及以下文档变更，请选择需要执行的项："
选项（allow_multiple=true）：
- [更新] docs/xxx.md - xxx
- [新增] docs/yyy.md - yyy
- 全部跳过
```

---

## 三、质量门禁

→ [checklist.md](../checklist.md) § Phase 6
