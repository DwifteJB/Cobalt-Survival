
--[[
		Main Status System
		Written by Dwifte
]]--

local players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local PlayerEvents = script.Parent.PlayerEvents
local PlayerStatus = Instance.new("Folder")
PlayerStatus.Name = "PlayerStatus"
PlayerStatus.Parent = ServerStorage:WaitForChild("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.Remotes
local Settings = ReplicatedStorage.Settings

function mainSys(player)

	local Thirst = PlayerStatus[player.Name].Thirst
	local Hunger = PlayerStatus[player.Name].Hunger
	while true do
		wait(math.random(6,20))
		if Thirst.Value <= 0 or Hunger.Value <= 0 then
			player.Character.Humanoid:TakeDamage(math.random(3,8))
		end
		local randThirstValue = Thirst.Value - math.random(4,7)
		local randHungerValue = Hunger.Value - math.random(4,7)
		if randHungerValue < 0 then
			Hunger.Value = 0
		else
			Hunger.Value = randHungerValue
		end
		if randThirstValue < 0 then
			Thirst.Value = 0
		else
			Thirst.Value = randThirstValue
		end
		Remotes.Core.UpdateHungerThirst:FireClient(player,Settings.MaxHunger.Value,Settings.MaxThirst.Value,Thirst.Value,Hunger.Value)
	end
end

PlayerEvents.PlayerAdded.Event:Connect(function(player)
	local PlrStats = Instance.new("Folder")
	PlrStats.Name = player.Name
	PlrStats.Parent = PlayerStatus

	local Thirst = Instance.new("IntValue")
	Thirst.Name = "Thirst"
	Thirst.Value = Settings.MaxThirst.Value / 3 -- math.random(3,5)
	Thirst.Parent = PlayerStatus[player.Name]


	local Hunger = Instance.new("IntValue")
	Hunger.Name = "Hunger"
	Hunger.Value = Settings.MaxHunger.Value /  3
	Hunger.Parent = PlayerStatus[player.Name]
	coroutine.wrap(mainSys)(player)
end)

PlayerEvents.CharacterAdded.Event:Connect(function(player,character)
	if PlayerEvents:FindFirstChild(player.Name) then
		PlayerStatus[player.Name].Hunger.Value = Settings.MaxHunger.Value / 3
		PlayerStatus[player.Name].Thirst.Value = Settings.MaxThirst.Value / 3
		Remotes.Core.UpdateHungerThirst:FireClient(player,Settings.MaxHunger.Value,Settings.MaxThirst.Value,PlayerStatus[player.Name].Thirst.Value,PlayerStatus[player.Name].Hunger.Value)
	end

end)
