local General = {}

function General.StopAnimation(Humanoid)
	for i,v in pairs(Humanoid:GetPlayingAnimationTracks()) do
		v:Stop()
	end
end

function General.CanCollide(Obj, Collide)
	for i,v in pairs(Obj:GetChildren()) do
		if v:IsA("BasePart") then
			v.CanCollide = Collide
		end
		if #v:GetChildren() >= 1 then
			General.CanCollide(v, Collide)
		end
	end
end


return General
