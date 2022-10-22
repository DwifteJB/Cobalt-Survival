local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.Remotes
local ServerStorage = game.ServerStorage
local SpawnItem = require(script.Parent.Parent.Modules.SpawnItem)
local InvManager = require(script.Parent.Parent.Modules.InventoryManager)
local Tags = ServerStorage:WaitForChild("Tags")
local Links = Tags:WaitForChild("LinkedContainers")
local Items = Tags:WaitForChild("Items")
local DroppedItems = workspace.DroppedItems
local Bags = DroppedItems.Bags

local Despawner = {}

function Despawner.Storage(Tag,Time,Settings)
	coroutine.wrap(function()
		delay(Time,function()
			if Links[Tag] then
				local SavedPos
				if not Links[Tag] then return end
				if Links[Tag].Value:IsA("Model") then
					SavedPos = Links[Tag].Value.PrimaryPart.CFrame
				else
					SavedPos = Links[Tag].Value.CFrame
				end

				Links[Tag].Value:Destroy()
				if Settings then
					if Settings.SpawnAnother then
						-- spawn a bag
						
						local newPart = Settings.Part:Clone()
						if Settings.Name then
							newPart.Name = Settings.Name
						end
						local T = Instance.new("IntValue")
						T.Name = "Tag"
						T.Value = Tag
						T.Parent = newPart
						newPart.CFrame = SavedPos+Vector3.new(0,3,0)
						newPart.Parent = Bags
						Links[Tag].Value = newPart
						if not Settings.DespawnTime then
							Settings.DespawnTime = Time
						end
						Despawner.Storage(Tag,Settings.DespawnTime)
						return
					end
				end
				InvManager.Storage.Delete(tostring(Tag))
				Links[Tag]:Destroy()
			end
		end)
	end)()
end


return Despawner
