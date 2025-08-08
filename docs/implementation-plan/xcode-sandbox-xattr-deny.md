# Xcode Sandbox xattr Denial — Triage and Resolution Plan

- Task Name: Xcode sandbox xattr denial triage
- Branch Name: chore/xcode-sandbox-xattr-deny
- Owner: Executor
- Last Updated: 2025-08-07 20:57:00 -06:00

## Background and Motivation
When running the app from Xcode, a console message appears:

```
Sandbox: xattr(<pid>) deny(1) file-read-data <DerivedData path>/Build/Products/Debug/ConsciousMonitor.app
```

This may be benign (a helper trying to inspect extended attributes) or indicative of a misconfiguration (e.g., an over-eager build phase or sandboxed subprocess). We need a deterministic understanding and a clean developer experience.

## Key Challenges and Analysis
- The project has a build phase "Strip Extended Attributes" that invokes `/usr/bin/xattr -cr` to mitigate codesigning EA issues. This should only run at build time and only when signing is enabled.
- No runtime usages of `xattr` exist in source, suggesting the denial is from Xcode tooling or a stale artifact.
- Debug App Sandbox entitlements, if enabled, can cause denials for spawned tools; however, the message alone is not a failure.
- DerivedData and stale build intermediates can amplify noise.

## High-level Task Breakdown

1) Create feature branch
- Command: create a git branch `chore/xcode-sandbox-xattr-deny` off `main`.
- Success: branch exists locally.

2) Reproduce and capture logs
- Action: Run from Xcode (Debug) and capture full Run console around the message.
- Success: Confirm whether the app launches and note any additional errors.

3) Validate build phase gating and position
- Inspect target Build Phases → "Strip Extended Attributes" script:
  - Ensure conditional guards: run only when signing is enabled (e.g., `CODE_SIGNING_ALLOWED == YES || CODE_SIGNING_REQUIRED == YES`).
  - Prefer `CODESIGNING_FOLDER_PATH` to locate the bundle, else fall back to `TARGET_BUILD_DIR/WRAPPER_NAME`.
  - Emit a stamp file in `DERIVED_FILE_DIR` to appease Xcode and avoid warnings.
  - Ensure the phase is before Code Sign but not part of any Copy Files that run post-build.
  - Ensure "Based on dependency analysis" is enabled.
- Success: Script is correctly guarded and positioned.

4) Add extra defensive checks to script (if needed)
- Add guards to ensure the target path exists and `xattr` is only invoked if signing is actually occurring.
- Sample guard additions:
  - Check that `$CODESIGNING_FOLDER_PATH` or computed `$TARGET_PATH` exists (directory).
  - Double-check `[[ "${CODE_SIGNING_ALLOWED:-NO}" == "YES" ]] || [[ "${CODE_SIGNING_REQUIRED:-NO}" == "YES" ]]`.
  - Optionally, check `$EXPANDED_CODE_SIGN_IDENTITY` non-empty as another signal.
- Success: Script becomes no-op in unsigned Debug builds.

5) Scheme and build setting sanity checks
- Confirm the Debug configuration builds unsigned by default to avoid unnecessary signing.
- Ensure no Run/Pre/Post Actions in the scheme invoke `xattr`.
- Success: No stray invocations.

6) Entitlements review (Debug)
- Review `ConsciousMonitor.entitlements` or target capabilities.
- If App Sandbox is enabled, confirm no runtime file access outside allowed paths is required; otherwise, note the denials are expected for unrelated tools.
- Do not disable sandbox unless necessary; if disabling temporarily for diagnosis, re-enable after verification.
- Success: Entitlements are appropriate; app runs.

7) Clean state rebuild
- Product → Clean Build Folder; delete DerivedData for project; rebuild and re-run.
- Success: If message remains but app runs fine, classify as benign. If it disappears after guards, document the reason.

8) Document outcome and update docs
- Update `DEVELOPMENT.md` with a note about the benign nature or the fix.
- Update implementation plan status and scratchpad.
- Success: Clear documentation and repeatable behavior.

## Acceptance Criteria
- App launches from Xcode (Debug) without runtime failures.
- "Strip Extended Attributes" script does not run in unsigned Debug builds.
- If the sandbox xattr denial still appears, it is conclusively documented as benign; otherwise, the message is eliminated after safeguards.
- Unsigned build (`npm run build`) and tests (`npm test`) continue to pass.

## Project Status Board
- [ ] Branch created: `chore/xcode-sandbox-xattr-deny`
- [ ] Logs captured and analyzed
- [ ] Build phase audited and guarded
- [ ] Defensive checks added (if required)
- [ ] Scheme/build settings verified
- [ ] Entitlements reviewed
- [ ] Clean rebuild validated
- [ ] Docs updated

## Current Status / Progress Tracking
- Planner prepared detailed steps and acceptance criteria.
- Awaiting Executor to create branch and begin Step 2.

## Executor's Feedback or Assistance Requests
- If the app fails to launch, paste the surrounding Run console output for targeted diagnosis.
- Confirm current "Strip Extended Attributes" script contents and position for review if anything differs locally.

## Lessons Learned
- Extended attribute stripping should be tied strictly to signing workflows to avoid unnecessary operations and console noise.
- Sandbox denials from helper tools are not necessarily failures; always confirm app behavior and log context before acting.
