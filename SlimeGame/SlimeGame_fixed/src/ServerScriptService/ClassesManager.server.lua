local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataManager = require(ServerScriptService.Data.DataManager)

local ModuleScripts = ServerScriptService.ModuleScripts
local ClassesInfo = require(ModuleScripts.ClassesInfo)

local mClassesInfo = ModuleScripts.ClassesInfo
if not ReplicatedStorage.Modules:FindFirstChild('ClassesInfo') then
	mClassesInfo:Clone().Parent = ReplicatedStorage.Modules
end

local BuyClassRemote = ReplicatedStorage.Remotes:WaitForChild("BuyClass")

local function getClassInfoFromName(className: string)
	for _, classInfo in ipairs(ClassesInfo) do
		if classInfo.Name == className then
			return classInfo
		end
	end

	return nil
end

BuyClassRemote.OnServerEvent:Connect(function(player: Player, action: string, className: string)
	if typeof(action) ~= "string" then
		return
	end

	if typeof(className) ~= "string" then
		return
	end

	local classInfo = getClassInfoFromName(className)

	if not classInfo then
		warn("Invalid class:", className)
		return
	end

	if action == "Buy" then
		if DataManager.OwnsClass(player, className) then
			DataManager.SetEquippedClass(player, className)
			return
		end

		local gems = DataManager.GetGems(player)
		local price = classInfo.Price or 0

		if gems < price then
			warn(player.Name .. " does not have enough gems for " .. className)
			return
		end

		DataManager.RemoveGems(player, price)
		DataManager.AddOwnedClass(player, className)
		DataManager.SetEquippedClass(player, className)

	elseif action == "Equip" then
		if not DataManager.OwnsClass(player, className) then
			warn(player.Name .. " tried to equip unowned class:", className)
			return
		end

		DataManager.SetEquippedClass(player, className)
	end
end)