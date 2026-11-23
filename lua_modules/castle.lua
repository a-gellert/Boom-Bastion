-- lua_modules/castle.lua
-- Castle layout: rooms, segment bricks, units and the support/collapse graph.
-- Pure data - the battle controller spawns and moves the sprites.

local constants = require("lua_modules.constants")
local wall = require("lua_modules.segmented_wall")

local M = {}

local COLS = constants.CASTLE_COLS
local ROWS = constants.CASTLE_ROWS
local ROOM = constants.ROOM_CELLS
local CELL_W = constants.CELL_W
local CELL_H = constants.CELL_H
local ROOMS_PER_SIDE = math.floor(COLS / ROOM)

local function cell_kind(team, r, c)
	if team == "enemy" and r >= 8 and (c == 1 or c == 4 or c == 9) then
		return "steel"
	end
	return (team == "player") and "blue" or "red"
end

function M.brick_anim(kind, state)
	local base = "brick_" .. kind .. "_"
	return base .. tostring(state)
end

function M.new(opts)
	local castle = {
		team = opts.team or "player",
		x0 = opts.x0 or 0,
		tilt = opts.tilt or 0,
		ax = (opts.x0 or 0) + COLS * CELL_W * 0.5,
		ay = constants.CASTLE_BOTTOM,
		cols = COLS,
		rows = ROWS,
		rooms = {},
		columns = {},
		bricks = {},
		units = {},
	}

	for cc = 0, ROOMS_PER_SIDE - 1 do
		castle.columns[cc] = {}
	end

	for rr = 0, ROOMS_PER_SIDE - 1 do
		castle.rooms[rr] = {}
		for cc = 0, ROOMS_PER_SIDE - 1 do
			local open_c0 = (castle.team == "player") and (cc * ROOM + 1) or (cc * ROOM)
			local open_r0 = rr * ROOM + 1
			local room = {
				cc = cc,
				rr = rr,
				level = rr,
				standing = true,
				supported = true,
				bricks = {},
				bottom = {},
				open_c0 = open_c0,
				open_r0 = open_r0,
				open_center_c = open_c0 + 1.5,
				open_center_r = open_r0 + 1,
				decor = {},
			}
			castle.rooms[rr][cc] = room
			table.insert(castle.columns[cc], room)

			for r = rr * ROOM, rr * ROOM + ROOM - 1 do
				for c = cc * ROOM, cc * ROOM + ROOM - 1 do
					local in_open = (r >= open_r0 and r <= open_r0 + 1
						and c >= open_c0 and c <= open_c0 + 2)
					if not in_open then
						local kind = cell_kind(castle.team, r, c)
						local brick = wall.new_brick(kind, r, c, room)
						table.insert(castle.bricks, brick)
						table.insert(room.bricks, brick)
						if r == rr * ROOM then
							table.insert(room.bottom, brick)
						end
					end
				end
			end
			room.standing = #room.bricks >= 2
		end
	end

	-- units: { role, cc, rr }
	for _, spot in ipairs(opts.units or {}) do
		local room = castle.rooms[spot.rr] and castle.rooms[spot.rr][spot.cc]
		if room and not room.unit then
			local unit = {
				role = spot.role,
				team = castle.team,
				room = room,
				hp = 100,
				max_hp = 100,
				alive = true,
				cooldown = 0,
			}
			room.unit = unit
			table.insert(castle.units, unit)
		end
	end

	-- roof / tower shell: destructible bricks outside the room grid
	local function add_shell(row, col)
		local kind = (castle.team == "player") and "blue" or "red"
		table.insert(castle.bricks, wall.new_brick(kind, row, col, nil))
	end
	for c = 0, COLS - 1 do add_shell(ROWS, c) end
	for _, c in ipairs({ 0, 2, 8, 10 }) do add_shell(ROWS + 1, c) end
	for r = ROWS + 1, ROWS + 3 do
		for c = 4, 7 do add_shell(r, c) end
	end
	for _, c in ipairs({ 4, 6 }) do add_shell(ROWS + 4, c) end

	M.layout(castle)
	M.update_support(castle)
	return castle
end

function M.world_pos(castle, ox, oy)
	local ca, sa = math.cos(castle.tilt), math.sin(castle.tilt)
	return castle.ax + ox * ca - oy * sa,
		castle.ay + ox * sa + oy * ca
end

function M.layout(castle)
	local half_w = COLS * CELL_W * 0.5
	for _, b in ipairs(castle.bricks) do
		b.wx, b.wy = M.world_pos(castle,
			(b.col + 0.5) * CELL_W - half_w,
			(b.row + 0.5) * CELL_H)
	end
	for rr = 0, ROOMS_PER_SIDE - 1 do
		for cc = 0, ROOMS_PER_SIDE - 1 do
			local room = castle.rooms[rr][cc]
			local ux, uy = M.world_pos(castle,
				room.open_center_c * CELL_W - half_w,
				room.open_center_r * CELL_H)
			room.ux, room.uy = ux, uy
			if room.unit then
				room.unit.x, room.unit.y = ux, uy
			end
		end
	end
end

function M.alive_count(room)
	local n = 0
	for _, b in ipairs(room.bricks) do
		if b.alive then n = n + 1 end
	end
	return n
end

function M.bottom_alive(room)
	local n = 0
	for _, b in ipairs(room.bottom) do
		if b.alive then n = n + 1 end
	end
	return n
end

-- A room is supported when it is the next standing level above the highest
-- supported room in its column (the ground is level -1). A floor with fewer
-- than two alive bricks no longer carries the room above.
function M.update_support(castle)
	for cc = 0, ROOMS_PER_SIDE - 1 do
		local col = castle.columns[cc]
		table.sort(col, function(a, b) return a.level < b.level end)
		local top = -1
		for _, room in ipairs(col) do
			room.standing = M.alive_count(room) >= 2
			room.supported = room.standing and room.level == top + 1
				and (room.level == 0 or M.bottom_alive(room) >= 2)
			if room.supported then
				top = room.level
			end
		end
	end
end

-- Bricks not connected to the foundation through alive neighbours have lost
-- their support and must fall. Openings are holes, pillars keep the frame up.
function M.detached_bricks(castle)
	local function key(r, c) return r * 100 + c end
	local alive = {}
	for _, b in ipairs(castle.bricks) do
		if b.alive then alive[key(b.row, b.col)] = b end
	end
	local visited = {}
	local queue = {}
	for _, b in ipairs(castle.bricks) do
		if b.alive and b.row == 0 then
			local k = key(b.row, b.col)
			visited[k] = true
			table.insert(queue, b)
		end
	end
	local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
	local head = 1
	while head <= #queue do
		local b = queue[head]
		head = head + 1
		for _, d in ipairs(dirs) do
			local k = key(b.row + d[1], b.col + d[2])
			local nb = alive[k]
			if nb and not visited[k] then
				visited[k] = true
				table.insert(queue, nb)
			end
		end
	end
	local out = {}
	for _, b in ipairs(castle.bricks) do
		if b.alive and not visited[key(b.row, b.col)] then
			table.insert(out, b)
		end
	end
	return out
end

-- One fall step per column: the unsupported room and everything above it
-- drop onto the highest supported room below (or the ground).
function M.plan_falls(castle)
	local falls = {}
	for cc = 0, ROOMS_PER_SIDE - 1 do
		local col = castle.columns[cc]
		table.sort(col, function(a, b) return a.level < b.level end)
		for i, room in ipairs(col) do
			if room.standing and not room.supported then
				local below = nil
				for j = i - 1, 1, -1 do
					local cand = col[j]
					if cand.supported and cand.standing then
						below = cand
						break
					end
				end
				local target
				if M.bottom_alive(room) == 0 then
					-- the floor is gone: the room drops through and crushes the room below
					target = below and below.level or 0
				else
					target = below and (below.level + 1) or 0
				end
				local drop = room.level - target
				if drop > 0 then
					for k = i, #col do
						local r = col[k]
						r.level = r.level - drop
						table.insert(falls, {
							room = r,
							drop = drop,
							below = (k == i) and below or nil,
						})
					end
				end
				break
			end
		end
	end
	return falls
end

-- Moves a room's data down by dy world pixels (visuals are tweened by the battle).
function M.shift_room(room, dy)
	for _, b in ipairs(room.bricks) do
		b.wy = b.wy + dy
	end
	if room.unit then
		room.unit.y = room.unit.y + dy
	end
	room.uy = room.uy + dy
end

function M.first_alive_unit(castle, role_filter)
	for _, u in ipairs(castle.units) do
		if u.alive and (not role_filter or u.role == role_filter) then
			return u
		end
	end
	return nil
end

function M.all_units_dead(castle)
	for _, u in ipairs(castle.units) do
		if u.alive then return false end
	end
	return true
end

return M

