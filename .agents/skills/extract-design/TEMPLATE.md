# DESIGN.md Output Template

This file defines the exact structure an agent must produce when writing `references/DESIGN.md`.
Replace all `[placeholder]` values with extracted or inferred content.
Replace all `<!-- TODO -->` sections with authored content when available, or leave as-is for human follow-up.

---

```markdown
---
version: alpha
name: [Project Name]
description: [One sentence: dominant surface, primary accent color with hex, typography personality. Example: "A dark-canvas product UI built on #010102, with a lavender-blue accent (#5e6ad2) and a custom sans display face at weight 600 with aggressive negative tracking."]

colors:
  primary: "#[hex]"
  on-primary: "#[hex]"
  # Brand & Accent
  # [token-name]: "#[hex]"

  # Surface
  canvas: "#[hex]"
  # [token-name]: "#[hex]"

  # Text
  ink: "#[hex]"
  # [token-name]: "#[hex]"

  # Semantic (omit section if none extracted)
  # semantic-error: "#[hex]"
  # semantic-success: "#[hex]"
  # semantic-warning: "#[hex]"

typography:
  display-xl:
    fontFamily: [font-family stack]
    fontSize: [N]px
    fontWeight: [N]
    lineHeight: [ratio]
    letterSpacing: [N]px
  # ... repeat for each token in scale

rounded:
  xs: [N]px
  sm: [N]px
  md: [N]px
  lg: [N]px
  xl: [N]px
  pill: 9999px

spacing:
  xxs: [N]px
  xs: [N]px
  sm: [N]px
  md: [N]px
  lg: [N]px
  xl: [N]px
  xxl: [N]px
  section: [N]px

components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: [N]px [N]px
  button-secondary:
    backgroundColor: "{colors.canvas}"
    textColor: "{colors.primary}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: [N]px [N]px
  card:
    backgroundColor: "{colors.[surface-token]}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.lg}"
    padding: [N]px
  text-input:
    backgroundColor: "{colors.[surface-token]}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: [N]px [N]px
  # Add more components as extracted
---

## Overview

[One paragraph describing the design language: dominant surface color, primary accent, typography personality, and the overall visual mood — e.g. dark/light, dense/airy, editorial/utilitarian.]

**Key Characteristics:**
- [Characteristic 1 — e.g. "Dark canvas: `{colors.canvas}` (#010102) as the system anchor"]
- [Characteristic 2 — e.g. "Single chromatic accent: `{colors.primary}` used only on CTAs and brand mark"]
- [Characteristic 3 — e.g. "Aggressive negative tracking: -3.0px at display-xl scale"]
- [Characteristic 4 — optional]
- [Characteristic 5 — optional]

## Colors

> **Source:** [e.g. "tailwind.config.ts `theme.extend.colors` + globals.css `:root` variables"]

### Brand & Accent
- **[Token label]** (`{colors.[key]}` — `#[hex]`): [One-line description of role and usage context.]

### Surface
- **Canvas** (`{colors.canvas}` — `#[hex]`): Default page background.
- **[Token label]** (`{colors.[key]}` — `#[hex]`): [Description.]

### Text
- **Ink** (`{colors.ink}` — `#[hex]`): Primary text color.
- **[Token label]** (`{colors.[key]}` — `#[hex]`): [Description — e.g. "Secondary text, helper copy."]

### Semantic
<!-- TODO: document error, success, warning colors and their usage contexts. If none extracted, remove this section. -->

## Typography

### Font Family

[Name the primary font(s) and their roles. Describe fallback stack. If the font is proprietary, recommend an open-source substitute.]

<!-- TODO: describe typographic personality — weight range, tracking conventions, any OpenType features used. -->

### Hierarchy

| Token | Size | Weight | Line Height | Letter Spacing | Use |
|---|---|---|---|---|---|
| `{typography.display-xl}` | [N]px | [N] | [ratio] | [N]px | [Use description] |
| `{typography.display-lg}` | [N]px | [N] | [ratio] | [N]px | [Use description] |
| `{typography.display-md}` | [N]px | [N] | [ratio] | [N]px | [Use description] |
| `{typography.heading-lg}` | [N]px | [N] | [ratio] | [N]px | [Use description] |
| `{typography.heading-md}` | [N]px | [N] | [ratio] | [N]px | [Use description] |
| `{typography.body-lg}` | [N]px | [N] | [ratio] | [N]px | [Use description] |
| `{typography.body}` | [N]px | [N] | [ratio] | [N]px | Default body |
| `{typography.body-sm}` | [N]px | [N] | [ratio] | [N]px | [Use description] |
| `{typography.caption}` | [N]px | [N] | [ratio] | [N]px | Captions, meta |
| `{typography.button}` | [N]px | [N] | [ratio] | [N]px | Button labels |

### Principles

<!-- TODO: describe typography rules — e.g. weight conventions, when to use negative tracking, tabular figures for numbers. -->

## Layout

### Spacing System

- **Base unit**: [N]px
- **Tokens**: `{spacing.xxs}` [N]px · `{spacing.xs}` [N]px · `{spacing.sm}` [N]px · `{spacing.md}` [N]px · `{spacing.lg}` [N]px · `{spacing.xl}` [N]px · `{spacing.xxl}` [N]px · `{spacing.section}` [N]px

### Grid & Container

<!-- TODO: describe max-width, column grid, card grid breakpoints. -->

### Whitespace Philosophy

<!-- TODO: describe how whitespace is used — generous/dense, section gaps, card padding conventions. -->

## Elevation & Depth

| Level | Treatment | Use |
|---|---|---|
| 0 | Flat | Default surface |
| 1 | <!-- TODO --> | Cards |
| 2 | <!-- TODO --> | Floating panels, modals |

<!-- TODO: describe whether the system uses shadows, surface lifts, or borders for depth. -->

## Shapes

### Border Radius Scale

| Token | Value | Use |
|---|---|---|
| `{rounded.xs}` | [N]px | Small chips, badges |
| `{rounded.sm}` | [N]px | Tags, inline elements |
| `{rounded.md}` | [N]px | Buttons, inputs |
| `{rounded.lg}` | [N]px | Cards, panels |
| `{rounded.xl}` | [N]px | Large containers |
| `{rounded.pill}` | 9999px | Pill buttons, status pills |

## Components

### Buttons

**`button-primary`**
- Background `{colors.primary}`, text `{colors.on-primary}`, type `{typography.button}`, padding [padding], rounded `{rounded.[key]}`.
- <!-- TODO: describe hover/pressed states if found. -->

**`button-secondary`**
- Background `{colors.canvas}`, text `{colors.primary}`, 1px solid `{colors.primary}` border, same geometry.
- <!-- TODO: describe hover state. -->

### Cards & Containers

**`card`**
- Background `{colors.[surface-token]}`, text `{colors.ink}`, type `{typography.body}`, rounded `{rounded.lg}`, padding [padding].
- <!-- TODO: describe border/shadow treatment. -->

### Inputs & Forms

**`text-input`**
- Background `{colors.[surface-token]}`, text `{colors.ink}`, type `{typography.body}`, rounded `{rounded.md}`, padding [padding].
- <!-- TODO: describe focus/error states. -->

### Navigation

<!-- TODO: describe the nav bar / sidebar pattern if extracted. -->

## Do's and Don'ts

### Do
<!-- TODO: add after reviewing the design in practice. Example: "Reserve {colors.primary} for CTAs only." -->

### Don't
<!-- TODO: add after reviewing the design in practice. Example: "Don't use pill buttons for destructive actions." -->

## Responsive Behavior

### Breakpoints

| Name | Width | Key Changes |
|---|---|---|
| Desktop | ≥1024px | Default layout |
| Tablet | 768–1023px | <!-- TODO --> |
| Mobile | <768px | <!-- TODO --> |

<!-- If Tailwind screens config was found, replace the table above with extracted breakpoints. -->

### Touch Targets
<!-- TODO: document minimum touch target sizes. -->

### Collapsing Strategy
<!-- TODO: describe how layout, typography, and navigation collapse across breakpoints. -->

## Iteration Guide

1. Focus on ONE component at a time.
2. Reference tokens directly (`{colors.primary}`, `{rounded.pill}`, `{typography.body}`).
3. Add new variants as separate component entries in the frontmatter `components:` block.
4. Keep this file in sync with implementation — update tokens when the implementation diverges.
5. When reusing this design system in another project, copy `references/DESIGN.md` and update only the tokens that differ.
```
