local DataStoreService = game:GetService("DataStoreService")
local Statistics = DataStoreService:GetDataStore("Statistics")
local CombatLog = {}



local DM = {}
DM.Statistics = {}
DM.CombatLog = {}
local queue = {}
function DM.SendOutQueue()
	while wait(5) do
		for key,val in queue do
			wait(0.5)
			Statistics:SetAsync(key,val)
			queue[key] = nil
		end
	end
end
coroutine.wrap(DM.SendOutQueue)()

function StatisticsIfEmpty(player)
	if tonumber(player) then
		if not Statistics:GetAsync(player) then
			Statistics:SetAsync(player,{})
		end
		return Statistics:GetAsync(player)
	else
		if not Statistics:GetAsync(player.UserId) then
			Statistics:SetAsync(player.UserId,{})
		end
		return Statistics:GetAsync(player.UserId)
	end

end


function DM.CombatLog.AddDamageData(Attacker,Recipient,Damage,ToolUsed,PartHit)
	--soon.

	if not CombatLog[Attacker.UserId] then
		CombatLog[Attacker.UserId] = {}
	end

	CombatLog[Attacker.UserId][#CombatLog[Attacker.UserId]+1] = {
		["Time"]=os.clock(),
		["RecipientDetails"]={
			["ID"]=Recipient.UserId,
			["Name"]=Recipient.Name,
			["CFrame"]=Recipient.Character.HumanoidRootPart.CFrame
		},
		["AttackerDetails"]={
			["CFrame"]=Attacker.Character.HumanoidRootPart.CFrame,
			["Name"]=Attacker.Name,
			["ID"]=Attacker.UserId
		},
		["Damage"]=Damage,
		["ToolUsed"]=ToolUsed,
		["PartHit"]=PartHit
	}

end

function DM.CombatLog.GetAllAttackedData(Attacker)
	if not CombatLog[Attacker.UserId] then
		CombatLog[Attacker.UserId] = {}
	end
	return CombatLog[Attacker.UserId]
end

function DM.CombatLog.GetAllRecipientData(Recipient)
	local RData = {}
	for _,v in CombatLog do
		for _,CL in v do
			if v.RecipientDetails.ID == Recipient.UserId then
				table.insert(RData,CL)
			end
		end
	end
	return RData
end


function DM.Statistics.AddValueToStat(player,key,val)
	if tonumber(player) then
		player = player.UserId
	end
	local StatData = StatisticsIfEmpty(player)
	if not StatData[key] then
		StatData[key] = val
	else
		StatData[key] += val
	end
	queue[player.UserId] = StatData

end

function DM.Statistics.AddToGlobalStat(key,val)
	local GLStat = Statistics:GetAsync("Global")
	
	if not GLStat[key] then
		GLStat[key] = val
	else
		GLStat[key] += val
	end
	queue["Global"] = GLStat
end


return DM
