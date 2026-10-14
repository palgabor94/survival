# Fishing tutorial and control refresh — 2026-10-13

The pond's ready state explains cast → hook → reel before any bait is spent. The practice button and header help button open a replayable tutorial with a separate simulation. Practice casts, hooks and catches fish without touching the real session, resources, daylight, loot, saves or RNG. Practice bites wait for input; failed attempts can be retried. Closing help resumes the real clock from its paused state. Both sessions pause when the app leaves the foreground.

The white bar represents the player; the moving green zone contains a fish symbol. Holding moves right and releasing moves left. In the real attempt, captions tell the player which input brings the marker back into green. The catch bar must fill to land the fish. The reel uses pointer down/up/cancel so finger movement does not cancel a hold; keyboard and accessibility activation retain toggle controls. Waiting now occupies the primary card slot rather than moving the Leave card into its place.

Real bites last 2 seconds (previously 1.2). Reeling starts with the marker aligned with the fish, progress 30% (previously 20%) and target angular speed 1.2 (previously 1.7). Duration remains 8 seconds. The player must actively reel for at least 0.2 seconds before the catch bar can complete. No input and continuous holding are checked as failures. Perfect quality still needs a hook within 0.45 seconds and 80% in-zone time. Costs and rewards remain 2 daylight and 1 bait per trip, 1 fish for good / 2 for perfect.

Validation: 310 repository tests pass through the native Flutter runner; analyzer reports no issues. The full fishing UI test catches and consumes a fish using actual touch events and the rendered marker positions, without assigning session.holding directly. Practice also completes via touch events and leaves game.toJson unchanged. Finger movement/cancel, real lifecycle pause, and help layouts at 320×568, 390×844, 844×390 and 375×667 with 2× text are checked. Model tests cover 100 initial alignments, bite timing, quality, inactive input and frame consistency. These are automated checks, not physical-device playtesting. Earlier balance reports describe the pre-refresh fishing timing.

[Actual mobile screenshots](../../screenshots/fishing-tutorial-v1/index.html). Re-export with:

```sh
LOST_CANOPY_CAPTURE_FISHING_TUTORIAL=1 python3 screenshots/tools/capture_unified_ui.py
```
