--[[
	Dwifte's server-sided leg IKController
	written for cobalt :)
	
	-- pair with client one for accuracy on client
]]
local players = game:GetService("Players")
local PlayerEvents = script.Parent.PlayerEvents
local IKContollersFolder = Instance.new("Folder")
local RunService = game:GetService("RunService")
IKContollersFolder.Name = "IKControllers"
IKContollersFolder.Parent = workspace

PlayerEvents.CharacterAdded.Event:Connect(function(player,Char)
	local RightIKObj
	local LeftIKObj
	if not IKContollersFolder:FindFirstChild(player.Name.."RightIK") then
		RightIKObj = Instance.new("Part")
		RightIKObj.CanCollide = false
		RightIKObj.Transparency = 1
		RightIKObj.Anchored = true
		RightIKObj.Name = player.Name.."RightIK"
		RightIKObj.Parent = IKContollersFolder
	else
		RightIKObj = IKContollersFolder:FindFirstChild(player.Name.."RightIK")
	end
	if not IKContollersFolder:FindFirstChild(player.Name.."LeftIK") then
		LeftIKObj = Instance.new("Part")
		LeftIKObj.CanCollide = false
		LeftIKObj.Transparency = 1
		LeftIKObj.Anchored = true
		LeftIKObj.Name = player.Name.."LeftIK"
		LeftIKObj.Parent = IKContollersFolder
	else
		LeftIKObj = IKContollersFolder:FindFirstChild(player.Name.."LeftIK")
	end

	local LeftLegIK = Instance.new("IKControl")
	local RightLegIK = Instance.new("IKControl")

	LeftLegIK.Name = "LeftLeg"
	LeftLegIK.Parent = Char:WaitForChild("Humanoid")
	LeftLegIK.Type = Enum.IKControlType.Position

	LeftLegIK.EndEffector = Char:WaitForChild("LeftFoot")
	LeftLegIK.ChainRoot = Char:WaitForChild("LeftUpperLeg")

	LeftLegIK.Weight = 0.5
	LeftLegIK.Priority = 0

	LeftLegIK.Target = LeftIKObj

	RightLegIK.Name = "RightLeg"
	RightLegIK.Parent = Char:WaitForChild("Humanoid")
	RightLegIK.Type = Enum.IKControlType.Position

	RightLegIK.Weight = 0.5
	RightLegIK.Priority = 0

	RightLegIK.EndEffector = Char:WaitForChild("RightFoot")
	RightLegIK.ChainRoot = Char:WaitForChild("RightUpperLeg")

	RightLegIK.Target = RightIKObj
end)


local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Blacklist
RunService.Stepped:Connect(function()
	for _,player in players:GetPlayers() do
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			if IKContollersFolder:FindFirstChild(player.Name.."RightIK") and IKContollersFolder:FindFirstChild(player.Name.."LeftIK") then
				params.FilterDescendantsInstances = {player.Character,IKContollersFolder}
				local Char = player.Character
				-- left leg
				local LeftRay = workspace:Raycast(Vector3.new(Char:WaitForChild("LeftFoot").Position.X,Char:WaitForChild("LeftFoot").Position.Y+2,Char:WaitForChild("LeftFoot").Position.Z),Vector3.new(0,-1,0)*50,params)
				if LeftRay then
					IKContollersFolder:FindFirstChild(player.Name.."LeftIK").CFrame = CFrame.new(LeftRay.Position,LeftRay.Normal)
				end
				-- right leg :)
				local RightRay = workspace:Raycast(Vector3.new(Char:WaitForChild("RightFoot").Position.X,Char:WaitForChild("RightFoot").Position.Y+2,Char:WaitForChild("RightFoot").Position.Z),Vector3.new(0,-1,0)*50,params)
				if RightRay then
					IKContollersFolder:FindFirstChild(player.Name.."RightIK").CFrame = CFrame.new(RightRay.Position,RightRay.Normal)
				end
			end
		end

	end
end)