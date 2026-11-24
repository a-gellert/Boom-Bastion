-- lua_modules/progress.lua
-- Persistent meta: gold and castle/unit upgrades. sys.save keeps it in LocalStorage on web.

local M = {}

local SAVE_NAME = "bastion_blast_save"

M.KEYS = { "fortify", "power", "vitality" }

local DEFAULTS = {
	gold = 0,
	fortify = 0,
	power = 0,
	vitality = 0,
	best_level = 1,
}

M.data = nil

function M.load()
	if M.data then return M.data end
	local ok, saved = pcall(sys.load, SAVE_NAME)
	if ok and type(saved) == "table" then
		M.data = {}
		for k, v in pairs(DEFAULTS) do
			M.data[k] = tonumber(saved[k]) or v
		end
	else
		M.data = {}
		for k, v in pairs(DEFAULTS) do M.data[k] = v end
	end
	return M.data
end

function M.save()
	pcall(sys.save, SAVE_NAME, M.data)
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

return M
