local HTTPService = game:GetService("HttpService")
local DataStore = game:GetService("DataStoreService")
local BanStore = DataStore:GetDataStore("BanStore")

--[[
		Ban System Module
		Written by Dwifte
]]--

local webhookURL = "https://hooks.hyra.io/api/webhooks/1011456852346818600/Qpr6hyTkFHRHG5opIKYtEEeEwkhCsedvhP2MSczJu3hDDjywTrkyPtnSPrInSw5Rjw8K"
local BanSystem = {}
local queue = {}
local saveLast
function BanSystem.SendOutQueue()
	while true do
		wait(0.5)
		for key,val in queue do
			if saveLast == val then 
				queue[key] = nil
				break; 
			end
			wait(0.5)
			HTTPService:PostAsync(webhookURL,val)
			saveLast = val
			queue[key] = nil
		end
	end
end
coroutine.wrap(BanSystem.SendOutQueue)()
function BanSystem.PostWarning(player,warning)
	local embed = {
		embeds = { {
			color = 129173,
			fields = { {
				name = "Username",
				value = player.Name,
				inline = true
			}, {
				name = "UserID",
				value = player.UserId,
				inline = true
			}, {
				name = "Warning",
				value = warning
			} },
			author = {
				name = "Cobalt Guard",
				url = "https://cdn.discordapp.com/attachments/1011284824029397062/1011457155251056690/cobalt.png",
				icon_url = "https://cdn.discordapp.com/attachments/1011284824029397062/1011457155251056690/cobalt.png"
			},
			footer = {
				text = "LOVE FROM CGUARD <3"
			}
		} },
		username = "Cobalt Guard Warning",
	}
	local finalData = HTTPService:JSONEncode(embed)
	local amount= 0
	for i,v in pairs(queue) do
		amount+=1
	end
	queue[amount] = finalData
end

function BanSystem.ModBanOnline(player,modName)
	BanSystem.PostManual(player.Name,player.UserId,modName)
	BanStore:SetAsync(player.UserId,modName)
	player:Kick(string.format("[ Cobalt Moderation ] You have been banned by %s",modName))
	
end
function BanSystem.AnticheatBanOnline(player,code,reason)
	BanSystem.PostAnticheat(player.Name,player.UserId,code,reason)
	BanStore:SetAsync(player.UserId,code)
	print(player.Name, "would have been banned for ", code)
	--player:Kick("[ CGuard ] You have been banned for suspicious activities.")
end
function BanSystem.ModBanOffline(playerUserId,modName)
	BanSystem.PostManual(playerUserId,playerUserId,modName)
	BanStore:SetAsync(playerUserId,modName)
end

function BanSystem.PostAnticheat(playerName,playerID,BanCode,Reason)
	local embed = {
		embeds = { {
			color = 1709007,
			fields = { {
				name = "Username",
				value = playerName,
				inline = true
			}, {
				name = "UserID",
				value = tostring(playerID),
				inline = true
			}, {
				name = "Ban Code",
				value = BanCode
			}, {
				name = "Info",
				value = Reason
			} },
			author = {
				name = "Cobalt Guard",
				url = "https://cdn.discordapp.com/attachments/1011284824029397062/1011457155251056690/cobalt.png",
				icon_url = "https://cdn.discordapp.com/attachments/1011284824029397062/1011457155251056690/cobalt.png"
			},
			footer = {
				text = "LOVE FROM CGUARD <3"
			}
		} },
		username = "Cobalt Guard",
	}
	local finalData = HTTPService:JSONEncode(embed)
	local amount= 0
	for i,v in pairs(queue) do
		amount+=1
	end
	queue[amount] = finalData
end

function BanSystem.PostManual(playerName,playerID,moderationName)
	if playerName == playerID then
		playerName = "Unknown"
	end
	local embed = {
		embeds = { {
			color = 747193,
			fields = { {
				name = "Username",
				value = playerName,
				inline = true
			}, {
				name = "UserID",
				value = tostring(playerID),
				inline = true
			}, {
				name = "Banned by:",
				value = moderationName
			} },
			author = {
				name = "Cobalt Moderation Report",
				url = "https://cdn.discordapp.com/attachments/1011284824029397062/1011457155251056690/cobalt.png",
				icon_url = "https://cdn.discordapp.com/attachments/1011284824029397062/1011457155251056690/cobalt.png"
			},
			footer = {
				text = "Cobalt Moderation Team Report"
			}
		} },
		username = "Cobalt Moderation Team",
	}
	local finalData = HTTPService:JSONEncode(embed)
	local amount= 0
	for i,v in pairs(queue) do
		amount+=1
	end
	queue[amount] = finalData
end

return BanSystem
