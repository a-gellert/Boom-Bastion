-- lua_modules/i18n.lua
-- EN / RU / PT / TR. Add keys here; everything else reads through t().

local M = {}

M.LANGS = { "en", "ru", "pt", "tr" }
M.current_lang = "en"

local supported = {}
for _, code in ipairs(M.LANGS) do supported[code] = true end

local D = {
	en = {
		app_title = "BASTION BLAST",
		tagline = "Turn-based castle demolition",
		m1_badge = "M1 · LOOK-DEV",
		m1_hint = "Segmented walls, gates and collapsing floors arrive in M2.",
		hint_fire = "Drag anywhere · Release to fire",
		footer = "Defold 1.14 · procedural art pack",
		paused = "PAUSED",
		resume_hint = "Press Esc to resume",
		esc_pause = "ESC — pause",
		language = "Language",
		keep_blue = "BLUE FORT",
		keep_red = "RED KEEP",
	},
	ru = {
		app_title = "BASTION BLAST",
		tagline = "Пошаговое разрушение замков",
		m1_badge = "M1 · СТИЛЬ-КАДР",
		m1_hint = "Сегментные стены, ворота и обвал этажей — в M2.",
		hint_fire = "Тяни в любом месте · Отпусти, чтобы выстрелить",
		footer = "Defold 1.14 · процедурный арт-пак",
		paused = "ПАУЗА",
		resume_hint = "Esc — продолжить",
		esc_pause = "ESC — пауза",
		language = "Язык",
		keep_blue = "СИНИЙ ФОРТ",
		keep_red = "КРАСНАЯ КРЕПОСТЬ",
	},
	pt = {
		app_title = "BASTION BLAST",
		tagline = "Demolição de castelos por turnos",
		m1_badge = "M1 · LOOK-DEV",
		m1_hint = "Muralhas segmentadas, portais e desabamento chegam no M2.",
		hint_fire = "Arraste em qualquer lugar · Solte para atirar",
		footer = "Defold 1.14 · pacote de arte procedural",
		paused = "PAUSADO",
		resume_hint = "Esc para continuar",
		esc_pause = "ESC — pausa",
		language = "Idioma",
		keep_blue = "FORTE AZUL",
		keep_red = "FORTE VERMELHO",
	},
	tr = {
		app_title = "BASTION BLAST",
		tagline = "Sıra tabanlı kale yıkımı",
		m1_badge = "M1 · GÖRSEL TEST",
		m1_hint = "Bölümlü duvarlar, kapılar ve çöken katlar M2'de.",
		hint_fire = "Herhangi bir yerde sürükle · Ateş için bırak",
		footer = "Defold 1.14 · prosedürel sanat paketi",
		paused = "DURAKLATILDI",
		resume_hint = "Devam için Esc",
		esc_pause = "ESC — duraklat",
		language = "Dil",
		keep_blue = "MAVİ KALE",
		keep_red = "KIRMIZI KALE",
	},
}

local function interpolate(s, params)
	if not params then return s end
	return (s:gsub("{([%w_]+)}", function(key)
		local v = params[key]
		return v ~= nil and tostring(v) or ("{" .. key .. "}")
	end))
end

function M.t(key, params)
	local lang = D[M.current_lang] or D.en
	local s = lang[key] or D.en[key] or key
	return interpolate(s, params)
end

-- For ad-hoc localized tables: i18n.pick({ ru = "...", en = "..." })
function M.pick(tbl)
	return (tbl and (tbl[M.current_lang] or tbl.en)) or ""
end

function M.set_language(code)
	code = string.lower(code or "en")
	if not supported[code] then code = "en" end
	M.current_lang = code
	return code
end

function M.next_language()
	for i, code in ipairs(M.LANGS) do
		if code == M.current_lang then
			return M.set_language(M.LANGS[(i % #M.LANGS) + 1])
		end
	end
	return M.set_language("en")
end

function M.detect_language()
	local code = nil
	if html5 and html5.run then
		local ok, res = pcall(html5.run, "(navigator.language || navigator.userLanguage || 'en').slice(0,2)")
		if ok and type(res) == "string" and res ~= "" then
			code = res
		end
	end
	if not code and sys and sys.get_sys_info then
		local ok, info = pcall(sys.get_sys_info)
		if ok and info and info.language then
			code = info.language
		end
	end
	return M.set_language(code or "en")
end

return M
