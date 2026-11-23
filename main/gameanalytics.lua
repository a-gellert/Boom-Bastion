-- main/gameanalytics.lua
-- Thin, crash-proof adapter over the official GameAnalytics Defold SDK (GA-SDK-DEFOLD 5.x).
--
-- The SDK is added as a project dependency and configured in the [gameanalytics] section of
-- game.project, so it initializes itself when the game starts. Every call here is optional and
-- wrapped in pcall: analytics must never interrupt gameplay, and builds without the extension
-- (or a platform where it is unavailable) keep working through the no-op fallbacks in main/sdk.lua.

local M = {}

local MAX_EVENT_SEGMENTS = 5

-- The extension registers a global "gameanalytics" table. The pcall(require) is a fallback for
-- builds where the module is exposed as a Lua module instead.
local function api()
	local ga = rawget(_G, "gameanalytics")
	if type(ga) == "table" then
		return ga
	end
	local ok, mod = pcall(require, "gameanalytics")
	if ok and type(mod) == "table" then
		return mod
	end
	return nil
end

function M.is_available()
	local ga = api()
	return ga ~= nil and type(ga.addDesignEvent) == "function"
end

local function invoke(method, ...)
	local ga = api()
	if not ga or type(ga[method]) ~= "function" then
		return false
	end
	local ok, err = pcall(ga[method], ...)
	if not ok then
		print("[GameAnalytics] " .. method .. " failed: " .. tostring(err))
	end
	return ok
end

-- GameAnalytics accepts letters, digits and a small set of punctuation in event values. Strip
-- everything else so a stray id (underscores, spaces, localised text) cannot make the SDK reject
-- the whole event.
local function clean(value, fallback)
	local s = tostring(value == nil and "" or value)
	s = s:gsub("[^%w_%-%.%(%)!%?%s]", "")
	s = s:gsub("%s+", "")
	if s == "" then
		return fallback or "unknown"
	end
	if #s > 64 then
		s = s:sub(1, 64)
	end
	return s
end

-- Design event ids are 1-5 colon separated segments; the first segment is stricter (no underscore).
local function clean_event_id(event_id)
	local parts = {}
	for part in tostring(event_id == nil and "" or event_id):gmatch("[^:]+") do
		local cleaned = clean(part, "")
		if #parts == 0 then
			cleaned = cleaned:gsub("_", "")
			if cleaned == "" then
				cleaned = "event"
			end
		elseif cleaned == "" then
			cleaned = "unknown"
		end
		parts[#parts + 1] = cleaned
		if #parts == MAX_EVENT_SEGMENTS then
			break
		end
	end
	if #parts == 0 then
		parts[1] = "event"
	end
	return table.concat(parts, ":")
end

--- Called from main/sdk.lua after the platform is known. The extension initializes itself, so this
--- only reports availability; call initialize() explicitly only with manual_initialize = 1.
function M.init()
	if M.is_available() then
		M.available = true
		print("[GameAnalytics] SDK ready")
		return true
	end
	M.available = false
	print("[GameAnalytics] SDK not available — analytics calls are no-ops")
	return false
end

function M.initialize()
	if M.is_available() then
		return invoke("initialize")
	end
	return false
end

--- Custom dimensions (whitelisted in game.project under [gameanalytics]).
function M.set_dimension_01(value)
	if value and value ~= "" then
		return invoke("setCustomDimension01", clean(value))
	end
	return false
end

function M.set_dimension_02(value)
	if value and value ~= "" then
		return invoke("setCustomDimension02", clean(value))
	end
	return false
end

function M.set_dimension_03(value)
	if value and value ~= "" then
		return invoke("setCustomDimension03", clean(value))
	end
	return false
end

--- Structured progression. progression01 is the world/chapter, 02 the level, 03 an optional stage.
function M.start_progression(progression01, progression02, progression03)
	return invoke("addProgressionEvent", {
		progressionStatus = "Start",
		progression01 = clean(progression01, "game"),
		progression02 = progression02 ~= nil and clean(progression02) or nil,
		progression03 = progression03 ~= nil and clean(progression03) or nil,
	})
end

function M.complete_progression(progression01, progression02, progression03, score)
	local options = {
		progressionStatus = "Complete",
		progression01 = clean(progression01, "game"),
		progression02 = progression02 ~= nil and clean(progression02) or nil,
		progression03 = progression03 ~= nil and clean(progression03) or nil,
	}
	local value = tonumber(score)
	if value then
		options.score = math.floor(value + 0.5)
	end
	return invoke("addProgressionEvent", options)
end

function M.fail_progression(progression01, progression02, progression03, score)
	local options = {
		progressionStatus = "Fail",
		progression01 = clean(progression01, "game"),
		progression02 = progression02 ~= nil and clean(progression02) or nil,
		progression03 = progression03 ~= nil and clean(progression03) or nil,
	}
	local value = tonumber(score)
	if value then
		options.score = math.floor(value + 0.5)
	end
	return invoke("addProgressionEvent", options)
end

--- Free-form event: category:subcategory:outcome (max 5 segments). value is optional.
function M.design_event(event_id, value)
	if event_id == nil or event_id == "" then
		return false
	end
	local options = { eventId = clean_event_id(event_id) }
	local number = tonumber(value)
	if number then
		options.value = number
	end
	return invoke("addDesignEvent", options)
end

--- Virtual currency flow. flow is "Source" (gained) or "Sink" (spent).
function M.resource_event(flow, currency, amount, item_type, item_id)
	local value = tonumber(amount) or 0
	if value <= 0 then
		return false
	end
	return invoke("addResourceEvent", {
		flowType = (flow == "Sink") and "Sink" or "Source",
		currency = clean(currency, "coins"),
		amount = value,
		itemType = clean(item_type, "other"),
		itemId = clean(item_id, "item"),
	})
end

--- Real-money purchase. amount is in cents, e.g. 99 for 0.99 USD.
function M.business_event(currency, amount, item_type, item_id, cart_type)
	local value = math.floor(tonumber(amount) or 0)
	if value <= 0 then
		return false
	end
	return invoke("addBusinessEvent", {
		currency = clean(currency, "USD"),
		amount = value,
		itemType = clean(item_type, "iap"),
		itemId = clean(item_id, "item"),
		cartType = clean(cart_type, "store"),
	})
end

--- adAction: Clicked | Show | FailedShow | RewardReceived
--- adType: Video | RewardedVideo | Playable | Interstitial | OfferWall | Banner
function M.ad_event(ad_action, ad_type, sdk_name, placement, duration, no_ad_reason)
	local options = {
		adAction = ad_action or "Show",
		adType = ad_type or "Interstitial",
		adSdkName = clean(sdk_name, "none"),
		adPlacement = clean(placement, "default"),
	}
	local time = tonumber(duration)
	if time and time > 0 then
		options.duration = math.floor(time + 0.5)
	elseif no_ad_reason then
		options.noAdReason = no_ad_reason
	end
	return invoke("addAdEvent", options)
end

--- severity: Debug | Info | Warning | Error | Critical
function M.error_event(severity, message)
	return invoke("addErrorEvent", {
		severity = severity or "Warning",
		message = tostring(message or "unknown"),
	})
end

function M.set_user_id(user_id)
	if user_id == nil or user_id == "" then
		return false
	end
	return invoke("setExternalUserId", tostring(user_id))
end

function M.get_user_id()
	local ga = api()
	if ga and type(ga.getUserId) == "function" then
		local ok, value = pcall(ga.getUserId)
		if ok then
			return value
		end
	end
	return ""
end

function M.start_session()
	return invoke("startSession")
end

function M.end_session()
	return invoke("endSession")
end

function M.set_enabled(enabled)
	return invoke("setEnabledEventSubmission", enabled == true)
end

return M
