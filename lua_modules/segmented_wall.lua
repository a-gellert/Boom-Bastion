-- lua_modules/segmented_wall.lua
-- Brick HP, damage states and blast damage. Pure rules - the battle controller owns visuals.

local constants = require("lua_modules.constants")

local M = {}

function M.max_hp(kind)
	return constants.BRICK_HP[kind] or 45
end

function M.new_brick(kind, row, col, room)
	local max_hp = M.max_hp(kind)
	return {
		kind = kind,
		row = row,
		col = col,
		room = room,
		hp = max_hp,
		max_hp = max_hp,
		alive = true,
		half_w = constants.CELL_W * 0.5 + 1,
		half_h = constants.CELL_H * 0.5 + 1,
	}
end

-- 0 = whole, 1 = cracked, 2 = rubble (the last alive state)
function M.state(brick)
	local t = brick.hp / brick.max_hp
	if t > 0.65 then return 0 end
	if t > 0.30 then return 1 end
	return 2
end

-- Returns true when this hit destroyed the brick.
function M.apply_damage(brick, amount, pierce)
	if not brick.alive then return false end
	local resist = constants.BRICK_RESIST[brick.kind] or 1
	if pierce then resist = 1 end
	brick.hp = brick.hp - amount / resist
	if brick.hp <= 0 then
		brick.hp = 0
		brick.alive = false
		return true
	end
	return false
end

-- Falloff: 100% at the centre, 35% at the blast edge.
function M.falloff(dist, radius)
	if dist >= radius then return 0 end
	return 1 - 0.65 * (dist / radius)
end

-- Damages every alive brick in the castle around (x, y). Returns destroyed bricks.
function M.blast(castle, x, y, radius, damage, pierce)
	local destroyed = {}
	for _, b in ipairs(castle.bricks) do
		if b.alive then
			local dx = b.wx - x
			local dy = b.wy - y
			local dist = math.sqrt(dx * dx + dy * dy)
			local reach = radius + math.max(b.half_w, b.half_h)
			if dist < reach then
				local amount = damage * M.falloff(dist, reach)
				if amount > 1 and M.apply_damage(b, amount, pierce) then
					table.insert(destroyed, b)
				end
			end
		end
	end
	return destroyed
end

return M
