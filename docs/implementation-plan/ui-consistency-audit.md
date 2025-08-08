# UI Consistency Audit and Remediation Plan

- Planner: Cascade
- Mode: Planner
- Created: 2025-08-08 00:02:01 -06:00
- Branch Name: feature/ui-consistency-audit

## Background and Motivation
A design system (`ConsciousMonitor/DesignSystem.swift`) exists and is widely used, but several views bypass tokens or use inconsistent semantics. Normalizing styling improves readability, accessibility, and velocity for future UI work.

## Key Challenges and Analysis
- Hardcoded styling in some views (e.g., `FloatingFocusView.swift`) for spacing, fonts, radii, and colors.
- Mixed page background tokens: `contentBackground` vs `primaryBackground` vs others, all mapped to the same system color, increasing semantic drift.
- Chart annotation foreground uses a background color, risking poor contrast on saturated slices.
- Icon sizes hardcoded at 20px in multiple places; token exists as `DesignSystem.Layout.iconSize`.
- Naming drift between "Modern*" components and their file/type names (e.g., `ContentView` uses `ModernAnalyticsTabView` but file present is `AnalyticsTabView.swift`).
- Hover affordances: `EventRow` has `isHovered` state but no hover background applied; token `hoverBackground` exists.
- Accessibility: accessible variants exist (e.g., `AccessibleStatCard`). Agree when to use them vs baseline components.

## High-level Task Breakdown
1) Create feature branch
   - Steps: create `feature/ui-consistency-audit` off `main`.
   - Success: branch exists; no file changes yet; CI green.

2) Normalize FloatingFocusView to DesignSystem
   - Steps: replace raw spacing, fonts, radii, and colors with `DesignSystem.Spacing`, `DesignSystem.Typography`, `DesignSystem.Layout`, `DesignSystem.Colors`.
   - Success: visual parity maintained; no hardcoded numbers left (except legitimate fixed layout widths if needed); passes build.

3) Fix PieChartView annotation contrast
   - Steps: change annotation `foregroundColor` to a contrast-safe token (temporary: `DesignSystem.Colors.primaryText`). Consider future contrast utility.
   - Success: labels legible in light/dark; build passes.

4) Standardize icon sizing in EventRow
   - Steps: replace `frame(width: 20, height: 20)` with `DesignSystem.Layout.iconSize` and align fallbacks.
   - Success: consistent icon size; no regressions.

5) Apply hover background to EventRow
   - Steps: use `DesignSystem.Colors.hoverBackground` when `isHovered` is true, with subtle animation if desired.
   - Success: clear hover affordance; meets HIG subtlety.

6) Unify page background token usage
   - Steps: decide a primary page background token. Proposal: use `DesignSystem.Colors.contentBackground` across top-level views.
   - Success: `ContentView`, `AnalyticsTabView`, `CategoryPickerView` all use the same token; visual parity maintained.

7) Decide and enforce background token semantics
   - Option A: keep multiple tokens but document intended usage; adjust their color values to differentiate surfaces (page vs card vs grouped).
   - Option B: simplify to fewer tokens (e.g., `appBackground`, `surface`, `hover`) and update design system.
   - Success: documented guidance in `DesignSystem.swift` comments; tokens consistently referenced in UI.

8) Resolve Modern* naming drift
   - Steps: confirm canonical names; either rename types to match files or rename files to match types. Update references.
   - Success: no mismatches between type names and file names; `ContentView` builds with resolved imports.

9) Accessibility policy for stat cards
   - Steps: choose default (`StatCard` with built-in traits or always use `AccessibleStatCard`). Implement chosen default or wrap accessibility into `StatCard`.
   - Success: consistent strategy documented in `AccessibilityEnhancements.swift` and applied in analytics views.

10) Add UI PR checklist and lintable guidelines
   - Steps: add a short checklist to `docs/` and reference it in PR template (if present). Optionally add a SwiftLint/SwiftFormat rule comment block for future automation.
   - Success: checklist exists; contributors follow token usage; spot-check passes.

## Acceptance Criteria
- No hardcoded spacing, radius, font, or color values in the touched views; all use `DesignSystem` tokens.
- Page backgrounds are unified to the decided token across audited views.
- Chart labels are legible in light and dark modes.
- Icon sizing uses `DesignSystem.Layout.iconSize` consistently in `EventRow`.
- Hover state visible for `EventRow` using `DesignSystem.Colors.hoverBackground`.
- Naming for “Modern*” components and files is consistent; build is green.
- Accessibility approach for stat cards is documented and applied.

## Project Status Board
- [x] Branch created
- [x] FloatingFocusView normalized
- [x] PieChartView annotation contrast fixed
- [x] EventRow icon sizing standardized
- [x] EventRow hover background applied
- [x] Background token unified across top-level views
- [ ] Token semantics decision documented and enforced
- [ ] Modern* naming drift resolved (partial: ModernActivityView → ActivityView, ModernAIInsightsView → AIInsightsView; ModernAnalyticsTabView pending due to name collision with existing AnalyticsTabView)
- [ ] Accessibility approach for stat cards decided and applied
- [ ] UI PR checklist added

## Executor's Feedback or Assistance Requests
- Confirm preference: keep multiple background tokens (and differentiate) vs simplify to fewer tokens.
- Confirm canonical naming for “Modern*” views (retain “Modern” prefixes or remove).
- Preference on accessible defaults: always use `AccessibleStatCard` or integrate traits into `StatCard` by default.

## Lessons Learned (to be populated by Executor)
- Record any visual regressions and resolutions.
- Note any HIG-specific adjustments made during normalization.
