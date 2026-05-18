# POC: Confluence chatbot wedge
**Date:** 2026-04-25
**FDE:** Dan Cleary
**Purpose:** feasibility
**Source scope:** scope-2026-04-22.md

## What this proves
ACL-aware retrieval via per-user Confluence tokens IS feasible — the API returns only pages the token holder can see, so retrieval inherits ACLs for free.

## How to demo it
`python chatbot.py "how do I unlock a stuck PO?"` — uses Maya's token.

## Shortcuts taken (do NOT carry to prod)
- Hardcoded: Maya's Confluence token, Ops SOP space key
- Faked: nothing — real API calls (token is fake here but pattern is real)
- Skipped: per-user token rotation, audit logging, multi-user UX

## What would need to change for production
- Per-user OAuth flow via Okta (stack.md mentions Okta)
- Token refresh and storage
- Audit log for every retrieval
- ACL test suite (5 negative queries × multiple users)
