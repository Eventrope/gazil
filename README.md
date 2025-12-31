# Gazil

A Gazillionaire-inspired space trading simulation game built with Godot 4.

## How to Play

1. **Open in Godot 4.x** - Open the project folder in Godot Engine 4.2+
2. **Run the game** - Press F5 or click the Play button
3. **Start trading!** - Click "New Game" to begin

### Core Gameplay Loop

1. **Check the Market** - Buy commodities that are cheap on your current planet
2. **Travel** - Select a destination and travel there (uses fuel based on distance)
3. **Handle Events** - Random events may occur during travel - make choices!
4. **Sell High** - Sell your cargo at planets where it's expensive
5. **Upgrade** - Visit the Shipyard to upgrade your ship or refuel
6. **Repeat** - Keep trading until you reach 100,000 credits to win!

### Tips

- **Food** is cheap on Earth, expensive on Mars and Titan
- **Ore** is cheap on Mars, expensive on Venus
- **Tech** is cheap on Venus, expensive elsewhere
- **Fuel Cells** are cheapest at Jupiter Orbital
- **Medicine** sells best at Titan Research Base
- Watch your fuel! Running out in space means game over
- Save often - the galaxy is dangerous

### Win/Lose Conditions

- **Win:** Accumulate 100,000 credits
- **Lose:** Go bankrupt (no credits and no cargo) or run out of fuel

---

## Game Design

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

### Vertical Slice Scope (v0.1)

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

### Key Systems

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

## Project Structure

```
gazil/
├── data/           # JSON game data (moddable)
│   ├── planets.json
│   ├── commodities.json
│   ├── events.json
│   ├── upgrades.json
│   └── ships.json
├── src/
│   ├── autoload/   # Global singletons
│   ├── models/     # Data model classes
│   └── utils/      # Utility scripts
├── scenes/         # Godot scene files (.tscn)
├── scripts/        # Scene scripts (.gd)
└── saves/          # Runtime save files
```

### Autoloads

| Singleton | Purpose | Key Methods |
|-----------|---------|-------------|
| **GameState** | Holds current player state, handles state transitions | `new_game()`, `save()`, `load()`, `get_player()`, `advance_day()` |
| **DataRepo** | Loads and provides access to static game data | `get_planet(id)`, `get_commodity(id)`, `get_all_planets()`, `get_events_for_trigger(trigger)` |
| **EventManager** | Selects and executes events | `roll_event(trigger)`, `execute_choice(event, choice_idx)` |

### Naming Conventions
- **Scenes:** `snake_case.tscn`
- **Scripts:** `snake_case.gd`
- **Classes:** `PascalCase`
- **Variables/Functions:** `snake_case`
- **Constants:** `SCREAMING_SNAKE_CASE`
- **Signals:** `snake_case` (past tense: `trade_completed`, `fuel_depleted`)

---

## Modding

All game content is defined in JSON files in the `/data/` folder. You can:
- Add new planets
- Create new commodities
- Design new random events
- Add ship upgrades

Just follow the existing format in each JSON file.

---

## Task Tracker

### Current Sprint: v0.1 Vertical Slice

#### Completed
- [x] Project setup and folder structure
- [x] Data JSON files (planets, commodities, events, upgrades, ships)
- [x] Model classes (Planet, Commodity, Ship, Player, GameEvent)
- [x] DataRepo autoload (loads all game data from JSON)
- [x] GameState autoload (player state, save/load, game logic)
- [x] EventManager autoload (random events, choice resolution)
- [x] Main Menu screen (new game, load game, quit)
- [x] Galaxy Map screen (planet selection, travel, HUD)
- [x] Market screen (buy/sell commodities)
- [x] Shipyard screen (upgrades, refuel)
- [x] Travel Event screen (random events with choices)
- [x] Game Over screen (victory/defeat, statistics)

#### In Progress
- [ ] Playtesting and balance tuning
- [ ] Bug fixes from initial testing

#### Backlog
- [ ] Price trend indicators in market
- [ ] Confirm dialogs for expensive purchases
- [ ] Keyboard shortcuts
- [ ] Sound effects
- [ ] Background music
- [ ] Visual polish

### Known Issues
- None yet (needs testing)

### Notes
- Remember to test full game loop: new game → trade → travel → events → win/lose
- Check edge cases: run out of fuel, go bankrupt, max cargo

---

## GDScript Coding Guidelines (for AI Agents)

### 1. Type Inference from Dictionary/Array Operations

**Problem:** GDScript cannot infer types from Dictionary or Array element operations.

```gdscript
# BAD - Cannot infer type
var remaining_count := active_events.size() - result["expired"].size()

# GOOD - Explicitly type the variable
var expired_count: int = result["expired"].size()
var remaining_count: int = active_events.size() - expired_count
```

**Rule:** When performing arithmetic with values from Dictionary lookups or Array operations, always use explicit type annotations (`: int`, `: float`, etc.) instead of type inference (`:=`).

### 2. Variable Scope in Conditional Blocks

**Problem:** Variables declared inside `if/else` blocks are not accessible outside those blocks.

```gdscript
# BAD - travel_modifier only exists inside the else block
if planet.id == current_planet:
	display_text += " (Current)"
else:
	var travel_modifier := get_modifier()  # Only accessible here
	display_text += " [%d days]" % distance

# This will fail - travel_modifier is out of scope
if travel_modifier > 1.0:  # ERROR!
	highlight_planet()

# GOOD - Declare variable before the conditional
var travel_modifier: float = 1.0  # Default value
if planet.id == current_planet:
	display_text += " (Current)"
else:
	travel_modifier = get_modifier()  # Reassign, don't redeclare
    display_text += " [%d days]" % distance

# Now this works
if travel_modifier > 1.0:
    highlight_planet()
```

**Rule:** If a variable needs to be used after a conditional block, declare it before the `if` statement with a default value.

### 3. Type Annotations Best Practices

```gdscript
# For simple literals, inference is fine
var count := 0
var name := "player"
var speed := 1.5

# For function returns that may be Variant, use explicit types
var result: Dictionary = some_function()
var items: Array = get_items()
var value: int = dict.get("key", 0)

# For class instances
var player: Player = Player.new()
var event: NewsEvent = NewsEvent.from_dict(data)
```

### 4. Null/Empty Checks

```gdscript
# Check for null before accessing properties
if planet == null:
    return

# Check array emptiness
if valid_events.is_empty():
    return null

# Safe dictionary access with defaults
var value: int = dict.get("key", 0)
var name: String = dict.get("name", "Unknown")
```

### 5. Signal Connections

```gdscript
# Connect with bind for passing additional arguments
button.pressed.connect(_on_button_pressed.bind(item_id, quantity))

# Signal declarations
signal event_started(event: NewsEvent)
signal value_changed(old_value: int, new_value: int)
```

### 6. Resource Paths

Always verify resource files exist before referencing them in project.godot or scenes:
- Custom fonts in `[gui]` section
- Autoload scripts in `[autoload]` section
- Main scene in `[application]` section

---

## Requirements

- Godot Engine 4.2 or higher
- No additional dependencies
