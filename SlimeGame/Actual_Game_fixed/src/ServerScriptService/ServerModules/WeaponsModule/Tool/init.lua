--!strict

local WeaponTool = {}
WeaponTool.__index = WeaponTool

export type WeaponInfo = {
	Tier: number,
	Name: string,
	Type: "Melee" | "Projectile",
	Damage: number,
	Cooldown: number,
	Range: number,
	Radians: number,
	Description: string?,
	Tool: Tool?
}

function WeaponTool.new(info: WeaponInfo)
	assert(info.Tool, "Weapon has no Tool model: " .. info.Name)

	local self = setmetatable({}, WeaponTool)
	self.Tool = info.Tool:Clone()
	self.Tool.CanBeDropped = false
	self.Tool:SetAttribute("WeaponName", info.Name)
	self.Tool:SetAttribute("WeaponType", info.Type)
	self.Tool:SetAttribute("Damage", info.Damage)
	self.Tool:SetAttribute("Cooldown", info.Cooldown)
	self.Tool:SetAttribute("Range", info.Range)
	self.Tool:SetAttribute("Radians", info.Radians)
	return self
end

return WeaponTool