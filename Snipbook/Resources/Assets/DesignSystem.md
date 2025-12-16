# Snipbook Design System

## Brand Identity

**Tagline:** "Little Moments, Cut & Kept"

**Personality:** Calm, tactile, analog, cozy, nostalgic

**Feeling:** Like sitting at a kitchen table with scissors, glue, and a stack of photos

---

## Color Palette

### Primary Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Terracotta** | `#D17B5D` | 209, 123, 93 | Primary accent, buttons, active states |
| **Warm Peach** | `#E8B89D` | 232, 184, 157 | Stamp shapes, secondary accent |
| **Cream** | `#F5EDE4` | 245, 237, 228 | Main background |

### Paper Textures

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Paper Cream** | `#FAF5EE` | 250, 245, 238 | Default page background |
| **Paper White** | `#FCFCFC` | 252, 252, 252 | Clean page option |
| **Paper Kraft** | `#D9C7B3` | 217, 199, 179 | Kraft/brown paper |
| **Paper Gray** | `#F0F0F0` | 240, 240, 240 | Modern gray option |

### Neutral Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Charcoal** | `#3D4144` | 61, 65, 68 | Primary text |
| **Slate** | `#6B7075` | 107, 112, 117 | Secondary text |
| **Mist** | `#B8BCC0` | 184, 188, 192 | Disabled states, dividers |
| **Cloud** | `#E8EAEC` | 232, 234, 236 | Subtle backgrounds |

### Accent Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Sage** | `#7BA87B` | 123, 168, 123 | Success states, nature imagery |
| **Sky** | `#87ACBF` | 135, 172, 191 | Links, informational |
| **Sunshine** | `#F4D56B` | 244, 213, 107 | Highlights, warmth |

---

## Typography

### Font Stack

```
Primary: SF Pro Rounded (iOS system)
Fallback: -apple-system, system-ui
Serif accent: New York (iOS) / Georgia
```

### Type Scale

| Style | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| **Title Large** | 34pt | Semibold | 1.2 | Screen titles |
| **Title** | 28pt | Semibold | 1.2 | Section headers |
| **Headline** | 17pt | Semibold | 1.3 | Card titles |
| **Body** | 17pt | Regular | 1.4 | Main content |
| **Callout** | 16pt | Regular | 1.4 | Secondary content |
| **Subhead** | 15pt | Regular | 1.4 | Labels |
| **Footnote** | 13pt | Regular | 1.4 | Captions, metadata |
| **Caption** | 12pt | Regular | 1.3 | Small labels |

### Tagline Style

```
Font: New York (serif)
Style: Italic
Size: 14pt
Color: Slate (#6B7075)
```

---

## Spacing

### Base Unit: 8pt

| Token | Value | Usage |
|-------|-------|-------|
| `spacing-xs` | 4pt | Tight gaps |
| `spacing-sm` | 8pt | Related elements |
| `spacing-md` | 16pt | Standard gaps |
| `spacing-lg` | 24pt | Section spacing |
| `spacing-xl` | 32pt | Major sections |
| `spacing-2xl` | 48pt | Screen padding |

### Corner Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius-sm` | 4pt | Small buttons, tags |
| `radius-md` | 8pt | Cards, inputs |
| `radius-lg` | 16pt | Modals, large cards |
| `radius-xl` | 24pt | Floating action button |
| `radius-full` | 9999pt | Circles, pills |

---

## Shadows

### Elevation Levels

```css
/* Subtle - Cards, pages */
shadow-sm: 0 2px 8px rgba(0, 0, 0, 0.06)

/* Medium - Floating elements */
shadow-md: 0 4px 16px rgba(0, 0, 0, 0.10)

/* Strong - Modals, FAB */
shadow-lg: 0 8px 32px rgba(0, 0, 0, 0.15)

/* Snip shadow - For cut-out images */
shadow-snip: 2px 3px 8px rgba(0, 0, 0, 0.12)
```

---

## Icons

### Style Guidelines

- Line weight: 1.5pt - 2pt
- Corner radius: Rounded
- Style: SF Symbols preferred
- Size: 24pt standard, 20pt compact

### Core Icons

| Icon | SF Symbol | Usage |
|------|-----------|-------|
| Add | `plus` | Add new snip |
| Camera | `camera` | Take photo |
| Photos | `photo.on.rectangle` | Import from library |
| Scissors | `scissors` | App identity |
| Book | `book.pages` | Page count |
| Settings | `gearshape` | Settings |
| Close | `xmark` | Dismiss |
| Flip | `camera.rotate` | Switch camera |
| Undo | `arrow.counterclockwise` | Undo action |
| Export | `square.and.arrow.up` | Share/export |

---

## Shape Assets

### Shape Dimensions (relative)

| Shape | Aspect Ratio | Character |
|-------|--------------|-----------|
| **Postage Stamp** | 1:1.2 | Classic, nostalgic |
| **Circle** | 1:1 | Clean, modern |
| **Ticket** | 1:0.5 | Fun, eventful |
| **Label** | 1:0.45 | Organized, tagged |
| **Torn Paper** | ~1:1.1 | Organic, casual |
| **Rectangle** | 1:0.75 | Simple, versatile |

---

## Motion

### Timing

| Token | Duration | Usage |
|-------|----------|-------|
| `duration-fast` | 150ms | Micro-interactions |
| `duration-normal` | 250ms | Standard transitions |
| `duration-slow` | 400ms | Page transitions |

### Easing

```
ease-out: cubic-bezier(0.0, 0.0, 0.2, 1)  - Entering
ease-in: cubic-bezier(0.4, 0.0, 1, 1)     - Exiting
ease-in-out: cubic-bezier(0.4, 0.0, 0.2, 1) - Moving
spring: response 0.5, dampingFraction 0.7   - Playful
```

---

## Component Patterns

### Floating Action Button

```
Size: 60pt diameter
Color: Terracotta (#D17B5D)
Icon: plus (white)
Shadow: shadow-lg
Position: 24pt from bottom-right
```

### Page Card

```
Background: Paper texture color
Corner radius: 4pt (subtle)
Shadow: shadow-sm
Margin: 20pt horizontal
Height: 400pt
```

### Shape Picker Item

```
Size: ~100pt width
Border: 1.5pt when unselected
Border: 2.5pt Terracotta when selected
Background: Terracotta 10% opacity when selected
Corner radius: 12pt
```

---

## Accessibility

### Color Contrast

- All text meets WCAG AA (4.5:1 minimum)
- Interactive elements have visible focus states
- Don't rely on color alone for meaning

### Touch Targets

- Minimum: 44pt x 44pt
- Recommended: 48pt x 48pt for primary actions

### Motion

- Respect "Reduce Motion" system setting
- Provide static alternatives for animations
