local Player = game:GetService("Players").LocalPlayer

local TweenService =game:GetService("TweenService")
local TweenOut = TweenInfo.new(0.09,Enum.EasingStyle.Sine,Enum.EasingDirection.Out)

local Mouse = Player:GetMouse()
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Hit = script.Parent.HitLabel
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AS = game:GetService("SoundService")
local HitMarker = script.Parent.HitMarker
local HitMarkerHead = script.Parent.HitMarkerHead
local lkatobj = false
local OutlineCopy = nil
local Action = script.Parent.action
local ActionImage = script.Parent.actionImage

local InventoryOpen = false

function getDistance(Player,Object)
	if Object:IsA("Model") then
		return (Object.PrimaryPart.Position - Player.Character.LowerTorso.Position).Magnitude
	else
		return (Object.Position - Player.Character.LowerTorso.Position).Magnitude
	end	
end

ReplicatedStorage.Remotes.Client.UI.ShowCenter.Event:Connect(function(torf)
	script.Parent.Center.Visible = torf
end)

ReplicatedStorage.Remotes.Core.Hitmarker.OnClientEvent:Connect(function(head)
	Hit.Size = UDim2.new(1, 0,0.02, 0)
	Hit.Visible = true
	local Size
	if head == true then
		Hit.ImageColor3 = Color3.new(1,0,0.2)
		Size = UDim2.new(1, 0,0.04, 0) -- 0.04
		AS:PlayLocalSound(HitMarkerHead)

	else
		Hit.ImageColor3 = Color3.new(1,1,1)

		Size = UDim2.new(1, 0,0.03, 0)
		AS:PlayLocalSound(HitMarker)
	end
	local T = TweenService:Create(Hit,TweenOut,{Size=Size})
	T:Play()
	T.Completed:Wait()
	Hit.Size = UDim2.new(1, 0,0.025, 0)
	Hit.Visible = false
end)

RunService:BindToRenderStep("MouseHover", Enum.RenderPriority.Camera.Value - 1, function()
	if lkatobj == false and OutlineCopy ~= nil then
		OutlineCopy.Visible = false
		OutlineCopy = nil
	end

	local Target = Mouse.Target
	if Target == nil then return end
	local Tag = Target.Parent:FindFirstChild("Tag") or Target:FindFirstChild("Tag")
	if (Target and Target.Parent) and Tag ~= nil then
		if Tag.Parent.Parent.Parent.Name == "Harvestable" then return end
		if getDistance(Player,Tag.Parent) <= 7 then
			-- we are dealing with an enemy stand user!
			if _G.InInv == true then return end 
			if Tag.Parent.Name ~= "Harvestable" then
				lkatobj = true
				if Target:FindFirstChild("Outline") then
					Target.Outline.Visible = true
					OutlineCopy = Target.Outline
				end
				Action.Visible = true
				Action.Text = string.format("Press F to Open")
				ActionImage.Visible = true
			end
		else
			lkatobj = false
			Action.Visible = false
			ActionImage.Visible = false
		end
	else
		lkatobj = false
		Action.Visible = false
		ActionImage.Visible = false
	end
end)