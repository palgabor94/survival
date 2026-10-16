# Lost Canopy gameplay analytics

## Current integration status

- Account requested and verified locally: **3pgabor@gmail.com**.
- Proposed Firebase project ID: **lost-canopy-3pgabor**, display name Lost Canopy.
- **Cloud creation is not completed.** The creation attempt failed because this
  environment cannot resolve Google API hosts. No Firebase project/app IDs or
  keys have been invented. `assets/config/firebase.json` is explicitly unconfigured.
- iOS Bundle ID: **com.palgabor.lostcanopy** (Debug/Profile/Release and related test targets).
- Android package remains **com.example.survival_game**.
- Firebase Flutter dependencies resolve offline. CocoaPods native SDK installation
  is blocked by DNS for github.com. iOS device/build and cloud delivery are not verified.

## Finish cloud setup

Use Node 20+ and Firebase CLI, signed in as the account above. From `survival_game`:

```sh
python3 tools/analytics/setup_firebase.py
flutter pub get
cd ios
pod install
```

The setup script checks accessible projects, creates the project only if missing,
registers/reuses the exact iOS and Android app identifiers, and atomically writes
public Firebase SDK options to `assets/config/firebase.json` plus Android
Analytics string resources. Dart initializes
Firebase with these options. No service account key is bundled. The CLI's auth
responses and temporary debug logs are never forwarded to the terminal/repository.
If the proposed project ID is globally unavailable, choose an available ID using
`--project`. The script never changes billing or deploys a database/hosting.

After creation, enable Google Analytics under Firebase Project settings →
Integrations. Link a GA property belonging to the owner, then link BigQuery there
for raw event analysis. These account/property and export steps are **pending**;
creating a Firebase project alone does not enable Analytics/BigQuery.
Use daily export to begin; review the selected project's storage/query costs
before enabling additional exports. No paid resource has been enabled here.

Verify on a real iPhone: opt in, begin a journey, open map, confirm a choice,
craft, fish, background/resume, complete a night, die or rescue. Enable Analytics
DebugView (`-FIRDebugEnabled` launch argument) and confirm `lc_` events and user ID.
Repeat after opting out: no custom events should be sent. Remove debug mode for
release. App Store privacy disclosures must describe gameplay/usage collection.

Official references: [Flutter Analytics](https://firebase.google.com/docs/analytics/flutter/get-started),
[events](https://firebase.google.com/docs/analytics/flutter/events),
[CLI](https://firebase.google.com/docs/cli),
[collection controls](https://firebase.google.com/docs/analytics/ios/configure-data-collection),
[BigQuery export](https://support.google.com/firebase/answer/6318765).

## What is collected

Opt-in choice appears on the first real main-menu launch. Settings in both menus
can enable/disable collection; disabling clears the device journal and resets the
SDK's local Analytics data. A random installation ID becomes Firebase user ID;
there is no name/email/login/ad identifier. It is a pseudonymous ID, not a
cross-device identity. Firebase itself still has its standard SDK metadata.
The iOS ad-ID-free SDK variant is selected; Android AD_ID permission is removed,
ad consent denied, and automatic native screen reporting disabled.

All custom events are prefixed `lc_`. Common fields: schema_version, event_id,
event_index, client_time_ms, session_id, screen, run_id, day, location, phase, camp_tier,
health/water/food/sanity. At most 25 scalar parameters per event. Action IDs and
static game copy are used, not free text, screenshots, contacts or keystrokes.

| Group | Events / additional information |
|---|---|
| Identity/session | consent_granted, session_start, session_interrupted, app_foreground, app_background |
| Navigation | screen_view (previous screen), screen_time (foreground duration_ms) |
| Interaction | interaction: tap/swipe, semantic target when instrumented, normalized x/y |
| Journeys | run_loaded, run_started, run_restarted, run_ended (lost/rescued/abandoned, fatal_location, counters, conditions) |
| Progression | day_reached, camp_tier_reached, tutorial_decision, tutorial_skipped, tutorial_progress (next lesson, completed lessons) |
| Transactions | action_started, craft_started, item_consumed, action_result (stat deltas, time spent), resource_change |
| Exploration | map_destination_selected (including locked), travel_started, event_presented, choice_confirmed, expedition_deeper (risk/depth), expedition_return |
| Minigames | fishing_cast (rod/bait), fishing_result (species/quality/release/miss), gathering_strike (quality), plant_picked |
| Survival | night_started, conditions_changed, beacon_activated |
| Engagement | heartbeat every 30 foreground seconds, idle_seconds |

Screen route names are explicit across game flow and dialogs. Shared action cards,
parchment cards/buttons, menu rows, shortcuts and close controls have semantic
targets. Other taps are recorded as `surface` with coordinates. This is **not**
a video/session replay or an assertion that every bespoke widget has a semantic
ID. Minigame animation frames and finger movement paths are not streamed.

## Reliability and interpretation

The observer never changes game RNG or state; callback failures are isolated.
Reports restored from saves are not replayed as new results. Run end is emitted
when its summary is first created, including restart/abandon, not on UI rebuild.
A report contains post-action stats and separate deltas; action IDs distinguish
interest (card details) from commitment (choice_confirmed).

The journal retains up to **2,000** recent events. It is persisted before SDK
acceptance, then marked sent. Events awaiting configuration are retried on a
configured next launch; the Firebase SDK handles its own subsequent offline queue.
A full journal drops oldest events and persists a drop counter. Preferences are
best-effort storage, not a guarantee against an immediate OS kill/disk failure.
Stable event_id enables deduplication after a crash during delivery. `sent` means
accepted by the SDK, **not** confirmed in BigQuery.

Screen dwell excludes background intervals. A background event does not mean quit.
`session_interrupted` on the next launch describes the previous checkpoint;
it cannot distinguish force quit, OS reclamation and a normal process restart.
The final screen can be inferred within the last checkpoint (usually at most
30 foreground seconds old), not captured at every possible termination instant.
Unfinished runs can resume later: don't label them abandoned until a cohort has
had enough return time. Long idle/repeated input indicate possible confusion or
friction, not proven boredom. The reports only represent consenting installations.

## Analyze captured data

Settings → Copy diagnostic data exports the bounded device journal as JSONL.
Save the clipboard into a local file, then:

```sh
python3 tools/analytics/analyze.py gameplay.jsonl --out /private/tmp/lost-canopy-report
```

Produces `report.md` and `report.json`: distinct players/sessions/runs, outcomes,
end days, foreground screen time, background screens, deaths by location,
choices and friction candidates. Stable IDs deduplicate retries. Avoid committing
real player exports. For cloud analysis use `tools/analytics/bigquery.sql` with
real project/property IDs and date parameters; export its normalized JSONL rows
and run the same analyzer. BigQuery and the live data pipeline are pending.

For balancing, compare rescue/death rates by day, tier, location, conditions and
choice, fishing success by bait/rod, and tutorial step completion. Use session/run
paths for individual investigations; use cohorts and enough sample size before
changing difficulty. Cloud exports may have delay and cannot explain every exit.

Device clearing/SDK reset does not delete previously uploaded GA/BigQuery data.
Administrator-side deletion must use the prior pseudonymous player ID in both
services; retention and deletion operations remain an owner configuration step.
