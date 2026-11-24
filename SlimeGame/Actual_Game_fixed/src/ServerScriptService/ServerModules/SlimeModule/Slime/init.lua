--!strict

local Slime = {}
Slime.__index = Slime

local SlimeInfo = require(script.Parent.SlimeInfo)

export type SlimeData = SlimeInfo.SlimeData

export type Slime = {
	Data: SlimeData,
	AutoRotate: BoolValue,
	Model: Model,
	PrimaryPart: BasePart,
	Spawn: (self: Slime, cf : CFrame) -> (),
}

function Slime.new(data: SlimeData): Slime
	local self = setmetatable({}, Slime) :: Slime

	self.Data = data --const
	self.Model = data.SlimeModel:Clone()
	self.PrimaryPart = self.Model.PrimaryPart :: BasePart
	
	
	return self
end

function Slime:Spawn(cf : CFrame)
	self.Model.Parent = workspace.AllSlimes
	self.Model:PivotTo(cf)
end


return Slime