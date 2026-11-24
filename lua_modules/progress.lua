-- lua_modules/progress.lua
-- Persistent meta: gold and castle/unit upgrades. sys.save keeps it in LocalStorage on web.

local M = {}

local SAVE_APP = "BastionBlast"
local SAVE_FILE = "save"
local LEGACY_NAME = "bastion_blast_save"

local save_path = nil

local function path()
	if not save_path then
		local ok, p = pcall(sys.get_save_file, SAVE_APP, SAVE_FILE)
		save_path = ok and p or (SAVE_APP .. "_" .. SAVE_FILE)
	end
	return save_path
end

M.KEYS = { "fortify", "power", "vitality" }

local DEFAULTS = {
	gold = 0,
	fortify = 0,
	power = 0,
	vitality = 0,
	best_level = 1,
	music = 1,
	sfx = 1,
}

M.data = nil

function M.load()
	if M.data then return M.data end
	local ok, saved = pcall(sys.load, path())
	if (not ok or type(saved) ~= "table" or not next(saved)) then
		local old_ok, old = pcall(sys.load, LEGACY_NAME)
		if old_ok and type(old) == "table" and next(old) then
			ok, saved = true, old
		end
	end
	if ok and type(saved) == "table" then
		M.data = {}
		for k, v in pairs(DEFAULTS) do
			M.data[k] = tonumber(saved[k]) or v
		end
		M.data.stars = (type(saved.stars) == "table") and saved.stars or {}
	else
		M.data = {}
		for k, v in pairs(DEFAULTS) do M.data[k] = v end
		M.data.stars = {}
	end
	return M.data
end

function M.save()
	local ok, err = pcall(sys.save, path(), M.data)
	if not ok then
		print("[BASTION] save failed:", err)
	end
end

function M.gold()
	return M.load().gold
end

function M.add_gold(amount)
	M.load().gold = math.max(0, M.data.gold + math.floor(amount))
	M.save()
	return M.data.gold
end

function M.spend(amount)
	if M.gold() < amount then return false end
	M.data.gold = M.data.gold - amount
	M.save()
	return true
end

function M.level(key)
	return M.load()[key] or 0
end

function M.cost(key)
	local lvl = M.level(key)
	if key == "fortify" then return math.floor(100 * 1.35 ^ lvl) end
	if key == "power" then return math.floor(120 * 1.35 ^ lvl) end
	return math.floor(90 * 1.35 ^ lvl)
end

function M.buy(key)
	if not M.data then M.load() end
	if M.level(key) >= 10 then return false end
	local price = M.cost(key)
	if not M.spend(price) then return false end
	M.data[key] = M.level(key) + 1
	M.save()
	return true
end

function M.wall_mult()
	return 1 + 0.10 * M.level("fortify")
end

function M.damage_mult()
	return 1 + 0.08 * M.level("power")
end

function M.hp_bonus()
	return 10 * M.level("vitality")
end

function M.best_level()
	return M.load().best_level
end

function M.set_best_level(n)
	if n > M.best_level() then
		M.data.best_level = n
		M.save()
	end
end

-- Sound settings: 1 = on, 0 = off. Persisted with the rest of the save.
function M.setting(key)
	return tonumber(M.load()[key]) or 0
end

function M.set_setting(key, value)
	M.load()[key] = value and 1 or 0
	M.save()
end

function M.stars(level_id)
	local saved = M.load().stars or {}
	return tonumber(saved[tostring(level_id)]) or 0
end

function M.set_stars(level_id, stars)
	M.load()
	local key = tostring(level_id)
	local best = math.max(M.stars(level_id), math.max(0, math.min(3, math.floor(stars or 0))))
	if best ~= M.stars(level_id) then
		M.data.stars[key] = best
		M.save()
	end
	return best
end

function M.total_stars()
	local total = 0
	for _, v in pairs(M.load().stars or {}) do total = total + (tonumber(v) or 0) end
	return total
end

return M
