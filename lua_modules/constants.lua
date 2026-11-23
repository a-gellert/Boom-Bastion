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
M.MAX_SPEED = 1450
M.MIN_SPEED = 260
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

-- M2 combat layout (one cell = one brick)
M.CELL_W = 26
M.CELL_H = 22
M.CASTLE_COLS = 12
M.CASTLE_ROWS = 12
M.ROOM_CELLS = 4
M.CASTLE_BOTTOM = 200
M.PLAYER_X0 = 80
M.ENEMY_X0 = 888
M.PLAYER_TILT = math.rad(-1)
M.ENEMY_TILT = math.rad(2.2)
M.UNIT_SIZE = 52
M.UNIT_HIT_R = 20

M.BRICK_HP = {
	blue = 45, red = 45, wood = 30, stone = 60, steel = 105, barrel = 15,
}
M.BRICK_RESIST = {
	stone = 1.25, steel = 1.5,
}
M.CRUSH_DAMAGE = 30
M.BARREL_BLAST = { radius = 85, wall = 70, unit = 45 }

M.AI_DELAY = 0.7
M.TURN_DELAY = 0.6
M.HITSTOP = 0.045


function M.log(...)
	local parts = { ... }
	for i = 1, #parts do
		parts[i] = tostring(parts[i])
	end
	print("[BASTION]", table.concat(parts, " "))
end

return M

