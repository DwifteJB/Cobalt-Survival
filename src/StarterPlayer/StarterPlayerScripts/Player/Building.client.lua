local player = game:GetService("Players").LocalPlayer
local mouse = player:GetMouse()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Building = require(ReplicatedStorage.Modules.Building)
local Data = require(ReplicatedStorage.Modules.Data)
local General = require(script.Parent.Modules.General)

local BuildFolder = Instance.new("Folder")
BuildFolder.Name = "Builds"
BuildFolder.Parent = workspace
local BuildPart = nil
local building = false
local attachedTo = false
local attachedAttachment = nil
local BuildRad = 9

local RenderStepped = {}
function RenderStepped.Build()
	if building == true then
		BuildPart.CanCollide = false
		local shouldChange = true
		local unitR = workspace.CurrentCamera:ScreenPointToRay(mouse.X,mouse.Y,1)

		if mouse.Target then
			local pm = RaycastParams.new()
			pm.FilterType = Enum.RaycastFilterType.Blacklist
			pm.FilterDescendantsInstances = {player,player.Character,workspace.CurrentCamera,BuildFolder}
			local ray = workspace:Raycast(unitR.Origin,unitR.Direction*BuildRad,pm)

			if ray and ray.Instance then
				local rayIns = ray.Instance
				local rayPos = ray.Position
				if attachedTo == true then
					if (ray.Position - attachedAttachment.WorldPosition).Magnitude > 5 or attachedAttachment:GetAttribute("CanSnap") == false then
						attachedTo = false
						attachedAttachment = nil
					else
						local offset = Building.calculateOffset(BuildPart,attachedAttachment)
						shouldChange = false
						BuildPart.CFrame = CFrame.new(attachedAttachment.WorldPosition+offset) * CFrame.Angles(math.rad(attachedAttachment.Orientation.X),math.rad(attachedAttachment.Orientation.Y),math.rad(attachedAttachment.Orientation.Z))
						BuildPart.Color = Color3.new(0,0.56,1)
					end
				elseif shouldChange == true then
					for _, attachment in pairs(rayIns:GetChildren()) do
						if attachment:IsA("Attachment") then
							local attachWPOs = attachment.WorldPosition
							local attachOrientation = attachment.Orientation
							if (ray.Position - attachWPOs).Magnitude < 3 then
								if Data.CanSnapTo[BuildPart.Name][attachment.Name] == true then
									if attachment:GetAttribute("CanSnap") == true then
										local offset = Building.calculateOffset(BuildPart,attachment)
										attachedTo = true
										attachedAttachment = attachment
										shouldChange = false
										BuildPart.CFrame = CFrame.new(attachWPOs+offset) * CFrame.Angles(math.rad(attachOrientation.X),math.rad(attachOrientation.Y),math.rad(attachOrientation.Z))
										BuildPart.Color = Color3.new(0,0.56,1)
									end
								end
							end
						end
					end
				end
				if shouldChange == true then
					attachedAttachment = nil
					attachedTo = false
					if ray.Instance == workspace.Terrain then
						BuildPart.Color = Color3.new(0,0.2,0.75)
						BuildPart.Position = ray.Position
					else
						BuildPart.Color = Color3.new(0.86,0,0.12)
						BuildPart.Position = CFrame.new(unitR.Origin+unitR.Direction*BuildRad).Position
					end
					shouldChange = false
				end
			end
			if shouldChange == true then --- and mouse.Target == BuildPart
				BuildPart.Color = Color3.new(0.86,0,0.12)
				BuildPart.Position = CFrame.new(unitR.Origin+unitR.Direction*BuildRad).Position
			end
		elseif shouldChange == true then
			BuildPart.Color = Color3.new(0.86,0,0.12)
			BuildPart.Position = CFrame.new(unitR.Origin+unitR.Direction*BuildRad).Position
			--unitR.Origin,unitR.Direction*10
		end
	end
end

function createBuilding(PartName)
	local GhostPart = ReplicatedStorage.Items.Buildings[PartName]:Clone()
	GhostPart.Parent = BuildFolder
	GhostPart.Transparency = 0.7
	GhostPart.Material = Enum.Material.Plastic
	GhostPart.Color = Color3.new(0.86,0,0.12)
	GhostPart.Anchored = true
	General.CanCollide(GhostPart,false)
	building = true
	return GhostPart
end