--[[
		Server-Side Hit Registry
		Created by Dwifte
		
]]
local hitData = {}
local ThrowData = {}


local FSR = require(script.FastCastRedux)
local cast = FSR.new()
local castBehaviour = cast.newBehavior()
local castParams = RaycastParams.new()
castBehaviour.AutoIgnoreContainer = true
castBehaviour.Acceleration = Vector3.new(0, -workspace.Gravity*0.65, 0)
castParams.IgnoreWater = true
castParams.FilterType = Enum.RaycastFilterType.Blacklist

local ServerStorage = game:GetService("ServerStorage")
local ItemSettings = ServerStorage:WaitForChild("ItemSettings")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BanSystem = require(script.Parent:WaitForChild("Modules"):WaitForChild("BanSystem"))
local InventoryManager = require(script.Parent:WaitForChild("Modules"):WaitForChild("InventoryManager"))
local DamageSystem = require(script.Parent:WaitForChild("Modules"):WaitForChild("DamageSystem"))
local SpawnItem = require(script.Parent:WaitForChild("Modules"):WaitForChild("SpawnItem"))

local Items = ServerStorage:WaitForChild("Tags")
local Harvestables = Items:WaitForChild("Harvestables")
local Itms = Items:WaitForChild("Items")

local Players = game:GetService("Players")

local Remotes = ReplicatedStorage.Remotes

local ThrowableFolder = Instance.new("Folder")
ThrowableFolder.Name = "Throwables"
ThrowableFolder.Parent = workspace

local Settings = require(ServerStorage:WaitForChild("Settings"))

local GatherRate = Settings.SpawnSettings.Rate

function addStackableToHarvestable(player,name,amtToHarvest)
	print(amtToHarvest)
	local FFC = InventoryManager.Player:FindNamedChildren(player,name)
	local cnt = 0
	for _,_ in FFC do
		cnt+=1
	end
	if cnt == 0 then
		local StackableTag = SpawnItem.SpawnStackable(player,name,amtToHarvest)
		local newestSlot = InventoryManager.Player:GetNewestSlot(player)
		print("newslot",newestSlot)
		InventoryManager.Player.AddTagToInventory(player,tostring(newestSlot),StackableTag)
		print("created new slot")
	else
		local done = false
		local itemVals = ReplicatedStorage.Items.Stackables.Wood
		print(FFC)
		for _,key in FFC do
			if done == true then return end
			local slotDetails = Itms[key.Values.Tag]

			if (slotDetails.Quantity.Value + amtToHarvest) < itemVals.MaxAmount.Value then

				slotDetails.Quantity.Value += amtToHarvest
				InventoryManager.Player.ChangeVal(player,key.Slot,"Quantity",slotDetails.Quantity.Value)
				done = true
				break
			elseif (slotDetails.Quantity.Value + amtToHarvest) < (itemVals.MaxAmount.Value + amtToHarvest) then
				local amountToAddStack = (slotDetails.Quantity.Value + amtToHarvest) - itemVals.MaxAmount.Value

				slotDetails.Quantity.Value += itemVals.MaxAmount.Value
				InventoryManager.Player.ChangeVal(player,key.Slot,"Quantity",itemVals.MaxAmount.Value)

				local StackableTag = SpawnItem.SpawnStackable(player,name,amountToAddStack)
				local newestSlot = InventoryManager.Player:GetNewestSlot(player)
				InventoryManager.Player.AddTagToInventory(player,tostring(newestSlot),StackableTag)

				done = true
				break
			end
		end
		if done == false then
			local StackableTag = SpawnItem.SpawnStackable(player,name,amtToHarvest)
			local newestSlot = InventoryManager.Player:GetNewestSlot(player)

			InventoryManager.Player.AddTagToInventory(player,tostring(newestSlot),StackableTag)
			Itms[StackableTag].Quantity.Value += amtToHarvest
		end
		local Inv = InventoryManager.Player.GetAllItemsWithinInventory(player)
		Remotes.ItemSystem.RegisterHotbarItems:FireClient(player,Inv)
	end
end

function hitHarvestable(player,Object,Tag, ToolUsing)
	if Object:GetAttribute("Tag") == Tag then
		--pos
		local pos
		if Object:IsA("Model") then
			pos = (player.Character.HumanoidRootPart.Position - Object.PrimaryPart.Position).magnitude
		else
			pos = (player.Character.HumanoidRootPart.Position - Object.Position).magnitude
		end

		if pos < 10 then
			local resourceAmt = Items.Harvestables[Tag]:FindFirstChild("ResourceAmount") or nil
			local typeOfHarvestable = Items.Harvestables[Tag].Type or nil
			if typeOfHarvestable.Value == 0 and ReplicatedStorage.Items[ToolUsing].Gather.Value == true then
				local harvestMultiplier = ItemSettings[ToolUsing].WoodRate
				local amtToHarvest = (50 * harvestMultiplier.Value) * GatherRate
				if harvestMultiplier.Value == 0 then return false end 
				if resourceAmt.Value - amtToHarvest <= 200 then
					addStackableToHarvestable(player,"Wood",resourceAmt.Value)
					Remotes.Core.ItemAdded:FireClient(player,"Wood", resourceAmt.Value)
					Items.Harvestables[Tag].ResourceAmount.Value = 0
					-- destroy tree
					Object:Destroy()
					Items.Harvestables[Tag]:Destroy()
					return true
				else

					Items.Harvestables[Tag].ResourceAmount.Value -= amtToHarvest
					addStackableToHarvestable(player,"Wood",amtToHarvest)

					Remotes.Core.ItemAdded:FireClient(player,"Wood", amtToHarvest, "rbxassetid://5009602968")
					print("Wood left in tree:", resourceAmt.Value)
					return true
				end
			elseif typeOfHarvestable.Value == 1 and ReplicatedStorage.Items[ToolUsing].Gather.Value == true then
				local harvestMultiplier = ItemSettings[ToolUsing].OreRate
				local amtToHarvest = 50 * harvestMultiplier.Value
				if harvestMultiplier == 0 then return false end 
				if resourceAmt.Value - amtToHarvest <= 200 then

					addStackableToHarvestable(player,"Stone",resourceAmt.Value)
					Remotes.Core.ItemAdded:FireClient(player,"Stone", resourceAmt.Value, "rbxassetid://5009602968")
					resourceAmt.Value = 0
					-- destroy tree
					Object:Destroy()
					Items.Harvestables[Tag]:Destroy()

					return true
				else
					resourceAmt.Value -= amtToHarvest
					addStackableToHarvestable(player,"Stone",amtToHarvest)
					Remotes.Core.ItemAdded:FireClient(player,"Stone", amtToHarvest, "rbxassetid://5009602968")
					print("Stone left in ore:", resourceAmt.Value)
					-- would add item here
					-- but no inv code
					return true
				end

			elseif typeOfHarvestable.Value == 2 then
				print("hit barrel")
			end
		else
			-- Code 004
			BanSystem.AnticheatBanOnline(player,"004","Player hit a harvestable too far away")
		end
	else
		Object:Destroy()
		Items.Harvestables[Tag]:Destroy()
		return false
	end
end

Remotes.Melee.ValidateRaycast.OnServerInvoke = function(player,mouse,Tag)
	local TagVals = Itms[Tag]
	local itm = InventoryManager.Player.GetTagSlot(player,Tag)
	local tn = tonumber(itm)
	if itm == false or tn > 6 then
		return 1
	end
	if TagVals == nil then
		BanSystem(player,"027","Player tried to use a tool that did not exist in the TagSystem")
	end
	if TagVals.Owner.Value ~= player.UserId then
		BanSystem(player,"026","Player tried to use a tool that didn't belong to them")
	end
	local TagName = TagVals.NameTag.Value
	if hitData[player.UserId] == nil then
		hitData[player.UserId] = {}
		hitData[player.UserId][TagName] = {
			["LastHit"] = os.clock()-10
		}
	end
	if hitData[player.UserId][TagName].LastHit + ReplicatedStorage.Items[TagName].AnimationsCoolDown.Fire.Value >= os.clock() then return; end 
	--local direction = (mouse + player.Character.Head.Position).Unit * 16 -- only do 10 studs of distance!
	local raycastParams = RaycastParams.new()
	local blacklist = {player.Character,player}
	raycastParams.IgnoreWater = true
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = blacklist
	local ray = workspace:Raycast(player.Character.Head.Position, (mouse -player.Character.Head.Position).Unit * 100, raycastParams)
	hitData[player.UserId][TagName] = {
		["LastHit"] = os.clock()
	}
	if ray then
		if not player.Character.RightHand:FindFirstChild(TagName) then
			BanSystem.AnticheatBanOnline(player,"022","Player tool didn't match what player was holding.")
		end
		local itemValues = ReplicatedStorage.Items[TagName]
		if ray.Distance <= itemValues.Range.Value then
			--DamageSystem.DamagePlayer(player,plr,ray.Instance,itemValues.Damage.Value)
			--					DamageSystem.DamageNPC(player,ray.Instance.Parent.Parent:FindFirstChild("Humanoid"),ray.Instance.Name,itemValues.Damage.Value)
			local character = ray.Instance:FindFirstAncestorWhichIsA("Model")
			if character and character:FindFirstChild("Humanoid") then
				local plr = Players:GetPlayerFromCharacter(character)
				if plr then
					DamageSystem.DamagePlayer(player,plr,ray.Instance,itemValues.Damage.Value,TagName)
				else
					DamageSystem.DamageNPC(player,character:FindFirstChild("Humanoid"),ray.Instance,itemValues.Damage.Value)
				end
			else
				local Instanced
				local TagHarvest
				if ray.Instance.Parent:GetAttribute("Tag") then
					Instanced = ray.Instance.Parent
					TagHarvest = ray.Instance.Parent:GetAttribute("Tag")
				elseif ray.Instance:GetAttribute("Tag") then
					Instanced = ray.Instance
					TagHarvest = ray.Instance:GetAttribute("Tag")
				elseif ray.Instance.Parent.Parent:GetAttribute("Tag") then
					Instanced = ray.Instance.Parent.Parent
					TagHarvest = ray.Instance.Parent.Parent:GetAttribute("Tag")
				end
				print(Instanced,TagHarvest)
				if TagHarvest and Instanced then
					hitHarvestable(player,Instanced,TagHarvest,TagName)
				end
			end
		end

	end
end



Remotes.Melee.prepareThrow.OnServerInvoke = function(player,Tag,prepOrCancel)
	if Tag == false then
		if ThrowData[player.UserId] == nil then
			ThrowData[player.UserId] = {}
		else
			for i,v in ThrowData[player.UserId] do
				if v.Ready == true then
					ThrowData[player.UserId][i].Ready = false
				end
			end
		end
		return true
	end
	local TagVals = Itms[Tag]
	local itm = InventoryManager.Player.GetTagSlot(player,Tag)
	local tn = tonumber(itm)
	if itm == false or tn > 6 then
		return 1
	end
	if TagVals == nil then
		BanSystem.AnticheatBanOnline(player,"027","Player tried to use a tool that did not exist in the TagSystem")
	end
	if TagVals.Owner.Value ~= player.UserId then
		BanSystem.AnticheatBanOnline(player,"026","Player tried to use a tool that didn't belong to them")
	end
	local TagName = TagVals.NameTag.Value
	if prepOrCancel == true then -- prepare
		if ThrowData[player.UserId] == nil then
			ThrowData[player.UserId] = {}
		end
		if ThrowData[player.UserId][TagName] == nil then
			ThrowData[player.UserId][TagName] = {
				["Ready"] = true,
				["LastHit"] = 0,
				["Direction"] = 0,
			}
		end
		ThrowData[player.UserId][TagName]["Ready"] = true
		return 2

		-- would have anim / code to make arms go higher
	elseif prepOrCancel == false then
		if ThrowData[player.UserId] == nil then
			ThrowData[player.UserId] = {}
		end
		if ThrowData[player.UserId][TagName] == nil then
			ThrowData[player.UserId][TagName] = {
				["Ready"] = false,
				["LastHit"] = 0,
				["Direction"] = 0,
			}
		end
		ThrowData[player.UserId][TagName]["Ready"] = false
		return 2
	end
end

Remotes.Melee.Throw.OnServerInvoke = function(player,Tag,mousePos)
	local TagVals = Itms[Tag]
	local itm = InventoryManager.Player.GetTagSlot(player,Tag)
	local tn = tonumber(itm)
	if itm == false or tn > 6 then
		return false
	end
	if TagVals == nil then
		BanSystem(player,"027","Player tried to use a tool that did not exist in the TagSystem")
	end
	if TagVals.Owner.Value ~= player.UserId then
		BanSystem(player,"026","Player tried to use a tool that didn't belong to them")
	end
	local TagName = TagVals.NameTag.Value
	if ThrowData[player.UserId] == nil then return false end
	if ThrowData[player.UserId][TagName] == nil then return false end
	if ThrowData[player.UserId]["Ready"] == false then return false end
	if ThrowData[player.UserId][TagName].LastHit + ReplicatedStorage.Items[TagName].AnimationsCoolDown.Fire.Value >= os.clock() then return false; end 
	ThrowData[player.UserId][TagName].LastHit = os.clock()

	local RepVals = ReplicatedStorage.Items[TagName]


	local Bullet = ReplicatedStorage.ViewModels[TagName][TagName].PrimaryPart:Clone()
	Bullet.Name = "MClone"
	print(Bullet)

	local findplrfrombullet = Instance.new("ObjectValue")
	findplrfrombullet.Name = "Owner"
	findplrfrombullet.Value = player.Character
	findplrfrombullet.Parent = Bullet

	local ModelName = Instance.new("IntValue")
	ModelName.Name = "Tag"
	ModelName.Value = Tag
	ModelName.Parent = Bullet

	local ModelName = Instance.new("StringValue")
	ModelName.Name = "ModelName"
	ModelName.Value = TagName
	ModelName.Parent = Bullet

	local dmg = RepVals.Damage:Clone()
	dmg.Parent = Bullet

	castParams.FilterDescendantsInstances = {player,player.Character,ThrowableFolder}
	castBehaviour.RaycastParams = castParams
	castBehaviour.CosmeticBulletContainer = ThrowableFolder
	castBehaviour.CosmeticBulletTemplate = Bullet
	local org = player.Character.Head.Position
	local dir = (mousePos - player.Character.Head.Position).Unit * 100
	local vel = 82
	ThrowData[player.UserId][TagName]["Ready"] = false
	local cs = cast:Fire(org,dir,vel,castBehaviour)
end

function onRayHit(cast,result,velocity,bullet)
	local hit = result.Instance
	local character = hit:FindFirstAncestorWhichIsA("Model")
	local plrAtcking = Players:GetPlayerFromCharacter(bullet.Owner.Value)	
	if character and character:FindFirstChild("Humanoid") then

		local plr = Players:GetPlayerFromCharacter(character)

		if plr then
			DamageSystem.DamagePlayer(plrAtcking,plr,hit,bullet.Damage.Value,bullet.ModelName.Value)
		else
			DamageSystem.DamageNPC(plrAtcking,character:FindFirstChild("Humanoid"),hit,bullet.Damage.Value)
		end

	end
	local Slot = InventoryManager.Player.GetTagSlot(plrAtcking,bullet.Tag.Value)
	InventoryManager.Player.removeSlot(plrAtcking,tostring(Slot))
	local Inv = InventoryManager.Player.GetAllItemsWithinInventory(plrAtcking)

	Remotes.ItemSystem.RegisterHotbarItems:FireClient(plrAtcking,Inv)
	Remotes.Inventory.deEquip:FireClient(plrAtcking)
	local bulletLength = bullet.Size.Z/2
	local offset = CFrame.new(0,0,-bulletLength)
	if hit ~= workspace.Terrain then
		SpawnItem.SpawnDroppedItemWithTag(bullet.Tag.Value,ReplicatedStorage.ViewModels[bullet.ModelName.Value][bullet.ModelName.Value],bullet.CFrame,true)
		--[[local Link = Instance.new("Weld")
		Link.Name = "Link"
		Link.Part0=hit
		Link.Part1=Item.PrimaryPart
		Link.Parent = Item--]]
	else
		SpawnItem.SpawnDroppedItemWithTag(bullet.Tag.Value,ReplicatedStorage.ViewModels[bullet.ModelName.Value][bullet.ModelName.Value],bullet.CFrame,false)
	end
	bullet:Destroy()



end


function onLengthChanged(cast, lastPoint, direction, length, velocity, bullet)
	if bullet then
		local bulletLength = bullet.Size.Z/2
		local offset = CFrame.new(0,0,-(length-bulletLength))
		bullet.CFrame = CFrame.lookAt(lastPoint,lastPoint + direction):ToWorldSpace(offset)
	end

end

cast.LengthChanged:Connect(onLengthChanged)
cast.RayHit:Connect(onRayHit)

--[[RunService.Stepped:Connect(function()
	for i,v in ThrowableFolder:GetChildren() do
		v.Orientation *= Vector3.new(0,1,0)
	end
end)
--]]