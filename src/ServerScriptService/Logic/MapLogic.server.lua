--[[

		Map logic,
		Events, Harvestables, etc.
		
]]

-- SETTINGS --

local Settings = require(game:GetService("ServerStorage"):WaitForChild("Settings"))

local map_x,map_z = Settings.MapSize.X,Settings.MapSize.Z
local num_trees,num_nodes = Settings.SpawnSettings.TreeAmount,Settings.SpawnSettings.NodeAmount
local max_height = 200
local densityMin,densityMax = Settings.SpawnSettings.Density.Minimum,Settings.SpawnSettings.Density.Maximum
local chanceOfForest = Settings.SpawnSettings.ChanceOfForest -- 1/x chance
local timeout = 250 -- prevents "Script timeout: exhausted allowed execution time"


local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SpawnItem = require(script.Parent:WaitForChild("Modules"):WaitForChild("SpawnItem"))
local Harvestables = game:GetService("ReplicatedStorage").Harvestables

local count = 0

math.randomseed(tick())

-- airdrop spawner
function spawnAirdrop()
	local rand_x = math.random()*map_x - map_x/2
	local rand_z = math.random()*map_z - map_z/2

	local raycastPos = Vector3.new(rand_x,max_height,rand_z)

	local ray = Ray.new(raycastPos,Vector3.new(0,-1,0)*300)
	local instance,position = workspace:FindPartOnRay(ray,nil,false,false)
	local Tween
	if instance then
		local airdrop = Instance.new("Part")
		airdrop.CustomPhysicalProperties = PhysicalProperties.new(5000,0,0)
		airdrop.Anchored = true
		airdrop.Size = Vector3.new(8,4,8)
		airdrop.Name = "Airdrop"
		airdrop.Parent = workspace
		airdrop.Position = Vector3.new(rand_x,1000,rand_z)
		airdrop.Color = Color3.new(0,1,0)
		Tween = TweenService:Create(airdrop,TweenInfo.new(300,Enum.EasingStyle.Linear),{Position=Vector3.new(rand_x,position.y,rand_z)})
		Tween:Play()
		print("Spawned airdrop at:",rand_x,500,rand_z)
		airdrop.Touched:Connect(function(part)
			Tween:Cancel()
			airdrop.Anchored = false
		end)
	end
end


--spawnAirdrop()
-- spawn trees
local tim3 = os.clock()
local trees = num_trees
for i=1, trees do
	if count >= timeout then
		RunService.Heartbeat:Wait()
		count=0
	end
	count+=1
	local rand_x = math.random()*map_x - map_x/2
	local rand_z = math.random()*map_z - map_z/2

	local raycastPos = Vector3.new(rand_x,max_height,rand_z)

	local ray = Ray.new(raycastPos,Vector3.new(0,-1,0)*300)
	local instance,position,norm,material = workspace:FindPartOnRay(ray,nil,false,false)
	if instance and instance:IsA("Terrain") then
		if material == Enum.Material.Grass or material == Enum.Material.LeafyGrass or material == Enum.Material.Mud then
			if math.random(1,chanceOfForest) == 1 then
				local a = rand_x
				local b = rand_z
				local density = math.random(densityMin,densityMax)
				for i=1, density do
					local rand = (math.random()*10) * math.random(-4,4)
					local rand2 = (math.random()*10) * math.random(-4,4)
					a = a+rand
					b = b+rand2
					local partsinRadius = workspace:GetPartBoundsInRadius(Vector3.new(a,position.y,b),2)
					if #partsinRadius == 0 then
						--print("part too close!")
						--print("making tree")
						local r = Ray.new(Vector3.new(a,max_height,b),Vector3.new(0,-1,0)*300)
						local ins,pos,nm,mat = workspace:FindPartOnRay(r,nil,false,false)
						if ins and ins:IsA("Terrain") then

							SpawnItem.SpawnTree(Harvestables.TestTree,Vector3.new(a,pos.y,b),nm,1500)

						end
					end
				end
			elseif math.random(1,2) == 1 then
				-- spawns little clutter of trees nearby
				local a = rand_x
				local b = rand_z
				for i=0,3 do
					local rand = (math.random()*10) * math.random(-12,12)
					local rand2 = (math.random()*10) * math.random(-12,12)
					local partsinRadius = workspace:GetPartBoundsInRadius(Vector3.new(a,position.y,b),5)
					if #partsinRadius > 0 then
						trees+=1
					else
						local r = Ray.new(Vector3.new(a,max_height,b),Vector3.new(0,-1,0)*300)
						local ins,pos,nm,mat = workspace:FindPartOnRay(r,nil,false,false)
						if ins and ins:IsA("Terrain") then
							trees-=1
							SpawnItem.SpawnTree(Harvestables.TestTree,Vector3.new(a,pos.y,b),nm,1500)
						else
							trees+=1
						end
					end
				end
			else
				local partsinRadius = workspace:GetPartBoundsInRadius(raycastPos,3)
				if #partsinRadius > 0 then
					trees+=1
					print("part too close! - non-forest spawner")
				else
					SpawnItem.SpawnTree(Harvestables.TestTree,Vector3.new(rand_x,position.y,rand_z),norm,1500)
				end
			end

		end
	else
		trees+=1
	end

end
local nodes = num_nodes
for i=1, nodes do
	if count >= timeout then
		RunService.Heartbeat:Wait()
		count=0
	end
	count+=1
	local rand_x = math.random()*map_x - map_x/2
	local rand_z = math.random()*map_z - map_z/2

	local raycastPos = Vector3.new(rand_x,max_height,rand_z)

	local ray = Ray.new(raycastPos,Vector3.new(0,-1,0)*300)
	local instance,position,norm,material = workspace:FindPartOnRay(ray,nil,false,false)

	if instance and instance:IsA("Terrain") then
		SpawnItem.SpawnNode(Harvestables.Rock,Vector3.new(rand_x,position.y,rand_z),1500)

	else
		nodes+=1
	end
end
print("it took: ", os.clock()-tim3)