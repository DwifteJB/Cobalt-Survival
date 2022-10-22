local allCooldowns = {}
local Cooldown = {}

function Cooldown.Fire(player,event,timed)
	if not Cooldown[player.UserId] then
		Cooldown[player.UserId] = {}
	end
	if Cooldown[player.UserId][event] then
		if Cooldown[player.UserId][event] <= os.clock() then
			Cooldown[player.UserId][event] = os.clock() + timed
			return true
		else
			return false
		end
	else
		Cooldown[player.UserId][event] = os.clock() + timed
		return true
	end

end


return Cooldown
