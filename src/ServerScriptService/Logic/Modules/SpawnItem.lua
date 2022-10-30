local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tags = ServerStorage:WaitForChild("Tags")
local Items = Tags:WaitForChild("Items")
local Harvestable = Instance.new("Folder")
Harvestable.Name = "Harvestables"
Harvestable.Parent = Tags

local Hrvst = workspace:WaitForChild("Harvestable")

local Trees = Instance.new("Folder")
Trees.Name = "Trees"
Trees.Parent = Hrvst

local Ores = Instance.new("Folder")
Ores.Name = "Ores"
Ores.Parent = Hrvst

local Barrels = Instance.new("Folder")
Barrels.Name = "Barrels"
Barrels.Parent = Hrvst

local TagSystem = require(script.Parent:WaitForChild("TagSystem"))

local BarrelChance = {"AK47","Axe"}

--[[
	How does the tag system work?
	Well for each folder in the harvestable, weapons or items folder they will be "tagged"
	
	this allows for the item to have values stored within the serverstorage and cannot be modified by the client itself

]]


local SpawnItem = {}
---rbxassetid://5009602968

function SpawnOutline(Item)
	local OutlineClone = ReplicatedStorage.UI.Outline:Clone()
	OutlineClone.Visible = false
	OutlineClone.Adornee = Item
	OutlineClone.Parent = Item
end

function SpawnItem.SpawnBarrelItems(CF)
	local items = math.random(1,2)

	for _=1, items do
		local Item2Spawn = BarrelChance[math.random(1, #BarrelChance)]

		local ItemRep = ReplicatedStorage.Items[Item2Spawn]

		if ItemRep:FindFirstChild("Tool") then
			if ItemRep:FindFirstChild("Tool").Value == true then
				print(Item2Spawn)
				local Tag = SpawnItem.SpawnWeapon("World",Item2Spawn)

				SpawnItem.SpawnDroppedItemWithTag(Tag,ReplicatedStorage.ViewModels[Item2Spawn][Item2Spawn],CF+Vector3.new(0,3,0),false)
			end
		end
	end
end

function SpawnItem.SpawnStorage(Item,storageTag)
	local tag = Instance.new("IntValue")
	tag.Value = storageTag
	tag.Name = "Tag"
	tag.Parent = Item
	SpawnOutline(Item)

end

function SpawnItem.SpawnBarrel(pos,ori)
	local object = ReplicatedStorage.Harvestables.Barrel
	local TagTag = TagSystem.CreateNewHarvestableTag()
	local clonedHarvestable = object:Clone()

	clonedHarvestable:SetAttribute("Tag",TagTag)

	clonedHarvestable.Parent = Barrels

	if clonedHarvestable:IsA("Model") then
		clonedHarvestable:SetPrimaryPartCFrame(CFrame.new(pos.X,pos.Y+(clonedHarvestable.PrimaryPart.Size.Y/2),pos.Z),Vector3.new(math.clamp(ori.X,-50,50),ori.Y,math.clamp(ori.Z,-50,50)))
		clonedHarvestable.PrimaryPart.Orientation+=Vector3.new(0,math.random(-180,180),0)
		clonedHarvestable.Anchored = true
	else
		clonedHarvestable.Anchored = true
		clonedHarvestable.CFrame = CFrame.new(pos.X,pos.Y+(clonedHarvestable.Size.Y/2),pos.Z)
		clonedHarvestable.Orientation+=Vector3.new(math.clamp(ori.X,-50,50),ori.Y,math.clamp(ori.Z,-50,50))
	end

	--,ori+Vector3.new(0,math.random(-180,180),0)))
	--clonedHarvestable.PrimaryPart.Orientation = Vector3.new(math.clamp(ori.X,-30,30),ori.Y,math.clamp(ori.Z,-30,30))+Vector3.new(0,math.random(-180,180),0) -- Vector3.new(0,math.random(-180,180),0)
	local serverStorageTag = Instance.new("Folder")
	serverStorageTag.Name = TagTag
	serverStorageTag.Parent = Harvestable

	

	clonedHarvestable:SetAttribute("Health",100)

	local ResourceAmount = Instance.new("IntValue")
	ResourceAmount.Name = "B_Type"
	ResourceAmount.Value = 0 -- scrap
	ResourceAmount.Parent = serverStorageTag

	local daType = Instance.new("IntValue")
	daType.Name = "Type"
	daType.Value = 2
	daType.Parent = serverStorageTag
end

function SpawnItem.SpawnStackable(player,Item,Amount)
	local itmVals = ReplicatedStorage.Items.Stackables[Item]
	if itmVals then
		local tag = TagSystem.CreateNewItemTag()
		local tagFld = Instance.new("Folder")
		tagFld.Name = tag
		tagFld.Parent = Items
		
		local UserId
		if player == "World" then
			UserId = 0
		else
			UserId = player.UserId
		end
		local OwnerVal = Instance.new("IntValue")
		OwnerVal.Name = "Owner"
		OwnerVal.Value = UserId
		OwnerVal.Parent = tagFld

		local NameTag = Instance.new("StringValue")
		NameTag.Name = "NameTag"
		NameTag.Value = Item
		NameTag.Parent = tagFld
		
		local Quantity = Instance.new("IntValue")
		Quantity.Name = "Quantity"
		Quantity.Value = Amount
		Quantity.Parent = tagFld
		return tag
	end



end


function SpawnItem.SpawnWeapon(player,weaponName)
	local itemVals = ReplicatedStorage.Items[weaponName]
	if itemVals then
		if itemVals:FindFirstChild("Melee") and itemVals.Melee.Value == false then
			-- spawn as gun
			local RepStorageVals = ReplicatedStorage.Items[weaponName]
			if RepStorageVals then
				local maxMagVal = RepStorageVals.MagazineValue:Clone()
				local tag = TagSystem.CreateNewItemTag()
				
				local tagFld = Instance.new("Folder")
				tagFld.Name = tag
				tagFld.Parent = Items
				if player == "World" then
					local OwnerVal = Instance.new("IntValue")
					OwnerVal.Name = "Owner"
					OwnerVal.Value = 0
					OwnerVal.Parent = tagFld
				else
					local OwnerVal = Instance.new("IntValue")
					OwnerVal.Name = "Owner"
					OwnerVal.Value = player.UserId
					OwnerVal.Parent = tagFld
				end


				local NameTag = Instance.new("StringValue")
				NameTag.Name = "NameTag"
				NameTag.Value = weaponName
				NameTag.Parent = tagFld

				maxMagVal.Name = "Magazine"
				maxMagVal.Value = math.floor(math.random(1,RepStorageVals.MagazineValue.Value))
				maxMagVal.Parent = tagFld

				return tag
			else
				player:Kick("You tried to spawn an invalid weapon.. again? why try man???")
			end
		else
			-- spawn item as tool
			local tag = TagSystem.CreateNewItemTag()
			local tagFld = Instance.new("Folder")
			tagFld.Name = tag
			tagFld.Parent = Items
			local OwnerVal = Instance.new("IntValue")
			OwnerVal.Name = "Owner"
			OwnerVal.Value = player.UserId
			OwnerVal.Parent = tagFld
			local NameTag = Instance.new("StringValue")
			NameTag.Name = "NameTag"
			NameTag.Value = weaponName
			NameTag.Parent = tagFld
			return tag
		end 
	else
		player:Kick("You tried to spawn an invalid weapon... why even try man???")
	end
end

function SpawnItem.SpawnTree(object,pos:Vector3,ori:Vector3,resourceAmt)
	local TagTag = TagSystem.CreateNewHarvestableTag()
	local clonedHarvestable = object:Clone()

	clonedHarvestable:SetAttribute("Tag",TagTag)

	clonedHarvestable.Parent = Trees
	clonedHarvestable:SetPrimaryPartCFrame(CFrame.new(pos.X,pos.Y+(clonedHarvestable.PrimaryPart.Size.Y/2),pos.Z),Vector3.new(math.clamp(ori.X,-50,50),ori.Y,math.clamp(ori.Z,-50,50)))
	clonedHarvestable.PrimaryPart.Orientation+=Vector3.new(0,math.random(-180,180),0)
	--,ori+Vector3.new(0,math.random(-180,180),0)))
	--clonedHarvestable.PrimaryPart.Orientation = Vector3.new(math.clamp(ori.X,-30,30),ori.Y,math.clamp(ori.Z,-30,30))+Vector3.new(0,math.random(-180,180),0) -- Vector3.new(0,math.random(-180,180),0)
	local serverStorageTag = Instance.new("Folder")
	serverStorageTag.Name = TagTag
	serverStorageTag.Parent = Harvestable
	local ResourceAmount = Instance.new("IntValue")
	ResourceAmount.Name = "ResourceAmount"
	ResourceAmount.Value = resourceAmt
	ResourceAmount.Parent = serverStorageTag
	local daType = Instance.new("IntValue")
	daType.Name = "Type"
	daType.Value = 0
	daType.Parent = serverStorageTag

	--print("Successfully spawned Tree with: ", "tag:", TagTag, "Harvestable Amount:", ResourceAmount.Value)
end

function SpawnItem.SpawnNode(object,pos:Vector3,resourceAmt)
	local TagTag = TagSystem.CreateNewHarvestableTag()
	local clonedHarvestable = object:Clone()

	clonedHarvestable:SetAttribute("Tag",TagTag)

	clonedHarvestable.Parent = Ores
	clonedHarvestable:SetPrimaryPartCFrame(CFrame.new(pos)) -- Vector3.new(0,math.random(-180,180),0)
	local serverStorageTag = Instance.new("Folder")
	serverStorageTag.Name = TagTag
	serverStorageTag.Parent = Harvestable

	local ResourceAmount = Instance.new("IntValue")
	ResourceAmount.Name = "ResourceAmount"
	ResourceAmount.Value = resourceAmt
	ResourceAmount.Parent = serverStorageTag

	local daType = Instance.new("IntValue")
	daType.Name = "Type"
	daType.Value = 1
	daType.Parent = serverStorageTag

	--print("Successfully spawned Tree with: ", "tag:", TagTag, "Harvestable Amount:", ResourceAmount.Value)
end

function SpawnItem.SpawnDroppedItem(userId,Item,cf,conditions)
	local Tag = TagSystem.CreateNewItemTag()
	local ItmTag = Instance.new("IntValue")
	ItmTag.Name = "Tag"
	ItmTag.Value = Tag

	local FolderTag = Instance.new("Folder")
	FolderTag.Name = Tag
	FolderTag.Parent = Items
	
	for key,val in conditions do
		local val2Num = tonumber(val)
		if val2Num then
			local theVal = Instance.new("NumberValue")
			theVal.Name = key
			theVal.Value = val2Num
			theVal.Parent = FolderTag
		else
			local theVal = Instance.new("StringValue")
			theVal.Name = key
			theVal.Value = val
			theVal.Parent = FolderTag
		end

	end
	local OwnerVal = Instance.new("IntValue")
	OwnerVal.Name = "Owner"
	if userId == "World" then
		OwnerVal.Value = 0
	else 
		OwnerVal.Value = userId
	end
	OwnerVal.Parent = FolderTag
	local clonedItem = Item:Clone()
	ItmTag.Parent = clonedItem
	local Point2 = Instance.new("ObjectValue")
	Point2.Value = clonedItem
	Point2.Name = "Pointer"
	Point2.Parent = FolderTag
	clonedItem.PrimaryPart.CFrame = cf
	clonedItem.Parent = workspace.DroppedItems
	SpawnOutline(clonedItem)
end

function SpawnItem.SpawnDroppedItemWithTag(Tag,Item,cf,lockInPlace)
	if not lockInPlace or lockInPlace == nil then
		lockInPlace = false
	end
	local TagFolder = Items[Tag]
	TagFolder.Owner.Value = 0
	local clonedItem = Item:Clone()
	for _,x in clonedItem:GetDescendants() do
		pcall(function()
			x.CanCollide = true
		end)
	end
	
	local ItmTag = Instance.new("IntValue")
	ItmTag.Name = "Tag"
	ItmTag.Value = Tag
	ItmTag.Parent = clonedItem
	local Point2 = Instance.new("ObjectValue")
	Point2.Value = clonedItem
	Point2.Name = "Pointer"
	Point2.Parent = TagFolder
	clonedItem.PrimaryPart.CFrame = cf
	clonedItem.PrimaryPart.Anchored = lockInPlace
	SpawnOutline(clonedItem)
	clonedItem.Parent = workspace.DroppedItems
	print(clonedItem)
	return clonedItem

end

return SpawnItem
