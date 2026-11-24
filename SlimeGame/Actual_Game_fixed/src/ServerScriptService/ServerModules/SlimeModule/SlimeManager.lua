--!strict

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local SlimeManager = {}
SlimeManager.__index = SlimeManager

local SlimeModule = require(script.Parent)
local NavGrid = require(script.Parent.NavGrid)
local FlowField = require(script.Parent.FlowField)
local SlimeMover = require(script.Parent.SlimeMover)
local SlimeAnimator = require(script.Parent.SlimeAnimator)

function SlimeManager.new(map, gridFolder: Folder, targets: {BasePart}, slimeNames: {string}, flowfieldRate: number, arrivalRadius: number)
	local samplePart = gridFolder:FindFirstChildWhichIsA("BasePart")
	assert(samplePart, "Grid folder has no parts: " .. gridFolder.Name)

	local cellSize = samplePart.Size.X

	local self = setmetatable({}, SlimeManager)

	self.Grid = NavGrid.FromFolder(
		map.NavGridPoints.Start.Position,
		map.NavGridPoints.End.Position,
		cellSize,
		gridFolder
	)

	self.Targets = targets
	self.SlimeNames = slimeNames
	self.ActiveSlimes = {}
	self.Flowfields = {}
	self.ModelToState = {}

	self.FlowfieldTimer = 0
	self.ReassignTimer = 0

	self.FlowfieldRate = flowfieldRate
	self.ReassignRate = 1
	self.ArrivalRadius = arrivalRadius

	return self
end

function SlimeManager:CanUseCell(cell)
	return cell
		and cell.Part
		and cell.deadEnd == false
		and cell.occupied == false
end

function SlimeManager:GetNearestFreeCell(pos: Vector3)
	local bestCell = nil
	local bestDistance = math.huge

	for x = 1, self.Grid.XSteps do
		for z = 1, self.Grid.ZSteps do
			local cell = self.Grid.Cells[x][z]

			if self:CanUseCell(cell) then
				local distance = (cell.Part.Position - pos).Magnitude

				if distance < bestDistance then
					bestDistance = distance
					bestCell = cell
				end
			end
		end
	end

	return bestCell
end

local function getPlayerHumanoidFromTarget(targetPart: BasePart)
	local character = targetPart:FindFirstAncestorOfClass("Model")
	if not character then return nil end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return nil end

	return character:FindFirstChildWhichIsA("Humanoid")
end

local function flashSuccessfulHit(model: Model)
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(0, 255, 0)
	highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
	highlight.FillTransparency = 0.35
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = model
	highlight.Parent = model

	Debris:AddItem(highlight, 0.2)
end

local function flashSlimeHit(model: Model)
	local highlight = Instance.new("Highlight")
	highlight.Name = "DamageHighlight"
	highlight.FillColor = Color3.fromRGB(255, 35, 35)
	highlight.OutlineColor = Color3.fromRGB(255, 80, 80)
	highlight.FillTransparency = 0.2
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = model
	highlight.Parent = model
	Debris:AddItem(highlight, 0.18)
end

local function createHealthBar(model: Model, adornee: BasePart, healthValue: NumberValue, maxHealth: number)
	local gui = Instance.new("BillboardGui")
	gui.Name = "HealthBar"
	gui.Adornee = adornee
	gui.Size = UDim2.fromOffset(48, 6)
	gui.StudsOffsetWorldSpace = Vector3.new(0, model:GetExtentsSize().Y * 0.55 + 0.8, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 80
	gui.Parent = model

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	background.BorderSizePixel = 0
	background.Parent = gui

	local backgroundCorner = Instance.new("UICorner")
	backgroundCorner.CornerRadius = UDim.new(1, 0)
	backgroundCorner.Parent = background

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(70, 225, 80)
	fill.BorderSizePixel = 0
	fill.Parent = background

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local function update()
		local ratio = math.clamp(healthValue.Value / math.max(maxHealth, 1), 0, 1)
		fill.Size = UDim2.fromScale(ratio, 1)
		if ratio <= 0.3 then
			fill.BackgroundColor3 = Color3.fromRGB(255, 55, 55)
		elseif ratio <= 0.6 then
			fill.BackgroundColor3 = Color3.fromRGB(255, 185, 45)
		else
			fill.BackgroundColor3 = Color3.fromRGB(70, 225, 80)
		end
	end

	healthValue:GetPropertyChangedSignal("Value"):Connect(update)
	update()
end

function SlimeManager:RemoveSlime(index: number)
	local slimeState = self.ActiveSlimes[index]

	if slimeState.CurrentCell then
		slimeState.CurrentCell.occupied = false
	end

	if slimeState.NextCell then
		slimeState.NextCell.occupied = false
	end

	if slimeState.Animator then
		slimeState.Animator:Stop()
	end

	if slimeState.Slime and slimeState.Slime.Model then
		if slimeState.DamageConnection then
			slimeState.DamageConnection:Disconnect()
		end
		self.ModelToState[slimeState.Slime.Model] = nil
		slimeState.Slime.Model:Destroy()
	end

	table.remove(self.ActiveSlimes, index)
end

function SlimeManager:GetStateFromModel(model: Model)
	return self.ModelToState[model]
end

function SlimeManager:DamageSlime(slimeState, damage: number)
	if not slimeState or slimeState.Dead then
		return
	end

	slimeState.Health -= damage
	flashSlimeHit(slimeState.Slime.Model)

	if slimeState.HealthValue then
		slimeState.HealthValue.Value = math.max(slimeState.Health, 0)
	end

	if slimeState.Health <= 0 then
		slimeState.Dead = true
		slimeState.Moving = false

		if slimeState.Animator then
			slimeState.Animator:Play("Death")
		end

		task.delay(1, function()
			local index = table.find(self.ActiveSlimes, slimeState)
			if index then
				self:RemoveSlime(index)
			end
		end)

		return
	end

	if slimeState.Animator then
		slimeState.Animator:Play("Hit")
	end
end

function SlimeManager:SpawnSlime(slimeName: string, spawnPos: Vector3, targetPart: BasePart?)
	local spawnCell = self:GetNearestFreeCell(spawnPos)

	if not spawnCell then
		warn("No free cells left. Destroyed incoming slime:", slimeName)
		return nil
	end

	local slime = SlimeModule:LoadSlime(slimeName)
	slime:Spawn(spawnCell.Part.CFrame)

	local animator = SlimeAnimator.new(slime.Model)
	animator:Play("Idle")

	local maxHealth = slime.Data.Health or slime.Data.health or 1

	local healthValue = Instance.new("NumberValue")
	healthValue.Name = "Health"
	healthValue.Value = maxHealth
	healthValue.Parent = slime.Model

	local maxHealthValue = Instance.new("NumberValue")
	maxHealthValue.Name = "MaxHealth"
	maxHealthValue.Value = maxHealth
	maxHealthValue.Parent = slime.Model

	createHealthBar(slime.Model, slime.PrimaryPart, healthValue, maxHealth)

	spawnCell.occupied = true

	local slimeState = {
		Slime = slime,
		Animator = animator,
		Target = targetPart,

		CurrentCell = spawnCell,
		NextCell = nil,

		Moving = false,
		FromCF = spawnCell.Part.CFrame,
		ToCF = spawnCell.Part.CFrame,

		Alpha = 0,
		TravelTime = 0,

		AttackTimer = 0,

		Health = maxHealth,
		MaxHealth = maxHealth,
		HealthValue = healthValue,
		MaxHealthValue = maxHealthValue,
		Dead = false,
	}

	local damageEvent = Instance.new("BindableEvent")
	damageEvent.Name = "TakeDamage"
	damageEvent.Parent = slime.Model
	slimeState.DamageConnection = damageEvent.Event:Connect(function(damage)
		if typeof(damage) == "number" then
			self:DamageSlime(slimeState, damage)
		end
	end)

	self.ModelToState[slime.Model] = slimeState
	table.insert(self.ActiveSlimes, slimeState)

	return slimeState
end

function SlimeManager:SpawnSlimesEqually(slimeName: string, amount: number, spawnPos: Vector3)
	for i = 1, amount do
		local target = nil

		if #self.Targets > 0 then
			target = self.Targets[((i - 1) % #self.Targets) + 1]
		end

		self:SpawnSlime(slimeName, spawnPos, target)
	end
end

function SlimeManager:ReassignTargetsEqually()
	local slimeCount = #self.ActiveSlimes
	local targetCount = #self.Targets

	if slimeCount == 0 or targetCount == 0 then
		return
	end

	local targetSlots = {}

	local baseAmount = math.floor(slimeCount / targetCount)
	local extra = slimeCount % targetCount

	for targetIndex, targetPart in ipairs(self.Targets) do
		targetSlots[targetPart] = baseAmount

		if targetIndex <= extra then
			targetSlots[targetPart] += 1
		end
	end

	local candidates = {}

	for _, slimeState in ipairs(self.ActiveSlimes) do
		local currentCell = slimeState.CurrentCell

		if currentCell and currentCell.Part and not slimeState.Dead then
			local slimePos = currentCell.Part.Position

			for _, targetPart in ipairs(self.Targets) do
				if targetPart and targetPart.Parent then
					local distance = (slimePos - targetPart.Position).Magnitude

					table.insert(candidates, {
						SlimeState = slimeState,
						Target = targetPart,
						Distance = distance,
					})
				end
			end
		end
	end

	table.sort(candidates, function(a, b)
		return a.Distance < b.Distance
	end)

	local assigned = {}

	for _, candidate in ipairs(candidates) do
		local slimeState = candidate.SlimeState
		local target = candidate.Target

		if not assigned[slimeState] and targetSlots[target] and targetSlots[target] > 0 then
			slimeState.Target = target
			assigned[slimeState] = true
			targetSlots[target] -= 1
		end
	end
end

function SlimeManager:UpdateFlowfields()
	for _, targetPart in ipairs(self.Targets) do
		if targetPart and targetPart.Parent then
			self.Flowfields[targetPart] = FlowField.Generate(
				self.Grid,
				targetPart.Position,
				self.ArrivalRadius
			)
		else
			self.Flowfields[targetPart] = nil
		end
	end
end

function SlimeManager:Update(dt: number)
	self.ReassignTimer += dt
	self.FlowfieldTimer += dt

	if self.ReassignTimer >= self.ReassignRate then
		self.ReassignTimer = 0
		self:ReassignTargetsEqually()
	end

	if self.FlowfieldTimer >= self.FlowfieldRate then
		self.FlowfieldTimer = 0
		self:UpdateFlowfields()
	end

	for i = #self.ActiveSlimes, 1, -1 do
		local slimeState = self.ActiveSlimes[i]
		local slime = slimeState.Slime
		local currentCell = slimeState.CurrentCell
		local targetPart = slimeState.Target

		if slimeState.Dead then
			continue
		end

		if not slime or not slime.Model or not slime.Model.Parent then
			self:RemoveSlime(i)
			continue
		end

		if not currentCell or not currentCell.Part then
			self:RemoveSlime(i)
			continue
		end

		if not targetPart or not targetPart.Parent then
			slimeState.Target = nil
			slimeState.AttackTimer = 0

			if slimeState.Animator then
				slimeState.Animator:Play("Idle")
			end

			continue
		end

		local flowfield = self.Flowfields[targetPart]

		if flowfield and flowfield.Costs then
			local _, cx, cz = self.Grid:GetCellFromPosition(currentCell.Part.Position)

			if cx and cz then
				local cost = flowfield.Costs[cx][cz]

				if cost and cost <= 2 then
					slimeState.Animator:Play("Attack")
					slimeState.AttackTimer += dt

					local attackRate = slime.Data.AttackRate or slime.Data.attackrate or 1
					local damage = slime.Data.Damage or slime.Data.damage or 1

					if slimeState.AttackTimer >= attackRate then
						slimeState.AttackTimer = 0

						local humanoid = getPlayerHumanoidFromTarget(targetPart)

						if humanoid and humanoid.Health > 0 then
							humanoid:TakeDamage(damage)
							flashSuccessfulHit(slime.Model)
						end
					end

					continue
				else
					slimeState.AttackTimer = 0
					slimeState.Animator:Play("Idle")
				end
			end
		end

		if not slimeState.Moving then
			if not flowfield then
				continue
			end

			local nextCell = FlowField.GetNextCell(flowfield, currentCell)

			if not self:CanUseCell(nextCell) then
				continue
			end

			currentCell.occupied = false
			nextCell.occupied = true

			slimeState.NextCell = nextCell
			slimeState.FromCF = currentCell.Part.CFrame
			slimeState.ToCF = nextCell.Part.CFrame

			local distance = (slimeState.ToCF.Position - slimeState.FromCF.Position).Magnitude
			slimeState.TravelTime = distance / slime.Data.Speed

			if slimeState.TravelTime <= 0 then
				self:RemoveSlime(i)
				continue
			end

			slimeState.Alpha = 0
			slimeState.Moving = true
		end

		SlimeMover.Step(slimeState, dt)
	end
end

return SlimeManager