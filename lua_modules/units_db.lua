-- lua_modules/units_db.lua
-- The 8 fighters. M2 uses the ballistic part of each role; passives (shield, repair)
-- and burn damage land in M3.

local M = {}

M.LIST = {
	{
		id = "bombardier", gear = "bombardier", proj = "proj_bomb",
		wall = 65, unit = 35, blast = 52, speed = 1.0, gravity = 1.0,
		count = 1, spread = 0, pierce = 0, heavy = true,
	},
	{
		id = "triplet", gear = "triplet", proj = "proj_pellet",
		wall = 26, unit = 22, blast = 28, speed = 1.0, gravity = 1.0,
		count = 3, spread = 9,
	},
	{
		id = "driller", gear = "driller", proj = "proj_drill",
		wall = 55, unit = 45, blast = 34, speed = 1.15, gravity = 0.85,
		count = 1, spread = 0, pierce = 2,
	},
	{
		id = "sniper", gear = "sniper", proj = "proj_laser",
		wall = 30, unit = 60, blast = 14, speed = 1.5, gravity = 0.0,
		count = 1, spread = 0,
	},
	{
		id = "pyro", gear = "pyro", proj = "proj_molotov",
		wall = 32, unit = 28, blast = 46, speed = 1.0, gravity = 1.0,
		count = 1, spread = 0, fire = true,
	},
	{
		id = "barrel", gear = "barrel", proj = "proj_barrel",
		wall = 80, unit = 50, blast = 72, speed = 0.92, gravity = 1.3,
		count = 1, spread = 0, heavy = true,
	},
	{
		id = "tank", gear = "tank", proj = "proj_orb",
		wall = 35, unit = 30, blast = 32, speed = 1.0, gravity = 1.0,
		count = 1, spread = 0,
	},
	{
		id = "engineer", gear = "engineer", proj = "proj_hammer",
		wall = 35, unit = 35, blast = 30, speed = 1.0, gravity = 1.0,
		count = 1, spread = 0,
	},
}

M.BY_ID = {}
for _, u in ipairs(M.LIST) do
	M.BY_ID[u.id] = u
end

function M.get(id)
	return M.BY_ID[id] or M.BY_ID.bombardier
end

return M
