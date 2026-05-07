# Security Review Checklist

Loaded on demand during code reviews that touch auth, data handling, or external calls.

## Input validation
- [ ] All user input validated at system boundaries
- [ ] No string concatenation into SQL, shell commands, or HTML
- [ ] File paths sanitised (no path traversal: `../`)
- [ ] Integer bounds checked where relevant

## Authentication and authorisation
- [ ] Auth checks present on every protected endpoint
- [ ] Tokens / session IDs not logged
- [ ] Password fields excluded from serialisation
- [ ] Role checks correct (not just "is logged in", but "has this permission")

## Secrets
- [ ] No hardcoded credentials, tokens, or API keys
- [ ] Secrets loaded from environment or secret manager, not config files
- [ ] `.env` files in `.gitignore`

## Dependencies
- [ ] No new dependencies with known CVEs
- [ ] Pinned versions where possible
- [ ] No `eval()` or `exec()` on untrusted input

## Error handling
- [ ] Errors logged server-side, not exposed to client
- [ ] Stack traces not leaked in API responses
- [ ] Sensitive data not included in error messages
