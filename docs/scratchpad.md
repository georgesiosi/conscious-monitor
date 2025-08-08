# Project Scratchpad

- Last updated: 2025-08-08 00:06:37 -06:00
- Mode: Executor

## Active Planning Tasks

1) Naming alignment and build scripts fix
   - Implementation plan: `docs/implementation-plan/naming-alignment-and-build-scripts.md`
   - Goal: Resolve FocusMonitor vs ConsciousMonitor inconsistencies, correct build/test scripts, and ensure docs and entitlements align.

2) Xcode run: sandbox xattr denial triage
   - Implementation plan: `docs/implementation-plan/xcode-sandbox-xattr-deny.md`
   - Goal: Ensure app launches cleanly from Xcode. Determine if the `Sandbox: xattr(...) deny(1) file-read-data` message is benign or symptomatic, and eliminate any misconfiguration causing it.

3) UI consistency audit and remediation
    - Implementation plan: `docs/implementation-plan/ui-consistency-audit.md`
    - Goal: Normalize styling to `DesignSystem` tokens, unify page background semantics, fix chart label contrast, standardize icon sizing and hover states, and resolve naming drift in Modern* components.
    - Progress (current slice):
      - Created branch `feature/ui-consistency-audit`.
      - Normalized `FloatingFocusView` to `DesignSystem` tokens.
      - Fixed `PieChartView` annotation text color to `DesignSystem.Colors.primaryText`.
      - Standardized `EventRow` icon sizing to `DesignSystem.Layout.iconSize` and added hover background using `DesignSystem.Colors.hoverBackground`.
      - Unified `AnalyticsTabView` background to `DesignSystem.Colors.contentBackground`.

## Notes & Insights

- `README.md` and Xcode project are `ConsciousMonitor`, but `package.json` and some files (e.g., `ConsciousMonitor/FocusMonitor.entitlements`) still reference `FocusMonitor`.
- The team relies on `package.json` scripts (CI/local). We must update them to target `ConsciousMonitor.xcodeproj` and the `ConsciousMonitor` scheme.
- Primary build remains via `ConsciousMonitor.xcodeproj/`.
- Chrome Automation permission and OpenAI API key handling should be clearly surfaced in settings/onboarding docs.
- Chosen bundle identifier base: `com.cstack.ConsciousMonitor`.

## Open Questions

- Canonical product name confirmed: "ConsciousMonitor" everywhere.
- Current bundle identifiers (from `ConsciousMonitor.xcodeproj/project.pbxproj`):
  - App: `com.FocusMonitor`
  - Unit tests: `gsd.FocusMonitor-v0Tests`
  - UI tests: `gsd.FocusMonitor-v0UITests`
- Recommendation: choose a reverse-DNS you control, e.g., `com.yourcompany.ConsciousMonitor` (or `com.faiacorp.ConsciousMonitor`), and align app + test target IDs accordingly. Confirm preferred domain before Executor proceeds.
  - Decision: use `com.cstack.ConsciousMonitor` for app; tests to use `com.cstack.ConsciousMonitorTests` and `com.cstack.ConsciousMonitorUITests`.

## Related Docs

- `ConsciousMonitor/ARCHITECTURE.md`
- `ConsciousMonitor/COMPONENTS.md`
- `ConsciousMonitor/sqlite-migration-plan.md`
- Root: `DEVELOPMENT.md`, `INSTALL.md`, `IMPLEMENTATION_SUMMARY.md`
