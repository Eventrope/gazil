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

## Modding

All game content is defined in JSON files in the `/data/` folder. You can:
- Add new planets
- Create new commodities
- Design new random events
- Add ship upgrades

Just follow the existing format in each JSON file.

## Requirements

- Godot Engine 4.2 or higher
- No additional dependencies
