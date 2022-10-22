local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.Remotes
local TextService = game:GetService("TextService")
--30
Remotes.Chat.SendChatMessage.OnServerEvent:Connect(function(player,ChatMSG)
	if string.len(ChatMSG) == 0 then return end 
	local Message = ""
	local TextObject 
	local success, errorMessage = pcall(function()
		TextObject = TextService:FilterStringAsync(ChatMSG,player.UserId)
	end)
	if not success then
		warn("Error message occured filtering player"..player.Name.."'s text:", ChatMSG," : ", errorMessage)
		return 
	end
	local suc = pcall(function()
		Message = TextObject:GetNonChatStringForBroadcastAsync()
	end)
	if not suc then
		return
	end
	if (string.len(player.DisplayName) + string.len(Message)) <= 200 then
		-- send message
		if (string.len(player.DisplayName) + string.len(Message)) > 66 then
			-- needs to create extra
			local InitialChat = string.sub(Message,1,66-string.len(player.DisplayName))
			local AddChat = string.sub(Message,67-string.len(player.DisplayName),-1)
			Remotes.Chat.SendChatMessage:FireAllClients(player,InitialChat,AddChat)
		else
			local InitialChat = string.sub(Message,1,66-string.len(player.DisplayName))
			Remotes.Chat.SendChatMessage:FireAllClients(player,InitialChat)
		end
	end
end)
