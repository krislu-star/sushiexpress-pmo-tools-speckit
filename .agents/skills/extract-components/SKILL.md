---
name: extract-components
description: Extract reusable UI component patterns from a prototype and produce references/COMPONENTS.md, src/components/shared/*.tsx + *.module.css, and docs/design-system/components.html. Only runs when ui_stack = none. Callable standalone (/extract-components) or invoked by frontend-workflow Phase 1 Step 1.6.
version: 1.0.0
alwaysApply: false
---

# Extract Components

## When to use

- `ui_stack = none` (CSS Modules path) — this skill is meaningless for Ant Design or Shadcn projects
- A prototype directory exists with scannable source files or HTML
- `extract-design` has already run and `references/DESIGN.md` exists (required for token references)
- `frontend-workflow` calls this during Phase 1 Step 1.6, after extract-design

## Do NOT use for

- Projects with `ui_stack = antd`, `ui_stack = shadcn`, or any other UI library — return the skip signal immediately
- Projects with no prototype source code yet
- Replacing manually authored component files without user confirmation

---

## Input

| Argument | Default | Description |
|----------|---------|-------------|
| `--dir <path>` | auto-detect or `PROTOTYPE_DIR` from caller | Directory to scan for UI patterns |
| `--out-ref <path>` | `references/COMPONENTS.md` | Markdown inventory output |
| `--out-html <path>` | `docs/design-system/components.html` | Static visual reference output |
| `--out-src <path>` | `src/components/shared/` | Directory for generated `.tsx` + `.module.css` files |

**Auto-detect logic for `--dir`**: if not provided, scan for the first directory containing `package.json` or `src/`. If called from `frontend-workflow`, `PROTOTYPE_DIR` is passed directly.

---

## Protocol

### Step 0: Guard checks

**Check 1 — ui_stack guard:**
Read `package.json` in the project root. Find the `ui_stack` field.
- `ui_stack = none` → proceed
- Any other value → return immediately: `⏭ extract-components skipped (ui_stack=<value>)`
- Field absent → warn: "ui_stack not found in package.json. Is this a CSS Modules project? [Yes / No]". If Yes → proceed. If No → return skip signal.

**Check 2 — Existing output:**
If `<out-ref>` (`references/COMPONENTS.md`) already exists:
- **Called from `frontend-workflow`** (detected by: `--dir` was explicitly passed by the caller) → read it, skip Steps 1–5, go to Step 6 (return signal)
- **Called standalone** (detected by: `--dir` was not passed, using auto-detect) → ask user: **[Use existing]** or **[Regenerate]**. If [Use existing], go to Step 6.

**Check 3 — DESIGN.md prerequisite:**
Check that `references/DESIGN.md` exists.
- **Called from `frontend-workflow`** (explicit `--dir`) → if missing, error: "Step 1.5 must complete before Step 1.6"
- **Called standalone** (auto-detect `--dir`) → warn: "references/DESIGN.md not found — CSS token references will be unavailable. Proceed anyway? [Yes / No]"

---

### Step 1: Locate component candidates

Scan within `<dir>` in priority order. Collect all candidates across priorities before deduplication.

**Priority 1 — Explicit component directories**
Search for directories named `components/`, `ui/`, or `shared/` anywhere under `<dir>/src/`. For each `.tsx` / `.vue` file found, record: filename, all `className` values used, all props passed in JSX.

**Priority 2 — Repeated JSX patterns**
Search all `.tsx`, `.vue`, `.ts` source files under `<dir>/src/` for JSX elements where the same `className` string (or combination of classes) appears **3+ times** across distinct files or within a single file. Collect each unique repeated pattern as a candidate.

**Priority 3 — Static HTML class patterns (fallback)**
Active only when `<dir>` contains `*.html` files and Priority 1 yielded zero explicit component files. Priority 3 does NOT activate if Priority 2 found candidates — it is a fallback for when the prototype has no `src/components/` structure at all.
Parse all `*.html` files. Collect any CSS class string that appears on **3 or more distinct elements** across all files.

---

### Step 2: Map to canonical roles + collect per-component data

For each candidate from Step 1, attempt to assign a canonical role by keyword matching against the candidate's class names, file name, and directory name (all case-insensitive):

| Canonical role | Match keywords |
|----------------|---------------|
| `Button`  | `btn`, `button`, `cta` |
| `Card`    | `card`, `tile`, `panel` |
| `Badge`   | `badge`, `tag`, `chip`, `label` |
| `Input`   | `input`, `field`, `search` |
| `Nav`     | `nav`, `menu`, `sidebar`, `header` |
| `Modal`   | `modal`, `dialog`, `overlay`, `drawer` |
| `Avatar`  | `avatar`, `user-icon` |
| `Spinner` | `spinner`, `loading`, `skeleton` |

Candidates with no matching role → discard silently.

If zero canonical roles remain after discarding:
- If Step 1 found candidates but all were discarded: report "No candidates matched any canonical role in `<dir>` — consider adding more keyword coverage."
- If Step 1 found zero candidates at all: report "No repeated UI patterns found in `<dir>` — prototype may not have reusable components."

In both cases: return without writing any files.

**For each matched component, collect:**

1. **Props** — infer from JSX props or HTML attributes. Common props:
   - `variant`, `size`, `disabled`, `loading`, `children`, `onClick`, `className`, `href`, `type`
   - Record as TypeScript union literals where multiple values are visible (e.g. `variant: 'primary' | 'secondary'`)

2. **States** — CSS class variants found in source:
   - Modifier suffixes: `--active`, `--disabled`, `--loading`, `--sm`, `--md`, `--lg`
   - Sibling classes: `btn-primary`, `btn-ghost`, `card--elevated`
   - Record each as a named state

3. **CSS** — collect all rules that apply to this component:
   - From Tailwind: group class names by state (base / variant / size)
   - From `.css` / `.module.css`: collect relevant rules verbatim
   - From inline styles: collect `style={{...}}` property pairs
   - Convert to CSS module syntax (`.root {}` for base, one class per variant/state)
   - Where a CSS value matches a token in `references/DESIGN.md`, replace with `var(--<token-path>)` form.
     Token path format: `--` + section + `-` + key with `.` replaced by `-`.
     Example: `{colors.primary}` → `var(--colors-primary)`, `{rounded.md}` → `var(--rounded-md)`

4. **Token references** — for COMPONENTS.md prose, record matched tokens using `{section.key}` syntax:
   e.g. `{colors.primary}`, `{rounded.md}`, `{typography.button}`

---

### Step 3: Write `references/COMPONENTS.md`

Create `references/` if it does not exist.

Follow `.agents/skills/extract-components/TEMPLATE.md` exactly for structure and section order.

Write one `##` section per canonical role, in alphabetical order. Each section must include:
- **Props** — TypeScript prop signature (union literals for variants)
- **States** — comma-separated list
- **Token refs** — using `{section.key}` syntax for matched tokens
- **File** — the output path `src/components/shared/<Name>.tsx`

---

### Step 4: Write `.tsx` scaffold + `.module.css` per component

Create `<out-src>/` if it does not exist.

For each canonical role, produce two files:

#### `<out-src>/<Name>.tsx`

Rules:
- Props interface name: `<Name>Props`
- Named export: `export function <Name>(...)`
- JSX: one root element with `className={styles.root}` plus variant/size class lookups
- Variant classes: use template literal `${styles[variant]}` pattern — not ternary chains
- No implementation logic — structural skeleton only
- Import: `import styles from './<Name>.module.css'`

Template (adapt root element per role: `<button>` for Button, `<div>` for Card, etc.):

```tsx
import styles from './Button.module.css'

interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'ghost'
  size?: 'sm' | 'md' | 'lg'
  disabled?: boolean
  children: React.ReactNode
  onClick?: () => void
}

export function Button({ variant = 'primary', size = 'md', disabled, children, onClick }: ButtonProps) {
  return (
    <button
      className={`${styles.root} ${styles[variant]} ${styles[size]}`}
      disabled={disabled}
      onClick={onClick}
    >
      {children}
    </button>
  )
}
```

#### `<out-src>/<Name>.module.css`

Rules:
- `.root` class for base styles
- One class per variant/state name (matching what `.tsx` passes to `styles[variant]`)
- Use `var(--token-path)` for any value with a matching token in `references/DESIGN.md`
- Hardcode values only when no matching token exists

Template (adapt values from Step 2 CSS collection):

```css
.root {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  cursor: pointer;
  border-radius: var(--rounded-md);
  font-family: var(--font-body);
  transition: opacity 0.15s;
}
.root:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.primary {
  background-color: var(--colors-primary);
  color: var(--colors-on-primary);
}
.secondary {
  background-color: transparent;
  color: var(--colors-primary);
  border: 1px solid var(--colors-primary);
}
.ghost {
  background-color: transparent;
  color: var(--colors-ink);
}

.sm { padding: 4px 12px; font-size: 13px; }
.md { padding: 8px 16px; font-size: 14px; }
.lg { padding: 12px 24px; font-size: 16px; }
```

---

### Step 5: Write `docs/design-system/components.html`

Create `docs/design-system/` if it does not exist.

Structure (self-contained HTML — no external file dependency). Produce the HTML below, substituting ALL `[placeholder]` values with actual data and replacing all `{ ... }` and `.class { ... }` stub rules with actual extracted styles:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>[Project Name] Components</title>
  <style>
    /* 1. Design tokens as CSS custom properties — read from references/DESIGN.md */
    :root {
      --colors-primary: [value from DESIGN.md];
      --colors-on-primary: [value];
      --colors-canvas: [value];
      --colors-ink: [value];
      --rounded-md: [value];
      /* ... all tokens */
    }

    /* 2. Page chrome */
    * { box-sizing: border-box; }
    body { margin: 0; font-family: sans-serif; display: flex; min-height: 100vh; }
    .toc { width: 200px; padding: 24px 16px; border-right: 1px solid #eee; position: sticky; top: 0; height: 100vh; overflow-y: auto; flex-shrink: 0; }
    .toc h1 { font-size: 14px; font-weight: 600; margin: 0 0 16px; }
    .toc a { display: block; font-size: 13px; color: #555; text-decoration: none; padding: 4px 0; }
    .toc a:hover { color: #000; }
    .main { flex: 1; padding: 40px; max-width: 960px; }
    .component-section { margin-bottom: 64px; }
    .component-section h2 { font-size: 20px; border-bottom: 1px solid #eee; padding-bottom: 8px; margin-bottom: 24px; }
    .variant-row { display: flex; gap: 16px; flex-wrap: wrap; align-items: center; margin-bottom: 16px; }
    .variant-label { font-size: 11px; color: #999; margin-bottom: 4px; }

    /* 3. Component styles — copy from generated .module.css, using plain class names */
    /* Button */
    .btn-root { ... }
    .btn-primary { ... }
    /* Card */
    .card-root { ... }
    /* ... etc */
  </style>
</head>
<body>
  <aside class="toc">
    <h1>[Project] Components</h1>
    <nav>
      <!-- One <a href="#[role]">[Role]</a> per component, alphabetical -->
    </nav>
  </aside>
  <main class="main">
    <!-- One .component-section per role -->
    <section class="component-section" id="button">
      <h2>Button</h2>
      <!-- One .variant-row per state/variant group -->
      <div class="variant-row">
        <div><div class="variant-label">primary</div><button class="btn-root btn-primary">Label</button></div>
        <div><div class="variant-label">secondary</div><button class="btn-root btn-secondary">Label</button></div>
        <div><div class="variant-label">ghost</div><button class="btn-root btn-ghost">Label</button></div>
        <div><div class="variant-label">disabled</div><button class="btn-root btn-primary" disabled>Label</button></div>
      </div>
    </section>
    <!-- ... repeat for each component -->
  </main>
</body>
</html>
```

Note: prefix component CSS class names in the HTML page to avoid collisions (e.g. `.btn-root`, `.card-root`). The `.tsx` + `.module.css` files use plain `.root` because CSS Modules scope them automatically.

---

### Step 6: Return signal

Output one line:

```
✅ references/COMPONENTS.md — [N components: Button, Card, …]
```

If called from `frontend-workflow`: this is the signal that Phase 1 Step 1.6 is complete.

When `ui_stack ≠ none`:
```
⏭ extract-components skipped (ui_stack=<value>)
```

When zero canonical roles found (no files written):
```
⚠️ extract-components: no reusable component patterns found in <dir> — skipping file generation
```

---

## Output contract

| Field | Value |
|-------|-------|
| Exit signal (success) | `✅ references/COMPONENTS.md — [N components: ...]` |
| Exit signal (skip) | `⏭ extract-components skipped (ui_stack=<value>)` |
| Exit signal (no match) | `⚠️ extract-components: no reusable component patterns found in <dir>` |
| Output paths | `references/COMPONENTS.md`, `docs/design-system/components.html`, `src/components/shared/<Name>.tsx`, `src/components/shared/<Name>.module.css` |
| Reuse condition | If `references/COMPONENTS.md` exists when called from `frontend-workflow`, read and return without regeneration |
| Zero-match behavior | Return warning, write no files |
