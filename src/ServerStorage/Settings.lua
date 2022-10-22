local Settings = {
	["MaxPlayers"]=50,
	["RespawnLoadout"]={
		["Stone"]={
			["Durability"]="Max",
		},
		["Torch"]={
			["Durability"]="Max"
		}
	},
	["MapSize"]=Vector3.new(1024,512,1024),
	["SpawnSettings"]={
		["Rate"]=1.0,
		["TreeAmount"]=250,
		["NodeAmount"]=70,
		["ChanceOfForest"]=20, -- 1/x chance,
		["Density"]={
			["Minimum"]=8,
			["Maximum"]=15
		}
	},
	["QueueSettings"]={
		["Queue"]=true,
		["PriorityIds"]={1,2,3}
	},
	["CraftingSettings"]={
		["SpeedModifier"]=1.0,
		["PriceModifier"]=1.0
	},
	["Events"]={
		["Airdrop"]={
			["AmountOfDrops"]=2, 
			["DropSpeedModifier"]=1.0,
			["DespawnTime"]=500,
			["MinimumTimeBetweenDrops"]=20, -- x minutes
			["Chance"]=3 -- 1/x chance per 5 minutes
		}
	}
}

return Settings
