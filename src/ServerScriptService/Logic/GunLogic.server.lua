math.randomseed(tick())

local Desync = 5 -- magnitude!

local fireData = {}
local ReloadData = {}
--[[ #CLIENTSIDEPREDICTION

local BulletData = {}
local PlayerPositions = {}--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.Remotes
local players = game.Players
local ServerService = game:GetService("ServerStorage")
local Tags = ServerService:WaitForChild("Tags")
local Items = Tags:WaitForChild("Items")
local SwappedWeapon = script.Parent.PlayerEvents.PlayerSwappedWeapon

local InventoryManager = require(script.Parent:WaitForChild("Modules"):WaitForChild("InventoryManager"))
local BanSystem = require(script.Parent:WaitForChild("Modules"):WaitForChild("BanSystem"))
local DamageSystem = require(script.Parent:WaitForChild("Modules"):WaitForChild("DamageSystem"))
local Cooldown = require(script.Parent:WaitForChild("Modules"):WaitForChild("CooldownSystem"))
local Barrel = require(script.Parent:WaitForChild("Modules"):WaitForChild("BarrelSystem"))
local PlayerTracker = require(script.Parent:WaitForChild("Modules"):WaitForChild("PlayerTracker"))

local bulletsFolder = Instance.new("Folder")
bulletsFolder.Name = "BulletsFolder"
bulletsFolder.Parent = workspace

local FastCast = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FastCastRedux"))
local caster = FastCast.new()

local castBehaviour = FastCast.newBehavior()
local castParams = RaycastParams.new()
castBehaviour.AutoIgnoreContainer = true
castBehaviour.Acceleration = Vector3.new(0, -workspace.Gravity*0.5, 0)
castParams.IgnoreWater = true
castParams.FilterType = Enum.RaycastFilterType.Blacklist



SwappedWeapon.Event:Connect(function(player,newTag)
	if ReloadData[player.UserId] == nil then
		ReloadData[player.UserId] = {
			["Reloading"]=false,
			["Tag"]=0
		}
	elseif ReloadData[player.UserId]["Tag"] ~= newTag then
		if ReloadData[player.UserId]["Reloading"] == true then
			ReloadData[player.UserId]["Reloading"] = false
		end
	end
end)

function CanCollide(Obj, Collide)
	for i,v in pairs(Obj:GetChildren()) do
		if v:IsA("BasePart") then
			v.CanCollide = Collide
		end
		if #v:GetChildren() >= 1 then
			CanCollide(v, Collide)
		end
	end
end


--[[#CLIENTSIDEPREDICTION

coroutine.wrap(function()
	while true do
		print("srtrloop ")
		for _, player in players:GetPlayers() do
			local data = Remotes.Gun.ClientSidePrediction:InvokeClient(player)
			if data then 
				local ClientPos = data.PS
				local BulData = data.BD
				if BulletData[player.UserId] then
					print(2)
					for ServerNum,ServerBulletData in BulletData[player.UserId] do
						if ServerBulletData.Time + 7 < os.time() then
							print("deleted",ServerNum)
							BulletData[ServerNum] = nil
		
						elseif ServerBulletData.Finished == true then
							for ClientNum,ClientBulletData in BulData do
								if ServerBulletData.Time == ClientBulletData.Time then

									if ClientBulletData.Hit or ClientBulletData.Finished == true then 

										local PlrClientHit = players:GetPlayerFromCharacter(ClientBulletData.Hit:FindFirstAncestorWhichIsA("Model"))
										if PlrClientHit then
											print("found player!",PlrClientHit)
											if ClientPos[PlrClientHit.UserId] and PlayerPositions[PlrClientHit.UserId] then
												local PlrSPos = PlayerPositions[PlrClientHit.UserId]
												local PlrCPos = ClientPos[PlrClientHit.UserId]
												local ClientPartHit = PlrCPos["HumanoidRootPart"]
												local ServerPartHit = PlrSPos["HumanoidRootPart"]
												if table.find(PlrSPos,ClientBulletData.PartHit) then
													ClientPartHit = PlrCPos[ClientBulletData.PartHit]
													ServerPartHit = PlrSPos[ClientBulletData.PartHit]
												end
												if (ClientPartHit.Position - ServerPartHit.Position).Magnitude < Desync then
													if (ServerBulletData.Time - ClientBulletData.Time) <= 4 or (ServerBulletData.Time - ClientBulletData.Time) <= -4 then
														DamageSystem.DamagePlayer(PlrClientHit,player,ServerBulletData.Bullet.PartHit,ServerBulletData.Bullet.Damage,ServerBulletData.Bullet.GunValue)
														print("Hit through prediction")
													end
												end
											end
										end
									
									end
							
									BulletData[player.UserId][ServerNum] = nil
								end
		
							end
						end
					end
				end
			end
		end
		wait(5)
	end
end)()


coroutine.wrap(function()
	while wait(0.3) do
		for _,player in players:GetPlayers() do
			if player.Character then
				PlayerPositions[player.UserId] = {}
				for _,v in player.Character:GetChildren() do
					if v:IsA("MeshPart") or v:IsA("Part") then
						PlayerPositions[player.UserId][v.Name] = v.CFrame
					end
				end
			end

		end
	end
end)() --]]

function onRayHit(cast,result,velocity,bullet)
	local hit = result.Instance
	if hit == nil then return end
	local character = hit:FindFirstAncestorWhichIsA("Model")
	local plrAtcking = players:GetPlayerFromCharacter(bullet.Owner.Value)

	--local BC = bullet:GetAttribute("BC")
	local Damage = bullet:GetAttribute("Damage")
	local Gun = bullet:GetAttribute("Gun")
	if character and character:FindFirstChild("Humanoid") then

		local plr = players:GetPlayerFromCharacter(character)
		-- #CLIENTSIDEPREDICTION BulletData[plrAtcking.UserId][BC]["Hit"]=character

		if plr then
			DamageSystem.DamagePlayer(plrAtcking,plr,hit,Damage,Gun)
		else
			DamageSystem.DamageNPC(plrAtcking,character:FindFirstChild("Humanoid"),hit,Damage)
		end
	--else
		-- #CLIENTSIDEPREDICTION BulletData[plrAtcking.UserId][BC]["Hit"]=hit
	end

	--#region
	local Instanced
	local TagHarvest
	if hit.Parent:GetAttribute("Tag") then
		Instanced = hit.Parent
		TagHarvest = hit.Parent:GetAttribute("Tag")
	elseif hit:GetAttribute("Tag") then
		Instanced = hit
		TagHarvest = hit:GetAttribute("Tag")
	elseif hit.Parent.Parent:GetAttribute("Tag") then
		Instanced = hit.Parent.Parent
		TagHarvest = hit.Parent.Parent:GetAttribute("Tag")
	end
	if Instanced and TagHarvest then
		if Instanced:GetAttribute("Health") == nil or Instanced:GetAttribute("Tag")  == nil then return end
		Barrel.Hit(TagHarvest,Instanced,Damage)
		ReplicatedStorage.Remotes.Core.Hitmarker:FireClient(plrAtcking,false)
	end
	--#endregion
	--[[ #CLIENTSIDEPREDICTION
	BulletData[plrAtcking.UserId][BC]["CFrame"]=hit.CFrame
	BulletData[plrAtcking.UserId][BC]["Bullet"] = {
		["PartHit"]=hit,
		["Damage"]=Damage,
		["GunValue"]=Gun
	}
	BulletData[plrAtcking.UserId][BC]["Finished"]=true
	bullet:Destroy() --]]
end

function onLengthChanged(cast, lastPoint, direction, length, velocity, bullet)
	if bullet then
		local bulletLength = bullet.Size.Z/2
		local offset = CFrame.new(0,0,-(length-bulletLength))
		bullet.CFrame = CFrame.lookAt(lastPoint,lastPoint + direction):ToWorldSpace(offset)
	end

end


Remotes.Gun.Fire.OnServerEvent:Connect( function(player,mousePos,Tag,timeSent)
	local code = {}
	if player.Character.Humanoid.Health <= 0 then 
		code[1]=2
		code[2]=5
		Remotes.Gun.Fire:FireClient(player,code)
		return;
	end
	--sty
	local currentWeapon = Items[Tag]
	if not currentWeapon then
		code[1]=4
		code[2]=5
		Remotes.Gun.Fire:FireClient(player,code)
		return;
	end
	if fireData[player.UserId] == nil then
		fireData[player.UserId] = {}
	end
	--[[ #CLIENTSIDEPREDICTION
	if BulletData[player.UserId] == nil then
		BulletData[player.UserId] = {}
	end]]
	if ReloadData[player.UserId] == nil then
		ReloadData[player.UserId] = {
			["Reloading"]=false,
			["Tag"]=0
		}
	end
	if fireData[player.UserId][Tag] == nil then
		fireData[player.UserId][Tag] = {
			["LastShot"] = os.clock()-10,
			["Reloading"] = false
		}
	end
	local inv = InventoryManager.Player.GetTagSlot(player,Tag)
	if inv == false or tonumber(inv) > 6 then
		fireData[player.UserId][Tag].LastShot = os.clock() + 5
		code[1] = 4
		code[2] = 5
		Remotes.Gun.Fire:FireClient(player,code)
		return;
	end

	local ItemValues = ReplicatedStorage.Items[currentWeapon.NameTag.Value]

	if fireData[player.UserId][Tag].LastShot + ItemValues.TimeBetweenBullets.Value - (player:GetNetworkPing() * 100) >= os.clock() then 
		code[1] = 1
		Remotes.Gun.Fire:FireClient(player,code)
		return;
	end 
	if currentWeapon.Magazine.Value <= 0 or ReloadData[player.UserId].Reloading == true then
		fireData[player.UserId][Tag].LastShot = os.clock() + ItemValues.ReloadTime.Value
		code[1] = 7
		Remotes.Gun.Fire:FireClient(player,code)
		return;
	end
	if currentWeapon.Owner.Value ~= player.UserId then
		BanSystem.AnticheatBanOnline(player,"026","Player tried to shoot a gun that didn't belong to them")
	end

	local bullet = Instance.new("Part")
	bullet.Size = Vector3.new(0.1,0.1,0.1)
	bullet.Transparency = 1

	local findplrfrombullet = Instance.new("ObjectValue")
	findplrfrombullet.Name = "Owner"
	findplrfrombullet.Value = player.Character
	findplrfrombullet.Parent = bullet

	bullet:SetAttribute("Gun", currentWeapon.NameTag.Value)

	--bullet:SetAttribute("BC",timeSent)

	bullet:SetAttribute("Damage", ItemValues.Damage.Value)

	castParams.FilterDescendantsInstances = {player,player.Character,bulletsFolder}
	castBehaviour.RaycastParams = castParams
	castBehaviour.CosmeticBulletContainer = bulletsFolder
	castBehaviour.CosmeticBulletTemplate = bullet

	local sprd = ItemValues.Spread.Value
	fireData[player.UserId][Tag].LastShot = os.clock()
	currentWeapon.Magazine.Value -= 1
	coroutine.wrap(function()
		Remotes.Gun.ammoBack:FireClient(player,Tag,currentWeapon.Magazine.Value)
		InventoryManager.Player.ChangeVal(player,inv,"Magazine",currentWeapon.Magazine.Value)
	end)()
	local spread = CFrame.Angles(math.rad((sprd  * (math.random() * 2 - 1)*(player.Character.Humanoid.WalkSpeed/10))),math.rad((sprd  * (math.random() * 2 - 1)*(player.Character.Humanoid.WalkSpeed/10))),math.rad((sprd  * (math.random() * 2 - 1)*(player.Character.Humanoid.WalkSpeed/10))))
	coroutine.wrap(function()
		Remotes.Gun.spreadReturn:FireClient(player,spread)
	end)()
	--[[BulletData[player.UserId][timeSent] = {}
	BulletData[player.UserId][timeSent].Time = os.time()
	BulletData[player.UserId][timeSent].Finished = false]]
	local org = player.Character.Head.Position
	local dir = spread*(mousePos - player.Character.Head.Position).Unit * 100
	local vel = ItemValues.BulletVelocity.Value
	caster:Fire(org,dir,vel,castBehaviour)

	coroutine.wrap(function()
		for _,plr in players:GetPlayers() do
			if player ~= plr then
				Remotes.Gun.ReplicateBullet:FireClient(plr,org,dir,vel,currentWeapon.NameTag.Value)
			end
		end
	end)()
	if ItemValues.SingleFire.Value == true then 
		code[1] = 3
		code[2] = ItemValues.TimeBetweenBullets.Value
		Remotes.Gun.Fire:FireClient(player,code)
		return;
	end

	--coroutine.wrap(function()
	--end)()

end)

caster.LengthChanged:Connect(onLengthChanged)
caster.RayHit:Connect(onRayHit)


Remotes.Gun.Reload.OnServerEvent:Connect(function(player,tag)

	local currentWeapon = Items[tag]
	if Items[tag] then
		if ReloadData[player.UserId] == nil then
			ReloadData[player.UserId] = {
				["Reloading"]=false,
				["Tag"]=0
			}
		end
		local ItemValues = ReplicatedStorage.Items[currentWeapon.NameTag.Value]
		if ItemValues.MagazineValue.Value == Items[tag].Magazine.Value then return false end
		if currentWeapon.Owner.Value ~= player.UserId then 
			BanSystem.AnticheatBanOnline(player,"026","Player tried to reload a gun that didn't belong to them")
		end
		ReloadData[player.UserId]["Reloading"] = true
		ReloadData[player.UserId]["Tag"] = tag

		coroutine.wrap(function()
			task.delay(ItemValues.ReloadTime.Value,function()
				local inv = InventoryManager.Player.GetTagSlot(player,tag)
				local HeldTag = PlayerTracker:GetHeldItem(player)

				if HeldTag ~= tag then return end
				if tonumber(inv) > 6 then return end 
				if ReloadData[player.UserId]["Reloading"] == false then return end
				Items[tag].Magazine.Value = ItemValues.MagazineValue.Value
				ReloadData[player.UserId]["Reloading"] = false
				Remotes.Gun.ammoBack:FireClient(player,tag,Items[tag].Magazine.Value)

				InventoryManager.Player.ChangeVal(player,inv,"Magazine",Items[tag].Magazine.Value)
			end)
		end)()
		return ItemValues.ReloadTime.Value

	end
end)

