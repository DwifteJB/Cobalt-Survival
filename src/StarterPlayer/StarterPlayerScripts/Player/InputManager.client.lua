local UserInputService = game:GetService("UserInputService")
UserInputService.MouseIconEnabled = false
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Remotes = game:GetService("ReplicatedStorage").Remotes

-- Values
local debounce = false

-- Signals

local Controls = {
	["Began"]=script.Parent.Bindable.Controls.Began,
	["Ended"]=script.Parent.Bindable.Controls.Ended
}


function ParseKeycode(EnumKC)
	if EnumKC == Enum.KeyCode.One then
		return "1"
	elseif EnumKC == Enum.KeyCode.Two then
		return "2"
	elseif EnumKC == Enum.KeyCode.Three then
		return "3"
	elseif EnumKC == Enum.KeyCode.Four then
		return "4"
	elseif EnumKC == Enum.KeyCode.Five then
		return "5"
	elseif EnumKC == Enum.KeyCode.Six then
		return "6"
	end
end


UserInputService.InputBegan:Connect(function(input, gPE)
	if gPE then return end
	if input.KeyCode == Enum.KeyCode.Q then
		-- qlean
		Controls.Began.LeftLean:Fire()
	end
	if input.KeyCode == Enum.KeyCode.E then
		-- elean
		Controls.Began.RightLean:Fire()
	end
	if input.KeyCode == Enum.KeyCode.F then
		pcall(function()
			local Target = player:GetMouse().Target
			local Tag = Target:FindFirstChild("Tag") or Target.Parent:FindFirstChild("Tag")
			if Target and Tag ~= nil then
				local db = Remotes.Inventory.InteractionSystem:InvokeServer(Tag.Value,player:GetMouse().Hit.Position)
				if tonumber(db) == nil then
					local inv = Remotes.Client.Inventory.OpenInventory:Invoke(db)
					if inv == true then
						UserInputService.MouseIconEnabled = true
						_G.InInv = true
					elseif inv == false then
						UserInputService.MouseIconEnabled = false
						_G.InInv = false
					else
						return
					end
				end
			end
		end)
		-- interact
	end
	if input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.N then
		-- open inv
		local inv = Remotes.Client.Inventory.OpenInventory:Invoke()
		if inv == true then
			UserInputService.MouseIconEnabled = true
			_G.InInv = true
		elseif inv == false then
			UserInputService.MouseIconEnabled = false
			_G.InInv = false
		else
			return
		end
	end
	-- Axe --
	if table.find({Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four,Enum.KeyCode.Five,Enum.KeyCode.Six},input.KeyCode) then
		Controls.Began.Equip:Fire(ParseKeycode(input.KeyCode))
	end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		-- Sprint
		Controls.Began.Sprint:Fire()
	end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		-- aim
		Controls.Began.MouseButton2:Fire()
	end
	-- build test
	if input.KeyCode == Enum.KeyCode.R then
		-- reload
		Controls.Began.Reload:Fire()
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- shoot
		Controls.Began.MouseButton1:Fire()
	end
end)

UserInputService.InputEnded:Connect(function(input, gPE)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- shoot
		Controls.Ended.MouseButton1:Fire()
	end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		-- sprint
		Controls.Ended.Sprint:Fire()
	end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		-- aim
		Controls.Ended.MouseButton2:Fire()
	end
	if input.KeyCode == Enum.KeyCode.Q then
		-- QLean
		Controls.Ended.LeftLean:Fire()
	end
	if input.KeyCode == Enum.KeyCode.E then
		--ELean
		Controls.Ended.RightLean:Fire()
	end
end)

UserInputService.JumpRequest:Connect(function()
	Remotes.Core.Jump:FireServer()
end)