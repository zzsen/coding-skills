# 5.lint-report.md 模板 — Lint 汇总

> **Phase 5** · [phase5.md](../phases/phase5.md) · 推荐由 `run-lint` 脚本生成；手动编写参考下方：

```markdown
# Lint 检测汇总报告

> 生成时间：YYYY-MM-DD HH:mm:ss
> 最后更新：YYYY-MM-DD HH:mm:ss
> 计划目录：dev-plan/...

## 总体结果：✅ 全部通过 / ❌ 存在未通过项（共 N 个错误）

> 错误数量来源：parse-lint-results 脚本正则提取（lint-counts.json）

## 检测明细

| 检测项 | 状态 | 错误数 | 警告数 | 累计运行次数 | 日志文件 |
|--------|------|--------|--------|-------------|----------|
| golangci-lint | ✅ | 0 | 0 | 3 | lint-results/xxx.log |

## 错误详情（最后一次运行）

（各检测项的错误详情或"无错误"）

## 修复建议

（无需修复 / 具体建议）
```
