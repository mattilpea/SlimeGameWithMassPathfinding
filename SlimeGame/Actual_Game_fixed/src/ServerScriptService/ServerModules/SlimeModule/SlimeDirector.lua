--!strict

local RunService = game:GetService("RunService")

local SlimeManager = require(script.Parent.SlimeManager)

local SlimeDirector = {}
SlimeDirector.__index = SlimeDirector

function SlimeDirector.new()
	local self = setmetatable({}, SlimeDirector)

	self.Managers = {}
	self.SlimeToManager = {}
	self.Connection = nil

	return self
end

function SlimeDirector:AddGroup(map, gridFolder: Folder, targets: {BasePart}, slimeNames: {string}, flowfieldRate: number, arrivalRadius: number)
	local manager = SlimeManager.new(
		map,
		gridFolder,
		targets,
		slimeNames,
		flowfieldRate,
		arrivalRadius
	)

	table.insert(self.Managers, manager)

	for _, slimeName in ipairs(slimeNames) do
		self.SlimeToManager[slimeName] = manager
	end

	return manager
end

function SlimeDirector:SpawnSlime(slimeName: string, spawnPos: Vector3, targetPart: BasePart)
	local manager = self.SlimeToManager[slimeName]

	if not manager then
		warn("No manager for slime:", slimeName)
		return nil
	end

	return manager:SpawnSlime(slimeName, spawnPos, targetPart)
end

function SlimeDirector:SpawnSlimesEqually(slimeName: string, amount: number, spawnPos: Vector3)
	local manager = self.SlimeToManager[slimeName]

	if not manager then
		warn("No manager for slime:", slimeName)
		return
	end

	manager:SpawnSlimesEqually(slimeName, amount, spawnPos)
end

function SlimeDirector:Start()
	if self.Connection then
		return
	end

	self.Connection = RunService.Heartbeat:Connect(function(dt)
		for _, manager in ipairs(self.Managers) do
			manager:Update(dt)
		end
	end)
end

function SlimeDirector:Stop()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
end

return SlimeDirector