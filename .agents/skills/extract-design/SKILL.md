---
name: extract-design
description: Extract design tokens from a prototype or existing project and produce references/DESIGN.md following the awesome-design-md format. Callable standalone (/extract-design) or invoked by frontend-workflow.
version: 1.0.0
alwaysApply: false
---

# Extract Design

## When to use

- You have a prototype or project directory with Tailwind config, CSS variables, or hardcoded styles
- You want to produce a portable `DESIGN.md` capturing the project's design language
- `frontend-workflow` calls this during Phase 1 to extract tokens before task planning

## Do NOT use for

- Projects with no source code yet (nothing to extract from)
- Replacing a manually authored `DESIGN.md` without user confirmation

---

## Input

| Argument | Default | Description |
|----------|---------|-------------|
| `--dir <path>` | auto-detect | Directory to scan for design tokens |
| `--out <path>` | `references/DESIGN.md` | Output path |

**Auto-detect logic for `--dir`**: scan for the first directory containing `tailwind.config.ts`, `tailwind.config.js`, `globals.css`, or `src/`. If called from `frontend-workflow`, `PROTOTYPE_DIR` is passed directly.

---

## Protocol

### Step 0: Check existing DESIGN.md

If `<out>` already exists:
- **Called from `frontend-workflow`** → read it, skip Steps 1–4, go to Step 5 (return path)
- **Called standalone** → ask user: **[Use existing]** or **[Regenerate]**. If [Use existing], go to Step 5.

---

### Step 1: Locate token sources

Scan within `<dir>` in this priority order:

| Priority | Source | What to find |
|----------|--------|-------------|
| 1 | `tailwind.config.ts` / `tailwind.config.js` | `theme.colors`, `theme.extend.colors`, `theme.spacing`, `theme.extend.spacing`, `theme.borderRadius`, `theme.extend.borderRadius`, `theme.fontSize`, `theme.extend.fontSize`, `theme.fontFamily`, `theme.screens` |
| 2 | `**/globals.css`, `**/index.css`, `**/_variables.css` | `:root { --color-*, --radius-*, --spacing-*, --font-* }` |
| 3 | `src/**/*.tsx`, `src/**/*.vue`, `src/**/*.ts` | Hardcoded hex codes (`#[0-9a-fA-F]{3,8}`), rgba values |
| 4 | `**/*.html` — `<style>` blocks | Parse all `<style>` and `<style scoped>` blocks; extract class rules, CSS variables, hex/rgba values. Treat each `.class-name { ... }` block the same as a CSS file rule. |
| 5 | `**/*.html` — inline styles | Parse all `style="..."` attribute values; collect `color`, `background`, `background-color`, `font-size`, `font-family`, `border-radius`, `padding`, `margin`, `width`, `height` properties. Values appearing 3+ times across all inline styles are promoted to token candidates. |

Read all sources found. If none found, report and ask user to point to the correct directory.

**HTML prototype note**: When `<dir>` contains `*.html` files and no `package.json` (static HTML prototype from Claude design or similar tools), priorities 4 and 5 are the primary sources. Run priorities 1–3 first; if they yield fewer than 3 color tokens, fall through to 4–5 automatically.

---

### Step 2: Build token map

#### Colors

1. Flatten Tailwind `theme.extend.colors` (nested → kebab-case keys, e.g. `primary.500` → `primary-500`)
2. Parse CSS `:root` variables: `--color-primary: #xxx` → `primary: "#xxx"`; CSS vars override Tailwind where keys overlap
3. From component scan: collect hex values appearing **3 or more times** that are not already named in steps 1–2. Assign descriptive names based on context (button className, background, text color).
4. Merge all three layers. Final precedence: CSS vars > Tailwind > component scan.

Organize into semantic groups: Brand & Accent, Surface, Text, Semantic.

**Required color aliases** — if not found, infer from the closest extracted value:
- `primary` — most-used accent/CTA color
- `on-primary` — text on primary background (usually `#ffffff`)
- `canvas` — default page background
- `ink` — primary text color

#### Typography

1. From Tailwind `theme.fontFamily`: extract font stack for display and body roles.
2. From Tailwind `theme.fontSize`: each entry becomes a token. Infer role from key name (xl → display, lg → heading, base/md → body, sm → caption, xs → micro).
3. Build a named scale mapping to these canonical roles (use only roles that have matching sizes):

   `display-xl`, `display-lg`, `display-md`, `heading-lg`, `heading-md`, `heading-sm`, `body-lg`, `body`, `body-sm`, `caption`, `button`, `eyebrow`, `mono`

4. For each token: populate `fontFamily`, `fontSize`, `fontWeight`, `lineHeight`, `letterSpacing`. Use `0` for letterSpacing if not found.

#### Rounded

From Tailwind `theme.extend.borderRadius` or CSS `--radius-*`. Map to scale: `xs`, `sm`, `md`, `lg`, `xl`, `pill` (9999px). Add `pill: 9999px` if not present.

#### Spacing

From Tailwind `theme.extend.spacing` or CSS `--spacing-*`. Select up to 8 representative tokens: `xxs`, `xs`, `sm`, `md`, `lg`, `xl`, `xxl`, `section`. If the config has more, pick the values that best represent those scale steps.

#### Components

Scan for these component patterns in source files. For each found, infer token values from className or style props:

- `button-primary` — look for primary/filled button usage
- `button-secondary` — look for outline/ghost button usage
- `card` — look for Card, card wrapper with bg/padding/radius
- `text-input` — look for Input, input field components
- `nav` / `top-nav` — look for navigation bar/header component

Each component entry must have: `backgroundColor`, `textColor`, `typography`, `rounded`, `padding`.
Reference other tokens using `"{colors.xxx}"` / `"{typography.xxx}"` / `"{rounded.xxx}"` syntax.

---

### Step 3: Infer project metadata

- **name**: from `package.json` → `name` field, or from `--dir` directory name
- **description**: one sentence summarizing the dominant color, surface, and typography personality. Infer from extracted tokens.
- **version**: always `alpha`

---

### Step 4: Write `references/DESIGN.md`

Create `references/` if it does not exist.

Follow `.agents/skills/extract-design/TEMPLATE.md` exactly for structure and section order.

**YAML frontmatter**: populate all extracted token sections. Omit a section entirely if no tokens were found for it.

**Prose sections**:
- **Overview**: write a short paragraph describing the dominant surface color, primary accent, and typography personality based on extracted tokens. List Key Characteristics (3–5 bullet points inferred from token values).
- **Colors**: for each color token, one-line description of its role. Group into Brand & Accent / Surface / Text / Semantic.
- **Typography**: fill the Hierarchy table with all extracted tokens. Leave Principles as `<!-- TODO: describe typography principles -->`.
- **Layout**: fill Spacing System token list. Leave Grid and Whitespace as TODO.
- **Elevation & Depth**: leave as TODO.
- **Shapes**: fill Border Radius Scale table from extracted `rounded` tokens.
- **Components**: describe each extracted component with its token references.
- **Do's and Don'ts**: leave as `<!-- TODO: add after reviewing the design in practice -->`.
- **Responsive Behavior**: fill Breakpoints table from Tailwind `theme.screens` if available; otherwise leave as TODO.
- **Iteration Guide**: always include the standard iteration guide (see TEMPLATE.md).

---

### Step 5: Return

Output one line:

```
✅ references/DESIGN.md — [N colors, M typography tokens, K spacing tokens, P components]
```

If called from `frontend-workflow`: this is the signal that Phase 1 Step 1.5 is complete. The path `references/DESIGN.md` is now available for BUILD task Briefs.

---

## Token reference syntax

When writing DESIGN.md prose or component definitions, always use the `{section.key}` syntax to reference other tokens:

- `{colors.primary}` not `#5e6ad2`
- `{typography.body}` not `16px / 400`
- `{rounded.md}` not `8px`
- `{spacing.lg}` not `24px`

This makes DESIGN.md portable: when tokens change, prose descriptions stay accurate by reference.

---

## Output contract (for callers)

| Field | Value |
|-------|-------|
| Exit signal | `✅ references/DESIGN.md — ...` |
| Output path | `references/DESIGN.md` (or value of `--out`) |
| Reuse condition | If file already exists when called from orchestrator, it is read and returned without regeneration |
