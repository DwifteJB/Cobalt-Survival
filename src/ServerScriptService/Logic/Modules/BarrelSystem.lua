local SpawnItem = require(script.Parent.SpawnItem)
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tags = ServerStorage:WaitForChild("Tags")
local Items = Tags:WaitForChild("Items")
local BarrelChance = {"AK47","Axe"}

local Barrel = {}


function Barrel.SpawnBarrelItems(CF)
	local items = math.random(1,2)

	for _=1, items do
		local Item2Spawn = BarrelChance[math.random(1, #BarrelChance)]

		local ItemRep = ReplicatedStorage.Items[Item2Spawn]

		if ItemRep:FindFirstChild("Tool") then
			if ItemRep:FindFirstChild("Tool").Value == true then
				local Tag = SpawnItem.SpawnWeapon("World",Item2Spawn)

				SpawnItem.SpawnDroppedItemWithTag(Tag,ReplicatedStorage.ViewModels[Item2Spawn][Item2Spawn],CF+Vector3.new(0,3,0),false)
			end
		end
	end
end

function Barrel.Hit(Tag,Object,Damage)
	if Object == nil or Object:GetAttribute("Health") == nil then return end 
    if Object:GetAttribute("Health") or Object:GetAttribute("Health") > 0 then
        local newHealth = Object:GetAttribute("Health") - Damage
        if newHealth <= 0 then
            
            -- drop items, remove
            local CF
            if Object:IsA("Model") then
                CF = Object.PrimaryPart.CFrame
            else
                CF = Object.CFrame
            end
            Barrel.SpawnBarrelItems(CF)
            Object:SetAttribute("Health",0)
            Tags.Harvestables[Tag]:Destroy()
            Object:Destroy()
        else
            Object:SetAttribute("Health",newHealth)
        end
    else
        Tags.Harvestables[Tag]:Destroy()
        Object:Destroy()
    end
end

return Barrel