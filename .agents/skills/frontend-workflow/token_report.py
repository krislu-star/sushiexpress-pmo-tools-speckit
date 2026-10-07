#!/usr/bin/env python3
"""Generate token usage report from workflow token log files."""

import re
import sys
import os
from datetime import datetime
from collections import defaultdict

# Sonnet 4.6 API pricing (per token) — used as computation proxy for subscription users
PRICE = {
    "out": 15.00 / 1_000_000,
    "in":   3.00 / 1_000_000,
    "cw":   3.75 / 1_000_000,
    "cr":   0.30 / 1_000_000,
}


def parse_log_files(workflow_dir):
    log_files = []
    for entry in sorted(os.listdir(workflow_dir)):
        full = os.path.join(workflow_dir, entry)
        if os.path.isdir(full) and re.match(r"token_\w+$", entry):
            # New format: token_{session}/ directory with per-entry files
            log_files += sorted(
                os.path.join(full, f)
                for f in os.listdir(full)
                if f.endswith(".txt")
            )
        elif os.path.isfile(full) and re.match(r"token_\w+\.txt$", entry):
            # Old format: single token_{session}.txt file
            log_files.append(full)

    if not log_files:
        print(f"No token log files found in {workflow_dir}", file=sys.stderr)
        sys.exit(1)

    phases = {}
    phase_order = []
    totals = defaultdict(int)

    for log_file in log_files:
        with open(log_file) as f:
            for line in f:
                line = line.strip()
                if not line or "COMPACT_TRIGGERED" in line:
                    continue

                is_sub = "[subagent]" in line

                m = re.search(r"phase=(\S+)", line)
                if not m:
                    continue
                phase = m.group(1)

                if not re.match(r"^(BUILD|REVIEW)-\d{3}$", phase):
                    phase = "other"

                def extract(pattern):
                    m = re.search(pattern, line)
                    return int(m.group(1)) if m else 0

                in_v  = extract(r"\bin=(\d+)")
                out_v = extract(r"\bout=(\d+)")
                cr_v  = extract(r"cache_read=(\d+)")
                cw_v  = extract(r"cache_write=(\d+)")

                if phase not in phases:
                    phases[phase] = defaultdict(int)
                    phase_order.append(phase)

                phases[phase]["in"]      += in_v
                phases[phase]["out"]     += out_v
                phases[phase]["cr"]      += cr_v
                phases[phase]["cw"]      += cw_v
                if is_sub:
                    phases[phase]["sub_out"] += out_v

                totals["in"]  += in_v
                totals["out"] += out_v
                totals["cr"]  += cr_v
                totals["cw"]  += cw_v

    return phases, totals


def usd(d):
    cost = (
        d["out"] * PRICE["out"]
        + d["in"]  * PRICE["in"]
        + d["cw"]  * PRICE["cw"]
        + d["cr"]  * PRICE["cr"]
    )
    return f"${cost:.3f}"


def fmt(n):
    return f"{n:,}"


def generate_report(phases, totals):
    def sort_key(p):
        if p.startswith("BUILD-"):  return (0, p)
        if p.startswith("REVIEW-"): return (1, p)
        return (2, p)

    sorted_phases = sorted(phases.keys(), key=sort_key)
    total_out = totals["out"]

    rows = []
    for phase in sorted_phases:
        d = phases[phase]
        pct = f"{d['out'] * 100 // total_out}%" if total_out > 0 else "0%"
        out_str = fmt(d["out"])
        if d["sub_out"] > 0:
            out_str += f" ↑{fmt(d['sub_out'])}"
        rows.append(
            f"| {phase} | {out_str} | {fmt(d['in'])} | {fmt(d['cw'])} | {fmt(d['cr'])} | {pct} | {usd(d)} |"
        )

    total_cost = (
        totals["out"] * PRICE["out"]
        + totals["in"]  * PRICE["in"]
        + totals["cw"]  * PRICE["cw"]
        + totals["cr"]  * PRICE["cr"]
    )
    rows.append(
        f"| **Total** | **{fmt(totals['out'])}** | **{fmt(totals['in'])}** |"
        f" **{fmt(totals['cw'])}** | **{fmt(totals['cr'])}** | 100% | **${total_cost:.3f}** |"
    )

    ts = datetime.now().astimezone().isoformat(timespec="seconds")

    return "\n".join([
        "# Token Usage Report",
        "",
        f"Generated: {ts}",
        "",
        "## By Phase",
        "",
        "| Phase | out ¹ | in ² | cache_write ³ | cache_read ⁴ | out% | ~USD ⁵ |",
        "|-------|------:|-----:|-------------:|------------:|-----:|-------:|",
        *rows,
        "",
        "> `↑N` in the `out` column = subagent contribution to that phase",
        "",
        "**欄位說明**",
        "",
        "| # | 欄位 | 說明 | 對訂閱配額的影響 |",
        "|---|------|------|----------------|",
        "| ¹ | `out` | AI 生成的 token 數 | **最高**，是 5 小時配額的主要消耗來源 |",
        "| ² | `in` | 用戶輸入的新 token 數 | 低，通常比 `out` 小一個數量級 |",
        "| ³ | `cache_write` | 首次將 context 寫入 cache | 一次性成本；後續回合轉為 `cache_read` |",
        "| ⁴ | `cache_read` | 從 cache 讀取的 context | 幾乎免費；數字高代表 context 複用良好 |",
        "| ⁵ | `~USD` | Sonnet 4.6 API 定價換算 | 訂閱制無實際帳單，此欄作為計算量的相對參考 |",
    ])


if __name__ == "__main__":
    workflow_dir = sys.argv[1] if len(sys.argv) > 1 else "workflow"

    if not os.path.isdir(workflow_dir):
        print(f"Directory not found: {workflow_dir}", file=sys.stderr)
        sys.exit(1)

    phases, totals = parse_log_files(workflow_dir)
    report = generate_report(phases, totals)

    output_path = os.path.join(workflow_dir, "token_report.md")
    with open(output_path, "w") as f:
        f.write(report + "\n")

    print(f"✅ Token report → {output_path}\n")
    print(report)
