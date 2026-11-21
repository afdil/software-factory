# Design System — <Project Name>

- **Project Slug:** `<slug>`
- **Status:** `DRAFT` | `LOCKED`
- **Mockup Status:** `NOT_REQUIRED` | `DRAFT` | `LOCKED` (see `.factory/mockups/` if applicable)

---

## 1. Visual Direction & Aesthetic Thesis
- **Brand Tone:** (e.g., crisp editorial precision, utilitarian fintech calm, warm crafted studio — avoid generic default SaaS templates).
- **Theme Mode:** `light-default` | `dark-default` | `light-and-dark`
- **Density:** `compact` | `balanced` | `airy`

## 2. Color Palette & Semantic Tokens (CSS Variables / Tailwind)
Provide exact hex / HSL values mapped to CSS variables used by Tailwind and `shadcn-vue`:

```css
:root {
  --background: #ffffff;
  --foreground: #0f172a;
  --card: #f8fafc;
  --card-foreground: #0f172a;
  --primary: #...;
  --primary-foreground: #...;
  --secondary: #...;
  --secondary-foreground: #...;
  --muted: #...;
  --muted-foreground: #...;
  --accent: #...;
  --accent-foreground: #...;
  --destructive: #...;
  --border: #...;
  --ring: #...;
  --radius: 0.5rem;
}
```
*(Include `.dark { ... }` block if dark mode is enabled.)*

## 3. Typography
- **Display / Headings Font:** `<Font Name>` (weights, letter-spacing, line-height)
- **Body / UI Font:** `<Font Name>`
- **Monospace / Numbers Font:** `<Font Name>` (use `tabular-nums` for metrics/tables/currency)
- **Type Scale:** H1, H2, H3, Body, Small, Caption sizes & usage rules.

## 4. Spacing, Layout & Breakpoints
- Container max-width, sidebar width, header height, card padding, section vertical rhythm.
- Responsive rules: mobile (`375px`), tablet (`768px`), desktop (`1280px+`).

## 5. Component Standards (`shadcn-vue` + Custom)
- **Buttons:** Primary, Secondary, Ghost, Destructive, Loading state (MUST prevent double-submit).
- **Forms & Inputs:** Label placement, inline validation error styling, disabled/focus ring states.
- **Tables & Lists:** Empty state design, skeleton loading state, pagination/filter bar.
- **Feedback:** Toast positioning, confirmation dialogs for destructive actions.

## 6. Visual Do's & Don'ts
- **Do:** ...
- **Don't:** No generic blue/purple gradient hero slop, no unstyled browser alerts, no missing loading/empty states.

## 7. Locked Mockup References (If Applicable)
- `.factory/mockups/01-dashboard.html` — Approved layout & hierarchy for primary screen.
