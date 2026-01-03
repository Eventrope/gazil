# Gazil - Bot Competition System Specification

## Overview

This spec defines the bot/CPU opponent system for Gazil, transforming it from a solo trading game into a competitive experience against AI rivals. The goal is to create a living, reactive universe where bots have distinct personalities, affect the economy, and create emergent stories.

---

## V1.0 Scope (Core Bots)

**Included:**
- 5-10 configurable bot opponents
- 4 distinct bot personalities
- Bots trade, travel, upgrade, and compete economically
- Shared economy with partial market impact
- Leaderboard and news feed system
- Victory by highest credits after 200 days
- Bot bankruptcy/elimination
- Debug mode for AI transparency

**Deferred to v1.1+:**
- Space encounters (info trade, cargo trade, race wagers)
- Sabotage system (hire pirates, spread rumors, bribe officials)
- Skill tree and passive abilities
- Planet reputation system
- Notoriety and grudge systems
- Scanner upgrades for encounter chance

---

## Bot Personalities (V1.0)

### 1. The Vulture
- **Strategy:** Waits for price crashes from events, buys distressed goods
- **Behavior:** Patient, opportunistic, hoards cash until opportunities arise
- **Risk Level:** Low - only acts on clear advantages
- **Quirk:** Often found lingering at planets waiting for bad news

### 2. The Speedrunner
- **Strategy:** Short routes, high volume, low margins
- **Behavior:** Always moving, prefers nearby planets, trades frequently
- **Risk Level:** Medium - prioritizes speed over optimal prices
- **Quirk:** Rarely stays at any planet for long

### 3. The Gambler
- **Strategy:** High-risk routes, volatile commodities, all-in plays
- **Behavior:** Goes for big scores, ignores safe plays, unpredictable
- **Risk Level:** Very High - might explode in wealth or go bankrupt spectacularly
- **Quirk:** Makes decisions that seem irrational but occasionally pay off huge

### 4. The Steady
- **Strategy:** Reliable, predictable, consistent profits
- **Behavior:** Follows established trade routes, avoids extremes
- **Risk Level:** Very Low - slow and steady, rarely fails
- **Quirk:** Good benchmark for new players to understand the game

### Visual Identity
- Name + unique color per bot (minimal art for v1.0)
- Example: "Captain Vex" (red), "Zara Kell" (blue)

### Bot Names & Backstories
Each bot should have:
- A memorable name (human or alien, mixed universe)
- 1-2 sentence quirky backstory
- Personality-appropriate dialogue for news feed

---

## Economy Integration

### Market Impact
- **Partial Impact (50%):** Bot trades affect prices/supply at 50% strength compared to player trades
- When a bot buys 100 Food, supply decreases and prices rise as if 50 were bought
- Creates competition without total market lockout
- Player always gets first priority when both want same goods at same planet

### Bot Knowledge (Difficulty-Scaled)
| Difficulty | Price Memory | Route Planning |
|------------|--------------|----------------|
| Easy | Remembers prices for 5 days | Often suboptimal routes |
| Medium | Remembers prices for 15 days | Generally good routes |
| Hard | Remembers prices for 30 days | Near-optimal decisions |

### Bot Starting Credits (Difficulty-Scaled)
| Difficulty | Player Start | Bot Start |
|------------|--------------|-----------|
| Easy | 1,000 | 500 |
| Medium | 1,000 | 1,000 |
| Hard | 1,000 | 2,000 |

---

## Time & Turn System

### Core Principle
Time should feel fair - bots and player operate on similar time scales.

### Travel Pacing (Hybrid System)
1. Player initiates travel (e.g., 10 days to Mars)
2. Game simulates those 10 days for all bots
3. "Meanwhile..." summary shows what bots did during player's journey
4. Bots make proportional progress on their own routes
5. If bot started 5-day trip same time as player's 10-day trip, bot arrives mid-journey and can act again

### Port Time
- **Time frozen while in port** - browse market/shipyard freely
- Days only advance when player travels
- No pressure while making decisions

### Bot Turn Processing
- Instant calculation (no animations needed for v1.0)
- Results displayed via news feed
- Debug mode shows reasoning

---

## Bot AI Architecture

### Decision Loop (Per Game Day)
```
1. Evaluate current state (location, cargo, credits, fuel)
2. Check if should sell (is current planet good for held cargo?)
3. Check if should buy (are there cheap goods here worth carrying?)
4. Plan next destination (based on personality + knowledge)
5. Execute: Trade → Travel or Stay
6. Consider upgrades if at shipyard and can afford
```

### Personality Modifiers

| Factor | Vulture | Speedrunner | Gambler | Steady |
|--------|---------|-------------|---------|--------|
| Min profit margin to trade | 40% | 10% | 5% | 25% |
| Max travel distance preferred | Any | 3 days | Any | 5 days |
| Cash reserve kept | 50% | 20% | 0% | 40% |
| Willingness to wait | High | None | Low | Medium |
| Volatility preference | High | Low | Very High | Low |

### Fuel Management
- Bots consider fuel in all route decisions
- Always plan routes that allow refueling
- Will prioritize fuel purchase when below 30% capacity
- Smart enough to never get stranded (unlike Gambler who might cut it close)

### Upgrade Decisions
- Bots purchase upgrades when they can afford them
- Priority: Fuel Capacity → Cargo Capacity → Efficiency
- Personality affects threshold (Gambler buys ASAP, Steady waits for safety margin)

---

## Random Events & Bots

### Events Affect Bots
- Bots experience random events during travel just like player
- Same event pool, same probabilities
- Event outcomes affect bot state (cargo loss, credit gain, etc.)

### News Feed Integration
When bot experiences event:
```
"BREAKING: The Gambler's cargo raided by pirates near Jupiter!
Lost 30 units of Luxury Goods. They're reportedly 'not worried about it.'"
```

### Bot Event Choices
- Bots make event choices based on personality
- Gambler always picks risky option
- Steady always picks safe option
- Vulture/Speedrunner weigh risk/reward

---

## Information Display

### Leaderboard
- Shows all bots + player ranked by credits
- Full list, collapsed by default
- Expand to see: Name, Credits, Current Planet, Ship Type
- Your position always highlighted

### News Feed (Priority Filtered)
- End-of-day summary after each player travel
- Shows "important" events, summarizes minor ones
- Categories (all togglable):
  - Major transactions ("Captain Vex bought 50 Ore at Mars")
  - Event outcomes ("The Gambler lost cargo to pirates!")
  - Market shifts ("Food prices crashing at Earth due to oversupply")
  - Bankruptcies ("BREAKING: Local trader discovers bankruptcy, blames space pigeons")

### Debug Mode (Optional Toggle)
When enabled, shows bot reasoning:
```
[DEBUG] Speedrunner Decision:
- Current: Earth, 500 credits, 20 Food
- Considered: Mars (profit +200), Venus (profit +150)
- Chose: Mars (shorter travel, matches personality)
```

---

## Victory & Elimination

### Win Condition
- **Highest credits after 200 days wins**
- Timed game creates strategic depth
- Comeback mechanics possible until the end

### Bot Bankruptcy
- Bots can go bankrupt (credits ≤ 0, no cargo)
- Bankrupt bot is eliminated
- News headline announces their dramatic exit:
  ```
  "BREAKING: Zara Kell's trading empire collapses!
  Last seen selling their ship for 'one last big score.' It did not work out."
  ```
- Eliminated bots don't respawn - field thins over time

### End Game
- Awards ceremony screen
- Superlatives for player and bots:
  - "Most Profitable Trade"
  - "Most Distance Traveled"
  - "Luckiest" (best event outcomes)
  - "Most Dramatic Collapse" (for bankrupted bots)

---

## Game Setup

### Quick Start Defaults
- One-click "New Game" with preset defaults
- Options accessible in separate "Custom Game" menu

### Default Settings
- **Bot Count:** 5
- **Difficulty:** Medium
- **Game Length:** 200 days

### Custom Game Options
- Bot count: 5-10 (slider)
- Difficulty: Easy / Medium / Hard
- Game length: 100 / 200 / 300 days

---

## Quirky Tone Guidelines

### Universe
- Mixed humans and aliens
- Weird species with strange motivations
- Quirky names: "Captain Vex", "Blorgg the Inexplicable", "Susan"

### Writing Style
- News headlines should be absurdist/humorous
- Bot backstories should be memorable and weird
- Events can be silly while having real consequences

### Examples
```
"The Blorgg Consortium has cornered the market on Food.
They claim it's for 'religious purposes' but mostly they just really like sandwiches."

"MARKET ALERT: Ore prices spike after Mars mining union demands
'reasonable gravity' in the workplace."

"Captain Vex was spotted purchasing 47 units of Medicine.
When asked why, they simply whispered 'soon' and flew away."
```

---

## Future Systems (V1.1+)

### Space Encounters
- Chance meetings during travel (player scanner upgrade required)
- Options: Info trade, cargo trade, race wager, decline
- Identity revealed if previously met (reputation system)

### Sabotage System
- Available via "shady contact" random events
- Options: Hire pirates, spread rumors, bribe officials
- Builds notoriety (dual reputation - some planets respect it, others don't)

### Grudge System
- Bots remember player actions
- Hostile bots: worse encounters, market blocking, targeted sabotage
- General indicator (mood icons on bot portraits)
- Time heals grudges

### Skill Tree
- 3 branches: Trade Efficiency, Reputation Bonuses, Event Manipulation
- 5 tiers each (15 total perks)
- Points earned via hybrid system (time + achievements)
- Can't unlock everything - must specialize

### Planet Reputation
- Each planet has unique perks at reputation thresholds
- Earth: Trade efficiency bonus
- Mars: Fuel discounts
- etc.

### Planet Cultural Effects
- Planet quirks affect events and prices
- "Venus bans luxury goods during Festival of Silence"
- Adds depth and unpredictability

---

## Technical Implementation Notes

### GDScript Type Inference Rules

**CRITICAL:** GDScript cannot infer types from function return values or Dictionary/Array access. Always use explicit type annotations in these cases:

```gdscript
# BAD - These will cause "Cannot infer type" errors:
var result := some_function()         # Function returns are not type-inferred
var value := dict.get("key", default) # Dictionary access returns Variant
var item := array[0]                  # Array access returns Variant
var node := Node.new()                # .new() calls need explicit types

# GOOD - Use explicit type annotations:
var result: SomeType = some_function()
var value: String = dict.get("key", "")
var item: int = array[0]
var node: Node = Node.new()
```

**Safe to use `:=` (type inference works):**
```gdscript
var count := 0              # Integer literal
var ratio := 0.5            # Float literal
var name := "test"          # String literal
var flag := true            # Bool literal
var items := {"key": value} # Dictionary literal
var list := [1, 2, 3]       # Array literal
```

**Always explicit type for:**
- Any `.get()` call on Dictionary
- Any index access `[]` on Array or Dictionary
- Any function/method return value
- Any `.new()` constructor call
- Any static method call (e.g., `Bot.create()`)

### Bot State Structure
```
Bot {
  id: string
  name: string
  personality: "vulture" | "speedrunner" | "gambler" | "steady"
  color: Color
  credits: int
  cargo: Dictionary<commodity_id, quantity>
  fuel: int
  current_planet: string
  destination_planet: string | null
  days_until_arrival: int
  price_memory: Dictionary<planet_id, Dictionary<commodity_id, {price, day_recorded}>>
  ship: Ship
  is_eliminated: bool
}
```

### Key Systems to Modify
1. **GameState** - Track array of bots, process bot turns
2. **DataRepo** - Load bot personality definitions from JSON
3. **EventManager** - Apply events to bots, not just player
4. **Market** - Calculate partial impact from bot trades
5. **New: BotAI** - Decision-making engine per personality
6. **New: NewsManager** - Aggregate and filter news items
7. **UI: Leaderboard** - New collapsible panel
8. **UI: NewsFeed** - End-of-day summary screen
9. **UI: GameSetup** - Bot count, difficulty, length options
10. **UI: GameOver** - Awards ceremony

### Data Files to Add/Modify
- `data/bots.json` - Bot names, backstories, personalities
- `data/news_templates.json` - News headline templates
- `data/awards.json` - End-game award definitions

---

## Success Metrics

A successful v1.0 bot system should:
1. Make solo play feel like a competition, not just optimization
2. Create memorable moments via bot personalities and news
3. Add replayability through different bot matchups
4. Feel fair - player should win through skill, not exploitation
5. Be entertaining even when losing - quirky failures are fun
6. Run smoothly with 10 bots without performance issues
