game.ReplicatedFirst:RemoveDefaultLoadingScreen()
local PlayerGUI = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local GUI = script.LoadingScreen:Clone()
GUI.Parent = PlayerGUI
repeat wait(1) until game:IsLoaded()
wait(5)

GUI:Destroy()