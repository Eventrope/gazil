# Gazil - Economic & Market System Specification

## Overview

This spec redesigns Gazil's market, commodity, and economic systems to create strategic depth while maintaining the rapid, information-dense trading experience inspired by Gazillionaire (1994). The goal is to make trading decisions feel meaningful, routes discoverable, and the economy reactive.

---

## Design Principles

1. **Day Trader Mental Model** - Rapid decisions, high information density, quick scanning
2. **Full Information Assistance** - Game shows purchase prices, profit margins, trends
3. **Strategic Depth Priority** - Multiple valid strategies, interesting choices at every step
4. **Quirky Tone** - Absurdist commodity names and planet personalities

---

## Commodities

### Count & Categories

**10-12 commodities** organized into functional tiers:

| Category | Behavior | Volatility | Weight | Example Goods |
|----------|----------|------------|--------|---------------|
| Bulk | High volume, low margin | Low | Heavy | Raw materials |
| Standard | Balanced trading | Medium | Medium | Basic supplies |
| Luxury | Low volume, high margin | High | Light | Premium goods |
| Contraband | High risk, high reward | Extreme | Light | Illegal items |

### Commodity List (v1.0)

Each commodity has: **Quirky Name (Functional Category)**

| ID | Name | Category | Base Price | Weight | Volatility | Notes |
|----|------|----------|------------|--------|------------|-------|
| `ore` | Sparkle Rocks (Ore) | Bulk | 25 | 5 | Low | Mining planets produce heavily |
| `grain` | Space Wheat (Food) | Bulk | 30 | 4 | Low | Agricultural planets specialize |
| `fuel` | Gloop Juice (Fuel) | Standard | 50 | 3 | Low | Gas giants produce cheaply |
| `parts` | Clanky Bits (Parts) | Standard | 75 | 2 | Medium | Industrial planets manufacture |
| `medicine` | Glowing Pills (Medicine) | Standard | 100 | 1 | Medium | Research outposts produce |
| `tech` | Blinky Boxes (Tech) | Standard | 120 | 1 | Medium | High-tech planets export |
| `entertainment` | Fun Cubes (Entertainment) | Luxury | 180 | 1 | High | Leisure planets specialize |
| `artifacts` | Ancient Junk (Artifacts) | Luxury | 250 | 1 | High | Rare, found at specific locations |
| `luxury` | Shiny Things (Luxury) | Luxury | 300 | 1 | Very High | Elite planets consume heavily |
| `contraband` | Definitely Not Illegal (???) | Contraband | 400 | 1 | Extreme | High profit, confiscation risk |

### Volatility Tiers

Volatility affects how much prices swing from base:

| Tier | Price Range | Behavior |
|------|-------------|----------|
| Low | 70-130% of base | Stable, predictable |
| Medium | 50-150% of base | Moderate swings |
| High | 30-200% of base | Significant variation |
| Very High | 20-300% of base | Wild swings |
| Extreme | 10-500% of base | Contraband - anything goes |

---

## Planet Economy

### All Planets Unlocked

No unlock gates - all planets accessible from game start. Complexity comes from:
- Distance/fuel costs
- Price discovery
- Planet specializations

### Planet Archetypes

Each planet has 1-2 **signature goods** they produce (cheap to buy) and consume (expensive to sell). Some planets are **wildcards** with no strong pattern.

| Archetype | Produces (Cheap) | Consumes (Expensive) | Example Planets |
|-----------|------------------|---------------------|-----------------|
| Mining World | Ore, Parts | Food, Entertainment | Mercury, Mars, Ceres |
| Agricultural | Food, Grain | Tech, Medicine | Ganymede, Earth |
| Gas Giant | Fuel | Everything else | Jupiter, Neptune |
| Research Station | Medicine, Tech | Food, Luxury | Titan, Europa, Pluto |
| Leisure Hub | Entertainment, Luxury | Ore, Parts | Venus, Saturn |
| Crossroads | Nothing specific | Nothing specific | Earth (balanced) |

### Exclusive Goods

Some commodities are **only available** at specific planet types:
- **Artifacts** - Only found at outer system research stations (Titan, Pluto)
- **Contraband** - Only available at "shady" planets (Ceres, Neptune)

### Price Information at Destinations

Before traveling, player sees **relative indicators** (not exact prices):

```
MARS COLONY
  Ore: [CHEAP] - producing
  Food: [EXPENSIVE] - shortage
  Tech: [FAIR]
  ...

  Your Cargo Profit Estimate: ~1,200 cr
```

Indicators based on planet archetype + current events:
- `[CHEAP]` - Price below 60% of galactic average
- `[FAIR]` - Price within 40-160% of average
- `[EXPENSIVE]` - Price above 160% of average

---

## Stock & Supply System

### Reduced Base Stock

Current stocks are too high. New system:

| Planet Type | Signature Goods Stock | Other Goods Stock |
|-------------|----------------------|-------------------|
| Producer | 200-400 | 30-80 |
| Consumer | 20-50 | 50-100 |
| Balanced | 80-150 | 80-150 |

This means:
- Producer planets have lots of what they make
- Consumer planets have little of what they want
- Buying out stock is possible and impactful

### Stock Regeneration

**Production-based + slow regen hybrid:**

1. **Production** - Planets generate signature goods daily:
   - Mining worlds: +20-40 Ore/day
   - Farms: +20-40 Food/day
   - Gas giants: +30-50 Fuel/day

2. **Trade Ships** (background) - Random stock deliveries:
   - Every 3-7 days, a "supply ship" event
   - Adds 50-100 units of random goods
   - Announced via news: "Supply convoy arrives at Mars"

3. **Slow Decay** - Non-signature goods slowly deplete:
   - -5% per day if not replenished
   - Creates natural scarcity over time

### Player Trade Impact

**Slight impact** - Player trades nudge prices:

| Trade Size | Price Impact |
|------------|--------------|
| 1-10 units | No change |
| 11-50 units | 1-3% shift |
| 51-100 units | 3-5% shift |
| 100+ units | 5-10% shift |

Impact decays over 2-3 days back to baseline.

---

## Price Dynamics

### Price Changes During Travel

**Significant change** - Longer routes = more uncertainty:

| Travel Days | Price Drift |
|-------------|-------------|
| 1-2 days | 0-5% |
| 3-5 days | 5-15% |
| 6-10 days | 10-25% |
| 10+ days | 15-40% |

Creates risk/reward for long-distance trading. Short routes are safer but lower margin.

### Daily Fluctuation

All prices have small daily wobble:
- +/- 2-5% random variance each day
- Stacks with event effects
- Volatility tier affects range

---

## Event System

### Event Frequency

**Mixed system** - Daily minor + occasional major:

| Event Type | Frequency | Duration | Price Impact |
|------------|-----------|----------|--------------|
| Minor wobble | Daily | 1 day | 2-5% |
| Local event | Every 3-5 days | 2-4 days | 10-25% |
| Major event | Every 10-20 days | 5-10 days | 30-60% |

### Event Telegraphing

Some events are **announced in advance**:

```
NEWS TICKER:
"Festival of Lights begins on Venus in 3 days - Luxury goods expected to spike"
"Mining union vote on Mars tomorrow - Ore production may halt"
"BREAKING: Pirate raid at Ceres! Contraband prices soaring!"
```

| Event Type | Advance Notice |
|------------|----------------|
| Festivals/holidays | 3-5 days ahead |
| Political/labor | 1-2 days ahead |
| Disasters | No warning |
| Market crashes | Rumors only ("word is...") |

### Event Examples

**Local Events:**
- "Fungal bloom at Ganymede" - Food production doubled for 5 days
- "Solar flare near Mercury" - All prices +20% for 3 days
- "Research breakthrough at Titan" - Medicine prices drop 30%

**Major Events:**
- "Galactic Festival of Consumption" - Luxury prices +100% everywhere for 7 days
- "Fuel Crisis" - Fuel prices triple for 10 days
- "Trade War" - Two planets refuse each other's goods

---

## Contraband System

### Mechanics

Contraband goods have:
- **Very high profit margins** - Buy for 50cr, sell for 500cr at right location
- **Confiscation risk** - % chance of inspection at each planet
- **Fines** - If caught, pay credits penalty

### Inspection Chance

| Planet Type | Inspection Chance |
|-------------|------------------|
| Core worlds (Earth, Mars) | 40% |
| Outer stations | 20% |
| Shady ports (Ceres, Neptune) | 5% |

### Getting Caught

When caught, player chooses:

1. **Surrender** - Lose contraband, pay fine (50% of goods value)
2. **Run** - Skill check based on ship speed
   - Success: Escape, but can't dock at that planet for 10 days
   - Failure: Lose contraband, double fine, reputation hit

---

## Contract System

### Purpose

**Early game helper** - Provides direction for new players:

```
CONTRACT AVAILABLE:
"Deliver 30 Medicine to Pluto within 15 days"
Reward: 2,500 credits (guaranteed)
Penalty: -500 credits if late
```

### Contract Types

| Type | Difficulty | Reward | Deadline |
|------|------------|--------|----------|
| Basic Delivery | Easy | 1.2x cargo value | Generous |
| Rush Order | Medium | 1.8x cargo value | Tight |
| Bulk Shipment | Hard | 1.5x cargo value | Generous but heavy cargo |
| Emergency Supply | Variable | 2.5x cargo value | Very tight |

### Availability

- 2-3 contracts available at major ports
- Refresh every 5 days
- Player can hold 1 active contract at a time

---

## Market Screen UI

### Layout Philosophy

**Gazillionaire-inspired density** with modern clarity:

```
+------------------------------------------------------------------+
| MARKET - MARS COLONY                    Credits: 12,450  Day: 47 |
| Cargo: 45/100t                                                   |
+------------------------------------------------------------------+
| COMMODITY      | PRICE    | OWNED        | STOCK  | WT |         |
+----------------|----------|--------------|--------|----|---------+
| Sparkle Rocks  | 18 cr    | 20 @ 15cr    | 342    | 5t | [    ] |
| (Ore)          | (12-38)  | +60 profit   |        |    |         |
+----------------|----------|--------------|--------|----|---------+
| Space Wheat    | 54 cr    | --           | 23     | 4t | [    ] |
| (Food)         | (20-45)  | EXPENSIVE    |        |    |         |
+----------------|----------|--------------|--------|----|---------+
| [Selected commodity details and trade controls appear here]      |
+------------------------------------------------------------------+
| TRADE: Space Wheat                                               |
| [====|========] 50 units                                         |
| Buy: 2,700 cr total     [BUY MAX]  [BUY]  [SELL]  [SELL ALL]    |
+------------------------------------------------------------------+
```

### Row Information

Each commodity row shows:

| Column | Content | Notes |
|--------|---------|-------|
| Name | Quirky name + (Category) | Two lines |
| Price | Current + (range) | Color-coded: green=cheap, red=expensive |
| Owned | Quantity @ purchase price | Shows profit/loss if owned |
| Stock | Available units | Color: green=high, yellow=mid, red=low |
| Weight | Per-unit weight | For cargo planning |
| Selection | Radio/checkbox | Click to select for trading |

### Price Color Coding

Price number color indicates quality:

| Price Position | Color | Meaning |
|----------------|-------|---------|
| Bottom 15% | Bright Green | Excellent buy |
| 15-35% | Yellow-Green | Good buy |
| 35-65% | Yellow | Fair |
| 65-85% | Orange | Poor buy |
| Top 15% | Red | Terrible buy |

### Trade Controls

When commodity selected, show in detail panel:

1. **Quantity Slider** - Drag to select amount
2. **Quick Buttons** - BUY MAX, BUY, SELL, SELL ALL
3. **Cost/Profit Display** - Shows total transaction value
4. **Cargo Space Indicator** - Shows remaining space after trade

**BUY MAX** calculates: `min(affordable_units, cargo_space_available, stock_available)`

---

## Information Display

### What Player Always Sees

| Information | Where | Notes |
|-------------|-------|-------|
| Current credits | Header | Always visible |
| Cargo used/capacity | Header | "45/100t" format |
| Current day | Header | Day counter |
| All commodity prices | Market rows | Color-coded |
| Owned cargo + purchase price | Market rows | Per commodity |
| Profit/loss per commodity | Market rows | If owned |
| Stock levels | Market rows | Color-coded |

### What Player Discovers

| Information | How Discovered |
|--------------|----------------|
| Exact prices at other planets | By visiting |
| Price trends over time | Observation + news |
| Event predictions | News ticker |
| Best trade routes | Experience + calculation |

---

## Technical Implementation Notes

### GDScript Type Inference Rules

(Same as main SPEC.md - always use explicit types for function returns, Dictionary access, .new() calls)

### Commodity Structure

```gdscript
Commodity {
  id: String
  name: String              # "Sparkle Rocks"
  category: String          # "Ore"
  base_price: int           # 25
  weight_per_unit: int      # 5
  volatility: String        # "low", "medium", "high", "very_high", "extreme"
  legality: String          # "legal", "contraband"
  description: String
  exclusive_to: Array       # Planet IDs where this can be bought, [] = everywhere
}
```

### Planet Economy Structure

```gdscript
PlanetEconomy {
  planet_id: String
  archetype: String         # "mining", "agricultural", "gas_giant", etc
  produces: Array[String]   # Commodity IDs this planet makes cheaply
  consumes: Array[String]   # Commodity IDs this planet wants
  inspection_chance: float  # 0.0-1.0 for contraband

  # Dynamic state
  current_stock: Dictionary # {commodity_id: quantity}
  current_prices: Dictionary # {commodity_id: price}
  price_modifiers: Dictionary # {commodity_id: float}
}
```

### Market State

```gdscript
MarketState {
  # Per-commodity tracking
  purchase_history: Dictionary  # {commodity_id: {quantity: int, avg_price: float}}

  # Global
  galactic_averages: Dictionary # {commodity_id: average_price}
  active_events: Array[MarketEvent]
  news_ticker: Array[String]
}
```

### Data Files to Modify

1. `data/commodities.json` - Replace with new 10-12 commodity list
2. `data/planets.json` - Add archetype, produces, consumes, inspection_chance
3. `data/market_events.json` - New file for event definitions
4. `data/contracts.json` - New file for contract templates

### Scripts to Modify

1. `scripts/market.gd` - Complete rewrite for new UI layout
2. `src/autoload/game_state.gd` - Add purchase tracking, profit calculation
3. `src/autoload/data_repo.gd` - Load new commodity/event data

---

## Success Metrics

A successful economy redesign should:

1. **Make decisions clearer** - Player knows good deals at a glance
2. **Create meaningful routes** - Some planet pairs are naturally profitable
3. **Add strategic depth** - Multiple valid strategies (safe bulk, risky luxury, etc)
4. **Feel fast** - Trading is quick, not tedious
5. **Be discoverable** - Routes and patterns emerge through play
6. **Support bots** - Economy works for AI traders too
7. **Match quirky tone** - Names and events are memorable and fun

---

## Implementation Priority

### Phase 1: Core Mechanics
1. New commodity list (10-12 items)
2. Planet archetypes and signatures
3. Reduced stock levels
4. Basic price volatility

### Phase 2: UI Redesign
1. New market screen layout
2. Purchase price tracking
3. Profit/loss display
4. Quantity slider + Buy Max

### Phase 3: Events & Contracts
1. Event system with telegraphing
2. Contract system
3. Contraband risk mechanics

### Phase 4: Polish
1. Visual hierarchy improvements
2. Color-coded price quality
3. Destination profit estimates
