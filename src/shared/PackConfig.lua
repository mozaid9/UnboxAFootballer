-- ============================================================
-- PackConfig.lua
-- Defines the 7 pack types and the rarity-based weight tiers
-- used by PackService to roll cards.
--
-- WeightTiers index order (1 = lowest, 7 = highest):
--   1 Gold | 2 Rare Gold | 3 Premium Gold | 4 Talisman
--   5 Maestro | 6 Immortal | 7 Player of the Year
--
-- tierWeights per pack must sum to 100.
-- ============================================================

local PackConfig = {}

-- ── Global rarity tier definitions ───────────────────────────
-- Each tier names the rarity strings that belong to it.
-- PackService uses these to filter CardData.Pool.
PackConfig.WeightTiers = {
	{ label = "Gold",             rarities = { "Gold" } },
	{ label = "Rare Gold",        rarities = { "Rare Gold" } },
	{ label = "Premium Gold",     rarities = { "Premium Gold" } },
	{ label = "Talisman",         rarities = { "Talisman" } },
	{ label = "Maestro",          rarities = { "Maestro" } },
	{ label = "Immortal",         rarities = { "Immortal" } },
	{ label = "Player of the Year", rarities = { "Player of the Year" } },
}

-- Minimum weight floor per tier (rebirth luck can't push below these).
-- Indexed 1-7, matching WeightTiers above.
PackConfig.WeightFloorPerTier = { 5, 2, 1, 0, 0, 0, 0 }

-- Maximum total luck-shift points from rebirth (spread across tiers).
PackConfig.MaxLuckShift = 18

-- ── Pack definitions ─────────────────────────────────────────
-- tierWeights[i] = chance (out of 100) of landing in WeightTiers[i].
-- guaranteed.minRarity = lowest rarity name that is guaranteed.
-- padWeight = relative spawn frequency on the player's pack pad.
--             Set to 0 to prevent pad spawning entirely.

PackConfig.ShopOrder = {
	-- ── 1 · Gold Pack ──────────────────────────────────────
	{
		id          = "GoldPack",
		displayName = "Gold Pack",
		description = "A solid pull — mostly Gold with a chance at Rare Gold.",
		cost        = 0,
		futureCost  = 3000,
		cardCount   = 1,
		hitsRequired = 8,
		padWeight   = 55,
		color       = Color3.fromRGB(255, 215, 0),
		-- 92 Gold · 7 Rare · 1 Premium · 0 · 0 · 0 · 0
		tierWeights = { 92, 7, 1, 0, 0, 0, 0 },
		station     = { position = Vector3.new(-24, 1.5, -16) },
	},

	-- ── 2 · Rare Pack ──────────────────────────────────────
	{
		id          = "RarePack",
		displayName = "Rare Pack",
		description = "Guaranteed at least a Rare Gold. Real chance at Premium.",
		cost        = 0,
		futureCost  = 7500,
		cardCount   = 1,
		hitsRequired = 12,
		padWeight   = 28,
		color       = Color3.fromRGB(255, 168, 42),
		-- 55 Gold · 36 Rare · 7 Premium · 2 Talisman · 0 · 0 · 0
		tierWeights = { 55, 36, 7, 2, 0, 0, 0 },
		guaranteed  = { minRarity = "Rare Gold" },
		station     = { position = Vector3.new(-8, 1.5, -16) },
	},

	-- ── 3 · Premium Pack ───────────────────────────────────
	{
		id          = "PremiumPack",
		displayName = "Premium Pack",
		description = "Guaranteed Premium Gold minimum. Slim Talisman chance.",
		cost        = 0,
		futureCost  = 15000,
		cardCount   = 1,
		hitsRequired = 18,
		padWeight   = 12,
		color       = Color3.fromRGB(255, 238, 172),
		-- 18 Gold · 47 Rare · 28 Premium · 6 Talisman · 1 Maestro · 0 · 0
		tierWeights = { 18, 47, 28, 6, 1, 0, 0 },
		guaranteed  = { minRarity = "Premium Gold" },
		station     = { position = Vector3.new(8, 1.5, -16) },
	},

	-- ── 4 · Jumbo Pack ─────────────────────────────────────
	{
		id          = "JumboPack",
		displayName = "Jumbo Pack",
		description = "Premium Gold guaranteed. Real shot at Talisman.",
		cost        = 0,
		futureCost  = 30000,
		cardCount   = 1,
		hitsRequired = 25,
		padWeight   = 4,
		color       = Color3.fromRGB(255, 100, 50),
		-- 5 Gold · 28 Rare · 47 Premium · 17 Talisman · 3 Maestro · 0 · 0
		tierWeights = { 5, 28, 47, 17, 3, 0, 0 },
		guaranteed  = { minRarity = "Premium Gold" },
		station     = { position = Vector3.new(24, 1.5, -16) },
	},

	-- ── 5 · Deluxe Pack ────────────────────────────────────
	{
		id          = "DeluxePack",
		displayName = "Deluxe Pack",
		description = "Talisman guaranteed. Maestro and Immortal in the mix.",
		cost        = 0,
		futureCost  = 75000,
		cardCount   = 1,
		hitsRequired = 35,
		padWeight   = 1,
		color       = Color3.fromRGB(235, 56, 43),
		-- 0 · 8 Rare · 40 Premium · 38 Talisman · 11 Maestro · 2 Immortal · 1 POTY
		tierWeights = { 0, 8, 40, 38, 11, 2, 1 },
		guaranteed  = { minRarity = "Talisman" },
		station     = { position = Vector3.new(-16, 1.5, 4) },
	},

	-- ── 6 · Mythic Pack ────────────────────────────────────
	{
		id          = "MythicPack",
		displayName = "Mythic Pack",
		description = "Maestro guaranteed. Immortal and POTY are possible.",
		cost        = 0,
		futureCost  = 200000,
		cardCount   = 1,
		hitsRequired = 50,
		padWeight   = 0,  -- does not spawn on pads
		color       = Color3.fromRGB(157, 80, 255),
		-- 0 · 0 · 12 Premium · 48 Talisman · 30 Maestro · 8 Immortal · 2 POTY
		tierWeights = { 0, 0, 12, 48, 30, 8, 2 },
		guaranteed  = { minRarity = "Maestro" },
		station     = { position = Vector3.new(0, 1.5, 4) },
	},

	-- ── 7 · God Pack ───────────────────────────────────────
	{
		id          = "GodPack",
		displayName = "God Pack",
		description = "The rarest pull in the game. Legends and POTY only.",
		cost        = 0,
		futureCost  = 999999,
		cardCount   = 1,
		hitsRequired = 80,
		padWeight   = 0,  -- shop drop only — logic TBD
		color       = Color3.fromRGB(226, 248, 255),
		-- 0 · 0 · 0 · 20 Talisman · 48 Maestro · 24 Immortal · 8 POTY
		tierWeights = { 0, 0, 0, 20, 48, 24, 8 },
		guaranteed  = { minRarity = "Talisman" },
		station     = { position = Vector3.new(16, 1.5, 4) },
	},
}

-- ── Fast lookup by ID ────────────────────────────────────────
PackConfig.ById = {}
for _, pack in ipairs(PackConfig.ShopOrder) do
	PackConfig.ById[pack.id] = pack
end

-- Pads only spawn packs with padWeight > 0
PackConfig.PadSpawnOrder = {}
for _, pack in ipairs(PackConfig.ShopOrder) do
	if (pack.padWeight or 0) > 0 then
		table.insert(PackConfig.PadSpawnOrder, pack)
	end
end

return PackConfig
