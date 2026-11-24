--!strict
--IGNORE.
local Slime = {}
Slime.__index = Slime

local SlimeInfo = require(script.Parent.SlimeInfo)

export type SlimeData = SlimeInfo.SlimeData

export type Slime = {
	Data: SlimeData,
	AutoRotate: BoolValue,
	Model: Model,
	PrimaryPart: BasePart,

	Attachment: Attachment,
	AlignPosition: AlignPosition,
	AlignOrientation: AlignOrientation,
	DataFunctions: Folder,
	MoveValue: Vector3Value,

	Move: (self: Slime, direction: Vector3) -> (),
	Spawn: (self: Slime, position: Vector3) -> (),
}

function Slime.new(data: SlimeData): Slime
	local self = setmetatable({}, Slime) :: Slime

	self.Data = data --const
	self.Model = data.SlimeModel:Clone()
	self.PrimaryPart = self.Model.PrimaryPart :: BasePart
	
	local attachment = Instance.new("Attachment")
	local alignPosition = Instance.new("AlignPosition")
	local alignOrientation = Instance.new("AlignOrientation")
	
	local dataFunctions = Instance.new('Folder')
	local moveValue = Instance.new('Vector3Value')
	local AutoRotateVal = Instance.new('BoolValue')

	self.Attachment = attachment
	self.AlignPosition = alignPosition
	self.AlignOrientation = alignOrientation
	self.DataFunctions = dataFunctions
	self.MoveValue = moveValue
	self.AutoRotate = AutoRotateVal
	
	dataFunctions.Name = "DataFunctions"
	moveValue.Name = "MoveValue"
	AutoRotateVal.Name = "AutoRotate"
	
	dataFunctions.Parent = self.Model
	attachment.Parent = self.PrimaryPart
	alignPosition.Parent = self.PrimaryPart
	alignOrientation.Parent = self.PrimaryPart
	
	moveValue.Parent = dataFunctions
	moveValue.Value = Vector3.zero
	
	AutoRotateVal.Parent = dataFunctions
	AutoRotateVal.Value = true

	alignPosition.Attachment0 = attachment
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.MaxForce = 1e10
	alignPosition.Responsiveness = 10
	alignPosition.MaxVelocity = self.Data.Speed

	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.RigidityEnabled = true
	alignOrientation.Attachment0 = attachment
	
	moveValue:GetPropertyChangedSignal("Value"):Connect(function()
		local val = moveValue.Value
		self:Move(val)
	end)
	
	
	return self
end

function Slime:Spawn(position: Vector3)
	self.Model.Parent = workspace.AllSlimes
	self.Model:MoveTo(position + Vector3.new(math.random(1,3), 0, math.random(1,3)))
	
	self:Move(Vector3.new(0,0,0))
end

function Slime:Move(direction: Vector3)
	if direction.Magnitude == 0 then
		self.AlignPosition.Position = self.PrimaryPart.Position
		return
	end
	
	local dir = direction.Unit
	local speed = self.Data.Speed
	local currentPos = self.PrimaryPart.Position

	if self.AutoRotate.Value then
		local AO = self.AlignOrientation :: AlignOrientation
		AO.CFrame = CFrame.lookAt(currentPos, currentPos + Vector3.new(dir.X, 0, dir.Z))
	end
	
	local target = currentPos + Vector3.new(dir.X, -0.4, dir.Z) * speed
	self.AlignPosition.Position = target
end

return Slime