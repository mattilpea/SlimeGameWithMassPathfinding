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

function DataManager.OwnsClass(player: Player, className: string)
	local profile = DataManager.Profiles[player]
	if not profile then return false end

	for _, ownedClass in ipairs(profile.Data.OwnedClasses) do
		if ownedClass == className then
			return true
		end
	end

	return false
end

function DataManager.AddOwnedClass(player: Player, className: string)
	local profile = DataManager.Profiles[player]
	if not profile then return false end

	if DataManager.OwnsClass(player, className) then
		return false
	end

	table.insert(profile.Data.OwnedClasses, className)

	local ownedClassesFolder = player:FindFirstChild("OwnedClasses")
	if ownedClassesFolder then
		local classValue = Instance.new("StringValue")
		classValue.Name = className
		classValue.Value = className
		classValue.Parent = ownedClassesFolder
	end

	return true
end

function DataManager.SetEquippedClass(player: Player, className: string)
	local profile = DataManager.Profiles[player]
	if not profile then return false end

	if not DataManager.OwnsClass(player, className) then
		return false
	end

	profile.Data.SelectedClass = className

	local equippedClassValue = player:FindFirstChild("EquippedClass")
	if equippedClassValue then
		equippedClassValue.Value = className
	end

	return true
end

return DataManager