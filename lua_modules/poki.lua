-- lua_modules/poki.lua
-- Optional Poki SDK bridge. The web bundle ships tools/web/poki.js, which loads the
-- official SDK only on Poki hosts; everywhere else every call is a no-op.
-- Keep this module dependency-free: it must also run in the native editor.

local M = {}

local available = false
local checked = false
local loading_sent = false
local gameplay_running = false
local gameplay_sent = false
local check_timer = 0
local recheck_left = 20
local ad_active = false
local ad_poll = 0
local wins = 0
local last_ad = -999

local function js(code)
	if not (html5 and html5.run) then return nil end
	local ok, res = pcall(html5.run, code)
	if ok then return res end
	return nil
end

local function detect()
	local res = js("(window.BastionPoki && window.BastionPoki.available && window.BastionPoki.available()) ? 1 : 0")
	available = (res == "1" or res == "true")
	checked = true
	if available then
		if not loading_sent then
			loading_sent = true
			js("window.BastionPoki.gameLoadingFinished && window.BastionPoki.gameLoadingFinished()")
		end
		-- The SDK can initialise after the first battle starts; replay the state.
		if gameplay_running and not gameplay_sent then
			gameplay_sent = true
			js("window.BastionPoki.gameplayStart && window.BastionPoki.gameplayStart()")
		end
	end
end

function M.init()
	detect()
end

function M.available()
	return available
end

function M.gameplay_start()
	gameplay_running = true
	if available and not gameplay_sent then
		gameplay_sent = true
		js("window.BastionPoki.gameplayStart && window.BastionPoki.gameplayStart()")
	end
end

function M.gameplay_stop()
	gameplay_running = false
	gameplay_sent = false
	if available then js("window.BastionPoki.gameplayStop && window.BastionPoki.gameplayStop()") end
end

function M.happy_time()
	if available then js("window.BastionPoki.happyTime && window.BastionPoki.happyTime()") end
end

function M.game_loading_finished()
	if available and not loading_sent then
		loading_sent = true
		js("window.BastionPoki.gameLoadingFinished && window.BastionPoki.gameLoadingFinished()")
	end
end

-- Starts a rewarded/interstitial break. Returns true when the SDK accepted it.
function M.commercial_break()
	if not available then return false end
	local res = js("window.BastionPoki.commercialBreak ? (window.BastionPoki.commercialBreak() ? 1 : 0) : 0")
	if res == "1" then
		ad_active = true
		ad_poll = 0
		return true
	end
	return false
end

-- Every third win, at most once per two minutes of battle time.
function M.maybe_commercial(battle_time)
	wins = wins + 1
	if wins % 3 ~= 0 then return false end
	if (battle_time or 0) - last_ad < 120 then return false end
	if M.commercial_break() then
		last_ad = battle_time or 0
		return true
	end
	return false
end

function M.ad_active()
	return ad_active
end

-- Polls the ad state while a break is running. Returns "ad_end" on the frame the
-- break finishes so the caller can restore the mix.
function M.update(dt)
	if not checked or (not available and recheck_left > 0) then
		check_timer = check_timer + dt
		if check_timer >= 1 then
			check_timer = 0
			recheck_left = recheck_left - 1
			detect()
		end
	end
	if ad_active then
		ad_poll = ad_poll + dt
		if ad_poll >= 0.25 then
			ad_poll = 0
			local res = js("(window.BastionPoki && window.BastionPoki.adActive && window.BastionPoki.adActive()) ? 1 : 0")
			if res ~= "1" then
				ad_active = false
				return "ad_end"
			end
		end
	end
	return nil
end

return M
