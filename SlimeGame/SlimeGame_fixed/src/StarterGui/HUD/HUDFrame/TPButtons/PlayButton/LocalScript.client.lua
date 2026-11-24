local Players = game:GetService("Players")

script.Parent.Activated:Connect(function()
	Players.LocalPlayer.Character:MoveTo(workspace.TpForPlay.Position)
end)