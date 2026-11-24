local Players = game:GetService("Players")

local plr = Players.LocalPlayer

local gemValue = plr:WaitForChild('leaderstats'):WaitForChild('Gems') :: IntValue

local function setval()
	script.Parent.BalanceValue.Text = tostring(gemValue.Value)
	script.Parent.BalanceValue.BalanceValue.Text = tostring(gemValue.Value)
end

setval()

gemValue.Changed:Connect(function()
	setval()
end)

