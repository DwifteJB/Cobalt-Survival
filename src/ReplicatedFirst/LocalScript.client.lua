local ContentProvider = game:GetService("ContentProvider")
game.ReplicatedFirst:RemoveDefaultLoadingScreen()
local PlayerGUI = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local GUI = script.Loading:Clone()
GUI.Parent = PlayerGUI

local Need2Load = {
    game:GetService("ReplicatedStorage"),
    workspace,
    game:GetService("StarterGui")
}

coroutine.wrap(function()
    ContentProvider:PreloadAsync(Need2Load)
end)()

while ContentProvider.RequestQueueSize > 0 do
    GUI.ImageLabel.Preload.Text = string.format("Loading world (%s remaining)",tostring(ContentProvider.RequestQueueSize) )
    wait()
end


GUI:Destroy()