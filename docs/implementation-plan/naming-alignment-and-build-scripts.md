# Implementation Plan: Naming Alignment and Build Scripts

- Task Slug: naming-alignment-and-build-scripts
- Branch Name: chore/naming-alignment-and-build-scripts
- Owner: TBD
- Last Updated: 2025-08-07 19:13:20 -06:00

## Background and Motivation

The repository presents naming inconsistencies between "ConsciousMonitor" (canonical in `README.md` and Xcode project `ConsciousMonitor.xcodeproj/`) and legacy "FocusMonitor" references (e.g., `package.json` scripts, `ConsciousMonitor/FocusMonitor.entitlements`). These inconsistencies can break helper scripts, confuse contributors, and risk entitlement/bundle-mismatch at build/distribution time.

Aligning names, scripts, and docs will reduce friction for contributors and ensure repeatable builds.

## Key Challenges and Analysis

- Mixed naming across:
  - `package.json` (helper scripts point to `FocusMonitor.xcodeproj`)
  - Entitlements file named `FocusMonitor.entitlements` while the app is "ConsciousMonitor"
  - Documentation references to "FocusMonitor" under `docs/README.md`
- Risk that bundle identifier(s) and provisioning profiles rely on specific file names.
- Need to preserve App Sandbox/Automation permissions (Chrome integration) while renaming entitlements.
- Ensure CI or local xcodebuild invocations work post-change.
- Canonical product name confirmed by stakeholder: "ConsciousMonitor" everywhere.
- CI/local workflows rely on `package.json` scripts; they must be corrected and kept green.

Current bundle identifiers in `ConsciousMonitor.xcodeproj/project.pbxproj`:
- App: `com.FocusMonitor`
- Unit tests: `gsd.FocusMonitor-v0Tests`
- UI tests: `gsd.FocusMonitor-v0UITests`
Chosen canonical identifiers:
- App: `com.cstack.ConsciousMonitor`
- Unit tests: `com.cstack.ConsciousMonitorTests`
- UI tests: `com.cstack.ConsciousMonitorUITests`

## High-level Task Breakdown

1) Create Feature Branch
   - Command: `git checkout -b chore/naming-alignment-and-build-scripts`
   - Acceptance Criteria:
     - New branch created off `main`.

2) Audit Current Names and Identifiers
   - Search for "FocusMonitor" and "ConsciousMonitor" across repo.
   - Inventory: project file references, scheme names, target names, bundle IDs, entitlements path.
   - Acceptance Criteria:
     - A short inventory appended to this plan under "Current Status / Progress Tracking".

3) Update Helper Scripts (`package.json`)
   - Point scripts to `ConsciousMonitor.xcodeproj` and correct scheme (`ConsciousMonitor`).
   - Replace project description and name to match current app identity.
   - Acceptance Criteria:
     - `npm run build|test|clean` invoke xcodebuild successfully on the correct project.

4) Bundle Identifier Alignment
   - Use canonical reverse-DNS: `com.cstack.ConsciousMonitor` (app), `com.cstack.ConsciousMonitorTests`, `com.cstack.ConsciousMonitorUITests` (tests).
   - Update `PRODUCT_BUNDLE_IDENTIFIER` for app and test targets in the project to these exact values.
   - Update any signing settings/profiles as needed.
   - Acceptance Criteria:
     - Project builds under the new bundle identifiers in Xcode and via `npm run build`.
     - Test targets have matching, updated identifiers.

4) Entitlements Alignment
   - Option A: Rename `ConsciousMonitor/FocusMonitor.entitlements` to `ConsciousMonitor/ConsciousMonitor.entitlements`.
   - Update Xcode project build settings to reference the new entitlements file.
   - Verify capabilities (Automation for Chrome, etc.) remain intact.
    - Acceptance Criteria:
      - Build succeeds in Xcode and via xcodebuild; app still prompts for Chrome Automation when needed.
      - Note: Unsigned build acceptable for CI validation; signed build will be validated separately.

5) Documentation Cleanup
   - Update `docs/README.md` and any doc pages that still say "FocusMonitor" to "ConsciousMonitor".
   - Ensure screenshots and internal links remain valid.
   - Acceptance Criteria:
     - No lingering references to "FocusMonitor" in docs unless historically noted.

6) Sanity Build and Run
   - Build in Xcode on macOS 13+.
   - Run the app, validate:
     - App/activity tracking works (`ActivityMonitor.swift`).
     - Chrome tab tracking works after Automation permission.
     - Local JSON persistence works (`DataStorage.swift`).
   - Acceptance Criteria:
     - Manual smoke test checklist completed, appended to this plan.

7) Tests and UI Tests
   - Run existing tests (`ConsciousMonitor-Tests`, `ConsciousMonitor-UITests`).
   - Acceptance Criteria:
     - Tests pass locally or failures documented with follow-up tasks.

8) Update Versioning/Release Notes (if needed)
   - If visible user-facing changes are made, add note to `RELEASE_CHECKLIST.md` or `IMPLEMENTATION_SUMMARY.md`.
   - Acceptance Criteria:
     - Release artifacts/docs reflect the alignment changes.

9) PR Preparation and Review
   - Commit with descriptive messages.
   - Open PR with summary of changes and test evidence.
   - Acceptance Criteria:
     - PR includes screenshots/logs of successful build, and checklists below filled out.

## Acceptance Criteria (Overall)

- No mismatched naming across project, scripts, entitlements, and docs.
- `xcodebuild` works with helper scripts and the Xcode GUI build works.
- App capabilities (Chrome Automation, storage) remain functional.
- Documentation is consistent, links valid.
- Bundle identifiers standardized to the chosen reverse-DNS across app and test targets.

## Project Status Board

- [ ] Create feature branch
- [ ] Audit names and identifiers
- [x] Fix `package.json` scripts
- [x] Align bundle identifiers
- [x] Align entitlements file and project settings
- [ ] Update documentation
- [~] Sanity build and run
- [x] Run tests
- [ ] Update release notes (if needed)
- [ ] Open PR

## Current Status / Progress Tracking

- Completed:
  - Updated `package.json` scripts to use `ConsciousMonitor.xcodeproj` and `ConsciousMonitor` scheme; updated package name/description to ConsciousMonitor.
  - Updated `PRODUCT_BUNDLE_IDENTIFIER` values in `ConsciousMonitor.xcodeproj/project.pbxproj` to:
    - App: `com.cstack.ConsciousMonitor`
    - Unit tests: `com.cstack.ConsciousMonitorTests`
    - UI tests: `com.cstack.ConsciousMonitorUITests`
  - Created `ConsciousMonitor/ConsciousMonitor.entitlements` and repointed `CODE_SIGN_ENTITLEMENTS` for Debug/Release.
  - Added Run Script phase “Strip Extended Attributes” to mitigate codesign issues; added `npm run build:unsigned` and `npm run test:unsigned` for CI/local validation without signing.

Next Up:
  - Replace remaining "FocusMonitor" references in docs.
  - Validate build locally: `xcodebuild -project ConsciousMonitor.xcodeproj -list` then `npm run build`.
-Notes:
  - Unsigned Release build succeeded: `npm run build:unsigned` (compiles and bundles app without codesigning).
  - Tests passed unsigned: `npm run test:unsigned` (Debug, unsigned).
  - Signed Release build currently fails at codesign with: `resource fork, Finder information, or similar detritus not allowed`.
  - Mitigation in place: Run Script phase attempts `xattr -cr "${TARGET_BUILD_DIR}/${WRAPPER_NAME}"` but encountered `Operation not permitted` during signed build.
  - Recommended local workaround to validate signed build: after build step and before codesign, run manually:
    - `xattr -cr build/Build/Products/Release/ConsciousMonitor.app`
    - Re-run `npm run build`.
  - Follow-up: Investigate which resource injects extended attributes; ensure no `.DS_Store` or quarantined files are copied into bundle.

## Executor's Feedback or Assistance Requests

- Confirm canonical bundle identifier and whether any signing profiles are tied to entitlements filename.
- Confirm preferred product name variants (menu title, marketing name) if different from project name.

## Lessons Learned

- Keep helper scripts aligned with Xcode project names to avoid bit-rot.
- Entitlements filename changes require Xcode project updates; verify capabilities after rename.
