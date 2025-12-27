# GDScript Coding Guidelines for AI Agents

## Common GDScript 4.x Errors to Avoid

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

## Project Structure

```
gazil/
├── data/           # JSON data files
├── scenes/         # .tscn scene files
├── scripts/        # Scene-specific GDScript files
├── src/
│   ├── autoload/   # Global singletons (GameState, DataRepo, etc.)
│   ├── models/     # Data model classes (Player, Planet, etc.)
│   └── utils/      # Utility functions
└── assets/         # Fonts, images, audio (verify paths exist!)
```
