# Default blinds to $2/$5 instead of $1/$2

## Problem

When the hand parser cannot infer blind sizes from the input text, it defaults to $1/$2. This is almost never correct — the vast majority of hands played are $2/$5 live cash games.

## Fix

In `src/services/hand.ts`, change the fallback blinds from `{ "small": 1, "big": 2 }` to `{ "small": 2, "big": 5 }`. Update the corresponding validation warning message to say "defaulted to 2/5" instead of "defaulted to 1/2".

## Acceptance criteria

- Default blinds are $2/$5 when not inferable from input
- Validation warning reflects the new default
- Existing tests updated to expect 2/5
- Any test that explicitly sets blinds should be unaffected
