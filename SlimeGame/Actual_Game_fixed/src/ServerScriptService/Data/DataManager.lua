local DataManager = {}

-- Store profiles from ProfileStore
DataManager.Profiles = {}

-- Add Gems
function DataManager.AddGems(player : Player, amount : number)
	local profile = DataManager.Profiles[player]
	if not profile then return end

	amount = math.abs(amount)

	profile.Data.Gems += amount

	if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Gems") then
		player.leaderstats.Gems.Value = profile.Data.Gems
	end

	-- fire tell player
end

-- Remove Gems
function DataManager.RemoveGems(player : Player, amount : number)
	local profile = DataManager.Profiles[player]
	if not profile then return end

	amount = math.abs(amount)

	profile.Data.Gems -= amount

	-- prevent going below 0
	if profile.Data.Gems < 0 then
		profile.Data.Gems = 0
	end

	if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Gems") then
		player.leaderstats.Gems.Value = profile.Data.Gems
	end

	-- fire tell player
end

-- Get Gems
function DataManager.GetGems(player : Player)
	local profile = DataManager.Profiles[player]
	if not profile then return 0 end

	return profile.Data.Gems
end

return DataManager