-- lua_modules/biomes_db.lua
-- Six arena palettes. The arena sprites are retinted on every level start.

local M = {}

local function c(r, g, b, a) return vmath.vector4(r, g, b, a or 1) end

M.LIST = {
	meadow = {
		name = "MEADOW",
		sky_top = c(0.56, 0.72, 0.91), sky_bottom = c(1.0, 0.85, 0.66),
		haze = c(1.0, 0.70, 0.38, 0.32), sun = c(1.0, 0.89, 0.64),
		hills_back = c(0.74, 0.82, 0.90, 0.55), hills_far = c(0.62, 0.73, 0.84),
		hills_near = c(0.42, 0.66, 0.34), grass = c(0.50, 0.75, 0.25), grass_top = c(0.36, 0.60, 0.16),
	},
	desert = {
		name = "DUNES",
		sky_top = c(0.95, 0.76, 0.52), sky_bottom = c(0.98, 0.55, 0.34),
		haze = c(1.0, 0.55, 0.22, 0.40), sun = c(1.0, 0.82, 0.45),
		hills_back = c(0.88, 0.70, 0.52, 0.55), hills_far = c(0.78, 0.53, 0.33),
		hills_near = c(0.60, 0.38, 0.22), grass = c(0.85, 0.64, 0.34), grass_top = c(0.70, 0.48, 0.22),
	},
	frost = {
		name = "FROST",
		sky_top = c(0.66, 0.83, 0.95), sky_bottom = c(0.91, 0.96, 1.0),
		haze = c(0.75, 0.89, 1.0, 0.30), sun = c(1.0, 0.95, 0.82),
		hills_back = c(0.86, 0.92, 0.97, 0.60), hills_far = c(0.72, 0.81, 0.90),
		hills_near = c(0.56, 0.70, 0.82), grass = c(0.91, 0.96, 1.0), grass_top = c(0.72, 0.81, 0.90),
	},
	volcano = {
		name = "CALDERA",
		sky_top = c(0.23, 0.16, 0.29), sky_bottom = c(0.76, 0.27, 0.16),
		haze = c(1.0, 0.42, 0.16, 0.40), sun = c(1.0, 0.55, 0.22),
		hills_back = c(0.42, 0.23, 0.29, 0.60), hills_far = c(0.29, 0.16, 0.22),
		hills_near = c(0.16, 0.10, 0.14), grass = c(0.23, 0.16, 0.16), grass_top = c(0.35, 0.16, 0.10),
	},
	sky = {
		name = "SKY",
		sky_top = c(0.50, 0.72, 1.0), sky_bottom = c(0.84, 0.94, 1.0),
		haze = c(1, 1, 1, 0.28), sun = c(1.0, 0.95, 0.82),
		hills_back = c(0.80, 0.90, 1.0, 0.50), hills_far = c(0.66, 0.83, 0.95),
		hills_near = c(0.50, 0.72, 0.91), grass = c(0.63, 0.85, 1.0), grass_top = c(0.44, 0.72, 0.91),
	},
	night = {
		name = "NIGHT",
		sky_top = c(0.10, 0.14, 0.25), sky_bottom = c(0.23, 0.29, 0.48),
		haze = c(0.42, 0.48, 0.69, 0.30), sun = c(0.91, 0.94, 1.0),
		hills_back = c(0.16, 0.21, 0.31, 0.60), hills_far = c(0.13, 0.16, 0.24),
		hills_near = c(0.08, 0.11, 0.16), grass = c(0.13, 0.19, 0.29), grass_top = c(0.18, 0.25, 0.35),
	},
}

function M.get(id)
	return M.LIST[id] or M.LIST.meadow
end

return M
