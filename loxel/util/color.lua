local Color = {
	WHITE = {1, 1, 1},
	BLACK = {0, 0, 0},
	RED = {1, 0, 0},
	GREEN = {0, 1, 0},
	BLUE = {0, 0, 1},
	PURPLE = {1, 0, 1},
	CYAN = {0, 1, 1},
	YELLOW = {1, 1, 0}
}

function Color.HSL(h, s, l)
	if s <= 0 then return l, l, l end
	h = (h / 360) * 6
	local c = (1 - math.abs(2 * l - 1)) * s
	local x = (1 - math.abs(h % 2 - 1)) * c
	local m, r, g, b = (l - .5 * c), 0, 0, 0
	if h < 1 then
		r, g, b = c, x, 0
	elseif h < 2 then
		r, g, b = x, c, 0
	elseif h < 3 then
		r, g, b = 0, c, x
	elseif h < 4 then
		r, g, b = 0, x, c
	elseif h < 5 then
		r, g, b = x, 0, c
	else
		r, g, b = c, 0, x
	end
	return r + m, g + m, b + m
end

function Color.HSLtoRGB(h, s, l)
	local C = ( 1 - math.abs( l + l - 1 ))*s
	local m = l - 0.5*C
	local r, g, b = m, m, m
	if h == h then
		local h_ = (h % 1.0) * 6.0
		local X = C * (1 - math.abs(h_ % 2 - 1))
		C, X = C + m, X + m
		if     h_ < 1 then r, g, b = C, X, m
		elseif h_ < 2 then r, g, b = X, C, m
		elseif h_ < 3 then r, g, b = m, C, X
		elseif h_ < 4 then r, g, b = m, X, C
		elseif h_ < 5 then r, g, b = X, m, C
		else               r, g, b = C, m, X
		end
	end
	return r, g, b
end

function Color.RGBtoHSL(r, g, b)
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local h, s, l = 0, 0, (max + min) / 2

	if max ~= min then
		local d = max - min
		s = l > 0.5 and d / (2 - max - min) or d / (max + min)
		if max == r then
			h = (g - b) / d + (g < b and 6 or 0)
		elseif max == g then
			h = (b - r) / d + 2
		else
			h = (r - g) / d + 4
		end
		h = h / 6
	end

	return h, s, l
end

function Color.fromHSL(...)
	return {Color.HSL(...)}
end

function Color.fromString(str)
	str = str:gsub("#", "")
	return Color.fromRGB(tonumber('0x' .. str:sub(1, 2)),
		tonumber('0x' .. str:sub(3, 4)),
		tonumber('0x' .. str:sub(5, 6)))
end

function Color.fromRGB(r, g, b)
	return {r / 255, g / 255, b / 255}
end

function Color.convert(rgb)
	return {rgb[1] / 255,
		rgb[2] / 255,
		rgb[3] / 255}
end

return Color
