# Economy System Fix Plan

## Critical Issues Identified

1. **Instant Profit Exploit** - Price changes on trade allow immediate buy-sell profit
2. **Ship Capacity Too Small** - Ships are 8-26t, making cargo decisions meaningless
3. **Weight/Value Imbalance** - Expensive items always light, no interesting tradeoffs
4. **No Sell Spread** - Buy and sell at same price removes trading friction

---

## Fix Priority Order

### Priority 1: Buy/Sell Spread (Critical - Fixes Exploit)

**Problem:** Player can buy commodity, immediately sell for profit due to price change mechanics.

**Solution:** Implement 5% fixed sell spread.

```
Buy Price: 100 cr
Sell Price: 95 cr (95% of buy price)
```

**Display:** Single price shown with note: "Price: 100 cr (sell at 95%)"

**Implementation:**
1. Modify `GameState.sell_commodity()` to apply 0.95 multiplier
2. Update market UI to show "(sell at 95%)" note
3. Update profit/loss calculations to account for spread

**Files to modify:**
- `src/autoload/game_state.gd` - Add sell spread multiplier
- `scripts/market.gd` - Update price display

---

### Priority 2: Ship Capacity Increase (4-5x)

**Problem:** Ships are 8-26t. With commodities at 1-5t, you can only carry 2-26 units total.

**Solution:** Multiply all ship cargo capacities by 4-5x.

| Ship | Current | New |
|------|---------|-----|
| Starter | 8-12t | 40-60t |
| Mid-tier | 15-20t | 75-100t |
| Advanced | 22-26t | 110-130t |

**Implementation:**
1. Update `data/ships.json` - Multiply `cargo_tonnes` by 4-5x
2. No other code changes needed - cargo system already uses these values

**Files to modify:**
- `data/ships.json` - Update cargo_tonnes values

---

### Priority 3: Commodity Weight/Value Redesign

**Problem:** All expensive things are light (1t), all cheap things are heavy (5t). No interesting choices.

**Solution:** Create mixed weight/value combinations across 12 commodities.

**New Weight Tiers:** 1-10t per unit

| Weight | Examples |
|--------|----------|
| Light (1-2t) | Data, Seeds, Spices |
| Medium (3-5t) | Food, Medicine, Tech |
| Heavy (8-10t) | Ore, Machinery, Fuel |

**New Commodity Matrix (12 items):**

| ID | Name | Weight | Base Price | Category | Notes |
|----|------|--------|------------|----------|-------|
| `ore` | Sparkle Rocks | 10t | 20 | Bulk | Heavy, cheap - classic bulk |
| `scrap` | Space Junk | 8t | 15 | Bulk | Heavy, very cheap |
| `grain` | Space Wheat | 5t | 35 | Standard | Medium weight, reliable |
| `fuel` | Gloop Juice | 8t | 45 | Standard | Heavy, always needed |
| `parts` | Clanky Bits | 5t | 60 | Standard | Medium, industrial |
| `medicine` | Glowing Pills | 3t | 80 | Standard | Light-medium, good margins |
| `tech` | Blinky Boxes | 4t | 100 | Standard | Medium weight, valuable |
| `machinery` | Big Clankers | 10t | 150 | Luxury | HEAVY + EXPENSIVE - unique! |
| `spices` | Zesty Dust | 1t | 120 | Luxury | Light, high value |
| `entertainment` | Fun Cubes | 2t | 180 | Luxury | Light, volatile |
| `artifacts` | Ancient Junk | 3t | 250 | Rare | Medium, very valuable |
| `contraband` | Definitely Legal | 2t | 400 | Contraband | Light, extreme risk/reward |

**Key Design Points:**
- **Machinery (10t, 150cr)** - Breaks "expensive = light" rule. High profit potential but eats cargo.
- **Fuel (8t, 45cr)** - Heavy but essential. Creates route planning tension.
- **Scrap (8t, 15cr)** - Very heavy, very cheap. Only profitable on specific routes.
- **Spices (1t, 120cr)** - Classic light luxury, but limited stock.

**Implementation:**
1. Update `data/commodities.json` with new weights and prices
2. Ensure weight calculations in `game_state.gd` still work correctly

**Files to modify:**
- `data/commodities.json` - New commodity definitions

---

### Priority 4: Price Variation by Commodity Type

**Problem:** All commodities have similar price ranges, making them feel same-y.

**Solution:** Different volatility creates different trading dynamics.

| Category | Price Range | Behavior |
|----------|-------------|----------|
| Bulk | 0.6x - 1.5x base | Stable, predictable |
| Standard | 0.5x - 2.0x base | Moderate swings |
| Luxury | 0.3x - 3.0x base | Wild swings |
| Rare | 0.4x - 4.0x base | Very volatile |
| Contraband | 0.2x - 5.0x base | Extreme |

**Example with new prices:**

| Commodity | Base | Low | High | Potential Profit |
|-----------|------|-----|------|------------------|
| Ore (Bulk) | 20 | 12 | 30 | +150% |
| Tech (Standard) | 100 | 50 | 200 | +300% |
| Entertainment (Luxury) | 180 | 54 | 540 | +900% |
| Contraband | 400 | 80 | 2000 | +2400% |

**Implementation:**
1. Add `volatility` field to commodities.json with min/max multipliers
2. Update price calculation in `game_state.gd` to use volatility
3. Ensure planet modifiers stack with volatility correctly

**Files to modify:**
- `data/commodities.json` - Add volatility_min, volatility_max
- `src/autoload/game_state.gd` - Update price calculation

---

### Priority 5: Auto-Notebook (Price Memory)

**Problem:** Player has no way to remember prices at other planets.

**Solution:** Auto-notebook tracks last-seen prices with staleness.

**Staleness Rules:**
- Prices older than 5 days: "Recent" (full confidence)
- Prices older than 10 days: "Stale" (yellow warning)
- Prices older than 20 days: "Old" (red warning, may be very different)

**Display on Galaxy Map:**
```
MARS COLONY (visited 3 days ago)
  Ore: 15 cr [Recent]
  Food: 68 cr [Recent]
  Tech: ?? (never seen)
```

**Implementation:**
1. Add `price_memory: Dictionary` to Player model
   - Structure: `{planet_id: {commodity_id: {price: int, day_seen: int}}}`
2. Update prices in memory when visiting a planet
3. Display remembered prices on galaxy map / travel screen
4. Color-code by staleness

**Files to modify:**
- `src/models/player.gd` - Add price_memory field
- `src/autoload/game_state.gd` - Update memory on planet visit
- `scripts/galaxy_map.gd` - Display remembered prices

---

## Implementation Checklist

### Phase 1: Critical Fix (Do First)
- [x] Add 5% sell spread to `game_state.gd`
- [x] Update market UI to show "(sell at 95%)"
- [ ] Test that instant profit exploit is fixed

### Phase 2: Capacity Fix
- [x] Update `ships.json` with 4-5x cargo capacity
- [ ] Verify cargo system still works correctly
- [ ] Test trading with larger cargo holds

### Phase 3: Commodity Redesign
- [x] Create new `commodities.json` with 12 items
- [x] Implement new weight values (1-12t range)
- [x] Add volatility fields to commodities
- [x] Update price calculation to use volatility
- [x] Update planets.json with new commodities (scrap, machinery, spices)
- [x] Update all unlock_day values to 0 (all planets available)
- [ ] Test price ranges at different planets

### Phase 4: Price Memory
- [ ] Add price_memory to Player model
- [ ] Record prices when visiting planets
- [ ] Display remembered prices on galaxy map
- [ ] Add staleness coloring

---

## Testing Scenarios

### Exploit Fix Test
1. Start game, go to any market
2. Buy 10 units of any commodity
3. Immediately try to sell
4. **Expected:** Sell price should be 5% lower, resulting in loss

### Cargo Capacity Test
1. Start with new ship capacities
2. Buy mixed cargo (some heavy, some light)
3. **Expected:** Can carry 40-60 units total on starter ship

### Weight/Value Tradeoff Test
1. At a planet with cheap Machinery (150cr, 10t each)
2. Compare profit potential vs cheap Spices (120cr, 1t each)
3. **Expected:** Machinery fills cargo fast but high profit; Spices many units but limited stock

### Price Memory Test
1. Visit Mars, note Ore price
2. Travel to Earth
3. Check galaxy map for Mars
4. **Expected:** Shows remembered Ore price with "Recent" indicator

---

## Data Changes Summary

### commodities.json (new)
```json
{
  "commodities": [
    {"id": "ore", "name": "Sparkle Rocks", "category": "Bulk", "base_price": 20, "weight_per_unit": 10, "volatility_min": 0.6, "volatility_max": 1.5},
    {"id": "scrap", "name": "Space Junk", "category": "Bulk", "base_price": 15, "weight_per_unit": 8, "volatility_min": 0.6, "volatility_max": 1.5},
    {"id": "grain", "name": "Space Wheat", "category": "Standard", "base_price": 35, "weight_per_unit": 5, "volatility_min": 0.5, "volatility_max": 2.0},
    {"id": "fuel", "name": "Gloop Juice", "category": "Standard", "base_price": 45, "weight_per_unit": 8, "volatility_min": 0.5, "volatility_max": 2.0},
    {"id": "parts", "name": "Clanky Bits", "category": "Standard", "base_price": 60, "weight_per_unit": 5, "volatility_min": 0.5, "volatility_max": 2.0},
    {"id": "medicine", "name": "Glowing Pills", "category": "Standard", "base_price": 80, "weight_per_unit": 3, "volatility_min": 0.5, "volatility_max": 2.0},
    {"id": "tech", "name": "Blinky Boxes", "category": "Standard", "base_price": 100, "weight_per_unit": 4, "volatility_min": 0.5, "volatility_max": 2.0},
    {"id": "machinery", "name": "Big Clankers", "category": "Luxury", "base_price": 150, "weight_per_unit": 10, "volatility_min": 0.3, "volatility_max": 3.0},
    {"id": "spices", "name": "Zesty Dust", "category": "Luxury", "base_price": 120, "weight_per_unit": 1, "volatility_min": 0.3, "volatility_max": 3.0},
    {"id": "entertainment", "name": "Fun Cubes", "category": "Luxury", "base_price": 180, "weight_per_unit": 2, "volatility_min": 0.3, "volatility_max": 3.0},
    {"id": "artifacts", "name": "Ancient Junk", "category": "Rare", "base_price": 250, "weight_per_unit": 3, "volatility_min": 0.4, "volatility_max": 4.0},
    {"id": "contraband", "name": "Definitely Legal", "category": "Contraband", "base_price": 400, "weight_per_unit": 2, "volatility_min": 0.2, "volatility_max": 5.0}
  ]
}
```

### ships.json (example changes)
```json
// Before
{"cargo_tonnes": 12}

// After (4x multiplier)
{"cargo_tonnes": 48}
```

---

## Success Criteria

1. **No instant profit** - Buying and immediately selling results in 5% loss
2. **Meaningful cargo choices** - Player must decide between heavy/cheap vs light/expensive
3. **Route discovery** - Player learns which planets are good for which goods
4. **Price variation** - Same commodity can be 3-5x different price at different planets
5. **Mixed strategies viable** - Bulk trading, luxury trading, and mixed all work
