# STITCH_FIDELITY_RULES.md — Pixel-to-Pixel Visual Fidelity Rules

## Purpose & Mandate

This file defines the **mandatory visual fidelity and layout rules** for implementing Google Stitch designs in Flutter across all viewports (Mobile, Tablet, Desktop Web).

**MANDATORY RULE:** 
> **Every agent working on this repository MUST read this file completely BEFORE implementing or modifying any UI screen or component.**
> 
> Stitch designs are the **absolute visual and interaction source of truth**. You must reproduce the exact layout geometry, visual hierarchy, element placement, typography, and styling down to the pixel. 
> 
> **NEVER substitute generic Material Design component templates for the approved Stitch layout.**

---

## 1. The Core Trap: Generic Templates vs. Stitch Geometry

The most common visual fidelity failure is relying on a mental model of "generic Material administration dashboards" rather than dissecting the actual geometry of the Stitch screen.

### Example: The Inverted KPI Card Failure
| Element | Generic Material Dashboard (INCORRECT) | Approved Stitch Design (MANDATORY) |
| :--- | :--- | :--- |
| **Top Left** | Icon container | **Metric Title** (15px semibold, wraps cleanly) |
| **Top Right** | Status Chip / Tag | **Icon Container** (38–40dp rounded box, 10px radius, semantic tint) |
| **Middle** | Big number only (always black) | **Large Metric Value** (36px bold) + **INLINE BADGE** directly adjacent (e.g., `95.3%` or `Requires triage`) |
| **Middle Accent** | No semantic color on numbers | **Semantic Coloring on Data** (e.g., Suspended count is **bold crimson red `#ba1a1a`**) |
| **Below Number** | Plain text title & subtitle | **Dedicated Bottom Row**: 6px status dot (🟢/🔴) or icon (🌐/🪪) + supporting metadata |

**Rule:** Design tokens (colors, radii, typography) control *styling*. They do NOT dictate *layout composition*. Always inspect where elements sit relative to each other inside every container.

---

## 2. The 5-Point Component Decomposition Protocol

Before writing Flutter code for **any** visual component or card, execute this 5-point layout decomposition:

### 1. Top Row / Component Header
- What sits on the top-left? (Title, label, code badge, or icon?)
- What sits on the top-right? (Action button, icon box, chevron, or menu?)
- What is the exact padding and vertical alignment?

### 2. Middle Row / Primary Data Body
- How is the primary data styled? (Font family, size, weight, line-height, letter-spacing?)
- Does the data use semantic coloring? (e.g., `#ba1a1a` for urgent/suspended, `#0f8b4d` for success/active, `#191c20` for neutral?)
- Are there **inline badges** placed directly next to the primary metric in a `Row`? (Never move inline badges to the corner of the card if Stitch shows them beside the number).

### 3. Bottom Row / Component Footer
- Is there a status indicator dot? (6px circular colored dot: `#0f8b4d` active, `#ba1a1a` urgent).
- Is there a leading metadata icon? (e.g., globe, id-badge, clock, building).
- What is the font size, weight, and color of the supporting text? (`Inter`, 12px, `#43474e` / `#737685`).

### 4. Container Surface & Elevation
- Background color: Level 1 white surface (`AppColors.surfaceContainerLowest`, `#ffffff`).
- Border: 1px solid subtle outline (`AppColors.outlineSubtle`, `#e2e5eb`). Never use heavy dark borders.
- Border radius: 12px–14px (`AppSpacing.roundedMd`).
- Shadow: Level 1 ambient diffused shadow (`box-shadow: 0 1px 3px rgba(25, 28, 32, 0.05), 0 1px 2px rgba(25, 28, 32, 0.03)`).

### 5. Spacing, Margins & Aspect Ratios
- Internal padding: 20px–24px.
- Gutters between sibling cards: 24px on desktop (`AppSpacing.xl`), 16px on mobile (`AppSpacing.md`).
- Overall page envelope: Constrained centered width (`maxWidth: 1440` on desktop web) with 32px outer padding (`AppSpacing.xxl`).

---

## 3. Stitch Screen Layout Rules by Section

### A. Navigation & Application Shell
- **Desktop Sidebar (260dp width)**:
  - White surface (`#ffffff`) bounded by a 1px right border (`#e2e5eb`).
  - Brand header: 38x38dp blue container (`#004ac6`), "Ops Hub" (16px bold `#191c20`), subtitle "MANAGEMENT" (10px `JetBrains Mono` bold `#004ac6`, letter-spacing 0.8px).
  - Active nav item: Elongated pill indicator (`#d9e2ff`), icon & text `#001945` (14px semibold).
  - Inactive nav item: Icon & text `#43474e` (14px medium) with subtle hover state.
  - **No profile at bottom of sidebar**: The user profile is strictly located in the Top Console Header bar on the right.
- **Top Platform Console Bar (Desktop & Medium >=600dp)**:
  - Height 60dp, white surface (`#ffffff`), 1px bottom border (`#e2e5eb`).
  - Left: "Operations Hub" (16px bold `#191c20`) + uppercase role console pill badge (e.g., `PLATFORM CONSOLE`, `ORGANIZATION CONSOLE`, `BRANCH OPERATIONS`, `EMPLOYEE PORTAL` in `JetBrains Mono` 10px bold `#003ea8` on `#dbe1ff` container).
  - Right: **User Profile Section** (Name in 13px bold `#191c20`, role subtitle in 11px `#004ac6`, and circular blue avatar 34dp `#003594` with white person icon).
- **Mobile & Tablet Header Bar (Compact <600dp and Medium 600–839dp)**:
  - Top AppBar with hamburger button on the left, centered WorkAxis branding, and **Profile Icon on the right** (`Icons.person` circular blue avatar).
  - **No standalone Sign Out icon button in the header**: Sign Out is integrated within the Profile Icon's dropdown menu.
  - **No profile or Sign Out at bottom of side pane**: Both the collapsible drawer (phone/tablet) and desktop sidebar are strictly dedicated to navigation destinations, with no profile or signout at the bottom.

### B. Page Headers
- **Eyebrow Category Tag**: Uppercase, 11px bold, letter-spacing 1.2px, color `#515f74` (e.g., `PLATFORM ADMINISTRATION`).
- **Headline**: 32px bold (`#191c20`, line-height 40px, letter-spacing -0.5px) on desktop; 24px bold on mobile.
- **Subtitle**: 14px regular (`#43474e`, line-height 20px).
- **Primary Action Button**: 48dp height, 8px corner radius, background `#004ac6`, white text 14px medium, 18px leading icon.

### C. Data Tables & Record Panels
- Single cohesive white panel container (`#ffffff`, 12px radius, 1px border `#e2e5eb`, Level 1 ambient shadow).
- **Panel Header**: Section title (18px bold), subtitle (13px secondary), right-aligned action link (e.g. "View All" with arrow).
- **Header Row**: `#f2f4f6` background, 11px uppercase bold labels (`#515f74`), letter-spacing 0.6px.
- **Monospace Badges**: Organization/Branch/Employee codes rendered in `JetBrains Mono` 11px bold (`#004ac6`) inside a `#f2f4f6` container with 4px radius and 1px border.
- **Status Chips**: 28dp pill with 6px circular dot on the left.
  - Active: `#e6f7ee` container, `#0f8b4d` text & dot, `#a7f3d0` border.
  - Suspended / Urgent: `#ffdad6` container, `#ba1a1a` text & dot, `#fecaca` border.
  - Pending: `#fff4e5` container, `#b26200` text & dot, `#fde68a` border.
- **Panel Footer**: "Showing X records" count + navigation link to full module.

---

## 3.1 Mandatory Canonical Templates (Reuse & Multi-Form-Factor Consistency)

To ensure pixel-perfect fidelity and absolute consistency across all screens without code duplication, **agents must use the canonical reusable templates in `lib/core/widgets/`**:

1. **`AppKpiCard` (`lib/core/widgets/kpi/app_kpi_card.dart`)**:
   - Strictly enforces the Stitch 3-row layout (Top Row title + icon container, Middle Row metric + inline badge, Bottom Row status dot + metadata).
   - Zero custom KPI card boilerplate allowed.
2. **`ResponsiveKpiSection` (`lib/core/widgets/kpi/responsive_kpi_section.dart`)**:
   - **Smartphone (<600dp)**: Full-width swipeable carousel (`PageView` with `viewportFraction: 1.0` and animated dots), spanning 100% width matching recent lists.
   - **Tablet (600–839dp)**: Balanced 2-column grid (`Row`s of 2 `Expanded` cards) filling 100% width.
   - **Desktop (>=840dp)**: Balanced N-column flex row (`Row` of `Expanded` cards) filling 100% width.
3. **`AppButton` (`lib/core/widgets/app_button.dart`)**:
   - `AppButton.primary`, `AppButton.secondary`, `AppButton.outlined`, and `AppButton.responsive`.
   - Guaranteed 48dp minimum touch target, built-in loading state, and container-safe bounded-width protection.
4. **`AppTextField` & `AppPasswordField` (`lib/core/widgets/app_text_field.dart`)**:
   - Standard M3 outlined inputs, `AppTextField.search` with search prefix, and `AppPasswordField` with integrated visibility toggle.
5. **`AppPageHeader` (`lib/core/widgets/app_page_header.dart`)**:
   - Canonical screen headline, eyebrow category tag, subtitle, and adaptive action button placement (inline on tablet/desktop, stacked full-width below on smartphone).

---

## 4. Pre-Implementation Checklist

Before committing any UI code, check off every item:

- [ ] **Visual Hierarchy Checked**: Have you checked what is on top-left, top-right, center, and bottom of each card?
- [ ] **No Generic Inversion**: Did you verify that titles, icons, and status chips are not placed according to generic admin templates?
- [ ] **Inline Badges Verified**: Are badges placed directly beside numbers when shown in Stitch?
- [ ] **Data Coloring Verified**: Are urgent, suspended, or critical numbers styled with semantic colors (`#ba1a1a`)?
- [ ] **Typography Scale Grounded**: Are you using `Inter` for UI text and `JetBrains Mono` for IDs, codes, and metrics?
- [ ] **Surfaces & Borders Exact**: Are cards using `#ffffff`, 1px `#e2e5eb` stroke, 12px radius, and subtle ambient shadows?
- [ ] **Responsive Adaptation Verified**: Does the layout adapt cleanly to Phone (<600dp), Tablet (600–839dp), and Desktop (>840dp) without overflow?
- [ ] **Formatting & Lints Clean**: Does `flutter analyze` report 0 issues and `dart format .` format cleanly?
- [ ] **All Tests Passing**: Do all unit, widget, and layout tests pass?
