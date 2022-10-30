local SettingsExample ={
	["RemoveWhenEmpty"]=false,
	["DisableTransfer"]=false,
	["isLocked"]=false,
	["LockedCode"]=0000,
	["PlayerDroppedBag"]=false
}

local StorageAmount = 0

local inventories = {}
local Storage = {}

--[[
slot MUST be string
tag MUST be number


]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Tags = ServerStorage:WaitForChild("Tags")
local Links = Tags:WaitForChild("LinkedContainers")

function DeepClone(t) -- clones a table
	local c = {}
	for k,v in pairs(t) do
		if type(v) == "table" then
			v = DeepClone(v)
		end
		c[k]=v
	end
	return c 
end

local Items = Tags:WaitForChild("Items")
local SpawnItem = require(script.Parent:WaitForChild("SpawnItem"))

local IH = {}
IH.Storage = {}
IH.Player = {}
IH.Dongle = {}

local function updateInventory(player)
	if not inventories[player.UserId] then
		inventories[player.UserId] = {}
		--for i=1,36,1 do
		--inventories[player.UserId][i] = {["Name"]="Empty"}
		--end

	end
	IH.Player.UpdateTagsWithinInv(player)
end

function IH.Storage.GetExtraData(storageTag,Key)
	return Storage[tostring(storageTag)][Key]
end

function IH.Storage.AddExtraData(storageTag,Key,Val)
	Storage[tostring(storageTag)][Key]=Val
	print("add data",Storage[tostring(storageTag)])
end

function IH.Storage.GetSettings(storageTag)
	return Storage[tostring(storageTag)]["Settings"]
end

function IH.Storage.Exists(storageTag)
	if Storage[tostring(storageTag)] then
		return Storage[tostring(storageTag)]["Contains"]
	else
		return false
	end
end

function IH.Storage.LinkObject(storageTag,Item)
	local ObjectVal = Links:FindFirstChild(storageTag) or Instance.new("ObjectValue")
	ObjectVal.Name = storageTag
	ObjectVal.Value = Item
	ObjectVal.Parent = Links
end

function IH.Storage.Delete(storageTag)
	Storage[tostring(storageTag)] = nil
end

function IH.Storage.CreateContainer(slotsAmt,Settings)
	local cpSettings = DeepClone(SettingsExample)
	for k,v in Settings do
		cpSettings[k] = v
	end
	local STag = StorageAmount
	StorageAmount+=1
	print(STag)
	Storage[tostring(STag)] = {["SlotAmount"]=slotsAmt,["Contains"]={},["Settings"]=cpSettings}
	print(Storage[tostring(STag)])
	return tostring(STag)
end

function IH.Storage.GetSlotAmt(Slt)
	return Storage[tostring(Slt)]["SlotAmount"]
end

function IH.Storage.GetAllItemsFromStorage(storageTag)
	return Storage[tostring(storageTag)]["Contains"]
end

function IH.Storage.AddTagToStorage(storageTag:string,slot:string,Tag:Int)
	--local Storage = InventoryManager.Storage.CreateContainer("12",{["RemoveWhenEmpty"]=true,["DisableTransfer"]=true})String,List
	--InventoryManager.Storage.AddTagToStorage(Storage,tostring(itmSlots),SpawnItem.SpawnWeapon("World",val)) --String,String,Int
	local itemVal = Items[Tag]

	if itemVal then
		local vals = {}
		Storage[tostring(storageTag)]["Contains"][slot] = {["Tag"]=Tag,["Name"]=itemVal.NameTag.Value}
		for _,v in ipairs(itemVal:GetChildren()) do
			if not table.find({"NameTag","Tag"},v.Name) then
				table.insert(vals,{[v.Name]=v.Value})
				Storage[tostring(storageTag)]["Contains"][slot][v.Name] = v.Value
			end
		end

	end
end

--storageTag:string,slot:string,Tag:int
function IH.Storage.SwapSlotsInStorage(storageTag:string,slot1:string,slot2:string)
	local oldslot2 = Storage[tostring(storageTag)]["Contains"][slot2]
	Storage[tostring(storageTag)]["Contains"][slot2] = Storage[tostring(storageTag)]["Contains"][slot1]
	Storage[tostring(storageTag)]["Contains"][slot1] = oldslot2
end

function IH.Dongle.SwapFromInv2Storage(storageTag:string,player,inventorySlot:string,ChestSlot:string)
	local oldslot2 = inventories[player.UserId][tostring(inventorySlot)]
	if inventories[player.UserId][tostring(inventorySlot)] then
		Items[inventories[player.UserId][tostring(inventorySlot)]["Tag"]].Owner.Value = 0
		print(Items[inventories[player.UserId][tostring(inventorySlot)]["Tag"]].Owner.Value)
	end
	if Storage[tostring(storageTag)]["Contains"][tostring(ChestSlot)] then
		Items[Storage[tostring(storageTag)]["Contains"][tostring(ChestSlot)]["Tag"]].Owner.Value = player.UserId
		print(Items[Storage[tostring(storageTag)]["Contains"][tostring(ChestSlot)]["Tag"]].Owner.Value)
	end
	print(inventories[player.UserId][tostring(inventorySlot)])
	print(Storage[tostring(storageTag)]["Contains"][tostring(ChestSlot)] )
	inventories[player.UserId][tostring(inventorySlot)] = Storage[tostring(storageTag)]["Contains"][tostring(ChestSlot)] 
	Storage[tostring(storageTag)]["Contains"][tostring(ChestSlot)] = oldslot2 -- changes storage to inv

	-- change tags

end

function IH.Dongle.SwapSlots(player,slot1:string,slot2:string)
	if inventories[player.UserId][slot1] == nil or inventories[player.UserId][slot2] == nil then
		local oldslot2 = inventories[player.UserId][slot2]
		inventories[player.UserId][slot2] = inventories[player.UserId][slot1]
		inventories[player.UserId][slot1] = oldslot2
		return
	end
	if inventories[player.UserId][slot1].Name == inventories[player.UserId][slot2].Name and (inventories[player.UserId][slot2].Quantity and inventories[player.UserId][slot1].Quantity) then
		local maxAmount = ReplicatedStorage.Items.Stackables[inventories[player.UserId][slot1].Name].Value
		if (inventories[player.UserId][slot2].Quantity +inventories[player.UserId][slot1].Quantity ) <= maxAmount then
			print("yes.")
			inventories[player.UserId][slot2].Quantity += inventories[player.UserId][slot1].Quantity
			inventories[player.UserId][slot1] = nil
			Items[inventories[player.UserId][slot1].Tag] = nil
			Items[inventories[player.UserId][slot2].Tag].Quantity.Value = inventories[player.UserId][slot2].Quantity
			-- 980 + 60 = 1040 < 1060
		elseif (inventories[player.UserId][slot2].Quantity + inventories[player.UserId][slot1].Quantity) <= (maxAmount+inventories[player.UserId][slot1].Quantity) then
			local dxd = (inventories[player.UserId][slot2].Quantity + inventories[player.UserId][slot1].Quantity) - maxAmount 
			print(dxd)
			Items[inventories[player.UserId][slot2].Tag].Quantity.Value += inventories[player.UserId][slot1].Quantity-dxd
			inventories[player.UserId][slot2].Quantity = Items[inventories[player.UserId][slot2].Tag].Quantity.Value

			-- create new tag
			local StackableTag = SpawnItem.SpawnStackable(player,inventories[player.UserId][slot2].Name,dxd)
			local newestSlot = IH.GetNewestSlot(player)
			IH.AddTagToInventory(player,tostring(newestSlot),StackableTag)
			Items[StackableTag].Quantity.Value += dxd
		else
			local oldslot2 = inventories[player.UserId][slot2]
			inventories[player.UserId][slot2] = inventories[player.UserId][slot1]
			inventories[player.UserId][slot1] = oldslot2
		end
		return
	else
		local oldslot2 = inventories[player.UserId][slot2]
		inventories[player.UserId][slot2] = inventories[player.UserId][slot1]
		inventories[player.UserId][slot1] = oldslot2
	end

end

function IH.Player.deleteInventory(player)
	updateInventory(player)
	inventories[player.UserId] = {}
end

function IH.Player.AddTagToInventory(player,slot:string,Tag:IntValue)
	updateInventory(player)
	local itemVal = Items[Tag]

	if itemVal then
		local vals = {}
		inventories[player.UserId][slot] = {["Tag"]=Tag,["Name"]=itemVal.NameTag.Value}
		for _,v in ipairs(itemVal:GetChildren()) do
			if not table.find({"NameTag","Tag"},v.Name) then
				table.insert(vals,{[v.Name]=v.Value})
				inventories[player.UserId][slot][v.Name] = v.Value
			end
		end

	end
end


function IH.Player.removeSlot(player,slot:string)
	updateInventory(player)
	if inventories[player.UserId][slot] then
		print(inventories[player.UserId][slot])
		inventories[player.UserId][slot] = nil
	end
end


function IH.Player.GetTagSlot(player,Tag:string)
	updateInventory(player)
	local itemVal = Items[Tag]
	if itemVal then
		for slotNum,slot in inventories[player.UserId] do
			if slot.Tag == Tag then
				return slotNum
			end
		end
	end
	return false
end

function IH.Player:FindNamedChildren(player,Name)
	updateInventory(player)
	local namedChildren = {}
	for slotNum,slot in inventories[player.UserId] do
		if tostring(slot["Name"]) == tostring(Name) then
			table.insert(namedChildren,{["Slot"]=slotNum,["Values"]=slot})
		end
	end
	print(namedChildren)
	return namedChildren
end

-- deprecated
function IH.Player.ChangeVal(player,Slot:string,Change,Val)
	inventories[player.UserId][Slot][Change] = Val
	updateInventory(player)
end

function IH.Player.UpdateTagsWithinInv(player)
	if not inventories[player.UserId] then
		inventories[player.UserId] = {}
		--for i=1,36,1 do
		--inventories[player.UserId][i] = {["Name"]="Empty"}
		--end

	end
	local checkedtags = {}
	for slnum1,slot in inventories[player.UserId] do
		if not Items:FindFirstChild(slot.Tag) then
			inventories[player.UserId][slnum1] = nil -- tag of that slot doesnt exist
		end
		for _,_ in slot do
			if slot.Tag then
				local itemVal = Items[slot.Tag]
				for slnum2,v in ipairs(itemVal:GetChildren()) do
					if table.find(checkedtags,slot.Tag) then
						inventories[player.UserId][slnum2] = nil -- duplicate slot with another tag
					end
					table.insert(checkedtags,slot.Tag)
					if not table.find({"NameTag","Tag"},v.Name) then
						pcall(function()
							inventories[player.UserId][slnum2][v.Name] = v.Value
						end)
					end
				end
			else
				inventories[player.UserId][_] = nil -- slot seems to be malfunctioned..?
			end
		end
	end
end

function IH.Player.GetAllItemsWithinInventory(player)
	updateInventory(player)
	return inventories[player.UserId]
end

function IH.Player.GetSlotContents(player,slot:string)
	updateInventory(player)
	if inventories[player.UserId][slot] then
		return inventories[player.UserId][slot]
	else
		return false
	end
end

function IH.Player:GetNewestSlot(player)
	updateInventory(player)
	local cnt = 1
	for slotNum,slot in inventories[player.UserId] do
		if not Items[slot.Tag] then
			cnt=slotNum
			break
		end 
		if not inventories[player.UserId][tostring(cnt)] then
			break
		end
		cnt +=1
	end
	if cnt > 31 then
		return false
	else
		return tostring(cnt)
	end
end


function IH.Player.FindPlayerIDWithTag(tag:number)
	for playerId,inventory in inventories do
		for _,slot in inventory do
			if slot.Tag == tag then
				return playerId
			end
		end
	end
	return false
end

return IH
