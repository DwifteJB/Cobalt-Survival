local Data = {}

Data.Icons = {
	["Axe"] = "rbxassetid://5009602968",
	["CustomSMG"] = "rbxassetid://10788536508",
	["Thompson"] = "rbxassetid://10788536357",
	["AK47"] = "rbxassetid://10788536078",
	["Crossbow"] = "rbxassetid://10788536233",
	["Wood"]="rbxassetid://339291882",
	["Stone"]="rbxassetid://5009602968",
	["BuildingPlan"]="rbxassetid://10590477428"
}

Data.CanSnapTo = {
	["Wall"]= {
		["Bottom"]=false,
		["Top"]=true,
		["WallLeft"]=true,
		["WallRight"]=true,
		["FoundationWallConnect"]=true,
		["Foundation"]=false
	},
	["Foundation"]= {
		["Bottom"]=false,
		["Top"]=false,
		["WallLeft"]=false,
		["WallRight"]=false,
		["FoundationWallConnect"]=false,
		["Foundation"]=true
	}
}

return Data
