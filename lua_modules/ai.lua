-- lua_modules/ai.lua
-- Honest analytic artillery: pick an exposed target, solve the low arc, add error.

local constants = require("lua_modules.constants")
local units_db = require("lua_modules.units_db")
local ballistics = require("lua_modules.ballistics")

local M = {}

local function room_alive(unit)
	local n = 0
	for _, b in ipairs(unit.room.bricks) do
		if b.alive then n = n + 1 end
	end
	return n
end

local function pick_target(player_castle)
	local best, best_score = nil, -1
	for _, u in ipairs(player_castle.units) do
		if u.alive then
			-- fewer surviving bricks around a unit = a more tempting target
			local score = 20 - room_alive(u) + (u.hp < 50 and 5 or 0)
			if score > best_score then
				best, best_score = u, score
			end
		end
	end
	return best
end

function M.pick_shot(enemy_castle, player_castle, error_deg)
	local shooter = nil
	for _, u in ipairs(enemy_castle.units) do
		if u.alive then
			shooter = u
			break
		end
	end
	if not shooter then return nil end
	local target = pick_target(player_castle)
	if not target then return nil end

	local role = units_db.get(shooter.role)
	local speed = constants.MAX_SPEED * 0.95 * role.speed
	local gravity = constants.GRAVITY * (role.gravity or 1)
	local vx, vy = ballistics.solve_velocity(shooter.x, shooter.y + 6, target.x, target.y + 6, speed, gravity)
	if not vx then
		-- fall back to a 45-degree lob toward the target
		local dir = (target.x < shooter.x) and -1 or 1
		vx = dir * speed * 0.7071
		vy = speed * 0.7071
	end

	local angle = math.atan2(vy, vx) + math.rad((math.random() * 2 - 1) * (error_deg or 5.5))
	local s = ballistics.speed(vx, vy)
	return {
		unit = shooter,
		target = target,
		vx = math.cos(angle) * s,
		vy = math.sin(angle) * s,
	}
end

return M

