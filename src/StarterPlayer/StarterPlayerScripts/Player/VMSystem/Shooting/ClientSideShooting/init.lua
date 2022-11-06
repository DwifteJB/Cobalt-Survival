--[[
		client side shooting
		invalids etc etc.

]]

local BulletData = {}



local PlayerPositions = {}
local CSH = {}
local players = game:GetService("Players")
local player = players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FastCast = require(script.FastCastRedux)
local crst = FastCast.new()
local SpreadReturn = 0
local Remotes = ReplicatedStorage.Remotes

local LBF = Instance.new("Folder")
LBF.Name = "LocalBulletFolder"
LBF.Parent = workspace

local castBehaviour = FastCast.newBehavior()
local castParams = RaycastParams.new()

castBehaviour.Acceleration = Vector3.new(0, -workspace.Gravity*0.1, 0)
castParams.IgnoreWater = true

function playSound(player,Sound)
	local ClonedSound = Sound:Clone()
	ClonedSound.Parent = player.Character.HumanoidRootPart
	coroutine.wrap(function()
		ClonedSound.Volume = 0.5
		ClonedSound:Play()
		ClonedSound.Ended:Wait()
		ClonedSound:Destroy()
	end)()
	return ClonedSound
end



--[[ #CLIENTSIDEPREDICTION
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
end)()--]]

--[[ #CLIENTSIDEPREDICTION
ReplicatedStorage.Remotes.Gun.ClientSidePrediction.OnClientInvoke = function()
	return {["PS"]=PlayerPositions,["BD"]=BulletData}
end--]]

function onRayHit(cast,result,velocity,bullet)
	local hit = result.Instance
	--[[ #CLIENTSIDEPREDICTION
	local character = hit:FindFirstAncestorWhichIsA("Model")
	if character and character:FindFirstChild("Humanoid") then
		BulletData[bullet.BC.Value]["Hit"]=character

	else
		BulletData[bullet.BC.Value]["Hit"]=hit
	end
	BulletData[bullet.BC.Value]["PartHit"]=hit
	BulletData[bullet.BC.Value]["CFrame"]=hit.CFrame
	BulletData[bullet.BC.Value]["Finished"]=true--]]
	bullet:Destroy()
end

function onLengthChanged(cast, lastPoint, direction, length, velocity, bullet)
	if bullet then
		local bulletLength = bullet.Size.Z/2
		local offset = CFrame.new(0,0,-(length-bulletLength))
		bullet.CFrame = CFrame.lookAt(lastPoint,lastPoint + direction):ToWorldSpace(offset)
	end

end
function CSH.Fire(mousePos,CW,timeSent,gunName) 
	--[[ #CLIENTSIDEPREDICTION
	pcall(function()
		for i,v in BulletData do
			if v.Time +7 < os.time() and v.Finished == true then
				BulletData[i] = nil
			end
		end
		if BulletData[#BulletCount].Time + 5 > os.time() then
			BulletData = nil
			BulletCount = nil
		end
	end)]]

	local sprd = ReplicatedStorage.Items[CW.Name].Spread.Value
	if SpreadReturn == nil then
		SpreadReturn = CFrame.Angles(math.rad((sprd  * (math.random() * 2 - 1)*(player.Character.Humanoid.WalkSpeed/10))),math.rad((sprd  * (math.random() * 2 - 1)*(player.Character.Humanoid.WalkSpeed/10))),math.rad((sprd  * (math.random() * 2 - 1)*(player.Character.Humanoid.WalkSpeed/10))))
	end
	local Bullet = ReplicatedStorage.Items.Bullets.Pistol:Clone()


	--[[ #CLIENTSIDEPREDICTION
	local BC = Instance.new("IntValue")
	BC.Name = "BC"
	BC.Value = timeSent
	BC.Parent = Bullet]]
	
	--bullet trails
	local attach0 = Instance.new("Attachment")
	attach0.Name = "Attachment0"
	attach0.Parent = Bullet
	attach0.Position = Vector3.new(0,0.055,0)
	
	local attach1 = Instance.new("Attachment")
	attach1.Name = "Attachment1"
	attach1.Parent = Bullet
	attach1.Position = Vector3.new(0,-0.055,0)
	
	local trail = Instance.new("Trail")

	trail.Attachment0 = Bullet.Attachment0
	trail.Attachment1 = Bullet.Attachment1
	trail.Lifetime = 0.3
	trail.Parent = Bullet

	Bullet.Color = Color3.new(0,0.05,0.007)
	Bullet.Material = Enum.Material.Metal
	
	castBehaviour.AutoIgnoreContainer = true
	castParams.FilterType = Enum.RaycastFilterType.Blacklist
	castParams.FilterDescendantsInstances = {player,player.Character,LBF,workspace.BulletsFolder}

	for _,v in player.Character:GetDescendants() do
		table.insert(castParams.FilterDescendantsInstances,v)
	end
	for _,v in CW:GetDescendants() do
		table.insert(castParams.FilterDescendantsInstances,v)
	end

	castBehaviour.RaycastParams = castParams
	castBehaviour.CosmeticBulletContainer = LBF
	castBehaviour.CosmeticBulletTemplate = Bullet
	--[[ #CLIENTSIDEPREDICTION
	BulletData[timeSent] = {}
	BulletData[timeSent].Time = os.time()
	BulletData[timeSent]["Finished"] = false]]
	local Velocity =  ReplicatedStorage.Items[CW.Name].BulletVelocity.Value
	playSound(player,ReplicatedStorage.Items[CW.Name].Sound)
	coroutine.wrap(function()
		crst:Fire(CW[CW.Name].FirePoint.Position,SpreadReturn*(mousePos - player.Character.Head.Position).Unit * 100,Velocity,castBehaviour)
	end)()
end

crst.LengthChanged:Connect(onLengthChanged)
crst.RayHit:Connect(onRayHit)


Remotes.Gun.spreadReturn.OnClientEvent:Connect(function(spread)
	SpreadReturn = spread
end)

return CSH
