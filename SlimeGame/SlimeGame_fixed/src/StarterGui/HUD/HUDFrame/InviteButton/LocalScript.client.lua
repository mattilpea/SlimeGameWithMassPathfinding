local SocialService = game:GetService("SocialService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local button = script.Parent

button.Activated:Connect(function()
	local canInvite = SocialService:CanSendGameInviteAsync(player)
	if canInvite then
		SocialService:PromptGameInvite(player)
	elseif not canInvite then
		--player.PlayerGui.ScreenGui.CantInvite:TweenPosition(UDim2.new(0.5,0,0.3,0))
	end
end)