---
name: refactor
description: Use for small, behavior-preserving refactors that improve maintainability without changing contracts. Language-neutral.
version: 1.0.0-template
alwaysApply: false
---

# Refactor

Use this skill to improve structure without changing observable behavior.

## When To Use

- Code is hard to read, duplicate, oversized, or difficult to change.
- User asks to clean up, simplify, rename, extract, or reorganize code.
- A feature change exposes unsafe coupling that should be reduced first.

## Rules

- Preserve behavior and public contracts.
- Do not mix refactoring with feature changes unless explicitly requested.
- Prefer small patches over rewrites.
- Keep dependency direction intact.
- Add or run tests when behavior preservation is not obvious.
- Do not move files across architectural layers without checking imports and runtime wiring.

## Common Moves

- Extract small functions for repeated or multi-step logic.
- Rename unclear variables/functions/components/modules.
- Split oversized screen components into smaller sub-components.
- Move repeated style objects into `src/constants/`.
- Move repeated JSX patterns into `src/components/{feature}/ui/`.
- Move utility functions into `src/lib/utils/` and add unit tests.
- Replace magic strings/numbers with named constants when they represent domain concepts.

## Done Criteria

- Behavior and contracts are unchanged.
- Relevant checks/tests pass or are documented as unavailable.
- Diff is smaller and clearer than the original shape.
- No unrelated formatting or broad rewrites are included.
