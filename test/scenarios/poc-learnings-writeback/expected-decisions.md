## 2026-04-25: Per-user Confluence tokens for chatbot retrieval
**Context:** Need ACL-aware retrieval over Confluence; POC validated approaches.
**Decision:** Use per-user Confluence OAuth tokens (via existing Okta SSO) rather than service-account + downstream ACL filter.
**Rationale:** Confluence's content-search API enforces ACLs when called with a user token — pages the user can't see don't surface. Service-account approach would require us to reimplement ACL logic correctly, which Tom Reilly explicitly flagged as the "fireable offense" risk class.
**Implications for /integrate:** Production must implement per-user OAuth flow via Okta, secure token storage, token refresh, and audit logging at retrieval time. Do NOT implement a downstream ACL filter — that's the wrong layer.

## Last Updated
<!-- Update this line whenever you edit this file -->

<!-- Format: ## YYYY-MM-DD: Decision title
What was decided, who decided it, and why. -->
