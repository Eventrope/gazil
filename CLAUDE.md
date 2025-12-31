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

### Contract System (Pending)
- Basic delivery contracts planned but not yet implemented
