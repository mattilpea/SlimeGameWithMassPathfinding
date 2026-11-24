local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiAnimations = require(ReplicatedStorage.Modules.UiAnimations)

local HUD = script.Parent.HUDFrame

local UIManager = {
	Frames = {}
}

------------------------------------------------
-- SPECIAL FRAME (BOOL CONTROLLED)
------------------------------------------------

local PartySizeFrame = script.Parent.Parent.PartyUi.Create.PartySize
local PartySizeOpen = Players.LocalPlayer.PlayerGui.PartySizeOpen

------------------------------------------------
-- CORE FUNCTIONS
------------------------------------------------

function UIManager.CloseAll(except)
	for _, frame in pairs(UIManager.Frames) do
		if frame ~= except and frame.Visible then
			UiAnimations.Close(frame, false, true, true, false)
		end
	end
end

function UIManager.Open(frame)
	if not frame.Visible then
		UIManager.CloseAll(frame)
		UiAnimations.Open(frame, false, true, true, false)
	end
end

function UIManager.Close(frame)
	if frame.Visible then
		UiAnimations.Close(frame, false, true, true, false)
	end
end

function UIManager.Toggle(frame)
	if frame.Visible then
		UIManager.Close(frame)
	else
		UIManager.Open(frame)
	end
end

------------------------------------------------
-- NORMAL REGISTER SYSTEM
------------------------------------------------

function UIManager.Register(frame, openButton, closeButton)
	table.insert(UIManager.Frames, frame)

	local function toggle()
		UIManager.Toggle(frame)
	end

	if openButton then
		openButton.Activated:Connect(toggle)
	end

	if closeButton then
		closeButton.Activated:Connect(toggle)
	end
end

------------------------------------------------
-- BOOL BIND SYSTEM (FOR SINGLE FRAME)
------------------------------------------------

function UIManager.BindBool(frame, boolValue : BoolValue)
	local function update()
		if boolValue.Value then
			UIManager.Open(frame)
		else
			UIManager.Close(frame)
		end
	end

	update()
	boolValue:GetPropertyChangedSignal('Value'):Connect(update)
end

------------------------------------------------
-- REGISTER NORMAL UI
------------------------------------------------

UIManager.Register(
	script.Parent.Upgrades,
	HUD.TPButtons.UpgradesButton,
	script.Parent.Upgrades.TopBar.Close
)

UIManager.Register(
	script.Parent.Shop,
	HUD.MenuButtons.ShopButton,
	script.Parent.Shop.TopBar.Close
)

UIManager.Register(
	script.Parent.Loadout,
	HUD.TPButtons.LoadoutButton,
	script.Parent.Loadout.TopBar.Close
)

------------------------------------------------
-- BOOL-BASED FRAME (ONLY THIS ONE)
------------------------------------------------

UIManager.BindBool(PartySizeFrame, PartySizeOpen)

--PartySizeFrame.TopBar.Close.Activated:Connect(function()
--	PartySizeOpen.Value = false
--end)