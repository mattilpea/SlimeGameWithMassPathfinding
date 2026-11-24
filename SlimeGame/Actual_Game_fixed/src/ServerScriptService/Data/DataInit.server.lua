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
	--Leaderstats
	local leaderstats = Instance.new('Folder')
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
		
	local credits = Instance.new('IntValue')
	credits.Name = "Credits"
	credits.Value = 0
	credits.Parent = leaderstats
		
	local plrData = Instance.new('Folder')
	plrData.Name = "plrData"
	plrData.Parent = player
	
	local strValue = Instance.new('StringValue')
	strValue.Name = "EquippedClass"
	strValue.Value = profile.Data.SelectedClass or "Starter Class"
	strValue.Parent = plrData
	
	local Dead = Instance.new('BoolValue')
	Dead.Name = "Dead"
	Dead.Value = false
	Dead.Parent = plrData
	
	--yes, shut up, idc
	local SelectedTier1 = Instance.new("StringValue")
	local SelectedTier2 = Instance.new('StringValue')
	local SelectedTier3 = Instance.new('StringValue')
	local SelectedTier4 = Instance.new('StringValue') 
	
	SelectedTier1.Name = "SelectedTier1"
	SelectedTier2.Name = "SelectedTier2"
	SelectedTier3.Name = "SelectedTier3"
	SelectedTier4.Name = "SelectedTier4"
	
	SelectedTier1.Value = profile.Data.SelectedTier1 or "Basic Wood Sword"
	SelectedTier2.Value = profile.Data.SelectedTier2 or "Fireball Wand"
	SelectedTier3.Value = profile.Data.SelectedTier3 or "Claymore"
	SelectedTier4.Value = profile.Data.SelectedTier4 or "Magic Slasher"
	
	SelectedTier1.Parent = plrData
	SelectedTier2.Parent = plrData
	SelectedTier3.Parent = plrData
	SelectedTier4.Parent = plrData
	
	
	print(player.Name.." has "..tostring(profile.Data.Gems).." gems!")
	
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
	
	local leaderstats = player:FindFirstChild('leaderstats')
	local credits = leaderstats:FindFirstChild('Credits') :: IntValue
	
	DataManager.AddGems(player, (math.round(credits.Value/2)))
	print(player.Name.." has "..tostring(profile.Data.Gems).." gems!")
	
	profile:EndSession()
	DataManager.Profiles[player] = nil
end)