local decodeJSON = (require "lib.json").decode

local Mods = {
	root = "mods",
	mods = {},
	currentMod = nil
}
if love.filesystem.isFused() and love.system.getDevice() == "Desktop" and love.filesystem.mount(love.filesystem.getSourceBaseDirectory(), "root") then
	Mods.root = "root/" .. Mods.root
end

function Mods.getBanner(mods)
	local loadedBanner = nil
	local banner = Mods.root .. "/" .. mods .. "/banner.png"
	local obj = paths.images[banner]
	if obj then loadedBanner = obj end
	if paths.exists(banner, "file") then
		obj = love.graphics.newImage(banner)
		paths.images[banner] = obj
		loadedBanner = obj
	else
		local emptyBanner = paths.getPath("images/menus/modsEmptyBanner.png")
		obj = paths.images[emptyBanner]
		if obj then loadedBanner = obj end
		if paths.exists(emptyBanner, "file") then
			obj = love.graphics.newImage(emptyBanner)
			paths.images[emptyBanner] = obj
			loadedBanner = obj
		end
	end
	return loadedBanner
end

function Mods.getMetadata(mod)
  local path = Mods.root .. "/" .. mod .. "/meta.json"
  if paths.exists(Mods.root, "directory") and paths.exists(path, "file") then
		return decodeJSON(path)
	end
	return {
		name = mod,
		color = "#1F1F1F",
		description = "No description provided.",
		version = 1
	}
end

function Mods.loadMods()
	Mods.mods = {}
	if not paths.exists(Mods.root, "directory") then return end

	for _, dir in ipairs(love.filesystem.getDirectoryItems(Mods.root)) do
		if love.filesystem.getInfo(Mods.root .. "/" .. dir, "directory") ~= nil then
			table.insert(Mods.mods, dir)
		end
	end

	if game.save.data.currentMod then
		Mods.currentMod = game.save.data.currentMod
		if table.find(Mods.mods, Mods.currentMod) then
			Mods.currentMod = game.save.data.currentMod
		else
			Mods.currentMod = nil
			game.save.data.currentMod = Mods.currentMod
		end
	end
end

return Mods
