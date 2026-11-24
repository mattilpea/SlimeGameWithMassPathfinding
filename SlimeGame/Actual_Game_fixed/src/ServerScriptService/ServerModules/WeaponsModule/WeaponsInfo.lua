local ServerStorage = game:GetService("ServerStorage")

local WeaponsInfo = {}

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

export type WeaponsInfo = {
	[number]: WeaponInfo
}

local weapons = ServerStorage.Weapons

WeaponsInfo = {
	-- Tier 1
	[1] = {
		Tier = 1,
		Name = "Basic Wood Sword",
		Type = "Melee",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
		Tool = weapons["Basic Wood Sword"],
	},

	[2] = {
		Tier = 1,
		Name = "Magic Wand",
		Type = "Projectile",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},

	[3] = {
		Tier = 1,
		Name = "Fist Gloves with Spikes",
		Type = "Melee",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},

	[4] = {
		Tier = 1,
		Name = "Throwing Kunai",
		Type = "Melee",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},

	[5] = {
		Tier = 1,
		Name = "VIP Sword",
		Type = "Melee",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},

	-- Tier 2
	[6] = {
		Tier = 2,
		Name = "Fireball Wand",
		Type = "Projectile",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
		Tool = weapons["Fireball Wand"]
	},

	[7] = {
		Tier = 2,
		Name = "Giant Axe",
		Type = "Melee",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
		Tool = weapons["Giant Axe"]
	},

	[8] = {
		Tier = 2,
		Name = "Earth Breaker",
		Type = "Melee",
		Description = "Earth bending giant doom fist weapon",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},

	[9] = {
		Tier = 2,
		Name = "Deadly Crossbow",
		Type = "Projectile",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},

	[10] = {
		Tier = 2,
		Name = "Gold Ray Sweep",
		Type = "Melee",
		Description = "Elden Ring style gold sweep attack",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},

	-- Tier 3
	[11] = {
		Tier = 3,
		Name = "Claymore",
		Type = "Melee",
		Description = "Large heavy sword",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},

	[12] = {
		Tier = 3,
		Name = "Reaper",
		Type = "Melee",
		Description = "Large sweeping weapon",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},

	[13] = {
		Tier = 3,
		Name = "Sniper Wand",
		Type = "Projectile",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},

	[14] = {
		Tier = 3,
		Name = "Giant Magic Wind Fan",
		Type = "Melee",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},

	[15] = {
		Tier = 3,
		Name = "Gold Blast Wand",
		Type = "Projectile",
		Description = "AOE sniper-style blast weapon",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},

	-- Tier 4
	[16] = {
		Tier = 4,
		Name = "Magic Slasher",
		Type = "Melee",
		Description = "Giant slashes of magic energy",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},

	[17] = {
		Tier = 4,
		Name = "Flame Sword",
		Type = "Melee",
		Description = "Flamethrower style sword slashes",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},

	[18] = {
		Tier = 4,
		Name = "Meteor Staff",
		Type = "Projectile",
		Description = "Throws meteor-like explosions everywhere",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},

	[19] = {
		Tier = 4,
		Name = "Grandmaster Ice Staff",
		Type = "Projectile",
		Description = "Fantasy ice magic staff",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},

	[20] = {
		Tier = 4,
		Name = "Demon Slasher",
		Type = "Melee",
		Description = "Giant slashes of dark energy",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},

	[21] = {
		Tier = 4,
		Name = "Magic AK47",
		Type = "Projectile",
		Description = "Funny magic rifle weapon",
		Damage = 50,
		Cooldown = 1,
		Range = 12,
		Radians = 160,
	},
} :: WeaponsInfo

return WeaponsInfo