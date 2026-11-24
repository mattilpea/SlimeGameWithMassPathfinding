local ServerStorage = game:GetService("ServerStorage")
local Slimes = ServerStorage.Slimes

export type SlimeData = {
	Name: string,
	SlimeModel: Model,
	AttackDamage: number,
	Speed: number,
	JumpHeight: number,
	JumpCooldown: number,
	AttackRange: number,
	AttackRate: number,
	Credits: number,
	Health: number,
}

const SlimeInfo: {[string]: SlimeData} = {
	["Normal Slime"] = {
		Name = "Normal Slime",
		SlimeModel = Slimes.Normal_Slime,
		AttackDamage = 10,
		Speed = 16,
		JumpHeight = 5,
		AttackRange = 5,
		AttackRate = 3,
		JumpCooldown = 0.5,	
		Credits = 10,
		Health = 100,
	},

	["Fire Slime"] = {
		Name = "Fire Slime",
		SlimeModel = Slimes.Fire_Slime,
		AttackDamage = 10,
		Speed = 16,
		JumpHeight = 10,
		AttackRange = 5,
		AttackRate = .7,
		Credits = 10,
		Health = 100,
	},

	["Ghost Slime"] = {
		Name = "Ghost Slime",
		SlimeModel = Slimes.Ghost_Slime,
		AttackDamage = 5,
		Speed = 25,
		JumpHeight = 15,
		AttackRange = 5,
		AttackRate = .7,
		Credits = 10,
		Health = 100,
	},

	["Giant Slime"] = {
		Name = "Giant Slime",
		SlimeModel = Slimes.Giant_Slime,
		AttackDamage = 10,
		Speed = 10,
		JumpHeight = 5,
		AttackRange = 5,
		AttackRate = .7,
		Credits = 10,
		Health = 100,
	},

	["Giant Demon Slime"] = {
		Name = "Giant Demon Slime",
		SlimeModel = Slimes.Giant_Demon_Slime,
		AttackDamage = 15,
		Speed = 10,
		JumpHeight = 5,
		AttackRange = 5,
		AttackRate = .7,
		Credits = 10,
		Health = 100,
	},

	["Golden Slime"] = {
		Name = "Golden Slime",
		SlimeModel = Slimes.Golden_Slime,
		AttackDamage = 10,
		Speed = 16,
		JumpHeight = 10,
		AttackRange = 5,
		AttackRate = .7,
		Credits = 10,
		Health = 100,
	},

	["Speedy Slime"] = {
		Name = "Speedy Slime",
		SlimeModel = Slimes.Speedy_Slime,
		AttackDamage = 10,
		Speed = 30,
		JumpHeight = 20,
		AttackRange = 5,
		AttackRate = .7,
		Credits = 10,
		Health = 100,
	},
}

return SlimeInfo