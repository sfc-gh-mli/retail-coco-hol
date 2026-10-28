# HOL project conventions

Use Plan before multi-step changes. Read the generated lab-config.json for the approved database, schema, role and warehouse. Never infer that an existing connection is the intended account.

- Only synthetic SOURCE tables may be read; only the participant's allocated schema may be written.
- Use uppercase descriptive Snowflake identifiers and explicit column lists.
- Parameterize business cutoffs; use bound values or validated identifiers, never raw user text in SQL.
- Net spend in this simulated lab means SUM(AMOUNT) for COMPLETED transactions; canceled/refunded rows contribute zero.
- Preview edits/SQL and validate results against expected-results.json.
- Report evidence, not guessed performance improvements. No production access or permission changes.
- Keep secrets and private participant rosters out of source and reports.
- Publishing, email, schedules and cleanup require separate approval.
