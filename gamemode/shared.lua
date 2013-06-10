--[[
	Ovias
	Copyright © Slidefuse LLC - 2012
--]]

GM.Name			= "Ovias"
GM.Author		= "Slidefuse LLC"
GM.Email 		= "spencer@sf-n.com"
GM.Website 		= "slidefuse.com"

SF = {}
SF.CLASSES = {}

SF.TEAM_CONNECTED = 2
SF.TEAM_SPEC = 1
SF.TEAM_JOINING = 0

include("netstream.lua")

function file.FindDir(path, mode)
	local f, d = file.Find(path, mode)
	return d
end

// Name: Creating Teams Function
// Description: To create teams that will run smoothly with the gamemode.

function GM:CreateTeams()
	team.SetUp(SF.TEAM_CONNECTED, "Connected", Color(200, 0, 200, 255))

	team.SetUp(SF.TEAM_JOINING, "Joining", Color(20, 20, 20, 255))
	team.SetSpawnPoint(SF.TEAM_JOINING, "info_player_counterterrorist")
end


// Name: Get Game Description
// Description: A function used to return the description in a later date.

function GM:GetGameDescription()
	return "Ovias"
end

function GM:GetGamemodeDescription()
	return self:GetGameDescription()
end

// Name: Start of the SF Classes.
// Description: n/a

function SF:Msg(s, t)
	s = tostring(s)
	
	if (!t) then
		s = s.."\n"
		Msg(s)
		return
	end

	for i = 1, t do
		s = "\t"..s
	end
	s = s.."\n"
	Msg(s)
end

function SF:Print(s)
	print(s)
end

local oldHook = hook.Call
function hook.Call(name, gamemode, ...)
	if (CLIENT) then
		SF.Client = LocalPlayer()
	end
	local returnvalue = true
	for _, v in next, SF.CLASSES do
		if (v[name]) then
			returnvalue = v[name](v, ...)
		end
		if (v["HookCall"]) then
			returnvalue = v:HookCall(name, gamemode, ...)
		end
	end

	if (returnvalue) then
		returnvalue = oldHook(name, gamemode, ...)
	end

	return returnvalue
end

function SF:Call(name, ...)
	return hook.Call(name, self, ...)
end

function SF:RandomString(length, sHaystack)
	local haystack = sHaystack or "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
	local returnval = ""
	for i = 1, length do
		returnval = returnval..haystack[math.random(1, string.len(haystack))]
	end
	return returnval
end

function SF:RegisterClass(s, t)
	if (!self.CLASSES[s]) then
		self.CLASSES[s] = t
		self:Msg("Registering Class: "..s, 3)
	end
end

function SF:GetSides()
	if(SERVER) then
		return {"sh_", "sv_"}
	else
		return {"sh_", "cl_"}
	end
end

function SF:Include(Dir, File)
	include(Dir.."/"..File)
end

function SF:IncludeCS(Dir, Prefix)
	local Prefix = Prefix or ""
	self:Msg("Adding Client Folder: ["..self.LoaderDir.."/"..Dir.."]", 1)
	for k, File in pairs(file.Find(self.LoaderDir.."/"..Dir.."/cl_*.lua", "LUA")) do
		self:Msg("Found Client File: "..File, 2)
		AddCSLuaFile(Prefix..Dir.."/"..File)
	end

	for k, File in pairs(file.Find(self.LoaderDir.."/"..Dir.."/sh_*.lua", "LUA")) do
		self:Msg("Found Shared File: "..File, 2)
		AddCSLuaFile(Prefix..Dir.."/"..File)
	end
end

function SF:IncludeDirectoryRecursive(Dir, Prefix)
    local Prefix = Prefix or ""
    for k, v in pairs(file.FindDir(self.LoaderDir.."/"..Dir.."/*", "LUA")) do
        local File = Dir.."/"..v
		self:IncludeDirectoryRecursive(File)
	end

    self:IncludeDirectory(Dir, Prefix)
end

function SF:IncludeDirectory(Dir, Prefix)
	local Prefix = Prefix or ""
	if (SERVER) then
		self:IncludeCS(Dir, Prefix)
	end

	for k, side in pairs(self:GetSides()) do
		self:Msg("Loading Side: "..side.." ["..self.LoaderDir.."/"..Dir.."/"..side.."*.lua]", 1)
		for k, File in pairs(file.Find(self.LoaderDir.."/"..Dir.."/"..side.."*.lua", "LUA")) do
			self:Msg("Found File: "..File, 2)
			self:Include(Dir, File)
		end
	end
end

function SF:IncludeDirectoryRel(Search, Include, t, hide)
	local hide = hide or false
	local t = t or 1

	if (hide) then self:Msg("Adding Client Folder: ["..self.LoaderDir.."/"..Search.."]", t) end
	for k, File in pairs(file.Find(self.LoaderDir.."/"..Search.."/cl_*.lua", "LUA")) do
		if (hide) then self:Msg("Found Client File: "..File, t+1) end
		AddCSLuaFile(Include.."/"..File)
	end

	for k, File in pairs(file.Find(self.LoaderDir.."/"..Search.."/sh_*.lua", "LUA")) do
		if (hide) then self:Msg("Found Shared File: "..File, t+1) end
		AddCSLuaFile(Include.."/"..File)
	end

	for k, side in pairs(self:GetSides()) do
		if (hide) then self:Msg("Loading Side: "..side.." ["..self.LoaderDir.."/"..Search.."/"..side.."*.lua]", t) end
		for k, File in pairs(file.Find(self.LoaderDir.."/"..Search.."/"..side.."*.lua", "LUA")) do
			if (hide) then self:Msg("Found File: "..File, t+1) end
			self:Include(Include, File)
		end
	end
end

function SF:AddResourceDirectory(Dir)
	local FoundDir = false
 	for k, v in pairs(file.FindDir(self.ResourceDir.."/"..Dir.."/*", "MOD")) do
		local File = Dir.."/"..v
		self:AddResourceDirectory(File)
	end

	for k, v in pairs(file.Find(self.ResourceDir.."/"..Dir.."/*", "MOD")) do
		if (!string.find(v, ".bz2", 1, true) and !string.find(v, ".bat", 1, true)) then
			local File = Dir.."/"..v
			resource.AddFile(File)
		end
 	end
end

SF.PlayerMeta = FindMetaTable("Player")
SF.EntityMeta = FindMetaTable("Entity")

function SF:Init(Dir)
	if(SERVER) then
		self.LoaderDir = Dir.."/gamemode"
	else
		self.LoaderDir = Dir.."/gamemode"
	end
	
	self.ResourceDir = "gamemodes/"..Dir.."/content"

	self:Msg("###############################################")
	self:Msg("# "..GM.Name.." by "..GM.Author.." ("..GM.Email..")")
	
	if(SERVER) then
		self:Msg("# Sending Resources to Client Buffer")
		self:AddResourceDirectory("sound")
		self:AddResourceDirectory("models")
		self:AddResourceDirectory("materials")
		self:AddResourceDirectory("resources")
	end
	
	self:Msg("# Loading LUA Files")
	self:IncludeRecursiveDirectory("classes")
	self:IncludeDirectory("vgui")

	self:Msg("Setting up NetHooks", 1)
	self:Call("SetupNetHooks")
	self:Msg("###############################################")
end

SF:Init("ovias")
