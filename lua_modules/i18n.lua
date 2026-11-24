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
		battle_start = "BATTLE ON",
		your_turn = "YOUR TURN",
		enemy_turn = "ENEMY TURN",
		victory = "VICTORY!",
		defeat = "DEFEAT",
		retry = "RETRY",
		next = "NEXT",
		perks_title = "CHOOSE A PERK",
		meta_title = "UPGRADES",
		meta_fortify = "WALL FORTIFY",
		meta_power = "POWER",
		meta_vitality = "VITALITY",
		meta_buy = "BUY",
		meta_close = "CLOSE",
		meta_lv = "LV {n}",
		meta_gold = "GOLD",
		gold = "GOLD",
		level = "LEVEL",
		sfx_on = "SFX: ON",
		sfx_off = "SFX: OFF",
		music_on = "MUSIC: ON",
		music_off = "MUSIC: OFF",
		new_run = "NEW RUN",
		p1_turn = "PLAYER 1",
		p2_turn = "PLAYER 2",
		p1_wins = "PLAYER 1 WINS",
		p2_wins = "PLAYER 2 WINS",
		campaign_complete = "CAMPAIGN COMPLETE",
		hint_aim = "Pull back · Release to fire",
		hint_enemy = "Enemy is aiming...",
		comic_boom = "BOOM!",
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
		battle_start = "БОЙ!",
		your_turn = "ТВОЙ ХОД",
		enemy_turn = "ХОД ВРАГА",
		victory = "ПОБЕДА!",
		defeat = "ПОРАЖЕНИЕ",
		retry = "ЗАНОВО",
		next = "ДАЛЬШЕ",
		perks_title = "ВЫБЕРИ ПЕРК",
		meta_title = "УЛУЧШЕНИЯ",
		meta_fortify = "УКРЕПЛЕНИЕ СТЕН",
		meta_power = "МОЩЬ",
		meta_vitality = "ЖИВУЧЕСТЬ",
		meta_buy = "КУПИТЬ",
		meta_close = "ЗАКРЫТЬ",
		meta_lv = "УР. {n}",
		meta_gold = "ЗОЛОТО",
		gold = "ЗОЛОТО",
		level = "УРОВЕНЬ",
		sfx_on = "ЗВУК: ВКЛ",
		sfx_off = "ЗВУК: ВЫКЛ",
		music_on = "МУЗЫКА: ВКЛ",
		music_off = "МУЗЫКА: ВЫКЛ",
		new_run = "НОВЫЙ ЗАБЕГ",
		p1_turn = "ИГРОК 1",
		p2_turn = "ИГРОК 2",
		p1_wins = "ПОБЕДА ИГРОКА 1",
		p2_wins = "ПОБЕДА ИГРОКА 2",
		campaign_complete = "КАМПАНИЯ ПРОЙДЕНА",
		hint_aim = "Оттяни · Отпусти, чтобы выстрелить",
		hint_enemy = "Враг целится...",
		comic_boom = "БАХ!",
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
		battle_start = "BATALHA!",
		your_turn = "SEU TURNO",
		enemy_turn = "TURNO INIMIGO",
		victory = "VITÓRIA!",
		defeat = "DERROTA",
		retry = "TENTAR DE NOVO",
		next = "PRÓXIMO",
		perks_title = "ESCOLHA UM PERK",
		meta_title = "MELHORIAS",
		meta_fortify = "FORTALECER MUROS",
		meta_power = "PODER",
		meta_vitality = "VITALIDADE",
		meta_buy = "COMPRAR",
		meta_close = "FECHAR",
		meta_lv = "NÍVEL {n}",
		meta_gold = "OURO",
		gold = "OURO",
		level = "NÍVEL",
		sfx_on = "SFX: SIM",
		sfx_off = "SFX: NÃO",
		music_on = "MÚSICA: SIM",
		music_off = "MÚSICA: NÃO",
		new_run = "NOVA JORNADA",
		p1_turn = "JOGADOR 1",
		p2_turn = "JOGADOR 2",
		p1_wins = "JOGADOR 1 VENCE",
		p2_wins = "JOGADOR 2 VENCE",
		campaign_complete = "CAMPANHA CONCLUÍDA",
		hint_aim = "Puxe para trás · Solte para atirar",
		hint_enemy = "O inimigo está mirando...",
		comic_boom = "BUM!",
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
		battle_start = "SAVAŞ!",
		your_turn = "SENİN SIRAN",
		enemy_turn = "DÜŞMAN SIRASI",
		victory = "ZAFER!",
		defeat = "YENİLGİ",
		retry = "TEKRAR",
		next = "SONRAKİ",
		perks_title = "BİR PERK SEÇ",
		meta_title = "GELİŞTİRMELER",
		meta_fortify = "DUVAR GÜÇLENDİRME",
		meta_power = "GÜÇ",
		meta_vitality = "DAYANIKLILIK",
		meta_buy = "SATIN AL",
		meta_close = "KAPAT",
		meta_lv = "SV {n}",
		meta_gold = "ALTIN",
		gold = "ALTIN",
		level = "SEVİYE",
		sfx_on = "SES: AÇIK",
		sfx_off = "SES: KAPALI",
		music_on = "MÜZİK: AÇIK",
		music_off = "MÜZİK: KAPALI",
		new_run = "YENİ TUR",
		p1_turn = "OYUNCU 1",
		p2_turn = "OYUNCU 2",
		p1_wins = "OYUNCU 1 KAZANDI",
		p2_wins = "OYUNCU 2 KAZANDI",
		campaign_complete = "KAMPANYA TAMAMLANDI",
		hint_aim = "Geri çek · Ateş için bırak",
		hint_enemy = "Düşman nişan alıyor...",
		comic_boom = "GÜM!",
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
