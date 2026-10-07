---
name: anti-ai-design
description: Force explicit visual identity choices before any UI is generated. Reads the ui-ux-pro-max design database to surface 4 project-relevant, non-AI-default options across color, typography, and visual style. Use when starting a new project with no prototype.
version: 2.0.0
alwaysApply: false
---

# Anti-AI Design

Use this skill to lock in a distinctive visual identity **before generating any UI**. It reads real design data from the local ui-ux-pro-max database to surface options that match the project's domain — then filters out AI-default patterns so you never accidentally ship another indigo SaaS clone.

## When to use

- Starting a new project with no prototype (no existing design to extract from)
- Before building the first real UI page or component
- When `frontend-template-bootstrap` confirms `ui_stack` and there is no prototype
- When `frontend-workflow` shows the ⚠️ no STYLE-IDENTITY.md warning

## Do NOT use for

- Projects with an existing prototype — use `extract-design` instead
- Mid-development projects with an established visual identity
- Pure backend, API, or infrastructure work

---

## The Ban List

These patterns are **prohibited** unless the user explicitly overrides with a stated reason.

**Colors (banned defaults)**
- Indigo primary: `#6366f1`, `#4f46e5`, `#818cf8` and nearby (Tailwind indigo family)
- Violet primary: `#7c3aed`, `#8b5cf6`, `#a78bfa` (Tailwind violet family)
- Blue-purple gradients: `from-blue-600 to-purple-600` or similar
- Default dark mode: `#0f172a` (slate-900) as the only dark surface

**Typography (banned defaults)**
- Inter as the sole or primary font
- Geist as the sole or primary font
- Both heading AND body fonts from the generic set: Inter, Poppins, Open Sans, Roboto, Lato, Nunito

**Layout & Style (banned defaults)**
- Glassmorphism: `backdrop-blur` + semi-transparent surfaces as the default treatment
- Neumorphism
- Hero → Feature grid → CTA strip (the "Vercel clone" pattern)
- `whileInView` Framer Motion entrance animations on every section without purpose

---

## Data files

This skill reads from:
- `.agents/skills/ui-ux-pro-max/data/colors.csv` — 161 product-type color palettes
- `.agents/skills/ui-ux-pro-max/data/styles.csv` — 50+ visual styles
- `.agents/skills/ui-ux-pro-max/data/typography.csv` — 73 font pairings

If any file is missing, report it and stop.

---

## Protocol

### Step 0: Check for existing STYLE-IDENTITY.md

If `references/STYLE-IDENTITY.md` already exists:
- Read it and confirm the choices with the user.
- If confirmed → skip to Step 6 (return).
- If the user wants to regenerate → continue from Step 1.

---

### Step 1: Show the ban list

Display the ban list above. Say:

> "這些樣式被禁止使用。如需覆蓋任何項目，請現在說明原因。"

Wait for acknowledgement or override requests before continuing.

---

### Step 2: Ask project category

Call `AskUserQuestion` (one question):

question: `這個產品是哪種類型？`
header: `Project type`
multiSelect: false

Options:

**Option 1** — label: `業務工具 / 後台`
description: `SaaS、管理後台、B2B 服務、數據 dashboard、生產力工具`

**Option 2** — label: `消費者產品`
description: `電商、健康 app、社交、教育、生活風格`

**Option 3** — label: `創意 / 內容`
description: `品牌官網、設計公司、Portfolio、部落格、媒體`

**Option 4** — label: `技術 / 開發者工具`
description: `開發工具、CLI、文件站、API 平台、AI 產品`

---

### Step 3: Read CSV data and select candidates

Read the three data files. For each dimension, select 4 candidates based on the project category answer. **Do not invent values — every hex, font name, and style name must come directly from the CSV.**

#### 3a — Color palettes (from `colors.csv`)

Columns: `No, Product Type, Primary, On Primary, Secondary, On Secondary, Accent, On Accent, Background, Foreground, Card, Card Foreground, Muted, Muted Foreground, Border, Destructive, On Destructive, Ring, Notes`

**Category → matching Product Type rows:**

| Category | Match these `Product Type` values |
|----------|-----------------------------------|
| 業務工具 / 後台 | SaaS (General), B2B Service, Financial Dashboard, Analytics Dashboard, Productivity Tool, Design System/Component Library |
| 消費者產品 | E-commerce, E-commerce Luxury, Healthcare App, Educational App, Social Media App |
| 創意 / 內容 | Creative Agency, Portfolio/Personal, Gaming, NFT/Web3 Platform |
| 技術 / 開發者工具 | AI/Chatbot Platform, Fintech/Crypto, Government/Public Service, Micro SaaS |

**Ban filter — exclude any row where `Primary` is:**
`#6366F1`, `#4F46E5`, `#818CF8`, `#7C3AED`, `#8B5CF6`, `#A78BFA`

**Selection rule:**
Pick 4 rows where the `Primary` colors come from different hue families (e.g. one green, one warm neutral, one dark, one vivid). Aim for maximum visual diversity. If fewer than 4 rows survive the filter, pull from adjacent categories.

**For each selected row, note:**
- `No` (row number, for traceability)
- `Product Type`
- `Primary`, `Background`, `Foreground`, `Accent` hex values
- `Notes` (personality description)
- An emoji for the Primary color:
  - 🔴 red (0–20°) · 🟠 orange (20–40°) · 🟡 yellow (40–65°) · 🟢 green (80–160°)
  - 🩵 teal/cyan (160–200°) · 🔵 blue (200–235°) · 🩷 pink/rose (330–360°)
  - ⬛ very dark (#000–#222) · 🟫 warm dark (#1C0A00 type) · 🟨 gold/amber

#### 3b — Font pairings (from `typography.csv`)

Columns: `No, Font Pairing Name, Category, Heading Font, Body Font, Mood/Style Keywords, Best For, Google Fonts URL, CSS Import, Tailwind Config, Notes`

**Ban filter — exclude rows where:**
- `Body Font` is "Inter" AND `Heading Font` is from: Poppins, Open Sans, Roboto, Lato, Nunito, Source Sans
- (Inter body + a distinctive display heading is acceptable)

**Selection rule:**
Find pairings where `Best For` mentions content matching the project category. Pick 4 with different `Category` values (e.g. Serif+Sans, Display+Serif, Sans+Sans, Mono+Sans) for visual diversity.

**For each selected row, note:**
- `No`, `Font Pairing Name`, `Category`
- `Heading Font`, `Body Font`
- First 4 keywords from `Mood/Style Keywords`
- First use-case from `Best For`
- `CSS Import` URL

#### 3c — Visual styles (from `styles.csv`)

Columns: `No, Style Category, Type, Keywords, Primary Colors, Secondary Colors, Effects & Animation, Best For, Do Not Use For, ...`

**Ban filter — exclude rows where `Style Category` contains:**
"Neumorphism", "Glassmorphism"

**Selection rule:**
Find styles where `Best For` mentions content relevant to the project category. Pick 4 with noticeably different `Keywords` (e.g. one clean/minimal, one bold/typographic, one retro, one editorial). Prefer styles with `Performance: ⚡ Excellent` or `⚡ Good`.

**For each selected row, note:**
- `No`, `Style Category`
- First 4 `Keywords`
- First 2 entries from `Best For`

---

### Step 4: Present identity choices

Call `AskUserQuestion` with **4 questions in one call** using the candidates from Step 3.

---

**Question 1 — Color** (`header: "Color"`, `multiSelect: false`):
question: `這個專案的顏色個性？`

For each of the 4 selected palettes create one option:
- label: `Product Type` value from CSV (shorten if > 4 words)
- description: `[emoji] [Primary hex]  ⬜ [Background hex] — [Notes, max 30 chars]`
- preview: full CSV palette details (Primary, Secondary, Accent, Background, Notes)

---

**Question 2 — Fonts** (`header: "Fonts"`, `multiSelect: false`):
question: `字體個性？`

For each of the 4 selected pairings:
- label: `Font Pairing Name` from CSV
- description: `[Heading Font] + [Body Font] — [first 3 Mood/Style Keywords]`
- preview: `Best For` + `CSS Import` URL

---

**Question 3 — Style** (`header: "Style"`, `multiSelect: false`):
question: `視覺語言？`

For each of the 4 selected styles:
- label: `Style Category` name
- description: `[first 4 Keywords] — 像 [first Best For entry]`
- preview: full `Keywords` + `Best For` text from CSV

---

**Question 4 — Accent use** (`header: "Accent use"`, `multiSelect: false`):
question: `強調色怎麼用？`

This question is static (same for all project types):

Option 1 — label: **Only on Buttons & Links**
description: `強調色只出現在按鈕、連結、focus ring — 其他一律中性`
preview:
```
  [ Primary Button ]  ← 強調色在這裡
  點這裡 ──────────    ← 強調色在這裡
  ☑ 勾選時變色         ← 強調色在這裡

  其他地方：灰色或黑色
→ 最剋制、最功能性
```

Option 2 — label: **Color Lives in Words**
description: `強調色只出現在標題文字上 — 背景永遠是白或灰`
preview:
```
  Build something
  ▓▓ DIFFERENT ▓▓    ← 強調色在文字
  for the world

  背景永遠是白或灰
→ 編輯感、平面設計感
```

Option 3 — label: **Color as Lines & Borders**
description: `強調色用在邊框、分隔線、左側裝飾線 — 不做背景填色`
preview:
```
  ┃ Section title      ← 強調色左邊框
  │                    ← 強調色分隔線
  ┗━━━━━━━━━━━━━━━━    ← 強調色底線

  沒有填色背景。
→ 有建築感、理性、精準
```

Option 4 — label: **Hero Takeover**
description: `強調色佔滿 hero 區塊背景 — 其他區塊回歸中性`
preview:
```
  ████████████████████
  ██  BIG STATEMENT  ██  ← 強調色滿版背景
  ████████████████████

  然後回到中性背景
→ 品牌感強、第一眼就記住
```

---

### Step 5: Translate choices to CSS variables

Use the actual CSV column values from the selected rows. **Do not invent hex values.**

**From the selected `colors.csv` row:**
```css
--color-primary:    [Primary column];
--color-on-primary: [On Primary column];
--color-secondary:  [Secondary column];
--color-accent:     [Accent column];
--color-surface:    [Background column];
--color-ink:        [Foreground column];
--color-muted:      [Muted column];
--color-border:     [Border column];
```
Dark mode surface: use `Card` column as dark background, `Card Foreground` as dark ink.

**From the selected `typography.csv` row:**
```css
--font-display: '[Heading Font]', [serif or sans-serif based on Category];
--font-body:    '[Body Font]',    [serif or sans-serif based on Category];
```
Google Fonts: use the `CSS Import` column URL verbatim.

**From the selected `styles.csv` row — derive shape:**

Scan `Keywords` for these signals:

| Keyword signal | `--radius-default` | `--shadow-default` |
|----------------|-------------------|-------------------|
| flat / minimal / brutalist / Swiss / grid | `0px`–`2px` | `none` (use `1px solid` borders instead) |
| rounded / soft / friendly / organic | `12px`–`20px` | `0 8px 32px rgba(0,0,0,0.08)` |
| editorial / magazine / large type / spacious | `2px`–`4px` | `0 2px 8px rgba(0,0,0,0.06)` |
| retro / vintage / craft / print | `4px`–`6px` | `3px 3px 0 currentColor` |
| (none of the above) | `8px` | `0 4px 16px rgba(0,0,0,0.08)` |

**From the accent choice:**

| Choice | Write this rule |
|--------|----------------|
| Only on Buttons & Links | "Use `--color-primary` only on `<button>`, `<a>`, focus rings, active states. Never on section backgrounds or decorative elements." |
| Color Lives in Words | "Use `--color-primary` only on text — key words in headings and inline emphasis. Backgrounds stay neutral." |
| Color as Lines & Borders | "Use `--color-primary` only on borders, dividers, left rules, underlines. Never as fill or background." |
| Hero Takeover | "Use `--color-primary` as the hero section background and primary CTA fill. All other sections use `--color-surface`." |

---

### Step 6: Write `references/STYLE-IDENTITY.md`

Create `references/` if it does not exist. Write the file:

```markdown
# Style Identity

> Generated by anti-ai-design before any UI was built.
> Choices are LOCKED. Do not drift toward AI defaults during implementation.
> Override only with explicit user instruction and a stated reason.

## Banned Patterns (Enforced)

- ❌ Indigo / violet primary (#6366f1 / #4f46e5 / #7c3aed and nearby hues)
- ❌ Inter or Geist as the primary/only font
- ❌ Glassmorphism (backdrop-blur + semi-transparent surfaces)
- ❌ Neumorphism
- ❌ Vercel-clone layout: hero → feature grid → CTA strip
- ❌ Framer Motion entrance animations on every section

## Chosen Identity

| Dimension | Choice | Source |
|-----------|--------|--------|
| Color palette | [Product Type] | colors.csv row [No] |
| Font pairing | [Font Pairing Name] | typography.csv row [No] |
| Visual style | [Style Category] | styles.csv row [No] |
| Accent use | [Choice] | — |

## CSS Starting Point

```css
:root {
  /* Color — colors.csv: [Product Type] */
  --color-primary:    [hex];
  --color-on-primary: [hex];
  --color-secondary:  [hex];
  --color-accent:     [hex];
  --color-surface:    [hex];
  --color-ink:        [hex];
  --color-muted:      [hex];
  --color-border:     [hex];

  /* Typography — typography.csv: [Font Pairing Name] */
  --font-display: '[Heading Font]', [stack];
  --font-body:    '[Body Font]', [stack];

  /* Shape — styles.csv: [Style Category] */
  --radius-default: [value];
  --shadow-default: [value];
}
```

## Google Fonts

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="[CSS Import URL from typography.csv]" rel="stylesheet">
```

## Accent Rules

[Paste the rule text from Step 5 for the chosen accent option]

## Implementation Checklist

Before submitting any UI component or page for this project:
- [ ] No indigo / violet primary in the diff
- [ ] No Inter or Geist as the sole font
- [ ] No `backdrop-blur` unless explicitly requested by user
- [ ] Font variables use `var(--font-display)` / `var(--font-body)`, not hardcoded names
- [ ] Accent color follows the rule above
- [ ] Layout does not follow hero → feature grid → CTA strip
```

---

### Step 7: Return

Output one line:

```
✅ references/STYLE-IDENTITY.md — [Color: X | Fonts: Y | Style: Z | Accent: W]
```

If called from `frontend-workflow`: this is the signal that visual identity is locked and Phase 0 may proceed.

---

## Integration points

### `frontend-template-bootstrap`
After step 13 (ui_stack confirmed), if no prototype exists: add `[ ] Run /anti-ai-design before first BUILD task` to `TASK-000-bootstrap.md`. Do not run during bootstrap itself.

### `frontend-workflow`
Session Start Protocol fresh-start path: if `references/STYLE-IDENTITY.md` is missing, prompt A/B (run now vs skip) before Phase 0.

### `extract-design`
Mutually exclusive: prototype exists → `extract-design`. No prototype → `anti-ai-design`. If both files exist, `DESIGN.md` from extract-design takes precedence for token values; `STYLE-IDENTITY.md` provides the ban list enforcement.

---

## Do Not

- Do not ask color/font/style questions before reading the CSV files.
- Do not invent hex values, font names, or style names — use the CSV data directly.
- Do not present options from banned rows even if the filtered set is small.
- Do not skip the project category question — it drives all three CSV selections.
- Do not let banned styles slip in because they are "close enough".
