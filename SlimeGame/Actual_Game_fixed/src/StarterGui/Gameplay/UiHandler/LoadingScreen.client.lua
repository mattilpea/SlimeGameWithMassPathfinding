local Players = game:GetService("Players")

if Players.LocalPlayer:GetAttribute('Loaded') then return end

local TweenService = game:GetService("TweenService")

local UiSettings = require(script.Parent.UiSettings)

local loadingScreenFrame = script.Parent.Parent.LoadingScreen
local loadingBar = loadingScreenFrame.LoadingBar
local fillbar = loadingBar.FillBar
local tipTxtLbl = loadingScreenFrame.Tip
local loadingTxtLbl = loadingScreenFrame.LoadingTxt

local totalLoadTime = UiSettings.TotalLoadingScreenTime
local readTimeForEachTip = UiSettings.TotalTimeToReachEachLoadingScreenTip

loadingScreenFrame.Visible = true
loadingScreenFrame.BackgroundTransparency = 0

local tips = UiSettings.LoadingScreenTipList

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local function loadRandomTip()
	local rn = math.random(1, #tips)
	local random_tip = tips[rn]

	tipTxtLbl.Text = random_tip
end
loadRandomTip()
loadingTxtLbl.Text = "Loading"

local beginTipTime = 0
local totalTimeElapsed = 0

TweenService:Create(fillbar, TweenInfo.new(totalLoadTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Size = UDim2.new(1,0,1,0)}):Play()

for i = 0, totalLoadTime, 1 do
	task.wait(1)
	beginTipTime += 1
	totalTimeElapsed += 1
	
	loadRandomTip()
	
	loadingTxtLbl.Text = loadingTxtLbl.Text.."."
	if loadingTxtLbl.Text == "Loading..." then
		loadingTxtLbl.Text = "Loading"
	end
	
	if beginTipTime >= readTimeForEachTip then
		beginTipTime = 0
		loadRandomTip()
	end
	
	if totalTimeElapsed >= totalLoadTime then
		TweenService:Create(loadingScreenFrame, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
	end
end


loadingScreenFrame.Visible = false
loadingScreenFrame.BackgroundTransparency = 1
Players.LocalPlayer:SetAttribute('Loaded', true)