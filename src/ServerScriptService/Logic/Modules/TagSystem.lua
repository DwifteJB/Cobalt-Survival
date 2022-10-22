local ServerStorage = game:GetService("ServerStorage")


local Tags = ServerStorage:WaitForChild("Tags")
local Items = Tags:WaitForChild("Items")
local Harvestable = Tags:WaitForChild("Harvestables")
local TS = {}

function TS.RemoveTag(tag)
	if Items[tag] then
		Items[tag]:Destroy()
	end	
end

function TS.CreateNewHarvestableTag()
	local HarvestableGetChildren = Harvestable:GetChildren()
	local TagTag = 0
	for i = 1, #HarvestableGetChildren do
		if not Harvestable:FindFirstChild(TagTag) then
			return TagTag
		end
		TagTag += 1
	end
	return TagTag
end
function TS.FindHarvestableWithTag(Tag)
	if Harvestable:FindFirstChild(Tag) then
		return Harvestable:FindFirstChild(Tag)
	else
		return false
	end
end

function TS.FindItemWithTag(Tag) 
	if Items:FindFirstChild(Tag) then
		return Items:FindFirstChild(Tag)
	end
end

function TS.CreateNewItemTag()
	local ItemsGetChildren = Items:GetChildren()
	local TagTag = 0
	for i = 1, #ItemsGetChildren do
		if not Items:FindFirstChild(TagTag) then
			return TagTag
		end
		TagTag += 1
	end
	return TagTag
end

function TS.FindDuplicatedDroppedItem(Tag)
	local ItemsChild = workspace:WaitForChild("DroppedItems"):GetChildren()
	local amount = 0
	for _, child in pairs(ItemsChild) do
		if not child:FindFirstChild(Tag) then
			child:Destroy()
		end
		if child.Tag.Value == Tag then
			amount = amount + 1
		end
	end
	return amount
end

return TS