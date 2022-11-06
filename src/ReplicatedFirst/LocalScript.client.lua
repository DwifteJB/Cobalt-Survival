game.ReplicatedFirst:RemoveDefaultLoadingScreen()
local PlayerGUI = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local GUI = script.Loading:Clone()
GUI.Parent = PlayerGUI

local ContentProvider = game:GetService("ContentProvider")



local Loading = Instance.new("Folder")
Loading.Name = "Loading"
Loading.Parent = workspace

local Framework = Instance.new("BoolValue")
Framework.Value = false
Framework.Name = "Framework"
Framework.Parent = Loading

local Need2Load = {
    game:GetService("ReplicatedStorage"),
    workspace,
    game:GetService("StarterGui")
}

coroutine.wrap(function()
    ContentProvider:PreloadAsync(Need2Load)
end)()

while ContentProvider.RequestQueueSize > 0 do
    GUI.BKG.Preload.Text = string.format("Loading world (%s remaining)",tostring(ContentProvider.RequestQueueSize) )
    task.wait()
end

while Framework.Value == false do
    GUI.BKG.Preload.Text = "Waiting for framework..."
    task.wait()
end


GUI:Destroy()