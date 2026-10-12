# Implementation Notes

## Ajánlott architektúra
A content legyen data-driven. A UI ne eventenként külön kód legyen.

Javasolt fő komponensek:
- `CardDefinition`
- `EventDefinition`
- `RequirementDefinition`
- `OutcomeDefinition`
- `LootTable`
- `RecipeDefinition`
- `BuildDefinition`
- `PlayerState`
- `InventoryState`
- `CampState`

## CardDefinition
Ajánlott mezők:

```json
{
  "id": "use_torch",
  "title": "Use Torch",
  "art": "cards/actions/use_torch.png",
  "requirementText": "Requires: Torch x1",
  "riskTag": "COSTS_ITEM",
  "enabledWhen": [],
  "costs": [],
  "outcomeId": "jaguar_torch_success"
}
```

## EventDefinition

```json
{
  "id": "jaguar_encounter",
  "title": "Jaguar Encounter",
  "description": "A jaguar blocks your path.",
  "scene": "scenes/jaguar_encounter.png",
  "choices": ["use_torch", "use_spear", "throw_meat", "retreat"]
}
```

## Requirement típusok
- has_item
- item_count
- stat_min
- stat_max
- has_perk
- camp_level
- tool_tier
- location_unlocked

## Outcome elemek
Egy outcome több effectet is tartalmazhat:
- add_item
- remove_item
- health_delta
- water_delta
- food_delta
- sanity_delta
- add_status
- advance_time
- unlock_location
- unlock_recipe
- set_story_flag

## UI szabály
Ugyanaz a `CardView` komponens renderelje az event, craft és build kártyákat eltérő skin/config segítségével.

Ez csökkenti a kódot és garantálja a vizuális konzisztenciát.

## MVP-ben szükséges card view variánsok
1. `ChoiceCardView`
2. `RecipeCardView`
3. `BuildCardView`
4. `LootCardView`
5. `OutcomeCardView`

## Locked kártyák
Ne rejtsük el. Maradjanak láthatók szürkítve, hogy a játékos lássa, milyen gearrel oldhatta volna meg jobban a helyzetet.

## Asset naming
- `scene_event_jaguar.png`
- `card_action_use_torch.png`
- `card_item_stone_spear.png`
- `card_recipe_water_filter.png`
- `card_build_rain_collector.png`

## Vizuális konzisztencia
Minden új asset generálásakor használjuk a pack képeit style reference-ként. A karakter, kamera és shape language ne változzon.
