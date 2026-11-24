--!strict

local WeaponsInfo = require(script.WeaponsInfo)
local WeaponTool = require(script.Tool)

local WeaponsModule = {}

function WeaponsModule:GetInfo(name: string)
	for _, weapon in pairs(WeaponsInfo) do
		if weapon.Name == name then
			return weapon
		end
	end
	return nil
end

function WeaponsModule:IsSelected(player: Player, weaponName: string): boolean
	local playerData = player:FindFirstChild("plrData")
	if not playerData then return false end

	for _, selectedWeapon in ipairs(playerData:GetChildren()) do
		if selectedWeapon:IsA("StringValue")
			and selectedWeapon.Name:match("^SelectedTier%d+$")
			and selectedWeapon.Value == weaponName then
			return true
		end
	end
	return false
end

local function ensureStarterGearCopy(player: Player, tool: Tool)
	local starterGear = player:FindFirstChild("StarterGear")
	if starterGear and not starterGear:FindFirstChild(tool.Name) then
		tool:Clone().Parent = starterGear
	end
end

function WeaponsModule:LoadTool(weaponName: string, player: Player): Tool?
	local info = self:GetInfo(weaponName)
	if not info then
		warn("WeaponInfo not found:", weaponName)
		return nil
	end
	if not info.Tool then
		warn("Tool model not found for weapon:", weaponName)
		return nil
	end
	if not self:IsSelected(player, weaponName) then
		return nil
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return nil end

	local existing = backpack:FindFirstChild(weaponName)
		or (player.Character and player.Character:FindFirstChild(weaponName))
	if existing and existing:IsA("Tool") then
		ensureStarterGearCopy(player, existing)
		return existing
	end

	local weapon = WeaponTool.new(info)
	weapon.Tool.Parent = backpack
	ensureStarterGearCopy(player, weapon.Tool)
	return weapon.Tool
end

function WeaponsModule:LoadSelectedTools(player: Player)
	local playerData = player:WaitForChild("plrData", 15)
	if not playerData then return end

	for _, selectedWeapon in ipairs(playerData:GetChildren()) do
		if selectedWeapon:IsA("StringValue") and selectedWeapon.Name:match("^SelectedTier%d+$") then
			self:LoadTool(selectedWeapon.Value, player)
		end
	end
end

return WeaponsModule