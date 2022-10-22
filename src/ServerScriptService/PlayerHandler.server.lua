local players = game:GetService("Players")
local PlayerEvents = script.Parent.Logic.PlayerEvents

players.PlayerAdded:Connect(function(player)
	
	player.DevEnableMouseLock = false
	PlayerEvents.PlayerAdded:Fire(player)
	
	player.CharacterAdded:Connect(function(character)
		--CharacterAdded CharacterAdded
		character.Archivable = true
		PlayerEvents.CharacterAdded:Fire(player,character)
		character:WaitForChild("Humanoid").Died:Connect(function()
			PlayerEvents.PlayerDied:Fire(player,character)
		end)
		
	end)
end)