--!strict
-- this script generates all possible positions and paths the slimes can take
-- once generated it, it will store it in server storage
-- then copy paste it into the actual game later
-- do this whenever theres a new map
-- make sure to set navgridpoints, take example from map1 (first map)

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local SlimeModule = require(ServerScriptService.ServerModules.SlimeModule)
local SlimeInfo = require(ServerScriptService.ServerModules.SlimeModule.SlimeInfo)
local NavGrid = require(ServerScriptService.ServerModules.SlimeModule.NavGrid)

local slimesFolder = ServerStorage.Slimes
local mapVisuals = workspace.mapVisuals
local currentMapFolder = workspace.CurrentMap

workspace.Gravity = 5

for _, mapFolder in pairs(ServerStorage.Maps:GetChildren()) do
	
	local map_model = mapFolder:FindFirstChildOfClass('Model')
	local mapGridFolder = mapFolder:FindFirstChild('NavGrids')
	
	local navGridPoints = map_model.NavGridPoints
	local start_pos = navGridPoints.Start.Position
	local end_pos = navGridPoints.End.Position
	local HighestPoint = navGridPoints.Configuration.HighestPoint.Value
	local LowestPoint = navGridPoints.Configuration.LowestPoint.Value
	
	map_model.Parent = currentMapFolder
	
	for _, slimeModel in pairs(slimesFolder:GetChildren()) do
		local cellSize = slimeModel.PrimaryPart.Size.Y
		
		
		local newGrid = NavGrid.new(start_pos, end_pos, cellSize , mapVisuals)
		local complete = newGrid:Generate(LowestPoint, HighestPoint)
		
		repeat task.wait() until complete
		
		local slimeGrid = mapVisuals:Clone()
		slimeGrid.Name = slimeModel.Name
		slimeGrid.Parent = mapGridFolder
		
		mapVisuals:ClearAllChildren()
		
	end
	
	map_model.Parent = mapFolder
	
end

