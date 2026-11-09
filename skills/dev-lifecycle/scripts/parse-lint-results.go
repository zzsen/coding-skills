//go:build ignore

// =============================================================================
// parse-lint-results.go — 解析 Phase 5 Lint 日志（Go 实现）
// =============================================================================
// 【功能】从 lint-results/ 四个 log 提取最后一次运行的 errors/warnings，写 lint-counts.json。
// 【调用阶段】Phase 5；由 run-lint 自动调用（node/python 不可用时的 fallback）。
// 【输入】<plan-dir> 位置参数
// 【输出】lint-counts.json；stdout：KEY=VALUE；errors=-1 表示未执行
// 【流程】
//   1. 按分隔符取各 log 最后批次
//   2. 正则解析四类工具输出
//   3. 汇总 passed 并写 JSON
// 【用法】go run parse-lint-results.go <plan-dir>
// =============================================================================

package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

var separatorRe = regexp.MustCompile(`(?m)^>>>>>>>>>> LINT RUN @`)

// golangci-lint: file.go:line:col: message
var golintIssueRe = regexp.MustCompile(`(?m)^\S+\.go:\d+:\d+:.*$`)
var warningRe = regexp.MustCompile(`(?i)\bwarning\b`)

// eslint 汇总: N errors, N warnings
var eslintSummaryRe = regexp.MustCompile(`(\d+)\s+errors?\s*,\s*(\d+)\s+warnings?`)
var eslintProblemRe = regexp.MustCompile(`[✖×]\s*(\d+)\s+problems?`)
var eslintErrorLineRe = regexp.MustCompile(`(?m)^\s+\d+:\d+\s+error\s+`)
var eslintWarningLineRe = regexp.MustCompile(`(?m)^\s+\d+:\d+\s+warning\s+`)

// vue-tsc: Found N errors
var vueTscFoundRe = regexp.MustCompile(`Found\s+(\d+)\s+errors?`)
var tsErrorRe = regexp.MustCompile(`error TS\d+`)

// build: ✘ [ERROR]
var esbuildErrorRe = regexp.MustCompile(`✘\s*\[ERROR\]`)
var buildErrorRe = regexp.MustCompile(`(?i)error during build`)
var genericErrorRe = regexp.MustCompile(`(?m)^ERROR\b`)
var exitedWithRe = regexp.MustCompile(`exited with (\d+)`)

type ToolResult struct {
	Errors   int `json:"errors"`
	Warnings int `json:"warnings,omitempty"`
	Runs     int `json:"runs"`
}

type Result struct {
	GolangciLint ToolResult `json:"golangci_lint"`
	Eslint       ToolResult `json:"eslint"`
	VueTsc       ToolResult `json:"vue_tsc"`
	Build        ToolResult `json:"build"`
	TotalErrors  int        `json:"total_errors"`
	Passed       bool       `json:"passed"`
	ParsedAt     string     `json:"parsed_at"`
	Parser       string     `json:"parser"`
}

func fileExists(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}

func readFile(path string) string {
	data, err := os.ReadFile(path)
	if err != nil {
		return ""
	}
	return string(data)
}

func extractLastRun(content string) string {
	if content == "" {
		return ""
	}
	locs := separatorRe.FindAllStringIndex(content, -1)
	if len(locs) > 0 {
		last := locs[len(locs)-1]
		// 找到分隔符行末尾
		rest := content[last[1]:]
		if idx := strings.Index(rest, "\n"); idx >= 0 {
			return strings.TrimLeft(rest[idx+1:], "\n")
		}
		return ""
	}
	return content
}

func countRuns(content string) int {
	if content == "" {
		return 0
	}
	return len(separatorRe.FindAllString(content, -1))
}

func parseGolangciLint(content string) (errors, warnings int) {
	if strings.TrimSpace(content) == "" {
		return 0, 0
	}
	issues := golintIssueRe.FindAllString(content, -1)
	for _, line := range issues {
		if warningRe.MatchString(line) {
			warnings++
		} else {
			errors++
		}
	}
	return
}

func parseEslint(content string) (errors, warnings int) {
	if strings.TrimSpace(content) == "" {
		return 0, 0
	}
	if m := eslintSummaryRe.FindStringSubmatch(content); len(m) == 3 {
		errors = atoi(m[1])
		warnings = atoi(m[2])
		return
	}
	if m := eslintProblemRe.FindStringSubmatch(content); len(m) == 2 {
		errors = atoi(m[1])
		return
	}
	errors = len(eslintErrorLineRe.FindAllString(content, -1))
	warnings = len(eslintWarningLineRe.FindAllString(content, -1))
	return
}

func parseVueTsc(content string) int {
	if strings.TrimSpace(content) == "" {
		return 0
	}
	if m := vueTscFoundRe.FindStringSubmatch(content); len(m) == 2 {
		return atoi(m[1])
	}
	return len(tsErrorRe.FindAllString(content, -1))
}

func parseBuild(content string) int {
	if strings.TrimSpace(content) == "" {
		return 0
	}
	if n := len(esbuildErrorRe.FindAllString(content, -1)); n > 0 {
		return n
	}
	if n := len(tsErrorRe.FindAllString(content, -1)); n > 0 {
		return n
	}
	if buildErrorRe.MatchString(content) {
		return 1
	}
	if n := len(genericErrorRe.FindAllString(content, -1)); n > 0 {
		return n
	}
	if m := exitedWithRe.FindStringSubmatch(content); len(m) == 2 && m[1] != "0" {
		return 1
	}
	return 0
}

func atoi(s string) int {
	n := 0
	for _, c := range s {
		if c >= '0' && c <= '9' {
			n = n*10 + int(c-'0')
		}
	}
	return n
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "用法: go run parse-lint-results.go <plan-dir>")
		os.Exit(1)
	}
	planDir := os.Args[1]
	lintDir := filepath.Join(planDir, "lint-results")

	// errors = -1 表示日志文件不存在（未执行对应检测）
	// errors = 0  表示已执行且无错误
	// errors > 0  表示已执行且存在错误
	golintPath := filepath.Join(lintDir, "golangci-lint.log")
	eslintPath := filepath.Join(lintDir, "eslint.log")
	vuetscPath := filepath.Join(lintDir, "vue-tsc.log")
	buildPath := filepath.Join(lintDir, "build.log")

	golintExists := fileExists(golintPath)
	eslintExists := fileExists(eslintPath)
	vuetscExists := fileExists(vuetscPath)
	buildExists := fileExists(buildPath)

	var golintErrors, golintWarnings int
	var eslintErrors, eslintWarnings int
	var vuetscErrors, buildErrors int

	if golintExists {
		raw := readFile(golintPath)
		golintErrors, golintWarnings = parseGolangciLint(extractLastRun(raw))
	} else {
		golintErrors = -1
	}

	if eslintExists {
		raw := readFile(eslintPath)
		eslintErrors, eslintWarnings = parseEslint(extractLastRun(raw))
	} else {
		eslintErrors = -1
	}

	if vuetscExists {
		raw := readFile(vuetscPath)
		vuetscErrors = parseVueTsc(extractLastRun(raw))
	} else {
		vuetscErrors = -1
	}

	if buildExists {
		raw := readFile(buildPath)
		buildErrors = parseBuild(extractLastRun(raw))
	} else {
		buildErrors = -1
	}

	rawGolint := readFile(golintPath)
	rawEslint := readFile(eslintPath)
	rawVuetsc := readFile(vuetscPath)
	rawBuild := readFile(buildPath)

	golintRuns := countRuns(rawGolint)
	eslintRuns := countRuns(rawEslint)
	vuetscRuns := countRuns(rawVuetsc)
	buildRuns := countRuns(rawBuild)

	allErrors := []int{golintErrors, eslintErrors, vuetscErrors, buildErrors}
	hasMissing := false
	positiveErrors := 0
	for _, e := range allErrors {
		if e == -1 {
			hasMissing = true
		} else if e > 0 {
			positiveErrors += e
		}
	}
	totalErrors := positiveErrors
	if hasMissing {
		totalErrors = -1
	}
	passed := !hasMissing && positiveErrors == 0

	result := Result{
		GolangciLint: ToolResult{Errors: golintErrors, Warnings: golintWarnings, Runs: golintRuns},
		Eslint:       ToolResult{Errors: eslintErrors, Warnings: eslintWarnings, Runs: eslintRuns},
		VueTsc:       ToolResult{Errors: vuetscErrors, Runs: vuetscRuns},
		Build:        ToolResult{Errors: buildErrors, Runs: buildRuns},
		TotalErrors:  totalErrors,
		Passed:       passed,
		ParsedAt:     time.Now().Format(time.RFC3339),
		Parser:       "go",
	}

	_ = os.MkdirAll(lintDir, 0o755)
	data, _ := json.MarshalIndent(result, "", "  ")
	_ = os.WriteFile(filepath.Join(lintDir, "lint-counts.json"), data, 0o644)

	// stdout: KEY=VALUE
	fmt.Printf("GOLINT_ERRORS=%d\n", golintErrors)
	fmt.Printf("GOLINT_WARNINGS=%d\n", golintWarnings)
	fmt.Printf("GOLINT_RUNS=%d\n", golintRuns)
	fmt.Printf("ESLINT_ERRORS=%d\n", eslintErrors)
	fmt.Printf("ESLINT_WARNINGS=%d\n", eslintWarnings)
	fmt.Printf("ESLINT_RUNS=%d\n", eslintRuns)
	fmt.Printf("VUETSC_ERRORS=%d\n", vuetscErrors)
	fmt.Printf("VUETSC_RUNS=%d\n", vuetscRuns)
	fmt.Printf("BUILD_ERRORS=%d\n", buildErrors)
	fmt.Printf("BUILD_RUNS=%d\n", buildRuns)
	fmt.Printf("TOTAL_ERRORS=%d\n", totalErrors)
	fmt.Printf("PASSED=%t\n", passed)
}
