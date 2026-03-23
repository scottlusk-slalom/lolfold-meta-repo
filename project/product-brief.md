---
type: product_brief
status: draft
owner: "Scott Lusk"
created: 2026-03-22
updated: 2026-03-22
---

# Lolfold - Product Brief

## Product Overview

### Name
Lolfold

### Tagline
AI-powered live poker hand tracking and player scouting.

### Summary
Lolfold is a web app for live poker players who want to record hand histories at the table using quick shorthand notation, then have AI parse, standardize, and organize those hands into a searchable database.

Players type fast, messy notes between hands on their phone. The app turns those into structured, replayable hand records. Over time, it builds a profile on every opponent — aggregating hands played, tendencies noted, and tells observed. Players can search their database with natural language ("show me 3bet pots against Pete") or traditional filters (position, pot type, villain, etc.).

The app supports shared groups so friends can pool their hand data and collectively scout opponents.

## Value Proposition

### Problem Statement

#### Current State
Live poker players keep hand notes in their phone's Notes app or on paper. These notes are messy, unsearchable, and quickly forgotten. There's no easy way to look up "what did Pete do last time I 3bet him from the button?" without scrolling through pages of unstructured text. Existing poker tracking tools are designed for online play with automatic hand import — they don't solve the live player's input problem.

#### Desired State
A player types a quick shorthand note at the table, and within seconds has a fully structured hand record. Before sitting down at the next session, they can pull up any opponent's profile and see their tendencies, notable hands, and behavioral notes — all organized and searchable.

### Core Benefits

1. **Fast table-side input**: Shorthand notation designed for speed — record a hand in 30 seconds between deals
2. **AI-powered structure**: Messy notes become standardized, searchable hand records automatically
3. **Opponent intelligence**: Build scouting reports on players over time from hands + freeform notes
4. **Collaborative scouting**: Share a hand pool with friends to build larger sample sizes on common opponents

### Differentiation
Existing tools (PokerTracker, Hold'em Manager) are built for online poker with automatic hand history import. There is no good tool for live players who need to manually input hands quickly. Lolfold solves the input problem with shorthand notation + AI parsing, which doesn't exist in the market.

## Target Users

### Primary Users
- **Live poker regulars**: Play 1-3+ times per week at casinos or home games, want to track hands and opponents systematically
- **Home game groups**: Friends who play together regularly and want to share scouting intel on the wider player pool

## Core Capabilities

### Hand Recording & AI Parsing
Type shorthand at the table. AI expands it into a fully structured hand with positions, stack sizes, actions per street, and pot math.

### Player Tracking & Notes
Every player mentioned in a hand is tracked. Attach freeform notes (tells, tendencies, behavioral observations) to any player. View a player's full profile with summary stats and all recorded hands.

### Search & Filtering
Traditional filters: position, pot type (SRP, 3bet, 4bet), villain, pot size, street reached. Natural language AI search: "hands where I check-raised the turn against Tom."

### Hand Replayer
Visual table-top view of any structured hand. Click through action street by street. Shows stack sizes, blinds, pot, and only Hero's hole cards.

### Session Tracking
Group hands by poker session (date, location, stakes, buy-in). View session history as one way to browse hands.

## Technical Boundaries

### Platform & Environment
- **Supported platforms**: Web (mobile-first, responsive)
- **Deployment model**: AWS (us-west-2)
- **Key integrations**: Amazon Bedrock (Claude) for AI parsing/search/analysis

### Architectural Constraints
- Mobile-first — primary input happens on a phone at a poker table
- Google authentication
- No publicly accessible security group ingress (VPC CIDR + personal IP only)
- Terraform for all infrastructure

### Technical Architecture Reference
See: `architecture/` directory

## Scope Boundaries

### What This Product IS
- A hand recording and opponent tracking tool for live poker
- AI-assisted: parsing, search, and pattern recognition
- A collaborative scouting tool for groups of friends

### What This Product IS NOT
- An online poker HUD or real-time overlay
- A poker training tool or GTO solver
- A bankroll management or session P&L tracker (session tracking is for hand organization, not accounting)
- A social network or public-facing platform

## References

- **Architecture**: `./architecture/`
- **Requirements**: `./requirements/`

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-03-22 | Scott Lusk | Initial draft from requirements discussion |
