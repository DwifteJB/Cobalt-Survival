local timer = os.clock()

local TweenService = game:GetService("TweenService")

local FadeTweenInfo = TweenInfo.new(1,Enum.EasingStyle.Linear)

local player = game:GetService("Players").LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid",5)
local HP_Frame = script.Parent.Back.HP_BG.BAROFHOLDING.BAR_AMT
local THIRST_Frame = script.Parent.Back.THIRST_BG.BAROFHOLDING.BAR_AMT
local HUNGER_Frame = script.Parent.Back.HUNGER_BG.BAROFHOLDING.BAR_AMT
local HP_Text = script.Parent.Back.HP_BG.TextLabel
local THIRST_Text = script.Parent.Back.THIRST_BG.TextLabel
local HUNGER_Text = script.Parent.Back.HUNGER_BG.TextLabel

local VM = script.Parent.ViewportFrame
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Icons = require(ReplicatedStorage.Modules.Data).Icons
local ItemContainer = ReplicatedStorage.UI.ItemContainer
local Remotes = ReplicatedStorage.Remotes
local ItemAdded = script.Parent.ItemsAdded

Humanoid.HealthChanged:Connect(function()
	local amt
	if Humanoid.Health < 0 then
		amt = 0 / Humanoid.MaxHealth
	else
		 amt = Humanoid.Health / Humanoid.MaxHealth
	end
	if Humanoid.Health >= 50 then
		script.Parent.Blood.ImageTransparency = Humanoid.Health / 100
	end
	local TS= TweenService:Create(HP_Frame,TweenInfo.new(Humanoid.Health / 100,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Size=UDim2.new(amt,0,1,0)}):Play()
	HP_Text.Text = tostring(Humanoid.Health)
end)
Humanoid.Died:Connect(function()
	HUNGER_Frame.Size = UDim2.new(0,0,1,0)
	THIRST_Frame.Size = UDim2.new(0,0,1,0)
	THIRST_Text.Text = tostring(0)
	HUNGER_Text.Text = tostring(0)
end)
Remotes.Core.UpdateHungerThirst.OnClientEvent:Connect(function(maxHunger,maxThirst,Thirst,Hunger)
	local TS= TweenService:Create(HUNGER_Frame,TweenInfo.new((maxHunger-Hunger)/ 100,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Size=UDim2.new(Hunger/maxHunger,0,1,0)}):Play()
	local TS2= TweenService:Create(THIRST_Frame,TweenInfo.new((maxThirst-Thirst)/ 100,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Size=UDim2.new(Thirst/maxThirst,0,1,0)}):Play()
	THIRST_Text.Text = tostring(Thirst)
	HUNGER_Text.Text = tostring(Hunger)

end)


function waitToClose(uiElement)
	TweenService:Create(uiElement,FadeTweenInfo,{BackgroundTransparency=1}):Play()
	for i,v in uiElement:GetChildren() do
		if v:IsA("Frame") then
			TweenService:Create(v,FadeTweenInfo,{BackgroundTransparency=1}):Play()
		elseif v:IsA("TextLabel") then
			TweenService:Create(v,FadeTweenInfo,{TextTransparency=1}):Play()
		elseif v:IsA("ImageLabel") then
			TweenService:Create(v,FadeTweenInfo,{ImageTransparency=1,BackgroundTransparency=1}):Play()
		
		end
	end
	wait(FadeTweenInfo.Time)
	uiElement:Destroy()
end

function addItem(itemName,itemAmount,itemImage)
	local Item = ItemContainer:Clone()
	Item.ITEM_NAME.Text = itemName
	Item.ITEM_AMOUNT.Text = string.format("X%s",tostring(itemAmount))
	Item.ITEM_IMAGE.Image = Icons[itemName]
	Item.Parent = ItemAdded
	return coroutine.wrap(waitToClose)(Item)
end

Remotes.Core.ItemAdded.OnClientEvent:Connect(function(itemname,itemamount,itemimage)
	addItem(itemname,itemamount,itemimage)
end)
coroutine.wrap(function()
	while task.wait(1) do
		pcall(function()
			if player.Character.HumanoidRootPart.Velocity.Magnitude > 10 then
				VM.Visible = true
			else
				VM.Visible = false
			end
		end)
	end
end)()