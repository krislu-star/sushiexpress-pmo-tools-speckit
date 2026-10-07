---
name: frontend-workflow
description: Full-cycle frontend build and review — auto-detects prototype reference
  and spec directories under references/, implements per FRONTEND_RULE_COMMON + profile
  RULE, then validates per REVIEW_RULE. PROTOTYPE_DIR is optional — if absent, runs
  in spec-only mode (read specs → plan → build → review, no visual comparison).
version: 5.4.0
alwaysApply: false
---

# Frontend Workflow

## Activation Contract

### Use this skill when
- A spec directory with `features/` and `use-cases/` exists under `references/`
- You need the full cycle: build → review → fix → pass
- A prototype reference directory optionally exists under `references/` (Figma Make, v0, Lovable, etc.)

### Do NOT use for
- Single component fixes or small changes with clear scope
- Review-only runs (follow `.agents/skills/frontend-workflow/REVIEW_RULE.md` directly)
- Projects without spec files (`features/` + `use-cases/`)

### How it works

This skill runs as an **orchestrator + subagent** architecture:

- **Main agent** (this session): runs Phase 0–1.5 (setup + study + planning), then orchestrates Phase 2–3 by spawning subagents for each task. Stays lightweight throughout.
- **Subagents**: each executes one BUILD or REVIEW task in its own isolated context. Returns `DONE:[summary]` or `BLOCKER:[description]`.
- **Planning always pauses for user review** before execution begins. No auto mode.

### Spec-only mode

When no `PROTOTYPE_DIR` is found, the workflow enters **spec-only mode**:
- Phase 1 Steps 1, 1.5, 1.6 (prototype reading, token extraction, component extraction) are skipped
- `comparison/STUDY_NOTES.md` is simplified (no Sections A/B/C — only spec-derived sections)
- BUILD task Briefs have no `**Page component structure**` block
- Phase 2 subagents do not perform prototype verification
- §2 (Visual Comparison) is skipped for all REVIEW tasks — no prototype reference to screenshot against

### Common mistakes / gotchas
- Building before mapping all spec features to screens
- Skipping the refactor pass after all screens are built (FRONTEND_RULE §8)
- Proceeding past a functional deviation without recording it in `comparison/DEVIATION_REPORT.md`
- Treating Phase 1 as complete without producing `comparison/STUDY_NOTES.md`
- Inferring shell layout decisions from conventions instead of quoting the reference source
- **Putting structure (markup, class names, column lists) into the Brief instead of a pointer to the prototype** — any transcribed or prose-described structure can drift from the source and get faithfully mis-built. The Brief names `port from <file>:<lines>` + a Deviations list; the subagent reads the prototype for structure. The only failure to guard now is an incomplete Deviations list (subagent reproduces the prototype where the spec wanted a change).

---

## Session Start Protocol

**Every session begins here before any phase logic.**

1. Check if `requirements/tasks/_index.md` exists.
   - **Exists** → Read it. Find the `▶ Next Task` entry.
     - Entry is a BUILD or REVIEW task → Output: `"繼續執行 [Task ID]: [Title]"` then go to Phase 2 or Phase 3 Orchestration Loop.
     - All tasks are `done` →
       **New cycle check:**
       1. Read `## Covered Specs` from `_index.md` (comma-separated F-xxx list).
       2. Run: `ls <SPEC_DIR>/features/` and collect all `F-xxx` filenames.
       3. Compare: new_specs = (all F-xxx in SPEC_DIR) − (Covered Specs).
       4. new_specs is non-empty →
          Output: `"偵測到 N 個新 spec：[F-xxx list]. 進入增量規劃"` then go to **Incremental Phase 1**.
       5. new_specs is empty → go to Phase 5.
   - **Does not exist** → Check if `comparison/STUDY_NOTES.md` exists.
     - **Exists** → Phase 1 is complete. Output: `"STUDY_NOTES 已存在，進入 Phase 1.5 (Task Planning)"` then go to Phase 1.5.
     - **Does not exist** → Fresh start. Output: `"全新 session，從 Phase 0 開始"` then go to Phase 0.

2. Main agent does NOT execute tasks directly — it spawns subagents. On resume, read `_index.md` to find the current task and spawn the appropriate subagent.

---

## Incremental Phase 1 — Read New Specs (New Cycle Only)

> Entered from Session Start Protocol when new uncovered F-xxx specs are detected.
> `STUDY_NOTES.md`, `DESIGN.md`, and `COMPONENTS.md` already exist — do not regenerate them. `DESIGN.md` covers all design tokens from the prototype globally; new features do not add new tokens.

### Step 1: Identify new specs

New specs = files in `SPEC_DIR/features/` whose F-xxx ID is NOT in `_index.md Covered Specs`.

Read all new `F-xxx.md` files. Read their corresponding `UC-xxx.md` files from `SPEC_DIR/use-cases/`.

### Step 2: Read prototype pages for new features (prototype mode only)

For each new F-xxx, identify the corresponding prototype page component(s) in `PROTOTYPE_DIR`.
Read **only those source files** — do not re-read prototype files already covered in existing STUDY_NOTES.

### Step 3: Append to `comparison/STUDY_NOTES.md`

**Append** new entries to the existing file. Do NOT modify existing sections.

**With PROTOTYPE_DIR** — append:
- **Section A additions**: new prototype files read in Step 2
- **Section B additions**: any new structural decisions visible in new prototype pages not already captured
- **Section D additions**: new spec requirements classified (Visual / Behavioral / Additive)

**Spec-only mode** — append:
- **Section A additions**: new feature → screen mappings (from new F-xxx.md)
- **Section B additions**: new Behavioral / Additive spec requirements

### Step 4: Proceed to Incremental Phase 1.5

Go to Incremental Phase 1.5.

---

## Incremental Phase 1.5 — New Cycle Task Planning

> Entered after Incremental Phase 1. Follows the same rules as standard Phase 1.5 except:
> - Task numbering continues from where the previous cycle left off
> - New tasks are appended to the existing `_index.md` (not rewritten)
> - FRONTEND_RULE_COMMON.md and profile SKILL.md need not be re-read if already read this session; in a fresh session, read them as Step 1 of standard Phase 1.5 before proceeding

### Step 1: Read existing `_index.md` for continuation numbers

```bash
grep "BUILD-\|REVIEW-" requirements/tasks/_index.md | tail -10
```

Identify:
- `last_build_num`: highest BUILD-N number in Task Queue (e.g., 4 if BUILD-004 exists)
- `last_review_num`: highest REVIEW-N number in Task Queue (e.g., 4 if REVIEW-004 exists)

New BUILD tasks start at `last_build_num + 1`. New REVIEW tasks start at `last_review_num + 1` (maintaining 1:1 pairing with new BUILD tasks).

### Step 2: Plan new BUILD tasks

Follow Phase 1.5 Steps 1–4 for new features only (new F-xxx identified in Incremental Phase 1).
Number new BUILD tasks from `last_build_num + 1` onward.
Write `requirements/tasks/BUILD-XXX-<slug>.md` files for each new BUILD task
(see **Task File Naming** in Phase 1.5 Step 4).

### Step 3: Plan new REVIEW tasks

For each new BUILD task (BUILD-N), create a paired `requirements/tasks/REVIEW-N-<slug>.md`
reusing that BUILD task's slug.
Follow the REVIEW task template from Phase 1.5 Step 5.
Status: `pending`.

### Step 4: Append to `_index.md`

Append new BUILD and REVIEW rows to the existing Task Queue table.
Update `## Covered Specs` to include all newly planned F-xxx (add to existing list, do not replace).
**Replace** `## ▶ Next Task` with the first new BUILD task — see the Index Hygiene rule below.

### `_index.md` Index Hygiene (mandatory)

`_index.md` is a **registry**, not a progress log. It answers only: which tasks exist, what
status they are, where the file is. Anything narrative belongs in `BUILD-xxx.md` /
`REVIEW-xxx.md`, which already hold the full record.

Two hard limits — check both whenever you touch `_index.md`:

1. **`## ▶ Next Task` holds at most 1 `▶` entry + 1 `▷` candidate.**
   Advancing means: move the current `▶` entry to `requirements/tasks/_index-archive.md`,
   then write the new one. **Never prepend a new entry above the old one.** Stacking entries
   is how this section grew to 16 entries / 99 KB before it was cut back.

2. **`## Task Queue` lists only unfinished tasks.**
   When a task flips to `done`, move its row to `_index-archive.md` in the same edit.

`_index-archive.md` is append-only, never read by this workflow, and exists purely for
traceability. Create it on first use with this header:

```markdown
# Task Index — Archive

> Historical rows moved out of `_index.md`, kept verbatim. This workflow never reads this file.
> For a task's full content, read its `BUILD-xxx.md` / `REVIEW-xxx.md`.
```

**Why this matters:** this skill reads `_index.md` in 8 places (continuation numbers, next
task, Covered Specs), so every run pays for its full size. A registry is bounded — one row
per task. A progress log is unbounded. Keeping them in one file makes the bounded thing grow
without limit.

### Step 5: Present plan to user (mandatory pause)

Same as Phase 1.5 Step 7 — present the new task rows and any blockers. Wait for confirmation before spawning subagents.

### Phase 1.5 Gate (same as standard Phase 1.5)

Apply all standard Phase 1.5 gate criteria to the new BUILD tasks only.

After user confirms → proceed to Phase 2 Orchestration Loop for the new BUILD tasks.

---

## Phase 0 — Setup

### Step 1: Auto-detect directories

Scan subdirectories under `references/` and identify:

**PROTOTYPE_DIR** (optional) — the subdirectory that contains `package.json`, `src/`, or `*.html` files.
- If exactly one match → auto-select.
- If multiple matches → ask the user.
- If **no match found** → set `PROTOTYPE_DIR=none`, `PROTO_TYPE=none`, and continue in **spec-only mode**. Report: `"未偵測到 PROTOTYPE_DIR，以 spec-only 模式執行"`.
- If the matched directory contains `*.html` but no `package.json` → mark as **static HTML prototype** (`PROTO_TYPE=static`); otherwise `PROTO_TYPE=npm`.

**SPEC_DIR** — detected in two stages:

1. **Primary: `-pm` suffix** — scan direct subdirectories of `references/` whose name ends with `-pm`.
   - Exactly one match → auto-select and report.
   - Multiple matches → skip to fallback below.
   - Zero matches → skip to fallback below.

2. **Fallback: structure scan** — collect all directories (recursively under `references/`) that contain both `features/` and `use-cases/`.
   - If exactly one candidate → auto-select.
   - If multiple candidates → apply keyword matching against `PROTOTYPE_DIR` (or project name if spec-only):
     1. Extract keywords from the `PROTOTYPE_DIR` path or project root name (e.g., `fsm-admin` → `admin`).
     2. Score each candidate by keyword matches in path.
     3. Unique top scorer → auto-select and report reason.
     4. Tie → ask the user and list tied options.

### Step 2: Resolve remaining inputs

**REF_PORT** (spec-only mode: skip)
- If `PROTO_TYPE=npm`: parse `-p <port>` or `--port <port>` from prototype's `package.json` dev script. If not found → use Vite default `5173` and report.
- If `PROTO_TYPE=static`: serve with `npx serve <PROTOTYPE_DIR> -p 5174 -l` (or next free port if 5174 is taken). Set `REF_PORT=5174`. Record the serve command — Phase 5 cleanup must kill this process too.

**OURS_PORT**
- Parse `-p <port>` from project root `package.json` dev script.
- If not found → auto-probe from port `3000`:
  1. `lsof -i :<candidate> -P -n | grep LISTEN`
     - No output AND candidate ≠ `REF_PORT` → use this port.
     - Otherwise → increment by 1 and retry (up to 3010).
  2. Only ask if no free port found in 3000–3010.

**REF_SOURCE** (spec-only mode: skip) — Default `server`; ask only if ref server fails to start.

Report all confirmed values, then proceed to Phase 1.

### Phase 0 Gate

- [ ] `PROTOTYPE_DIR` 已確認（路徑可存取）**或**已設為 `none`（spec-only 模式）
- [ ] `SPEC_DIR` 已確認（含 `features/` 與 `use-cases/`）
- [ ] `OURS_PORT` 已確認
- [ ] `REF_PORT` 已確認（spec-only 模式跳過）

輸出確認值後進入 Phase 1。

---

## Phase 1 — Study Prototype + Specs

> **Spec-only mode** (`PROTOTYPE_DIR=none`): Skip Steps 1, 1.5, and 1.6. Go directly to Step 2.

### Step 1: Read all source files (with PROTOTYPE_DIR only)

List every source file under `PROTOTYPE_DIR` and read each one.
Priority order:

1. Entry point / app shell (e.g., `App.tsx`, `Dashboard.tsx`, `_layout.tsx`)
2. Shared layout components (sidebar, header, navigation)
3. Feature page components
4. Shared UI primitives / stores

#### After reading: trace `src/imports/` active renders

For every file under `src/imports/` in the prototype:
1. Search all prototype source files for `import ... from '...imports/...'`
2. If imported AND appears in JSX → mark **active render** in Section A — must be ported or recorded as deviation
3. If never imported or type-reference only → mark **reference only**

> Common mistake: labeling all `src/imports/*.tsx` as "reference only". Figma Make often generates full-page visual components (e.g., `AccountLogin-60-86.tsx`) that are directly rendered — dropping them silently removes brand assets without any deviation record.

### Step 1.5: Extract Design Tokens (with PROTOTYPE_DIR only)

Invoke the `extract-design` skill:

```
Follow .agents/skills/extract-design/SKILL.md with:
  --dir <PROTOTYPE_DIR>
  --out references/DESIGN.md
```

- If `references/DESIGN.md` already exists, the skill reads it and returns immediately — do not regenerate.
- Wait for the `✅ references/DESIGN.md` return signal before proceeding.

All subsequent BUILD task Briefs must reference token names from `references/DESIGN.md` (e.g., `{colors.primary}`, `{typography.body}`) rather than quoting hardcoded hex or px values.

### Step 1.6: Extract Components (with PROTOTYPE_DIR only; ui_stack = none only)

If `ui_stack ≠ none`: skip this step and proceed to Step 2.

Invoke the `extract-components` skill:

```
Follow .agents/skills/extract-components/SKILL.md with:
  --dir <PROTOTYPE_DIR>
  --out-ref references/COMPONENTS.md
  --out-html docs/design-system/components.html
  --out-src src/components/shared/
```

- If `references/COMPONENTS.md` already exists, the skill returns immediately — do not regenerate.
- Wait for `✅ references/COMPONENTS.md` or `⏭ extract-components skipped` or `⚠️ extract-components: no reusable component patterns found` signal before proceeding.

When `ui_stack = none` and components were found: all subsequent BUILD task Briefs must reference `src/components/shared/` components and must not re-implement them.

### Step 2: Read all specs

Read all `F-xxx.md` under `SPEC_DIR/features/` and all `UC-xxx.md` under `SPEC_DIR/use-cases/`.

### Step 3: Produce `comparison/STUDY_NOTES.md`

**This file is the gate to Phase 1.5. Do not begin planning until it is written.**

---

#### With PROTOTYPE_DIR — full STUDY_NOTES

##### Section A — File Inventory

| File | Role |
|------|------|
| src/app/components/Dashboard.tsx | App shell: Layout structure, Header, Sider, routing |
| ... | ... |

No file may be omitted. A missing file = Phase 1 incomplete.

##### Section B — Structural Decisions (5 Categories)

For each category, quote the **exact line(s)** from the prototype.
Do not paraphrase. Do not infer. Copy the actual code.

| Category | Question | Reference code (file:line) |
|----------|----------|---------------------------|
| **App shell** | How is the overall layout structured? (sidebar position, header placement, content area) | _(quote actual code)_ |
| **Navigation** | Flat or nested menu? Light or dark theme? How many top-level groups? | _(quote actual code)_ |
| **Brand / theme** | What is the primary color? Background color of sidebar/header/page? | _(quote actual code)_ |
| **Page header pattern** | How is the page title and action buttons arranged relative to each other? | _(quote actual code)_ |
| **Data display pattern** | How are lists / tables / detail cards structured? Any common wrapper or padding? | _(quote actual code)_ |

All 5 rows must be filled with real code quotes. Rows with _(quote actual code)_ still in them = Phase 1 incomplete.

##### Section C — Data Entity Inventory

| Store 檔案 | 實體型別 | Mock 資料筆數 | Port 狀態 | 目標路徑 |
|-----------|---------|------------|---------|---------|
| `userStore.ts` | `UserRecord` | 8 筆 | ✓ 已 port | `src/types/user.ts` + `src/lib/mocks/users.ts` |

任何 ✗ 項目 = Phase 1 incomplete，Phase 1.5 不可開始。

##### Section D — Spec 需求分類

| Spec 條目 | 類型 | 處理方式 |
|----------|------|---------|

分類規則：
- **Visual**（與 prototype 視覺結構衝突）→ 跟 prototype
- **Behavioral**（prototype 看不出來的驗證 / 邏輯規則）→ 跟 spec
- **Additive**（spec 要求新增 prototype 沒有的功能欄位）→ 跟 spec

---

#### Spec-only mode — simplified STUDY_NOTES

When `PROTOTYPE_DIR=none`, produce only the following two sections:

##### Section A — Feature → Screen Mapping

Derived from reading all `F-xxx.md` under `SPEC_DIR/features/`:

| Feature | Screens | Components to produce |
|---------|---------|----------------------|
| F-001 [title] | [screen names] | [component files] |
| ... | | |

##### Section B — Spec 需求分類

| Spec 條目 | 類型 | 來源 | 處理方式 |
|----------|------|------|---------|

分類規則（spec-only mode — no Visual type without a prototype）：
- **Behavioral**（驗證 / 邏輯規則 / 狀態轉換）→ 按 spec 實作
- **Additive**（需新增的功能欄位 / 元件，spec 有但未詳細定義 UI）→ 按 spec 實作，UI 自行決定並記錄

---

### Step 4: Map features

**With PROTOTYPE_DIR**: Map each feature → prototype screens → components to produce.

**Spec-only mode**: Map each feature → screens → components to produce (from specs only).

Flag any ambiguities or gaps.

**If a gap or conflict cannot be self-resolved → stop and ask the user before Phase 1.5.**

### Phase 1 Gate

**With PROTOTYPE_DIR:**
- [ ] `references/DESIGN.md` 已產出（Step 1.5 回傳 ✅ 訊號）
- [ ] `ui_stack = none` 時：`references/COMPONENTS.md` 已產出（或 skip / no-match 訊號已收到）
- [ ] `ui_stack = none` 時：`src/components/shared/` 下有 .tsx 檔案（零 component 找到時例外）
- [ ] Section A：所有 prototype source 檔案均已列出（無遺漏）
- [ ] Section A：`src/imports/` 中每個檔案已查 import chain，標記 **active render** 或 **reference only**
- [ ] Section B：5 個 Structural Decisions 列有**實際程式碼引用**（非 paraphrase，無空白列）；Brand/theme 欄位使用 `{colors.xxx}` token 語法
- [ ] Section C：所有 store / mock 資料標記 ✓ ported（無 ✗ 項目）
- [ ] Section D：所有 spec 衝突條目已分類（Visual / Behavioral / Additive）

**Gate 驗證指令（prototype 模式，必須執行並貼出輸出結果）：**

```bash
# 1. 確認 Section C 所有 ✓ ported 項目的目標路徑實際存在
ls src/types/*.ts src/lib/mocks/*.ts 2>&1

# 2. 確認 STUDY_NOTES.md 中沒有未填的佔位符（任何輸出 = Section B 未完成）
grep -n "quote actual code" comparison/STUDY_NOTES.md

# 3. ui_stack = none 時：確認 shared components 存在
ls src/components/shared/*.tsx 2>&1
```

指令 2 必須無輸出。任何不符 → 修正後再執行。

**Spec-only mode:**
- [ ] Section A（Feature → Screen Mapping）已完整列出所有 F-xxx.md 中的 screens
- [ ] Section B：所有 spec 條目已分類（Behavioral / Additive）
- [ ] `comparison/STUDY_NOTES.md` 已寫出

---

## Phase 1.5 — Task Planning

> **這是整個 workflow 中唯一一次讀取規則全文。**
> 規劃階段將相關規則蒸餾進各 task 檔案，後續 Build subagents 不再重讀整份規則。

**進入 Phase 1.5 的第一件事：**
1. 從 `package.json` 確認 `framework_profile` 和 `ui_stack`。
2. 讀取 `.agents/skills/frontend-workflow/FRONTEND_RULE_COMMON.md` 全文（通用規則）。
3. 讀取 `.agents/skills/<framework_profile>/SKILL.md`（profile skill）。

> Token 節省指示：FRONTEND_RULE_COMMON.md 讀完後，RULE.md 只讀與本次畫面相關的 sections。antd 專案跳過 Tailwind 段落，反之亦然。`ui_stack = none` 專案跳過所有 UI library 段落（antd / shadcn / Element Plus / Headless UI 相關內容），只讀 §5（設計系統 — CSS Module 子節）與通用架構規則。BUILD task Brief 的元件選型指示改為「直接 port prototype CSS，用 CSS Module 包裝，不替換成第三方元件」。若 `references/COMPONENTS.md` 存在，BUILD task Brief 須額外列出可用的 shared component 清單，並加入指示：「優先 import `src/components/shared/`，不得重複實作已有的 shared component」。

### Step 1: Estimate screen complexity

Read each `F-xxx.md` spec. For every screen identified in the STUDY_NOTES §A + feature mapping, assign complexity:

| Complexity | Criteria |
|-----------|---------|
| **L** | Table with >5 columns + modal + form，或 multi-step workflow，或有複雜互動狀態 |
| **M** | 標準 list + detail，或 form 無複雜互動 |
| **S** | Display-only、simple card、或 single-action page |

### Step 2: Group screens into BUILD tasks

- **BUILD-001**: Always AppShell (AppSider, AppHeader, Layout shell) — complexity M, always first.
  BUILD-001 **must** include explicit route fallbacks — no placeholder page content allowed:
  - `src/app/page.tsx` → `redirect('/login')` (root always redirects to auth)
  - `src/app/dashboard/page.tsx` → `redirect('/dashboard/[first menu route]')` (derive from MENU constant)
  - Both redirects use Next.js `import { redirect } from 'next/navigation'` (Server Component, no 'use client')
  - If a `HomeScreen`, `DashboardHomeScreen`, or any other filler component was scaffolded by a prior tool, delete it.
- **BUILD-002+**: Group by complexity:
  - L → 1 screen per task
  - M → 2 screens per task
  - S → 3 screens per task
- **BUILD-N (last)**: Refactor Pass (FRONTEND_RULE §8) — no screens, complexity fixed

Review tasks (always after all BUILD tasks, start as `pending`):
- For every BUILD task (BUILD-001 through BUILD-N), create a paired **REVIEW-N** task with the same number.
  - REVIEW-001 → Review: AppShell
  - REVIEW-002 → Review: [BUILD-002 title]
  - …
  - REVIEW-N → Review: Refactor Pass
- There is no longer a fixed REVIEW-001=Static / REVIEW-002=Functional / REVIEW-003=Visual split. Each REVIEW-N covers all applicable sections (§1/§2/§3) for its paired BUILD-N, as determined by BUILD-N's Coverage section at review time.
- **Spec-only mode**: same 1:1 pairing; §2 (Visual) is skipped at execution time since Mode=spec-only.

### Step 3: Scan for potential blockers

**Before writing task files**, scan each BUILD task's screens for decisions a subagent cannot self-resolve:

- Spec vs prototype conflicts not resolved by Visual/Behavioral/Additive classification *(prototype mode only)*
- Active render components where port vs deviation is ambiguous *(prototype mode only)*
- Complex interactions present in prototype but absent or unclear in spec *(prototype mode only)*
- Any screen where the correct implementation has more than one reasonable answer
- **Additive components with no prototype/spec equivalent**: for each new component (Modal, Drawer, custom TreeSelect, etc.) not sufficiently specified, the following must be pre-specified in Pre-resolved Decisions or the `**New component API**` block — if any are missing, treat as a blocker: z-index, backdrop color+opacity, panel dimensions, transition. Do not let the subagent invent these.

Collect all blockers as a numbered list. These are presented to the user in Step 7 (review pause) and resolved before any subagent is spawned.

### Step 4: Write BUILD task files

Create `requirements/tasks/` directory. For each BUILD task, write
`requirements/tasks/BUILD-XXX-<slug>.md` — see the Task File Naming rule below.

### Task File Naming (applies to newly created task files)

New task files carry a semantic slug after the number:

```
BUILD-081-order-cancel-reason-options.md
REVIEW-081-order-cancel-reason-options.md
```

**Slug rules:**
- kebab-case, derived from the task title, **≤ 5 words / 40 chars**
- ASCII only — transliterate or summarise Chinese titles into English keywords
- A REVIEW task reuses its paired BUILD task's slug verbatim

**Why:** `BUILD-058.md` tells you nothing without opening it. With 150+ task files, `ls` and
`grep` on filenames become the fastest way to find "which task covered X" — especially since
`_index.md` only lists *unfinished* tasks (completed rows live in `_index-archive.md`).

**Existing numeric-only files are intentionally left alone.** Renaming them would break
references in `_index-archive.md`, other task files, PM issues, and already-merged PR bodies,
for no benefit — they are all `done` and rarely reopened. Mixed naming is expected and
self-healing: every new file uses a slug, old ones stay as they are. Never rename an existing
task file just for consistency.

Globs (`requirements/tasks/BUILD-*.md`) work across both conventions, so all lookup logic in
this skill is unaffected.

> Elsewhere in this document `BUILD-XXX.md` / `REVIEW-XXX.md` is shorthand for "that task's
> file", whichever naming convention it uses. Resolve it with a glob, not a literal path.

**Withdrawn tasks:** if a task is abandoned before completion, do not delete its file or
silently drop it from the index. Create `requirements/tasks/_withdrawn.md` (append-only) and
record the Task ID, the reason/source, the replacement task if any, and the PR that withdrew
it. A withdrawn ID is never reused and never returns to `_index.md`. This file does not exist
until the first withdrawal — create it then, not preemptively.

---

#### With PROTOTYPE_DIR — MANDATORY pre-write step for every BUILD task that contains screens:

**The Brief does not carry the screen's markup.** The prototype source file **is** the structure —
the BUILD subagent reads it directly (Phase 2). The Brief carries only a **pointer** to the exact
prototype location, plus a **Deviations** list: everything the subagent would get *wrong* by
copying the prototype literally. Structure lives once, in the prototype; the Brief supplies the delta.

This removes the planner's transcription step entirely — and with it the "planner mis-copies a
column, subagent faithfully builds the wrong thing" failure mode. There is no code to mis-copy.

**Procedure (per screen):**
1. Locate the prototype page component in `PROTOTYPE_DIR` and Read it, to confirm the exact file
   and line range that own this screen, and to discover what must deviate. (You read it to *plan*;
   you do **not** transcribe it into the Brief.)
2. Write a `**Page component structure**` block containing exactly two things:
   - **Structure pointer** — `port from PROTOTYPE_DIR/[file]:[lines] verbatim`: keep every layout
     container, every `className`, every `<th>`, and every child component tag. (Also add that
     file to `Meta.Inputs` so the subagent knows to open it.)
   - **Deviations** — a bullet per intended divergence from the prototype. This is the *only*
     load-bearing content: anything not listed here, the subagent takes from the prototype as-is.

**What counts as a Deviation (list every one — completeness is the whole job):**
- A column/field the spec adds, drops, or changes vs the prototype (e.g. 2-state pill → 3-state; drop the AI tab).
- An element the prototype renders that this feature must NOT port (out-of-scope panels, AI search, etc.).
- A structural swap the target stack forces (e.g. prototype `AppPageHead` component → inline `.page-head` per DashboardScreen).
- Anything where following the prototype literally would violate a project rule (SVG `<use>` → lucide-react icon; hardcoded hex → token) **only when it changes what the subagent would otherwise produce**. Global rules already in `Relevant Rules` need not be repeated per screen; list the screen-specific ones.

Behavioral logic, data bindings, and decorative styling are **not** deviations — they come from the
prototype + spec (Key patterns / Spec classification / DESIGN.md), not from a structure description.

**Self-verification (mandatory before moving to the next task):**
- The pointer resolves: the named file exists and the line range actually contains this screen's component (open it and confirm).
- Deviations are exhaustive: re-read the prototype and, for every place it diverges from the spec/target for this screen, confirm there is a matching Deviation bullet. A missing Deviation = the subagent will faithfully reproduce the prototype and be wrong.
- No structural prose: do **not** describe the layout / class names / column set in words. If it's in the prototype, point to it; if it diverges, list it as a Deviation. Prose re-description is the synthesis failure this format exists to avoid.

**Worked example** — brands list screen:
```markdown
**Page component structure**: port from `references/…/app/pages/brands/index.vue:1-86` verbatim
(keep every layout container / className / `<th>` / child component).
**Deviations:**
- 連線狀態 pill：prototype 只有 2 態（success/error），本 task 改 3 態
  (connected / auth_error / unconnected)，用 `connectionStatus`（D-061）。
- icon：prototype `<use href="#i-…">` → lucide-react（不搬 SVG path，§1.1）。
- eyebrow：prototype 有，對齊 DashboardScreen 省略。
```
No markup, no column list — the subagent opens `index.vue`, ports the `.tbl` + `<th>品牌</th><th>連線狀態</th>`
+ `clickable-row` etc. exactly, then applies the three deviations. Same result, zero code in the Brief.

**Additive screens with NO prototype** (e.g. a page designed purely from spec — `grep` finds no
matching prototype page): there is nothing to point to. These are the one exception — specify the
structure in the Brief, as a `**New component API**` interface plus a short designed-structure note.
Mark the block `**No prototype — additive, designed from spec.**` so it's clearly the exception, not the rule.

**Coverage section (fill during Phase 1.5 planning):**
After writing the Brief, fill in `## Coverage` for this BUILD task:
- **Features**: list the F-xxx IDs whose screens appear in this task
- **Use Cases**: list all UC-xxx IDs linked to those features (read UC files if needed). Set `—` for AppShell and Refactor Pass.
- **Screens**: list the screen component names this task implements. Set `—` for Refactor Pass.
- **Files**: leave a `[filled by BUILD subagent]` placeholder — the BUILD subagent fills this list when marking the task done.

> **Why**: the prototype already contains every screen's exact layout, classNames, and columns. Transcribing that into the Brief only creates a second copy that can drift or be mis-copied. Instead the Brief points at the prototype and lists deviations; the subagent reads the prototype (Phase 2) as the structure source of truth and applies the deltas. STUDY_NOTES §B still records shared cross-screen patterns; the pointer + Deviations records the per-screen specifics. Structure is looked up from one source; the Brief owns only what diverges.

---

#### BUILD task template (with PROTOTYPE_DIR)

```markdown
# BUILD-XXX: [Title]

## Meta
- Status: `ready`
- Complexity: S | M | L
- Screens: [list of screen names]
- Inputs: [exact file paths this task needs — e.g. src/types/user.ts]

## Brief
[Distilled from STUDY_NOTES — include only patterns, code quotes, and values
relevant to these screens. Do not include info for other screens.]

**Page component structure**: port from `PROTOTYPE_DIR/[file]:[lines]` verbatim (keep every layout
container / className / `<th>` / child component). Add `[file]` to Meta.Inputs.
**Deviations:**
- [one bullet per intended divergence from the prototype — added/dropped/changed column, dropped
  element, forced structural swap, screen-specific rule. Anything not listed = taken from prototype as-is.]
- [_"None — port as-is"_ if the screen matches the prototype exactly.]

_(No prototype for this screen? Replace the two lines above with `**No prototype — additive, designed
from spec.**` and specify structure via New component API + a short designed-structure note.)_

Key patterns:
- Layout: [shared patterns from STUDY_NOTES §B relevant to these screens] + any screen-specific overrides recorded as Deviations above
- Brand: [use token syntax from references/DESIGN.md — e.g. primary `{colors.primary}`, surface `{colors.canvas}`, body type `{typography.body}`; do NOT hardcode hex/px values]
- Active render components: [if any, with handling decision — port vs deviation]
- Spec classification: [from STUDY_NOTES §D — Visual/Behavioral/Additive items for this feature]

**New component API** (fill for every Additive component not present in the prototype — e.g. Modal, Drawer, custom TreeSelect, custom TagInput):
```typescript
// One interface per new component. Exact prop names fix the public API —
// all downstream tasks that consume this component must use these names.
// Mark optional props with ? explicitly. No implicit any.
interface [ComponentName]Props {
  // prop: type
}
```
_Omit this block entirely if this task has no Additive components._

**State shape** (fill for every new Zustand store introduced in this task):
```typescript
// Exact field names and action signatures. Downstream tasks import this store
// by name — changing names later causes ripple edits across all screens.
interface [StoreName]State {
  // fields
  // actions — include full function signature (params + return type)
}
```
_Omit this block entirely if this task introduces no new store._

## Relevant Rules
[Extracted from FRONTEND_RULE — copy the actual rule text for sections that apply
to these screens. Do not just write section pointers like "see §3".]

## Pre-resolved Decisions
[Empty if no blockers for this task. Filled during user review before execution starts.]

If this task has Additive components, **these CSS values must be filled** (leaving them blank = agent invents them differently each run):
- Overlay z-index (e.g. `1000`)
- Backdrop background (e.g. `rgba(0,0,0,0.45)`)
- Panel width/height (e.g. `480px`, `520px max-width`)
- Transition (e.g. `transform 0.25s ease`)

| 問題 | 決策 |
|------|------|

## Acceptance Criteria
- R1: [screen] visual structure matches prototype patterns quoted in Brief
- R2: [behavioral criterion from spec, referencing F-xxx]
- ...
- RN: 🌐 Browser smoke test: `npm run dev` → 實際操作 golden path（完整流程從頁面進入到功能完成），確認功能可用且視覺結構與 prototype 一致

## Implementation Checklist
- [ ] 確認 comparison/DEVIATION_REPORT.md 存在
- [ ] (AppShell only) `src/app/page.tsx` → `redirect('/login')` — no HomeScreen, no placeholder content
- [ ] (AppShell only) `src/app/dashboard/page.tsx` → `redirect('/dashboard/[first menu route]')` — no DashboardHomeScreen
- [ ] [screen name]: TypeScript types in src/types/
- [ ] [screen name]: mock data in src/lib/mocks/
- [ ] [screen name]: component implemented
- [ ] [screen name]: Per-Screen DoD 通過
  - [ ] 對照 STUDY_NOTES §B 程式碼引用，核對 layout / spacing / 色彩 token 一致
  - [ ] active render 元件處理方式已確認（port 或 DEVIATION 記錄）
  - [ ] deviation 已記錄（或確認無 deviation）
- [ ] [repeat per screen]
- [ ] 🌐 **Browser smoke test**: `npm run dev` → 實際操作各畫面 golden path
  - [ ] 每個畫面都在瀏覽器中打開並進行基本操作（點擊、表單提交等）
  - [ ] 確認視覺結構與 prototype 一致（無多餘或遺漏的元素）
  - [ ] 若發現視覺/功能偏差，立即修改並重新測試
- [ ] Coverage.Files 已填寫（列出所有新建或修改的 .tsx/.ts 檔案，對應 Implementation Checklist 中的 component / type / mock / util 項目）
- [ ] npx tsc --noEmit 無錯誤
- [ ] BUILD-XXX.md Status → done，Execution Log 填寫
- [ ] _index.md 更新（mark done，advance ▶ Next Task；若為最後 BUILD task → 將所有 REVIEW tasks 改為 ready）
- [ ] **_index.md hygiene gate**（見 Index Hygiene 節）：
  - [ ] `## ▶ Next Task` 只有 1 筆 `▶`（+ 至多 1 筆 `▷`）——舊條目已移入 `_index-archive.md`，不是留在原地
  - [ ] `## Task Queue` 沒有任何 `done` 列——本次轉 done 的列已移入 `_index-archive.md`
  - [ ] 新增/修改的 Task Queue 列，Title 欄 ≤ 80 字元（細節寫在 BUILD-xxx.md，不塞進表格 cell）

## Execution Log

## Coverage
- Features: [F-xxx — derived from spec mapping in Phase 1.5]
- Use Cases: [UC-xxx list — `—` if this task has no UC flows]
- Screens: [screen names — `—` if this task has no screens (e.g. Refactor Pass)]
- Files: [filled by BUILD subagent when marking done — list every .tsx/.ts created or modified]
```

---

#### BUILD task template (spec-only mode)

```markdown
# BUILD-XXX: [Title]

## Meta
- Status: `ready`
- Complexity: S | M | L
- Screens: [list of screen names]
- Inputs: [exact file paths this task needs — e.g. src/types/user.ts]
- Mode: spec-only

## Brief
[Derived from spec F-xxx.md and UC-xxx.md — include requirements, behavioral rules,
data fields, and any UI/UX decisions relevant to these screens.]

Key patterns:
- Screens: [from STUDY_NOTES §A feature mapping]
- Behavioral rules: [from UC-xxx.md relevant to these screens — quote actual spec text]
- Data: [types and mock data required]
- Spec classification: [from STUDY_NOTES §B — Behavioral/Additive items for this feature]

**New component API** (fill for every Additive component not sufficiently specified in spec):
```typescript
interface [ComponentName]Props {
  // prop: type
}
```
_Omit this block entirely if this task has no Additive components._

**State shape** (fill for every new Zustand store introduced in this task):
```typescript
interface [StoreName]State {
  // fields
  // actions — include full function signature (params + return type)
}
```
_Omit this block entirely if this task introduces no new store._

## Relevant Rules
[Extracted from FRONTEND_RULE — copy the actual rule text for sections that apply
to these screens. Do not just write section pointers like "see §3".]

## Pre-resolved Decisions
[Empty if no blockers for this task. Filled during user review before execution starts.]

If this task has Additive components, **these CSS values must be filled**:
- Overlay z-index (e.g. `1000`)
- Backdrop background (e.g. `rgba(0,0,0,0.45)`)
- Panel width/height (e.g. `480px`, `520px max-width`)
- Transition (e.g. `transform 0.25s ease`)

| 問題 | 決策 |
|------|------|

## Acceptance Criteria
- R1: [behavioral criterion from spec, referencing F-xxx / UC-xxx]
- ...
- RN: 🌐 Browser smoke test: `npm run dev` → 實際操作 golden path（完整流程從頁面進入到功能完成），確認功能正常

## Implementation Checklist
- [ ] (AppShell only) `src/app/page.tsx` → `redirect('/login')` — no HomeScreen, no placeholder content
- [ ] (AppShell only) `src/app/dashboard/page.tsx` → `redirect('/dashboard/[first menu route]')` — no DashboardHomeScreen
- [ ] [screen name]: TypeScript types in src/types/
- [ ] [screen name]: mock data in src/lib/mocks/
- [ ] [screen name]: component implemented
- [ ] [screen name]: Per-Screen DoD 通過
  - [ ] 所有 Behavioral 規則已實作（對照 UC-xxx）
  - [ ] 所有 Additive 欄位已實作（對照 F-xxx）
- [ ] [repeat per screen]
- [ ] 🌐 **Browser smoke test**: `npm run dev` → 實際操作各畫面 golden path
  - [ ] 每個畫面都在瀏覽器中打開並進行基本操作（點擊、表單提交等）
  - [ ] 確認功能符合 spec 描述
- [ ] Coverage.Files 已填寫（列出所有新建或修改的 .tsx/.ts 檔案，對應 Implementation Checklist 中的 component / type / mock / util 項目）
- [ ] npx tsc --noEmit 無錯誤
- [ ] BUILD-XXX.md Status → done，Execution Log 填寫
- [ ] _index.md 更新（mark done，advance ▶ Next Task；若為最後 BUILD task → 將所有 REVIEW tasks 改為 ready）
- [ ] **_index.md hygiene gate**（見 Index Hygiene 節）：
  - [ ] `## ▶ Next Task` 只有 1 筆 `▶`（+ 至多 1 筆 `▷`）——舊條目已移入 `_index-archive.md`，不是留在原地
  - [ ] `## Task Queue` 沒有任何 `done` 列——本次轉 done 的列已移入 `_index-archive.md`
  - [ ] 新增/修改的 Task Queue 列，Title 欄 ≤ 80 字元（細節寫在 BUILD-xxx.md，不塞進表格 cell）

## Execution Log

## Coverage
- Features: [F-xxx — derived from spec mapping in Phase 1.5]
- Use Cases: [UC-xxx list — `—` if this task has no UC flows]
- Screens: [screen names — `—` if this task has no screens (e.g. Refactor Pass)]
- Files: [filled by BUILD subagent when marking done — list every .tsx/.ts created or modified]
```

> **Subagent 注意**：每完成一個 checklist 項目立即更新 checkbox。若因 BLOCKER 重新啟動，讀取 Pre-resolved Decisions，從第一個未勾項目繼續，勿重做已完成的 screen。

> **Brief** 和 **Relevant Rules** 必須含蒸餾後的實文，不可只寫 pointer。Subagent 讀此檔案不需查閱其他文件。

### Step 5: Write REVIEW task files

For each BUILD task (BUILD-001 through BUILD-N including Refactor Pass), create a paired REVIEW task file `requirements/tasks/REVIEW-XXX.md` where XXX matches the BUILD task number.

> ⚠️ Remove the old note about REVIEW-001 AC 強制規則 — AC is no longer hardcoded in REVIEW files; the review skill derives it from Coverage at runtime.

```markdown
# REVIEW-XXX: Review: [BUILD-XXX title]

## Meta
- Status: `pending`
- BUILD Task: BUILD-XXX
- Mode: §1 Static [+ §2 Visual if Coverage.Screens ≠ `—` AND prototype mode] [+ §3 Functional if Coverage.Use Cases ≠ `—`]
  _(Mode is determined at execution time by reading BUILD-XXX.md Coverage — do not hardcode section list here)_

## §1 Static Code Review
_pending_

## §2 Visual Comparison
_pending — skipped if Coverage.Screens is `—` or Mode = spec-only_

## §3 Functional Validation
_pending — skipped if Coverage.Use Cases is `—`_

## Execution Log
```

REVIEW tasks use `pending` until all BUILD tasks in the cycle are `done`. The last BUILD subagent promotes all REVIEW tasks in the cycle from `pending` → `ready`.

### Step 6: Write `requirements/tasks/_index.md`

```markdown
# Task Index

## Config
- PROTOTYPE_DIR: [path | none]
- SPEC_DIR: [path]
- REF_PORT: [port | N/A]
- OURS_PORT: [port]
- Mode: [prototype | spec-only]

## Covered Specs
[comma-separated list of all F-xxx IDs planned in this and prior cycles]

## ▶ Next Task
BUILD-001

## Task Queue

| Task ID    | Title                    | Complexity | Status  |
|------------|--------------------------|-----------|---------|
| BUILD-001  | AppShell                 | M         | ready   |
| BUILD-002  | [title]                  | M         | ready   |
| ...        |                          |           |         |
| BUILD-N    | Refactor Pass            | —         | ready   |
| REVIEW-001 | Review: AppShell         | —         | pending |
| REVIEW-002 | Review: [BUILD-002 title]| —         | pending |
| ...        |                          |           |         |
| REVIEW-N   | Review: Refactor Pass    | —         | pending |
```

**Title 欄 ≤ 80 字元。** 它是給人掃描用的標籤，不是規格摘要——範圍、修法、契約、deviation
一律寫在 `BUILD-xxx.md` 裡。超長 Title 會讓這張表從「一眼看完的清單」退化成必須逐列閱讀的
長文（實測曾出現單列 1,244 bytes）。

`## ▶ Next Task` 恆為 1 筆，推進時把舊的移入 `_index-archive.md` — 見 Index Hygiene 節。

### Step 7: Present plan + blockers to user (mandatory pause)

Display the Task Queue table and all blockers from Step 3. Output:

```
Task Planning 完成，已生成 N 個 tasks。

[Task Queue table]

⚠️ 執行前需解決的問題（M 個）：

1. [BUILD-XXX] [問題描述]
   選項 A：...
   選項 B：...

2. ...

請確認計畫（可要求調整，例如「把 BUILD-003 拆兩個」「合併 BUILD-004 和 005」），
並回覆每個問題的決策。確認後立即開始執行。
```

Wait for user confirmation and blocker resolutions. Apply any requested splits/merges. Write each resolution into the corresponding BUILD task's `Pre-resolved Decisions` table. Then proceed to Phase 2.

If no blockers: present table only, wait for "ok" or adjustments.

### Phase 1.5 Gate

- [ ] `requirements/tasks/_index.md` 已建立，Task Queue 完整列出所有 tasks
- [ ] 每個 BUILD task 的 `Relevant Rules` 含 FRONTEND_RULE 相關段落實文（非 pointer）
- [ ] 每個 BUILD task 的 `Pre-resolved Decisions` 已填入（或確認無 blockers）
- [ ] 每個含 Additive component 的 BUILD task 的 Brief 含 **New component API** 區塊（TypeScript interface，非文字描述；Omit 行除外）
- [ ] 每個引入新 store 的 BUILD task 的 Brief 含 **State shape** 區塊（TypeScript interface，含 action 完整 signature；Omit 行除外）
- [ ] 每個含 Additive component 的 BUILD task 的 Pre-resolved Decisions 已填入 z-index / backdrop / dimensions / transition
- [ ] User 已確認計畫

**With PROTOTYPE_DIR — 額外 gate 項目：**
- [ ] 每個 BUILD task 的 `Brief` 含 STUDY_NOTES §B 的相關程式碼引用（非 paraphrase）
- [ ] 每個有畫面的 BUILD task 的 `Brief` 含 **Page component structure** 區塊：一個指向 prototype 的 **Structure pointer**（`port from <file>:<lines> verbatim`）+ **Deviations** 清單。**Brief 內不得含 markup / 結構散文描述**（結構由 subagent 讀 prototype 取得）。無對應 prototype 的 additive 畫面例外，標 `**No prototype — additive…**`
- [ ] 每個 Structure pointer 指向的 prototype 檔案已列入該 task 的 `Meta.Inputs`
- [ ] 所有 REVIEW tasks（REVIEW-001 through REVIEW-N）已建立，Status = `pending`

**Gate 補充驗證（prototype 模式，針對 Page component structure）：**
```bash
# 1. 確認每個有畫面的 BUILD task Brief 都有 Page component structure 區塊
grep -l "Page component structure" requirements/tasks/BUILD-*.md 2>&1
# 輸出的檔案數應等於有畫面的 BUILD task 數（不含 Refactor Pass）
```

```bash
# 2. 確認 task 狀態
ls requirements/tasks/ 2>&1
grep "Status:" requirements/tasks/BUILD-001.md 2>&1
```

**逐一抽查（prototype 模式，必須執行，所有有畫面的 BUILD task，不可跳過任何一個）：**

對每個有畫面的 BUILD task 執行：
1. **Pointer 解析**：讀 Structure pointer 指向的 `<file>:<lines>`，開檔確認該行段確實含此畫面的 component（非空、非錯檔）。
2. **Deviations 完整性**：對照 STUDY_NOTES §D 該畫面的 spec 分類，逐項確認「凡是與 prototype 有出入的（新增/刪除/改欄、drop 元素、結構替換、畫面級規則）」在 Deviations 都有對應 bullet。缺一項 → subagent 會忠實照抄 prototype 而做錯 → **必須補齊後才能進入 Phase 2**。
3. **無結構散文**：Brief 不得用文字重述 layout / className / 欄位集（那是合成失敗模式）；結構只能靠 pointer。若發現散文結構描述 → 改回 pointer + Deviations。

> 重點從「驗 Brief 內的 className 是否真存在」轉為「驗 pointer 指對地方 + Deviations 是否列全」。因為 Brief 不再轉抄結構，就沒有「抄錯 className/欄位」的風險；新的風險是「pointer 指錯檔」或「漏列一個 deviation」，故上面兩項為抽查重點。

```bash
# 抽查範例（依實際 task 調整）：pointer 指向的檔案是否存在且含該畫面
sed -n '1,86p' references/asgard-freyr-web-proto/app/pages/brands/index.vue | head -5
grep -n "<th>" references/asgard-freyr-web-proto/app/pages/brands/index.vue   # 對照 Deviations 有無改欄
```

> **判準**：pointer 指向的檔案/行段不含該畫面，或有一項 prototype 與 spec 的出入未列入 Deviations → Phase 1.5 未完成，修正後才能繼續。

**Spec-only mode gate：**
- [ ] 所有 REVIEW tasks（REVIEW-001 through REVIEW-N）已建立，Status = `pending`
- [ ] 每個有畫面的 BUILD task 的 `Brief` 含實際 spec 文字引用（非純描述）

---

## Phase 2 — Build Orchestration

> **主 Agent 是 orchestrator，不直接執行任何 BUILD 任務。** 每個 task 交給獨立 subagent，主 Agent 只追蹤狀態、處理 BLOCKER、推進 _index.md。

### Orchestration Loop

For each BUILD task in `_index.md` queue (in order):

**Step 1: Spawn subagent**

Invoke the Agent tool with this prompt:

**With PROTOTYPE_DIR:**

```
Execute frontend build task BUILD-XXX.

Read requirements/tasks/BUILD-XXX.md for the Brief, Relevant Rules, Pre-resolved Decisions, and Implementation Checklist.

**BEFORE implementing any screen — read the structure source (mandatory):**
The `Page component structure` block is a **pointer + Deviations**, not markup. The prototype file
is the structure source of truth; you must open it.
1. Read the prototype file+lines named in the Structure pointer (also listed in Meta.Inputs).
   Find the exact page component for each screen.
2. Port the prototype structure verbatim: every layout container, `className`, `<th>`, and child
   component, exactly as written — do NOT re-invent or "improve" it.
3. Apply the Brief's **Deviations** list on top of that structure — each bullet overrides the prototype
   (an added/changed column, a dropped element, a forced structural swap, a screen-specific rule).
   Anything not listed as a Deviation is taken from the prototype unchanged.
4. Return a BLOCKER only if the pointer is unusable — the named file/lines do not contain the screen,
   or a Deviation is self-contradictory / impossible against the actual prototype:
   `BLOCKER: [screen name]: pointer/deviation problem — [what's wrong]`
   Do NOT guess a different prototype file; the Brief must be corrected first.
   (For **No prototype — additive** screens there is no pointer: build from the Brief's New component
   API + designed-structure note instead.)

Structure = prototype (looked up). Deviations = the Brief's delta. Leaf content, handlers, and exact
styling all come from the prototype source too.

Instructions:
- Work through the Implementation Checklist in order
- Check off each item in BUILD-XXX.md as you complete it
- If restarting after a BLOCKER: read checklist first, skip checked items, resume from first unchecked
- Consult Pre-resolved Decisions for any known ambiguities before acting
- Run `npx tsc --noEmit` before marking done
- Create comparison/DEVIATION_REPORT.md if it does not exist

Blocking rule:
- If you encounter a decision requiring human judgment NOT covered by Pre-resolved Decisions,
  immediately return: BLOCKER: [clear description + two best options]
  Do NOT guess. Do NOT proceed past the blocker.

On completion return: DONE BUILD-XXX: [one-line summary — screens implemented, deviations if any, TS status]
```

**Spec-only mode:**

```
Execute frontend build task BUILD-XXX (spec-only mode — no prototype reference).

Read requirements/tasks/BUILD-XXX.md for the Brief, Relevant Rules, Pre-resolved Decisions, and Implementation Checklist.

Instructions:
- Implement from spec requirements in the Brief (F-xxx.md / UC-xxx.md content)
- Work through the Implementation Checklist in order
- Check off each item in BUILD-XXX.md as you complete it
- If restarting after a BLOCKER: read checklist first, skip checked items, resume from first unchecked
- Consult Pre-resolved Decisions for any known ambiguities before acting
- Run `npx tsc --noEmit` before marking done

Blocking rule:
- If you encounter a decision requiring human judgment NOT covered by Pre-resolved Decisions,
  immediately return: BLOCKER: [clear description + two best options]
  Do NOT guess. Do NOT proceed past the blocker.

On completion return: DONE BUILD-XXX: [one-line summary — screens implemented, TS status]
```

**Step 2: On `DONE` response**

- Update `requirements/tasks/BUILD-XXX.md`: Status `ready` → `done`, Execution Log
- Update `requirements/tasks/_index.md` per **Index Hygiene**: move the done row and the
  superseded `▶` entry into `_index-archive.md`, then write the new `▶ Next Task`.
  Never leave a `done` row in Task Queue or stack a new `▶` above the old one
- If this was the **last BUILD task** in the current cycle:
  - Update all paired REVIEW tasks (REVIEW-001 through REVIEW-N for this cycle) from `pending` → `ready`
  - This applies to both prototype and spec-only mode — section applicability is determined at execution time by the review skill, not at planning time.
- Proceed to next task in queue

**Step 3: On `BLOCKER` response**

- Output to user: `⛔ BUILD-XXX blocked: [description]`
- Wait for user resolution
- Append resolution to `requirements/tasks/BUILD-XXX.md` Pre-resolved Decisions table
- Spawn a new subagent for the same BUILD-XXX (checklist records progress; subagent resumes from first unchecked item)

### Phase 2 Gate（所有 BUILD tasks done 後）

- [ ] `requirements/tasks/_index.md` 中所有 BUILD tasks status = `done`
- [ ] 所有 REVIEW tasks（本 cycle 的 REVIEW-001 through REVIEW-N）status = `ready`

```bash
grep "BUILD-" requirements/tasks/_index.md | grep -v "| done"
grep "REVIEW-" requirements/tasks/_index.md
```

---

## Phase 3 — Review Orchestration

> **同樣以 subagent 執行每個 REVIEW task。** 主 Agent 按順序 spawn，收到結果後推進 _index.md；有 ❌ 則進入 Phase 4 再繼續。

### Orchestration Loop

Run all REVIEW tasks in `_index.md` that have status `ready`, in Task Queue order (REVIEW-001 → REVIEW-002 → … → REVIEW-N).

Section applicability (§1/§2/§3) is determined at execution time by the review skill reading the paired BUILD task's Coverage — no special handling needed here for prototype vs spec-only mode.

**Spawn subagent** with this prompt:

```
Execute frontend review task REVIEW-XXX.

Follow .agents/skills/review/SKILL.md.

Paired BUILD task: BUILD-XXX.
Read BUILD-XXX.md Coverage section for scope.
Write §1/§2/§3 results to REVIEW-XXX.md (skip sections not applicable per Coverage).

If blocked: return BLOCKER: [description]
On completion: return DONE REVIEW-XXX: [summary — sections run, pass/fail counts, any ❌ items needing Phase 4]
```

**On `DONE`**: update REVIEW-XXX.md status → done, update _index.md.
If findings include ❌ items:
- **§1 Static violations**: proceed to Phase 4 for auto-fix, then continue to next REVIEW task
- **§3 Functional failures**: 🔄 Surface to user as "BLOCKER from REVIEW-XXX §3" → User decides whether to reopen BUILD-XXX for fix + re-test, or mark as acceptable deviation in DEVIATION_REPORT.md
- **§2 Visual diff > 10%**: proceed to Phase 4 pixel-diff fix loop (max 3 rounds), then mark done

**On `BLOCKER`**: surface to user, get resolution, spawn new subagent.

### Output Summary

After all REVIEW tasks in the current cycle are `done`, write or update `comparison/REPORT.md`.

The report should summarise results per BUILD task (not per review type), e.g.:

| BUILD Task | §1 Static | §2 Visual | §3 Functional |
|------------|-----------|-----------|---------------|
| BUILD-001 AppShell | ✅ 26/26 | ✅ 2% diff | N/A |
| BUILD-002 Login | ✅ 26/26 | ✅ 1% diff | ✅ 12/12 |
| BUILD-003 Dashboard | ✅ 26/26 | ⚠️ 8% diff | ✅ 7/7 |
| BUILD-004 Refactor | ✅ 26/26 | N/A | N/A |

---

## Phase 4 — Fix & Re-validate

For each ❌ found in Phase 3, apply the matching fix strategy:

| Failure type | Fix strategy |
|-------------|-------------|
| §1 Static violations | Fix, re-run §1 checks |
| §3 Functional failures | Fix per UC flow; reopen BUILD-XXX if needed |
| §2 Visual diff > 10% (prototype mode only) | Auto-fix loop, max 3 rounds per page |

**Auto-fix loop (pixel diff, prototype mode only):**
1. Analyze diff screenshot → identify cause
2. **DOM & CSS Analysis**: Before modifying code, analyze the expected vs. actual DOM structure or CSS properties to find the root cause. **Blindly adjusting margin/padding without structural analysis is strictly forbidden.**
3. Fix relevant code
4. Retake ours screenshot (ref stays unchanged)
5. Recompare; update `comparison/REPORT.md`
6. Repeat until diff ≤ 10% or round 3 is reached

After round 3 still > 10% → mark `⚠️ 自動修正達上限，需人工介入` in REPORT.md and continue.

**If fix direction is unclear → stop and ask the user.**

Update the relevant REVIEW task file's Execution Log after fixing.

---

## Phase 5 — Cleanup

Kill dev servers:

```bash
lsof -i :<OURS_PORT> -P -n | awk 'NR>1 {print $2}' | xargs kill
# With PROTOTYPE_DIR only:
lsof -i :<REF_PORT>  -P -n | awk 'NR>1 {print $2}' | xargs kill
```

Output final acceptance summary. For each task in `requirements/tasks/_index.md`, list:
- Task ID | Title | Status | Execution Log (one-line summary)

All tasks must appear. If a task was completed in a prior subagent, note `(subagent)`.

### Token Report

If any `requirements/token_*.txt` files exist, generate the token usage report:

```bash
python3 .agents/skills/frontend-workflow/token_report.py requirements
```

This writes `requirements/token_report.md` and prints the table to stdout.

**Wait for user instruction before proceeding to commit/push.**

### PR Creation

When the user confirms to commit and push, create a PR with this description template:

```markdown
## Summary

[Brief description of what was implemented — derived from _index.md task list]

## Tasks Completed

[Task ID list from _index.md with one-line summaries]

## Deviations

[Copy from comparison/DEVIATION_REPORT.md if it exists, otherwise "None"]

## Token Usage

[Paste the full content of requirements/token_report.md here, including the phase table, the ↑N footnote, and the 欄位說明 table]
```

Use `gh pr create` with the description above. Set the base branch to `main` unless the user specifies otherwise.

---

## When to Stop and Ask the User

| Situation | Phase |
|-----------|-------|
| `SPEC_DIR` cannot be auto-detected | 0 |
| Multiple `PROTOTYPE_DIR` candidates cannot be auto-ranked | 0 |
| Spec gap or conflict cannot be self-resolved | 1 |
| Any of the 5 Structural Decision rows cannot be filled with a real code quote *(prototype mode)* | 1 |
| Section C has ✗ entries when Phase 1.5 is about to begin *(prototype mode)* | 1 |
| Waiting for user confirmation of task plan + blocker resolutions | 1.5 |
| User requests task split/merge during review confirmation | 1.5 |
| Subagent returns BLOCKER (BUILD or REVIEW) | 2, 3 |
| Pixel diff auto-fix reaches 3-round limit *(prototype mode)* | 4 |

---

## Output Artifacts

| File | Created in | Mode |
|------|-----------|------|
| `comparison/STUDY_NOTES.md` | Phase 1 (gate to Phase 1.5) | both |
| `requirements/tasks/_index.md` | Phase 1.5 | both |
| `requirements/tasks/BUILD-001.md` … `BUILD-N.md` | Phase 1.5 | both |
| `requirements/tasks/REVIEW-001.md` … `REVIEW-N.md` | Phase 1.5 (one per BUILD task) | both |
| `comparison/DEVIATION_REPORT.md` | Phase 2 subagent (ongoing) | prototype only |
| `comparison/ref/*.png` | Phase 3 (REVIEW-N tasks where §2 applies) | prototype only |
| `comparison/ours/*.png` | Phase 3 (REVIEW-N tasks where §2 applies) | prototype only |
| `comparison/diff/*.png` | Phase 3 (REVIEW-N tasks where §2 applies) | prototype only |
| `comparison/REPORT.md` | Phase 3 output | both |
| `requirements/token_report.md` | Phase 5 (if token logs exist) | both |
