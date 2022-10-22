local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.Remotes
local Data = require(ReplicatedStorage.Modules.Data)
local Cooldown = require(script.Parent.Modules.CooldownSystem)
local allBuilds = workspace.Buildings
local Building = require(ReplicatedStorage.Modules.Building)

Remotes.Building.Build.OnServerEvent:Connect(function(player,mouseHit,attachment,BuildPartName)
	if Cooldown.Fire(player,"Build",1) == false then return end
	if attachment:IsA("Attachment") and attachment:GetAttribute("CanSnap") == true then
		local attachWPOs = attachment.WorldPosition
		local attachOrientation = attachment.Orientation
		if player:DistanceFromCharacter(attachment.WorldPosition) < 13 and player:DistanceFromCharacter(attachment.Parent.Position) < 13 then
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Blacklist
			rayParams.FilterDescendantsInstances = {player.Character,player}
			local ray = workspace:Raycast(player.Character.Head.Position, (mouseHit -player.Character.Head.Position).Unit * 100, rayParams)			
			if ray then
				if (ray.Position - attachment.WorldPosition).Magnitude < 4 then
					local BuildPartClone = ReplicatedStorage.Items.Buildings[BuildPartName]:Clone()
					local offset = Building.calculateOffset(BuildPartClone,attachment)
					BuildPartClone.CFrame = CFrame.new(attachWPOs+offset) * CFrame.Angles(math.rad(attachOrientation.X),math.rad(attachOrientation.Y),math.rad(attachOrientation.Z))
					BuildPartClone.Parent = allBuilds
					attachment:SetAttribute("CanSnap",false)
					for i,newAttach in BuildPartClone:GetChildren() do
						for i,d in workspace:GetPartBoundsInBox(BuildPartClone.CFrame,BuildPartClone.Size) do
							if d.Parent == allBuilds and BuildPartClone ~= d then
								for i,OldAttach in d:GetChildren() do
									if (newAttach:IsA("Attachment") and OldAttach:IsA("Attachment")) and OldAttach.Name == attachment.Name and (newAttach.WorldPosition - OldAttach.WorldPosition).Magnitude < 2 and (OldAttach:GetAttribute("CanSnap") == true or newAttach:GetAttribute("CanSnap")) then
										OldAttach:SetAttribute("CanSnap",false)
										newAttach:SetAttribute("CanSnap",false)
									end
								end
							end
						end
					end
					print("built lol")
				end
			end
		end
	end
end)

