---
name: review
description: Per-BUILD-task review skill — reads Coverage from a BUILD task, runs applicable §1/§2/§3 sections, writes results to the paired REVIEW task file
version: 1.0.0
alwaysApply: false
---

# Review Skill

## Activation Contract

### Use this skill when
- Running `/review BUILD-XXX` to review a specific BUILD task
- Running `/review BUILD-XXX..YYY` to review a range of BUILD tasks (e.g. `/review BUILD-002..004`)
- Running `/review all` to review all `done` BUILD tasks listed in `requirements/tasks/_index.md`
- Spawned as a Phase 3 subagent by the frontend-workflow orchestrator

### Do NOT use for
- Running the full frontend workflow (use `frontend-workflow` skill instead)
- Applying fixes — this skill reports findings only; fixes are handled by BUILD task subagents

---

## Execution

### Step 1: Read configuration

Read `requirements/tasks/_index.md` Config block:
- `PROTOTYPE_DIR` (path or `none`)
- `SPEC_DIR`
- `REF_PORT`
- `OURS_PORT`
- `Mode` (prototype | spec-only)

### Step 2: Resolve BUILD tasks in scope

| Invocation | Scope |
|------------|-------|
| `/review BUILD-002` | [BUILD-002] |
| `/review BUILD-002..004` | [BUILD-002, BUILD-003, BUILD-004] |
| `/review all` | all Task Queue rows matching `BUILD-*` with Status = `done` |
| Phase 3 subagent (REVIEW-XXX) | [BUILD-XXX] (paired task) |

### Step 3: For each BUILD task in scope

#### 3a. Read Coverage

Open `requirements/tasks/BUILD-XXX.md`, read `## Coverage`:
- Features: [F-xxx list or `—`]
- Use Cases: [UC-xxx list or `—`]
- Screens: [screen names or `—`]
- Files: [list of .tsx/.ts paths]

#### 3b. Determine which sections to run

| Section | Condition |
|---------|-----------|
| §1 Static Code Review | Always — scoped to Coverage.Files |
| §2 Visual Comparison | Coverage.Screens ≠ `—` **AND** _index.md Mode = `prototype` |
| §3 Functional Validation | Coverage.Use Cases ≠ `—` |

#### 3c. Run §1 — Static Code Review (always)

Follow `REVIEW_RULE.md §1` (程式碼靜態審查).
Scope: only the files listed in Coverage.Files (do not scan unrelated files).
Run all grep checks from §1.1 restricted to those paths.
Run `npx tsc --noEmit` and `npm run lint` (project-wide — cannot be scoped to individual files).

Write results under `## §1 Static Code Review` in `REVIEW-XXX.md`:
- List each check with ✅ / ❌
- For ❌: include file path, line number, rule reference

#### 3d. Run §2 — Visual Comparison (if applicable)

Follow `REVIEW_RULE.md §2` (視覺像素比對).
Scope: only the screens listed in Coverage.Screens.
Take screenshots for those screens only, compare against ref, produce diff.
Write results under `## §2 Visual Comparison` in `REVIEW-XXX.md`.

Skip this section and write `_skipped — Coverage.Screens is `—` or Mode = spec-only_` if not applicable.

#### 3e. Run §3 — Functional Validation (if applicable)

Follow `REVIEW_RULE.md §3` (功能流程驗收).
Scope: only the Use Cases listed in Coverage.Use Cases and Features listed in Coverage.Features.
Write results under `## §3 Functional Validation` in `REVIEW-XXX.md`.

Skip this section and write `_skipped — Coverage.Use Cases is `—`_` if not applicable.

### Step 4: Finalize REVIEW-XXX.md

Update `Status: pending` → `Status: done`.
Fill `## Execution Log` with a one-line summary per section (sections run, pass/fail counts).

### Step 5: Update `_index.md`

Mark REVIEW-XXX as `done` in the Task Queue.
Advance `▶ Next Task` to the next REVIEW task (or Phase 5 if this was the last).

---

## Common mistakes / gotchas

- **§2 in spec-only mode**: always check `_index.md Mode` before running §2. Skip if `spec-only`.
- **Scoping §1 greps**: restrict grep paths to Coverage.Files, not all of `src/`. TypeScript and lint still run project-wide.
- **Reading Coverage.Files before it is filled**: if `[filled by BUILD subagent]` placeholder is still present, the BUILD task was not marked done correctly — report as BLOCKER.
- **Wrong pairing**: REVIEW-003 pairs with BUILD-003, not with Visual Comparison. Confirm the paired BUILD task ID from `## Meta - BUILD Task`.
