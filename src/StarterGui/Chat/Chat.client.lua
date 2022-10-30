--[[ 
	epic chat script
	made by dwifte lol
]]
local players = game:GetService("Players")
local player = players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.Remotes
local ChatMessage = ReplicatedStorage.UI.Chat.InitialChatMessage
local AdditionalSpace = ReplicatedStorage.UI.Chat.AdditionalSpace

local Chat = script.Parent.ChatUI
Chat.AutomaticCanvasSize = Enum.AutomaticSize.Y
local InputMSG = script.Parent.InputMessage

local UIS = game:GetService("UserInputService")
local lastTimeInteracted = os.clock()

Chat.MouseEnter:Connect(function()
	lastTimeInteracted = os.clock()
	InputMSG.Visible = true
	Chat.Visible = true
end)

coroutine.wrap(function()
	while task.wait(5) do
		if lastTimeInteracted + 10 < os.clock() then
			InputMSG.Text = ""
			InputMSG.Visible = false
			Chat.Visible = false
		end
	end
end)()

UIS.InputEnded:Connect(function(input,gPE)
	if gPE == true then return end
	if input.KeyCode == Enum.KeyCode.Slash then
		-- chat
		InputMSG.Visible = true
		InputMSG:CaptureFocus()
		InputMSG.Text = ""
		Chat.Visible = true
		lastTimeInteracted = os.clock()
	end
end)

InputMSG.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		if InputMSG.Text and string.len(InputMSG.Text) < 200-(string.len(player.DisplayName)) then
			Remotes.Chat.SendChatMessage:FireServer(InputMSG.Text)
			
			InputMSG.Text = ""
			lastTimeInteracted = os.clock()
		end
	end
end)

Remotes.Chat.SendChatMessage.OnClientEvent:Connect(function(playerChat,initialChat,AdditionalChat)
	local ClonedChatMsg = ChatMessage:Clone()
	ClonedChatMsg.Name = playerChat.UserId.."-message"
	ClonedChatMsg.UserIcon.Image = players:GetUserThumbnailAsync(playerChat.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
	ClonedChatMsg.Message.Text = string.format("<font weight=\"bold\"><stroke color=\"#000000\" thickness=\"0.1\"><font color=\"#0C4156\">%s</font><font color=\"#ffffff\">:</font></stroke></font> %s",playerChat.DisplayName,initialChat)
	ClonedChatMsg.Parent = Chat
	if AdditionalChat ~= nil then
		local AdditionalClone = AdditionalSpace:Clone()
		AdditionalClone.Name = playerChat.UserId.."-extended"
		AdditionalClone.Message.Text = AdditionalChat
		AdditionalClone.Parent = Chat
	end
	lastTimeInteracted = os.clock()
	InputMSG.Visible = true
	Chat.Visible = true
end)
