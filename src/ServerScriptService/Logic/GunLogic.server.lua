math.randomseed(tick())

local Desync = 5

local fireData = {}
local warns = {}
local BulletData = {}
local PlayerPositions = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.Remotes
local players = game.Players
local ServerService = game:GetService("ServerStorage")
local Tags = ServerService:WaitForChild("Tags")
local Items = Tags:WaitForChild("Items")


local InventoryManager = require(script.Parent:WaitForChild("Modules"):WaitForChild("InventoryManager"))
local BanSystem = require(script.Parent:WaitForChild("Modules"):WaitForChild("BanSystem"))
local DamageSystem = require(script.Parent:WaitForChild("Modules"):WaitForChild("DamageSystem"))
local Cooldown = require(script.Parent:WaitForChild("Modules"):WaitForChild("CooldownSystem"))
local Barrel = require(script.Parent:WaitForChild("Modules"):WaitForChild("BarrelSystem"))

local bulletsFolder = Instance.new("Folder")
bulletsFolder.Name = "BulletsFolder"
bulletsFolder.Parent = workspace

local FastCast = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FastCastRedux"))
local caster = FastCast.new()

local castBehaviour = FastCast.newBehavior()
local castParams = RaycastParams.new()
castBehaviour.AutoIgnoreContainer = true
castBehaviour.Acceleration = Vector3.new(0, -workspace.Gravity*0.75, 0)
castParams.IgnoreWater = true
castParams.FilterType = Enum.RaycastFilterType.Blacklist
--[[local Tracer = Instance.new("Folder")
Tracer.Name = "Tracer"
Tracer.Parent =workspace--]]


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


coroutine.wrap(function()
	while wait(5) do
		for _, player in players:GetPlayers() do
			local data = Remotes.Gun.ClientSidePrediction:InvokeClient(player)
			if data == nil then return end
			local ClientPos = data.PS
			local BulData = data.BD
			if BulletData[player.UserId] then
				for ServerNum,v in BulletData[player.UserId] do
					if v.Time + 7 < os.time() and v.Finished == true then
						BulletData[ServerNum] = nil
					elseif v.Finished == true and v.Hit and v.CFrame then
						for ClientNum,e in BulData do
							if tonumber(ClientNum) == tonumber(ServerNum) then
								-- cross side refrence
								if not e.Hit or not v.Hit then return end
								local plrAtcking1 = players:GetPlayerFromCharacter(e.Hit:FindFirstAncestorWhichIsA("Model"))
								local plrAttcking2 = players:GetPlayerFromCharacter(v.Hit:FindFirstAncestorWhichIsA("Model"))
								if not plrAtcking1 and plrAttcking2 then
									if (v.CFrame.Position.X - e.CFrame.Position.X <= Desync or v.CFrame.Position.X - e.CFrame.Position.X <= -Desync) and (v.CFrame.Position.Z - e.CFrame.Position.Z <= Desync or v.CFrame.Position.Z - e.CFrame.Position.Z <= -Desync) then
										if ClientPos[plrAttcking2.UserId] and PlayerPositions[plrAttcking2.UserId] then
											local PlrSPos = PlayerPositions[plrAttcking2.UserId]
											local PlrCPos = ClientPos[plrAttcking2.UserId]
											if (PlrSPos.Position.X - PlrCPos.CFrame.Position.X <= Desync or PlrSPos.CFrame.Position.X - PlrCPos.CFrame.Position.X <= -Desync) and (PlrSPos.CFrame.Position.Z - PlrCPos.CFrame.Position.Z <= Desync or PlrSPos.CFrame.Position.Z - PlrCPos.CFrame.Position.Z <= -Desync) then
												if (v.Time - e.Time) <= 4 or (v.Time - e.Time) <= -4 then
													DamageSystem.DamagePlayer(plrAttcking2,player,v.Bullet.PartHit,v.Bullet.Damage,v.Bullet.GunValue)
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
end)()

function onRayHit(cast,result,velocity,bullet)
	local hit = result.Instance
	if hit == nil then return end
	local character = hit:FindFirstAncestorWhichIsA("Model")
	local plrAtcking = players:GetPlayerFromCharacter(bullet.Owner.Value)	
	if character and character:FindFirstChild("Humanoid") then

		local plr = players:GetPlayerFromCharacter(character)
		BulletData[plrAtcking.UserId][bullet.BC.Value]["Hit"]=character

		if plr then
			DamageSystem.DamagePlayer(plrAtcking,plr,hit,bullet.Damage.Value,bullet.Gun.Value)
		else
			DamageSystem.DamageNPC(plrAtcking,character:FindFirstChild("Humanoid"),hit,bullet.Damage.Value)
		end
	else
		BulletData[plrAtcking.UserId][bullet.BC.Value]["Hit"]=hit

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
		Barrel.Hit(TagHarvest,Instanced,bullet.Damage.Value)
		ReplicatedStorage.Remotes.Core.Hitmarker:FireClient(plrAtcking,false)
	end
	--#endregion
	BulletData[plrAtcking.UserId][bullet.BC.Value]["CFrame"]=hit.CFrame
	BulletData[plrAtcking.UserId][bullet.BC.Value]["Bullet"] = {
		["PartHit"]=hit,
		["Damage"]=bullet.Damage.Value,
		["GunValue"]=bullet.Gun.Value
	}
	BulletData[plrAtcking.UserId][bullet.BC.Value]["Finished"]=true
	bullet:Destroy()
end

function onLengthChanged(cast, lastPoint, direction, length, velocity, bullet)
	if bullet then
		local bulletLength = bullet.Size.Z/2
		local offset = CFrame.new(0,0,-(length-bulletLength))
		bullet.CFrame = CFrame.lookAt(lastPoint,lastPoint + direction):ToWorldSpace(offset)
	end

end


Remotes.Gun.Fire.OnServerInvoke = function(player,mousePos,Tag,timeSent)
	local code = {}
	if player.Character.Humanoid.Health <= 0 then 
		code[1]=2
		code[2]=5
		return code	
	end
	--sty
	local currentWeapon = Items[Tag]
	if not currentWeapon then
		code[1]=4
		code[2]=5
		return code	
	end
	if fireData[player.UserId] == nil then
		fireData[player.UserId] = {}
	end
	if BulletData[player.UserId] == nil then
		BulletData[player.UserId] = {}
	end
	if fireData[player.UserId][currentWeapon.NameTag.Value] == nil then
		fireData[player.UserId][currentWeapon.NameTag.Value] = {
			["LastShot"] = os.clock()-10,
			["001Warns"] = 0,
			["Reloading"] = false
		}
	end
	local inv = InventoryManager.Player.GetTagSlot(player,Tag)
	if inv == false or tonumber(inv) > 6 then
		fireData[player.UserId][currentWeapon.NameTag.Value].LastShot = os.clock() + 5
		code[1] = 4
		code[2] = 5
		return code
	end

	local ItemValues = ReplicatedStorage.Items[currentWeapon.NameTag.Value]

	if fireData[player.UserId][currentWeapon.NameTag.Value].LastShot + ItemValues.TimeBetweenBullets.Value >= os.clock() then 
		code[1] = 1
		return code
	end 
	if currentWeapon.Magazine.Value <= 0 or fireData[player.UserId][currentWeapon.NameTag.Value]["Reloading"] == true then
		fireData[player.UserId][currentWeapon.NameTag.Value].LastShot = os.clock() + ItemValues.ReloadTime.Value
		code[1] = 7
		return code
	end
	if currentWeapon.Owner.Value ~= player.UserId then
		BanSystem.AnticheatBanOnline(player,"026","Player tried to shoot a gun that didn't belong to them")
	end

	local bullet = ReplicatedStorage.Items.Bullets["Pistol"]:Clone()
	bullet.Size = Vector3.new(0.1,0.1,0.1)
	bullet.Transparency = 1
	
	
	local findplrfrombullet = Instance.new("ObjectValue")
	findplrfrombullet.Name = "Owner"
	findplrfrombullet.Value = player.Character
	findplrfrombullet.Parent = bullet

	local GUN = Instance.new("StringValue")
	GUN.Name = "Gun"
	GUN.Value = currentWeapon.NameTag.Value
	GUN.Parent = bullet

	local BC = Instance.new("IntValue")
	BC.Name = "BC"
	BC.Value = timeSent
	BC.Parent = bullet

	local dmg = ItemValues.Damage:Clone()
	dmg.Parent = bullet
	
	local WhizSound = ReplicatedStorage.Sounds.Whiz:Clone()
	WhizSound:Play()
	WhizSound.Parent = bullet

	castParams.FilterDescendantsInstances = {player,player.Character,bulletsFolder}
	castBehaviour.RaycastParams = castParams
	castBehaviour.CosmeticBulletContainer = bulletsFolder
	castBehaviour.CosmeticBulletTemplate = bullet
	local sprd = ItemValues.Spread.Value
	fireData[player.UserId][currentWeapon.NameTag.Value].LastShot = os.clock()
	currentWeapon.Magazine.Value -= 1
	coroutine.wrap(function()
		Remotes.Gun.ammoBack:FireClient(player,Tag,currentWeapon.Magazine.Value)
		InventoryManager.Player.ChangeVal(player,inv,"Magazine",currentWeapon.Magazine.Value)
	end)()
	local spread = CFrame.Angles(math.rad((sprd  * (math.random() * 2 - 1)*(player.Character.Humanoid.WalkSpeed/10))),math.rad((sprd  * (math.random() * 2 - 1)*(player.Character.Humanoid.WalkSpeed/10))),math.rad((sprd  * (math.random() * 2 - 1)*(player.Character.Humanoid.WalkSpeed/10))))
	coroutine.wrap(function()
		Remotes.Gun.spreadReturn:FireClient(player,spread)
	end)()
	BulletData[player.UserId][timeSent] = {}
	BulletData[player.UserId][timeSent].Time = os.time()
	BulletData[player.UserId][timeSent].Finished = false
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
	else
		code[1] = 0
		code[2] = ItemValues.TimeBetweenBullets.Value
	end
	return code
	--coroutine.wrap(function()
	--end)()

end

caster.LengthChanged:Connect(onLengthChanged)
caster.RayHit:Connect(onRayHit)


Remotes.Gun.Reload.OnServerEvent:Connect(function(player,tag)

	local currentWeapon = Items[tag]
	if Items[tag] then
		if fireData[player.UserId] == nil then
			fireData[player.UserId] = {}
		end
		if fireData[player.UserId][currentWeapon.NameTag.Value] == nil then
			fireData[player.UserId][currentWeapon.NameTag.Value] = {
				["LastShot"] = os.clock()-10,
				["001Warns"] = 0,
				["Reloading"] = false
			}
		end
		local ItemValues = ReplicatedStorage.Items[currentWeapon.NameTag.Value]
		if ItemValues.MagazineValue.Value == Items[tag].Magazine.Value then return false end
		if currentWeapon.Owner.Value ~= player.UserId then 
			BanSystem.AnticheatBanOnline(player,"026","Player tried to reload a gun that didn't belong to them")
		end
		fireData[player.UserId][currentWeapon.NameTag.Value]["Reloading"] = true

		coroutine.wrap(function()
			task.delay(ItemValues.ReloadTime.Value,function()
				Items[tag].Magazine.Value = ItemValues.MagazineValue.Value
				fireData[player.UserId][currentWeapon.NameTag.Value]["Reloading"] = false
				Remotes.Gun.ammoBack:FireClient(player,tag,Items[tag].Magazine.Value)
				coroutine.wrap(function()
					local inv = InventoryManager.Player.GetTagSlot(player,tag)
					InventoryManager.Player.ChangeVal(player,inv,"Magazine",Items[tag].Magazine.Value)
				end)()
			end)
		end)()
		return ItemValues.ReloadTime.Value

	end
end)

Remotes.Gun.getGunSpreadValues.OnServerInvoke = function(Player)
	if Cooldown.Fire(Player,"GetSpread",2000) == false then return end
	local gSpread = {}
	local gVelocity = {}
	for _,folder in ReplicatedStorage.Items:GetChildren() do
		if folder:IsA("Folder") then
			for _,val in folder:GetChildren() do
				if val.Name == "Spread" then
					gSpread[folder.Name] = val.Value
				end
				if val.Name == "BulletVelocity" then
					gVelocity[folder.Name] = val.Value
				end
			end
		end
	end
	return {["Spread"]=gSpread,["Velocity"]=gVelocity}
end

