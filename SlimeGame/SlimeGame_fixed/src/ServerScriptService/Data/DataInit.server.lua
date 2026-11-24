--//Services 

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

--ProfileStore 
local ProfileStore = require(ServerScriptService.Libraries.ProfileStore)

local function GetStoreName()
	return RunService:IsStudio() and "Test" or "Live"
end

local Template = require(ServerScriptService.Data.Template)
local DataManager = require(ServerScriptService.Data.DataManager)

--Access profile store
local PlayerStore = ProfileStore.New(GetStoreName(), Template )

local function Intitialize(player: Player, profile: typeof(PlayerStore:StartSessionAsync()))
	-- Leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local Gems = Instance.new("IntValue")
	Gems.Name = "Gems"
	Gems.Value = profile.Data.Gems
	Gems.Parent = leaderstats

	leaderstats.Parent = player

	-- Owned Classes folder
	local ownedClassesFolder = Instance.new("Folder")
	ownedClassesFolder.Name = "OwnedClasses"
	ownedClassesFolder.Parent = player

	for _, className in ipairs(profile.Data.OwnedClasses) do
		local classValue = Instance.new("StringValue")
		classValue.Name = className
		classValue.Value = className
		classValue.Parent = ownedClassesFolder
	end

	-- Equipped class value
	local equippedClass = Instance.new("StringValue")
	equippedClass.Name = "EquippedClass"
	equippedClass.Parent = player

	local selectedClass = profile.Data.SelectedClass
	local ownsSelectedClass = false

	for _, ownedClassName in ipairs(profile.Data.OwnedClasses) do
		if ownedClassName == selectedClass then
			ownsSelectedClass = true
			break
		end
	end

	if ownsSelectedClass then
		equippedClass.Value = selectedClass
	else
		local fallbackClass = profile.Data.OwnedClasses[1] or "Starter Class"

		equippedClass.Value = fallbackClass
		profile.Data.SelectedClass = fallbackClass
	end
end

---creates and stores a profile
local function PlayerAdded(player : Player)
	--Start a new profile session
	local key = "Player_" .. tostring(player.UserId)
	local profile = PlayerStore:StartSessionAsync(key,{
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	--Sanity check to ensure profile exists
	if profile ~= nil then
		profile:AddUserId(player.UserId) --GDPR compliance to be able to remove later if required
		profile:Reconcile()
		
		
		--Handles session locking
		profile.OnSessionEnd:Connect(function()
			DataManager.Profiles[player] = nil
			player:Kick("Data error occured. Please rejoin.")
		end)
		
		
		--save profile for later use
		if player.Parent == Players then
			DataManager.Profiles[player] = profile
			Intitialize(player, profile)
		else
			profile:EndSession()
			
		end
		
		
	else
		--Server shuts down while player is joining (highly NOT likely to happen)
		player:Kick("Data error occured. Please rejoin.	")
		
		
	end
	
	
	
end

for _, player in Players:GetPlayers() do
	task.spawn(PlayerAdded, player)
end


Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	profile:EndSession()
	DataManager.Profiles[player] = nil
end)