# Default potType to single_raised when not determinable

## Problem

When the hand parser cannot determine the pot type from preflop action (e.g., incomplete hand history), it defaults to `null`. Downstream consumers expect a non-null potType value. The most common pot type in live cash games is single_raised.

## Fix

In `src/services/hand.ts`, in the system prompt where potType is described (rule 9), add a fallback instruction: "If pot type cannot be determined from preflop action, default to single_raised." Also update the confidence flags example to show this case.

## Acceptance criteria

- potType defaults to `single_raised` when not determinable from preflop action
- A confidence flag is added when the default is used: `{ "field": "potType", "issue": "Pot type not determinable from action, defaulted to single_raised" }`
- Hands where potType IS determinable remain unaffected
