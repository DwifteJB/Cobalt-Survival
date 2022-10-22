local Tracked = {}

local PT = {}

function PT:PlayersInActionWithKey(Action,AKey)
	local playerIds = {}
	for key,val in Tracked do
		pcall(function()
			if val[Action] == AKey then
				table.insert(playerIds,key)
			end
		end)
	end
	return playerIds
end

function PT:PlayersInAction(Action)
	local playerIds = {}
	for key,val in Tracked do
		pcall(function()
			if val[Action] then
				table.insert(playerIds,key)
			end
		end)
	end
	return playerIds
end

function PT.ChangePlayerAction(player,Action)
	print("Changed",player.Name,"action to",Action)
	Tracked[player.UserId] = Action
end

function PT.GetAction(player)
	return Tracked[player.UserId]
end

return PT
