--for copy naming weapons

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local weaponsClone = ServerStorage.Weapons:Clone()

for _, weapon in pairs(weaponsClone:GetChildren()) do
	weapon:ClearAllChildren()
end

weaponsClone.Parent = ReplicatedStorage