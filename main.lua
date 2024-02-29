io.stdout:setvbuf("no")

require "loxel"

if love.system.getOS() == "Windows" then
	WindowDialogue = require "lib.windows.dialogue"
	WindowUtil = require "lib.windows.util"

	-- since love 12.0, windows no longer recreates for updateMode
	if love._version_major < 12 then
		local _ogUpdateMode = love.window.updateMode
		local includes = {"x", "y", "centered"}
		function love.window.updateMode(width, height, settings)
			if settings then
				for i, v in pairs(settings) do
					nuh = not table.find(includes, i) and (i ~= "fullscreen" or v ~= f)
					if nuh then
						local s = _ogUpdateMode(width, height, settings)
						WindowUtil.setDarkMode(true)
						return s
					end
				end
			end

			if love.window.getFullscreen() then return false end

			local x, y, flags = love.window.getMode()
			local centered = true
			if settings and settings.centered ~= nil then centered = settings.centered end
			if centered then
				local width2, height2 = love.window.getDesktopDimensions(flags.display)
				x, y = (width2 - width) / 2, (height2 - height) / 2
			else
				x, y = settings and settings.x or x, settings and settings.y or y
			end

			WindowUtil.setWindowPosition(x, y, width, height)
			return true
		end
	end

	local _ogSetMode = love.window.setMode
	function love.window.setMode(...)
		_ogSetMode(...)
		WindowUtil.setDarkMode(true)
	end
end

Timer = require "lib.timer"
Https = require "lib.https"

paths = require "funkin.paths"
util = require "funkin.util"

ClientPrefs = require "funkin.backend.clientprefs"
Conductor = require "funkin.backend.conductor"
Discord = require "funkin.backend.discord"
Highscore = require "funkin.backend.highscore"
Mods = require "funkin.backend.mods"
Script = require "funkin.backend.scripting.script"
ScriptsHandler = require "funkin.backend.scripting.scriptshandler"
Throttle = require "funkin.backend.throttle"

HealthIcon = require "funkin.gameplay.ui.healthicon"
Note = require "funkin.gameplay.ui.note"
NoteSplash = require "funkin.gameplay.ui.notesplash"
Receptor = require "funkin.gameplay.ui.receptor"
BackgroundDancer = require "funkin.gameplay.backgrounddancer"
BackgroundGirls = require "funkin.gameplay.backgroundgirls"
Character = require "funkin.gameplay.character"
Stage = require "funkin.gameplay.stage"
TankmenBG = require "funkin.gameplay.tankmenbg"

Alphabet = require "funkin.ui.alphabet"
MenuCharacter = require "funkin.ui.menucharacter"
MenuItem = require "funkin.ui.menuitem"
ModCard = require "funkin.ui.modcard"
Options = require "funkin.ui.options"

StatsCounter = require "funkin.ui.statscounter"
SoundTray = require "funkin.ui.soundtray"

TitleState = require "funkin.states.title"
MainMenuState = require "funkin.states.mainmenu"
ModsState = require "funkin.states.mods"
StoryMenuState = require "funkin.states.storymenu"
FreeplayState = require "funkin.states.freeplay"
PlayState = require "funkin.states.play"

EditorMenu = require "funkin.ui.editor.editormenu"

AssetsErrorSubstate = require "funkin.substates.assetserror"
GameOverSubstate = require "funkin.substates.gameover"

CharacterEditor = require "funkin.states.editors.character"
ChartingState = require "funkin.states.editors.charting"

local TransitionFade = require "loxel.transition.transitionfade"
local SplashScreen = require "funkin.states.splash"

function love.load()
	ClientPrefs.loadData()

	local res, isMobile = ClientPrefs.data.resolution, love.system.getDevice() == "Mobile"
	love.window.setTitle(Project.title)
	love.window.setIcon(love.image.newImageData(Project.icon))
	love.window.setMode(Project.width * res, Project.height * res, {
		fullscreen = isMobile or ClientPrefs.data.fullscreen,
		resizable = not isMobile,
		vsync = 0,
		usedpiscale = false
	})

	if Project.bgColor then
		love.graphics.setBackgroundColor(Project.bgColor)
	end

	Mods.loadMods()
	Highscore.load()

	local color = {0, 0, 0}
	State.defaultTransIn = TransitionFade(0.6, color, "vertical")
	State.defaultTransOut = TransitionFade(0.7, color, "vertical")

	game.onPreStateEnter = function(state)
		if paths and getmetatable(state) ~= getmetatable(game.getState()) then
			paths.clearCache()
		end
	end

	SoundTray.init(love.graphics.getDimensions())
	game:add(SoundTray)
	SoundTray.new()

	game.init(Project, (false and SplashScreen or (require "funkin.states.ui")))
	game:add(game.statsCounter)

	love.mouse.setVisible(true)

	Discord.init()
end

function love.resize(w, h) game.resize(w, h) end

function love.keypressed(key, ...)
	if Project.DEBUG_MODE and love.keyboard.isDown("lctrl", "rctrl") then
		if key == "f4" then error("force crash") end
		if key == "`" then return "restart" end
	end
	controls:onKeyPress(key, ...)
	game.keypressed(key, ...)
end

function love.keyreleased(...)
	controls:onKeyRelease(...)
	game.keyreleased(...)
end

function love.wheelmoved(...) game.wheelmoved(...) end

function love.mousemoved(...) game.mousemoved(...) end

function love.mousepressed(...) game.mousepressed(...) end

function love.mousereleased(...) game.mousereleased(...) end

function love.touchmoved(...) game.touchmoved(...) end

function love.touchpressed(...) game.touchpressed(...) end

function love.touchreleased(...) game.touchreleased(...) end

function love.textinput(text) game.textinput(text) end

function love.update(dt)
	controls:update()

	Throttle:update(dt)
	Timer.update(dt)
	game.update(dt)

	if love.system.getDevice() == "Desktop" then Discord.update() end
	if controls:pressed("fullscreen") then love.window.setFullscreen(not love.window.getFullscreen()) end
end

function love.draw()
	game.draw()
end

function love.focus(f) game.focus(f) end

function love.fullscreen(f, t)
	ClientPrefs.data.fullscreen = f
	game.fullscreen(f)
end

function love.quit()
	ClientPrefs.saveData()
	game.quit()
	Discord.shutdown()
end

local function error_printer(msg, layer)
	print((debug.traceback("Error: " .. tostring(msg), 1 + (layer or 1)):gsub("\n[^\n]+$", "")))
end
function love.errorhandler(msg)
	love.errorhandler_quit()

	msg = tostring(msg)
	error_printer(msg, 2)

	if not love.window or not love.graphics or not love.event then return end

	if not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then return end
	end

	local trace = debug.traceback()

	if utf8 == nil then utf8 = require("utf8") end

	local sanitizedmsg, err = {}, {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)

	table.insert(err, sanitizedmsg)
	if #sanitizedmsg ~= #msg then
		table.insert(err, "Invalid UTF-8 string in error message.")
	end

	table.insert(err, "\n")

	for l in trace:gmatch("(.-)\n") do
		l = l:gsub("stack traceback:", "Traceback\n")
		table.insert(err, l)
	end

	local p = table.concat(err, "\n"):gsub("\t", ""):gsub("%[string \"(.-)\"%]", "%1")
	local fullErrorText = p

	love.graphics.reset()
	love.graphics.setCanvas()
	love.graphics.setColor(1, 1, 1)
	love.graphics.origin()

	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		if love.mouse.isCursorSupported() then love.mouse.setCursor() end
	end
	if love.joystick then
		for i, v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.window then
		love.window.setFullscreen(false)
		love.window.setDisplaySleepEnabled(true)
	end
	if love.audio then love.audio.stop() end
	if love.handlers then love.handlers = nil end

	collectgarbage()
	collectgarbage()

	if love.system then
		p = p .. "\n\nPress Ctrl+C or tap to copy this error"
	end
	p = p .. "\nPress ESC to quit"
	p = p .. "\nPress Ctrl+R to restart"

	local menuDesat, funkinLogo, fnfFont18, fnfFont20
	local bgMusic, missSfx

	function firstPass()
		menuDesat = paths.getImage("menus/menuDesat")
		funkinLogo = paths.getImage("menus/splashscreen/FNFLOVE_logo")
		fnfFont18 = paths.getFont("phantommuff.ttf", 18) or love.graphics.setNewFont(18)
		fnfFont20 = paths.getFont("phantommuff.ttf", 35) or love.graphics.setNewFont(35)

		bgMusic = paths.getMusic("pause/railways", "static")
		missSfx = love.audio.newSource(paths.getSound("gameplay/missnote" .. love.math.random(1, 3)), "static")

		bgMusic:setLooping(true)
		bgMusic:setVolume(0.7)
		bgMusic:play()

		missSfx:setVolume(0.4)
		missSfx:play()
	end

	local dontDraw = false
	local __error__, __center__, focused = "[ ERROR ]", "center"
	local scale1, scale2, gameW, gameH, hgameW, hgameH, retval
	local menuDesatW, menuDesatH, funkinLogoW, funkinLogoH
	local function draw(force)
		if not force and dontDraw then return end

		love.graphics.clear(0, 0, 0)

		hgameW, hgameH = gameW / 2, gameH / 2
		menuDesatW, menuDesatH = menuDesat:getWidth(), menuDesat:getHeight()
		funkinLogoW, funkinLogoH = funkinLogo:getWidth(), funkinLogo:getHeight()

		scale1 = math.max(gameW / menuDesatW, gameH / menuDesatH)
		scale2 = math.max(math.min(gameW, 1600) / funkinLogoW, math.min(gameH, 900) / funkinLogoH) * 0.7

		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.draw(menuDesat, hgameW, hgameH, 0, scale1, scale1, menuDesatW / 2, menuDesatH / 2)
		love.graphics.draw(funkinLogo, hgameW, hgameH, 0, scale2, scale2, funkinLogoW / 2, funkinLogoH / 2)

		love.graphics.setColor(1, 1, 1)

		love.graphics.setFont(fnfFont20)
		love.graphics.printf(__error__, 40, 40, love.graphics.getWidth() - 80, __center__)

		love.graphics.setFont(fnfFont18)
		love.graphics.printf(p, 40, 110, love.graphics.getWidth() - 80, __center__)

		love.graphics.present()
	end

	local function copyToClipboard()
		love.system.setClipboardText(fullErrorText)
		p = p .. "\nCopied to clipboard!"
		draw()
	end

	eventhandlers = {
		quit = function()
			return 1
		end,
		keypressed = function(key)
			if key == "escape" then return 1 end
			if not love.keyboard.isDown("lctrl", "rctrl") then return end
			if love.system and key == "c" then
				copyToClipboard()
			elseif key == "r" then
				return "restart"
			end
		end,
		touchpressed = function()
			local name = love.window.getTitle()
			if #name == 0 or name == "Untitled" then name = "Game" end

			local buttons = {"OK", "Cancel", "Restart"}
			if love.system then buttons[4] = "Copy to clipboard" end

			local pressed = love.window.showMessageBox("Quit " .. name .. "?", "", buttons)
			if pressed == 1 then
				return 1
			elseif pressed == 3 then
				return "restart"
			elseif pressed == 4 then
				copyToClipboard()
			end
		end,
		focus = function(f)
			bgMusic:setVolume(f and 0.7 or 0.3)
		end,
		resize = function(w, h)
			gameW, gameH = w, h
			draw()
		end,
		displayrotated = function(force)
			gameW, gameH = love.graphics.getDimensions()
			draw(force)
		end
	}

	local __step__, name, a, b = "step"
	if love.system.getDevice() == "Mobile" then
		dontDraw = true

		local first, done = true, false
		return function()
			if first then
				first = false
				return
			end

			love.event.pump()
			for name, a in love.event.poll() do
				if eventhandlers[name] ~= nil then
					retval = eventhandlers[name](a)
					if retval then return retval end
				end
			end

			if not done then
				firstPass()
			end
			eventhandlers.displayrotated(true)

			done = true
			collectgarbage(__step__)
			sleep(0.1)
		end
	end

	firstPass()
	eventhandlers.displayrotated(true)

	return function()
		name, a, b = love.event.wait()
		if eventhandlers[name] ~= nil then
			collectgarbage(__step__)
			retval = (eventhandlers[name])(a, b)
			if retval then return retval end
		end
	end
end
