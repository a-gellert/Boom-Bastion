-- lua_modules/constants.lua
-- One place for tuning. Gameplay values are scaled to the 1280x720 arena.

local M = {}

-- Arena
M.SCREEN_WIDTH = 1280
M.SCREEN_HEIGHT = 720
M.WORLD_WIDTH = 1280
M.WORLD_HEIGHT = 720
M.GROUND_Y = 150

-- Physics / ballistics (M2)
M.GRAVITY = 1500
M.MAX_PULL = 230
M.MIN_PULL = 18
M.DEAD_ZONE = 20
M.MAX_SPEED = 1250
M.MIN_SPEED = 220
M.PREVIEW_FRACTION = 0.62
M.PROJECTILE_STEP = 1 / 240
M.PROJECTILE_RADIUS = 10

-- Teams
M.TEAM_BLUE = 1
M.TEAM_RED = 2
M.TEAM_COLORS = {
	[M.TEAM_BLUE] = vmath.vector4(0.18, 0.44, 0.96, 1),
	[M.TEAM_RED] = vmath.vector4(0.96, 0.23, 0.18, 1),
}

-- Palette (art bible in M1)
M.COLOR_OUTLINE = vmath.vector4(0.07, 0.09, 0.15, 1)
M.COLOR_GOLD = vmath.vector4(0.96, 0.72, 0.18, 1)
M.COLOR_WHITE = vmath.vector4(1, 1, 1, 1)
M.COLOR_MUTED = vmath.vector4(0.72, 0.78, 0.86, 1)

-- Modes / states (M2+)
M.MODE_CAMPAIGN = "campaign"
M.MODE_HOTSEAT = "hotseat"
M.MODE_ENDLESS = "endless"

M.STATE_BOOT = "boot"
M.STATE_AIM = "aim"
M.STATE_FLYING = "flying"
M.STATE_RESOLVE = "resolve"
M.STATE_ENEMY = "enemy"
M.STATE_PERK = "perk"
M.STATE_OVER = "over"

function M.log(...)
	local parts = { ... }
	for i = 1, #parts do
		parts[i] = tostring(parts[i])
	end
	print("[BASTION]", table.concat(parts, " "))
end

return M
