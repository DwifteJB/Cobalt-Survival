--[[

					Cobalt Guard
					Written by Dwifte(RobsPlayz)
					
					TagSystem is in here too !!! :)

]]
local WhitelistedStates = {"Falling","Standing","Flinging"}
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Datastore = game:GetService("DataStoreService")
local BanSystem = require(script.Parent:WaitForChild("Modules"):WaitForChild("BanSystem"))

local BanStore = Datastore:GetDataStore("BanStore")

local PlayerEvents = script.Parent.PlayerEvents

local RunService = game:GetService("RunService")
local lighting = game:GetService("Lighting")
local ClientSideOn = {}
local warnings = {}
local allowedNames = {}
for _,part in pairs(ServerScriptService:GetChildren()) do
	table.insert(allowedNames,part.Name)
end

--BanSystem.PostManual("RobsPlayz",69,"RobsPlayz")
--BanSystem.AnticheatBanOnline(game:GetService("Players"):WaitForChild("RobsPlayz"),"003","Player shot too quickly. They shot below the TimeBetweenBullets threshold.")

PlayerEvents.CharacterAdded.Event:Connect(function(player,character)
	ClientSideOn[player.UserId] = {}
	if player:GetRankInGroup(15771966) <= 3 then
		warnings[player.Name] = {}
		local partsDet = {}
		local parts = player.Character:GetChildren()
		for _, part in pairs(parts) do
			if part:IsA("MeshPart") then
				table.insert(partsDet,part.Name)
				part:GetPropertyChangedSignal("Size"):Connect(function()
					BanSystem.AnticheatBanOnline(player,"008","Player body part size changed")
				end)
				part:GetPropertyChangedSignal("Transparency"):Connect(function()
					BanSystem.AnticheatBanOnline(player,"009","Player body transparency changed")
				end)
			end
		end
		local Humanoid = character:WaitForChild("Humanoid")
		local function checkMag()
			if not character:FindFirstChild("HumanoidRootPart") then return end
			local PrevPos = character.HumanoidRootPart.Position
			local prevState = Humanoid:GetState().Value
			delay(1,function()
				if (character.HumanoidRootPart.Position - PrevPos).Magnitude >= 30 then
					wait(0.1)
					if table.find(WhitelistedStates,Humanoid:GetState().Value) or table.find(WhitelistedStates,prevState) then return end
					if Humanoid.FloorMaterial ~= Enum.Material.Air or Humanoid.Health == 0 then return end
					if warnings[player.Name].Banned == nil or warnings[player.Name].Banned == false then
						BanSystem.AnticheatBanOnline(player,"006","Player teleported/walked 30 studs within a second")
					end
					warnings[player.Name].Banned = true

				end
			end)
			if character.HumanoidRootPart.Position.Y > 600 then
				if warnings[player.Name].Banned == nil or warnings[player.Name].Banned == false then
					BanSystem.AnticheatBanOnline(player,"012","Player Y value was too high, most likely: fly or fling")
				end
				warnings[player.Name].Banned = true
			end
			if character.HumanoidRootPart.Position.Y < -41.103 then
				if warnings[player.Name].Banned == nil or warnings[player.Name].Banned == false then
					BanSystem.AnticheatBanOnline(player,"013","Player Y value was too low, most likely: fly or fling")
				end
				warnings[player.Name].Banned = true

			end

		end
		local function createClientSide()
			pcall(function()
				local Descendants = player:GetDescendants()
				for _,v in pairs(player.Character:GetDescendants()) do
					table.insert(Descendants,v)
				end
				table.remove(Descendants, (table.find(Descendants, player.PlayerGui)))
				local CSED = script.CobaltGuardCS:Clone()
				CSED.Name = HttpService:GenerateGUID(true)
				CSED.Parent = Descendants[math.random(1,#Descendants)]
				CSED.Disabled = false
				ClientSideOn[player.UserId].Passed = false
				wait(15)
				CSED:Destroy()
			end)



		end
		coroutine.resume(coroutine.create(function()
			while wait(1) do
				checkMag()
			end
		end))
		coroutine.resume(coroutine.create(function()
			createClientSide()
			while true do
				createClientSide()
				wait(15)
				if ClientSideOn[player.UserId].Passed == false then
					print(player.Name, "didnt pass..")
				end
			end
		end))

		Humanoid.HealthChanged:Connect(function()
			if character:WaitForChild("Humanoid").Health > 100 then

				if warnings[player.Name].Banned == nil or warnings[player.Name].Banned == false then
					BanSystem.AnticheatBanOnline(player,"010","Players health was higher than 100")
				end
				warnings[player.Name].Banned = true
			end
		end)

		Humanoid.StateChanged:Connect(function(PrevState,NewState)
			if NewState == Enum.HumanoidStateType.PlatformStanding then
				if warnings[player.Name].Banned == nil or warnings[player.Name].Banned == false then
					BanSystem.AnticheatBanOnline(player,"007","Player had uncommon PlatformStanding state, this usually means fly.")
				end
				warnings[player.Name].Banned = true
			end

		end)
		character.ChildRemoved:Connect(function(Child)
			if table.find(partsDet,Child.Name) then
				if warnings[player.Name].Banned == nil or warnings[player.Name].Banned == false then
					BanSystem.AnticheatBanOnline(player,"011","Player part had been removed.")
				end
				warnings[player.Name].Banned = true
			end
		end)
		Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if Humanoid.WalkSpeed > 22 then
				if warnings[player.Name].Banned == nil or warnings[player.Name].Banned == false then
					BanSystem.AnticheatBanOnline(player,"021","Players walkspeed was set above 22.")
				end
				warnings[player.Name].Banned = true

			end
		end)
		local hrp = character:WaitForChild("HumanoidRootPart")
		hrp:GetPropertyChangedSignal("CFrame"):Wait()
		local lastCF = hrp.CFrame
		local lastGroundedCF = hrp.CFrame
		local lastGrounded = tick()

		RunService.Heartbeat:Connect(function(step)
			local cf = hrp.CFrame
			--Walk Speed Cheats
			local velocityNoY = (cf.Position * Vector3.new(1, 0, 1) - lastCF.Position * Vector3.new(1, 0, 1)).Magnitude / step
			if velocityNoY > 140 then
				hrp.CFrame = lastCF
			end

			--Jump and Fly Cheats
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {player.Character}

			local ray = workspace:Raycast(cf.Position, -cf.UpVector * 5, raycastParams)

			local velocityOnlyY = (cf.Position.Y - lastCF.Position.Y) / step

			if ray and ray.Instance.CanCollide then

				lastGrounded = tick()
				lastGroundedCF = hrp.CFrame

			elseif tick() - lastGrounded > 2 and velocityOnlyY >= 0 then

				hrp.CFrame = lastGroundedCF
			end

			--No Clip Cheats
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {player.Character}

			local ray = workspace:Raycast(cf.Position, cf.LookVector * 1.5, raycastParams)

			if ray and ray.Instance.CanCollide then

				hrp.CFrame = lastCF
			end
			lastCF = hrp.CFrame
		end)
		if BanStore:GetAsync(player.UserId) then
			local ban = BanStore:GetAsync(player.UserId) 
			if tonumber(ban) then
				print(player.Name, "is banned by Anticheat")
				BanStore:RemoveAsync(player.UserId)
			else
				print(player.Name, "is banned by a mod!")
			end
		end
	else
		print("CobaltGuard Bypassed")
	end
end)



coroutine.resume(coroutine.create(function()
	while task.wait(math.random(20,40)) do -- prevents scripts from using game.Players to use services 
		game:GetService("Workspace").Name = HttpService:GenerateGUID(true)
		game:GetService("Players").Name = HttpService:GenerateGUID(true)
		game:GetService("Lighting").Name = HttpService:GenerateGUID(true)
		game:GetService("ReplicatedStorage").Name = HttpService:GenerateGUID(true)
		game:GetService("ReplicatedFirst").Name = HttpService:GenerateGUID(true)
		game:GetService("ServerStorage").Name = HttpService:GenerateGUID(true)
		game:GetService("ServerScriptService").Name = HttpService:GenerateGUID(true)
		game:GetService("StarterGui").Name = HttpService:GenerateGUID(true)
		game:GetService("StarterPlayer").Name = HttpService:GenerateGUID(true)
		game:GetService("Chat").Name = HttpService:GenerateGUID(true)
	end
end))

--BanSystem.PostAnticheat("RobsPlayz",1201311,003,"Player shot too quickly. They shot below the TimeBetweenBullets threshold.")
lighting:GetPropertyChangedSignal("Ambient"):Connect(function()
	lighting.Ambient = Color3.new(138,138,138)
end)
lighting:GetPropertyChangedSignal("OutdoorAmbient"):Connect(function()
	lighting.OutdoorAmbient = Color3.new(70,70,70)
end)
lighting:GetPropertyChangedSignal("Brightness"):Connect(function()
	lighting.Brightness = 2
end)

-- some exploits can inject server-side scripts :(
ServerScriptService.ChildAdded:Connect(function(Child)
	if Child.Name == "ChatServiceRunner" or Child.Name == "DefaultChatSystemChatEvents" then return end
	for key,val in allowedNames do
		if Child.Name == val then
			return
		end
	end
	if Child.Name ~= "ChatServiceRunner" then
		pcall(function()
			Child:Destroy()
		end)
	end
end)

-- some exploits can inject server-side scripts :(
ReplicatedStorage.ChildAdded:Connect(function(Child)
	if not Child:IsA("Folder") and not Child:IsA("Configuration") and Child.Name ~= "DefaultChatSystemChatEvents" then
		pcall(function()
			Child:Destroy()
		end)
	end
end)





--[[local DroppedItems = workspace:WaitForChild("DroppedItems")
DroppedItems.ChildAdded:Connect(function(child)
	print(child)
	print(child.Tag)
	
	local Tag = child:FindFirstChild("Tag")
	if child.Name == "Bags" or child.Parent.Name == "Bags" then return end
	if not Tag then
		child:Destroy()
	end
	if Tag then
		if TagSystem.FindDuplicatedDroppedItem(child.Tag.Value) > 1 then
			child.Tag:Destroy()
		end
	end
end)--]]


ReplicatedStorage.Remotes.Misc.Goodbye.OnServerInvoke = function(player,banReason)
	--
	if banReason == "014" then
		ClientSideOn[player.UserId].Passed = true
	else
		local banCodeExplain = {
			["015"] = "Dex/Unwhitelisted UI has been found",
			["016"] = "FPS Unlocker/Script Speedup found",
			["017"] = "Banned Player State Detected",
			["018"] = "Item was added to backpack.",
			["019"] = "Banned class was added to Character",
		}
		if banCodeExplain[banReason] then
			BanSystem.AnticheatBanOnline(player,banReason,banCodeExplain[banReason])
		else
			BanSystem.AnticheatBanOnline(player,banReason,"Unknown cause. Didn't find in dictionary.")
		end
	end

end

ReplicatedStorage.Remotes.Misc.getGunValues.OnServerInvoke = function(player,ClientVals)
	-- fold name = foldInf
	coroutine.resume(coroutine.create(function()
		for key,val in ClientVals do
			local NameInsideItems = val.Name
			if val.Values[1] then
				for k,v in val.Values do
					if ReplicatedStorage.Items[NameInsideItems][v["Name"]].Value ~= v["Value"] then
						BanSystem.AnticheatBanOnline(player,"023",string.format("Client side value %s did not match server side value.",v["Name"]))
					end
				end
			end
		end
	end))
end