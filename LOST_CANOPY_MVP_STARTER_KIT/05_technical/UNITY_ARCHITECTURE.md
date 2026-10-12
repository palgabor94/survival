# Suggested Unity Architecture

## High-level
MVP does not need real 3D traversal. Treat each gameplay location as a 2D scene/background with UI overlays and state-based character poses/ambient animation.

## Scenes
- Boot
- MainMenu
- Camp
- WorldMap
- Location
- MinigameFishing
- MinigameHunting
- MinigameChopping
- MinigameForaging
- MinigameRuins
- RunEnd

## Core systems
### RunState
Stores:
- day/time
- health/water/food/sanity
- statuses
- inventory
- camp tier
- unlocked locations
- owned tools / tool tiers
- beacon progression
- current weather

### Content database
Prefer ScriptableObjects or JSON-backed definitions:
- ItemDefinition
- RecipeDefinition
- EventDefinition
- LocationDefinition
- CampUpgradeDefinition
- LootTableDefinition

### Event Engine
Input:
- event id
- conditions
- choices

Choice output:
- stat deltas
- item changes
- status changes
- next event / return / minigame

### Save
One active run + meta profile.
Autosave after every resolved action/event.

## Art implementation
Base location background + optional overlays:
- weather
- fire glow
- smoke
- water animation
- character pose
- camp upgrade object layers

For MVP, short looped video or sprite animation is acceptable for ambience, but keep a static fallback.

## Tool progression
Tool definition should contain both:
- gameplay assist modifier
- loot table tier/unlocks

Example:
`RodTier2.safeZoneMultiplier = 1.25`
`RodTier2.lootTable = Fishing_MediumAndRare`

## Data-driven first
Avoid hard-coding events and recipes. The point of the game is content expansion, so event/loot/craft data should be editable without code changes.
