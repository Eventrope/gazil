# Corporations System Specification

## Overview

Corporations are a hybrid system in Gazil that operates across multiple layers: they control planetary infrastructure, influence the economy, and offer contracts to players. The primary player interaction is through a **contract system** where corporations offer cargo hauling, supply runs, embargoes, and market manipulation missions.

### Design Goals
- Add strategic depth through contract-based missions
- Create meaningful economic influence without disrupting core trading loop
- Enable competition between player and AI bots for contract opportunities
- Integrate with existing news events system for dynamic galaxy state

---

## Corporations

### Corporation Count & Archetypes

8 corporations, aligned with existing planet archetypes:

| Corporation | Archetype | Home Planet | Secondary Presence | Specialty |
|-------------|-----------|-------------|-------------------|-----------|
| **Martian Mining Consortium** | Mining | Mars | Mercury | Ore, Parts |
| **Mercury Extraction Corp** | Mining | Mercury | Mars | Ore, Parts |
| **Europa Research Initiative** | Research | Europa | Titan, Pluto | Tech, Medicine, Artifacts |
| **Venus Luxury Holdings** | Leisure | Venus | Saturn | Entertainment, Luxury |
| **Jovian Fuel Authority** | Gas Giant | Jupiter | Neptune | Fuel |
| **Ganymede Agricultural Trust** | Agricultural | Ganymede | - | Grain, Food |
| **Terran Transit Alliance** | Crossroads | Earth | Ceres | Multi-commodity logistics |
| **Shadow Syndicate** | Smuggler | Ceres | Neptune | Contraband (High Risk/Reward) |

### Naming Convention
Serious corporate naming style (e.g., "Martian Mining Consortium", not "Sparkle Rock Inc.")

### Visual Identity
Each corporation has:
- Unique logo/icon (displayed on galaxy map near affiliated planets)
- Color scheme
- Visual styling for UI elements

### Territory System
- **Primary Presence**: Full corp office, all contracts available, strongest economic influence
- **Secondary Presence**: Limited contracts, reduced economic influence
- Galaxy map displays small corp logos near planets with presence

---

## Standing System

### Numeric Scale
- Range: 0-100
- Initial standing: **50 (Neutral)** for all corporations
- Standings are **per-playthrough** (reset with each new game)

### Standing Changes
- **Contracts Only**: Standing changes exclusively from completing or failing contracts
- Regular trading does NOT affect standing
- No rivalry impact: Working with one corp does not affect standing with others

### Standing Thresholds & Effects

| Standing | Level | Effects |
|----------|-------|---------|
| 80-100 | Trusted | Better contract payouts, priority over bots, exclusive high-reward contracts, price discounts at corp planets |
| 50-79 | Neutral | Standard contracts available, standard pricing |
| 20-49 | Low | Fewer contracts available, slightly worse rates |
| 0-19 | Hostile | Worse prices at corp markets, only "Recovery" contracts offered |

### Recovery Contracts
When standing drops below 20, corporations offer special "make amends" contracts designed to rebuild trust (typically low-pay, reliable delivery missions).

---

## Contract System

### Contract Types

#### 1. Cargo Hauling
- Move X units of commodity from A to B within deadline
- **Sealed Container** variant: Corporation provides mystery cargo
- **Player-Sourced** variant: Player must acquire goods at origin

#### 2. Supply Runs
- Deliver specific goods to corp-owned facility
- Player sources the goods themselves
- Fixed destination, player chooses origin

#### 3. Trade Embargo
- Avoid selling specified commodities to rival territories for a duration
- **Violation Detection**: Probability-based, tied to planet inspection chances
- Penalty: Financial + standing loss

#### 4. Market Manipulation
- Push prices/stock levels at target planet to benefit the corporation
- **Goal-Oriented**: Contract specifies target (price threshold or stock level)
- **Multiple Methods**: Player chooses how to achieve (buy/sell volumes, route manipulation)

#### 5. VIP Executive Transport (ties to Passenger System)
- Transport corporate VIPs between planets
- Separate from regular passenger contracts
- Higher pay, stricter requirements

### Contract Structure

```json
{
  "id": "template_id",
  "corp_id": "martian_mining",
  "type": "cargo_haul",
  "tier": "standard",
  "commodity": "ore",
  "quantity": 50,
  "cargo_provided": false,
  "origin": "mars",
  "destination": "venus",
  "deadline_days": 8,
  "reward": 2500,
  "penalty": 1250,
  "standing_gain": 5,
  "standing_loss": 8,
  "requirements": {
    "min_cargo": 250,
    "min_standing": 30
  }
}
```

### Contract Tiers

| Tier | Deadline | Reward | Description |
|------|----------|--------|-------------|
| Express | Tight (just enough if efficient) | +50% | Time pressure, premium pay |
| Standard | Comfortable buffer | Base | Allows for detours |

### Contract Limits
- **No hard limit** on concurrent contracts
- Cargo space naturally limits capacity
- No per-corporation limit

### Contract Availability
- **Refresh Trigger**: New contracts appear when player arrives at planet with corp presence
- **Bot Competition**: Bots can claim contracts; player sees "Contract taken by [Bot Name]" in notifications
- **Priority Access**: High standing (80+) grants first pick before bots

### Ship Requirements
Contracts can require:
- Minimum cargo capacity
- Minimum speed
- Minimum fuel range
- Specific upgrades installed

Requirements displayed upfront; player cannot accept if unqualified.

---

## Sealed Cargo Mechanics

### Mystery Contents
- Sealed containers are **fully opaque** - player does not know contents
- Could be legal goods or contraband

### No Betrayal
- Sealed cargo is **mechanically locked**
- Player cannot break seal, inspect, or sell contents
- Only options: Deliver or Abandon (discard)

### Inspection Risk
- If inspected at high-inspection planet and cargo is contraband:
  - **Player Bears Risk**: Fines and confiscation apply to player
  - No compensation from corporation
  - "Should have known better than to take mystery cargo"

### Expired Contracts
- If deadline passes with sealed cargo still held:
  - Cargo remains sealed but **becomes worthless dead weight**
  - Must be discarded to free cargo space
  - Counts as contract failure (standing loss + financial penalty)

---

## Contract Failure

### Consequences
- **Financial Penalty**: Proportional to contract value (specified per contract)
- **Standing Loss**: Specified per contract (typically higher than standing gain)
- Sealed cargo becomes worthless

### Abandonment
- Player can abandon contracts at any time
- Same consequences as failure

---

## Economic Impact

### Full Economic Control
Corporations influence the economy at planets where they have presence:

1. **Price Influence**: Corp specialty commodities are cheaper to buy/sell at corp planets
2. **Stock Influence**: Corp planets have different stock levels and regen rates
3. **Shortage Events**: Corps can temporarily cause commodity shortages (stock = 0)

### Standing-Based Pricing
- High standing (80+): 5-10% discount on purchases, bonus on sales at corp planets
- Low standing (<20): 5-10% penalty on trades at corp planets

---

## News Events Integration

### Bidirectional System
Corporations both **generate** and **react to** news events.

### Corporation-Generated Events

#### Market Events
- Corp announces expansion/contraction
- Affects prices at their planets for X days

#### Contract Bonanzas
- Corp launches major initiative
- Temporary surge in contract availability and rewards

#### Inter-Corp Drama
- Merger rumors
- Corporate scandals
- Rivalry escalation
- May affect multiple corporations

### News Affecting Corporations
- Outbreak events increase medical corp contract demand
- Piracy events affect smuggler corp activity
- Political events can block/open corp territories

---

## Competition Mode Integration

### Full Integration
- Corporations function in competition mode
- Bots compete for the same contracts as player

### Bot Behavior
- Bots evaluate and accept contracts based on their strategy
- Bots with higher standings have priority access
- Bots can complete contracts, gaining credits and standing

### Visibility
- **Full Transparency**: Player sees when bots take contracts
- Notification: "Contract taken by [Bot Name]"
- End-of-day summary available

---

## UI/UX Design

### Access Points

#### Galaxy Map - System-Wide View
- "Contracts" button opens system-wide contract board
- Shows all available contracts across galaxy
- Filter by corp, type, destination

#### Planet Screens - Local Office
- "Corp Office" button when at planet with corp presence
- Shows contracts offered at this location
- Corp standings display
- Tab system for multiple corps at same planet

### Galaxy Map Indicators
- Small corp logos displayed near planets with presence
- Major corps (primary presence) have larger/more prominent logos

### Contract UI Elements
- Clear deadline display (days remaining)
- Tier indicator (Express/Standard)
- Sealed cargo warning icon
- Ship requirement checklist

---

## Data Model

### New File: `data/corporations.json`

```json
{
  "corporations": [
    {
      "id": "martian_mining",
      "name": "Martian Mining Consortium",
      "abbreviation": "MMC",
      "archetype": "mining",
      "home_planet": "mars",
      "secondary_planets": ["mercury"],
      "specialty_commodities": ["ore", "parts"],
      "color": "#CC4400",
      "description": "The largest mining operation in the inner system..."
    }
  ],
  "contract_templates": [
    {
      "id": "mining_haul_standard",
      "corp_id": "martian_mining",
      "type": "cargo_haul",
      "tier": "standard",
      "commodity_options": ["ore", "parts"],
      "quantity_range": [20, 80],
      "destination_options": ["venus", "saturn", "earth"],
      "deadline_base": 10,
      "reward_per_unit": 25,
      "penalty_ratio": 0.5,
      "standing_gain": 3,
      "standing_loss": 5,
      "cargo_provided": false,
      "requirements": {
        "min_standing": 0
      }
    }
  ]
}
```

### Player Model Additions

```gdscript
# In Player class
var corp_standings: Dictionary = {}  # {corp_id: int (0-100)}
var active_contracts: Array = []      # Array of Contract objects
var sealed_cargo: Array = []          # Array of sealed container objects
```

### New Models

#### Corporation
```gdscript
class_name Corporation
extends RefCounted

var id: String
var corp_name: String
var abbreviation: String
var archetype: String
var home_planet: String
var secondary_planets: Array
var specialty_commodities: Array
var color: Color
var description: String
```

#### Contract
```gdscript
class_name Contract
extends RefCounted

var id: String
var corp_id: String
var type: String  # "cargo_haul", "supply_run", "embargo", "manipulation", "vip_transport"
var tier: String  # "express", "standard"
var commodity: String
var quantity: int
var cargo_provided: bool
var origin: String
var destination: String
var deadline_day: int
var reward: int
var penalty: int
var standing_gain: int
var standing_loss: int
var sealed_cargo_id: String  # If cargo provided, reference to sealed cargo
var requirements: Dictionary
var status: String  # "available", "accepted", "completed", "failed", "expired"
```

#### SealedCargo
```gdscript
class_name SealedCargo
extends RefCounted

var id: String
var contract_id: String
var weight: int
var is_contraband: bool  # Revealed only on inspection
var actual_commodity: String  # Hidden from player
var actual_quantity: int  # Hidden from player
```

---

## New Autoloads

### CorporationManager
```gdscript
# Responsibilities:
# - Load and cache corporation data
# - Track player standings
# - Generate contracts from templates
# - Process contract completion/failure
# - Handle bot contract competition
# - Trigger corp-related news events

signal contract_available(contract: Contract)
signal contract_taken(contract: Contract, taker: String)
signal contract_completed(contract: Contract, by_player: bool)
signal contract_failed(contract: Contract, reason: String)
signal standing_changed(corp_id: String, new_standing: int)
```

---

## Smuggler Corporation: Shadow Syndicate

### Unique Characteristics
- Operates from Ceres and Neptune (low inspection zones)
- Deals primarily in contraband
- **Higher Risk/Reward**:
  - Contracts pay 50-100% more than equivalent legitimate contracts
  - Penalties are 2x standard
  - Standing loss on failure is severe

### Sealed Cargo
- Smuggler sealed cargo is always contraband
- Very high pay, but player risks inspection penalties
- Players must plan routes through low-inspection systems

---

## Implementation Phases

### Phase 1: Foundation
- Corporation data model and JSON structure
- CorporationManager autoload
- Player standing tracking
- Basic cargo hauling contracts
- UI: Contract board on galaxy map

### Phase 2: Full Contract System
- All contract types (supply, embargo, manipulation, VIP)
- Sealed cargo mechanics
- Contract requirements checking
- Express/Standard tiers
- UI: Planet corp offices with tabs

### Phase 3: Economic Integration
- Corp price/stock influence
- Shortage events
- Standing-based pricing

### Phase 4: Competition Mode
- Bot contract competition
- Priority access for high standing
- Visibility notifications

### Phase 5: News Integration
- Corp-generated news events
- News affecting corps
- Inter-corp drama events

### Phase 6: Visual Polish
- Corporation logos and icons
- Color-coded UI elements
- Galaxy map indicators

---

## Balance Considerations

### Contract Rewards
- Should be competitive with pure trading profits
- Express tier must justify time pressure risk
- Sealed cargo mystery should have appropriate risk premium

### Standing Progression
- Reaching high standing (80+) should take significant effort (20-30 contracts)
- Recovery from hostile standing should be possible but slow

### Bot Competition
- Bots should take contracts at realistic rates (not monopolize)
- Player priority at high standing should feel meaningful

### Smuggler Balance
- High reward must compensate for inspection risk
- Routes through low-inspection zones should be viable but not trivial

---

## Open Questions for Playtesting

1. What's the right contract reward scale relative to trading profits?
2. How many contracts should refresh per planet visit?
3. What's the ideal standing gain/loss per contract?
4. Should there be a "contract history" tracking past performance?
5. How aggressive should bots be about taking contracts?

---

## Summary

The corporation system adds strategic depth through:
- **Contract missions** as primary interaction point
- **Standing progression** unlocking better opportunities
- **Economic influence** at corp-controlled planets
- **Risk/reward decisions** around sealed cargo and smuggling
- **Competition** with AI bots for limited opportunities
- **Dynamic events** through news system integration

This design maintains the core trading gameplay while layering on meaningful faction relationships and mission-based income streams.
