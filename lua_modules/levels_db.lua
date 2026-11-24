-- lua_modules/levels_db.lua
-- Campaign battles plus the deterministic endless-wave generator.

local M = {}

local R1 = { "bombardier", "triplet", "driller", "sniper" }
local R2 = { "bombardier", "triplet", "pyro", "barrel" }
local R3 = { "bombardier", "driller", "tank", "sniper" }
local R4 = { "bombardier", "barrel", "pyro", "sniper" }
local R5 = { "bombardier", "triplet", "tank", "driller" }
local E1 = { "pyro", "barrel", "tank" }
local E2 = { "pyro", "tank", "driller", "engineer" }
local E3 = { "pyro", "barrel", "tank", "driller" }

M.LIST = {
	{
		id = 1, biome = "meadow", name = "FIRST BREACH", ai_error = 5.5,
		player = { "bombardier", "triplet", "driller", "sniper" },
		enemy = { "pyro", "barrel", "tank" },
		gates = { { type = "x2", x = 640, y = 400 } },
	},
	{
		id = 2, biome = "meadow", name = "MULTIPLY", ai_error = 5.0,
		player = { "bombardier", "triplet", "pyro", "sniper" },
		enemy = { "pyro", "barrel", "tank", "driller" },
		gates = { { type = "x2", x = 580, y = 400 }, { type = "fire", x = 760, y = 520 } },
	},
	{
		id = 3, biome = "meadow", name = "THE HILL", ai_error = 4.5,
		player = { "bombardier", "triplet", "driller", "sniper" },
		enemy = { "pyro", "tank", "driller" },
		gates = { { type = "x2", x = 640, y = 430 } },
		hazard = "hill",
	},
	{
		id = 4, biome = "meadow", name = "POWDER KEG", ai_error = 4.0,
		player = { "bombardier", "barrel", "driller", "sniper" },
		enemy = { "pyro", "barrel", "tank", "engineer" },
		gates = { { type = "x3", x = 640, y = 410 } },
		steel = true, hazard = "barrels",
	},
	{
		id = 5, biome = "meadow", name = "THE WARDEN", ai_error = 0.8, boss = true,
		player = { "bombardier", "triplet", "tank", "sniper" },
		enemy = { "pyro", "barrel", "tank", "driller" },
		gates = { { type = "x3", x = 600, y = 410 }, { type = "fire", x = 780, y = 530 } },
		steel = true,
	},
	{
		id = 6, biome = "desert", name = "DUST DEVIL", ai_error = 3.5,
		player = { "bombardier", "triplet", "pyro", "barrel" },
		enemy = { "pyro", "tank", "driller", "engineer" },
		gates = { { type = "x2", x = 620, y = 420 } },
		wind = 55,
	},
	{
		id = 7, biome = "desert", name = "HIGH GROUND", ai_error = 3.0,
		player = { "bombardier", "driller", "tank", "sniper" },
		enemy = { "pyro", "barrel", "tank", "driller" },
		gates = { { type = "x3", x = 650, y = 430 } },
		steel = true, hazard = "hill",
	},
	{
		id = 8, biome = "desert", name = "BARREL RUN", ai_error = 2.5,
		player = { "bombardier", "triplet", "barrel", "sniper" },
		enemy = { "pyro", "barrel", "engineer", "tank" },
		gates = { { type = "x2", x = 580, y = 410 }, { type = "speed", x = 760, y = 520 } },
		steel = true, hazard = "barrels",
	},
	{
		id = 9, biome = "desert", name = "CROSSWIND", ai_error = 2.0,
		player = { "bombardier", "pyro", "driller", "tank" },
		enemy = { "pyro", "tank", "driller", "barrel" },
		gates = { { type = "x3", x = 600, y = 420 }, { type = "pierce", x = 780, y = 530 } },
		wind = -70,
	},
	{
		id = 10, biome = "desert", name = "THE RED KING", ai_error = 0.8, boss = true,
		player = { "bombardier", "triplet", "barrel", "sniper" },
		enemy = { "pyro", "barrel", "tank", "driller" },
		gates = { { type = "x3", x = 600, y = 410 }, { type = "giant", x = 780, y = 520 } },
		steel = true, hazard = "barrels",
	},
	{
		id = 11, biome = "frost", name = "FIRST SNOW", ai_error = 3.0,
		player = R2, enemy = E1,
		gates = { { type = "x2", x = 620, y = 410 } },
	},
	{
		id = 12, biome = "frost", name = "ICE WALL", ai_error = 2.6,
		player = R3, enemy = E2,
		gates = { { type = "x2", x = 580, y = 410 }, { type = "speed", x = 760, y = 520 } },
		steel = true, hazard = "hill",
	},
	{
		id = 13, biome = "frost", name = "AVALANCHE", ai_error = 2.2,
		player = R4, enemy = E3,
		gates = { { type = "x3", x = 640, y = 420 } },
		steel = true, hazard = "barrels",
	},
	{
		id = 14, biome = "frost", name = "FROZEN KEGS", ai_error = 1.9,
		player = R5, enemy = E2,
		gates = { { type = "x2", x = 580, y = 410 }, { type = "fire", x = 760, y = 520 } },
		steel = true, hazard = "barrels",
	},
	{
		id = 15, biome = "frost", name = "THE WHITE DUKE", ai_error = 0.8, boss = true,
		player = R1, enemy = E3,
		gates = { { type = "x3", x = 600, y = 410 }, { type = "giant", x = 780, y = 520 } },
		steel = true, hazard = "barrels",
	},
	{
		id = 16, biome = "volcano", name = "ASHES", ai_error = 1.8,
		player = R2, enemy = E1,
		gates = { { type = "x2", x = 620, y = 410 } },
	},
	{
		id = 17, biome = "volcano", name = "LAVA TUBES", ai_error = 1.6,
		player = R3, enemy = E2,
		gates = { { type = "x2", x = 580, y = 410 }, { type = "fire", x = 760, y = 520 } },
		steel = true, hazard = "hill",
	},
	{
		id = 18, biome = "volcano", name = "FIRE WAVE", ai_error = 1.5,
		player = R4, enemy = E3,
		gates = { { type = "x3", x = 640, y = 420 } },
		steel = true, hazard = "barrels",
	},
	{
		id = 19, biome = "volcano", name = "MAGMA KEGS", ai_error = 1.4,
		player = R5, enemy = E2,
		gates = { { type = "x3", x = 600, y = 410 }, { type = "speed", x = 780, y = 520 } },
		steel = true, hazard = "barrels",
	},
	{
		id = 20, biome = "volcano", name = "THE ASH LORD", ai_error = 0.8, boss = true,
		player = R1, enemy = E3,
		gates = { { type = "x3", x = 600, y = 410 }, { type = "fire", x = 780, y = 520 } },
		steel = true, hazard = "barrels",
	},
	{
		id = 21, biome = "sky", name = "CLOUD BREAK", ai_error = 1.7,
		player = R2, enemy = E1,
		gates = { { type = "x2", x = 620, y = 420 } },
		wind = 65,
	},
	{
		id = 22, biome = "sky", name = "UPDRAFT", ai_error = 1.6,
		player = R3, enemy = E2,
		gates = { { type = "x2", x = 580, y = 410 }, { type = "speed", x = 760, y = 520 } },
		wind = -80,
	},
	{
		id = 23, biome = "sky", name = "FLOATING ROCKS", ai_error = 1.5,
		player = R4, enemy = E3,
		gates = { { type = "x3", x = 640, y = 420 } },
		steel = true, hazard = "hill",
	},
	{
		id = 24, biome = "sky", name = "STORM KEGS", ai_error = 1.4,
		player = R5, enemy = E2,
		gates = { { type = "x3", x = 600, y = 410 }, { type = "pierce", x = 780, y = 520 } },
		hazard = "barrels", wind = 75,
	},
	{
		id = 25, biome = "sky", name = "THE SKY TYRANT", ai_error = 0.8, boss = true,
		player = R1, enemy = E3,
		gates = { { type = "x3", x = 600, y = 410 }, { type = "giant", x = 780, y = 520 } },
		steel = true, wind = 60,
	},
	{
		id = 26, biome = "night", name = "MIDNIGHT", ai_error = 1.6,
		player = R2, enemy = E1,
		gates = { { type = "x2", x = 620, y = 410 } },
	},
	{
		id = 27, biome = "night", name = "SHADOW WALL", ai_error = 1.5,
		player = R3, enemy = E2,
		gates = { { type = "x2", x = 580, y = 410 }, { type = "fire", x = 760, y = 520 } },
		steel = true, hazard = "hill",
	},
	{
		id = 28, biome = "night", name = "COLD MOON", ai_error = 1.4,
		player = R4, enemy = E3,
		gates = { { type = "x3", x = 640, y = 420 } },
		steel = true, hazard = "barrels",
	},
	{
		id = 29, biome = "night", name = "NIGHT KEGS", ai_error = 1.3,
		player = R5, enemy = E2,
		gates = { { type = "x3", x = 600, y = 410 }, { type = "pierce", x = 780, y = 520 } },
		steel = true, hazard = "barrels", wind = -65,
	},
	{
		id = 30, biome = "night", name = "THE NIGHT KING", ai_error = 0.8, boss = true,
		player = R1, enemy = E3,
		gates = { { type = "x3", x = 600, y = 410 }, { type = "giant", x = 780, y = 520 } },
		steel = true, hazard = "barrels",
	},
}

function M.count()
	return #M.LIST
end

function M.get(index)
	index = math.max(1, math.min(#M.LIST, index or 1))
	return M.LIST[index]
end

-- Endless: six biomes cycle, squads rotate, every fifth wave is a boss.
-- Deterministic per wave so restarts and tests see the same battle.
local ENDLESS_BIOMES = { "meadow", "desert", "frost", "volcano", "sky", "night" }
local ENDLESS_SQUADS = { R1, R2, R3, R4, R5 }
local ENDLESS_ENEMIES = { E1, E2, E3 }
local ENDLESS_GATES = { "x2", "x3", "fire", "speed", "pierce", "giant" }

function M.endless(wave)
	wave = math.max(1, math.floor(wave or 1))
	local boss = (wave % 5) == 0
	local gates = {}
	local count = (boss or wave % 3 == 0) and 2 or 1
	for i = 1, count do
		local g = ENDLESS_GATES[((wave + i * 2) % #ENDLESS_GATES) + 1]
		if wave == 1 then g = "x2"
		elseif wave < 3 and (g == "giant" or g == "pierce") then g = "x2" end
		gates[i] = {
			type = g,
			x = (i == 1) and (600 + (wave * 11) % 80) or (760 + (wave * 7) % 60),
			y = (i == 1) and (400 + (wave * 13) % 50) or (510 + (wave * 5) % 40),
		}
	end

	local hazard = nil
	if wave >= 3 then
		hazard = (wave % 4 < 2) and "barrels" or "hill"
	end

	local wind = nil
	if wave >= 8 and wave % 3 == 0 then
		wind = ((wave % 2 == 0) and 1 or -1) * (45 + (wave % 4) * 10)
	end

	return {
		id = 1000 + wave,
		wave = wave,
		endless = true,
		boss = boss,
		biome = ENDLESS_BIOMES[((wave - 1) % #ENDLESS_BIOMES) + 1],
		name = "WAVE " .. tostring(wave),
		ai_error = math.max(0.9, 4.8 - wave * 0.12),
		player = ENDLESS_SQUADS[((wave - 1) % #ENDLESS_SQUADS) + 1],
		enemy = boss and E3 or ENDLESS_ENEMIES[((wave - 1) % #ENDLESS_ENEMIES) + 1],
		gates = gates,
		hazard = hazard,
		wind = wind,
		steel = boss or wave >= 4,
	}
end

return M

