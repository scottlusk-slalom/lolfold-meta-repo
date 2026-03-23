---
type: feature
status: completed
priority: high
created: 2026-03-22
updated: 2026-03-22
tags: ["search", "filtering", "ai-search", "core"]
related: ["04-hand-input-parsing", "05-player-tracking"]
---

# Search & Filtering Specification

## Problem Statement

Users need to find specific hands quickly. Sometimes they know exactly what they're looking for ("3bet pots against Pete") and sometimes they want to browse with traditional filters (position, pot type, street reached). Both modes need to feel fast and work well on mobile.

## Objectives

1. Traditional filter controls on the hands list: villain, hero position, pot type, number of players, street reached
2. AI-powered natural language search: type a query in plain English, get relevant hands back
3. "Hands like this" — from any hand, find similar hands
4. Filters should be combinable and update results in real time

## Success Criteria

### Traditional Filters
- [ ] Filter bar on the hands list with: villain (dropdown/search), hero position, pot type (SRP/3bet/4bet), num players, street reached
- [ ] Filters combine with AND logic
- [ ] Results update quickly (ideally client-side filtering for datasets under a few hundred hands)

### AI Search
- [ ] Search bar accepts natural language queries
- [ ] "3bet pots involving Pete" → returns matching hands
- [ ] "hands where I check-raised the turn" → works
- [ ] "times Tom bet big on the river" → works
- [ ] Results show relevance and why they matched

### Hands Like This
- [ ] From a hand detail view, "find similar hands" button
- [ ] Similarity based on: same villain, similar board texture, similar action pattern, same spot type
- [ ] Returns a list of hands with explanation of why they're similar

## Scope

### In Scope
- Hands list page with filter controls
- AI search endpoint and UI
- "Hands like this" feature
- Hand list item component (used across list, search results, player profile)

### Out of Scope
- Full-text search indexing (ElasticSearch, etc.) — overkill for POC volumes
- Saved searches or search history
- Advanced analytics dashboards

## Dependencies

- Spec 04 complete (hands exist with denormalized filter fields)
- Spec 05 complete (players exist for villain filter dropdown)

## References

- [Core PRD](../../../requirements/prd-core.md) — REQ-009, REQ-010, REQ-027
