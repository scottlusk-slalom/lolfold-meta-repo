# Default straddle to false when not specified

## Problem

When the hand parser cannot determine whether a straddle was posted, the
`metadata.straddle` field can come back missing/undefined. Downstream code
expects a boolean.

## Fix

In `src/services/hand.ts`, ensure the parser's system prompt instructs that
`metadata.straddle` defaults to `false` when no straddle is mentioned in the
input. Add a brief note to the relevant rule in the prompt.

## Acceptance criteria

- The system prompt states straddle defaults to `false` when not mentioned
- A test pins that the prompt contains this instruction
- No change to hands that explicitly mention a straddle
