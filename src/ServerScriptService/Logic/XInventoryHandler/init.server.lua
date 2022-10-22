local Players = game:GetService("Players")
local PlayerEvents = script.Parent.PlayerEvents


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Cooldown = require(script.Parent:WaitForChild("Modules"):WaitForChild("CooldownSystem"))
local ActionTracker = require(script.Parent:WaitForChild("Modules"):WaitForChild("PlayerTracker"))
local Despawner = require(script.Despawner)
local Remotes = ReplicatedStorage.Remotes
local ServerStorage = game.ServerStorage
local Stats = Instance.new("Folder")
local SpawnItem = require(script.Parent.Modules.SpawnItem)
Stats.Name = "Stats"
Stats.Parent = ServerStorage
local Tags = ServerStorage:WaitForChild("Tags")
local Links = Tags:WaitForChild("LinkedContainers")
local Items = Tags:WaitForChild("Items")
local Inventories = Instance.new("Folder")
Inventories.Name = "Inventories"
Inventories.Parent = Stats

local InventoryManager = require(script.Parent.Modules.InventoryManager)

local TypesOfEquippables = {"Head","Torso","Feet","Legs","Gloves"}
local Weapons = {"Crossbow","CustomSMG","Thompson","AK47","Axe","BuildingPlan"}

PlayerEvents.PlayerAdded.Event:Connect(function(Player)
	print(Player)
	local plrFolder = Instance.new("Folder")
	plrFolder.Name = Player.Name
	plrFolder.Parent = Inventories
	local PlayerEquipped = Instance.new("Folder")
	PlayerEquipped.Name = "Equipped"
	PlayerEquipped.Parent = plrFolder
	for _,val in Weapons do
		local tg = SpawnItem.SpawnWeapon(Player,val)
		local slot = InventoryManager.Player:GetNewestSlot(Player)
		InventoryManager.Player.AddTagToInventory(Player,tostring(slot),tg)
		local slot2 = InventoryManager.Player:GetNewestSlot(Player)
		local tg2 = SpawnItem.SpawnWeapon(Player,val)
		InventoryManager.Player.AddTagToInventory(Player,tostring(slot2),tg2)

	end
	for _,val in TypesOfEquippables do
		local Value = Instance.new("NumberValue")
		Value.Name = val
		Value.Value = -1
		Value.Parent = PlayerEquipped
	end
	local vals = InventoryManager.Player.GetAllItemsWithinInventory(Player)
	Remotes.ItemSystem.RegisterHotbarItems:FireClient(Player,vals)
end)

PlayerEvents.PlayerDied.Event:Connect(function(Player,character)
	if character.RightHand:FindFirstChild("ToolMotor6D") then
		character.RightHand:FindFirstChild("ToolMotor6D").Part1.Parent:Destroy()
		character.RightHand:FindFirstChild("ToolMotor6D"):Destroy()
	end
	local Inv = InventoryManager.Player.GetAllItemsWithinInventory(Player)
	local Storage = InventoryManager.Storage.CreateContainer("30",{["RemoveWhenEmpty"]=true,["PlayerDroppedBag"]=true})
	local acceptableTags = {}
	-- equipment would be above here!!!
	InventoryManager.Storage.AddExtraData(Storage,"Equipment",{})
	local cnt=0
	for _,_ in Inv do
		cnt+=1
	end
	local InvSlots = 0
	for _,v in Inv do
		if Items[v.Tag] then
			if Items[v.Tag]:FindFirstChild("Owner") then
				if Items[v.Tag].Owner.Value == Player.UserId then
					-- prevent duping
					table.insert(acceptableTags,v.Tag)
				end
			end
		end
	end
	for i,Tag in acceptableTags do
		print(i,Tag)
		Items[tostring(Tag)].Owner.Value = 0
		InventoryManager.Storage.AddTagToStorage(Storage,tostring(InvSlots),tonumber(Tag))
		InvSlots+=1
	end
	InventoryManager.Player.deleteInventory(Player)

	character.Archivable = true
	local BagItem = character:Clone()
	local Filter = {"Humanoid","LocalScript"}

	for _,v in BagItem:GetChildren() do
		if table.find(Filter,v.ClassName) then
			v:Destroy()
		end
	end
	for _,v in character:GetChildren() do
		if v:IsA("MeshPart") or v:IsA("Part") then
			v.Transparency = 1
		end
	end
	BagItem.UpperTorso.Waist.C0=CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0)
	--BagItem.UpperTorso.Waist.C1=CFrame.new(0, BagItem.UpperTorso.Size.Y/2, 0)
	if BagItem.RightHand:FindFirstChild("ToolMotor6D") then
		BagItem.RightHand:FindFirstChild("ToolMotor6D").Part1.Parent:Destroy()
		BagItem.RightHand:FindFirstChild("ToolMotor6D"):Destroy()
	end
	local Tag = Instance.new("IntValue")
	Tag.Value = Storage
	Tag.Name = "Tag"
	Tag.Parent = BagItem
	BagItem.Parent = workspace.DroppedItems.Bags
	InventoryManager.Storage.LinkObject(Storage,BagItem)
	Despawner.Storage(Storage,100,{
		["SpawnAnother"]=true,
		["Part"]=ReplicatedStorage.Items.Bag,
		["DespawnTime"]=300,
		["Name"]=Player.DisplayName.."'s Bag"
	})
	local V = Instance.new("BodyVelocity")
	V.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
	V.Velocity = Vector3.new(3,1,1)
	V.P = 1250
	V.Parent = BagItem.HumanoidRootPart
	Debris:AddItem(V,0.2)
end)

local Storage = InventoryManager.Storage.CreateContainer("36",{["RemoveWhenEmpty"]=true,["DisableTransfer"]=false})
local itmSlots = 0
for _,val in Weapons do
	InventoryManager.Storage.AddTagToStorage(Storage,tostring(itmSlots),SpawnItem.SpawnWeapon("World",val))
	itmSlots+=1
end
print(InventoryManager.Storage.GetAllItemsFromStorage(Storage))
local tstItem = Instance.new("Part")
tstItem.Size = Vector3.new(2,1,2)
tstItem.Parent = workspace
tstItem.Position = Vector3.new(-204.74, 56.477, -63.529)
tstItem.Name = "SMALL WOODEN BOX"
tstItem.Anchored = true
SpawnItem.SpawnStorage(tstItem,Storage,CFrame.new(Vector3.new(-185, 30.5, -43)))
InventoryManager.Storage.LinkObject(Storage,tstItem)

-- inventory updater...
--[[coroutine.wrap(function()
	while wait(10) do
		for _,player in pairs(Players:GetPlayers()) do
			-- prevent desync
			InventoryManager.Player.UpdateTagsWithinInv(player)
		end
	end
end)()--]]

function getDistance(Player,Object)
	if Object:IsA("Model") then
		return (Object.PrimaryPart.Position - Player.Character.LowerTorso.Position).Magnitude
	else
		return (Object.Position - Player.Character.LowerTorso.Position).Magnitude
	end	
end

function ContainerUpdate(storageTag)
	local PlayerIds = ActionTracker:PlayersInActionWithKey("Container",tonumber(storageTag))
	for _,v in PlayerIds do
		pcall(function()
			local container = InventoryManager.Storage.Exists(tostring(storageTag))
			local sltM = InventoryManager.Storage.GetSlotAmt(tostring(storageTag))
			local data = {["ContainerName"]=Links[storageTag].Value.Name,["Values"]=container,["SlotAmount"]=sltM}
			Remotes.Inventory.UpdateContents:FireClient(Players:GetPlayerByUserId(v),data)
		end)
	end
	local CSettings = InventoryManager.Storage.GetSettings(storageTag)
	local Items = InventoryManager.Storage.GetAllItemsFromStorage(storageTag)
	local c = 0
	for _,_ in Items do
		c+=1

	end
	if CSettings then
		if CSettings.RemoveWhenEmpty == true then
			if c <= 0 then
				-- remove
				if Links[storageTag] then
					Links[storageTag].Value:Destroy()
					local PlayerIds = ActionTracker:PlayersInActionWithKey("Container",tonumber(storageTag))
					for _,v in PlayerIds do
						pcall(function()
							ActionTracker.ChangePlayerAction(Players:GetPlayerByUserId(v),{["Main"]="Inventory"})
							Remotes.Inventory.forceClose:FireClient(Players:GetPlayerByUserId(v))
						end)
					end
				end

			end
		end
	end
end


function canUseContainer(player)
	local data = {["Passed"]=false}
	local plrAction = ActionTracker.GetAction(player)
	if plrAction.Container then
		local Tag = plrAction.Container
		local container = InventoryManager.Storage.Exists(tostring(Tag))
		-- all checks
		if container ~= false then
			if Links[Tag] then
				if Links[Tag].Value then
					if getDistance(player,Links[Tag].Value) > 7 then
						return data
					end
					if player.Character.Humanoid.Health <= 0 then
						return data
					end
					-- could use raycast...? maybe later,
					-- seems good, lets swap slots.
					data.Passed = true
					data.Tag = Tag
					data.Container = container
					pcall(function()
						data.Container.Settings = nil
					end)
				end
			end
		end
	end
	return data
end


Remotes.Inventory.swapSlots.OnServerInvoke = function(player,slot1,slot2)
	local plrAction = ActionTracker.GetAction(player)
	if plrAction.Main == "Inventory" then
		if Cooldown.Fire(player,"SwapSlots",0.3) == false then task.wait(0.3) end
		local containTag = canUseContainer(player)
		local StorageSettings
		if containTag.Passed == true then
			StorageSettings = InventoryManager.Storage.GetSettings(tostring(containTag.Tag))
		end

		local Passed = false

		local Slot1Subbed = string.sub(slot1,2,-1)
		local Slot2Subbed = string.sub(slot2,2,-1)
		if string.sub(slot1,1,1) == "S" and string.sub(slot2,1,1) == "S" then -- slot1,2 is container

			if StorageSettings.DisableTransfer == true then return true end
			if containTag.Passed ~= false then

				InventoryManager.Storage.SwapSlotsInStorage(tostring(containTag.Tag),tostring(Slot1Subbed),tostring(Slot2Subbed))
				Passed = true
			end

		elseif string.sub(slot2,1,1) == "S" then -- slot2 is container

			if StorageSettings.DisableTransfer == true then return true end
			if containTag.Passed ~= false then

				InventoryManager.Dongle.SwapFromInv2Storage(tostring(containTag.Tag),player,tostring(slot1),tostring(Slot2Subbed))
				Passed = true
			end
		elseif string.sub(slot1,1,1) == "S" then -- slot1 is container

			if containTag.Passed ~= false then
				InventoryManager.Dongle.SwapFromInv2Storage(tostring(containTag.Tag),player,tostring(slot2),tostring(Slot1Subbed))
				Passed = true
			end
		else
			InventoryManager.Dongle.SwapSlots(player,tostring(slot1),tostring(slot2))
			return true
		end

		if Passed == true then
			ContainerUpdate(tostring(containTag.Tag))
			local continInfo = InventoryManager.Storage.GetAllItemsFromStorage(tostring(containTag.Tag))
			local sltM = InventoryManager.Storage.GetSlotAmt(tostring(containTag.Tag))
			local data = {}
			local d =InventoryManager.Storage.GetExtraData(Storage,"Equipment")
			if d == nil then
				d={}
			end
			if StorageSettings.PlayerDroppedBag == true then
				data["Type"]="PlayerBag"
				data["Equipment"]=d
			end
			data["ContainerName"]=Links[containTag.Tag].Value.Name
			data["Values"]=containTag.Container
			data["SlotAmount"]=sltM
			return data
		else
			ActionTracker.ChangePlayerAction(player,{["Main"]="Inventory"})
			Remotes.Inventory.forceClose:FireClient(player)
			return true
		end
	else
		return false
	end

end


Remotes.Gun.getAmmo.OnServerInvoke = function(Player,Tag)
	local TagItems = Items[Tag]
	if TagItems then
		coroutine.wrap(function()
			Remotes.Gun.ammoBack:FireClient(Player,Tag,TagItems.Magazine.Value)
		end)()
		return TagItems.Magazine.Value
	end
end

ReplicatedStorage.Remotes.Inventory.getInventoryContents.OnServerInvoke = function(player,Deception)
	-- redraw
	local data = ActionTracker.GetAction(player)

	if Deception then
		ActionTracker.ChangePlayerAction(player,nil)
	else
		local fnd = false
		if data ~= nil then
			for i,o in data do
				if i == "Container" then
					fnd = true
					break;
				end
			end
		end

		if fnd == false then
			ActionTracker.ChangePlayerAction(player,{["Main"]="Inventory"})
		end
	end
	local d = InventoryManager.Player.GetAllItemsWithinInventory(player)
	return d
end

ReplicatedStorage.Remotes.Inventory.InteractionSystem.OnServerInvoke = function(player,Tag,mouse)
	Cooldown.Fire(player,"Interact",1)
	local container = InventoryManager.Storage.Exists(tostring(Tag))
	print(Tag)
	if container ~= false then
		if Links[Tag] then
			if Links[Tag].Value then
				-- sanity checks
				if player.Character.Humanoid.Health <= 0 then
					return 4
				end
				if ActionTracker.GetAction(player) ~= nil then
					return 3
				end
				local raycastParams = RaycastParams.new()
				local blacklist = {player.Character,player}
				raycastParams.IgnoreWater = true
				raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
				raycastParams.FilterDescendantsInstances = blacklist
				local ray = workspace:Raycast(player.Character.Head.Position, (mouse -player.Character.Head.Position).Unit * 15, raycastParams)
				if ray then
					if ray.Instance == Links[Tag].Value or ray.Instance.Parent == Links[Tag].Value then
						local data = {}
						local Settings = InventoryManager.Storage.GetSettings(tostring(Tag))
						local d =InventoryManager.Storage.GetExtraData(Storage,"Equipment")
						if d == nil then
							d={}
						end
						if Settings.isLocked == true then return end
						if Settings.PlayerDroppedBag == true then
							data["Type"]="PlayerBag"
							data["Equipment"]=d
						else
							data["Type"]=nil
						end
						ActionTracker.ChangePlayerAction(player,{["Main"]="Inventory",["Container"]=Tag})
						local sltM = InventoryManager.Storage.GetSlotAmt(tostring(Tag))
						pcall(function()
							container.Settings = nil
						end)
						data["ContainerName"]=Links[Tag].Value.Name
						data["Values"]=container
						data["SlotAmount"]=sltM
						coroutine.wrap(constantCheck)(player,Links[Tag].Value)
						return data
					end
				end
				return 2


			end
		end
	elseif Items[Tag] then
		if not Items[Tag]:FindFirstChild("Pointer") then return 4 end
		if getDistance(player,Items[Tag].Pointer.Value) > 7 then
			return 3
		end
		if player.Character.Humanoid.Health <= 0 then
			return 4
		end
		if ActionTracker.GetAction(player) ~= nil then
			return 2
		end

		local slot = InventoryManager.Player:GetNewestSlot(player)
		if slot == false then return 5 end

		Items[Tag].Owner.Value = player.UserId
		InventoryManager.Player.AddTagToInventory(player,tostring(slot),Tag)
		Items[Tag].Pointer.Value:Destroy()
		Items[Tag].Pointer:Destroy()

		local Inv = InventoryManager.Player.GetAllItemsWithinInventory(player)

		if tonumber(slot) <= 6 then
			Remotes.ItemSystem.RegisterHotbarItems:FireClient(player,Inv)
		end
		return 69

	end
end

function constantCheck(Player,Object)
	local done = false
	while done == false do

		if getDistance(Player,Object) >= 8 then
			local act = ActionTracker.GetAction(Player)
			if act ~= nil then
				if act["Container"] ~= nil then
					ActionTracker.ChangePlayerAction(Player,{["Main"]="Inventory"})
				end
			end
			Remotes.Inventory.forceClose:FireClient(Player)
			done = true
		end
		wait(.5)
	end
end