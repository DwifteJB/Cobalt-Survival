--[[
		Main Player Script
		Written by Dwifte
]]--
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local starterGui = game:GetService("StarterGui")
local RS = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CSShoot = require(script.Shooting.ClientSideShooting)
local General = require(script.Parent.Modules.General)

local ControlsBegan = script.Parent.Bindable.Controls.Began
local ControlsEnded = script.Parent.Bindable.Controls.Ended


local Remotes = ReplicatedStorage.Remotes


-- cam stuff
local Camera = workspace.CurrentCamera
local viewModelOffset = Instance.new("CFrameValue")
viewModelOffset.Value = CFrame.new(0,-1.5,0)
local aimOff = Instance.new("CFrameValue")
aimOff.Value = CFrame.new(0,0,0)
local LeanOff = Instance.new("CFrameValue")
LeanOff.Value = CFrame.new(0,0,0)
local SwayOffset = CFrame.new()
local SwayMultiplier = 1
local AimSwayMultiplier = 0.05
local lastCameraCF = workspace.CurrentCamera.CFrame

local mouse = player:GetMouse()
player.CameraMode = Enum.CameraMode.LockFirstPerson
mouse.TargetFilter = workspace.Camera
--

-- Tween Data
local LeanTween = TweenInfo.new(0.21,Enum.EasingStyle.Sine,Enum.EasingDirection.Out)
local AimTween = TweenInfo.new(0.2,Enum.EasingStyle.Sine,Enum.EasingDirection.Out)
local SprintTween = TweenInfo.new(0.2,Enum.EasingStyle.Sine,Enum.EasingDirection.Out)

local AimFinished=false

-- spring stuff
local Spring = require(ReplicatedStorage.Modules.spring)
local RCSpring = Spring:create()
local BobbingSpring = Spring:create()
local GunRCSpring = Spring:create()
--


-- game vals, prevent false anti-cheat executions+allow smooth gameplay
local CurrentWeapon
local isToolReady
local isMelee
local aiming = false
local heldMouse1 = false
local dead = false 
local reloading = false
local QLean = nil
local ELean = nil
local MeleeThrow = false
local BeforeLeanCF
--

--[[

							FUNCTIONS 

]]


local RenderStepped = {}
function RenderStepped.CurrentWeapon(delta)
	local GunRCSpringUpdate = GunRCSpring:update(delta)
	local GunBobUpdate = BobbingSpring:update(delta)
	local updatedRecoilSpring = RCSpring:update(delta)	
	if CurrentWeapon and CurrentWeapon.Parent then
		CurrentWeapon.Humanoid.PlatformStand = true
		CurrentWeapon.Humanoid.AutoRotate = false
		CurrentWeapon.Humanoid.AutoJumpEnabled = false
		CurrentWeapon.Humanoid.UseJumpPower = false
		local rotation = Camera.CFrame:ToObjectSpace(lastCameraCF)
		local x,y,z = rotation:ToOrientation()
		if aiming == false then
			local bob = Vector3.new(Bob(10),Bob(5),Bob(5))
			BobbingSpring:shove(bob / 10 * (player.Character.HumanoidRootPart.Velocity.Magnitude / 10))
			SwayOffset = SwayOffset:Lerp(CFrame.Angles(math.sin(x)*SwayMultiplier,math.sin(y)*SwayMultiplier,0),0.1)
		else
			if AimFinished then
				local offset3 = CurrentWeapon[CurrentWeapon.Name].Aim.CFrame:toObjectSpace(CurrentWeapon.PrimaryPart.CFrame)
				viewModelOffset.Value = offset3
				AimFinished=false
			end
			SwayOffset = SwayOffset:Lerp(CFrame.Angles(math.sin(x)*AimSwayMultiplier,math.sin(y)*AimSwayMultiplier,0),0.1)
		end

		--[[if QLean == true or ELean == true then
			local offset3 = CurrentWeapon[CurrentWeapon.Name].Aim.CFrame:toObjectSpace(CurrentWeapon.PrimaryPart.CFrame)
			local Tween = TweenService:Create(viewModelOffset,AimTween,{Value=offset3})
			Tween:Play()
		end]]

		CurrentWeapon:SetPrimaryPartCFrame(workspace.Camera.CFrame * viewModelOffset.Value * CFrame.new(GunBobUpdate.Y,GunBobUpdate.X,0)*SwayOffset*CFrame.Angles(math.rad(GunRCSpringUpdate.Y),0,0)) --CFrame.Angles(math.rad(GunBobUpdate.Y),math.rad(GunBobUpdate.X),math.rad(GunBobUpdate.Z))
		Camera.CFrame *= CFrame.Angles(math.rad(updatedRecoilSpring.x),math.rad(updatedRecoilSpring.y),math.rad(updatedRecoilSpring.z)) * LeanOff.Value
		lastCameraCF = workspace.CurrentCamera.CFrame
		if QLean == true or ELean == true then
			CurrentWeapon[CurrentWeapon.Name].Aim.CFrame = Camera.CFrame
		end

	end
end

function Bob(addition) 
	return math.sin(tick() * addition * 1.3) * 0.65 -- increase multipl for faster bobbing
end

function resetVals()
	heldMouse1 = false
	isToolReady = false
	isMelee = nil
	aiming = false
	reloading = false
	viewModelOffset.Value = CFrame.new(0,-1.5,0)
	MeleeThrow = false
	Remotes.Melee.prepareThrow:InvokeServer(false)
	Remotes.Client.UI.ShowCenter:Fire(false)
end

function renderDead()
	dead = true
	resetVals()
	if CurrentWeapon then
		CurrentWeapon:Destroy()
		CurrentWeapon = nil
	end
end

function deEquip()
	resetVals()
	SendAnimationToServer("Stop")
	if CurrentWeapon then
		CurrentWeapon:Destroy()
		CurrentWeapon = nil
	end

end

function SendAnimationToServer(animlol)
	if CurrentWeapon == nil then
		Remotes.Core.PlayAnimation:FireServer(animlol)
	else
		Remotes.Core.PlayAnimation:FireServer(animlol,CurrentWeapon.Tag.Value)
	end

end

function doRay()
	local yes = Remotes.Melee.ValidateRaycast:InvokeServer(player:GetMouse().Hit.Position,CurrentWeapon.Tag.Value)
	if yes == 1 then
		deEquip()
	end
end

function EquipItem(KeyCode)
	local ItemDetails = Remotes.Client.Inventory.GetTagFromHotbar:Invoke(KeyCode)
	if ItemDetails == nil then
		deEquip()
		return
	end
	local name = ItemDetails[2]
	local tag = ItemDetails[1]
	local Tool = ReplicatedStorage.Items[name]
	if Tool.Tool.Value == true and reloading == false and dead == false then
		if CurrentWeapon and CurrentWeapon.Parent then 
			CurrentWeapon:Destroy()
		end

		resetVals()
		
		local ViewModel = ReplicatedStorage.ViewModels[name]
		CurrentWeapon = ViewModel:Clone()
		if Tool:FindFirstChild("Melee") then
			isMelee = Tool.Melee.Value
		else
			isMelee = false
		end

		local tagVal = Instance.new("IntValue")
		tagVal.Name = "Tag"
		tagVal.Value = tag
		tagVal.Parent = CurrentWeapon
		CurrentWeapon.PrimaryPart.Anchored = true
		General.CanCollide(CurrentWeapon, false)
		CurrentWeapon.Parent = workspace.Camera
		local Equip
		local Idle
		if isMelee == false and Tool:FindFirstChild("Recoil") then
			local Ammo = Remotes.Gun.getAmmo:InvokeServer(CurrentWeapon.Tag.Value)
			if CurrentWeapon.Name == "Crossbow" then
				if Ammo <= 0 then
					CurrentWeapon[CurrentWeapon.Name].Arrow.Transparency = 1
					Equip = CurrentWeapon.Humanoid:LoadAnimation(ViewModel.ClientAnimations.Alternative.Equip)
					Idle = CurrentWeapon.Humanoid:LoadAnimation(ViewModel.ClientAnimations.Alternative.Idle)
				else
					CurrentWeapon[CurrentWeapon.Name].Arrow.Transparency = 0
					Equip = CurrentWeapon.Humanoid:LoadAnimation(ViewModel.ClientAnimations.Equip)
					Idle = CurrentWeapon.Humanoid:LoadAnimation(ViewModel.ClientAnimations.Idle)
				end
			else
				Equip = CurrentWeapon.Humanoid:LoadAnimation(ViewModel.ClientAnimations.Equip)
				Idle = CurrentWeapon.Humanoid:LoadAnimation(ViewModel.ClientAnimations.Idle)
			end
		else
			Equip = CurrentWeapon.Humanoid:LoadAnimation(ViewModel.ClientAnimations.Equip)
			Idle = CurrentWeapon.Humanoid:LoadAnimation(ViewModel.ClientAnimations.Idle)
		end
		Equip:Play()
		SendAnimationToServer("Equip")
		Equip.Stopped:Connect(function()
			isToolReady = true
			Idle.Looped = true
			Idle:Play()
			SendAnimationToServer("Idle")
		end)
	end
end

--[[

							Player Stuff 

]]


player.CharacterRemoving:Connect(function(character)
	renderDead()
end)

player.CharacterAdded:Connect(function(character)
	dead = false
end)

--[[

								Remotes
					

]]

Remotes.Client.Inventory.deEquip.OnInvoke = function()
	deEquip()
end

Remotes.Inventory.deEquip.OnClientEvent:Connect(function()
	deEquip()
end)

Remotes.Client.Inventory.getEquippedItem.OnInvoke = function()
	if CurrentWeapon then
		return CurrentWeapon.Tag.Value
	else
		return false
	end
end


--[[

							UserInputService

]]

ControlsBegan.Equip.Event:Connect(function(KeyCode)
	EquipItem(KeyCode)
end)

ControlsBegan.LeftLean.Event:Connect(function()
	if aiming == true and isMelee == false then
		if ELean == true then
			ELean = false
			local T2 = TweenService:Create(LeanOff,LeanTween,{Value = CFrame.new(0,0,0)*CFrame.Angles(0,0,0)})
			T2:Play()
			Remotes.Core.LeanPlayer:InvokeServer(false)
			T2.Completed:Wait()
		end
		local leanVal = Remotes.Core.LeanPlayer:InvokeServer(1)
		if leanVal == false then
			Remotes.Core.LeanPlayer:InvokeServer(false)
			local T2 = TweenService:Create(LeanOff,LeanTween,{Value = CFrame.new(0,0,0)})
			T2:Play()
			return
		end
		local T2 = TweenService:Create(LeanOff,LeanTween,{Value = CFrame.new(-0.5,-0.05,0)*CFrame.Angles(0,0,math.asin(math.rad(25)))})
		T2:Play()
		QLean = true
	end
end)

ControlsBegan.RightLean.Event:Connect(function()
	if aiming == true and isMelee == false then
		if QLean == true then
			QLean = false
			local T2 = TweenService:Create(LeanOff,LeanTween,{Value = CFrame.new(0,0,0)})
			T2:Play()
			Remotes.Core.LeanPlayer:InvokeServer(false)
			T2.Completed:Wait()
		end
		local leanVal = Remotes.Core.LeanPlayer:InvokeServer(2)
		if leanVal == false then
			Remotes.Core.LeanPlayer:InvokeServer(false)
			local T2 = TweenService:Create(LeanOff,LeanTween,{Value = CFrame.new(0,0,0)*CFrame.Angles(0,0,0)})
			T2:Play()
			--correct
			return
		end
		ELean = true
		local T2 = TweenService:Create(LeanOff,LeanTween,{Value = CFrame.new(0.5,-0.05,0)*CFrame.Angles(0,0,math.asin(math.rad(-25)))})
		T2:Play()

	end
end)

ControlsBegan.Sprint.Event:Connect(function()
	if _G.InInv == false and aiming == false then
		local Properties = {FieldOfView = 95}
		local T = TweenService:Create(workspace.Camera,SprintTween,Properties)
		local T2 = TweenService:Create(viewModelOffset,SprintTween,{Value = CFrame.new(0,-1.6,0)*CFrame.Angles(math.random(12,12.2),0,0)})
		T2:Play()
		T:Play()
		player.Character.Humanoid.WalkSpeed = 20
	end
end)

ControlsBegan.MouseButton2.Event:Connect(function()
	if CurrentWeapon == nil then return; end
	if ReplicatedStorage.Items[CurrentWeapon.Name].Melee.Value == false and isToolReady == true and _G.InInv == false then
		if CurrentWeapon[CurrentWeapon.Name].Aim ~= nil then
			player.Character.Humanoid.WalkSpeed = 12
			local PARTS = CurrentWeapon:GetChildren()
			for i=1, #PARTS do
				if PARTS[i]:IsA("MeshPart") then
					PARTS[i].Transparency = 0.5
				end
			end
			local offset3 = CurrentWeapon[CurrentWeapon.Name].Aim.CFrame:toObjectSpace(CurrentWeapon.PrimaryPart.CFrame)
			local Tween = TweenService:Create(viewModelOffset,AimTween,{Value=offset3})
			local Properties = {FieldOfView = 80}
			local T = TweenService:Create(Camera,AimTween,Properties)
			T:Play()
			Tween:Play()			
			Tween.Completed:Connect(function()
				AimFinished = true
			end)
			aiming = true
		end
	elseif ReplicatedStorage.Items[CurrentWeapon.Name].Melee.Value == true then
		-- melee throwing!
		player.Character.Humanoid.WalkSpeed = 12
		Remotes.Client.UI.ShowCenter:Fire(true)
		aiming = true
		local Properties = {FieldOfView = 95}
		local T = TweenService:Create(Camera,AimTween,Properties)
		local Tween = TweenService:Create(viewModelOffset,AimTween,{Value=CFrame.new(0,-1.6,0)*CFrame.Angles(math.rad(40),0,0)})
		Tween:Play()
		T:Play()
		Tween.Completed:Wait()
		Remotes.Melee.prepareThrow:InvokeServer(CurrentWeapon.Tag.Value,true)
		MeleeThrow = true

	end
end)

ControlsBegan.Reload.Event:Connect(function()
	if not CurrentWeapon or isToolReady == false and _G.InInv == true then return; end
	if dead == true then return; end
	local LocalBulletVal = Remotes.Client.UI.GetItemCapacity:Invoke(CurrentWeapon.Tag.Value)
	if tonumber(LocalBulletVal) == ReplicatedStorage.Items[CurrentWeapon.Name].MagazineValue.Value then return end
	if ReplicatedStorage.Items[CurrentWeapon.Name].Melee.Value == false then
		if CurrentWeapon.Name == "Crossbow" then
			CurrentWeapon[CurrentWeapon.Name].Arrow.Transparency = 1
			local Idle = CurrentWeapon.Humanoid:LoadAnimation(CurrentWeapon.ClientAnimations.Idle)
			Idle:Play()
		end
		reloading = true
		isToolReady = false
		Remotes.Gun.Reload:FireServer(CurrentWeapon.Tag.Value)
		local ReloadAnim = CurrentWeapon.Humanoid:LoadAnimation(CurrentWeapon.ClientAnimations.Reload)
		SendAnimationToServer("Reload")
		ReloadAnim:Play()
		ReloadAnim.Stopped:Connect(function()
			if CurrentWeapon.Name == "Crossbow" then
				CurrentWeapon[CurrentWeapon.Name].Arrow.Transparency = 0
			end
			reloading = false
			isToolReady = true
			General.StopAnimation(CurrentWeapon.Humanoid)
			local Idle = CurrentWeapon.Humanoid:LoadAnimation(CurrentWeapon.ClientAnimations.Idle)
			Idle.Looped = true
			Idle:Play()

		end)

	end
end)

ControlsBegan.MouseButton1.Event:Connect(function()
	--[[if building == true then
		if attachedTo == true and attachedAttachment then
			Remotes.Building.Build:FireServer(mouse.Hit.Position,attachedAttachment,BuildPart.Name)

			-- reset building
			local GPName = BuildPart.Name
			BuildPart:Destroy()
			building = false
			BuildPart = createBuilding(GPName) 
			return
		end
	end]]
	if not CurrentWeapon or isToolReady == false or dead == true or reloading == true then return; end
	if ReplicatedStorage.Items[CurrentWeapon.Name].Melee.Value == false and ReplicatedStorage.Items[CurrentWeapon.Name]:FindFirstChild("Recoil") and _G.InInv == false then
		heldMouse1 = true
		local repItems = ReplicatedStorage.Items[CurrentWeapon.Name]
		local magAmt = Remotes.Client.UI.GetItemCapacity:Invoke(CurrentWeapon.Tag.Value)
		if tonumber(magAmt) <= 0 then
			heldMouse1 = false
			return
		end --act as a 'control'
		local run = repItems.Bolt.Value  -- https://i.imgur.com/VxjbSpm.png
		local coil = repItems.Recoil.Value

		local FirePoint = CurrentWeapon[CurrentWeapon.Name]:FindFirstChild("FirePoint")

		coroutine.wrap(function()
			while heldMouse1 == true do
				pcall(function()
					CurrentWeapon.Humanoid:LoadAnimation(CurrentWeapon.ClientAnimations.Fire):Play()
				end)
				local lastResponse = os.clock()
				if FirePoint then
					for i,v in FirePoint:GetChildren() do
						v.Enabled = true
					end
				end
				coroutine.wrap(function()
					local magAmt = Remotes.Gun.getAmmo:InvokeServer(CurrentWeapon.Tag.Value)
					if magAmt <= 0 then
						heldMouse1 = false
						return
					end -- could cause lag without coroutine.wrap
				end)()
				coroutine.wrap(function()
					local startD = os.time()
					local YVal

					if math.random(1,2) == 1 then
						YVal = -coil.Y + -(math.random(10,40)/100)
					else
						YVal = coil.Y + (math.random(10,40)/100)
					end
					coroutine.wrap(function()
						CSShoot.Fire(mouse.Hit.Position,CurrentWeapon,startD,CurrentWeapon.Name)
					end)()
					coroutine.wrap(function()
						local firVal = Remotes.Gun.Fire:InvokeServer(mouse.Hit.Position,CurrentWeapon.Tag.Value,startD)
						if firVal[1] == 0 then
							lastResponse = os.clock()
						elseif firVal[1] == 1 then
							--adWait = 0.02 -- lag break, incase you are lagging *alot.*
							--task.wait(adWait)
							lastResponse = os.clock()
						elseif firVal[1] == 4 then
							deEquip()
							heldMouse1 = false
							return
						elseif firVal[1] == 3 then
							if aiming == true then
								RCSpring:shove(Vector3.new(coil.X,YVal,0))
							else
								RCSpring:shove(Vector3.new(coil.X*1.5,YVal*1.5,0))
							end
							heldMouse1 = false
							return
						else
							heldMouse1 = false
							return
						end
					end)()
					RCSpring:shove(Vector3.new(coil.X,YVal,0))

				end)()
				if lastResponse + 2 + repItems.TimeBetweenBullets.Value < os.clock() then
					task.wait(0.2)
				end
				task.wait(repItems.TimeBetweenBullets.Value)
				if FirePoint then
					for i,v in FirePoint:GetChildren() do
						v.Enabled = false
					end
				end
				--if adWait ~= nil then
				--	task.wait(adWait)
				--end
				--adWait = nil

			end
		end)()
	end
	if CurrentWeapon and isToolReady == true and dead == false and _G.InInv == false then
		if ReplicatedStorage.Items[CurrentWeapon.Name].Melee.Value == true then
			if MeleeThrow == true then
				Remotes.Melee.Throw:InvokeServer(CurrentWeapon.Tag.Value,mouse.Hit.Position)
				deEquip()
				Remotes.Client.UI.ShowCenter:Fire(false)
				MeleeThrow = false
				aiming = false
				return
			end
			isToolReady = false
			local itemValues = ReplicatedStorage.Items[CurrentWeapon.Name]
			local ViewModel = ReplicatedStorage.ViewModels[CurrentWeapon.Name]
			local Anim = CurrentWeapon.Humanoid:LoadAnimation(ViewModel.ClientAnimations.Fire)
			coroutine.wrap(doRay)()
			SendAnimationToServer("Fire")
			Anim:Play()
			Anim.Stopped:Connect(function()
				task.wait(itemValues.AnimationsCoolDown.Fire.Value)
				isToolReady = true
			end)
		end
	end
end)

ControlsEnded.MouseButton1.Event:Connect(function()
	if heldMouse1 == true then 
		heldMouse1 = false
		isToolReady = true 
	end
	heldMouse1 = false
end)

ControlsEnded.MouseButton2.Event:Connect(function()
	if not CurrentWeapon or not CurrentWeapon.Parent then return end
	if aiming == true or isToolReady == false or dead == false then
		if ReplicatedStorage.Items[CurrentWeapon.Name].Melee.Value == false then
			-- is a gun!
			if CurrentWeapon[CurrentWeapon.Name].Aim ~= nil then
				local PARTS = CurrentWeapon:GetChildren()
				for i=1, #PARTS do
					if PARTS[i]:IsA("MeshPart") then
						PARTS[i].Transparency = 0
					end
				end
				local Properties = {FieldOfView = 90}
				local T = TweenService:Create(Camera,AimTween,Properties)
				local Tween = TweenService:Create(viewModelOffset,AimTween,{Value=CFrame.new(0,-1.5,0)})
				Tween:Play()
				T:Play()
				player.Character.Humanoid.WalkSpeed = 16
				if QLean == true or ELean == true then
					local T2 = TweenService:Create(LeanOff,LeanTween,{Value = CFrame.new(0,0,0)})
					T2:Play()
					Remotes.Core.LeanPlayer:InvokeServer(false)
					QLean = false
					ELean = false
				end
				AimFinished=false
				aiming = false
			end
		else
			-- melee weapons! :)
			Remotes.Melee.prepareThrow:InvokeServer(CurrentWeapon.Tag.Value,false)
			Remotes.Client.UI.ShowCenter:Fire(false)
			MeleeThrow = false
			aiming = false
			local Properties = {FieldOfView = 90}
			local T = TweenService:Create(Camera,AimTween,Properties)
			local Tween = TweenService:Create(viewModelOffset,AimTween,{Value=CFrame.new(0,-1.5,0)})
			Tween:Play()
			T:Play()
		end

	end
end)

ControlsEnded.Sprint.Event:Connect(function()
	if aiming == false then
		local Properties = {FieldOfView = 90}
		local T = TweenService:Create(Camera,SprintTween,Properties)
		local T2 = TweenService:Create(viewModelOffset,SprintTween,{Value = CFrame.new(0,-1.5,0)})
		T2:Play()
		T:Play()
		player.Character.Humanoid.WalkSpeed = 14
	end
end)

ControlsEnded.LeftLean.Event:Connect(function()
	if QLean == true then
		local T2 = TweenService:Create(LeanOff,LeanTween,{Value = CFrame.new(0,0,0)})
		T2:Play()
		Remotes.Core.LeanPlayer:InvokeServer(false)
		QLean = false
	end
end)

ControlsEnded.RightLean.Event:Connect(function()
	if ELean == true then
		local T2 = TweenService:Create(LeanOff,LeanTween,{Value = CFrame.new(0,0,0)})
		T2:Play()
		Remotes.Core.LeanPlayer:InvokeServer(false)
		ELean = false
	end
end)



--[[

					RUN SERVICE

]]

RS.RenderStepped:connect(function(delta)
	RenderStepped.CurrentWeapon(delta)
end)
