# Parameterization requirements
Read target identifiers from validated configuration. Business dates must be explicit parameters, not hidden literals or CURRENT_DATE when reproducibility matters. Use bound values and validated identifiers. Never interpolate display names or untrusted text into SQL. Credentials belong in approved secret management, never code or reports.
