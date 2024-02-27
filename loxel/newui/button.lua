---@class Button:Object
local Button = Object:extend("Button")

function Button:new(x, y, width, height, text, callback)
	Button.super.new(self, x, y)

	self.width = width or 80
	self.height = height or 20

	self.text = text or "Button"
	self.font = love.graphics.getFont()
	self.font:setFilter("nearest", "nearest")

	self.hovered = false
	self.callback = callback
	self.color = {0.5, 0.5, 0.5}
    self.lineColor = {0.1, 0.1, 0.1}
    self.lineColorHovered = {0.2, 0.2, 0.2}
	self.textColor = {1, 1, 1}
end

function Button:update()
	local mx, my = game.mouse.x, game.mouse.y
	self.hovered =
		(mx >= self.x and mx <= self.x + self.width and my >= self.y and my <=
			self.y + self.height)

	if game.mouse.justPressed then
		if game.mouse.justPressedLeft then
			self:mousepressed(game.mouse.x, game.mouse.y, game.mouse.LEFT)
		elseif game.mouse.justPressedRight then
			self:mousepressed(game.mouse.x, game.mouse.y, game.mouse.RIGHT)
		elseif game.mouse.justPressedMiddle then
			self:mousepressed(game.mouse.x, game.mouse.y, game.mouse.MIDDLE)
		end
	end
end

function Button:__render(camera)
	local r, g, b, a = love.graphics.getColor()
    local lineWidth = love.graphics.getLineWidth()

	love.graphics.setColor(self.color[1], self.color[2], self.color[3],
		self.alpha)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 8, 8)

	if self.hovered then
		love.graphics.setColor(self.lineColorHovered[1], self.lineColorHovered[2],
            self.lineColorHovered[3], self.alpha)
	else
		love.graphics.setColor(self.lineColor[1], self.lineColor[2], self.lineColor[3],
		    self.alpha)
	end
    love.graphics.setLineWidth(1.5)
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 8, 8)
    love.graphics.setLineWidth(lineWidth)

	local textX = self.x + (self.width - self.font:getWidth(self.text)) / 2
	local textY = self.y + (self.height - self.font:getHeight()) / 2

	love.graphics.setColor(self.textColor[1], self.textColor[2],
		self.textColor[3], self.alpha)
	love.graphics.print(self.text, textX, textY)

	love.graphics.setColor(r, g, b, a)
end

function Button:mousepressed(x, y, button)
	if self.hovered and self.callback then self.callback() end
end

return Button