local Building = {}


function Building.calculateOffset(BuildPart,attachment)
	local offset = Vector3.new(0,0,0)
	if BuildPart.Name == "Wall" then
		if attachment.Name == "Right" then
			offset = Vector3.new((BuildPart.Size.X/2),0,0)
		end
		if attachment.Name == "Left" then
			offset = Vector3.new(-(BuildPart.Size.X/2),0,0)
		end
		if attachment.Name == "Top" or attachment.Name == "Bottom" then
			offset = Vector3.new(0,(BuildPart.Size.Y/2),0)
		end
	elseif BuildPart.Name == "Foundation" then
		if attachment.Name == "Foundation" then
			if attachment.Position.X ~= 0 then
				-- if attachment is not negative
				if attachment.Position.X > 0 then
					offset = Vector3.new((BuildPart.Size.X/2),0,0)
				else
					offset = Vector3.new(-(BuildPart.Size.X/2),0,0)
				end
			elseif attachment.Position.Y ~= 0 then
				if attachment.Position.Y > 0 then
					offset = Vector3.new(0,0,(BuildPart.Size.X/2))
				else
					offset = Vector3.new(0,0,-(BuildPart.Size.X/2))
				end

			end
		end

	end
	return offset
end


return Building
