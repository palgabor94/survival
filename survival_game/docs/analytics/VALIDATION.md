# Validation — 2026-10-16

- Native Flutter test suite: **485 passed, 0 failed, 0 skipped**.
- Analytics-specific tests: 10 included in that suite (consent, opt-out, retry,
  stable IDs, foreground dwell, death dedup, RNG isolation, parameter limits,
  corrupt storage, initial menu and passive taps/swipes).
- Python setup/analyzer tests: **2 passed**. All cloud responses are mocked in
  these tests; they do not create an actual project.
- Dart analysis of production code, changed tests and screenshot exporter:
  **No issues found**.
- Xcode project and Info.plist: `plutil -lint` OK.
- Git whitespace checks: clean.
- Actual Flutter UI exports reviewed at 390×844, rendered at 2×:
  `screenshots/analytics-v1/01-gameplay-analytics-choice.png` and
  `screenshots/analytics-v1/02-gameplay-analytics-settings.png`.

Cloud project creation was attempted with 3pgabor@gmail.com and failed on network
name resolution. Firebase configuration stays explicitly unconfigured. Native
CocoaPods installation also failed on DNS for github.com after the writable
cache workaround. No iOS build, DebugView delivery or BigQuery export is claimed.
The Firebase project/property and native SDK setup still need completion using
the commands in README.md with working Google/GitHub access.
