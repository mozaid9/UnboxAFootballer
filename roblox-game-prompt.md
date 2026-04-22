#  Prompt — Roblox FIFA Pack Opening Simulator

Paste everything below the line.

---

## The Prompt

I'm building a Roblox pack opening game — a FIFA-style card opening simulator where players open packs, collect gold player cards, store them in their base, trade with others, and rebirth for prestige rewards. I need you to build the full project structure in Roblox-compatible Luau.

### Game Overview
Players earn coins, buy packs, open them with animated reveals, collect cards, display them in a personal base that others can visit, trade cards with other players, and eventually rebirth to reset progress for permanent bonuses.

### Card Pool (Launch Set — Gold Cards Only, no special cards yet)

```lua
local CardPool = {
    {name = "Leonel Messi", nation = "Argentina", position = "RW", rating = 92, rarity = "Rare Gold"},
    {name = "Cristian Ronaldo", nation = "Portugal", position = "ST", rating = 92, rarity = "Rare Gold"},
    {name = "Kylann Mbappe", nation = "France", position = "ST", rating = 89, rarity = "Rare Gold"},
    {name = "Erling Halland", nation = "Norway", position = "ST", rating = 88, rarity = "Rare Gold"},
    {name = "Rodrigo Bellingham", nation = "England", position = "CM", rating = 87, rarity = "Rare Gold"},
    {name = "Vinicius Jr", nation = "Brazil", position = "LW", rating = 86, rarity = "Rare Gold"},
    {name = "Keven De Bruin", nation = "Belgium", position = "CM", rating = 85, rarity = "Rare Gold"},
    {name = "Jamal Musley", nation = "Germany", position = "CAM", rating = 84, rarity = "Gold"},
    {name = "Pedri Gonzalez", nation = "Spain", position = "CM", rating = 83, rarity = "Gold"},
    {name = "Bukayo Sako", nation = "England", position = "RW", rating = 82, rarity = "Gold"},
    {name = "Toni Kruger", nation = "Germany", position = "CM", rating = 81, rarity = "Gold"},
    {name = "Phil Fodo", nation = "England", position = "CAM", rating = 80, rarity = "Gold"},
    {name = "Alison Becker", nation = "Brazil", position = "GK", rating = 80, rarity = "Gold"},
    {name = "Luca Modric", nation = "Croatia", position = "CM", rating = 79, rarity = "Gold"},
    {name = "Marcus Rashford", nation = "England", position = "LW", rating = 78, rarity = "Gold"},
}
```

### Card Value System
Higher rating = more valuable. Use this scale:
- 92 rated: 5,000 coin sell value, 20,000 coin market floor
- 88-89 rated: 2,500 coin sell value, 10,000 coin market floor
- 85-87 rated: 1,500 coin sell value, 6,000 coin market floor
- 80-84 rated: 750 coin sell value, 2,500 coin market floor
- 78-79 rated: 300 coin sell value, 800 coin market floor

### Pack Rarity Weights
Weight drops by rating. Lower rated cards appear far more often:
- 78-80 rated: 45% chance
- 81-84 rated: 30% chance
- 85-87 rated: 15% chance
- 88-89 rated: 7% chance
- 92 rated: 3% chance

### Pack Types (for now just two)
1. **Gold Pack** — costs 5,000 coins, contains 3 cards, minimum all gold
2. **Rare Gold Pack** — costs 10,000 coins, contains 5 cards, guaranteed at least 1 Rare Gold (85+)

### Systems to Build

#### 1. Pack Opening System (PRIORITY — build this first)
- Server-sided drop logic using the weights above. NEVER run rarity rolls on the client.
- RemoteEvents to communicate between server and client
- Client-side animated card reveal UI — cards flip one by one with a short delay between each
- Gold glow effect on the card frame, brighter glow for Rare Gold cards
- Sound effect placeholder hooks for card flip and rare pull moments
- After reveal, player can "Quick Sell" individual cards or "Store All" to inventory

#### 2. Inventory & DataStore
- Use DataStoreService to persist: coins, card inventory (as a table of card IDs and quantities), rebirth tier, base layout data
- Inventory UI showing all owned cards in a scrollable grid
- Card detail view showing name, nation, position, rating, sell value
- Sell button on each card (gives coin value)
- Duplicate counter on each card

#### 3. Base System
- Each player gets a personal plot (use a plot assignment system on join)
- The base is a flat platform with display slots where cards are physically shown as 3D parts with SurfaceGuis
- Players choose which cards to display from their inventory
- Other players can walk into anyone's base and view their displayed cards
- Base upgrades: more display slots unlocked as you collect more cards

#### 4. Trading System
- Player-to-player trade window (both players add cards and/or coins, both confirm)
- Trade request via proximity prompt or a menu
- Both players must accept before trade executes
- Server validates both players actually own the items being traded
- Global Transfer Market: players list cards at a price (with floor/ceiling based on rating), others can buy

#### 5. Rebirth System
- First rebirth requires: owning at least 1 of every card + 50,000 coins
- Rebirthing wipes your inventory and coins but gives:
  - Rebirth tier +1 (visible badge/aura)
  - Permanent +5% pack luck per rebirth tier (shifts weights slightly toward higher rated cards)
  - Rebirth tokens (1 per rebirth) — saved for future rebirth-exclusive content
- Each subsequent rebirth costs more (multiply coin requirement by 1.5x per tier)
- Make rebirths progressively harder but rewarding

#### 6. Currency & Economy
- Two currencies for now: Coins (earnable) and Gems (premium, Robux purchase)
- Daily login reward: 1,000 coins
- Free pack every 4 hours
- Coins earned from selling cards, daily rewards, and completing collections
- Gems buy premium packs only (implement MarketplaceService for Robux → Gems)

#### 7. Collection Album
- UI showing every card in the game with collected/uncollected status
- Completion percentage tracked
- Rewards for completing milestones (e.g. "Collect all English players" = bonus coins)

### Project Structure
Organise as a proper Roblox project:
```
src/
├── server/
│   ├── PackService.lua        -- pack opening logic, rarity rolls
│   ├── DataService.lua        -- DataStore save/load
│   ├── TradeService.lua       -- trade validation and execution
│   ├── MarketService.lua      -- transfer market logic
│   ├── RebirthService.lua     -- rebirth logic
│   ├── BaseService.lua        -- plot assignment, display management
│   └── EconomyService.lua     -- currency management, daily rewards
├── client/
│   ├── PackOpeningUI.lua      -- animated card reveal interface
│   ├── InventoryUI.lua        -- card collection viewer
│   ├── ShopUI.lua             -- pack store
│   ├── TradeUI.lua            -- trade window
│   ├── MarketUI.lua           -- transfer market browser
│   ├── BaseUI.lua             -- base customisation interface
│   ├── CollectionUI.lua       -- album/collection tracker
│   └── RebirthUI.lua          -- rebirth confirmation screen
├── shared/
│   ├── CardData.lua           -- the card pool table above
│   ├── PackConfig.lua         -- pack types, costs, weights
│   ├── Constants.lua          -- sell values, market floors/ceilings, rebirth costs
│   └── Utils.lua              -- shared utility functions
└── assets/
    └── (placeholder notes for card art, sounds, UI elements)
```

### Technical Requirements
- ALL game logic (drops, trading, economy) runs on the server
- Client only handles UI rendering and animations
- Use ModuleScripts for clean separation
- Use RemoteEvents and RemoteFunctions for client-server communication
- DataStore calls should be batched and throttled to avoid rate limits
- Include error handling and retry logic on DataStore operations
- Add anti-exploit checks: validate all client requests server-side

### Style & UI Direction
- Clean dark UI theme (dark navy/black backgrounds)
- Gold accent colour (#FFD700) for card borders and highlights
- FIFA-style card layout: rating top-left, position below it, name centered, nation flag
- Smooth tween animations on card reveals
- Glow/particle effects on high-rated card pulls

Build the full project. Start with the shared modules (CardData, PackConfig, Constants), then server services (PackService and DataService first), then client UI (PackOpeningUI first). Prioritise getting the core pack opening loop functional end-to-end before building trading and rebirth.
