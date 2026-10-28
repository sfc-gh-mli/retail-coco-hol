---
name: hol-deployment-review
description: "Review HOL SQL before deployment for team naming, efficiency and parameterization conventions. Use for pre-deployment review, review this transformation, and readiness checks. Does not deploy."
---
# Deployment review

1. Read the target code and project AGENTS.md. Do not execute or edit.
2. Load [naming](resources/naming.md), [performance](resources/performance.md), and [parameterization](resources/parameterization.md).
3. Confirm exact sandbox scope, output grain, business definitions and tests.
4. Report each finding: severity, file:line, evidence, violated rule, proposed fix, and validation needed.
5. Separate verified correctness issues from performance hypotheses. If no findings, say so and list test gaps.
6. Stop for approval before any edits. Deployment is a separate action.
