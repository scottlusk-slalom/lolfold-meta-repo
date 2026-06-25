---
type: prd
status: draft
owner: "Scott Lusk"
created: 2026-03-22
updated: 2026-06-25
related_specs: []
---

# Lolfold Core - Product Requirements Document

## Overview

### Problem Statement
Live poker players have no efficient way to record, organize, and analyze hand histories at the table. Notes apps are unstructured. Existing poker software assumes online play with automatic hand imports.

### Solution Summary
A mobile-first web app where players type shorthand hand histories at the table, AI parses them into structured records, and the app organizes everything into a searchable database with player profiles, session history, and a visual hand replayer.

## Target Users

### Primary Users
- **Live poker players**: Record hands and scout opponents at $1/$3 to $5/$10+ NLHE games
- **Poker friend groups**: Share hand databases to collectively scout a player pool

## Requirements

### Must Have

#### Hand Input & AI Parsing
- **REQ-001**: Users can type a hand in shorthand notation and submit it
- **REQ-002**: AI parses shorthand into a structured hand record with: hero identity, villain names, positions, stack sizes, blind/straddle structure, and street-by-street actions with exact bet sizes
- **REQ-003**: Support for multiway pots (3+ players)
- **REQ-004**: Support for game variants — multiple blinds, straddles, various buy-in amounts, carnival games (7-2 bounty, SB game, bounty game)
- **REQ-005**: User can view the original raw note alongside the parsed hand

#### Player Tracking
- **REQ-006**: Any player name mentioned in a hand is automatically tracked as a player entity
- **REQ-007**: Player profile page shows: summary of hands recorded, high-level strategy notes, and links to all hands involving that player
- **REQ-008**: Users can add freeform notes to a player — tells, tendencies, behavioral observations

#### Search & Filtering
- **REQ-009**: Traditional filter controls: filter hands by villain, hero position, pot type (SRP, 3bet pot, 4bet pot), number of players, street reached
- **REQ-010**: AI-powered natural language search across hands and notes

#### Hand Replayer
- **REQ-011**: Visual top-down table view showing player positions, stack sizes, blinds, and pot
- **REQ-012**: Click-through action replay — step through preflop, flop, turn, river with action-by-action detail
- **REQ-013**: Only Hero's hole cards are shown face-up; villain cards are hidden unless showdown occurred

#### Authentication & Sharing
- **REQ-014**: Google authentication via Amazon Cognito
- **REQ-015**: Each hand records which user was Hero
- **REQ-016**: All users share a single hand pool (v1 — group management is a future enhancement)

#### Session Tracking
- **REQ-017**: Hands can be grouped into sessions (date, location, stakes, game type)
- **REQ-018**: Session list view for browsing hands by session

#### Parsing Confidence & Ambiguity Handling
- **REQ-019**: AI parsing shows confidence indicators — highlights parts it's unsure about
- **REQ-020**: When AI cannot parse input, it returns a clear explanation of what it couldn't figure out

#### Player Intelligence
- **REQ-021**: Auto-generated player tendencies from recorded hands
- **REQ-022**: Player comparison — side-by-side view of two players' tendencies
- **REQ-023**: Player tags/archetypes — manually label or accept AI-suggested labels
- **REQ-024**: "Last seen" and session frequency per player
- **REQ-025**: Disambiguation of player names (merge suggestions for similar names)

#### Hand Analysis & Review
- **REQ-026**: Hand annotation — add post-session analysis notes to any hand
- **REQ-027**: "Hands like this" — find similar hands by villain, board texture, action pattern

#### Group Features
- **REQ-028**: Group activity feed — see when friends record hands against known players
- **REQ-029**: Decision point quiz — hide result at a key decision point, other users vote on action (stretch goal v1.01)

### Should Have

- **REQ-030**: Hand tagging — custom labels for personal organization
- **REQ-031**: Quick-start buttons for common spot types

### Could Have

- **REQ-032**: Export hands to standard format
- **REQ-033**: Session P&L tracking (buy-in, cash-out, hours played)
- **REQ-034**: AI hand review — "was my line good here?" sanity check

### Won't Have (Out of Scope)

- Real-time HUD overlays
- GTO solver integration
- Bankroll management
- Public player profiles or social features
- Native mobile apps (web only)
- Voice input

## Key User Flows

### Flow 1: Record a Hand at the Table
1. User opens app on phone, current session is active
2. User taps "New Hand" and types shorthand in text input
3. User submits — AI parses the shorthand
4. Parsed hand is shown for review (structured format)
5. User confirms or edits, hand is saved to database
6. Any new player names are auto-created as player profiles

### Flow 2: Scout an Opponent Before a Session
1. User opens app and searches for a player by name
2. Player profile shows: hand count, AI summary of tendencies, recent notes
3. User taps into specific hands to review details or use replayer
4. User adds a new note if they have fresh intel

### Flow 3: Post-Session Review
1. User browses hands from their most recent session
2. Uses replayer to step through interesting hands
3. Adds annotations to hands with their own analysis
4. Adds notes to player profiles based on observations
5. Uses AI search to find patterns

## UI/UX Considerations

- **Mobile-first**: Primary use is on a phone at a poker table. Input must be fast, one-handed friendly
- **Dark mode**: Poker rooms are dark; bright screens are distracting
- **Minimal taps**: Getting to "type a hand" should be 1 tap from the main screen
- **Offline resilience**: Handle spotty casino WiFi gracefully (queue submissions, don't lose input)

## Technical Considerations

### Performance
- Hand parsing should return in under 3 seconds (Bedrock/Claude latency)
- Hand list and filters should feel instant (client-side filtering where possible)

### Security
- Google auth only, no password management
- All data encrypted at rest
- No public ingress — VPC CIDR + personal IP only

### Integration Points
- Amazon Bedrock (Claude) for: hand parsing, natural language search, player analysis
- Amazon Cognito for Google OAuth
- PostgreSQL for data storage

## Resolved Decisions

1. **Database**: PostgreSQL — query patterns favor relational
2. **Parsing approach**: Recommended format + AI flexibility. AI interprets variations; surfaces ambiguity rather than guessing
3. **Offline**: Graceful degradation only. Don't lose text input if connection drops. No local-first architecture.
4. **Backend**: Node.js/Express + TypeScript. Same language as frontend, good Bedrock SDK support.

## Revision History
- **2026-03-22**: Initial draft
- **2026-06-25**: Migrated to new meta-repo harness
