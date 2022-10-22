local Gui = game:GetService("GuiService")
local Player = game:GetService("Players").LocalPlayer
local Disconnect = script.Parent.Disconnect
local Remotes = game:GetService("ReplicatedStorage").Remotes

coroutine.wrap(function()
	while wait(3) do
		if Player:GetNetworkPing() * 1000 > 200 then
			Disconnect.Visible = true
		else
			Disconnect.Visible = false
		end
	end
end)()

Gui:SetGameplayPausedNotificationEnabled(false)

Player:GetPropertyChangedSignal("GameplayPaused"):Connect(function()
	if Player.GameplayPaused then
		Disconnect.Visible = true
	else
		Disconnect.Visible = false
	end
end)
