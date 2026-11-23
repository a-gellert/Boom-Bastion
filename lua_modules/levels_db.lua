-- lua_modules/levels_db.lua
-- Ten campaign battles: rosters, gates, hazards, armor and bot accuracy.

local M = {}

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
}

function M.count()
	return #M.LIST
end

function M.get(index)
	index = math.max(1, math.min(#M.LIST, index or 1))
	return M.LIST[index]
end

return M

