-- lua_modules/audio.lua
-- Shared SFX/music player. Sound components live on /audio (see main/audio.go).

local M = {}

local AUDIO_GO = "/audio#"
local GROUP_MASTER = hash("master")
local GROUP_SFX = hash("sfx")
local GROUP_MUSIC = hash("music")

local SFX = {
	click = 0.7, pop = 0.6, whoosh = 0.5,
	bounce = 0.5,
	explode_small = 0.85, explode_big = 1.0, explode_huge = 1.0,
	hurt = 0.8, heal = 0.7,
	win = 0.9, lose = 0.8,
	coins = 0.7, unlock = 0.9,
	turn_player = 0.6, turn_enemy = 0.5, tick = 0.5,
}

local MUSIC_GAIN = {
	music_menu = 1.0,
	music_battle = 0.65,
}

local MIN_GAP = 0.05
local last_played = {}

local volume = { sfx = 1.0, music = 0.6 }
local ad_muted = false
local focus_muted = false
local current_music = nil
local music_paused = false
local initialized = false
local game_loaded = false
local pending_music = nil

local function apply_gains()
	local muted = ad_muted or focus_muted
	pcall(sound.set_group_gain, GROUP_MASTER, muted and 0 or 1)
	pcall(sound.set_group_gain, GROUP_SFX, volume.sfx)
	pcall(sound.set_group_gain, GROUP_MUSIC, volume.music)
end
M.apply_gains = apply_gains

function M.init()
	if initialized then return end
	initialized = true
	apply_gains()
	if window and window.set_listener then
		window.set_listener(function(_, event)
			if event == window.WINDOW_EVENT_FOCUS_LOST then
				focus_muted = true
				apply_gains()
			elseif event == window.WINDOW_EVENT_FOCUS_GAINED then
				focus_muted = false
				apply_gains()
			end
		end)
	end
end

function M.set_volume(kind, v)
	volume[kind] = math.max(0, math.min(1, v or 0))
	apply_gains()
end

function M.get_volume(kind)
	return volume[kind]
end

function M.set_ad_mute(muted)
	ad_muted = muted
	apply_gains()
end

-- opts: gain, speed, vary, pan
function M.play(name, opts)
	local base = SFX[name]
	if not base then return end
	local now = socket and socket.gettime and socket.gettime() or os.clock()
	local t = last_played[name]
	if t and now - t < MIN_GAP then return end
	last_played[name] = now
	opts = opts or {}
	local speed = opts.speed or 1
	if opts.vary then
		speed = speed * (1 + (math.random() * 2 - 1) * opts.vary)
	end
	pcall(sound.play, AUDIO_GO .. name, {
		gain = base * (opts.gain or 1),
		speed = speed,
		pan = opts.pan or 0,
	})
end

function M.music(name)
	if not game_loaded then
		pending_music = name
		return
	end
	if name == current_music then return end
	if current_music then
		pcall(sound.stop, AUDIO_GO .. current_music)
	end
	current_music = name
	if name and not music_paused then
		pcall(sound.play, AUDIO_GO .. name, { gain = MUSIC_GAIN[name] or 1.0 })
	end
end

function M.on_game_loaded()
	if game_loaded then return end
	game_loaded = true
	if pending_music then
		local track = pending_music
		pending_music = nil
		M.music(track)
	end
end

function M.pause_all()
	if current_music and not music_paused then
		pcall(sound.stop, AUDIO_GO .. current_music)
		music_paused = true
	end
end

function M.resume_all()
	if not music_paused then return end
	music_paused = false
	if game_loaded and current_music then
		pcall(sound.play, AUDIO_GO .. current_music, { gain = MUSIC_GAIN[current_music] or 1.0 })
	end
end

function M.play_click()
	M.play("click")
end

function M.play_explosion(radius)
	radius = radius or 36
	if radius >= 80 then
		M.play("explode_huge", { vary = 0.05 })
	elseif radius >= 40 then
		M.play("explode_big", { vary = 0.08 })
	else
		M.play("explode_small", { vary = 0.12 })
	end
end

return M
