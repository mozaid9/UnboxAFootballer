local CardFrames = {}

CardFrames.Assets = {
	["Gold"] = "rbxassetid://72910568501147",
	["Rare Gold"] = "rbxassetid://140015414798474",
	["Premium Gold"] = "rbxassetid://97865633994923",
	["Talisman"] = "rbxassetid://137795510427610",
	["Maestro"] = "rbxassetid://122214911600791",
	["Immortal"] = "rbxassetid://87765382302526",
	["Player of the Year"] = "rbxassetid://101208651203316",
}

CardFrames.Accents = {
	["Gold"] = {
		text = Color3.fromRGB(255, 244, 214),
		wash = Color3.fromRGB(172, 105, 24),
		glow = Color3.fromRGB(255, 206, 88),
		washTransparency = 0.54,
		glowTransparency = 0.70,
	},
	["Rare Gold"] = {
		text = Color3.fromRGB(255, 238, 218),
		wash = Color3.fromRGB(190, 44, 12),
		glow = Color3.fromRGB(255, 112, 28),
		washTransparency = 0.44,
		glowTransparency = 0.64,
	},
	["Premium Gold"] = {
		text = Color3.fromRGB(255, 248, 224),
		wash = Color3.fromRGB(218, 150, 28),
		glow = Color3.fromRGB(255, 233, 118),
		washTransparency = 0.50,
		glowTransparency = 0.64,
	},
	["Talisman"] = {
		text = Color3.fromRGB(246, 226, 255),
		wash = Color3.fromRGB(118, 36, 210),
		glow = Color3.fromRGB(210, 98, 255),
		washTransparency = 0.42,
		glowTransparency = 0.60,
	},
	["Maestro"] = {
		text = Color3.fromRGB(236, 244, 255),
		wash = Color3.fromRGB(24, 76, 202),
		glow = Color3.fromRGB(255, 202, 72),
		washTransparency = 0.42,
		glowTransparency = 0.62,
	},
	["Immortal"] = {
		text = Color3.fromRGB(245, 255, 255),
		wash = Color3.fromRGB(82, 190, 255),
		glow = Color3.fromRGB(238, 255, 255),
		washTransparency = 0.38,
		glowTransparency = 0.56,
	},
	["Player of the Year"] = {
		text = Color3.fromRGB(255, 238, 150),
		wash = Color3.fromRGB(18, 14, 4),
		glow = Color3.fromRGB(255, 210, 56),
		washTransparency = 0.72,
		glowTransparency = 0.70,
	},
}

function CardFrames.GetAsset(rarity)
	return CardFrames.Assets[rarity]
end

function CardFrames.GetAccent(rarity)
	return CardFrames.Accents[rarity] or CardFrames.Accents["Gold"]
end

return CardFrames
