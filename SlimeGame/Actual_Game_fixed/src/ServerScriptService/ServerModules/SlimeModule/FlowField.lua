--!strict

local FlowField = {}

local MAX_STEP_HEIGHT = 5

local DIRS = {
	Vector2.new(1, 0),
	Vector2.new(-1, 0),
	Vector2.new(0, 1),
	Vector2.new(0, -1),

	Vector2.new(1, 1),
	Vector2.new(1, -1),
	Vector2.new(-1, 1),
	Vector2.new(-1, -1),
}

local function isValidCell(cell)
	return cell
		and cell.Part
		and cell.deadEnd == false
end

local function canMoveBetween(fromCell, toCell)
	if not isValidCell(fromCell) or not isValidCell(toCell) then
		return false
	end

	local yDiff = math.abs(fromCell.Part.Position.Y - toCell.Part.Position.Y)

	return yDiff <= MAX_STEP_HEIGHT
end

local function getNearestValidTargetCell(grid, targetPos: Vector3)
	local bestCell = nil
	local bestX = nil
	local bestZ = nil
	local bestDistance = math.huge

	for x = 1, grid.XSteps do
		for z = 1, grid.ZSteps do
			local cell = grid.Cells[x][z]

			if isValidCell(cell) then
				local distance = (cell.Part.Position - targetPos).Magnitude

				if distance < bestDistance then
					bestDistance = distance
					bestCell = cell
					bestX = x
					bestZ = z
				end
			end
		end
	end

	return bestCell, bestX, bestZ
end

local function getArrivalCells(grid, targetX: number, targetZ: number, radius: number)
	local arrivals = {}
	local arrivalSet = {}

	local targetCell = grid.Cells[targetX] and grid.Cells[targetX][targetZ]

	for x = targetX - radius, targetX + radius do
		for z = targetZ - radius, targetZ + radius do
			local cell = grid.Cells[x] and grid.Cells[x][z]

			if isValidCell(cell) and canMoveBetween(targetCell, cell) then
				local dx = x - targetX
				local dz = z - targetZ

				if math.sqrt(dx * dx + dz * dz) <= radius then
					table.insert(arrivals, {
						Cell = cell,
						X = x,
						Z = z,
					})

					arrivalSet[cell] = true
				end
			end
		end
	end

	return arrivals, arrivalSet
end

function FlowField.Generate(grid, targetPos: Vector3, arrivalRadius: number?)
	arrivalRadius = arrivalRadius or 3

	local targetCell, tx, tz = grid:GetCellFromPosition(targetPos)

	if not isValidCell(targetCell) then
		targetCell, tx, tz = getNearestValidTargetCell(grid, targetPos)
	end

	if not targetCell or not tx or not tz then
		warn("No valid flowfield target found")
		return nil
	end

	local arrivals, arrivalSet = getArrivalCells(grid, tx, tz, arrivalRadius)

	if #arrivals == 0 then
		table.insert(arrivals, {
			Cell = targetCell,
			X = tx,
			Z = tz,
		})

		arrivalSet[targetCell] = true
	end

	local costs = {}

	for x = 1, grid.XSteps do
		costs[x] = {}

		for z = 1, grid.ZSteps do
			costs[x][z] = math.huge
		end
	end

	local queue = {}
	local head = 1

	for _, arrival in ipairs(arrivals) do
		costs[arrival.X][arrival.Z] = 0

		table.insert(queue, {
			x = arrival.X,
			z = arrival.Z,
		})
	end

	while head <= #queue do
		local current = queue[head]
		head += 1

		local currentCell = grid.Cells[current.x][current.z]
		local currentCost = costs[current.x][current.z]

		for _, dir in ipairs(DIRS) do
			local nx = current.x + dir.X
			local nz = current.z + dir.Y

			local neighbor = grid.Cells[nx] and grid.Cells[nx][nz]

			if canMoveBetween(currentCell, neighbor) then
				local moveCost = math.abs(dir.X) + math.abs(dir.Y) == 2 and 1.414 or 1
				local newCost = currentCost + moveCost

				if newCost < costs[nx][nz] then
					costs[nx][nz] = newCost

					table.insert(queue, {
						x = nx,
						z = nz,
					})
				end
			end
		end
	end

	return {
		Grid = grid,
		Costs = costs,
		ArrivalSet = arrivalSet,
		TargetCell = targetCell,
	}
end

function FlowField.GetNextCell(flowfield, currentCell)
	if not flowfield or not currentCell or not currentCell.Part then
		return nil
	end

	if flowfield.ArrivalSet[currentCell] then
		return nil
	end

	local grid = flowfield.Grid
	local _, cx, cz = grid:GetCellFromPosition(currentCell.Part.Position)

	if not cx or not cz then
		return nil
	end

	local currentCost = flowfield.Costs[cx][cz]
	local bestCell = nil
	local bestCost = currentCost

	for _, dir in ipairs(DIRS) do
		local nx = cx + dir.X
		local nz = cz + dir.Y

		local neighbor = grid.Cells[nx] and grid.Cells[nx][nz]

		if canMoveBetween(currentCell, neighbor) and neighbor.occupied == false then
			local cost = flowfield.Costs[nx][nz]

			if cost < bestCost then
				bestCost = cost
				bestCell = neighbor
			end
		end
	end

	return bestCell
end

return FlowField