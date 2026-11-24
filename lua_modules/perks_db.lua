-- lua_modules/perks_db.lua
-- Twelve run modifiers, one picked from three cards after every won battle.

local i18n = require("lua_modules.i18n")

local M = {}

local function perk(id, en, ru, den, dru, apply)
	return {
		id = id,
		name = { en = en, ru = ru },
		desc = { en = den, ru = dru },
		apply = apply,
	}
end

M.LIST = {
	perk("radius", "WIDE BLAST", "ШИРОКИЙ ВЗРЫВ",
		"+25% blast radius", "+25% радиус взрыва",
		function(run) run.radius = run.radius * 1.25 end),
	perk("wall", "SIEGE POWER", "ОСАДНАЯ МОЩЬ",
		"+30% damage to walls", "+30% урон по стенам",
		function(run) run.wall = run.wall * 1.30 end),
	perk("unit", "HUNTER", "ОХОТНИК",
		"+30% damage to units", "+30% урон по юнитам",
		function(run) run.unit = run.unit * 1.30 end),
	perk("crit", "LUCKY SHOT", "УДАЧНЫЙ ВЫСТРЕЛ",
		"25% chance of x1.8 damage", "25% шанс урона x1.8",
		function(run) run.crit = run.crit + 0.25 end),
	perk("crush", "DEMOLISHER", "РАЗРУШИТЕЛЬ",
		"Double crush damage", "Двойной урон обрушения",
		function(run) run.crush = run.crush * 2 end),
	perk("pierce", "ARMOR PIERCER", "БРОНЕБОЙ",
		"Shots pierce one brick", "Снаряды пробивают кирпич",
		function(run) run.pierce = (run.pierce or 0) + 1 end),
	perk("x2x3", "GOLDEN MATH", "ЗОЛОТАЯ МАТЕМАТИКА",
		"x2 gates split into three", "Ворота x2 делят на три",
		function(run) run.x2x3 = true end),
	perk("extra", "EXTRA AMMO", "ДОБАВОЧНЫЙ ЗАЛП",
		"+1 projectile to every shot", "+1 снаряд к каждому выстрелу",
		function(run) run.extra = (run.extra or 0) + 1 end),
	perk("wallhp", "FORTIFY", "УКРЕПЛЕНИЕ",
		"+35% HP of your walls", "+35% HP твоих стен",
		function(run) run.wall_hp = run.wall_hp * 1.35 end),
	perk("unithp", "VETERANS", "ВЕТЕРАНЫ",
		"+25 max HP to your units", "+25 макс. HP твоим юнитам",
		function(run) run.unit_hp = (run.unit_hp or 0) + 25 end),
	perk("nocd", "RELENTLESS", "БЕЗУСТАЛЬ",
		"Units never need to rest", "Юниты не уходят на кулдаун",
		function(run) run.zero_cd = true end),
	perk("gold", "MERCENARY", "НАЁМНИК",
		"+40% gold from battles", "+40% золота за бои",
		function(run) run.gold = run.gold * 1.40 end),
}

function M.new_run()
	return {
		radius = 1.0,
		wall = 1.0,
		unit = 1.0,
		crit = 0.0,
		crush = 1.0,
		pierce = 0,
		x2x3 = false,
		extra = 0,
		wall_hp = 1.0,
		unit_hp = 0,
		zero_cd = false,
		gold = 1.0,
		perks = {},
	}
end

local function localized(tbl)
	return i18n.pick(tbl) or tbl.en or ""
end

function M.name(p)
	return localized(p.name)
end

function M.desc(p)
	return localized(p.desc)
end

function M.random_three(rng)
	local pool = {}
	for _, p in ipairs(M.LIST) do pool[p] = true end
	local out = {}
	while #out < 3 and next(pool) do
		local keys = {}
		for p in pairs(pool) do table.insert(keys, p) end
		local chosen = keys[math.random(#keys)]
		pool[chosen] = nil
		table.insert(out, chosen)
	end
	return out
end

return M
