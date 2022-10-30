
local Player = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")

Player.CharacterAdded:Connect(function(character)
	script.Parent.Fade.Visible = false
	script.Parent.Fade.Transparency = 1

	character:WaitForChild("Humanoid").Died:Connect(function()
		script.Parent.Fade.Visible = true
		TweenService:Create(script.Parent.Fade,TweenInfo.new(1,Enum.EasingStyle.Sine),{Transparency=0}):Play()

	end)
end)

