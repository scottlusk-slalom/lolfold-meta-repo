---
type: prd
status: draft
owner: "Scott Lusk"
created: 2026-03-22
updated: 2026-03-22
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
  - Acceptance: A text input accepts freeform shorthand, submits to AI for parsing
- **REQ-002**: AI parses shorthand into a structured hand record with: hero identity, villain names, positions, stack sizes, blind/straddle structure, and street-by-street actions with exact bet sizes
  - Acceptance: Parsed hand is presented to user for confirmation before saving
- **REQ-003**: Support for multiway pots (3+ players)
  - Acceptance: Hands with 3+ players are correctly parsed and stored
- **REQ-004**: Support for game variants — multiple blinds, straddles, various buy-in amounts, carnival games (7-2 bounty, SB game, bounty game)
  - Acceptance: Variant info is captured in hand metadata
- **REQ-005**: User can view the original raw note alongside the parsed hand
  - Acceptance: Raw input is stored and viewable on the hand detail screen

#### Player Tracking
- **REQ-006**: Any player name mentioned in a hand is automatically tracked as a player entity
  - Acceptance: New player profiles are created on first mention; subsequent mentions link to existing profile
- **REQ-007**: Player profile page shows: summary of hands recorded, high-level strategy notes, and links to all hands involving that player
  - Acceptance: Profile page renders with hand count, notes, and hand list
- **REQ-008**: Users can add freeform notes to a player — tells, tendencies, behavioral observations, unstructured comments
  - Acceptance: Notes are saved to the player profile with timestamps

#### Search & Filtering
- **REQ-009**: Traditional filter controls: filter hands by villain, hero position, pot type (SRP, 3bet pot, 4bet pot), number of players, street reached
  - Acceptance: Filters are combinable and update the hand list in real time
- **REQ-010**: AI-powered natural language search across hands and notes
  - Acceptance: User can type queries like "3bet pots involving Pete" and get relevant results

#### Hand Replayer
- **REQ-011**: Visual top-down table view showing player positions, stack sizes, blinds, and pot
  - Acceptance: Renders a poker table with labeled seats
- **REQ-012**: Click-through action replay — step through preflop, flop, turn, river with action-by-action detail
  - Acceptance: Each click advances one action, updating pot and stack displays
- **REQ-013**: Only Hero's hole cards are shown face-up; villain cards are hidden unless showdown occurred
  - Acceptance: Cards render correctly based on available information

#### Authentication & Sharing
- **REQ-014**: Google authentication via Amazon Cognito (deferred — will be added after core features are working, access restricted by IP for now)
  - Acceptance: Users can sign up and sign in with Google
- **REQ-015**: Each hand records which user was Hero
  - Acceptance: Hero identity is stored and displayed; hands from different users in a shared group are distinguishable
- **REQ-016**: All users share a single hand pool (v1 — group management is a future enhancement)
  - Acceptance: All users see the same hands and players

#### Session Tracking
- **REQ-017**: Hands can be grouped into sessions (date, location, stakes, game type)
  - Acceptance: Users can create a session and associate hands with it
- **REQ-018**: Session list view for browsing hands by session
  - Acceptance: Sessions are listed chronologically with hand counts

#### Parsing Confidence & Ambiguity Handling
- **REQ-019**: AI parsing shows confidence indicators — highlights parts it's unsure about and surfaces ambiguities to the user rather than guessing wrong
  - Acceptance: Parsed hand highlights uncertain fields; user can tap to clarify or correct
- **REQ-020**: When AI cannot parse input, it returns a clear explanation of what it couldn't figure out, with the original text preserved
  - Acceptance: Unparseable input is saved as a raw note, not silently dropped

#### Player Intelligence
- **REQ-021**: Auto-generated player tendencies — surface patterns even from small samples (e.g., "Pete has called your 3bets 6/7 times", "Tom has never check-raised the turn")
  - Acceptance: Player profile surfaces binary and frequency-based patterns when enough data exists
- **REQ-022**: Player comparison — side-by-side view of two players' tendencies
  - Acceptance: User can select two players and see stats/tendencies compared
- **REQ-023**: Player tags/archetypes — manually label players (tight-passive, LAG, calling station, etc.) or accept AI-suggested labels
  - Acceptance: Tags display on player profile and are filterable
- **REQ-024**: "Last seen" and session frequency per player — when you last played against them, how often they appear
  - Acceptance: Player profile shows last seen date and session count
- **REQ-025**: Disambiguation of player names (e.g., "Pete" vs "Peter" might be the same person)
  - Acceptance: System suggests merges for similar names; users can confirm

#### Hand Analysis & Review
- **REQ-026**: Hand annotation — add post-session analysis notes to any hand ("I think this was a mistake because...")
  - Acceptance: Annotations are distinct from the raw hand record and display alongside it
- **REQ-027**: "Hands like this" — from any hand, find similar hands by villain, board texture, action pattern, or spot type
  - Acceptance: Returns a relevant set of hands with explanation of why they're similar

#### Group Features
- **REQ-028**: Group activity feed — see when friends record hands against known players
  - Acceptance: Feed shows recent hand submissions from group members with player names highlighted
#### Stretch Goal (v1.01)
- **REQ-029**: Decision point quiz — when sharing a hand, option to hide the result at a key decision point (river jam, bluff-catch, etc.). Other users must vote/pick their action before seeing what actually happened and the real result
  - Acceptance: Sharer selects a decision point and hides the outcome. Viewer sees the hand up to that point, submits their choice, then sees the real result and the sharer's action. Votes are recorded and visible to the group.
  - Note: High-priority post-launch feature. Deferred from initial build to avoid blocking core hand-tracking loop.

### Should Have

- **REQ-030**: Hand tagging — users can tag hands with custom labels for personal organization
  - Acceptance: Tags are filterable and searchable
- **REQ-031**: Quick-start buttons for common spot types (SRP IP, SRP OOP, 3bet IP, 3bet OOP) as a future enhancement consideration
  - Acceptance: Deferred — evaluate after core hand input is working

### Could Have

- **REQ-032**: Export hands to a standard format (e.g., PokerStars-style hand history text)
- **REQ-033**: Session P&L tracking (buy-in, cash-out, hours played)
- **REQ-034**: AI hand review — "was my line good here?" sanity check (not a GTO solver)

### Won't Have (Out of Scope)

- Real-time HUD overlays
- GTO solver integration
- Bankroll management
- Public player profiles or social features
- Native mobile apps (web only for POC)
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
5. Uses AI search to find patterns ("did Tom always bet the turn when checked to?")

### Flow 4: Decision Point Quiz
1. User records a hand with an interesting decision point
2. When sharing, user selects the decision point (e.g., "facing all-in on the river")
3. User marks the hand as a quiz — outcome is hidden after the decision point
4. Group members see the hand up to the decision point in the activity feed
5. Each member votes on what they would do (call, fold, raise, etc.)
6. After voting, the real result is revealed along with how everyone voted
7. Group can discuss in annotations

## UI/UX Considerations

- **Mobile-first**: Primary use is on a phone at a poker table. Input must be fast, one-handed friendly
- **Dark mode**: Poker rooms are dark; bright screens are distracting and annoying to other players
- **Minimal taps**: Getting to "type a hand" should be 1 tap from the main screen
- **Offline resilience**: Should handle spotty casino WiFi gracefully (queue submissions, don't lose input)

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

## Open Questions

1. **Q**: DynamoDB vs PostgreSQL?
   - **Status**: Resolved — PostgreSQL. Query patterns (filter by position, pot type, villain, cross-hand aggregation) favor relational.

2. **Q**: Should the shorthand notation be strictly defined, or should AI handle any reasonable variation?
   - **Status**: Resolved — Recommended format + AI flexibility. AI should interpret reasonable variations. When it can't parse something, it should surface the ambiguity back to the user rather than guessing wrong.

3. **Q**: Offline support — full offline-first with local storage, or just graceful degradation?
   - **Status**: Resolved — Graceful degradation. Don't lose the text input if connection drops. No local-first architecture.

4. **Q**: Backend language?
   - **Status**: Resolved — Node.js/Express + TypeScript. Same language as frontend, simpler dependency story, good Bedrock SDK support.

## Revision History
- **2026-03-22**: Initial draft from requirements discussion
- **2026-03-22**: Resolved open questions (Postgres, Node/TS, AI-flexible parsing, graceful degradation). Added parsing confidence, player intelligence features, hand annotation, "hands like this", group activity feed, decision point quiz. Renumbered requirements.
