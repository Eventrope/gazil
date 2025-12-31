# Gazil - Claude Code Context

## Project
Gazillionaire-inspired trading sim built with Godot 4.5.1

## GDScript Type Inference Rules

**IMPORTANT:** GDScript cannot infer types when using certain built-in functions that return `Variant`. Always use explicit type annotations (`: int`, `: float`, etc.) instead of type inference (`:=`) in these cases:

```gdscript
# BAD - Cannot infer type from max(), min(), clamp(), etc.
var affordable := player.credits / max(price, 1)
var result := dict.get("key", 0)
var count := array.size() - other_array.size()

# GOOD - Use explicit type annotations
var affordable: int = player.credits / max(price, 1)
var result: int = dict.get("key", 0)
var count: int = array.size() - other_array.size()
```

**When to use explicit types:**
- Arithmetic with `max()`, `min()`, `clamp()`, `abs()`
- Dictionary `.get()` calls
- Array element access `array[i]`
- Any operation involving `Variant` return types

**When `:=` is fine:**
- Simple literals: `var x := 0`, `var name := "player"`
- Strongly-typed function returns: `var player := GameState.player`
- Constructor calls: `var vec := Vector2(0, 0)`

**Method Return Type Issues:**
When a custom method returns a type that could be inferred as Variant, use explicit types:
```gdscript
# BAD - Method may return Variant-typed value
var standing := CorporationManager.get_standing(player, corp_id)
var presence := corp.get_presence_level(planet_id)
var result := contract.can_accept(ship, standing)

# GOOD - Use explicit type annotations
var standing: int = CorporationManager.get_standing(player, corp_id)
var presence: String = corp.get_presence_level(planet_id)
var result: Dictionary = contract.can_accept(ship, standing)
```

**Common patterns needing explicit types:**
- Manager methods: `CorporationManager.get_standing()` → `: int`
- Model methods: `contract.can_accept()` → `: Dictionary`
- Get methods: `corp.get_presence_level()` → `: String`
- Enum methods: Any method returning enum values
- Dictionary/Array operations

## Godot CLI

Executable: `/Applications/Godot.app/Contents/MacOS/Godot`

### Common Commands

```bash
# Validate project (check for load errors)
/Applications/Godot.app/Contents/MacOS/Godot --headless --quit --path /Users/mbuhler/Development/gazil 2>&1

# Run with verbose output
/Applications/Godot.app/Contents/MacOS/Godot --headless -v --quit --path /Users/mbuhler/Development/gazil 2>&1

# Run a specific scene headless
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/mbuhler/Development/gazil --scene res://scenes/main_menu.tscn 2>&1

# Launch game with window (for visual testing)
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/mbuhler/Development/gazil
```

## Project Structure

- `scenes/` - Godot scene files (.tscn)
- `scripts/` - GDScript files for scenes
- `src/autoload/` - Singleton autoload scripts (DataRepo, GameState, etc.)
- `src/models/` - Data model classes
- `data/` - JSON data files (planets, commodities, ships, etc.)

## Economy System (SPEC-ECONOMY.md)

### Commodities (10 total)
- **Bulk**: Sparkle Rocks (Ore), Space Wheat (Grain) - heavy, low margin
- **Standard**: Gloop Juice (Fuel), Clanky Bits (Parts), Glowing Pills (Medicine), Blinky Boxes (Tech)
- **Luxury**: Fun Cubes (Entertainment), Ancient Junk (Artifacts), Shiny Things (Luxury) - light, high margin
- **Contraband**: Definitely Not Illegal - high risk/reward, inspection mechanics

### Planet Archetypes
- `mining`: Produces ore/parts, consumes grain/entertainment
- `agricultural`: Produces grain, consumes tech/medicine
- `gas_giant`: Produces fuel, consumes everything else
- `research`: Produces medicine/tech/artifacts, consumes grain/luxury
- `leisure`: Produces entertainment/luxury, consumes ore/parts
- `crossroads`: Balanced prices

### Key Features
- **Purchase price tracking**: Player.cargo_purchase_prices tracks avg cost
- **Profit/loss display**: Market shows potential profit on owned cargo
- **Exclusive goods**: Artifacts only at Titan/Pluto, Contraband only at Ceres/Neptune
- **Volatility tiers**: low/medium/high/very_high/extreme affect price swings
- **Contraband inspection**: inspection_chance per planet, surrender or flee mechanics
- **Destination profit estimates**: Galaxy map shows cargo profit at each destination

### Corporation & Contract System

8 corporations with planet presence and contract offerings:

| Corp | Abbrev | Archetype | Home Planet | Specialty |
|------|--------|-----------|-------------|-----------|
| Martian Mining Consortium | MMC | Mining | Mars | Ore, Parts |
| Mercury Extraction Corp | MEC | Mining | Mercury | Ore, Parts |
| Europa Research Initiative | ERI | Research | Europa | Tech, Medicine, Artifacts |
| Venus Luxury Holdings | VLH | Leisure | Venus | Entertainment, Luxury |
| Jovian Fuel Authority | JFA | Gas Giant | Jupiter | Fuel |
| Ganymede Agricultural Trust | GAT | Agricultural | Ganymede | Grain |
| Terran Transit Alliance | TTA | Crossroads | Earth | Multi-commodity |
| Shadow Syndicate | SS | Smuggler | Ceres | Contraband |

**Contract Types:**
- `cargo_haul` - Move goods from A to B (sealed or player-sourced)
- `supply_run` - Deliver goods to corp facility
- `embargo` - Avoid selling specific goods to rival planets
- `manipulation` - Affect prices/stock at target planet
- `vip_transport` - Transport corporate VIPs

**Standing System:**
- Range: 0-100, starts at 50
- 80+: Trusted (better payouts, priority over bots)
- 50-79: Neutral (standard access)
- 20-49: Low (fewer contracts)
- 0-19: Hostile (only recovery contracts)

**Key Files:**
- `src/models/corporation.gd` - Corporation data model
- `src/models/contract.gd` - Contract with Type/Tier/Status enums
- `src/models/sealed_cargo.gd` - Sealed cargo container
- `src/autoload/corporation_manager.gd` - Central manager
- `data/corporations.json` - Corp and contract template data
- `scripts/corporation_office.gd` - UI for contracts

**Sealed Cargo:**
- Fully opaque - player doesn't know contents
- May contain contraband (inspection risk)
- Cannot be opened, only delivered or discarded
- Weight counts toward cargo capacity
