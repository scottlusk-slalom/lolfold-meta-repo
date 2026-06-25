---
name: visual-reference-discovery
applies_when:
  spec_section: "## Visual Reference"
skip_when:
  spec_tags_any: [api-only, worker, migration]
  visual_reference_has: source
requires:
  - dev-server (option A only)
  - playwright (option A only)
injects_into: execute (before TDD cycle)
---

# Visual Reference Discovery

Discovery-only instructions for capturing visual patterns from a reference page before TDD implementation.

## Options

### Option A: Live URL + Playwright Capture

```typescript
// Capture script
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('<reference-url>');
  await page.screenshot({ path: '_visual-notes-capture.png', fullPage: true });

  // Extract metrics
  const metrics = await page.evaluate(() => ({
    // Measure key layout properties
  }));

  await browser.close();
})();
```

### Option B: Source File

Read the source component directly. Map:
- Layout structure (flex/grid, nesting)
- Design token usage
- Responsive breakpoints

### Option C: Mockup Image

Extract from the image:
- Approximate spacing and sizing
- Color palette
- Typography hierarchy
- Component boundaries

## What to Extract

| Element | Capture |
|---------|---------|
| Layout mode | flex/grid, direction, wrap |
| Spacing | gap, padding, margin values |
| Typography | font-size, weight, line-height, family |
| Colors | background, text, borders, accents |
| Breakpoints | responsive behavior at standard widths |
| Interactions | hover, focus, active states |

## TestId Wrapper Pattern

For components using `data-testid`:
```tsx
// Generic wrapper — adapt to <your component library>
function TestId({ id, children }) {
  return <div data-testid={id}>{children}</div>;
}
```

## Gate

If spec has `## UI Test IDs` section but NO `## Visual Reference` section:
→ **HALT** — visual reference is required before writing UI tests.

## Output

Write to `_visual-notes.md`:
```markdown
## Visual Discovery — <page/component>

### Source
- Type: [live URL | source file | mockup]
- Reference: <path or URL>

### Layout
- Mode: <flex|grid>
- Direction: <row|column>
- Spacing: <values>

### Typography
| Element | Size | Weight | Family |
|---------|------|--------|--------|

### Colors
| Usage | Value | Token |
|-------|-------|-------|

### Components Identified
- [ ] <component-1>
- [ ] <component-2>
```
