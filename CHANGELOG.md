# Changelog

All notable changes to Gazil will be documented in this file.

## [0.1.0] - 2024-12-27

### Added
- Initial vertical slice release
- **Core Systems**
  - Data-driven design with JSON configuration files
  - GameState singleton for player state management
  - DataRepo singleton for static game data
  - EventManager singleton for random event handling
  - Save/load functionality (single save slot)

- **Gameplay**
  - 5 planets with unique price modifiers (Earth, Mars, Venus, Jupiter, Titan)
  - 6 tradeable commodities (Food, Ore, Tech, Luxury, Fuel Cells, Medicine)
  - Buy low/sell high trading mechanic
  - Fuel-based travel between planets
  - 10 random events with choice-based outcomes
  - 5 ship upgrades (cargo expansion, fuel tank, efficient engine)
  - Win condition: reach 100,000 credits
  - Lose conditions: bankruptcy or fuel depletion

- **UI Screens**
  - Main Menu (new game, load game, quit)
  - Galaxy Map (planet selection, travel, HUD display)
  - Market (commodity trading with buy/sell interface)
  - Shipyard (ship upgrades and refueling)
  - Travel Event (random event choices and outcomes)
  - Game Over (victory/defeat with statistics)

### Technical
- Godot 4.x with GDScript
- Modular scene-based architecture
- Seedable RNG for reproducible testing
- JSON-based content pipeline for easy modding
