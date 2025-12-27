# Gazil - Task Tracker

## Current Sprint: v0.1 Vertical Slice

### Completed
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

### In Progress
- [ ] Playtesting and balance tuning
- [ ] Bug fixes from initial testing

### Backlog
- [ ] Price trend indicators in market
- [ ] Confirm dialogs for expensive purchases
- [ ] Keyboard shortcuts
- [ ] Sound effects
- [ ] Background music
- [ ] Visual polish

## Known Issues
- None yet (needs testing)

## Notes
- Remember to test full game loop: new game → trade → travel → events → win/lose
- Check edge cases: run out of fuel, go bankrupt, max cargo
