--[[
		replicate shooting
		does no damage, just for the astethics and that :)
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.Remotes
local player = game:GetService("Players").LocalPlayer
local FastCast = require(script.FastCastRedux)
local RepCast = FastCast.new()
local LBF = workspace:WaitForChild("LocalBulletFolder")
local castBehaviour = FastCast.newBehavior()
local castParams = RaycastParams.new()

castBehaviour.Acceleration = Vector3.new(0, -workspace.Gravity*0.1, 0)
castParams.IgnoreWater = true

function playSound(org,Sound)
	local ClonedSound = Sound:Clone()
	local object = Instance.new("Part")
	object.CanCollide = false
	object.Transparency = 1
	object.Anchored = true
	object.Parent = workspace
	ClonedSound.Parent = object
	coroutine.wrap(function()
		ClonedSound.Volume = 0.5
		ClonedSound:Play()
		ClonedSound.Ended:Wait()
		ClonedSound:Destroy()
		object:Destroy()
	end)()
	return ClonedSound
end

function onRayHit(cast,result,velocity,bullet)
	local hit = result.Instance
	bullet:Destroy()
end

function onLengthChanged(cast, lastPoint, direction, length, velocity, bullet)
	if bullet then
		local bulletLength = bullet.Size.Z/2
		local offset = CFrame.new(0,0,-(length-bulletLength))
		bullet.CFrame = CFrame.lookAt(lastPoint,lastPoint + direction):ToWorldSpace(offset)
	end

end
function Fire(origin,direction,velocity,wpnName) 
	local Bullet = ReplicatedStorage.Items.Bullets.Pistol:Clone()
	Bullet.Color = Color3.new(0,0.05,0.007)
	Bullet.Material = Enum.Material.Metal

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

	castBehaviour.AutoIgnoreContainer = true
	castParams.FilterType = Enum.RaycastFilterType.Blacklist
	castParams.FilterDescendantsInstances = {player,player.Character,LBF,workspace.BulletsFolder}
	castBehaviour.RaycastParams = castParams
	castBehaviour.CosmeticBulletContainer = LBF
	castBehaviour.CosmeticBulletTemplate = Bullet
	playSound(origin,ReplicatedStorage.Items[wpnName].Sound)
	RepCast:Fire(origin,direction,velocity,castBehaviour)

end

RepCast.LengthChanged:Connect(onLengthChanged)
RepCast.RayHit:Connect(onRayHit)

Remotes.Gun.ReplicateBullet.OnClientEvent:Connect(function(origin,dir,vel,name)
	Fire(origin,dir,vel,name)
end)