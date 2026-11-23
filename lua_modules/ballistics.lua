-- lua_modules/ballistics.lua
-- Projectile integration, analytic AI solutions and the aim preview.

local M = {}

function M.integrate(p, dt)
	p.vy = p.vy - p.gravity * dt
	p.x = p.x + p.vx * dt
	p.y = p.y + p.vy * dt
end

-- Low-arc launch velocity that hits (x1, y1) from (x0, y0) at a fixed speed.
function M.solve_velocity(x0, y0, x1, y1, speed, gravity)
	local dx = x1 - x0
	local dy = y1 - y0
	local sign = (dx >= 0) and 1 or -1
	dx = math.abs(dx)
	if dx < 4 or gravity <= 0 then
		return sign * speed, 0
	end
	local v2 = speed * speed
	local disc = v2 * v2 - gravity * (gravity * dx * dx + 2 * dy * v2)
	if disc < 0 then
		return nil
	end
	local root = math.sqrt(disc)
	local angle = math.atan((v2 - root) / (gravity * dx))
	return sign * math.cos(angle) * speed, math.sin(angle) * speed
end

-- Samples the arc until `collide(x, y)` returns true or the step budget runs out.
function M.preview(x, y, vx, vy, gravity, steps, dt, collide)
	local points = { { x = x, y = y } }
	local cx, cy = x, y
	local cvx, cvy = vx, vy
	for _ = 1, steps do
		cvy = cvy - gravity * dt
		cx = cx + cvx * dt
		cy = cy + cvy * dt
		table.insert(points, { x = cx, y = cy })
		if collide and collide(cx, cy) then
			break
		end
	end
	return points
end

function M.speed(vx, vy)
	return math.sqrt(vx * vx + vy * vy)
end

return M
