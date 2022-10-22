local object			= nil
local dragInput			= nil
local dragStart			= nil
local startPos			= nil
local preparingToDrag	= false
local inputChanged		= nil
local Dragging		= false
local InputBegan = nil
local DragStarted	= nil
local inProg = false
local GlobalRefreshOn = false
local LocalRefresh = false
local InUse = {}

--

local TweenService = game:GetService("TweenService")
local FadeTween = TweenInfo.new(0.1,Enum.EasingStyle.Sine,Enum.EasingDirection.Out)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local Player = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local Remotes = ReplicatedStorage.Remotes
local Inventory = script.Parent.Inventory.InvSlots
local ItemContainer = Inventory.Parent.ItemContainer
local PlayerBag = Inventory.Parent.PlayerInv
local PlayerBagItems = PlayerBag.Items
local PlayerBagEquipment = PlayerBag.Equipped
local ItemInContainer = ItemContainer.Items
local GlobalRefresh = Inventory.Parent.Refresh
local HotBar = script.Parent
local InfoStats = Inventory.Parent.InfoStats
local Icons = require(ReplicatedStorage.Modules.Data).Icons
Inventory.Parent.Player.PlrName.Text = Player.Name
local lclChestData = nil

function Fade(Object)
	for i,v in Object:GetChildren() do
		if v:IsA("Frame") and tonumber(v.Name) ~= nil then
			v.MouseEnter:Connect(function() -- local T = TweenService:Create(v,FadeTween,{BackgroundColor3=Color3.new(0.164706, 0.164706, 0.164706)})
				local T = TweenService:Create(v,FadeTween,{BackgroundColor3=Color3.new(0.278431, 0.278431, 0.278431)}):Play()
			end)
			v.MouseLeave:Connect(function()
				local T = TweenService:Create(v,FadeTween,{BackgroundColor3=Color3.new(0.164706, 0.164706, 0.164706)}):Play()
			end)
		end
	end
end
local Clean = {}
function Clean.Filter(Object,Filter)
	for _,x in Object:GetChildren() do
		pcall(function()
			if not x:IsA(Filter) then
				x:Destroy()
			end
		end)
	end
end


Fade(HotBar)
Fade(Inventory)


function canSwap(v)
	return (table.find(Inventory:GetChildren(),v) or table.find(HotBar:GetChildren(),v) or table.find(ItemInContainer:GetChildren(),v) or table.find(PlayerBagItems:GetChildren(),v))
end

local function update(input)
	local delta 		= input.Position - dragStart
	local newPosition	= UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	object.Position 	= newPosition
	return newPosition
end


function renderHotbar(inventory)
	coroutine.wrap(function()
		local slotUsed = {}
		for _,x in HotBar:GetChildren() do
			pcall(function()
				x.NameTag:Destroy()
			end)
			pcall(function()
				x.Tag:Destroy()
			end)
		end
		for sn,slot in inventory do
			if sn == nil then return end
			if tonumber(sn) == nil then return end
			sn = tonumber(sn)
			local magazine = false
			if sn <= 6 then	
				if slot.Quantity then
					HotBar[sn].Quantity.Visible = true
					HotBar[sn].Quantity.Text = tostring(slot.Quantity)
					magazine = true
				elseif slot.Magazine then
					HotBar[sn].Quantity.Visible = true
					HotBar[sn].Quantity.Text = tostring(slot.Magazine)
					magazine = true
				end
				if magazine == false then
					HotBar[sn].Quantity.Visible = false
				end
				table.insert(slotUsed,tonumber(sn))
				HotBar[sn].ItemName.Text = slot["Name"]
				local tagd = Instance.new("IntValue")
				tagd.Value = slot.Tag
				tagd.Name = "Tag"
				tagd.Parent = HotBar[sn]
				local name = Instance.new("StringValue")
				name.Value = slot["Name"]
				name.Name = "NameTag"
				name.Parent = HotBar[sn]
				local suc, err = pcall(function()
					HotBar[sn].Item.Image = Icons[slot["Name"]]
				end)
				if not suc then
					HotBar[sn].Item.Image = "rbxassetid://5009602968"
					warn("Inventory got an error grabbing an image", err)
				end
				HotBar[sn].Item.Visible = true
			end
		end
		for i=1,6,1 do
			if not table.find(slotUsed,i) then
				for _, item in ipairs(HotBar[tostring(i)]:GetChildren()) do
					pcall(function()
						if item.Name ~= "SlotNum" then
							item.Visible = false
						end
						item.Tag:Destroy()
						item.NameTag:Destroy()

					end)
				end
			end
		end

	end)()
end

function redrawInv(InvContents)
	GlobalRefreshOn = true
	GlobalRefresh.Visible = true
	ItemContainer.Visible = false
	InfoStats.Visible = false
	coroutine.wrap(function()
		while GlobalRefreshOn == true do
			wait(0.02)			
			GlobalRefresh.Rotation += 6
		end
	end)()
	local slotUsed = {}
	-- cleanup
	for _,x in Inventory:GetChildren() do
		pcall(function()
			x.Tag:Destroy()
			x.NameTag:Destroy()
		end)
	end
	Clean.Filter(ItemContainer.Items,"UIGridLayout")
	Clean.Filter(PlayerBagEquipment,"UIGridLayout")
	Clean.Filter(PlayerBagItems,"UIGridLayout")
	Clean.Filter(InfoStats.Buttons,"UIGridLayout")
	for slotNum,item in InvContents do
		if slotNum == nil then return end
		if tonumber(slotNum) == nil then return end
		local magazine = false
		if tonumber(slotNum) > 6 then
			local tString = tostring(slotNum)
			if item.Quantity then
				Inventory[tString].Quantity.Visible = true
				Inventory[tString].Quantity.Text = tostring(item.Quantity)
				magazine = true
			elseif item.Magazine then
				Inventory[tString].Quantity.Visible = true
				Inventory[tString].Quantity.Text = tostring(item.Magazine)
				magazine = true
			end
			if Inventory[tString] then
				if magazine == false then
					Inventory[tString].Quantity.Visible = false
				end
				local Tag = Instance.new("IntValue")
				Tag.Value = item.Tag
				Tag.Name = "Tag"
				Tag.Parent = Inventory[tString]
				local ItemName = Instance.new("StringValue")
				ItemName.Name = "NameTag"
				ItemName.Value = item["Name"]
				ItemName.Parent = Inventory[tString]
				pcall(function()
					Inventory[tString].Item.Image = Icons[item["Name"]]
				end,function(err)
					HotBar[tString].Item.Image = "rbxassetid://5009602968"
				end)
				Inventory[tString].Item.Visible = true
				table.insert(slotUsed,tonumber(slotNum))
			end	
		end
	end
	for i=1,30,1 do
		if not table.find(slotUsed,i) and i > 6 then
			for _, item in ipairs(Inventory[tostring(i)]:GetChildren()) do
				pcall(function()
					item.Visible = false
					item.Tag:Destroy()
					item.NameTag:Destroy()
				end)
			end
		end
	end
	if lclChestData ~= nil then
		if lclChestData.Type and lclChestData.Type == "PlayerBag" then
			-- spawn as playerBag
			PlayerBag.LootableContainerTxt.inv.Text = string.upper(lclChestData.ContainerName)
			for i=0,tonumber(lclChestData.SlotAmount)-1,1 do
				local Slot = ReplicatedStorage.UI.Slot:Clone()
				Slot.Parent = PlayerBagItems
				Slot.Name = string.format("S%s",tostring(i))

				Slot.MouseEnter:Connect(function() -- local T = TweenService:Create(v,FadeTween,{BackgroundColor3=Color3.new(0.164706, 0.164706, 0.164706)})
					local T = TweenService:Create(Slot,FadeTween,{BackgroundColor3=Color3.new(0.278431, 0.278431, 0.278431)}):Play()
				end)
				Slot.MouseLeave:Connect(function()
					local T = TweenService:Create(Slot,FadeTween,{BackgroundColor3=Color3.new(0.164706, 0.164706, 0.164706)}):Play()
				end)
			end
			for i=1,6,1 do
				local Slot = ReplicatedStorage.UI.Slot:Clone()
				Slot.Name = string.format("E%s",tostring(i))
				Slot.Parent = PlayerBagEquipment
				Slot.MouseEnter:Connect(function() -- local T = TweenService:Create(v,FadeTween,{BackgroundColor3=Color3.new(0.164706, 0.164706, 0.164706)})
					local T = TweenService:Create(Slot,FadeTween,{BackgroundColor3=Color3.new(0.278431, 0.278431, 0.278431)}):Play()
				end)
				Slot.MouseLeave:Connect(function()
					local T = TweenService:Create(Slot,FadeTween,{BackgroundColor3=Color3.new(0.164706, 0.164706, 0.164706)}):Play()
				end)
			end

			for slotnm,v in lclChestData.Equipment do
				local Slot = PlayerBagEquipment[string.format("E%s",tostring(slotnm))]
				local magazine = false
				if v.Quantity then
					Slot.Quantity.Visible = true
					Slot.Quantity.Text = tostring(v.Quantity)
					magazine = true
				elseif v.Magazine then
					Slot.Quantity.Visible = true
					Slot.Quantity.Text = tostring(v.Magazine)
					magazine = true
				end
				if magazine == false then
					Slot.Quantity.Visible = false
				end
				local Tag = Instance.new("IntValue")
				Tag.Value = v.Tag
				Tag.Name = "Tag"
				Tag.Parent = Slot
				Slot.Item.Image = Icons[v["Name"]]
				local ItemName = Instance.new("StringValue")
				ItemName.Name = "NameTag"
				ItemName.Value = v["Name"]
				ItemName.Parent = Slot
				Slot.Item.Visible = true
			end

			for slotnm,v in lclChestData.Values do
				local Slot = PlayerBagItems[string.format("S%s",tostring(slotnm))]
				local magazine = false
				if v.Quantity then
					Slot.Quantity.Visible = true
					Slot.Quantity.Text = tostring(v.Quantity)
					magazine = true
				elseif v.Magazine then
					Slot.Quantity.Visible = true
					Slot.Quantity.Text = tostring(v.Magazine)
					magazine = true
				end
				if magazine == false then
					Slot.Quantity.Visible = false
				end
				local Tag = Instance.new("IntValue")
				Tag.Value = v.Tag
				Tag.Name = "Tag"
				Tag.Parent = Slot
				Slot.Item.Image = Icons[v["Name"]]
				local ItemName = Instance.new("StringValue")
				ItemName.Name = "NameTag"
				ItemName.Value = v["Name"]
				ItemName.Parent = Slot
				Slot.Item.Visible = true
			end
			PlayerBag.Visible = true
		else
			ItemContainer.LootableContainerTxt.inv.Text = string.upper(lclChestData.ContainerName)
			for i=0,tonumber(lclChestData.SlotAmount)-1,1 do
				local Slot = ReplicatedStorage.UI.Slot:Clone()
				Slot.Name = string.format("S%s",tostring(i))
				Slot.Parent = ItemInContainer
				Slot.MouseEnter:Connect(function() -- local T = TweenService:Create(v,FadeTween,{BackgroundColor3=Color3.new(0.164706, 0.164706, 0.164706)})
					local T = TweenService:Create(Slot,FadeTween,{BackgroundColor3=Color3.new(0.278431, 0.278431, 0.278431)}):Play()
				end)
				Slot.MouseLeave:Connect(function()
					local T = TweenService:Create(Slot,FadeTween,{BackgroundColor3=Color3.new(0.164706, 0.164706, 0.164706)}):Play()
				end)
			end
			for slotnm,v in lclChestData.Values do
				local Slot = ItemInContainer[string.format("S%s",tostring(slotnm))]
				local magazine = false
				if v.Quantity then
					Slot.Quantity.Visible = true
					Slot.Quantity.Text = tostring(v.Quantity)
					magazine = true
				elseif v.Magazine then
					Slot.Quantity.Visible = true
					Slot.Quantity.Text = tostring(v.Magazine)
					magazine = true
				end
				if magazine == false then
					Slot.Quantity.Visible = false
				end
				local Tag = Instance.new("IntValue")
				Tag.Value = v.Tag
				Tag.Name = "Tag"
				Tag.Parent = Slot
				Slot.Item.Image = Icons[v["Name"]]
				local ItemName = Instance.new("StringValue")
				ItemName.Name = "NameTag"
				ItemName.Value = v["Name"]
				ItemName.Parent = Slot
				Slot.Item.Visible = true
			end
			ItemContainer.Visible = true
		end

	else
		PlayerBag.Visible = false
		ItemContainer.Visible = false
	end

	GlobalRefreshOn = false
	GlobalRefresh.Visible = false
end

Remotes.Inventory.UpdateContents.OnClientEvent:Connect(function(mvT)
	lclChestData = mvT
	coroutine.wrap(function()
		local InvContents = Remotes.Inventory.getInventoryContents:InvokeServer() 
		redrawInv(InvContents,lclChestData)
		renderHotbar(InvContents)
	end)()
end)

Remotes.Inventory.forceClose.OnClientEvent:Connect(function()
	ItemContainer.Visible = false
	lclChestData = nil
	local InvContents = Remotes.Inventory.getInventoryContents:InvokeServer("quick") 
	redrawInv(InvContents)
	renderHotbar(InvContents)
end)

Remotes.Client.Inventory.OpenInventory.OnInvoke = function(chestData)
	if script.Parent.Inventory.Visible == false then
		if Dragging == true then return 0 end
		script.Parent.Inventory.Visible = true
		lclChestData = chestData
		coroutine.wrap(function()
			local InvContents = Remotes.Inventory.getInventoryContents:InvokeServer() 
			redrawInv(InvContents,lclChestData)
			renderHotbar(InvContents)
		end)()

		return true
	else
		if Dragging == true then return 0 end
		lclChestData = nil
		local InvContents = Remotes.Inventory.getInventoryContents:InvokeServer("quick") -- quick, possible error (since closing)
		script.Parent.Inventory.Visible = false
		return false
	end

end

UIS.InputBegan:Connect(function(Input,GPE)
	if Dragging == true then return end
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		local guiObjAtPos = script.Parent.Parent:GetGuiObjectsAtPosition(Input.Position.X,Input.Position.Y)
		for i,FirstObjectGrabbed in pairs(guiObjAtPos) do
			if canSwap(FirstObjectGrabbed) and FirstObjectGrabbed:FindFirstChild("Item") then
				if ReplicatedStorage.Items:FindFirstChild(FirstObjectGrabbed.NameTag.Value) then
					for _,x in InfoStats.Buttons:GetChildren() do
						if not x:IsA("UIGridLayout") then
							x:Destroy()
						end
					end
					if ReplicatedStorage.Items[FirstObjectGrabbed.NameTag.Value]:FindFirstChild("UI") then
						local Repl = ReplicatedStorage.Items[FirstObjectGrabbed.NameTag.Value].UI
						InfoStats.ItemImage.Image = Icons[FirstObjectGrabbed.NameTag.Value]
						if Repl:FindFirstChild("Description") then
							InfoStats.Description.Text = Repl.Description.Value
						else
							InfoStats.Description.Text = "This item does not have a description."
						end
					end
					local Drop = ReplicatedStorage.UI.ExampleButton:Clone()
					Drop.Name = "Drop"
					Drop.MouseButton1Click:Connect(function()
						print("Lol drop")
					end)
					Drop.Parent = InfoStats.Buttons
					InfoStats.ItemImage.Image = "rbxassetid://6034452653"
					InfoStats.ItemName.Text = FirstObjectGrabbed.NameTag.Value
					InfoStats.Visible = true
				end
				if Dragging == true or preparingToDrag == true then return false end
				object = FirstObjectGrabbed.Item
				object.ZIndex = 3
				local objCopy = object.Image
				local objVisible = object.Visible
				local objTxtVis = object.Parent.Quantity.Visible
				local objTxtCopy = object.Parent.Quantity.Text
				preparingToDrag = true
				local connection 
				connection = Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End and (Dragging or preparingToDrag) then
						Dragging = false
						if preparingToDrag == false then
							inputChanged:Disconnect()
							object.ZIndex = 2
						end
						coroutine.wrap(function()
							for i,SecondObjectGrabbed in pairs(script.Parent.Parent:GetGuiObjectsAtPosition(Input.Position.X,Input.Position.Y)) do
								if canSwap(SecondObjectGrabbed) then
									if tonumber(SecondObjectGrabbed.Name) == nil and tonumber(string.sub(SecondObjectGrabbed.Name,2,-1)) == nil then return false end


									if SecondObjectGrabbed.Item.Image.ImageColor3 == Color3.new(0,0,0) or object.ImageColor3 == Color3.new(0,0,0) then return end 
									if object.Parent.Name == SecondObjectGrabbed.Name then return end
									if table.find(InUse,SecondObjectGrabbed.Name) or table.find(InUse,SecondObjectGrabbed.Parent.Name) then return end
									if not object.Parent:FindFirstChild("Tag") then return end
									table.insert(InUse,SecondObjectGrabbed.Name)
									table.insert(InUse,object.Parent.Name)
									LocalRefresh = true
									local objectRefresh = ReplicatedStorage.UI.Refresh:Clone()
									objectRefresh.ZIndex = 1000
									objectRefresh.Visible = true
									objectRefresh.Parent = object.Parent

									local vItemRefresh = ReplicatedStorage.UI.Refresh:Clone()
									vItemRefresh.ZIndex = 1000
									vItemRefresh.Visible = true
									vItemRefresh.Parent = SecondObjectGrabbed

									coroutine.wrap(function()
										while LocalRefresh == true do
											wait(0.02)
											objectRefresh.Rotation += 6
											vItemRefresh.Rotation += 6
										end
									end)()				
									--cpy data
									local SecondObjectGrabbedCp = SecondObjectGrabbed:Clone()
									local vItemCopy = SecondObjectGrabbed.Item.Image
									local vTextCopy = SecondObjectGrabbed.Quantity.Text
									local vCapVis = SecondObjectGrabbed.Quantity.Visible
									local vItemVis = SecondObjectGrabbed.Item.Visible
									object.Image = vItemCopy
									object.Visible = vItemVis
									object.Parent.Quantity.Text = vTextCopy
									object.Parent.Quantity.Visible = vCapVis

									SecondObjectGrabbed.Item.Image = objCopy
									SecondObjectGrabbed.Quantity.Text = objTxtCopy
									SecondObjectGrabbed.Quantity.Visible = objTxtVis
									SecondObjectGrabbed.Item.Visible = objVisible
									--
									inProg = true
									SecondObjectGrabbed.Item.ImageColor3 = Color3.new(0,0,0)
									object.ImageColor3 = Color3.new(0,0,0)
									local mv = Remotes.Inventory.swapSlots:InvokeServer(object.Parent.Name,SecondObjectGrabbed.Name)
									pcall(function()
										object.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset)
										pcall(function()
											local NicolasKage = Remotes.Client.Inventory.getEquippedItem:Invoke()
											if NicolasKage == SecondObjectGrabbed.Tag.Value or NicolasKage == object.Parent.Tag.Value then
												coroutine.wrap(function()
													Remotes.Client.Inventory.deEquip:Invoke()
												end)()
											end
										end)
										pcall(function()
											if not SecondObjectGrabbed.Tag or not object.Parent.Tag then
												coroutine.wrap(function()
													Remotes.Client.Inventory.deEquip:Invoke()
												end)()
											end
										end)
									end)
									SecondObjectGrabbed.Item.ImageColor3 = Color3.new(1,1,1)
									object.ImageColor3 = Color3.new(1,1,1)
									if mv ~= false and mv ~= true then
										lclChestData = mv
									end
									vItemRefresh:Destroy()
									objectRefresh:Destroy()
									InUse = {}
									LocalRefresh = false
									local InvContents = Remotes.Inventory.getInventoryContents:InvokeServer()
									redrawInv(InvContents)
									renderHotbar(InvContents)
									inProg = false
								end
							end
						end)()
						pcall(function()
							object.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset)
						end)
						object.ZIndex = 2
						preparingToDrag = false
						inputChanged:Disconnect()
						connection:Disconnect()
					end
				end)
				inputChanged = UIS.InputChanged:Connect(function(input)
					if object.Parent == nil then
						return
					end
					if preparingToDrag then
						preparingToDrag = false
						Dragging	= true
						dragStart 	= input.Position
						startPos 	= object.Position
					end
					if Dragging == true then
						local newPosition = update(input)
					end
				end)

			end
		end
	end
end)

Remotes.Client.Inventory.GetTagFromHotbar.OnInvoke = function(Slot)
	coroutine.wrap(function()
		for slotNm,x in HotBar:GetChildren() do
			if x:IsA("Frame") and tonumber(slotNm) ~= nil then
				x.BackgroundColor3 = Color3.new(0.164706, 0.164706, 0.164706)
			end
		end
		HotBar[Slot].BackgroundColor3 = Color3.new(0.054902, 0.282353, 0.0156863)
	end)()
	if HotBar[Slot]:FindFirstChild("Tag") then
		return {[1]=HotBar[Slot].Tag.Value,[2]=HotBar[Slot].NameTag.Value}
	end
end

Remotes.ItemSystem.RegisterHotbarItems.OnClientEvent:Connect(function(inventory)
	renderHotbar(inventory)
end)

Remotes.Gun.ammoBack.OnClientEvent:Connect(function(tag,val)
	for _,itm in ipairs(HotBar:GetChildren()) do
		if itm:isA("Frame") then
			if itm:FindFirstChild("Tag") then
				if itm.Tag.Value == tag then
					itm.Quantity.Text = tostring(val)
					return true
				end
			end
		end
	end
end)

Remotes.Client.UI.GetItemCapacity.OnInvoke = function(tag,val)
	for _,itm in ipairs(HotBar:GetChildren()) do
		if itm:isA("Frame") then
			if itm:FindFirstChild("Tag") then
				if itm.Tag.Value == tag then
					return itm.Quantity.Text
				end
			end
		end
	end
	return false
end