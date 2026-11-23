-- lua_modules/camera_controller.lua
-- Fixed battle camera with juice (shake, punch, zoom). The world is 1280x720 and both
-- castles are always in frame; the camera exists for impact feedback, not for scrolling.

local constants = require("lua_modules.constants")

local M = {}

M.pos = vmath.vector3(constants.SCREEN_WIDTH * 0.5, constants.SCREEN_HEIGHT * 0.5, 0)
M.target = vmath.vector3(constants.SCREEN_WIDTH * 0.5, constants.SCREEN_HEIGHT * 0.5, 0)
M.zoom = 1.0
M.target_zoom = 1.0
M.punch = 0
M.shake_amount = 0
M.shake_timer = 0
M.shake_duration = 0.3
M.shake_phase = 0
M.view_matrix = vmath.matrix4()

-- Published by the render script every frame (visible world size in design units).
M.view_w = constants.SCREEN_WIDTH
M.view_h = constants.SCREEN_HEIGHT

local function view_size()
	local vw = M.view_w or constants.SCREEN_WIDTH
	local vh = M.view_h or constants.SCREEN_HEIGHT
	if vw <= 0 then vw = constants.SCREEN_WIDTH end
	if vh <= 0 then vh = constants.SCREEN_HEIGHT end
	return vw, vh
end

function M.init()
	M.reset(constants.SCREEN_WIDTH * 0.5, constants.SCREEN_HEIGHT * 0.5)
end

function M.reset(x, y)
	x = x or constants.SCREEN_WIDTH * 0.5
	y = y or constants.SCREEN_HEIGHT * 0.5
	M.pos.x, M.pos.y = x, y
	M.target.x, M.target.y = x, y
	M.zoom = 1.0
	M.target_zoom = 1.0
	M.shake_amount = 0
	M.shake_timer = 0
	M.punch = 0
	M.update(0)
end

function M.get_view_matrix()
	return M.view_matrix
end

function M.get_position()
	return M.pos
end

-- Clamped so the visible rectangle never leaves the arena.
function M.follow(x, y, immediate)
	local vw, vh = view_size()
	local z = math.max(0.55, M.target_zoom)
	local half_w = (vw * 0.5) / z
	local half_h = (vh * 0.5) / z
	local world_w = constants.WORLD_WIDTH
	local world_h = constants.WORLD_HEIGHT

	if world_w <= half_w * 2 then
		x = world_w * 0.5
	else
		x = math.max(half_w - 40, math.min(world_w - half_w + 40, x))
	end
	if world_h <= half_h * 2 then
		y = world_h * 0.5
	else
		y = math.max(half_h - 40, math.min(world_h - half_h + 40, y))
	end

	M.target.x, M.target.y = x, y
	if immediate then
		M.pos.x, M.pos.y = x, y
	end
end

function M.set_zoom(z)
	M.target_zoom = math.max(0.55, math.min(2.0, z or 1.0))
end

function M.shake(amount, duration)
	amount = amount or 10
	duration = duration or 0.3
	local remaining = (M.shake_timer > 0) and M.shake_amount * (M.shake_timer / M.shake_duration) or 0
	if amount >= remaining then
		M.shake_amount = amount
		M.shake_timer = duration
		M.shake_duration = duration
	end
	if amount >= 10 then
		M.punch = math.max(M.punch, math.min(0.08, amount * 0.0025))
	end
end

function M.punch_zoom(amount)
	M.punch = math.max(M.punch, amount or 0.03)
end

function M.world_to_screen(wx, wy)
	local sw = constants.SCREEN_WIDTH
	local sh = constants.SCREEN_HEIGHT
	local z = M.zoom * (1 + M.punch)
	return (wx - M.pos.x) * z + sw * 0.5, (wy - M.pos.y) * z + sh * 0.5
end

function M.screen_to_world(sx, sy)
	local sw = constants.SCREEN_WIDTH
	local sh = constants.SCREEN_HEIGHT
	local vw, vh = view_size()
	local z = M.zoom * (1 + M.punch)
	local wx = (sx - sw * 0.5) * (vw / sw) / z + M.pos.x
	local wy = (sy - sh * 0.5) * (vh / sh) / z + M.pos.y
	return wx, wy
end

function M.update(dt)
	local lerp = 8.5
	M.pos.x = M.pos.x + (M.target.x - M.pos.x) * math.min(1, lerp * dt)
	M.pos.y = M.pos.y + (M.target.y - M.pos.y) * math.min(1, lerp * dt)
	M.zoom = M.zoom + (M.target_zoom - M.zoom) * math.min(1, 3.8 * dt)

	local shake_x, shake_y = 0, 0
	if M.shake_timer > 0 then
		M.shake_timer = math.max(0, M.shake_timer - dt)
		M.shake_phase = M.shake_phase + dt
		local k = M.shake_timer / math.max(0.01, M.shake_duration)
		local amp = M.shake_amount * k * k
		local t = M.shake_phase
		shake_x = amp * (0.6 * math.sin(t * 47) + 0.4 * math.sin(t * 83 + 1.3))
		shake_y = amp * (0.6 * math.sin(t * 53 + 2.1) + 0.4 * math.sin(t * 71 + 0.4))
		if M.shake_timer <= 0 then
			M.shake_amount = 0
		end
	end
	M.punch = M.punch * math.exp(-9 * dt)

	local z = M.zoom * (1 + M.punch)
	local rx = M.pos.x + shake_x
	local ry = M.pos.y + shake_y
	M.view_matrix = vmath.matrix4_translation(vmath.vector3(constants.SCREEN_WIDTH * 0.5, constants.SCREEN_HEIGHT * 0.5, 0))
		* vmath.matrix4_scale(vmath.vector3(z, z, 1))
		* vmath.matrix4_translation(vmath.vector3(-rx, -ry, 0))
	return rx, ry, z
end

return M
