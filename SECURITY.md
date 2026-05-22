# Security Policy

## Supported versions

This project is in initial extraction. Security fixes are accepted on the default branch until versioned releases are published.

## Reporting a vulnerability

Please report suspected vulnerabilities privately through the repository's security advisory flow when available. Include:

- Affected package, platform, and version or commit.
- Reproduction steps or a minimal fixture.
- Impact, expected behavior, and any suggested fix.

Do not open a public issue for an unpatched vulnerability.

Before public release, maintainers must enable the repository security advisory flow and GitHub security baseline for the final Microsoft-owned GitHub repository.

## Security expectations

- Do not commit secrets, internal URLs, telemetry keys, service endpoints, or private identifiers.
- Treat markdown input as untrusted content.
- Treat raw HTML and Mermaid input as untrusted content. This renderer exposes fallback rendering only; hosts should not execute scripts or fetch remote content on behalf of markdown.
- Route link handling through host-provided callbacks.
- Keep copy/export actions explicit and user initiated.
