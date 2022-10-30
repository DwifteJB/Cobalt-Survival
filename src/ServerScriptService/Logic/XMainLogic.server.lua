--[[
		Main Server Script
		Written by Dwifte
]]--
local ServerStorage = game:GetService("ServerStorage")

local Tags = Instance.new("Folder")
Tags.Name = "Tags"
Tags.Parent = ServerStorage
-- WHERE ANY ITEMS WILL LAY!!!
local Items = Instance.new("Folder")
Items.Name = "Items"
Items.Parent = Tags

local Links = Instance.new("Folder")
Links.Name = "LinkedContainers"
Links.Parent = Tags


local PPos = Instance.new("Folder")
PPos.Name = "PlayerPos"

local playerRotations = {}

local MarketPlaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Remotes = ReplicatedStorage.Remotes
local players = game:GetService("Players")
local PlayerEvents = script.Parent.PlayerEvents

local DataManager = require(script.Parent:WaitForChild("Modules"):WaitForChild("DataManager"))
local Cooldown = require(script.Parent:WaitForChild("Modules"):WaitForChild("CooldownSystem"))

function StopAnimation(Humanoid)
	for _,v in pairs(Humanoid:GetPlayingAnimationTracks()) do
		v:Stop()
	end
end


function CanCollide(Model, Variable)
	for _,v in pairs(Model:GetChildren()) do
		if v:IsA("BasePart") then
			v.CanCollide = Variable
		end
		if #v:GetChildren() >= 1 then
			CanCollide(v, Variable)
		end
	end
end
function Transparency(Model, Variable)
	for _,v in pairs(Model:GetChildren()) do
		if v:IsA("BasePart") then
			v.Transparency = Variable
		end
		if #v:GetChildren() >= 1 then
			Transparency(v, Variable)
		end
	end
end

PlayerEvents.PlayerAdded.Event:Connect(function(player)

	if MarketPlaceService:UserOwnsGamePassAsync(player.UserId,78573237) == true or player:GetRankInGroup(15771966) >= 3 then
		print("white listed.")
	else
		player:Kick("get out bozo")
	end

end)

PlayerEvents.CharacterAdded.Event:Connect(function(player,character)
	-- add custom cosmetics, if special :)
	character.Archivable = true
	if ReplicatedStorage.Clothing:FindFirstChild(player.Name) then
		for _,v in character:GetChildren() do
			if (v:IsA("Hat") or v:IsA("Accessory")) and v.Name ~= "Beard" then
				v:Destroy()
			end
		end
		for _,v in ReplicatedStorage.Clothing:FindFirstChild(player.Name):GetChildren() do
			local clone = v:Clone()
			clone.Parent = character
		end
	end
end)

PlayerEvents.PlayerDied.Event:Connect(function(player)
	print(player.Name.." died!")
	pcall(function()
			if not PPos:FindFirstChild(tostring(player.UserId)) then
				PPos[tostring(player.UserId)].CFPos.Value = CFrame.new(0,0,0)
			end
		end)

		local data = DataManager.CombatLog.GetAllRecipientData(player)
		local cnt =0
		for _,_ in data do
			cnt+=1
		end
		print(#data)
		if data[cnt]["AttackerDetails"]["ID"] then
			print(data[#cnt]["AttackerDetails"]["ID"],"killadd")
			DataManager.Statistics.AddValueToStat(data[#cnt]["AttackerDetails"]["ID"],"Kills",1)
			DataManager.Statistics.AddToGlobalStat("Kills",1)
		end
		if player.Character.RightHand:FindFirstChild("ToolMotor6D") then
			player.Character.RightHand:FindFirstChild("ToolMotor6D").Part1.Parent:Destroy()
			player.Character.RightHand:FindFirstChild("ToolMotor6D"):Destroy()
		end
end)



Remotes.Core.PlayAnimation.OnServerEvent:Connect(function(player,animation,Tag)
	if animation == "Stop" then
		if player.Character.RightHand:FindFirstChild("ToolMotor6D") ~= nil then
			--print(player.Character.RightHand:FindFirstChild("ToolMotor6D").Part1)
			player.Character.RightHand:FindFirstChild("ToolMotor6D").Part1.Parent:Destroy()
			player.Character.RightHand:FindFirstChild("ToolMotor6D"):Destroy()
		end
		StopAnimation(player.Character.Humanoid)
		return
	end
	local Weapon = Items[Tag]
	if Weapon ~= nil then
		if player.Character.RightHand:FindFirstChild("ToolMotor6D") ~= nil then
			--print(player.Character.RightHand:FindFirstChild("ToolMotor6D").Part1)
			player.Character.RightHand:FindFirstChild("ToolMotor6D").Part1.Parent:Destroy()
			player.Character.RightHand:FindFirstChild("ToolMotor6D"):Destroy()
			for _,x in player.Character:GetChildren() do
				if table.find({"LeftLowerArm","RightLowerArm","RightHand","LeftHand"},x.Name) then
					CanCollide(x,false)
				end
			end
		end
		local ViewModel = ReplicatedStorage.ViewModels[Weapon.NameTag.Value]
		local weapon = ViewModel[Weapon.NameTag.Value]:Clone()
		weapon.Name = Weapon.NameTag.Value
		CanCollide(weapon,false)
		for _,x in player.Character:GetChildren() do
			if table.find({"LeftLowerArm","RightLowerArm","RightHand","LeftHand"},x.Name) then
				CanCollide(x,false)
			end
		end
		weapon.Parent = player.Character.RightHand
		local Motor6D = Instance.new("Motor6D")
		Motor6D.Part0 = player.Character.RightHand
		Motor6D.Part1 = weapon.PrimaryPart
		Motor6D.Name = "ToolMotor6D"
		Motor6D.Parent = player.Character.RightHand

		local Anim = player.Character.Humanoid:LoadAnimation(ViewModel.ServerAnimations[animation])
		Anim:Play()
		Anim.Stopped:Connect(function()
			player.Character.Humanoid:LoadAnimation(ViewModel.ServerAnimations.Idle):Play()
		end)
	end
end)

local TI = TweenInfo.new(0.05,Enum.EasingStyle.Sine,Enum.EasingDirection.Out)
local Lean = TweenInfo.new(0.1,Enum.EasingStyle.Sine,Enum.EasingDirection.Out)
Remotes.Core.LeanPlayer.OnServerInvoke = function(player,rot)
	if rot ~= false then
		if Cooldown.Fire(player,"Lean",0.3) == false then return false end
	end
	if not PPos:FindFirstChild(tostring(player.UserId)) then
		local PPF = Instance.new("Folder")
		PPF.Name = tostring(player.UserId)
		PPF.Parent = PPos
		
		
		local PPOSS = Instance.new("CFrameValue")
		PPOSS.Value = CFrame.new(0,0,0)
		PPOSS.Name = "CFPos"
		PPOSS.Parent = PPos[tostring(player.UserId)]
	end
	if rot == 1 then
		-- enable rotation
		local goal2 = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.asin(math.rad(20))) 
		TweenService:Create(PPos[tostring(player.UserId)].CFPos, Lean, {Value=goal2}):Play()

	elseif rot == 2 then
		local goal2 = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.asin(math.rad(-20))) 
		TweenService:Create(PPos[tostring(player.UserId)].CFPos, Lean, {Value=goal2}):Play()
	else
		local goal2 = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.asin(math.rad(0))) 
		TweenService:Create(PPos[tostring(player.UserId)].CFPos, Lean, {Value=goal2}):Play()
	end
end



Remotes.Core.ReplicateRotation.OnServerEvent:Connect(function(player,WaistC2)
	local chckAmount = 0.00001 + (#players:GetPlayers() * 0.000002)
	if playerRotations[player.UserId] == nil then
		playerRotations[player.UserId]={}
		playerRotations[player.UserId]["C2"]=WaistC2
	end
	if (WaistC2 - playerRotations[player.UserId]["C2"]) >= chckAmount or (WaistC2 - playerRotations[player.UserId]["C2"]) <= -chckAmount then
		playerRotations[player.UserId]["C2"] = WaistC2
	end

end) 

RunService.Stepped:Connect(function()
	for _,player in players:GetPlayers() do
		if player.Character then
			pcall(function()
				if PPos:FindFirstChild(tostring(player.UserId)) then
					if PPos[tostring(player.UserId)]:FindFirstChild("CFPos") then
						-- PPos[player.UserId].CFPos
						TweenService:Create(player.Character.UpperTorso.Waist, TI, {C0=CFrame.new(0, 0, 0) * CFrame.Angles(playerRotations[player.UserId]["C2"], 0, 0) * PPos[player.UserId]:FindFirstChild("CFPos").Value,C1=CFrame.new(0, -player.Character.UpperTorso.Size.Y/2, 0)}):Play()
						return
					end
				end
				if playerRotations[player.UserId] then
					if playerRotations[player.UserId]["C2"] then
						--CFrame.new(0, 0, 0) * CFrame.Angles(playerRotations[player.UserId]["C2"], 0, 0)
						TweenService:Create(player.Character.UpperTorso.Waist, TI, {C0=CFrame.new(0, 0, 0) * CFrame.Angles(playerRotations[player.UserId]["C2"], 0, 0),C1=CFrame.new(0, -player.Character.UpperTorso.Size.Y/2, 0)}):Play()
					end
				end
			end)
		end
	end

end)

Remotes.Core.Jump.OnServerEvent:Connect(function(player)
	if Cooldown.Fire(player,"Jump",1) == false then return end
	player.Character.Humanoid.JumpPower = 43
	player.Character.Humanoid.Jump = true
	wait()
	player.Character.Humanoid.JumpPower = 0
end)