local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameOverviewFrame = script.Parent.GameOverview
local GameplayHUDFrame = script.Parent.GameplayHUD

ReplicatedStorage.RemoteEvents.DeadSpectate.OnClientEvent:Connect(function()
	GameOverviewFrame.Visible = true
	GameplayHUDFrame.Visible = false
	
	
	
end)