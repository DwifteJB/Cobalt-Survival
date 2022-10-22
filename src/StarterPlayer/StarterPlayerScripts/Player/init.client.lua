local starterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Remotes = game:GetService("ReplicatedStorage").Remotes
local mouse = player:GetMouse()
local old = nil
local Camera = workspace.CurrentCamera


-- set global vars
_G.InInv = false

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