# AGENTS.md - Workspace Rules & Memory for ExpenseTrackerSwift

## 🎨 UI & Design System Rules: Light & Dark Mode Compatibility

> **MANDATORY:** All UI components, buttons, badges, and view layouts created or updated in this repository MUST comply with these Light/Dark mode contrast rules.

### 1. `Color.appPrimary` Usage Boundary
- `Color.appPrimary` is defined as a **foreground text/icon token** (Dark Charcoal `#18181B` in Light Mode, Near-White `#FAFAFA` in Dark Mode).
- 🚨 **NEVER** use `Color.appPrimary` as a background fill paired with hardcoded `.white` or `Color.white` text.
  - *Why:* In Dark Mode, `Color.appPrimary` becomes `#FAFAFA` (white), resulting in invisible white-on-white text.
- **Correct Usage:**
  - `Text("...").foregroundStyle(Color.appPrimary)`
  - For solid primary buttons, use `.background(Color.emeraldPrimary)` (or `.background(Color.appAccent)`) with `.foregroundStyle(.white)`.

### 2. High-Contrast Primary & Accent Surfaces
- Primary call-to-action buttons, active badges, and highlighted indicators MUST use `Color.emeraldPrimary` (or `Color.appAccent`).
- `Color.emeraldPrimary` (`#059669` in Light Mode, `#10B981` in Dark Mode) guarantees high contrast (≥ 4.5:1 WCAG AA) with white text across both appearances.

### 3. Standalone Financial Text Colors
- Avoid raw system `.green` (`#34C759`) for text on light backgrounds, as it yields a low contrast ratio (~2.4:1).
- Use `Color.emeraldPrimary` for positive financial figures, income indicators, and savings text.

### 4. Secondary Surfaces & Badges
- Text displayed over `Color.appLightGray` (`#F4F4F5` Light / `#27272A` Dark) MUST use `Color.appPrimary` to maintain readable contrast (≥ 4.5:1). Avoid using `Color.appSecondary` on `Color.appLightGray`.

### 5. Component & List Layout Uniformity Rules
- **Card Corner Radius Standard:** All list row items, summary cards, and content containers MUST use `AppRadius.card` (`16pt`) via `.appCardStyle()` or `RoundedRectangle(cornerRadius: AppRadius.card)` for visual consistency.
- **Card Padding Protocol:** `.appCardStyle()` automatically applies `AppSpacing.lg` (`16pt`) internal padding. NEVER apply extra `.padding(...)` before calling `.appCardStyle()` on a card component (prevents double-padding bugs).
- **Category & Row Icon Badges:** Use `CategoryIconBadge` (`40x40pt` circular container filled with `Color.appLightGray`) for all list item leading icons.
- **Progress Bars:** Standardize list and card progress indicators using `AppProgressBar` with a fixed `8pt` capsule height (`AppRow.progressBarHeight`).
- **Typography & Font Weight:** Use rounded font design `.font(.system(..., design: .rounded))` with `.fontWeight(.bold)` or `.fontWeight(.medium)` for card headers, category names, and currency amounts.
- **Currency & Theme Tokens:** NEVER hardcode currency symbols (e.g. `$`). Always format currency using `currencyManager.currencyCode` and use `Color.emeraldPrimary` for positive financial indicators instead of raw `.green`.
- **Flat Card Surface & No Drop Shadows:** Standard cards use crisp, subtle border stroke overlays (`lineWidth: 1`) on flat surfaces. Do NOT use heavy drop shadows (`.shadow(...)`) on list cards or toolbar items.


