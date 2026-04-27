-- ============================================================
-- CardData.lua
-- Master card pool — 77 players, 123 card variants.
--
-- Rarity hierarchy (low → high):
--   Gold → Rare Gold → Premium Gold → Talisman
--   → Maestro → Immortal  (+ Player of the Year, special tier)
--
-- Ratings are INTERNAL ONLY — never shown in player-facing UI.
-- They drive passive fan income via the PassiveIncome formula
-- in Constants.lua.
--
-- ModuleScript → ReplicatedStorage / Shared /
-- ============================================================

local CardData = {}

-- ── Card Pool ────────────────────────────────────────────────
CardData.Pool = {

	-- ════════════════════════════════════════════════════════
	-- IMMORTAL  ·  All-time legends  ·  no Gold base card
	-- ════════════════════════════════════════════════════════
	{ id = 1,  name = "Diego Maradona",         nation = "Argentina",   club = "Legend",         position = "SS",  rating = 97, rarity = "Immortal" },
	{ id = 2,  name = "Pelé",                   nation = "Brazil",      club = "Legend",         position = "ST",  rating = 97, rarity = "Immortal" },
	{ id = 3,  name = "Lionel Messi",           nation = "Argentina",   club = "Legend",         position = "RW",  rating = 96, rarity = "Immortal" },
	{ id = 4,  name = "Cristiano Ronaldo",      nation = "Portugal",    club = "Legend",         position = "ST",  rating = 95, rarity = "Immortal" },

	-- ════════════════════════════════════════════════════════
	-- MAESTRO  ·  Golden-era legends  ·  no Gold base card
	-- ════════════════════════════════════════════════════════
	{ id = 5,  name = "Andres Iniesta",         nation = "Spain",       club = "Legend",         position = "CM",  rating = 94, rarity = "Maestro" },
	{ id = 6,  name = "Ronaldinho",             nation = "Brazil",      club = "Legend",         position = "CAM", rating = 93, rarity = "Maestro" },
	{ id = 7,  name = "Zinedine Zidane",        nation = "France",      club = "Legend",         position = "CAM", rating = 93, rarity = "Maestro" },
	{ id = 8,  name = "Ronaldo Nazario",        nation = "Brazil",      club = "Legend",         position = "ST",  rating = 93, rarity = "Maestro" },
	{ id = 9,  name = "Thierry Henry",          nation = "France",      club = "Legend",         position = "LW",  rating = 92, rarity = "Maestro" },
	{ id = 10, name = "Toni Kroos",             nation = "Germany",     club = "Legend",         position = "CM",  rating = 91, rarity = "Maestro" },

	-- ════════════════════════════════════════════════════════
	-- PLAYER OF THE YEAR  ·  4-card players (Gold → POTY)
	-- ════════════════════════════════════════════════════════

	-- Kylian Mbappe
	{ id = 11, name = "Kylian Mbappe",          nation = "France",      club = "Real Madrid",    position = "ST",  rating = 91, rarity = "Gold" },
	{ id = 12, name = "Kylian Mbappe",          nation = "France",      club = "Real Madrid",    position = "ST",  rating = 93, rarity = "Rare Gold" },
	{ id = 13, name = "Kylian Mbappe",          nation = "France",      club = "Real Madrid",    position = "ST",  rating = 94, rarity = "Premium Gold" },
	{ id = 14, name = "Kylian Mbappe",          nation = "France",      club = "Real Madrid",    position = "ST",  rating = 97, rarity = "Player of the Year" },

	-- Mohamed Salah
	{ id = 15, name = "Mohamed Salah",          nation = "Egypt",       club = "Liverpool",      position = "RW",  rating = 89, rarity = "Gold" },
	{ id = 16, name = "Mohamed Salah",          nation = "Egypt",       club = "Liverpool",      position = "RW",  rating = 91, rarity = "Rare Gold" },
	{ id = 17, name = "Mohamed Salah",          nation = "Egypt",       club = "Liverpool",      position = "RW",  rating = 93, rarity = "Premium Gold" },
	{ id = 18, name = "Mohamed Salah",          nation = "Egypt",       club = "Liverpool",      position = "RW",  rating = 95, rarity = "Player of the Year" },

	-- Lamine Yamal
	{ id = 19, name = "Lamine Yamal",           nation = "Spain",       club = "Barcelona",      position = "RW",  rating = 84, rarity = "Gold" },
	{ id = 20, name = "Lamine Yamal",           nation = "Spain",       club = "Barcelona",      position = "RW",  rating = 87, rarity = "Rare Gold" },
	{ id = 21, name = "Lamine Yamal",           nation = "Spain",       club = "Barcelona",      position = "RW",  rating = 90, rarity = "Premium Gold" },
	{ id = 22, name = "Lamine Yamal",           nation = "Spain",       club = "Barcelona",      position = "RW",  rating = 94, rarity = "Player of the Year" },

	-- Raphinha
	{ id = 23, name = "Raphinha",               nation = "Brazil",      club = "Barcelona",      position = "LW",  rating = 86, rarity = "Gold" },
	{ id = 24, name = "Raphinha",               nation = "Brazil",      club = "Barcelona",      position = "LW",  rating = 88, rarity = "Rare Gold" },
	{ id = 25, name = "Raphinha",               nation = "Brazil",      club = "Barcelona",      position = "LW",  rating = 91, rarity = "Premium Gold" },
	{ id = 26, name = "Raphinha",               nation = "Brazil",      club = "Barcelona",      position = "LW",  rating = 93, rarity = "Player of the Year" },

	-- ════════════════════════════════════════════════════════
	-- TALISMAN  ·  3-card players (Gold + Rare Gold + Talisman)
	-- ════════════════════════════════════════════════════════

	-- Erling Haaland
	{ id = 27, name = "Erling Haaland",         nation = "Norway",      club = "Man City",       position = "ST",  rating = 89, rarity = "Gold" },
	{ id = 28, name = "Erling Haaland",         nation = "Norway",      club = "Man City",       position = "ST",  rating = 91, rarity = "Rare Gold" },
	{ id = 29, name = "Erling Haaland",         nation = "Norway",      club = "Man City",       position = "ST",  rating = 93, rarity = "Talisman" },

	-- Jude Bellingham
	{ id = 30, name = "Jude Bellingham",        nation = "England",     club = "Real Madrid",    position = "CM",  rating = 88, rarity = "Gold" },
	{ id = 31, name = "Jude Bellingham",        nation = "England",     club = "Real Madrid",    position = "CM",  rating = 90, rarity = "Rare Gold" },
	{ id = 32, name = "Jude Bellingham",        nation = "England",     club = "Real Madrid",    position = "CM",  rating = 92, rarity = "Talisman" },

	-- Vinicius Jr
	{ id = 33, name = "Vinicius Jr",            nation = "Brazil",      club = "Real Madrid",    position = "LW",  rating = 88, rarity = "Gold" },
	{ id = 34, name = "Vinicius Jr",            nation = "Brazil",      club = "Real Madrid",    position = "LW",  rating = 90, rarity = "Rare Gold" },
	{ id = 35, name = "Vinicius Jr",            nation = "Brazil",      club = "Real Madrid",    position = "LW",  rating = 92, rarity = "Talisman" },

	-- Kevin De Bruyne
	{ id = 36, name = "Kevin De Bruyne",        nation = "Belgium",     club = "Man City",       position = "CM",  rating = 87, rarity = "Gold" },
	{ id = 37, name = "Kevin De Bruyne",        nation = "Belgium",     club = "Man City",       position = "CM",  rating = 89, rarity = "Rare Gold" },
	{ id = 38, name = "Kevin De Bruyne",        nation = "Belgium",     club = "Man City",       position = "CM",  rating = 91, rarity = "Talisman" },

	-- Pedri
	{ id = 39, name = "Pedri",                  nation = "Spain",       club = "Barcelona",      position = "CM",  rating = 86, rarity = "Gold" },
	{ id = 40, name = "Pedri",                  nation = "Spain",       club = "Barcelona",      position = "CM",  rating = 88, rarity = "Rare Gold" },
	{ id = 41, name = "Pedri",                  nation = "Spain",       club = "Barcelona",      position = "CM",  rating = 90, rarity = "Talisman" },

	-- Florian Wirtz
	{ id = 42, name = "Florian Wirtz",          nation = "Germany",     club = "Bayern Munich",  position = "CAM", rating = 87, rarity = "Gold" },
	{ id = 43, name = "Florian Wirtz",          nation = "Germany",     club = "Bayern Munich",  position = "CAM", rating = 89, rarity = "Rare Gold" },
	{ id = 44, name = "Florian Wirtz",          nation = "Germany",     club = "Bayern Munich",  position = "CAM", rating = 91, rarity = "Talisman" },

	-- Khvicha Kvaratskhelia
	{ id = 45, name = "Khvicha Kvaratskhelia",  nation = "Georgia",     club = "PSG",            position = "LW",  rating = 85, rarity = "Gold" },
	{ id = 46, name = "Khvicha Kvaratskhelia",  nation = "Georgia",     club = "PSG",            position = "LW",  rating = 87, rarity = "Rare Gold" },
	{ id = 47, name = "Khvicha Kvaratskhelia",  nation = "Georgia",     club = "PSG",            position = "LW",  rating = 89, rarity = "Talisman" },

	-- ════════════════════════════════════════════════════════
	-- RARE GOLD  ·  2-card players (Gold + Rare Gold)
	-- ════════════════════════════════════════════════════════

	{ id = 48, name = "Harry Kane",             nation = "England",     club = "Bayern Munich",  position = "ST",  rating = 88, rarity = "Gold" },
	{ id = 49, name = "Harry Kane",             nation = "England",     club = "Bayern Munich",  position = "ST",  rating = 90, rarity = "Rare Gold" },

	{ id = 50, name = "Jamal Musiala",          nation = "Germany",     club = "Bayern Munich",  position = "CAM", rating = 87, rarity = "Gold" },
	{ id = 51, name = "Jamal Musiala",          nation = "Germany",     club = "Bayern Munich",  position = "CAM", rating = 89, rarity = "Rare Gold" },

	{ id = 52, name = "Bukayo Saka",            nation = "England",     club = "Arsenal",        position = "RW",  rating = 85, rarity = "Gold" },
	{ id = 53, name = "Bukayo Saka",            nation = "England",     club = "Arsenal",        position = "RW",  rating = 87, rarity = "Rare Gold" },

	{ id = 54, name = "Robert Lewandowski",     nation = "Poland",      club = "Barcelona",      position = "ST",  rating = 85, rarity = "Gold" },
	{ id = 55, name = "Robert Lewandowski",     nation = "Poland",      club = "Barcelona",      position = "ST",  rating = 87, rarity = "Rare Gold" },

	{ id = 56, name = "Rodri",                  nation = "Spain",       club = "Man City",       position = "CDM", rating = 87, rarity = "Gold" },
	{ id = 57, name = "Rodri",                  nation = "Spain",       club = "Man City",       position = "CDM", rating = 89, rarity = "Rare Gold" },

	{ id = 58, name = "Thibaut Courtois",       nation = "Belgium",     club = "Real Madrid",    position = "GK",  rating = 87, rarity = "Gold" },
	{ id = 59, name = "Thibaut Courtois",       nation = "Belgium",     club = "Real Madrid",    position = "GK",  rating = 89, rarity = "Rare Gold" },

	{ id = 60, name = "Alisson Becker",         nation = "Brazil",      club = "Liverpool",      position = "GK",  rating = 84, rarity = "Gold" },
	{ id = 61, name = "Alisson Becker",         nation = "Brazil",      club = "Liverpool",      position = "GK",  rating = 86, rarity = "Rare Gold" },

	{ id = 62, name = "Lautaro Martinez",       nation = "Argentina",   club = "Inter Milan",    position = "ST",  rating = 85, rarity = "Gold" },
	{ id = 63, name = "Lautaro Martinez",       nation = "Argentina",   club = "Inter Milan",    position = "ST",  rating = 87, rarity = "Rare Gold" },

	{ id = 64, name = "Bernardo Silva",         nation = "Portugal",    club = "Man City",       position = "CM",  rating = 85, rarity = "Gold" },
	{ id = 65, name = "Bernardo Silva",         nation = "Portugal",    club = "Man City",       position = "CM",  rating = 87, rarity = "Rare Gold" },

	{ id = 66, name = "Joshua Kimmich",         nation = "Germany",     club = "Bayern Munich",  position = "CDM", rating = 86, rarity = "Gold" },
	{ id = 67, name = "Joshua Kimmich",         nation = "Germany",     club = "Bayern Munich",  position = "CDM", rating = 88, rarity = "Rare Gold" },

	{ id = 68, name = "Declan Rice",            nation = "England",     club = "Arsenal",        position = "CDM", rating = 85, rarity = "Gold" },
	{ id = 69, name = "Declan Rice",            nation = "England",     club = "Arsenal",        position = "CDM", rating = 87, rarity = "Rare Gold" },

	{ id = 70, name = "Trent Alexander-Arnold", nation = "England",     club = "Real Madrid",    position = "RB",  rating = 84, rarity = "Gold" },
	{ id = 71, name = "Trent Alexander-Arnold", nation = "England",     club = "Real Madrid",    position = "RB",  rating = 86, rarity = "Rare Gold" },

	{ id = 72, name = "Federico Valverde",      nation = "Uruguay",     club = "Real Madrid",    position = "CM",  rating = 85, rarity = "Gold" },
	{ id = 73, name = "Federico Valverde",      nation = "Uruguay",     club = "Real Madrid",    position = "CM",  rating = 87, rarity = "Rare Gold" },

	{ id = 74, name = "Virgil van Dijk",        nation = "Netherlands", club = "Liverpool",      position = "CB",  rating = 86, rarity = "Gold" },
	{ id = 75, name = "Virgil van Dijk",        nation = "Netherlands", club = "Liverpool",      position = "CB",  rating = 88, rarity = "Rare Gold" },

	{ id = 76, name = "Ruben Dias",             nation = "Portugal",    club = "Man City",       position = "CB",  rating = 84, rarity = "Gold" },
	{ id = 77, name = "Ruben Dias",             nation = "Portugal",    club = "Man City",       position = "CB",  rating = 86, rarity = "Rare Gold" },

	{ id = 78, name = "Achraf Hakimi",          nation = "Morocco",     club = "PSG",            position = "RB",  rating = 85, rarity = "Gold" },
	{ id = 79, name = "Achraf Hakimi",          nation = "Morocco",     club = "PSG",            position = "RB",  rating = 87, rarity = "Rare Gold" },

	{ id = 80, name = "Phil Foden",             nation = "England",     club = "Man City",       position = "CAM", rating = 85, rarity = "Gold" },
	{ id = 81, name = "Phil Foden",             nation = "England",     club = "Man City",       position = "CAM", rating = 87, rarity = "Rare Gold" },

	{ id = 82, name = "Son Heung-min",          nation = "South Korea", club = "Tottenham",      position = "LW",  rating = 84, rarity = "Gold" },
	{ id = 83, name = "Son Heung-min",          nation = "South Korea", club = "Tottenham",      position = "LW",  rating = 86, rarity = "Rare Gold" },

	{ id = 84, name = "Antoine Griezmann",      nation = "France",      club = "Atletico Madrid",position = "CAM", rating = 84, rarity = "Gold" },
	{ id = 85, name = "Antoine Griezmann",      nation = "France",      club = "Atletico Madrid",position = "CAM", rating = 86, rarity = "Rare Gold" },

	{ id = 86, name = "Martin Odegaard",        nation = "Norway",      club = "Arsenal",        position = "CAM", rating = 85, rarity = "Gold" },
	{ id = 87, name = "Martin Odegaard",        nation = "Norway",      club = "Arsenal",        position = "CAM", rating = 87, rarity = "Rare Gold" },

	-- ════════════════════════════════════════════════════════
	-- GOLD ONLY  ·  Single card, solid active players
	-- ════════════════════════════════════════════════════════

	{ id = 88,  name = "Luka Modric",            nation = "Croatia",     club = "Real Madrid",    position = "CM",  rating = 83, rarity = "Gold" },
	{ id = 89,  name = "Marcus Rashford",         nation = "England",     club = "Aston Villa",    position = "LW",  rating = 79, rarity = "Gold" },
	{ id = 90,  name = "Bruno Fernandes",         nation = "Portugal",    club = "Man United",     position = "CAM", rating = 85, rarity = "Gold" },
	{ id = 91,  name = "Frenkie de Jong",         nation = "Netherlands", club = "Barcelona",      position = "CM",  rating = 83, rarity = "Gold" },
	{ id = 92,  name = "Gavi",                    nation = "Spain",       club = "Barcelona",      position = "CM",  rating = 83, rarity = "Gold" },
	{ id = 93,  name = "Eduardo Camavinga",       nation = "France",      club = "Real Madrid",    position = "CM",  rating = 83, rarity = "Gold" },
	{ id = 94,  name = "Federico Chiesa",         nation = "Italy",       club = "Liverpool",      position = "RW",  rating = 82, rarity = "Gold" },
	{ id = 95,  name = "Ousmane Dembele",         nation = "France",      club = "PSG",            position = "RW",  rating = 84, rarity = "Gold" },
	{ id = 96,  name = "Marcus Thuram",           nation = "France",      club = "Inter Milan",    position = "ST",  rating = 82, rarity = "Gold" },
	{ id = 97,  name = "Darwin Nunez",            nation = "Uruguay",     club = "Liverpool",      position = "ST",  rating = 82, rarity = "Gold" },
	{ id = 98,  name = "Dusan Vlahovic",          nation = "Serbia",      club = "Juventus",       position = "ST",  rating = 83, rarity = "Gold" },
	{ id = 99,  name = "Alexander Isak",          nation = "Sweden",      club = "Newcastle",      position = "ST",  rating = 84, rarity = "Gold" },
	{ id = 100, name = "Nico Williams",           nation = "Spain",       club = "Athletic Bilbao",position = "LW",  rating = 83, rarity = "Gold" },
	{ id = 101, name = "Cody Gakpo",              nation = "Netherlands", club = "Liverpool",      position = "LW",  rating = 82, rarity = "Gold" },
	{ id = 102, name = "Pau Cubarsi",             nation = "Spain",       club = "Barcelona",      position = "CB",  rating = 81, rarity = "Gold" },
	{ id = 103, name = "William Saliba",          nation = "France",      club = "Arsenal",        position = "CB",  rating = 85, rarity = "Gold" },
	{ id = 104, name = "Marquinhos",              nation = "Brazil",      club = "PSG",            position = "CB",  rating = 84, rarity = "Gold" },
	{ id = 105, name = "Jules Kounde",            nation = "France",      club = "Barcelona",      position = "CB",  rating = 84, rarity = "Gold" },
	{ id = 106, name = "Eder Militao",            nation = "Brazil",      club = "Real Madrid",    position = "CB",  rating = 83, rarity = "Gold" },
	{ id = 107, name = "Gianluigi Donnarumma",    nation = "Italy",       club = "PSG",            position = "GK",  rating = 85, rarity = "Gold" },
	{ id = 108, name = "Emiliano Martinez",       nation = "Argentina",   club = "Aston Villa",    position = "GK",  rating = 85, rarity = "Gold" },
	{ id = 109, name = "Ederson",                 nation = "Brazil",      club = "Man City",       position = "GK",  rating = 84, rarity = "Gold" },
	{ id = 110, name = "Manuel Neuer",            nation = "Germany",     club = "Bayern Munich",  position = "GK",  rating = 82, rarity = "Gold" },
	{ id = 111, name = "Marc-Andre ter Stegen",   nation = "Germany",     club = "Barcelona",      position = "GK",  rating = 83, rarity = "Gold" },
	{ id = 112, name = "Andrew Robertson",        nation = "Scotland",    club = "Liverpool",      position = "LB",  rating = 82, rarity = "Gold" },
	{ id = 113, name = "Theo Hernandez",          nation = "France",      club = "AC Milan",       position = "LB",  rating = 84, rarity = "Gold" },
	{ id = 114, name = "Joao Cancelo",            nation = "Portugal",    club = "Barcelona",      position = "RB",  rating = 83, rarity = "Gold" },
	{ id = 115, name = "Noni Madueke",            nation = "England",     club = "Chelsea",        position = "RW",  rating = 80, rarity = "Gold" },
	{ id = 116, name = "Casemiro",                nation = "Brazil",      club = "Man United",     position = "CDM", rating = 82, rarity = "Gold" },
	{ id = 117, name = "Kai Havertz",             nation = "Germany",     club = "Arsenal",        position = "CAM", rating = 83, rarity = "Gold" },
	{ id = 118, name = "Ryan Gravenberch",        nation = "Netherlands", club = "Liverpool",      position = "CM",  rating = 82, rarity = "Gold" },
	{ id = 119, name = "Dani Olmo",               nation = "Spain",       club = "Barcelona",      position = "CAM", rating = 85, rarity = "Gold" },
	{ id = 120, name = "Kobbie Mainoo",           nation = "England",     club = "Man United",     position = "CM",  rating = 81, rarity = "Gold" },
	{ id = 121, name = "Xavi Simons",             nation = "Netherlands", club = "PSG",            position = "CAM", rating = 83, rarity = "Gold" },
	{ id = 122, name = "Warren Zaire-Emery",      nation = "France",      club = "PSG",            position = "CM",  rating = 81, rarity = "Gold" },
	{ id = 123, name = "Mikel Merino",            nation = "Spain",       club = "Arsenal",        position = "CM",  rating = 82, rarity = "Gold" },
}

-- ── Fast lookup by ID ────────────────────────────────────────
CardData.ById = {}
for _, card in ipairs(CardData.Pool) do
	CardData.ById[card.id] = card
end

-- ── Nation groupings (used by collection milestones) ─────────
CardData.NationGroups = {
	England     = { 30, 48, 52, 68, 70, 80, 89, 115, 120 },
	France      = { 7,  9,  11, 23, 84, 93, 95, 96, 105, 113, 122 },
	Brazil      = { 2,  6,  8,  33, 60, 78, 96, 97, 101, 104, 106, 109, 116 },
	Spain       = { 5,  39, 56, 72, 92, 100, 102, 119, 123 },
	Germany     = { 10, 42, 50, 66, 110, 111, 117 },
	Argentina   = { 1,  3,  62, 108 },
	Portugal    = { 4,  64, 76, 90, 114 },
}

return CardData
