-- wsup, homie..... get out of here. <3 dwifte :)
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
ReplicatedStorage = game:GetService("ReplicatedStorage")
local _WorkSpace_ = game:GetService("Workspace")
repeat wait() until game:IsLoaded()

local WhitelistGuis = {"Chat","CenterUI","Stats","LoadingGui","ChatInstallVerifier","Freecom","KCoreUI","TouchGui","TopbarPlus","BubbleChat","RbxCameraUI","Inventory","HotBar","Menu","Death","TeamUI","Counters"}
local banned = {"BodyGyro","BodyPosition","BodyForce","BodyVelocity","BodyAngularVelocity","ModuleScript","Animation"}
local bannedState = {6,11,14,16}
function Bye(num)
	pcall(function()
		ReplicatedStorage.Remotes.Misc.Goodbye:InvokeServer(num)
	end)
end
coroutine.resume(coroutine.create(function()
	while wait(5) do
		pcall(function()
			for _, u in pairs(Player.PlayerGui:GetChildren()) do
				if table.find(WhitelistGuis, u.Name) then return end
				if u:IsA("LocalScript") or u.Name == "Dex" then
					Bye("015")
				end
			end
			if _WorkSpace_:GetRealPhysicsFPS() > 60 then
				Bye("016")
			end
		end)
	end
end))

Player.Character:WaitForChild("Humanoid").StateChanged:Connect(function(Prev,Curr)
	if table.find(bannedState, Curr.Value) then
		Bye("017")
	end
end)


Player.PlayerGui.ChildAdded:Connect(function(ui)
	if not table.find(WhitelistGuis,ui.Name) then
		Bye("015")
	end
end)

Player.Character.DescendantAdded:Connect(function(Descent)
	pcall(function()
		if table.Find(banned,Descent.Class) then
			Bye("019")
		end
	end)
end)
Bye("014")
local fldName
local tab = {}
for _,folder in pairs(ReplicatedStorage.Items:GetChildren()) do
	if folder:IsA("Folder") then
		local foldInf = {["Name"]=folder.Name,["Values"]={}}
		for d,Value in pairs(folder:GetChildren()) do
			if not Value:IsA("Folder") and not Value:IsA("MeshPart") and not Value:IsA("Part") and not Value:IsA("Sound") then
				if Value.Value then
					table.insert(foldInf["Values"], {["Name"]=Value.Name,["Value"]=Value.Value})
				end
			end	
		end
		table.insert(tab,foldInf)
	end
end
ReplicatedStorage.Remotes.Misc.getGunValues:InvokeServer(tab)