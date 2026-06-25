---
name: copy-page-with-code
applies_when:
  spec_section: "## Visual Reference"
  visual_reference_has: source
skip_when:
  spec_tags_any: [api-only, worker]
requires:
  - dev-server
  - playwright
injects_into: execute
---

# Copy Page with Code

Five-phase instructions for replicating a UI page when source code and a running instance are both available.

## Phase 1: Visual Capture

1. Start the reference application
2. Navigate to the target page
3. Capture full-page screenshot
4. Extract layout metrics:

```javascript
// Generic DOM/CSS measurement script
const metrics = await page.evaluate(() => {
  const el = document.querySelector('[data-testid="target"]');
  const styles = getComputedStyle(el);
  return {
    width: el.offsetWidth,
    height: el.offsetHeight,
    padding: styles.padding,
    margin: styles.margin,
    gap: styles.gap,
    fontSize: styles.fontSize,
  };
});
```

## Phase 2: Code Analysis

1. Locate the source component file
2. Map imports and dependencies
3. Identify:
   - State management patterns
   - API call patterns
   - Conditional rendering logic
   - Event handlers

## Phase 3: Architecture Mapping

| Issue | Pattern | Resolution |
|-------|---------|-----------|
| God component (>300 LOC) | Split into container + presentational | Extract sub-components |
| Inline styles | Map to design tokens | Use `<spacing-token>`, `<font-size-token>` |
| Direct DOM manipulation | Replace with framework idioms | Use refs or state |
| Hardcoded values | Extract to constants/config | Use theme/config |

## Phase 4: TDD Implementation

1. Write visual regression test with `toHaveScreenshot()`
2. Write interaction tests for all user flows
3. Implement component structure
4. Apply design tokens (generalized):
   - Spacing: `<spacing-token>`
   - Typography: `<font-size-token>`
   - Colors: `<color-token>`
5. Pass all tests

## Phase 5: Visual Regression Gate

```typescript
await expect(page.locator('[data-testid="target"]')).toHaveScreenshot(
  'target-page.png',
  { maxDiffPixelRatio: 0.01 }
);
```

## Output

Write findings to `_visual-notes.md`:
```markdown
## Visual Notes — <page-name>

### Layout Metrics
- Container: <width> x <height>
- Spacing: <values>
- Typography: <values>

### Architecture Issues Found
| Issue | Resolution |
|-------|-----------|

### Token Mapping
| Source Value | Target Token |
|-------------|-------------|
```
