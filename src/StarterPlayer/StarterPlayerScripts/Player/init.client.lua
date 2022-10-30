local starterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.Remotes
local mouse = player:GetMouse()
local old = nil
local Camera = workspace.CurrentCamera


-- set global vars
_G.InInv = false

-- preload anims

local Preload = Instance.new("Folder")
Preload.Parent = workspace.CurrentCamera
Preload.Name = "ViewModels"

for _,ViewModel in game:GetService("ReplicatedStorage").ViewModels:GetChildren() do
    local VM = ViewModel:Clone()
    VM.PrimaryPart.Anchored = true
    VM:SetPrimaryPartCFrame(CFrame.new(0,-100,0))
    VM.Parent = Preload
	for _,v in VM.ClientAnimations:GetChildren() do
		if v:IsA("Folder") then
			for _, d in v:GetChildren() do
				if d:IsA("Animation") then
					VM:WaitForChild("Humanoid"):LoadAnimation(d)
				end
			end
		end

		if v:IsA("Animation") then
			VM:WaitForChild("Humanoid"):LoadAnimation(v)
		end
	end
end


starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
coroutine.wrap(function()
	local timeout = 5
	local t = tick()
	while not pcall(starterGui.SetCore,starterGui, "TopBarEnabled",false) and tick()-t<timeout do
		wait()
	end
end)()



Camera:GetPropertyChangedSignal("CFrame"):Connect(function()
	if player.Character:WaitForChild("UpperTorso",1):FindFirstChild("Waist", true) and _G.InInv == false then
		if old == nil then
			old=math.asin((mouse.Hit.p - mouse.Origin.p).unit.y)
		end
		local chckAmount = 0.00001 + (#Players:GetPlayers() * 0.000002)
		local rtVal = math.asin((mouse.Hit.p - mouse.Origin.p).unit.y)

		if (rtVal - old) >= chckAmount or (rtVal - old) <= -chckAmount then
			old = rtVal
			Remotes.Core.ReplicateRotation:FireServer(rtVal)
		end
	end
end)