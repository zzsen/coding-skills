#!/usr/bin/env python3
"""
=============================================================================
parse-lint-results.py — 解析 Phase 5 Lint 日志（Python 实现）
=============================================================================
【功能】从 lint-results/ 四个 log 提取最后一次运行的 errors/warnings，写 lint-counts.json。
【调用阶段】Phase 5；由 run-lint 自动调用（node 不可用时的 fallback）。
【输入】<plan-dir> 位置参数
【输出】
  lint-counts.json；stdout：GOLINT_ERRORS=、PASSED= 等 KEY=VALUE
  errors=-1 表示该检测项未执行
【流程】
  1. 按分隔符取各 log 最后批次
  2. 正则解析四类工具输出
  3. 汇总 passed 并写 JSON
【用法】python parse-lint-results.py <plan-dir>
=============================================================================
"""

import sys
import os
import re
import json
from datetime import datetime

if len(sys.argv) < 2:
    print("用法: python parse-lint-results.py <plan-dir>", file=sys.stderr)
    sys.exit(1)

plan_dir = sys.argv[1]
lint_dir = os.path.join(plan_dir, "lint-results")
SEPARATOR_RE = re.compile(r"^>>>>>>>>>> LINT RUN @", re.MULTILINE)


def file_exists(filepath):
    return os.path.isfile(filepath)


def read_file(filepath):
    try:
        with open(filepath, "r", encoding="utf-8", errors="replace") as f:
            return f.read()
    except (FileNotFoundError, PermissionError):
        return ""


def extract_last_run(content):
    if not content:
        return ""
    separators = list(SEPARATOR_RE.finditer(content))
    if separators:
        return content[separators[-1].end():].lstrip("\n")
    return content


def count_runs(content):
    if not content:
        return 0
    return len(SEPARATOR_RE.findall(content))


def parse_golangci_lint(content):
    if not content.strip():
        return {"errors": 0, "warnings": 0}
    issues = re.findall(r"^\S+\.go:\d+:\d+:.*$", content, re.MULTILINE)
    warnings = sum(1 for line in issues if re.search(r"\bwarning\b", line, re.IGNORECASE))
    return {"errors": len(issues) - warnings, "warnings": warnings}


def parse_eslint(content):
    if not content.strip():
        return {"errors": 0, "warnings": 0}
    m = re.search(r"(\d+)\s+errors?\s*,\s*(\d+)\s+warnings?", content)
    if m:
        return {"errors": int(m.group(1)), "warnings": int(m.group(2))}
    m = re.search(r"[✖×]\s*(\d+)\s+problems?", content)
    if m:
        return {"errors": int(m.group(1)), "warnings": 0}
    errors = len(re.findall(r"^\s+\d+:\d+\s+error\s+", content, re.MULTILINE))
    warnings = len(re.findall(r"^\s+\d+:\d+\s+warning\s+", content, re.MULTILINE))
    return {"errors": errors, "warnings": warnings}


def parse_vue_tsc(content):
    if not content.strip():
        return {"errors": 0}
    m = re.search(r"Found\s+(\d+)\s+errors?", content)
    if m:
        return {"errors": int(m.group(1))}
    return {"errors": len(re.findall(r"error TS\d+", content))}


def parse_build(content):
    if not content.strip():
        return {"errors": 0}
    esbuild = len(re.findall(r"✘\s*\[ERROR\]", content))
    if esbuild > 0:
        return {"errors": esbuild}
    ts = len(re.findall(r"error TS\d+", content))
    if ts > 0:
        return {"errors": ts}
    if re.search(r"error during build", content, re.IGNORECASE):
        return {"errors": 1}
    generic = len(re.findall(r"^ERROR\b", content, re.MULTILINE))
    if generic > 0:
        return {"errors": generic}
    m = re.search(r"exited with (\d+)", content)
    if m and int(m.group(1)) != 0:
        return {"errors": 1}
    return {"errors": 0}


# ── 主流程 ──────────────────────────────────────
# errors = -1 表示日志文件不存在（未执行对应检测）
# errors = 0  表示已执行且无错误
# errors > 0  表示已执行且存在错误
file_paths = {
    "golangci_lint": os.path.join(lint_dir, "golangci-lint.log"),
    "eslint":        os.path.join(lint_dir, "eslint.log"),
    "vue_tsc":       os.path.join(lint_dir, "vue-tsc.log"),
    "build":         os.path.join(lint_dir, "build.log"),
}

exists = {k: file_exists(v) for k, v in file_paths.items()}
raw = {k: read_file(v) if exists[k] else "" for k, v in file_paths.items()}
last = {k: extract_last_run(v) for k, v in raw.items()}
runs = {k: count_runs(v) for k, v in raw.items()}

parsers = {
    "golangci_lint": parse_golangci_lint,
    "eslint":        parse_eslint,
    "vue_tsc":       parse_vue_tsc,
    "build":         parse_build,
}

parsed = {}
for k, parser_fn in parsers.items():
    if exists[k]:
        parsed[k] = parser_fn(last[k])
    else:
        parsed[k] = {"errors": -1, "warnings": 0} if k in ("golangci_lint", "eslint") else {"errors": -1}

all_errors = [p["errors"] for p in parsed.values()]
has_missing = any(e == -1 for e in all_errors)
positive_errors = sum(e for e in all_errors if e > 0)
total_errors = -1 if has_missing else positive_errors
passed = not has_missing and positive_errors == 0

result = {
    "golangci_lint": {**parsed["golangci_lint"], "warnings": parsed["golangci_lint"].get("warnings", 0), "runs": runs["golangci_lint"]},
    "eslint":        {**parsed["eslint"], "warnings": parsed["eslint"].get("warnings", 0), "runs": runs["eslint"]},
    "vue_tsc":       {**parsed["vue_tsc"], "runs": runs["vue_tsc"]},
    "build":         {**parsed["build"], "runs": runs["build"]},
    "total_errors":  total_errors,
    "passed":        passed,
    "parsed_at":     datetime.now().isoformat(),
    "parser":        "python",
}

os.makedirs(lint_dir, exist_ok=True)
with open(os.path.join(lint_dir, "lint-counts.json"), "w", encoding="utf-8") as f:
    json.dump(result, f, indent=2, ensure_ascii=False)

# stdout: KEY=VALUE
print(f"GOLINT_ERRORS={parsed['golangci_lint']['errors']}")
print(f"GOLINT_WARNINGS={parsed['golangci_lint'].get('warnings', 0)}")
print(f"GOLINT_RUNS={runs['golangci_lint']}")
print(f"ESLINT_ERRORS={parsed['eslint']['errors']}")
print(f"ESLINT_WARNINGS={parsed['eslint'].get('warnings', 0)}")
print(f"ESLINT_RUNS={runs['eslint']}")
print(f"VUETSC_ERRORS={parsed['vue_tsc']['errors']}")
print(f"VUETSC_RUNS={runs['vue_tsc']}")
print(f"BUILD_ERRORS={parsed['build']['errors']}")
print(f"BUILD_RUNS={runs['build']}")
print(f"TOTAL_ERRORS={total_errors}")
print(f"PASSED={str(passed).lower()}")
