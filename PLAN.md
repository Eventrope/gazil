# Gazil - Trading Sim Game Plan

## Deliverable 1: Game Design + Systems Plan

---

### 1. One-Page Game Design Overview

**Title:** Gazil (Gazillionaire-inspired Trading Sim)

**Core Loop:**
```
Plan Route → Buy Cargo → Travel → Resolve Event → Sell Cargo → Upgrade → Repeat
```

**Premise:** You're an interstellar trader starting with a rusty cargo hauler and 1,000 credits. Travel between planets, exploit price differences, survive random events, and upgrade your ship to become the galaxy's most successful merchant.

**What Makes It Fun:**
- **Risk/Reward decisions:** Cargo that's cheap here might be illegal there. High-margin goods attract pirates.
- **Emergent stories:** Random events create memorable moments ("That time plague rats ate my luxury silks")
- **Progression satisfaction:** Ship upgrades visibly improve your capabilities
- **Simple but deep economy:** Supply/demand creates natural price fluctuations to exploit

**Win Condition (v0.1 - Vertical Slice):** Reach 100,000 credits (endless mode after)

**Lose Condition:** Go bankrupt (credits < 0 and no cargo to sell)

---

### 2. Vertical Slice Scope (v0.1)

**IN SCOPE:**
- 5 planets with distinct price profiles
- 6 commodities (2 cheap/common, 2 mid-tier, 2 expensive/rare)
- Basic ship with upgradeable cargo capacity and fuel tank
- 10 random events (5 good, 5 bad, mix of choice-based)
- Simple 2D UI screens (no fancy graphics, text/buttons/lists)
- Manual save/load (single slot)
- Fuel as travel resource (run out = stranded = game over)
- Basic price drift over time

**OUT OF SCOPE (future):**
- Multiple ships/fleet management
- Crew members
- Combat system
- Reputation/faction system
- Procedural planet generation
- Multiplayer
- Sound/music
- Visual effects

---

### 3. Key Systems List

| System | Responsibility | Key Data |
|--------|---------------|----------|
| **Economy** | Track prices per planet, handle supply/demand, drift prices over time | Base prices, current prices, volatility, supply levels |
| **Travel** | Calculate fuel cost, time passage, trigger arrival events | Distance matrix, fuel consumption rate |
| **Cargo** | Manage player inventory, enforce capacity limits | Cargo hold contents, max capacity |
| **Ship** | Store ship stats, handle upgrades | Fuel capacity, cargo capacity, fuel efficiency, upgrade costs |
| **Events** | Select and resolve random events during travel | Event pool, triggers, choices, outcomes |
| **Player** | Track credits, current location, game state | Credits, location, play time, statistics |
| **UI** | Render screens, handle input | Screen stack, current context |
| **Persistence** | Save/load game state | Serialized game state |

---

### 4. Data Model

#### Planet
```
{
  "id": "mars",
  "name": "Mars Colony",
  "description": "Industrial hub with high demand for food",
  "distance_from": {
    "earth": 2,
    "venus": 3,
    "jupiter": 4,
    "saturn": 6,
    "titan": 7
  },
  "price_modifiers": {
    "food": 1.8,        // 80% more expensive (high demand)
    "ore": 0.6,         // 40% cheaper (local production)
    "tech": 1.0,
    "luxury": 1.2,
    "fuel_cells": 0.9,
    "medicine": 1.1
  },
  "supply_volatility": 0.15,  // How much prices drift
  "events_weight": 1.0        // Likelihood multiplier for events
}
```

#### Commodity
```
{
  "id": "food",
  "name": "Food Supplies",
  "base_price": 50,
  "weight_per_unit": 2,      // Cargo space per unit
  "legality": "legal",       // legal, restricted, contraband
  "description": "Basic rations and preserved goods"
}
```

#### Ship
```
{
  "id": "rustbucket",
  "name": "Rustbucket Mk1",
  "cargo_capacity": 100,
  "fuel_capacity": 50,
  "fuel_efficiency": 1.0,    // Multiplier on fuel consumption
  "upgrades_installed": []
}
```

#### Upgrade
```
{
  "id": "cargo_expansion_1",
  "name": "Cargo Bay Expansion",
  "description": "+50 cargo capacity",
  "cost": 5000,
  "effect": {
    "cargo_capacity": 50
  },
  "requires": []             // Prerequisite upgrades
}
```

#### Player State
```
{
  "credits": 1000,
  "current_planet": "earth",
  "ship": { ... },
  "cargo": {
    "food": 10,
    "ore": 0
  },
  "fuel": 50,
  "day": 1,
  "statistics": {
    "trades_made": 0,
    "distance_traveled": 0,
    "events_survived": 0
  }
}
```

#### Event
```
{
  "id": "pirate_ambush",
  "name": "Pirate Ambush!",
  "description": "A pirate vessel intercepts your ship and demands tribute.",
  "trigger": "travel",           // travel, arrival, departure
  "weight": 1.0,
  "conditions": {
    "min_cargo_value": 500       // Only triggers if carrying valuable cargo
  },
  "choices": [
    {
      "text": "Pay tribute (20% of cargo value)",
      "outcome": {
        "credits": -0.2,         // Percentage-based
        "message": "The pirates take their cut and let you go."
      }
    },
    {
      "text": "Try to flee",
      "outcome_success": {
        "chance": 0.4,
        "message": "You engage thrusters and escape!"
      },
      "outcome_failure": {
        "cargo_loss": 0.5,       // Lose 50% of cargo
        "message": "They catch you and take half your cargo."
      }
    }
  ]
}
```

---

### 5. Godot Architecture Plan

#### Scene Tree Outline

```
Main (Node)
├── GameState (Autoload Singleton)
├── DataRepo (Autoload Singleton)
├── EventManager (Autoload Singleton)
│
├── Screens/
│   ├── MainMenu.tscn
│   │   └── VBoxContainer
│   │       ├── TitleLabel
│   │       ├── NewGameButton
│   │       ├── LoadGameButton
│   │       └── QuitButton
│   │
│   ├── GalaxyMap.tscn
│   │   └── HSplitContainer
│   │       ├── PlanetList (ItemList)
│   │       └── PlanetInfo (VBoxContainer)
│   │           ├── NameLabel
│   │           ├── DescriptionLabel
│   │           ├── DistanceLabel
│   │           ├── FuelCostLabel
│   │           └── TravelButton
│   │
│   ├── Market.tscn
│   │   └── VBoxContainer
│   │       ├── PlanetNameLabel
│   │       ├── CommodityTable (GridContainer)
│   │       ├── BuySellPanel
│   │       └── LeaveButton
│   │
│   ├── TravelEvent.tscn
│   │   └── VBoxContainer
│   │       ├── EventTitle
│   │       ├── EventDescription
│   │       ├── ChoicesContainer (VBoxContainer of Buttons)
│   │       └── OutcomeLabel
│   │
│   ├── Shipyard.tscn
│   │   └── VBoxContainer
│   │       ├── ShipStatsPanel
│   │       ├── UpgradeList (ItemList)
│   │       ├── UpgradeInfo
│   │       └── BackButton
│   │
│   └── GameOver.tscn
│       └── VBoxContainer
│           ├── ResultLabel (Win/Lose)
│           ├── StatsPanel
│           ├── PlayAgainButton
│           └── MainMenuButton
│
└── UI/
    └── HUD.tscn
        └── HBoxContainer
            ├── CreditsLabel
            ├── FuelLabel
            ├── CargoLabel
            ├── DayLabel
            └── LocationLabel
```

#### Autoloads

| Singleton | Purpose | Key Methods |
|-----------|---------|-------------|
| **GameState** | Holds current player state, handles state transitions | `new_game()`, `save()`, `load()`, `get_player()`, `advance_day()` |
| **DataRepo** | Loads and provides access to static game data | `get_planet(id)`, `get_commodity(id)`, `get_all_planets()`, `get_events_for_trigger(trigger)` |
| **EventManager** | Selects and executes events | `roll_event(trigger)`, `execute_choice(event, choice_idx)` |

#### File Layout

```
gazil/
├── project.godot
├── PLAN.md
├── TASKS.md
├── CHANGELOG.md
│
├── data/
│   ├── planets.json
│   ├── commodities.json
│   ├── events.json
│   ├── upgrades.json
│   └── ships.json
│
├── src/
│   ├── autoload/
│   │   ├── game_state.gd
│   │   ├── data_repo.gd
│   │   └── event_manager.gd
│   │
│   ├── models/
│   │   ├── planet.gd
│   │   ├── commodity.gd
│   │   ├── ship.gd
│   │   ├── player.gd
│   │   └── event.gd
│   │
│   └── utils/
│       ├── rng.gd           # Seedable RNG wrapper
│       └── save_manager.gd
│
├── scenes/
│   ├── main_menu.tscn
│   ├── galaxy_map.tscn
│   ├── market.tscn
│   ├── travel_event.tscn
│   ├── shipyard.tscn
│   ├── game_over.tscn
│   └── hud.tscn
│
├── scripts/
│   ├── main_menu.gd
│   ├── galaxy_map.gd
│   ├── market.gd
│   ├── travel_event.gd
│   ├── shipyard.gd
│   ├── game_over.gd
│   └── hud.gd
│
└── saves/
    └── (runtime save files)
```

#### Naming Conventions
- **Scenes:** `snake_case.tscn`
- **Scripts:** `snake_case.gd`
- **Classes:** `PascalCase`
- **Variables/Functions:** `snake_case`
- **Constants:** `SCREAMING_SNAKE_CASE`
- **Signals:** `snake_case` (past tense: `trade_completed`, `fuel_depleted`)

---

### 6. Content Pipeline

All game content stored in JSON files in `/data/` folder. Loaded once at startup by `DataRepo`.

#### Example: planets.json
```json
{
  "planets": [
    {
      "id": "earth",
      "name": "Earth",
      "description": "Humanity's homeworld. Balanced prices, good for beginners.",
      "distance_from": {
        "mars": 2,
        "venus": 1,
        "jupiter": 5,
        "saturn": 8,
        "titan": 9
      },
      "price_modifiers": {
        "food": 1.0,
        "ore": 1.2,
        "tech": 0.8,
        "luxury": 1.0,
        "fuel_cells": 1.0,
        "medicine": 1.0
      },
      "supply_volatility": 0.1
    }
  ]
}
```

#### Example: commodities.json
```json
{
  "commodities": [
    {
      "id": "food",
      "name": "Food Supplies",
      "base_price": 50,
      "weight_per_unit": 2,
      "legality": "legal",
      "description": "Basic rations and preserved goods"
    },
    {
      "id": "ore",
      "name": "Raw Ore",
      "base_price": 30,
      "weight_per_unit": 5,
      "legality": "legal",
      "description": "Unprocessed minerals for manufacturing"
    }
  ]
}
```

#### Example: events.json
```json
{
  "events": [
    {
      "id": "cargo_bonus",
      "name": "Lucky Find",
      "description": "You discover some salvage floating in space!",
      "trigger": "travel",
      "weight": 0.8,
      "conditions": {},
      "choices": [
        {
          "text": "Claim the salvage",
          "outcome": {
            "random_cargo": { "min": 5, "max": 15 },
            "message": "You haul in some extra cargo!"
          }
        },
        {
          "text": "Leave it (might be a trap)",
          "outcome": {
            "message": "Better safe than sorry. You continue on your way."
          }
        }
      ]
    }
  ]
}
```

---

### 7. Risk List

| # | Risk | Impact | Likelihood | Mitigation |
|---|------|--------|------------|------------|
| 1 | **Economy too easy/hard to exploit** | Players find dominant strategy or can't progress | High | Playtest early, add price floors/ceilings, tune volatility |
| 2 | **Events feel repetitive** | Boring after 30 minutes | Medium | Design modular event system, plan for easy content addition |
| 3 | **Scope creep** | Never ship | High | Strict vertical slice, say no to features until v0.1 done |
| 4 | **Save/load corruption** | Lost progress = angry players | Medium | Version save format, add validation, keep backups |
| 5 | **UI becomes spaghetti** | Hard to add screens, bugs | Medium | Keep screen scripts focused, use signals for communication |

---

## Deliverable 2: Implementation Plan (Milestones)

### Milestone 1: Project Setup + Data Loading
**Goal:** Godot project with working data pipeline

**Create:**
- `project.godot` with Godot 4.x settings
- All folder structure
- `data_repo.gd` autoload
- `planets.json`, `commodities.json` with starter content

**UI:** None (console output for testing)

**Test Plan:**
1. Run project
2. Check Output panel shows "Loaded 5 planets, 6 commodities"

**Done When:**
- [ ] Project opens in Godot without errors
- [ ] DataRepo loads all JSON files
- [ ] Can access planet/commodity data from any script

---

### Milestone 2: GameState + Player Model
**Goal:** Track player state across sessions

**Create:**
- `game_state.gd` autoload
- `player.gd` model class
- `ship.gd` model class
- Basic save/load to JSON

**UI:** None

**Test Plan:**
1. Start game, verify player has 1000 credits
2. Modify credits in code, save, reload, verify persisted

**Done When:**
- [ ] Player model holds credits, location, cargo, fuel
- [ ] Ship model holds capacity stats
- [ ] Save/load works without data loss

---

### Milestone 3: Main Menu + Galaxy Map
**Goal:** Navigate between planets

**Create:**
- `main_menu.tscn` + script
- `galaxy_map.tscn` + script
- Basic HUD showing player stats

**UI:**
- Main menu with New Game / Load / Quit
- Planet list with names
- Planet info panel with description + distance + travel button

**Test Plan:**
1. Launch game, see main menu
2. Click New Game, see galaxy map
3. Select different planets, see info update
4. Click Travel, location changes (no events yet)

**Done When:**
- [ ] Can start new game from menu
- [ ] Can view all 5 planets
- [ ] Can travel between planets (fuel consumed)
- [ ] HUD shows current credits/fuel/location

---

### Milestone 4: Market System
**Goal:** Buy and sell commodities

**Create:**
- `market.tscn` + script
- Price calculation with planet modifiers
- Buy/sell transaction logic

**UI:**
- Table showing commodity name, buy price, sell price, player quantity
- Buy/sell buttons with quantity input
- Cargo space indicator

**Test Plan:**
1. At Earth, buy 10 Food for 500 credits
2. Travel to Mars (food expensive there)
3. Sell 10 Food for 900 credits
4. Verify profit of 400 credits (minus fuel cost)

**Done When:**
- [ ] Prices reflect planet modifiers
- [ ] Can buy commodities (credits decrease, cargo increases)
- [ ] Can sell commodities (credits increase, cargo decreases)
- [ ] Cannot exceed cargo capacity
- [ ] Cannot spend more credits than available

---

### Milestone 5: Random Events
**Goal:** Events trigger during travel

**Create:**
- `event_manager.gd` autoload
- `travel_event.tscn` + script
- `events.json` with 10 events
- RNG wrapper for seedable randomness

**UI:**
- Event title + description
- Choice buttons
- Outcome message + continue button

**Test Plan:**
1. Travel multiple times, sometimes get events
2. Choose different options, see different outcomes
3. Verify outcomes affect player state (credits/cargo)

**Done When:**
- [ ] ~30% of travels trigger events
- [ ] Events present choices
- [ ] Choices resolve with visible outcomes
- [ ] Outcomes correctly modify player state

---

### Milestone 6: Ship Upgrades
**Goal:** Spend credits to improve ship

**Create:**
- `shipyard.tscn` + script
- `upgrades.json` with 5 upgrades

**UI:**
- Current ship stats display
- Available upgrades list
- Purchase button

**Test Plan:**
1. Start with 100 cargo capacity
2. Buy Cargo Expansion upgrade
3. Verify capacity now 150
4. Verify can't rebuy same upgrade

**Done When:**
- [ ] Can view ship stats
- [ ] Can purchase upgrades (credits decrease)
- [ ] Upgrades modify ship stats
- [ ] Cannot buy same upgrade twice
- [ ] Cannot buy upgrades you can't afford

---

### Milestone 7: Win/Lose Conditions + Game Over
**Goal:** Complete game loop

**Create:**
- `game_over.tscn` + script
- Win check (100k credits)
- Lose check (bankrupt or stranded)

**UI:**
- Victory/defeat message
- Final statistics
- Play again / main menu buttons

**Test Plan:**
1. Cheat to 100k credits, verify win screen
2. Cheat to 0 credits + empty cargo, verify lose screen
3. Run out of fuel in space, verify stranded lose

**Done When:**
- [ ] Reaching 100k credits shows victory
- [ ] Going bankrupt shows defeat
- [ ] Running out of fuel shows stranded defeat
- [ ] Can restart or return to menu

---

### Milestone 8: Price Drift + Day System
**Goal:** Economy evolves over time

**Create:**
- Day counter advancement
- Price drift calculation per day
- Supply/demand visualization

**UI:**
- Day counter in HUD
- Price trend indicators (up/down arrows)

**Test Plan:**
1. Note Food price at Earth
2. Advance 10 days
3. Price should have changed within volatility range

**Done When:**
- [ ] Days advance with each travel
- [ ] Prices drift within bounds
- [ ] Can see price trends in market

---

### Milestone 9: Polish + Balance Pass
**Goal:** Make it feel good to play

**Tasks:**
- Tune starting credits, prices, distances
- Add flavor text to planets
- Improve UI feedback (confirm dialogs, error messages)
- Test full playthrough, adjust difficulty

**UI:** Quality improvements throughout

**Test Plan:**
1. Full playthrough from start to 100k credits
2. Should take 30-60 minutes
3. Should feel challenging but fair

**Done When:**
- [ ] Vertical slice is completable
- [ ] No softlocks or progression blockers
- [ ] UI feels responsive and clear

---

### Milestone 10: Documentation + Release
**Goal:** Playable vertical slice ready

**Tasks:**
- Write README with play instructions
- Document content adding process
- Create CHANGELOG
- Tag v0.1 release

**Done When:**
- [ ] README explains how to play
- [ ] CHANGELOG documents features
- [ ] Can hand game to someone else and they understand it

---

## Deliverable 3: First Build Tasks

**AWAITING APPROVAL**

Before proceeding with implementation, please confirm:

1. Does the vertical slice scope look right?
2. Any features you want to add or remove?
3. Any changes to the data model?
4. Ready to start Milestone 1?

Once approved, I'll provide the first implementation chunk:
- Godot project setup
- Folder structure creation
- DataRepo singleton with JSON loading
- Initial data files (planets, commodities)
