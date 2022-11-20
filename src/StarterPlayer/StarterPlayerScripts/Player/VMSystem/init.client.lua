--[[
		Main Player Script
		Written by Dwifte
]]--
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
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
local AimSwayMultiplier = 0.1
local lastCameraCF = workspace.CurrentCamera.CFrame

local mouse = player:GetMouse()
player.CameraMode = Enum.CameraMode.LockFirstPerson
mouse.TargetFilter = workspace.Camera
--

-- Tween Data

local GeneralTween = TweenInfo.new(0.2,Enum.EasingStyle.Sine,Enum.EasingDirection.Out)


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
local aimDisableOffset = false

--

--[[

							FUNCTIONS 

]]

function Bob(addition,multiplier)
	return math.sin(tick() * addition * 1.3) * multiplier -- increase multipl for faster bobbing
end

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
		local x,y = rotation:ToOrientation()
		if not aimDisableOffset then
			if aiming == false then
				local bob = Vector3.new(Bob(10,0.65),Bob(5,0.65),Bob(5,0.65))
				BobbingSpring:shove(bob / 10 * (player.Character.HumanoidRootPart.Velocity.Magnitude / 10))
				SwayOffset = SwayOffset:Lerp(CFrame.Angles(math.sin(x)*SwayMultiplier,math.sin(y)*SwayMultiplier,0),0.1)
			else
				local bob = Vector3.new(Bob(1,0.1),Bob(0.5,0.1),Bob(0.5,0.1))
				BobbingSpring:shove(bob / 10 * (player.Character.HumanoidRootPart.Velocity.Magnitude / 10))
								
				SwayOffset = SwayOffset:Lerp(CFrame.Angles(math.sin(x)*AimSwayMultiplier,math.sin(y)*AimSwayMultiplier,0),0.1)
			end
			Camera.CFrame *= CFrame.Angles(math.rad(updatedRecoilSpring.x),math.rad(updatedRecoilSpring.y),math.rad(updatedRecoilSpring.z)) * LeanOff.Value
			lastCameraCF = workspace.CurrentCamera.CFrame
			CurrentWeapon:SetPrimaryPartCFrame(workspace.Camera.CFrame * viewModelOffset.Value * CFrame.new(GunBobUpdate.Y,GunBobUpdate.X,0)*SwayOffset*CFrame.Angles(math.rad(GunRCSpringUpdate.Y),0,0)) --CFrame.Angles(math.rad(GunBobUpdate.Y),math.rad(GunBobUpdate.X),math.rad(GunBobUpdate.Z))
	
		else
			CurrentWeapon:SetPrimaryPartCFrame(workspace.Camera.CFrame * viewModelOffset.Value) --CFrame.Angles(math.rad(GunBobUpdate.Y),math.rad(GunBobUpdate.X),math.rad(GunBobUpdate.Z))
	
			Camera.CFrame *= CFrame.Angles(math.rad(updatedRecoilSpring.x),math.rad(updatedRecoilSpring.y),math.rad(updatedRecoilSpring.z))
		end
	

	end
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
	deEquip()
end

function deEquip()
	isToolReady = false
	SendAnimationToServer("Stop")
	if CurrentWeapon then
		local savedCW = CurrentWeapon
		CurrentWeapon = nil
		General.StopAnimation(savedCW.Humanoid)
		savedCW:SetPrimaryPartCFrame(CFrame.new(0,-100,0))
	end
	resetVals()
end

function SendAnimationToServer(animlol,forceTag)
	if animlol == "Stop" then
		Remotes.Core.PlayAnimation:FireServer(animlol)
	else
		if not forceTag then
			forceTag = CurrentWeapon:GetAttribute("Tag")
		end
		Remotes.Core.PlayAnimation:FireServer(animlol,forceTag)

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
	if Tool.Tool.Value == true and dead == false then
		if CurrentWeapon then 
			deEquip()
		end

		resetVals()
		isToolReady = false
		CurrentWeapon = workspace.CurrentCamera.ViewModels[name]
		print(CurrentWeapon,name,tag)
		--double check

		coroutine.wrap(function()
			for _, VM in workspace.CurrentCamera.ViewModels:GetChildren() do
				if VM.Name ~= name then 
					VM:SetPrimaryPartCFrame(CFrame.new(0,-100,0))
				end

			end
		end)()


		if Tool:FindFirstChild("Melee") then
			isMelee = Tool.Melee.Value
		else
			isMelee = false
		end

		CurrentWeapon:SetAttribute("Tag",tag)

		CurrentWeapon.PrimaryPart.Anchored = true
		General.CanCollide(CurrentWeapon, false)
		local Equip
		local Idle
		Equip = CurrentWeapon:WaitForChild("Humanoid"):LoadAnimation(CurrentWeapon.ClientAnimations.Equip)
		Idle = CurrentWeapon:WaitForChild("Humanoid"):LoadAnimation(CurrentWeapon.ClientAnimations.Idle)
		Equip:Play()
		SendAnimationToServer("Equip",tag)
		Equip.Stopped:Connect(function()
			isToolReady = true
			Idle.Looped = true
			Idle:Play()
			SendAnimationToServer("Idle",tag)
		end)
	end
end

--[[

							Player Stuff 

]]

player.CharacterAdded:Connect(function(character)
	dead = false
	Camera.CameraType = Enum.CameraType.Follow
	Camera.CameraSubject = character:WaitForChild("Humanoid")
	character:WaitForChild("Humanoid").Died:Connect(function()
		renderDead()
	end)
end)

--[[

								Remotes
					

]]

Remotes.Core.SetCamera.OnClientEvent:Connect(function(part)
	dead = true
	Camera.CameraType = Enum.CameraType.Attach
	Camera.CameraSubject = part:WaitForChild("Head")
	Camera.CameraSubject = part:WaitForChild("Head")
end)

Remotes.Client.Inventory.deEquip.OnInvoke = function()
	deEquip()
end

Remotes.Inventory.deEquip.OnClientEvent:Connect(function()
	deEquip()
end)

Remotes.Client.Inventory.getEquippedItem.OnInvoke = function()
	if CurrentWeapon then
		return CurrentWeapon:GetAttribute("Tag")
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
			local T2 = TweenService:Create(LeanOff,GeneralTween,{Value = CFrame.new(0,0,0)*CFrame.Angles(0,0,0)})
			T2:Play()
			Remotes.Core.LeanPlayer:InvokeServer(false)
			T2.Completed:Wait()
		end
		local leanVal = Remotes.Core.LeanPlayer:InvokeServer(1)
		if leanVal == false then
			Remotes.Core.LeanPlayer:InvokeServer(false)
			local T2 = TweenService:Create(LeanOff,GeneralTween,{Value = CFrame.new(0,0,0)})
			T2:Play()
			return
		end

		local T2 = TweenService:Create(LeanOff,GeneralTween,{Value = CFrame.new(-0.5,-0.05,0)*CFrame.Angles(0,0,math.asin(math.rad(25)))})
		T2:Play()
		QLean = true
	end
end)

ControlsBegan.RightLean.Event:Connect(function()
	if aiming == true and isMelee == false then
		if QLean == true then
			QLean = false
			local T2 = TweenService:Create(LeanOff,GeneralTween,{Value = CFrame.new(0,0,0)})
			T2:Play()
			Remotes.Core.LeanPlayer:InvokeServer(false)
			T2.Completed:Wait()
		end
		local leanVal = Remotes.Core.LeanPlayer:InvokeServer(2)
		if leanVal == false then
			Remotes.Core.LeanPlayer:InvokeServer(false)
			local T2 = TweenService:Create(LeanOff,GeneralTween,{Value = CFrame.new(0,0,0)*CFrame.Angles(0,0,0)})
			T2:Play()
			--correct
			return
		end
		ELean = true
		local T2 = TweenService:Create(LeanOff,GeneralTween,{Value = CFrame.new(0.5,-0.05,0)*CFrame.Angles(0,0,math.asin(math.rad(-25)))})
		T2:Play()

	end
end)

ControlsBegan.Sprint.Event:Connect(function()
	if _G.InInv == false and aiming == false then
		local Properties = {FieldOfView = 95}
		local T = TweenService:Create(workspace.Camera,GeneralTween,Properties)
		local T2 = TweenService:Create(viewModelOffset,GeneralTween,{Value = CFrame.new(0,-1.6,0)*CFrame.Angles(math.random(12,12.2),0,0)})
		T2:Play()
		T:Play()
		player.Character.Humanoid.WalkSpeed = 20
	end
end)

ControlsBegan.MouseButton2.Event:Connect(function()
	if CurrentWeapon == nil then return; end
	if ReplicatedStorage.Items[CurrentWeapon.Name].Melee.Value == false and reloading == false and isToolReady == true and _G.InInv == false then
		if CurrentWeapon[CurrentWeapon.Name].Aim ~= nil then
			player.Character.Humanoid.WalkSpeed = 12
			local PARTS = CurrentWeapon:GetChildren()
			for i=1, #PARTS do
				if PARTS[i]:IsA("MeshPart") then
					PARTS[i].Transparency = 0.5
				end
			end
			local offset3 = CurrentWeapon[CurrentWeapon.Name].Aim.CFrame:toObjectSpace(CurrentWeapon.PrimaryPart.CFrame)
			local Tween = TweenService:Create(viewModelOffset,GeneralTween,{Value=offset3})
			local Properties = {FieldOfView = 80}
			local T = TweenService:Create(Camera,GeneralTween,Properties)
			T:Play()
			Tween:Play()
			aimDisableOffset = true
			SwayOffset = CFrame.new(0,0,0)
			Tween.Completed:Connect(function()
				aimDisableOffset = false
				--local offset4 = CurrentWeapon[CurrentWeapon.Name].Aim.CFrame:toObjectSpace(CurrentWeapon.PrimaryPart.CFrame)
	
				--TweenService:Create(viewModelOffset, TweenInfo.new(0.1,Enum.EasingStyle.Sine,Enum.EasingDirection.Out), {Value=offset4}):Play()
			end)
			aiming = true
		end
	elseif ReplicatedStorage.Items[CurrentWeapon.Name].Melee.Value == true then
		-- melee throwing!
		player.Character.Humanoid.WalkSpeed = 12
		Remotes.Client.UI.ShowCenter:Fire(true)
		aiming = true
		local Properties = {FieldOfView = 95}
		local T = TweenService:Create(Camera,GeneralTween,Properties)
		local Tween = TweenService:Create(viewModelOffset,GeneralTween,{Value=CFrame.new(0,-1.6,0)*CFrame.Angles(math.rad(40),0,0)})
		Tween:Play()
		T:Play()
		Tween.Completed:Wait()
		Remotes.Melee.prepareThrow:InvokeServer(CurrentWeapon:GetAttribute("Tag"),true)
		MeleeThrow = true

	end
end)

ControlsBegan.Reload.Event:Connect(function()
	if not CurrentWeapon or isToolReady == false and _G.InInv == true then return; end
	if dead == true then return; end
	local LocalBulletVal = Remotes.Client.UI.GetItemCapacity:Invoke(CurrentWeapon:GetAttribute("Tag"))
	if tonumber(LocalBulletVal) == ReplicatedStorage.Items[CurrentWeapon.Name].MagazineValue.Value then return end
	if ReplicatedStorage.Items[CurrentWeapon.Name].Melee.Value == false then
		if CurrentWeapon.Name == "Crossbow" then
			CurrentWeapon[CurrentWeapon.Name].Arrow.Transparency = 1
			local Idle = CurrentWeapon.Humanoid:LoadAnimation(CurrentWeapon.ClientAnimations.Idle)
			Idle:Play()
		end

		--cancel aim if aiming

		if aiming == true then
			local PARTS = CurrentWeapon:GetChildren()
			for i=1, #PARTS do
				if PARTS[i]:IsA("MeshPart") then
					PARTS[i].Transparency = 0
				end
			end
			local Offset = CFrame.new(0,-1.5,0)
			local Properties = {FieldOfView = 90}

			local T = TweenService:Create(Camera,GeneralTween,Properties)
			local Tween = TweenService:Create(viewModelOffset,GeneralTween,{Value=Offset})
			Tween:Play()
			T:Play()
			if QLean == true or ELean == true then
				local T2 = TweenService:Create(LeanOff,GeneralTween,{Value = CFrame.new(0,0,0)})
				T2:Play()
				Remotes.Core.LeanPlayer:InvokeServer(false)
				QLean = false
				ELean = false
			end
			aiming = false
		end
		reloading = true
		Remotes.Gun.Reload:FireServer(CurrentWeapon:GetAttribute("Tag"))
		local Cache = CurrentWeapon
		local ReloadAnim = CurrentWeapon.Humanoid:LoadAnimation(CurrentWeapon.ClientAnimations.Reload)
		SendAnimationToServer("Reload")
		General.StopAnimation(CurrentWeapon.Humanoid)
		ReloadAnim:Play()
		ReloadAnim.Stopped:Connect(function()
			if not CurrentWeapon or Cache ~= CurrentWeapon then return end
			pcall(function()
				if CurrentWeapon.Name == "Crossbow" then
					CurrentWeapon[CurrentWeapon.Name].Arrow.Transparency = 0
				end
				reloading = false
				General.StopAnimation(CurrentWeapon.Humanoid)
				local Idle = CurrentWeapon.Humanoid:LoadAnimation(CurrentWeapon.ClientAnimations.Idle)
				Idle.Looped = true
				Idle:Play()				
			end)

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
		local magAmt = Remotes.Client.UI.GetItemCapacity:Invoke(CurrentWeapon:GetAttribute("Tag"))
		if tonumber(magAmt) <= 0 then
			heldMouse1 = false
			return
		end --act as a 'control'
		local coil = repItems.Recoil.Value

		coroutine.wrap(function()
			while heldMouse1 == true do
				pcall(function()
					CurrentWeapon.Humanoid:LoadAnimation(CurrentWeapon.ClientAnimations.Fire):Play()
				end)
				coroutine.wrap(function()
					local magAmt = Remotes.Gun.getAmmo:InvokeServer(CurrentWeapon:GetAttribute("Tag"))
					if magAmt <= 0 then
						heldMouse1 = false
						return
					end 
				end)()
				coroutine.wrap(function()
					local startD = os.time()
					local YVal

					if math.random(1,2) == 1 then
						YVal = -coil.Y + -(math.random(10,40)/100)
					else
						YVal = coil.Y + (math.random(10,40)/100)
					end
					CSShoot.Fire(mouse.Hit.Position,CurrentWeapon,startD,CurrentWeapon.Name)
					Remotes.Gun.Fire:FireServer(mouse.Hit.Position,CurrentWeapon:GetAttribute("Tag"),startD)
					RCSpring:shove(Vector3.new(coil.X,YVal,0))

				end)()
				task.wait(repItems.TimeBetweenBullets.Value)

			end
		end)()
	elseif CurrentWeapon and isToolReady == true and dead == false and _G.InInv == false then
		if ReplicatedStorage.Items[CurrentWeapon.Name].Melee.Value == true then
			if MeleeThrow == true then
				Remotes.Melee.Throw:InvokeServer(CurrentWeapon:GetAttribute("Tag"),mouse.Hit.Position)
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
			SendAnimationToServer("Fire")
			coroutine.wrap(function()
				local yes = Remotes.Melee.ValidateRaycast:InvokeServer(player:GetMouse().Hit.Position,CurrentWeapon:GetAttribute("Tag"))
				if yes == 1 then
					deEquip()
				end
			end)()
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
				local T = TweenService:Create(Camera,GeneralTween,Properties)
				local Tween = TweenService:Create(viewModelOffset,GeneralTween,{Value=CFrame.new(0,-1.5,0)})
				Tween:Play()
				T:Play()
				player.Character.Humanoid.WalkSpeed = 16
				if QLean == true or ELean == true then
					local T2 = TweenService:Create(LeanOff,GeneralTween,{Value = CFrame.new(0,0,0)})
					T2:Play()
					Remotes.Core.LeanPlayer:InvokeServer(false)
					QLean = false
					ELean = false
				end
				aiming = false
				aimDisableOffset = false
			end
		else
			-- melee weapons! :)
			Remotes.Melee.prepareThrow:InvokeServer(CurrentWeapon:GetAttribute("Tag"),false)
			Remotes.Client.UI.ShowCenter:Fire(false)
			MeleeThrow = false
			aiming = false
			local Properties = {FieldOfView = 90}
			local T = TweenService:Create(Camera,GeneralTween,Properties)
			local Tween = TweenService:Create(viewModelOffset,GeneralTween,{Value=CFrame.new(0,-1.5,0)})
			Tween:Play()
			T:Play()
		end

	end
end)

ControlsEnded.Sprint.Event:Connect(function()
	if aiming == false then
		local Properties = {FieldOfView = 90}
		local T = TweenService:Create(Camera,GeneralTween,Properties)
		local T2 = TweenService:Create(viewModelOffset,GeneralTween,{Value = CFrame.new(0,-1.5,0)})
		T2:Play()
		T:Play()
		player.Character.Humanoid.WalkSpeed = 14
	end
end)

ControlsEnded.LeftLean.Event:Connect(function()
	if QLean == true then
		local T2 = TweenService:Create(LeanOff,GeneralTween,{Value = CFrame.new(0,0,0)})
		T2:Play()
		Remotes.Core.LeanPlayer:InvokeServer(false)
		T2.Completed:Wait()
		QLean = false
	end
end)

ControlsEnded.RightLean.Event:Connect(function()
	if ELean == true then
		local T2 = TweenService:Create(LeanOff,GeneralTween,{Value = CFrame.new(0,0,0)})
		T2:Play()
		Remotes.Core.LeanPlayer:InvokeServer(false)
		T2.Completed:Wait()
		ELean = false
	end
end)

Remotes.Gun.Fire.OnClientEvent:Connect(function(firVal)
	if firVal[1] == 4 then
		deEquip()
		heldMouse1 = false
		return
	end
end)

--[[

					RUN SERVICE

]]

RS.RenderStepped:Connect(function(delta)
	RenderStepped.CurrentWeapon(delta)
end)

local Loading = workspace:WaitForChild("Loading"):WaitForChild("Framework")
Loading.Value = true