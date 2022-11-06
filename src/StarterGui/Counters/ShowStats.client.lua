local Gui = game:GetService("GuiService")
local Player = game:GetService("Players").LocalPlayer
local Disconnect = script.Parent.AllStats.Disconnect

coroutine.wrap(function()
	while wait(3) do
		if Player:GetNetworkPing() * 1000 > 200 then
			if script.Parent.Stats:FindFirstChild("Disconnect") then
				script.Parent.Stats:FindFirstChild("Disconnect"):Destroy()
			end
			local D = Disconnect:Clone()
			D.Visible = true
			D.Parent = script.Parent.Stats
		else
			if script.Parent.Stats:FindFirstChild("Disconnect") then
				script.Parent.Stats:FindFirstChild("Disconnect"):Destroy()
			end
		end
	end
end)()

Gui:SetGameplayPausedNotificationEnabled(false)

Player:GetPropertyChangedSignal("GameplayPaused"):Connect(function()
	if Player.GameplayPaused then
		if script.Parent.Stats:FindFirstChild("Disconnect") then
			script.Parent.Stats:FindFirstChild("Disconnect"):Destroy()
		end
		local D = Disconnect:Clone()
		D.Visible = true
		D.Parent = script.Parent.Stats
	else
		if script.Parent.Stats:FindFirstChild("Disconnect") then
			script.Parent.Stats:FindFirstChild("Disconnect"):Destroy()
		end
	end
end)
