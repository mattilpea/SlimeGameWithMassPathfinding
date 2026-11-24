--!strict

local BlockCaster = require(script.BlockCaster)

local NavGrid = {}
NavGrid.__index = NavGrid

local mapVisuals = workspace:WaitForChild("mapVisuals")

local function generatePart(folder : Folder)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = true
	part.Size = Vector3.new(1, 1, 1)
	part.Color = Color3.fromRGB(255, 0, 0)
	part.CollisionGroup = "mapVisuals"
	part.Parent = folder
	return part
end

function NavGrid.new(StartPos: Vector3, EndPos: Vector3, CellSize: number, folder : Folder)
	local self = setmetatable({}, NavGrid)
	
	local minX = math.min(StartPos.X, EndPos.X)
	local maxX = math.max(StartPos.X, EndPos.X)

	local minZ = math.min(StartPos.Z, EndPos.Z)
	local maxZ = math.max(StartPos.Z, EndPos.Z)

	local y = StartPos.Y

	local xSteps = math.max(1, math.floor((maxX - minX) / CellSize))
	local zSteps = math.max(1, math.floor((maxZ - minZ) / CellSize))
	
	self.Cells = {}
	self.MinX = minX
	self.MinZ = minZ
	self.CellSize = CellSize
	self.XSteps = xSteps
	self.ZSteps = zSteps
	
	for x = 1, xSteps do
		self.Cells[x] = {} -- IMPORTANT: always create row

		for z = 1, zSteps do
			local worldX = minX + ((x - 1) * CellSize) + (CellSize / 2)
			local worldZ = minZ + ((z - 1) * CellSize) + (CellSize / 2)

			local part = generatePart(folder)
			part.Position = Vector3.new(worldX, y, worldZ)
			part.Size = Vector3.new(CellSize, CellSize, CellSize)

			self.Cells[x][z] = {
				Part = part,
				Position = part.Position,
				Casted = false,
				deadEnd = false,
				occupied = false,
			}
		end
	end

	return self
end

function NavGrid:Generate(LowestPoint : number, HighestPoint : number)
	
	local finished = false
	
	-- First pass
	for x, column in pairs(self.Cells) do
		for z, cell in pairs(column) do
			local part = cell.Part
			if part then
				part.Color = Color3.fromRGB(0, 255, 0)
				BlockCaster:Register(part, cell)

			end
		end
	end

	-- Second pass (new behavior)
	for x, column in pairs(self.Cells) do
		for z, cell in pairs(column) do
			local part = cell.Part
			if part then
				part.Anchored = false
				
				BlockCaster:Cast(part, cell)
				--task.wait(0.5)
			end
		end
	end
	
	for x, column in pairs(self.Cells) do
		for z, cell in pairs(column) do
			if not cell.Casted then
				repeat task.wait() until cell.Casted
			end
		end
	end

	for x, column in pairs(self.Cells) do
		for z, cell in pairs(column) do
			if cell.Part.Position.Y > HighestPoint or cell.Part.Position.Y < LowestPoint then
				cell.Part:Destroy()
			end
		end
	end
	
	for x, column in pairs(self.Cells) do
		for z, cell in pairs(column) do
			local part = cell.Part
			
			if not part then --aka part got destroyed due to the earlier checks
				cell.deadEnd = true
			end
		end
	end
	
	finished = true
	
	return finished
end

function NavGrid.FromFolder(StartPos, EndPos, CellSize, folder)
	local self = setmetatable({}, NavGrid)

	local minX = math.min(StartPos.X, EndPos.X)
	local maxX = math.max(StartPos.X, EndPos.X)

	local minZ = math.min(StartPos.Z, EndPos.Z)
	local maxZ = math.max(StartPos.Z, EndPos.Z)

	self.MinX = minX
	self.MinZ = minZ
	self.CellSize = CellSize

	self.XSteps = math.max(1, math.floor((maxX - minX) / CellSize))
	self.ZSteps = math.max(1, math.floor((maxZ - minZ) / CellSize))

	self.Cells = {}

	for x = 1, self.XSteps do
		self.Cells[x] = {}

		for z = 1, self.ZSteps do
			self.Cells[x][z] = {
				Part = nil,
				Position = nil,
				Casted = true,
				deadEnd = true,
				occupied = false,
			}
		end
	end

	for _, part in ipairs(folder:GetChildren()) do
		if part:IsA("BasePart") then
			local x = math.floor((part.Position.X - self.MinX) / CellSize + 1)
			local z = math.floor((part.Position.Z - self.MinZ) / CellSize + 1)

			if self.Cells[x] and self.Cells[x][z] then
				self.Cells[x][z] = {
					Part = part,
					Position = part.Position,
					Casted = true,
					deadEnd = false,
					occupied = false,
				}
			end
		end
	end

	return self
end

function NavGrid:GetCellFromPosition(pos: Vector3)
	local x = (pos.X - self.MinX) / self.CellSize + 1
	local z = (pos.Z - self.MinZ) / self.CellSize + 1

	-- OUT OF BOUNDS CHECK (real check)
	if x < 1 or x > self.XSteps or z < 1 or z > self.ZSteps then
		return nil
	end

	x = math.floor(x)
	z = math.floor(z)

	return self.Cells[x][z], x, z
end

return NavGrid