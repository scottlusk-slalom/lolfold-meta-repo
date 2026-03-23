---
status: not_started
created: 2026-03-22
updated: 2026-03-23
---

# Hand Input & AI Parsing - Technical Implementation Plan

## Approach

Two-phase flow: input → parse → confirm → save.

Frontend sends raw shorthand text to the API. API sends it to Claude via Bedrock with a system prompt that defines the expected JSON output structure and includes examples. Claude returns structured data with confidence scoring. API validates the response and sends it back to the frontend for user confirmation. On confirm, the hand is saved with both raw input and structured data, and player records are auto-created/linked.

The prompt engineering is the hardest part. It needs examples of shorthand → structured output, explicit instructions to flag uncertainty rather than guess, and handling for edge cases (straddles, multiway, incomplete info).

## Key Decisions & Constraints

- Define the parsed_data JSON structure as part of this spec — it becomes the contract for the replayer (spec 07) and search (spec 06)
- Claude must return a confidence object with an overall score and per-field flags for uncertain parts
- When parsing fails, save the raw input as a Hand with parse_status="failed" — never lose user input
- Player names matched case-insensitively. Find-or-create on save. Proper dedup/merge comes in spec 05.
- Frontend must persist draft input in localStorage — if connection drops or page refreshes, the text survives
- Auto-correct and auto-capitalize must be disabled on the input field (shorthand fights autocorrect)
- The spec's shorthand examples (in the .spec.md) are the test cases for prompt engineering

## Milestones

- [ ] Parsed hand JSON structure defined (TypeScript types shared between API and frontend)
- [ ] API endpoints: POST /api/hands (parse), POST /api/hands/confirm (save)
- [ ] Claude system prompt producing correct structured output for common hand types
- [ ] Frontend hand input page with full-screen text area
- [ ] Frontend parse confirmation view with confidence indicators
- [ ] Hands saving correctly with raw input, parsed data, player links, and denormalized fields

## Affected Systems

- **lolfold-api** — Hand parsing endpoint, Bedrock prompt, hand/player creation logic
- **lolfold-frontend** — Hand input page, parse confirmation page

## Risks

| Risk | Mitigation |
|------|------------|
| Claude misparses hands frequently | Iterate on the prompt with real examples. Build a small test suite of shorthand samples. |
| Bedrock latency exceeds 3s | Show a loading indicator. Consider streaming if available. |

## Notes

- Start prompt engineering with the example from the spec (the "tom 20 co 1750e" hand). Get that working perfectly, then expand to multiway, straddles, etc.
- The parsed_data structure matters a lot — the replayer and search specs depend on it. Think carefully about how actions are represented (array of actions per street, each with player/type/amount).
