# Gazil - Claude Code Context

## Project
Gazillionaire-inspired trading sim built with Godot 4.5.1

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
