

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TagSystem = require(script.Parent:WaitForChild("TagSystem"))
local DataManager = require(script.Parent:WaitForChild("DataManager"))
local Webhook = "https://hooks.hyra.io/api/webhooks/1012512294514724904/zVe8JgXkylqoHyZCgxMnFdSRHZMYRAykZqeN2H0gTtrgFNSzfdEKldsCkIekFDWbT3yk"
local HTTPService = game:GetService("HttpService")
local queue = {}


local DS = {}

function DS.SendOutQueue()
	while wait(5) do

		for key,val in queue do
			wait(1.2)
			HTTPService:PostAsync(Webhook,val)
			queue[key] = nil
		end
	end
end
coroutine.wrap(DS.SendOutQueue)()

function DS.ParsePartShot(partShot)
	-- Head
	if partShot.Name == "Head" or partShot.Name == "Handle" then
		return "Head" 
	end
	if partShot.Name == "UpperTorso" or partShot.Name == "HumanoidRootPart" or partShot.Name == "LowerTorso" or partShot.Name == "RightHand" or partShot.Name == "RightLowerArm" or partShot.Name == "RightUpperArm" or partShot.Name == "Lefthand" or partShot.Name == "LeftLowerArm" or partShot.Name == "LeftUpperArm" then
		return "Torso"
	end
	if partShot.Name == "LeftLowerLeg" or partShot.Name == "LeftUpperLeg" or partShot.Name == "RightUpperLeg" or partShot.Name == "RightLowerLeg" then
		return "Legs"
	end
	if partShot.Name == "RightFoot" or partShot.Name == "LeftFoot" then
		return "Feet"
	end
	return "Feet"
end

function DS.PartDamage(Modifier)
	if Modifier == "Head" then
		return 2.0
	elseif Modifier == "Torso" then
		return 1.0
	elseif Modifier == "Legs" then
		return 0.75
	elseif Modifier == "Feet" then
		return 0.75
	end
end

function DS.CalculateDamage(damage,partShot,playerShot)
	if ServerStorage.Stats.Inventories[playerShot.Name] then
		-- we shot a player!
		local ModifierToFind = DS.ParsePartShot(partShot)
		local PartOuchie = DS.PartDamage(ModifierToFind)
		if ServerStorage.Stats.Inventories[playerShot.Name].Equipped[ModifierToFind] then
			local tag = ServerStorage.Stats.Inventories[playerShot.Name].Equipped[ModifierToFind].Value
			if tag ~= nil then
				if tag >= -1 then
					return damage * PartOuchie
				else
					local Stuf = TagSystem.FindItemWithTag(tag)
					if Stuf.Owner.Value == playerShot.UserId then
						return math.floor(damage * (PartOuchie / Stuf.Protection.Value))
					end
				end

			end
		end
	else
		return math.floor(damage)
	end
end

function DS.Log2DS(playerAttacking,playerAttacked,partShot,damage,toolUsed)
	local embed = {
		embeds = { {
			color = 5966571,
			fields = { {
				name = "Damage Dealt",
				value = damage,
				inline = true
			}, {
				name = "Weapon Used",
				value = toolUsed,
				inline = true
			}, {
				name = "Victim's Health Remaining",
				value = playerAttacked.Character.Humanoid.Health
			}, {
				name = "Attacker's Health",
				value = playerAttacking.Character.Humanoid.Health
			}, {
				name = "Part Hit",
				value = partShot

			}, },
			author = {
				name = string.format("%s VS %s",playerAttacking.Name,playerAttacked.Name),
				url = "https://cdn.discordapp.com/attachments/1011284824029397062/1011457155251056690/cobalt.png",
				icon_url = "https://cdn.discordapp.com/attachments/1011284824029397062/1011457155251056690/cobalt.png"
			},
			footer = {
				text = "Combat Logger - Not an IP Logger"
			}
		} },
		username = game.Name,
		attachments = { }
	}
	local finalEmbed = HTTPService:JSONEncode(embed)
	local amount= 0
	for _,_ in pairs(queue) do
		amount+=1
	end
	queue[amount] = finalEmbed
end


function DS.DamagePlayer(playerAttacking,playerAttacked,partShot,damage,toolUsed)
	-- function does all calculations for you.
	-- plus logs to combat log
	if playerAttacked.Character.Humanoid.Health < 0 then return end
	local dmg = DS.CalculateDamage(damage,partShot,playerAttacked)
	local ModifierToFind = DS.ParsePartShot(partShot)
	coroutine.wrap(DS.Log2DS)(playerAttacking,playerAttacked,partShot,dmg,toolUsed)
	if ModifierToFind == "Head" then
		ReplicatedStorage.Remotes.Core.Hitmarker:FireClient(playerAttacking,true)
	else
		ReplicatedStorage.Remotes.Core.Hitmarker:FireClient(playerAttacking,false)
	end
	DataManager.Statistics.AddValueToStat(playerAttacking,"Damage",damage)
	DataManager.Statistics.AddToGlobalStat("Damage",damage)
	DataManager.CombatLog.AddDamageData(playerAttacking,playerAttacked,damage,toolUsed,ModifierToFind)
	playerAttacked.Character.Humanoid:TakeDamage(dmg)
end

function DS.DamageNPC(player,Humanoid,partShot,damage)
	local ModifierToFind = DS.ParsePartShot(partShot)
	local PartOuchie = DS.PartDamage(ModifierToFind)
	if ModifierToFind == "Head" then
		ReplicatedStorage.Remotes.Core.Hitmarker:FireClient(player,true)
	else
		ReplicatedStorage.Remotes.Core.Hitmarker:FireClient(player,false)
	end
	Humanoid:TakeDamage(damage * PartOuchie)
end

function DS.FindPlayerFromName(Name)

end

return DS
