---
name: code-review
description: |
  Reviews code changes for quality, security, and correctness. Use when the user
  says "review this", "check my PR", "look over these changes", "is this safe",
  or "what do you think of this code". Covers: logic errors, security issues,
  style violations, missing tests, and architectural concerns.
version: "1.0"
---

## Critical

- Never approve changes that introduce hardcoded credentials, tokens, or secrets
- Flag any SQL string concatenation (injection risk) — always recommend parameterised queries
- Do not suggest refactors outside the scope of the change being reviewed

## Instructions

1. Read the diff or changed files in full before commenting
2. Check for security issues first: injection, auth bypasses, exposed secrets, insecure defaults
3. Check logic correctness: edge cases, null handling, error propagation
4. Check test coverage: are new code paths tested? Are existing tests still valid?
5. Check style: does it match the project's conventions (see `.cursorrules` or `CLAUDE.md`)?
6. Summarise findings as: **Must fix** / **Should fix** / **Consider**
7. For each Must fix item, provide a concrete suggestion or corrected snippet

## Gotchas

- Reviewing a large diff all at once misses subtleties — read file by file, not the whole patch at once
- "No tests changed" is not the same as "tests still pass" — ask if the test suite was run
- Style issues are Should fix, not Must fix, unless the project has a strict linter that would fail CI

## Performance Notes

Take your time. Quality over speed. Do not skip the security pass even for small changes.
A missed injection vulnerability in a two-line change is still a vulnerability.

<!-- For deep reference material, see references/security-checklist.md -->
