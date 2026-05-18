"""
Production Confluence chatbot for Northwind.
Built from scope-2026-04-22.md + decisions.md (per-user-token decision, 2026-04-25).
This is a CLEANROOM rebuild — no reference to POC code.
"""
import logging
import os
from typing import Optional

# Per decisions.md 2026-04-25: per-user OAuth tokens via Okta, NOT service account.
# stack.md POC learnings: Confluence /content/search inherits requester ACLs.

class ConfluenceChatbot:
    def __init__(self, okta_client, confluence_client, audit_logger):
        self.okta = okta_client
        self.confluence = confluence_client
        self.audit = audit_logger

    def answer(self, user_id: str, question: str) -> Optional[str]:
        # Real implementation:
        # 1. Get user's Confluence token via Okta token exchange (refresh if expired)
        # 2. confluence.search(question, token=user_token) — ACL enforcement is automatic
        # 3. Audit log: who queried what, when, which pages returned
        # 4. LLM call with retrieved pages as context
        # 5. Return answer + cite pages
        token = self.okta.exchange_for_confluence(user_id)
        pages = self.confluence.search(question, token=token, space="OPSSOP", limit=3)
        self.audit.log(user_id=user_id, question=question, pages=[p.id for p in pages])
        # ...
        return None  # stub
