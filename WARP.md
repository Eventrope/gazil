# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Tooling & Requirements

- Engine: Godot 4.x (README and `project.godot` target Godot 4.2+ with 4.5 features).
- Project entry: `project.godot` at the repo root.
- Main scene: `res://scenes/main_menu.tscn` (configured in `project.godot`).

### Common Commands

Replace `godot4` below with your local Godot 4 executable name or path.

- Launch the editor for this project:
  - `godot4 --path . --editor`
- Run the game from the CLI (uses the main scene from `project.godot`):
  - `godot4 --path .`
- Run the game from the GUI:
  - Open the project folder (or `project.godot`) in Godot 4.2+ and press F5.

There is no scripted build/export pipeline or automated test suite in this repo; use Godot's export presets from the editor when you need builds, and verify changes by playtesting the game.

## High-Level Architecture

This is a Godot 4 project for a Gazillionaire-style space trading sim. The code is organized into four main layers:

- **Data** (`data/`): JSON definitions for planets, commodities, events, news, upgrades, ships, ship traits, investments, crew roles, and passengers.
- **Domain** (`src/models/`, `src/autoload/`, `src/utils/`): Core game logic, data models, and global services.
- **UI Scenes** (`scenes/`, `scripts/`): Screen-specific scenes and GDScript controllers that drive the UI and call into the domain layer.
- **Persistence** (`src/autoload/game_state.gd`, `saves/`): Save/load, session management, and derived game state.

### Autoload Singletons (Global Services)

These are configured in `project.godot` under `[autoload]` and are the main entry points for game logic:

- **`DataRepo` (`src/autoload/data_repo.gd`)**
  - Loads all JSON content from `data/` at startup and builds typed objects (`Planet`, `Commodity`, `GameEvent`, `Ship`, etc.).
  - Exposes lookup and query APIs such as `get_planet`, `get_all_planet_ids`, `get_commodity`, `get_events_for_trigger`, `get_upgrade`, `get_starter_ships`, `get_crew_role`, `get_investment_type`.
  - Computes derived economy metrics like `get_commodity_price_range` and `get_price_quality` for UI hints (price bands and "BUY / SELL" indicators).

- **`GameState` (`src/autoload/game_state.gd`)**
  - Owns the current `Player` instance and all dynamic world state: per-planet price drifts, planet stock levels, active news events, and overall game activity flags.
  - Drives the core game loop via methods such as:
    - `start_new_game` / `finalize_new_game` / `return_to_main_menu`.
    - `advance_day` (price drift, stock regeneration, news, banking, crew wages, investments).
    - `travel_to` (fuel consumption, travel time, breakdown checks, passenger mood updates, random travel events, day advancement).
    - Trading and economy actions (`buy_commodity`, `sell_commodity`, `get_price_at`, `get_stock_at`, `get_fuel_price_at`).
    - Progression systems: upgrades, crew hiring/firing, investments, banking (savings and loans), ship repairs.
  - Emits many signals (`game_started`, `game_ended`, `day_advanced`, `player_traveled`, `news_event_started/ended`, `bank_interest_applied`, `loan_overdue`, `ship_breakdown`, `investment_matured`, `crew_quit`) that UI scenes can subscribe to.
  - Implements game-over checks (`check_game_over`) based on win condition (net worth ≥ 100,000 credits) and lose conditions (bankruptcy, stranded without fuel).
  - Handles save/load via JSON at `user://savegame.json`, including versioning (`SAVE_VERSION`) and serialization of `Player`, price drifts, stocks, and active news events.

- **`EventManager` (`src/autoload/event_manager.gd`)**
  - Handles random *travel and other game events* (separate from news): chooses events based on trigger (e.g., "travel"), weight, and conditional checks against the current `Player`.
  - Uses an internal `RandomNumberGenerator` with optional seeding for deterministic behavior.
  - Exposes `roll_event` to select an event and `execute_choice` to apply the outcome of a player choice, updating credits, fuel, and cargo, and recording statistics.

- **`NewsManager` (`src/autoload/news_manager.gd`)**
  - Manages *galactic news events* that create global modifiers to economy and travel.
  - `process_day` determines which news events expire and whether new ones spawn, based on per-template conditions (min day, max concurrent, weight).
  - `get_combined_effects` aggregates all active news effects into a single structure used by `GameState` and UI screens (price/stock modifiers, travel time modifiers, access blocking, and event-chance modifiers).
  - Helper APIs (`is_planet_accessible`, `get_travel_time_modifier`, `get_event_chance_modifier`) encapsulate how news interacts with specific routes.

- **`PassengerManager` (`src/autoload/passenger_manager.gd`)**
  - Loads passenger types from `data/passenger_types.json` and manages passenger contracts available at each planet.
  - Generates contracts (`generate_contracts_at`, `refresh_contracts_at`) based on planet, unlocked destinations, and player passenger reputation.
  - Tracks and updates accepted passenger contracts on the `Player`:
    - `deliver_passengers` handles delivery, payments, and reputation changes.
    - `process_travel_effects` updates passenger mood during travel (delays and breakdown penalties) and emits signals.
    - `abandon_contract` applies reputation penalties when contracts are dropped.
  - Provides aggregate metrics like `get_total_expected_payment` for active contracts.

### Core Models (`src/models/`)

Domain objects under `src/models/` represent persistent game state and data definitions. Key classes include:

- **`Player` (`src/models/player.gd`)**
  - Holds the player's economic and progression state: credits, cargo, fuel, current planet, day counter, statistics, banking (balance, loans, credit rating), passengers, investments, and crew.
  - Provides core operations for credits, fuel, travel, and banking (`add_credits`, `spend_credits`, `add_fuel`, `use_fuel`, `travel_to`, deposit/withdraw, loans and repayments) and emits signals for UI updates.
  - Encodes win/lose-related logic (`has_won`, `is_stranded`, `is_bankrupt`, `get_net_worth`, `has_overdue_loans`).
  - Offers helper methods for passenger and crew capacity and wages, and complete `to_dict` / `from_dict` serialization used by `GameState`.

- **`Planet` (`src/models/planet.gd`)**
  - Encapsulates static planet data: distances to other planets, per-commodity price modifiers, volatility, unlock day, category, base stock, stock regeneration rates, and fuel price modifier.
  - Provides methods used by autoloads and UI: `get_distance_to`, `get_price_modifier`, `is_unlocked`, `get_base_stock`, `get_stock_regen`.

- **`Ship` (`src/models/ship.gd`)**
  - Represents the player's ship template plus runtime state such as installed upgrades, modules, and current reliability.
  - Core behaviors:
    - Fuel usage and cost (`get_fuel_cost`).
    - Upgrade application (`apply_upgrade`, `has_upgrade`, module-slot tracking).
    - Reliability degradation and repair (`degrade_reliability`, `repair`, `get_breakdown_chance`, `get_repair_cost_per_point`).
  - Serializable via `to_dict` / `from_dict` and constructed from JSON data in `data/ships.json` through `DataRepo`.

Other model classes (e.g., `Commodity`, `GameEvent`, `NewsEvent`, `Investment`, `PassengerContract`, `CrewMember`) live alongside these and follow the same pattern: ingest JSON data, expose domain-specific operations, and support serialization for saving.

### Utility Layer (`src/utils/rng.gd`)

- **`RNG`** is a small wrapper around `RandomNumberGenerator` that provides a singleton instance with helpers (`set_seed`, `randf`, `randf_range`, `randi`, `randi_range`, `randfn`).
- Prefer using this utility when you need deterministic randomness in new systems or tests, instead of calling `randf()` / `randi()` directly.

## UI Scenes & Flow

UI and screen-specific logic lives under `scenes/` (Godot scenes) and `scripts/` (paired controllers):

- Each `.tscn` scene in `scenes/` generally has a corresponding script in `scripts/` with the same basename (e.g., `market.tscn` ↔ `scripts/market.gd`).
- Scenes act as *thin controllers* that:
  - Read from `GameState`, `DataRepo`, and other autoloads.
  - Render information using Godot UI nodes.
  - Invoke domain methods (e.g., trading, travel, banking, hiring) in response to UI events.

Key screens include:

- **Main Menu** (`scenes/main_menu.tscn`, `scripts/main_menu.gd`)
  - Entry point of the game; can start a new game or load an existing save.
  - Uses `GameState.start_new_game()` before transitioning to ship selection, and `GameState.load_game()` before entering the galaxy map.
  - Provides a quit action that calls `get_tree().quit()`.

- **Galaxy Map & Travel** (`scenes/galaxy_map.tscn` and its script)
  - Central hub for moving between planets; typically invokes `GameState.travel_to()` and reacts to day advancement, news events, and passenger effects.

- **Market** (`scenes/market.tscn`, `scripts/market.gd`)
  - Displays commodities available at the current planet using data from `DataRepo` and dynamic prices/stocks from `GameState`.
  - Uses `DataRepo.get_commodity_price_range` and `get_price_quality` to color-code prices and rating badges, and `NewsManager.get_combined_effects` to show news-driven price arrows.
  - Invokes `GameState.buy_commodity` / `sell_commodity` and checks `GameState.check_game_over()` after sales, transitioning to `game_over.tscn` when appropriate.

- **Other feature screens** (banking, crew, passengers, investments, shipyard, news, travel events, etc.)
  - Implement UI around the systems in `GameState`, `EventManager`, `NewsManager`, and `PassengerManager`:
    - `bank.tscn`, `investment_office.tscn` – interact with the banking and investment APIs on `GameState`.
    - `crew_quarters.tscn` – manage crew and wages.
    - `passenger_lounge.tscn` – display and accept passenger contracts via `PassengerManager`.
    - `galactic_news.tscn` – present active news events (instances of `NewsEvent`).
    - `travel_event.tscn` – show random events triggered by `EventManager` and handle player choices.
    - `ship_selection.tscn`, `shipyard.tscn` – choose and upgrade ships using `DataRepo` and `GameState`.
    - `game_over.tscn` – summarize outcome and allow returning to the main menu.

The UI layer should avoid duplicating game logic; prefer to call into the autoloads and models.

## Data-Driven Content & Modding

The game is intentionally data-driven, as described in `README.md`:

- All core content lives in JSON files under `data/` (planets, commodities, events, news events, upgrades, ships, ship traits, investments, crew roles, passenger types).
- `DataRepo` and `PassengerManager` are responsible for loading and validating these files at runtime.
- When adding or modifying content:
  - Keep JSON structure consistent with existing entries in each file.
  - Ensure new IDs are unique and referenced correctly (e.g., ship IDs used when starting a new game, event IDs referenced by news templates, crew roles used by crew creation).

## GDScript Guidelines for Agents

For AI-generated changes, follow the GDScript conventions defined in `agents.md` at the repo root. Important points:

- **Type inference with Dictionaries/Arrays**
  - Do *not* rely on `:=` for values derived from Dictionary/Array operations when you'll use them in arithmetic or typed contexts.
  - Instead, declare variables with explicit types, e.g. `var count: int = dict.get("key", 0)` or `var quality: float = values[i]`.

- **Variable scope across conditionals**
  - If a variable needs to be read after an `if`/`else` block, declare it *before* the conditional with a sensible default value, and only assign inside the branches.

- **Type annotations best practices**
  - Inference is fine for simple literals, but use explicit types when:
    - Storing results from functions that return `Variant`.
    - Holding instances of custom classes (`var player: Player = Player.new()`).
    - Reading from Dictionaries/Arrays that are later used in typed expressions.

- **Null/empty checks and safe Dictionary access**
  - Always check for `null` before using objects that may be missing (e.g., planets, commodities, ships).
  - Use `.is_empty()` and `is_empty()` for Arrays where appropriate.
  - Prefer `dict.get("key", default)` with explicit typed variables over direct indexing when keys may be absent.

- **Signals and connections**
  - Declare signals with clear, typed arguments (e.g., `signal value_changed(old_value: int, new_value: int)`).
  - When connecting signals in code and passing extra data, use `button.pressed.connect(_on_pressed.bind(extra_arg))`.

- **Resource paths**
  - When adding new scenes, scripts, or autoloads, verify that:
    - Paths in `project.godot` (e.g., `[application] run/main_scene`, `[autoload]` entries) match actual files.
    - Any new assets (fonts, images, audio) use correct `res://` paths and exist in the project.

Refer to `agents.md` for concrete examples; keep new code consistent with these patterns and with the existing autoload/model architecture described above.
