-- lua_modules/battle.lua
-- M2 battle controller: arena, castles, Pull & Release, gates, damage, collapse, AI.
-- One generic sprite entity drives every visual; no per-brick update scripts.

local constants = require("lua_modules.constants")
local camera = require("lua_modules.camera_controller")
local audio = require("lua_modules.audio")
local i18n = require("lua_modules.i18n")
local units_db = require("lua_modules.units_db")
local Castle = require("lua_modules.castle")
local wall = require("lua_modules.segmented_wall")
local ballistics = require("lua_modules.ballistics")
local ai = require("lua_modules.ai")
local art_sizes = require("lua_modules.art_sizes")

local M = {}

local WHITE = vmath.vector4(1, 1, 1, 1)
local TEAM_TINT = {
	player = vmath.vector4(0.36, 0.62, 1.0, 1),
	enemy = vmath.vector4(1.0, 0.42, 0.35, 1),
}
local DEAD_TINT = vmath.vector4(0.35, 0.35, 0.42, 0.7)

local Z = {
	brick = -0.75,
	backwall = -0.756,
	opening = -0.749,
	beam = -0.74,
	door = -0.742,
	platform = -0.73,
	wheel = -0.735,
	decor = -0.736,
	roof = -0.734,
	flag = -0.733,
	unit_shadow = -0.708,
	unit_body = -0.705,
	unit_gear = -0.704,
	unit_eyes = -0.703,
	balcony = -0.699,
	selection = -0.56,
	projectile = -0.55,
	gate = -0.54,
	balloon = -0.53,
	fx = -0.50,
	dots = -0.40,
}

local PLAYER_UNITS = {
	{ role = "bombardier", cc = 0, rr = 0 },
	{ role = "triplet", cc = 2, rr = 0 },
	{ role = "driller", cc = 1, rr = 1 },
	{ role = "sniper", cc = 0, rr = 2 },
}
local ENEMY_UNITS = {
	{ role = "pyro", cc = 2, rr = 0 },
	{ role = "barrel", cc = 0, rr = 0 },
	{ role = "tank", cc = 1, rr = 1 },
	{ role = "driller", cc = 2, rr = 2 },
}

local function url_of(id)
	return msg.url(nil, id, "sprite")
end

local function base_size(anim, w, h)
	local s = art_sizes[anim] or { w, h }
	return s[1], s[2]
end

local function add_sprite(self, anim, x, y, z, w, h, tint, rot, to_arena)
	local id = factory.create("#sprite_factory", vmath.vector3(x, y, z))
	local url = url_of(id)
	sprite.play_flipbook(url, hash(anim))
	local bw, bh = base_size(anim, w, h)
	go.set_scale(vmath.vector3(w / bw, h / bh, 1), id)
	if tint then
		go.set(url, "tint", tint)
	end
	if rot and rot ~= 0 then
		go.set_rotation(vmath.quat_rotation_z(math.rad(rot)), id)
	end
	if to_arena then
		table.insert(self.battle.arena_ids, id)
	else
		table.insert(self.battle.ids, id)
	end
	return id, url
end

local function set_anim(self, slot, anim, w, h, tint)
	local bw, bh = base_size(anim, w, h)
	sprite.play_flipbook(slot.url, hash(anim))
	if w and h then
		go.set_scale(vmath.vector3(w / bw, h / bh, 1), slot.id)
	end
	if tint then
		go.set(slot.url, "tint", tint)
	end
end

local function enable_go(id)
	msg.post(id, "enable")
end

local function disable_go(id)
	msg.post(id, "disable")
end

-- ------------------------------------------------------------------ arena
function M.build_arena(self)
	local b = self.battle
	b.arena_ids = {}
	local SKY_TOP = vmath.vector4(0.56, 0.72, 0.91, 1)
	local SKY_BOTTOM = vmath.vector4(1.0, 0.85, 0.66, 1)
	local SUN = vmath.vector4(1.0, 0.89, 0.64, 1)
	local SUN_GLOW = vmath.vector4(1.0, 0.79, 0.42, 0.55)
	local HAZE = vmath.vector4(1.0, 0.70, 0.38, 0.32)
	local CLOUD = vmath.vector4(1, 1, 1, 0.95)
	local HILL_BACK = vmath.vector4(0.74, 0.82, 0.90, 0.55)
	local HILL_FAR = vmath.vector4(0.62, 0.73, 0.84, 1)
	local HILL_NEAR = vmath.vector4(0.42, 0.66, 0.34, 1)
	local GRASS = vmath.vector4(0.50, 0.75, 0.25, 1)
	local GRASS_TOP = vmath.vector4(0.36, 0.60, 0.16, 1)

	local function arena(anim, x, y, z, w, h, tint, rot)
		return add_sprite(self, anim, x, y, z, w, h, tint, rot, true)
	end

	arena("white_pixel", 640, 360, -0.99, 1800, 950, SKY_TOP)
	arena("bg_gradient", 640, 360, -0.98, 1800, 950, SKY_BOTTOM)
	arena("fx_glow", 1010, 560, -0.975, 280, 280, SUN_GLOW)
	arena("circle", 1010, 560, -0.972, 100, 100, SUN)
	arena("fx_glow", 640, 235, -0.97, 1300, 320, HAZE)
	arena("fx_cloud", 280, 620, -0.965, 240, 100, CLOUD)
	arena("fx_cloud", 810, 650, -0.965, 190, 80, CLOUD)
	arena("fx_cloud", 1130, 515, -0.965, 150, 62, CLOUD)
	arena("bg_hills_far", 640, 300, -0.962, 1900, 280, HILL_BACK)
	arena("bg_hills_far", 640, 250, -0.96, 1800, 260, HILL_FAR)
	arena("bg_hills_near", 640, 180, -0.958, 1800, 190, HILL_NEAR)
	arena("white_pixel", 640, 45, -0.955, 1800, 200, GRASS)
	arena("white_pixel", 640, constants.GROUND_Y, -0.954, 1800, 14, GRASS_TOP)

	for _, gx in ipairs({ 40, 430, 470, 760, 810, 1210, 1250 }) do
		arena("grass_tuft", gx, constants.GROUND_Y + 9, -0.953, 30, 18, WHITE)
	end
	arena("flower", 150, constants.GROUND_Y + 9, -0.952, 16, 18, WHITE)
	arena("flower", 700, constants.GROUND_Y + 9, -0.952, 16, 18, WHITE)
	arena("flower", 1150, constants.GROUND_Y + 9, -0.952, 16, 18, WHITE)
	arena("bg_bird", 350, 600, -0.951, 18, 9, WHITE)
	arena("bg_bird", 390, 588, -0.951, 14, 7, WHITE)
	arena("bg_bird", 900, 640, -0.951, 16, 8, WHITE)
end

-- ------------------------------------------------------------------ pools
function M.build_pools(self)
	local b = self.battle
	b.proj_slots = {}
	b.fx = {}
	b.dots = {}
	for i = 1, 24 do
		local id = factory.create("#sprite_factory", vmath.vector3(0, 0, Z.projectile))
		local url = url_of(id)
		sprite.play_flipbook(url, hash("proj_bomb"))
		go.set_scale(vmath.vector3(0.1, 0.1, 1), id)
		disable_go(id)
		b.proj_slots[i] = { id = id, url = url, active = false }
	end
	for i = 1, 90 do
		local id = factory.create("#sprite_factory", vmath.vector3(0, 0, Z.fx))
		local url = url_of(id)
		sprite.play_flipbook(url, hash("fx_smoke"))
		go.set_scale(vmath.vector3(0.1, 0.1, 1), id)
		disable_go(id)
		b.fx[i] = { id = id, url = url, active = false }
	end
	for i = 1, 20 do
		local id = factory.create("#sprite_factory", vmath.vector3(0, 0, Z.dots))
		local url = url_of(id)
		sprite.play_flipbook(url, hash("fx_dot"))
		go.set_scale(vmath.vector3(1, 1, 1), id)
		disable_go(id)
		b.dots[i] = { id = id, url = url, active = false }
	end
	-- aim rubber band + knob
	local lid = factory.create("#sprite_factory", vmath.vector3(0, 0, -0.42))
	local lurl = url_of(lid)
	sprite.play_flipbook(lurl, hash("white_pixel"))
	go.set_scale(vmath.vector3(0.01, 0.01, 1), lid)
	go.set(lurl, "tint", vmath.vector4(1, 1, 1, 0.65))
	disable_go(lid)
	b.aim_line = { id = lid, url = lurl, active = false }
	local kid = factory.create("#sprite_factory", vmath.vector3(0, 0, -0.41))
	local kurl = url_of(kid)
	sprite.play_flipbook(kurl, hash("circle"))
	go.set_scale(vmath.vector3(0.9, 0.9, 1), kid)
	go.set(kurl, "tint", vmath.vector4(1.0, 0.8, 0.25, 0.85))
	disable_go(kid)
	b.aim_knob = { id = kid, url = kurl, active = false }

	-- selection ring
	local id = factory.create("#sprite_factory", vmath.vector3(0, 0, Z.selection))
	local url = url_of(id)
	sprite.play_flipbook(url, hash("fx_ring"))
	go.set_scale(vmath.vector3(1.2, 1.2, 1), id)
	go.set(url, "tint", vmath.vector4(1.0, 0.8, 0.25, 0.65))
	disable_go(id)
	b.sel_ring = { id = id, url = url, active = false }
end

-- ------------------------------------------------------------------ battle start
function M.start_battle(self)
	local b = self.battle
	for _, id in ipairs(b.ids) do
		go.delete(id)
	end
	b.ids = {}
	for _, p in ipairs(b.proj_slots) do
		p.active = false
		disable_go(p.id)
	end
	for _, f in ipairs(b.fx) do
		f.active = false
		disable_go(f.id)
	end
	for _, d in ipairs(b.dots) do
		d.active = false
		disable_go(d.id)
	end
	if b.sel_ring.active then
		b.sel_ring.active = false
		disable_go(b.sel_ring.id)
	end

	b.projectiles = {}
	b.pending = {}
	b.gates = {}
	b.falls = {}
	b.state = "intro"
	b.timer = 0.8
	b.turn = "player"
	b.selected = 1
	b.winner = nil
	b.paused = false
	b.hitstop = 0
	b.aiming = false
	b.aim = nil
	b.time = 0
	b.resolve_timer = 0
	camera.set_zoom(1.0)
	M.hide_aim_line(self)
	M.hide_preview(self)

	b.player = Castle.new({
		team = "player", x0 = constants.PLAYER_X0, tilt = constants.PLAYER_TILT,
		units = PLAYER_UNITS,
	})
	b.enemy = Castle.new({
		team = "enemy", x0 = constants.ENEMY_X0, tilt = constants.ENEMY_TILT,
		units = ENEMY_UNITS,
	})
	M.build_castle(self, b.player)
	M.build_castle(self, b.enemy)
	M.spawn_gate(self, "x2", 640, 400)

	M.select_unit(self, 1, true)
	M.update_hud(self)
	msg.post("/gui_hud#gui", "battle_restart")
	M.banner(self, i18n.t("battle_start"))
	audio.music("music_battle")
end

function M.build_castle(self, castle)
	local b = self.battle
	local tilt_deg = math.deg(castle.tilt)
	local half_w = constants.CASTLE_COLS * constants.CELL_W * 0.5

	local function off(ox, oy)
		return Castle.world_pos(castle, ox, oy)
	end

	local function decor(anim, ox, oy, z, w, h, tint, rot)
		local x, y = off(ox, oy)
		return add_sprite(self, anim, x, y, z, w, h, tint, tilt_deg + (rot or 0))
	end

	-- dark back wall so breaches show an interior, not the sky
	local bx, by = off(0, (constants.CASTLE_ROWS * constants.CELL_H) * 0.5 + 20)
	decor("white_pixel", 0, (constants.CASTLE_ROWS * constants.CELL_H) * 0.5 + 20, Z.backwall,
		constants.CASTLE_COLS * constants.CELL_W + 6,
		constants.CASTLE_ROWS * constants.CELL_H + 40,
		(castle.team == "player") and vmath.vector4(0.10, 0.14, 0.26, 1) or vmath.vector4(0.26, 0.10, 0.10, 1), 0)

	-- bricks
	for _, brick in ipairs(castle.bricks) do
		local anim = Castle.brick_anim(brick.kind, wall.state(brick))
		local z = Z.brick + brick.row * 0.0002
		local id, url = add_sprite(self, anim, brick.wx, brick.wy, z,
			constants.CELL_W + 1, constants.CELL_H + 1, WHITE, tilt_deg)
		brick.id = id
		brick.url = url
		brick.z = z
	end

	-- room openings and balconies
	for rr = 0, 2 do
		for cc = 0, 2 do
			local room = castle.rooms[rr][cc]
			local ux, uy = room.ux, room.uy
			room.decor = room.decor or {}
			local oid = add_sprite(self, "room_open", ux, uy, Z.opening, 78, 44, WHITE, tilt_deg)
			room.decor.opening = oid
			local bxp, byp = off(room.open_center_c * constants.CELL_W - half_w,
				room.open_r0 * constants.CELL_H + 4)
			local bid = add_sprite(self, "balcony", bxp, byp, Z.balcony, 104, 12, WHITE, tilt_deg)
			room.decor.balcony = bid
			room.decor.balcony_y = byp
			room.decor.extra = {}
		end
	end

	-- beams, posts, door, platform, wheels
	for floor = 0, 3 do
		for i = -1, 1 do
			decor("beam_wood_0", i * 104, floor * constants.ROOM_CELLS * constants.CELL_H,
				Z.beam, 104, 14, WHITE, 0)
		end
	end
	decor("post_wood", -52, 126, Z.door, 18, 252, WHITE, 0)
	decor("post_wood", 52, 126, Z.door, 18, 252, WHITE, 0)
	decor("door", 0, 36, Z.door, 56, 72, WHITE, 0)
	decor("castle_platform", 0, -16, Z.platform, 340, 58, WHITE, 0)
	decor("wheel", -105, -34, Z.wheel, 58, 58, WHITE, 0)
	decor("wheel", 105, -34, Z.wheel, 58, 58, WHITE, 0)

	-- roof, tower, flag (attached to the top centre room for the collapse)
	local top_room = castle.rooms[2] and castle.rooms[2][1]
	local extra = top_room and top_room.decor.extra
	local function roof_decor(anim, ox, oy, z, w, h, tint, rot)
		local id = decor(anim, ox, oy, z, w, h, tint, rot)
		if extra then
			table.insert(extra, { id = id, x = 0, y = oy, z = z })
		end
		return id
	end
	for c = 0, constants.CASTLE_COLS - 1 do
		local ox = (c + 0.5) * constants.CELL_W - half_w
		roof_decor((castle.team == "player") and "brick_blue_0" or "brick_red_0",
			ox, constants.CASTLE_ROWS * constants.CELL_H + constants.CELL_H * 0.5,
			Z.roof, constants.CELL_W + 1, constants.CELL_H + 1, WHITE, 0)
	end
	for _, c in ipairs({ 0, 2, 8, 10 }) do
		local ox = (c + 0.5) * constants.CELL_W - half_w
		roof_decor((castle.team == "player") and "brick_blue_0" or "brick_red_0",
			ox, (constants.CASTLE_ROWS + 1) * constants.CELL_H + constants.CELL_H * 0.5,
			Z.roof, constants.CELL_W + 1, constants.CELL_H + 1, WHITE, 0)
	end
	for r = 1, 3 do
		for c = 4, 7 do
			local ox = (c + 0.5) * constants.CELL_W - half_w
			roof_decor((castle.team == "player") and "brick_blue_0" or "brick_red_0",
				ox, (constants.CASTLE_ROWS + r) * constants.CELL_H + constants.CELL_H * 0.5,
				Z.roof, constants.CELL_W + 1, constants.CELL_H + 1, WHITE, 0)
		end
	end
	roof_decor("roof_" .. ((castle.team == "player") and "blue" or "red"),
		0, (constants.CASTLE_ROWS + 4) * constants.CELL_H + 30,
		Z.roof + 0.001, 152, 68, WHITE, 0)
	roof_decor("flag", 0, (constants.CASTLE_ROWS + 5) * constants.CELL_H + 50,
		Z.flag, 30, 40, (castle.team == "player") and TEAM_TINT.player or TEAM_TINT.enemy, 0)

	-- decor
	local team = castle.team
	decor("barrel_0", -110, 30, Z.decor, 32, 40, WHITE, 0)
	decor("crate", 70, 30, Z.decor, 30, 26, WHITE, 0)
	local shield = (team == "player") and "shield_blue" or "shield_red"
	decor(shield, -135, 250, Z.decor, 26, 30, WHITE, 0)
	decor(shield, 135, 330, Z.decor, 26, 30, WHITE, 0)
	local banner = (team == "player") and "banner_blue" or "banner_red"
	decor(banner, 75, 292, Z.decor, 30, 64, WHITE, 0)
	local side = (team == "player") and -1 or 1
	decor("plank_long", side * 190, 130, Z.decor, 190, 16, WHITE, side * 78)

	-- units
	for _, u in ipairs(castle.units) do
		local tint = TEAM_TINT[u.team]
		u.shadow_id, u.shadow_url = add_sprite(self, "fx_shadow", u.x, u.y - 26, Z.unit_shadow, 56, 14, WHITE, tilt_deg)
		u.body_id, u.body_url = add_sprite(self, "unit_body", u.x, u.y, Z.unit_body, constants.UNIT_SIZE, constants.UNIT_SIZE, tint, tilt_deg)
		u.gear_id, u.gear_url = add_sprite(self, "gear_" .. u.role, u.x, u.y, Z.unit_gear, constants.UNIT_SIZE, constants.UNIT_SIZE, WHITE, tilt_deg)
		u.eyes_id, u.eyes_url = add_sprite(self, "eyes_idle", u.x, u.y + 3, Z.unit_eyes, 36, 18, WHITE, tilt_deg)
		u.flash = 0
		u.eyes_timer = 0
	end
end

function M.spawn_gate(self, gate_type, x, y)
	local b = self.battle
	local ring_id, ring_url = add_sprite(self, "gate_" .. gate_type, x, y, Z.gate, 150, 150, WHITE)
	local balloon_id, balloon_url = add_sprite(self, "balloon_" .. gate_type, x, y + 105, Z.balloon, 72, 94, WHITE)
	local gate = {
		id = gate_type .. "_" .. tostring(#b.gates + 1),
		type = gate_type,
		x = x,
		y = y,
		base_y = y,
		phase = math.random() * 6.28,
		amp = 16,
		speed = 1.2,
		r = 58,
		ring_id = ring_id,
		ring_url = ring_url,
		balloon_id = balloon_id,
		balloon_url = balloon_url,
	}
	table.insert(b.gates, gate)
	return gate
end

-- ------------------------------------------------------------------ HUD glue
function M.banner(self, text)
	msg.post("/gui_hud#gui", "show_banner", { text = text })
end

function M.update_hud(self)
	local b = self.battle
	local rows = {}
	for _, u in ipairs(b.player.units) do
		table.insert(rows, {
			role = u.role,
			alive = u.alive,
			cooldown = u.cooldown,
			selected = (b.player.units[b.selected] == u),
		})
	end
	msg.post("/gui_hud#gui", "hud_state", {
		turn = b.turn,
		selected = b.selected,
		units = rows,
		state = b.state,
	})
end

function M.show_damage(self, x, y, amount)
	msg.post("/gui_hud#gui", "show_damage", { x = x, y = y, amount = amount })
end

-- ------------------------------------------------------------------ units
function M.current_unit(self)
	local b = self.battle
	return b.player.units[b.selected]
end

function M.select_unit(self, index, silent)
	local b = self.battle
	local u = b.player.units[index]
	if not u or not u.alive or u.cooldown > 0 then
		if silent then
			for i, cand in ipairs(b.player.units) do
				if cand.alive and cand.cooldown == 0 then
					return M.select_unit(self, i)
				end
			end
		end
		return false
	end
	b.selected = index
	local ring = b.sel_ring
	ring.active = true
	enable_go(ring.id)
	go.set_position(vmath.vector3(u.x, u.y, Z.selection), ring.id)
	ring.x, ring.y = u.x, u.y
	M.update_hud(self)
	return true
end

function M.set_unit_pose(unit, y)
	local tilt_deg = math.deg(unit.room and 0 or 0)
	go.set_position(vmath.vector3(unit.x, y, Z.unit_body), unit.body_id)
	go.set_position(vmath.vector3(unit.x, y, Z.unit_gear), unit.gear_id)
	go.set_position(vmath.vector3(unit.x, y + 3, Z.unit_eyes), unit.eyes_id)
	go.set_position(vmath.vector3(unit.x, y - 26, Z.unit_shadow), unit.shadow_id)
end

function M.damage_unit(self, unit, amount, x, y)
	if not unit.alive then return end
	amount = math.max(1, math.floor(amount))
	unit.hp = math.max(0, unit.hp - amount)
	M.show_damage(self, x or unit.x, (y or unit.y) + 30, amount)
	audio.play("hurt", { vary = 0.12, gain = 0.8 })
	unit.flash = 0.12
	unit.eyes_timer = 0.35
	sprite.play_flipbook(unit.eyes_url, hash("eyes_scared"))
	if unit.hp <= 0 then
		M.kill_unit(self, unit)
	end
end

function M.kill_unit(self, unit)
	if not unit.alive then return end
	unit.alive = false
	unit.cooldown = 0
	sprite.play_flipbook(unit.eyes_url, hash("eyes_dead"))
	go.set(unit.body_url, "tint", DEAD_TINT)
	go.set(unit.gear_url, "tint", DEAD_TINT)
	disable_go(unit.shadow_id)
	M.poof(self, unit.x, unit.y + 10, 60)
	audio.play("hurt", { gain = 0.9, speed = 0.8 })
	local b = self.battle
	if b.player.units[b.selected] == unit then
		M.select_unit(self, 1, true)
	end
	M.update_hud(self)
end

function M.poof(self, x, y, size)
	M.spawn_fx(self, "fx_smoke", x, y, Z.fx, size, size, vmath.vector4(1, 1, 1, 0.7), 0, 30, -0.2, 0.7, 0, 2.0, 0.1)
end

-- ------------------------------------------------------------------ gates
function M.update_gates(self, dt)
	for _, g in ipairs(self.battle.gates) do
		g.phase = g.phase + dt * g.speed
		g.y = g.base_y + math.sin(g.phase) * g.amp
		go.set_position(vmath.vector3(g.x, g.y, Z.gate), g.ring_id)
		go.set_position(vmath.vector3(g.x, g.y + 105, Z.balloon), g.balloon_id)
	end
end

function M.apply_gate(self, p, g)
	if g.type == "x2" or g.type == "x3" then
		p.gate_hit[g.id] = true
		local n = (g.type == "x3") and 3 or 2
		local base = math.atan2(p.vy, p.vx)
		local speed = ballistics.speed(p.vx, p.vy)
		local spread = math.rad(5)
		for i = 1, n - 1 do
			local angle = base + (i - (n - 1) * 0.5) * spread
			M.spawn_projectile(self, {
				x = g.x, y = g.y,
				vx = math.cos(angle) * speed, vy = math.sin(angle) * speed,
				gravity = p.gravity, blast = p.blast, wall = p.wall, unit = p.unit_damage,
				pierce = p.pierce, anim = p.anim, team = p.team, owner = p.owner,
				gate_hit = p.gate_hit, radius = p.radius, heavy = p.heavy, scale = p.scale,
			})
		end
		M.spawn_fx(self, "fx_star", g.x, g.y, Z.fx, 34, 34, WHITE, 0, 0, 0, 0.35, 0, 1, 0)
		audio.play("pop", { speed = 1.4, vary = 0.1 })
	elseif g.type == "fire" then
		p.fire = true
		go.set(p.slot.url, "tint", vmath.vector4(1, 0.55, 0.2, 1))
	elseif g.type == "giant" then
		p.radius = p.radius * 1.6
		p.scale = p.scale * 1.6
		p.blast = p.blast * 1.6
		p.wall = p.wall * 1.6
		p.unit_damage = p.unit_damage * 1.2
		go.set_scale(vmath.vector3(p.scale, p.scale, 1), p.slot.id)
	elseif g.type == "pierce" then
		p.pierce = p.pierce + 1
	elseif g.type == "speed" then
		p.vx = p.vx * 1.4
		p.vy = p.vy * 1.4
	end
end

-- ------------------------------------------------------------------ projectiles
function M.spawn_projectile(self, opts)
	local b = self.battle
	local slot = nil
	for _, s in ipairs(b.proj_slots) do
		if not s.active then slot = s break end
	end
	if not slot then return nil end
	slot.active = true
	enable_go(slot.id)
	local anim = opts.anim or "proj_bomb"
	set_anim(self, slot, anim, nil, nil, WHITE)
	local p_scale = opts.scale or constants.PROJECTILE_SCALE
	go.set_scale(vmath.vector3(p_scale, p_scale, 1), slot.id)
	go.set_position(vmath.vector3(opts.x, opts.y, Z.projectile), slot.id)
	local gate_hit = {}
	if opts.gate_hit then
		for k, v in pairs(opts.gate_hit) do gate_hit[k] = v end
	end
	local p = {
		slot = slot,
		x = opts.x, y = opts.y,
		vx = opts.vx, vy = opts.vy,
		gravity = opts.gravity,
		blast = opts.blast,
		wall = opts.wall,
		unit_damage = opts.unit,
		pierce = opts.pierce or 0,
		radius = opts.radius or constants.PROJECTILE_RADIUS,
		scale = p_scale,
		anim = anim,
		team = opts.team,
		owner = opts.owner,
		gate_hit = gate_hit,
		ignore = {},
		age = 0,
		spin = (anim == "proj_bomb" or anim == "proj_barrel") and 7 or 0,
		rot = 0,
		heavy = opts.heavy,
		fire = opts.fire,
		trail = 0,
		self_time = 0.45,
	}
	table.insert(b.projectiles, p)
	return p
end

function M.fire_projectiles(self, unit, vx, vy)
	local role = units_db.get(unit.role)
	local count = role.count or 1
	local base = math.atan2(vy, vx)
	local speed = ballistics.speed(vx, vy)
	local spread = math.rad(role.spread or 0)
	for i = 1, count do
		local angle = base
		if count > 1 then
			angle = base + (i - (count + 1) * 0.5) * spread
		end
		M.spawn_projectile(self, {
			x = unit.x, y = unit.y + 6,
			vx = math.cos(angle) * speed,
			vy = math.sin(angle) * speed,
			gravity = constants.GRAVITY * (role.gravity or 1),
			blast = role.blast,
			wall = role.wall,
			unit = role.unit,
			pierce = role.pierce or 0,
			anim = role.proj,
			team = unit.team,
			owner = unit,
			heavy = role.heavy,
			radius = 8,
		})
	end
	audio.play("whoosh", { vary = 0.08 })
end

function M.brick_at(self, x, y, r, ignore, skip_castle)
	for _, castle in ipairs({ self.battle.player, self.battle.enemy }) do
		if castle ~= skip_castle then
		for _, brick in ipairs(castle.bricks) do
			if brick.alive and not ignore[brick] then
				if math.abs(x - brick.wx) <= brick.half_w + r
					and math.abs(y - brick.wy) <= brick.half_h + r then
					return brick, castle
				end
			end
		end
		end
	end
	return nil
end

function M.unit_at(self, x, y, r, team)
	for _, castle in ipairs({ self.battle.player, self.battle.enemy }) do
		for _, u in ipairs(castle.units) do
			if u.alive and u.team ~= team then
				local dx, dy = x - u.x, y - (u.y + 2)
				if dx * dx + dy * dy <= (constants.UNIT_HIT_R + r) * (constants.UNIT_HIT_R + r) then
					return u
				end
			end
		end
	end
	return nil
end

function M.update_projectiles(self, dt)
	local b = self.battle
	local steps = 4
	local sub = dt / steps
	for i = #b.projectiles, 1, -1 do
		local p = b.projectiles[i]
		local exploded = false
		if p.slot.active then
			for _ = 1, steps do
				ballistics.integrate(p, sub)
				-- gates
				for _, g in ipairs(b.gates) do
					if not p.gate_hit[g.id] then
						local dx, dy = p.x - g.x, p.y - g.y
						if dx * dx + dy * dy < g.r * g.r then
							M.apply_gate(self, p, g)
						end
					end
				end
				-- bricks (the shot passes through its own castle while leaving the keep)
				local skip = nil
				if p.self_time > 0 then
					skip = (p.team == "player") and b.player or b.enemy
				end
				local brick = M.brick_at(self, p.x, p.y, p.radius, p.ignore, skip)
				if brick then
					if p.pierce > 0 then
						p.pierce = p.pierce - 1
						p.ignore[brick] = true
					else
						M.detonate(self, p, p.x, p.y, brick)
						exploded = true
						break
					end
				end
				-- units
				local u = M.unit_at(self, p.x, p.y, p.radius, p.team)
				if u then
					M.detonate(self, p, p.x, p.y, nil, u)
					exploded = true
					break
				end
				-- platforms
				for _, castle in ipairs({ b.player, b.enemy }) do
					local px = castle.ax
					if math.abs(p.x - px) <= 170 + p.radius and math.abs(p.y - 184) <= 29 + p.radius then
						M.detonate(self, p, p.x, p.y, nil)
						exploded = true
						break
					end
				end
				if exploded then break end
				-- ground
				if p.y <= constants.GROUND_Y + p.radius then
					M.detonate(self, p, p.x, constants.GROUND_Y, nil)
					exploded = true
					break
				end
				-- bounds
				if p.x < -80 or p.x > 1360 or p.y > 900 then
					p.slot.active = false
					disable_go(p.slot.id)
					break
				end
			end
		end
		if p.self_time and p.self_time > 0 then p.self_time = math.max(0, p.self_time - dt) end
		if exploded then
			table.remove(b.projectiles, i)
		elseif not p.slot.active then
			table.remove(b.projectiles, i)
		else
			p.age = p.age + dt
			p.rot = p.rot + p.spin * dt * 60
			go.set_position(vmath.vector3(p.x, p.y, Z.projectile), p.slot.id)
			local angle = (p.spin ~= 0) and math.rad(p.rot) or math.atan2(p.vy, p.vx)
			go.set_rotation(vmath.quat_rotation_z(angle), p.slot.id)
			-- trail
			if p.heavy then
				p.trail = p.trail + dt
				if p.trail > 0.07 then
					p.trail = 0
					M.spawn_fx(self, "fx_smoke", p.x, p.y, Z.fx, 22, 22,
						vmath.vector4(1, 1, 1, 0.55), -p.vx * 0.05, 10, -0.1, 0.5, 0, 2, 0)
				end
			end
		end
	end
end

function M.detonate(self, p, x, y, brick, unit)
	p.slot.active = false
	disable_go(p.slot.id)
	audio.play_explosion(p.blast)
	camera.shake(math.min(16, p.blast * 0.22), 0.32)
	camera.punch_zoom(0.02)
	self.battle.hitstop = constants.HITSTOP
	M.spawn_fx(self, "fx_burst", x, y, Z.fx, p.blast * 1.7, p.blast * 1.7, WHITE, 0, 0, 0, 0.32, 0, 1.6, 0)
	M.spawn_fx(self, "fx_ring", x, y, Z.fx + 0.001, p.blast * 1.4, p.blast * 1.4, vmath.vector4(1, 0.9, 0.7, 0.8), 0, 0, 0, 0.3, 0, 2.2, 0)
	for i = 1, 3 do
		M.spawn_fx(self, "fx_smoke", x + (math.random() - 0.5) * 30, y + (math.random() - 0.5) * 24,
			Z.fx, 34 + math.random() * 20, 34 + math.random() * 20,
			vmath.vector4(1, 1, 1, 0.6), (math.random() - 0.5) * 40, 20 + math.random() * 30,
			-0.15, 0.7 + math.random() * 0.3, 0, 2.1, 0)
	end
	for i = 1, 4 do
		M.spawn_fx(self, "fx_spark", x, y, Z.fx, 14, 14, WHITE,
			(math.random() - 0.5) * 320, (math.random() - 0.5) * 320, 0.9, 0.35, 0, 1, 0)
	end

	-- brick damage on both castles (self-damage included)
	local destroyed = {}
	for _, castle in ipairs({ self.battle.player, self.battle.enemy }) do
		local list = wall.blast(castle, x, y, p.blast, p.wall, p.pierce > 0)
		for _, b in ipairs(list) do table.insert(destroyed, b) end
	end
	for _, b in ipairs(destroyed) do
		M.destroy_brick(self, b)
	end
	for _, castle in ipairs({ self.battle.player, self.battle.enemy }) do
		for _, b in ipairs(castle.bricks) do
			if b.alive then M.update_brick_visual(b) end
		end
	end

	-- unit damage
	if unit then
		M.damage_unit(self, unit, p.unit_damage, x, y)
	end
	for _, castle in ipairs({ self.battle.player, self.battle.enemy }) do
		for _, u in ipairs(castle.units) do
			if u.alive and u ~= unit then
				local dx, dy = u.x - x, (u.y + 2) - y
				local dist = math.sqrt(dx * dx + dy * dy)
				local reach = p.blast + constants.UNIT_HIT_R
				if dist < reach then
					local dmg = p.unit_damage * wall.falloff(dist, reach)
					if dmg > 2 then
						M.damage_unit(self, u, dmg, u.x, u.y)
					end
				end
			end
		end
	end
end

function M.destroy_brick(self, brick)
	if not brick.alive then return end
	brick.alive = false
	if brick.id then
		disable_go(brick.id)
	end
	local shard = "fx_shard_" .. (brick.kind or "stone")
	M.spawn_fx(self, shard, brick.wx, brick.wy, Z.fx,
		14, 14, WHITE,
		(math.random() - 0.5) * 140, 60 + math.random() * 80,
		1.0, 0.9, (math.random() - 0.5) * 720, 1, 0.8)
end

function M.update_brick_visual(brick)
	if not brick.alive or not brick.url then return end
	sprite.play_flipbook(brick.url, hash(Castle.brick_anim(brick.kind, wall.state(brick))))
end

-- ------------------------------------------------------------------ FX
function M.spawn_fx(self, anim, x, y, z, w, h, tint, vx, vy, grav, life, spin, grow, drag)
	local slot = nil
	for _, s in ipairs(self.battle.fx) do
		if not s.active then slot = s break end
	end
	if not slot then return end
	slot.active = true
	enable_go(slot.id)
	set_anim(self, slot, anim, w, h, tint)
	go.set_position(vmath.vector3(x, y, z), slot.id)
	go.set_rotation(vmath.quat_rotation_z(0), slot.id)
	slot.x, slot.y, slot.z = x, y, z
	slot.vx, slot.vy = vx or 0, vy or 0
	slot.grav = grav or 0
	slot.life = life or 0.6
	slot.age = 0
	slot.spin = spin or 0
	slot.rot = 0
	slot.grow = grow or 1
	slot.drag = drag or 0
	slot.tint = tint or WHITE
	slot.w, slot.h = w or 30, h or 30
end

function M.update_fx(self, dt)
	for _, f in ipairs(self.battle.fx) do
		if f.active then
			f.age = f.age + dt
			if f.age >= f.life then
				f.active = false
				disable_go(f.id)
			else
				f.vy = f.vy - f.grav * constants.GRAVITY * dt
				if f.drag > 0 then
					local k = math.max(0, 1 - f.drag * dt)
					f.vx, f.vy = f.vx * k, f.vy * k
				end
				f.x = f.x + f.vx * dt
				f.y = f.y + f.vy * dt
				f.rot = f.rot + f.spin * dt
				go.set_position(vmath.vector3(f.x, f.y, f.z), f.id)
				go.set_rotation(vmath.quat_rotation_z(math.rad(f.rot)), f.id)
				local t = f.age / f.life
				local s = 1 + (f.grow - 1) * t
				local bw, bh = base_size(f.anim or "fx_smoke", f.w, f.h)
				go.set_scale(vmath.vector3(s * f.w / bw, s * f.h / bh, 1), f.id)
				if t > 0.55 then
					local a = (1 - t) / 0.45
					go.set(f.url, "tint", vmath.vector4(f.tint.x, f.tint.y, f.tint.z, f.tint.w * a))
				end
			end
		end
	end
end

-- ------------------------------------------------------------------ aim
function M.collide_preview(self, x, y)
	if y <= constants.GROUND_Y + 2 then return true end
	if M.brick_at(self, x, y, 3, {}, self.battle.player) then return true end
	if M.unit_at(self, x, y, 3, "player") then return true end
	for _, castle in ipairs({ self.battle.player, self.battle.enemy }) do
		if math.abs(x - castle.ax) <= 170 and math.abs(y - 184) <= 29 then
			return true
		end
	end
	return false
end

function M.compute_aim(self, sx, sy)
	local b = self.battle
	local u = M.current_unit(self)
	if not u or not u.alive then return nil end
	local dx = sx - b.aim_sx
	local dy = sy - b.aim_sy
	local len = math.sqrt(dx * dx + dy * dy)
	if len < constants.DEAD_ZONE then
		return nil
	end
	local power = math.min(len, constants.MAX_PULL)
	local role = units_db.get(u.role)
	local t = (power / constants.MAX_PULL) ^ constants.POWER_CURVE
	local speed = (constants.MIN_SPEED + t * (constants.MAX_SPEED - constants.MIN_SPEED)) * role.speed
	local nx, ny = -dx / len, -dy / len
	local vx, vy = nx * speed, ny * speed
	local gravity = constants.GRAVITY * (role.gravity or 1)
	local points = ballistics.preview(u.x, u.y + 6, vx, vy, gravity, 70, 0.025,
		function(px, py) return M.collide_preview(self, px, py) end)
	local shown = math.max(4, math.floor(#points * constants.PREVIEW_FRACTION))
	local dots = {}
	for i = 1, 18 do
		local idx = math.floor(1 + (shown - 1) * (i - 1) / 17)
		local pt = points[math.min(idx, #points)]
		table.insert(dots, pt)
	end
	return { vx = vx, vy = vy, dots = dots, power = power / constants.MAX_PULL }
end

function M.show_preview(self, dots)
	local b = self.battle
	for i, d in ipairs(b.dots) do
		local pt = dots[i]
		if pt then
			d.active = true
			enable_go(d.id)
			go.set_position(vmath.vector3(pt.x, pt.y, Z.dots), d.id)
			local a = 1.0 - i * 0.028
			go.set(d.url, "tint", vmath.vector4(1, 1, 1, a))
			go.set_scale(vmath.vector3(1.5, 1.5, 1), d.id)
		elseif d.active then
			d.active = false
			disable_go(d.id)
		end
	end
end

function M.hide_preview(self)
	for _, d in ipairs(self.battle.dots) do
		if d.active then
			d.active = false
			disable_go(d.id)
		end
	end
end

function M.update_aim_line(self, sx, sy, power)
	local b = self.battle
	local u = M.current_unit(self)
	if not u or not u.alive then
		M.hide_aim_line(self)
		return
	end
	local wx, wy = camera.screen_to_world(sx, sy)
	local x0, y0 = u.x, u.y + 6
	local dx, dy = wx - x0, wy - y0
	local len = math.sqrt(dx * dx + dy * dy)
	if len < 10 then
		M.hide_aim_line(self)
		return
	end
	local line = b.aim_line
	if not line.active then
		line.active = true
		enable_go(line.id)
	end
	local knob = b.aim_knob
	if not knob.active then
		knob.active = true
		enable_go(knob.id)
	end
	go.set_position(vmath.vector3((x0 + wx) * 0.5, (y0 + wy) * 0.5, -0.42), line.id)
	go.set_rotation(vmath.quat_rotation_z(math.atan2(dy, dx)), line.id)
	local t = math.max(0, math.min(1, power or len / constants.MAX_PULL))
	go.set_scale(vmath.vector3(len / 16, 0.2 + 0.28 * t, 1), line.id)
	go.set(line.url, "tint", vmath.vector4(1, 0.95 - 0.55 * t, 0.75 - 0.65 * t, 0.75))
	go.set_position(vmath.vector3(wx, wy, -0.41), knob.id)
	local ks = 0.8 + 0.6 * t
	go.set_scale(vmath.vector3(ks, ks, 1), knob.id)
	go.set(knob.url, "tint", vmath.vector4(1, 0.85 - 0.3 * t, 0.25, 0.92))
end

function M.hide_aim_line(self)
	local b = self.battle
	if b.aim_line and b.aim_line.active then
		b.aim_line.active = false
		disable_go(b.aim_line.id)
	end
	if b.aim_knob and b.aim_knob.active then
		b.aim_knob.active = false
		disable_go(b.aim_knob.id)
	end
end

function M.cancel_aim(self)
	self.battle.aiming = false
	self.battle.aim = nil
	camera.set_zoom(1.0)
	M.hide_aim_line(self)
	M.hide_preview(self)
end

function M.release_aim(self)
	local b = self.battle
	local aim = b.aim
	b.aiming = false
	b.aim = nil
	camera.set_zoom(1.0)
	M.hide_aim_line(self)
	M.hide_preview(self)
	if not aim then return end
	local u = M.current_unit(self)
	if not u or not u.alive then return end
	M.fire_projectiles(self, u, aim.vx, aim.vy)
	u.cooldown = 2
	b.state = "flying"
	M.update_hud(self)
end

-- ------------------------------------------------------------------ input
function M.on_input(self, action_id, action)
	local b = self.battle
	if b.paused or b.state == "over" then return false end
	if action_id == hash("unit_1") and action.pressed then M.select_unit(self, 1) return true end
	if action_id == hash("unit_2") and action.pressed then M.select_unit(self, 2) return true end
	if action_id == hash("unit_3") and action.pressed then M.select_unit(self, 3) return true end
	if action_id == hash("unit_4") and action.pressed then M.select_unit(self, 4) return true end
	if action_id == hash("debug_b") and action.pressed then
		for _, u in ipairs(b.enemy.units) do M.kill_unit(self, u) end
		M.finish(self, true)
		return true
	end
	if action_id == hash("debug_a") and action.pressed then
		M.debug_blast(self, b.enemy.ax - 104, constants.CASTLE_BOTTOM + 4 * constants.CELL_H, 62, 220)
		return true
	end
	if action_id == hash("touch") then
		if action.pressed and b.state == "aim" then
			local u = M.current_unit(self)
			if u and u.alive then
				b.aiming = true
				b.aim_sx, b.aim_sy = action.x, action.y
				b.aim_cx, b.aim_cy = action.x, action.y
				b.aim = nil
				camera.set_zoom(constants.AIM_ZOOM)
				M.hide_preview(self)
				M.hide_aim_line(self)
				return true
			end
		elseif b.aiming then
			if action.released then
				M.release_aim(self)
				return true
			end
			b.aim_cx, b.aim_cy = action.x, action.y
			b.aim = M.compute_aim(self, action.x, action.y)
			if b.aim then
				M.update_aim_line(self, action.x, action.y, b.aim.power)
				M.show_preview(self, b.aim.dots)
			else
				M.hide_aim_line(self)
				M.hide_preview(self)
			end
			return true
		end
	end
	if action_id == hash("touch_alt") and action.pressed and b.aiming then
		M.cancel_aim(self)
		return true
	end
	return false
end

-- ------------------------------------------------------------------ collapse
function M.start_room_fall(self, room, dy)
	local fall = { room = room, t = 0, dur = 0.26, dy = dy, bricks = {}, unit = nil }
	for _, brick in ipairs(room.bricks) do
		if brick.alive then
			table.insert(fall.bricks, { brick = brick, from_y = brick.wy - dy })
		end
	end
	if room.unit then
		fall.unit = { unit = room.unit, from_y = room.unit.y - dy }
	end
	fall.opening_from = room.uy - dy
	fall.balcony_from = (room.decor.balcony_y or room.uy) - dy
	room.fall = fall
	table.insert(self.battle.falls, fall)
end

function M.update_falls(self, dt)
	local b = self.battle
	for i = #b.falls, 1, -1 do
		local f = b.falls[i]
		f.t = f.t + dt
		local k = math.min(1, f.t / f.dur)
		local e = 1 - (1 - k) * (1 - k)
		for _, item in ipairs(f.bricks) do
			local br = item.brick
			local y = item.from_y + (br.wy - item.from_y) * e
			go.set_position(vmath.vector3(br.wx, y, br.z or Z.brick), br.id)
		end
		if f.unit then
			M.place_unit_at(f.unit.unit, f.unit.from_y + (f.unit.unit.y - f.unit.from_y) * e)
		end
		local room = f.room
		go.set_position(vmath.vector3(room.ux, f.opening_from + (room.uy - f.opening_from) * e, Z.opening), room.decor.opening)
		go.set_position(vmath.vector3(room.ux, f.balcony_from + ((room.decor.balcony_y or room.uy) - f.balcony_from) * e, Z.balcony), room.decor.balcony)
		if k >= 1 then
			for _, item in ipairs(f.bricks) do
				go.set_position(vmath.vector3(item.brick.wx, item.brick.wy, item.brick.z or Z.brick), item.brick.id)
			end
			if f.unit then M.place_unit_at(f.unit.unit, f.unit.unit.y) end
			room.fall = nil
			table.remove(b.falls, i)
		end
	end
end

function M.place_unit_at(unit, y)
	go.set_position(vmath.vector3(unit.x, y, Z.unit_body), unit.body_id)
	go.set_position(vmath.vector3(unit.x, y, Z.unit_gear), unit.gear_id)
	go.set_position(vmath.vector3(unit.x, y + 3, Z.unit_eyes), unit.eyes_id)
	go.set_position(vmath.vector3(unit.x, y - 26, Z.unit_shadow), unit.shadow_id)
end

function M.collapse(self)
	local b = self.battle
	for pass = 1, 4 do
		Castle.update_support(b.player)
		Castle.update_support(b.enemy)
		local any = false
		for _, castle in ipairs({ b.player, b.enemy }) do
			local falls = Castle.plan_falls(castle)
			for _, f in ipairs(falls) do
				local room = f.room
				local drop = f.drop
				local dy = -drop * constants.ROOM_CELLS * constants.CELL_H
				any = true

				-- a floor that lost its own bottom row crushes the room below
				if f.below then
					for _, br in ipairs(f.below.bricks) do
						if br.alive then M.destroy_brick(self, br) end
					end
					if f.below.decor then
						if f.below.decor.opening then disable_go(f.below.decor.opening) end
						if f.below.decor.balcony then disable_go(f.below.decor.balcony) end
					end
					if f.below.unit and f.below.unit.alive then
						M.damage_unit(self, f.below.unit, 999, f.below.ux, f.below.uy)
					end
				end

				-- crush damage on the falling room
				if room.unit and room.unit.alive then
					M.damage_unit(self, room.unit, constants.CRUSH_DAMAGE * drop, room.ux, room.uy)
				end
				for _, brick in ipairs(room.bricks) do
					if brick.alive then
						if wall.apply_damage(brick, 16 * drop) then
							M.destroy_brick(self, brick)
						else
							M.update_brick_visual(brick)
						end
					end
				end
				-- and on the room it lands on
				for rr2 = 0, 2 do
					for cc2 = 0, 2 do
						local other = castle.rooms[rr2][cc2]
						if other ~= room and other.cc == room.cc and other.level < room.level then
							for _, brick in ipairs(other.bricks) do
								if brick.alive and wall.apply_damage(brick, 22 * drop) then
									M.destroy_brick(self, brick)
								elseif brick.alive then
									M.update_brick_visual(brick)
								end
							end
						end
					end
				end
				Castle.shift_room(room, dy)
				if room.decor.balcony_y then room.decor.balcony_y = room.decor.balcony_y + dy end
				M.start_room_fall(self, room, dy)
				M.spawn_fx(self, "fx_dust", room.ux, room.uy - 30, Z.fx, 80, 40,
					vmath.vector4(1, 1, 1, 0.6), 0, 30, -0.1, 0.8, 0, 2.2, 0.5)
				camera.shake(10, 0.3)
				audio.play("bounce", { speed = 0.55, gain = 1.0 })
			end
		end
		if not any then break end
	end
end

-- ------------------------------------------------------------------ state
function M.debug_blast(self, x, y, radius, damage)
	local b = self.battle
	local destroyed = wall.blast(b.enemy, x, y, radius, damage, false)
	for _, br in ipairs(destroyed) do M.destroy_brick(self, br) end
	for _, br in ipairs(b.enemy.bricks) do
		if br.alive then M.update_brick_visual(br) end
	end
	M.spawn_fx(self, "fx_burst", x, y, Z.fx, radius * 1.4, radius * 1.4, WHITE, 0, 0, 0, 0.35, 0, 1.6, 0)
	M.spawn_fx(self, "fx_smoke", x, y - 20, Z.fx, 80, 50, vmath.vector4(1, 1, 1, 0.7), 0, 30, -0.1, 0.8, 0, 2, 0.4)
	camera.shake(16, 0.4)
	audio.play_explosion(radius)
	M.collapse(self)
end

function M.first_ready(self)
	local b = self.battle
	for i, u in ipairs(b.player.units) do
		if u.alive and u.cooldown == 0 then return i end
	end
	for i, u in ipairs(b.player.units) do
		if u.alive then
			u.cooldown = 0
			return i
		end
	end
	return nil
end

function M.start_player_turn(self)
	local b = self.battle
	for _, u in ipairs(b.player.units) do
		if u.cooldown > 0 then u.cooldown = u.cooldown - 1 end
	end
	b.state = "aim"
	b.turn = "player"
	local idx = M.first_ready(self)
	if idx then
		M.select_unit(self, idx, true)
	else
		M.finish(self, false)
		return
	end
	M.banner(self, i18n.t("your_turn"))
	M.update_hud(self)
end

function M.start_enemy_turn(self)
	local b = self.battle
	b.state = "enemy"
	b.turn = "enemy"
	b.timer = constants.AI_DELAY
	camera.set_zoom(1.0)
	M.hide_aim_line(self)
	M.banner(self, i18n.t("enemy_turn"))
	M.update_hud(self)
end

function M.enemy_fire(self)
	local b = self.battle
	local shot = ai.pick_shot(b.enemy, b.player, 5.5)
	if not shot then
		M.finish(self, true)
		return
	end
	M.fire_projectiles(self, shot.unit, shot.vx, shot.vy)
	b.state = "flying"
end

function M.finish(self, win)
	local b = self.battle
	b.state = "over"
	b.winner = win and "player" or "enemy"
	camera.set_zoom(1.0)
	M.hide_aim_line(self)
	M.hide_preview(self)
	if win then
		audio.play("win")
		audio.music(nil)
	else
		audio.play("lose")
		audio.music(nil)
	end
	msg.post("/gui_hud#gui", "battle_over", { win = win })
	M.update_hud(self)
end

function M.check_win(self)
	local b = self.battle
	if Castle.all_units_dead(b.enemy) then
		M.finish(self, true)
		return true
	end
	if Castle.all_units_dead(b.player) then
		M.finish(self, false)
		return true
	end
	return false
end

function M.toggle_pause(self)
	local b = self.battle
	if b.state == "over" then return end
	b.paused = not b.paused
	msg.post("/gui_hud#gui", "pause_changed", { paused = b.paused })
end

function M.update_state(self, dt)
	local b = self.battle
	if b.state == "intro" then
		b.timer = b.timer - dt
		if b.timer <= 0 then
			M.start_player_turn(self)
		end
	elseif b.state == "flying" then
		if #b.projectiles == 0 then
			b.state = "resolve"
			b.timer = 0.3
		end
	elseif b.state == "resolve" then
		b.timer = b.timer - dt
		if b.timer <= 0 then
			M.collapse(self)
			if M.check_win(self) then return end
			b.state = "settle"
			b.timer = 0.45
		end
	elseif b.state == "settle" then
		if #b.falls == 0 then
			b.timer = b.timer - dt
			if b.timer <= 0 then
				if M.check_win(self) then return end
				if b.turn == "player" then
					M.start_enemy_turn(self)
				else
					M.start_player_turn(self)
				end
			end
		end
	elseif b.state == "enemy" then
		b.timer = b.timer - dt
		if b.timer <= 0 then
			M.enemy_fire(self)
		end
	end
end

function M.update(self, dt)
	local b = self.battle
	if b.paused then return end
	b.time = b.time + dt
	if b.hitstop > 0 then
		b.hitstop = math.max(0, b.hitstop - dt)
		M.update_fx(self, dt)
		return
	end
	M.update_gates(self, dt)
	M.update_projectiles(self, dt)
	M.update_fx(self, dt)
	M.update_falls(self, dt)
	M.update_state(self, dt)

	-- unit flashes / eyes
	for _, castle in ipairs({ b.player, b.enemy }) do
		for _, u in ipairs(castle.units) do
			if u.alive then
				if u.flash > 0 then
					u.flash = u.flash - dt
					if u.flash <= 0 then
						go.set(u.body_url, "tint", TEAM_TINT[u.team])
					end
				end
				if u.eyes_timer > 0 then
					u.eyes_timer = u.eyes_timer - dt
					if u.eyes_timer <= 0 and u.alive then
						sprite.play_flipbook(u.eyes_url, hash("eyes_idle"))
					end
				end
			end
		end
	end

	if b.sel_ring.active then
		local u = M.current_unit(self)
		if u and u.alive then
			go.set_position(vmath.vector3(u.x, u.y, Z.selection), b.sel_ring.id)
			local s = 1.25 + math.sin(b.time * 4) * 0.08
			go.set_scale(vmath.vector3(s, s, 1), b.sel_ring.id)
		end
	end
end

-- ------------------------------------------------------------------ lifecycle
function M.init(self)
	self.battle = {
		ids = {},
		arena_ids = {},
		projectiles = {},
		fx = {},
		dots = {},
		gates = {},
		falls = {},
		pending = {},
		state = "boot",
		timer = 0,
		paused = false,
		turn = "player",
		selected = 1,
		hitstop = 0,
		time = 0,
	}
	M.build_arena(self)
	M.build_pools(self)
	M.start_battle(self)
end

function M.on_message(self, message_id, message, sender)
	if message_id == hash("select_unit") then
		M.select_unit(self, message.index or 1)
	elseif message_id == hash("toggle_pause") then
		M.toggle_pause(self)
	elseif message_id == hash("restart_battle") then
		M.start_battle(self)
	elseif message_id == hash("hud_ready") then
		M.update_hud(self)
	end
end

return M




