--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local SlimeModule = {}

local SlimeInfo = require(script.SlimeInfo)
local Slime = require(script.Slime)

local DefaultSlime = SlimeInfo["Normal Slime"] :: SlimeInfo.SlimeData

local function GetSlimeInfo(slime_name: string): SlimeInfo.SlimeData
	local slimeData = SlimeInfo[slime_name]

	if slimeData then
		return slimeData
	end

	warn("did not find slime data, returning default")
	return DefaultSlime
end

local function GetAveragePosition()
	local vec = Vector3.zero

	local allSlimeList = workspace.AllSlimes:GetChildren()

	for i, slime_model in pairs(allSlimeList) do
		if slime_model:IsA('Model') then
			local PrimaryPart = slime_model.PrimaryPart
			if PrimaryPart then
				PrimaryPart.Position += vec
			end
		end
	end

	return vec/#allSlimeList 

end

local function FindTarget()
	local rootPosition = GetAveragePosition()

	local nearest_target = nil
	local total_distance = math.huge

	for i, character_model in pairs(workspace.AllCharacters:GetChildren()) do
		if character_model:IsA('Model') then
			local PrimaryPart = character_model.PrimaryPart
			if PrimaryPart then
				local distance = (PrimaryPart.Position - rootPosition).Magnitude
				if nearest_target == nil then
					nearest_target = PrimaryPart
				end

				if total_distance > distance then
					total_distance = distance
					nearest_target = PrimaryPart
				end

			end
		end
	end

	return nearest_target
end

function SlimeModule:LoadSlime(slime_name : string)
	local SlimeData = GetSlimeInfo(slime_name)
 
	local newSlime = Slime.new(SlimeData)

	return newSlime
end

return SlimeModule