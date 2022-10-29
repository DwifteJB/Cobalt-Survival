--[[
	Client Version of IKController, makes it seem smoother for the player.
	written by dwifte
]]


local Char = script.Parent
local Humanoid = Char:WaitForChild("Humanoid")

Humanoid.Died:Connect(function()
	Humanoid.LeftLegClient:Destroy()
	Humanoid.RightLegClient:Destroy()
end)

local IKController = workspace:WaitForChild("IKControllers")
local Client = IKController:FindFirstChild("Client") or Instance.new("Folder")
Client.Name = "Client"
Client.Parent = IKController

local RunService = game:GetService("RunService")

local LeftIKObj = Client:FindFirstChild("LeftIK") or Instance.new("Part")
LeftIKObj.CanCollide = false
LeftIKObj.Transparency = 1
LeftIKObj.Name = "ClientLeftIK"
LeftIKObj.Parent = Client

local RightIKObj = Client:FindFirstChild("RightIK") or Instance.new("Part")
RightIKObj.CanCollide = false
RightIKObj.Transparency = 1
RightIKObj.Name = "ClientRightIK"
RightIKObj.Parent = Client

local LeftLegIK = Instance.new("IKControl")
local RightLegIK = Instance.new("IKControl")

LeftLegIK.Name = "LeftLegClient"
LeftLegIK.Parent = Char:WaitForChild("Humanoid")
LeftLegIK.Type = Enum.IKControlType.Position

LeftLegIK.EndEffector = Char:WaitForChild("LeftFoot")
LeftLegIK.ChainRoot = Char:WaitForChild("LeftUpperLeg")
LeftLegIK.Weight = 0.5
LeftLegIK.Priority = 1
LeftLegIK.Target = LeftIKObj

RightLegIK.Name = "RightLegClient"
RightLegIK.Parent = Char:WaitForChild("Humanoid")
RightLegIK.Type = Enum.IKControlType.Position

RightLegIK.Weight = 0.5
RightLegIK.Priority = 1

RightLegIK.EndEffector = Char:WaitForChild("RightFoot")
RightLegIK.ChainRoot = Char:WaitForChild("RightUpperLeg")

RightLegIK.Target = RightIKObj

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Blacklist
params.FilterDescendantsInstances = {Char,IKController,workspace.CurrentCamera} -- workspace camera if you are using a view model

-- disable server-sided IK (more smooth for client)
Char:WaitForChild("Humanoid"):WaitForChild("LeftLeg").Enabled = false
Char:WaitForChild("Humanoid"):WaitForChild("RightLeg").Enabled = false

RunService.RenderStepped:Connect(function()
	local LeftRay = workspace:Raycast(Vector3.new(Char.LeftFoot.Position.X,Char.LeftFoot.Position.Y,Char.LeftFoot.Position.Z),Vector3.new(0,-1,0)*50,params)
	if LeftRay then
		LeftIKObj.CFrame = CFrame.new(LeftRay.Position,LeftRay.Normal)
	end
	local RightRay = workspace:Raycast(Vector3.new(Char.RightFoot.Position.X,Char.RightFoot.Position.Y,Char.RightFoot.Position.Z),Vector3.new(0,-1,0)*50,params)
	if RightRay then
		RightIKObj.CFrame = CFrame.new(RightRay.Position,RightRay.Normal)
	end
end)