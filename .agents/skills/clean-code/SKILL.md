---
name: clean-code
description: Use when writing, reviewing, or improving code quality. Language-neutral checklist focused on naming, components, errors, tests, and maintainable boundaries.
version: 1.0.0-template
alwaysApply: false
---

# Clean Code

Use this skill as a lightweight quality checklist for any framework profile.

## Principles

- Names should reveal intent and be searchable.
- Components should do one thing at one abstraction level.
- Route/page layer should be thin; business UI logic belongs in screens.
- Server data belongs in query hooks (TanStack Query / useFetch), not in UI state stores.
- Third-party API details belong in `lib/api/` adapters.
- Comments should explain non-obvious why, not repeat what code says.
- Errors should be surfaced to the user (loading/error states); never silently fail.
- Tests should focus on behavior and important edge cases.

## Checklist

- Are component and function names specific enough to avoid reading the implementation first?
- Is business UI logic in screens, not in route/page files?
- Are API calls wrapped in `lib/api/` adapters with stable signatures?
- Are store files managing only UI state, not server responses?
- Are constants extracted to `src/constants/` rather than scattered as magic values?
- Are loading, empty, and error states handled explicitly in every data-fetching component?
- Are secrets, tokens, credentials, and PII excluded from logs, URLs, and committed files?
- Are tests or verification steps present for changed behavior in `lib/utils/`?

## Avoid

- Catch-all `utils` or `common` modules containing UI logic.
- Screen components over 300 lines without sub-component extraction.
- Silent fallback behavior that changes data or hides errors.
- Broad rewrites that make review harder without a clear benefit.
- Inline `axios.get()` calls inside components — use adapters.
