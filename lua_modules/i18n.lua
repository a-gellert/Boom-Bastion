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
		m0_badge = "M0 · SKELETON BUILD",
		m0_hint = "Real combat arrives in M2: Pull & Release, crumbling walls, x2 gates.",
		footer = "Defold 1.14 · 1280×720 · no game dependencies",
		paused = "PAUSED",
		resume_hint = "Press Esc to resume",
		esc_pause = "ESC — pause",
		language = "Language",
	},
	ru = {
		app_title = "BASTION BLAST",
		tagline = "Пошаговое разрушение замков",
		m0_badge = "M0 · КАРКАС",
		m0_hint = "Настоящий бой будет в M2: Pull & Release, пробоины в стенах, ворота x2.",
		footer = "Defold 1.14 · 1280×720 · без внешних зависимостей",
		paused = "ПАУЗА",
		resume_hint = "Esc — продолжить",
		esc_pause = "ESC — пауза",
		language = "Язык",
	},
	pt = {
		app_title = "BASTION BLAST",
		tagline = "Demolição de castelos por turnos",
		m0_badge = "M0 · ESQUELETO",
		m0_hint = "O combate real chega no M2: Pull & Release, muralhas a ruir, portais x2.",
		footer = "Defold 1.14 · 1280×720 · sem dependências de jogo",
		paused = "PAUSADO",
		resume_hint = "Esc para continuar",
		esc_pause = "ESC — pausa",
		language = "Idioma",
	},
	tr = {
		app_title = "BASTION BLAST",
		tagline = "Sıra tabanlı kale yıkımı",
		m0_badge = "M0 · İSKELET",
		m0_hint = "Gerçek savaş M2'de: Pull & Release, yıkılan duvarlar, x2 kapıları.",
		footer = "Defold 1.14 · 1280×720 · oyun bağımlılığı yok",
		paused = "DURAKLATILDI",
		resume_hint = "Devam için Esc",
		esc_pause = "ESC — duraklat",
		language = "Dil",
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
