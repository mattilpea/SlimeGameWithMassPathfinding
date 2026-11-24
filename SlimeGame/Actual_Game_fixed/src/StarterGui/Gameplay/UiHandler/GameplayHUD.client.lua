local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer

local UiAnimations = require(ReplicatedStorage.Modules.UiAnimations)

local RemoteEvents = ReplicatedStorage.RemoteEvents
local NotifyUserRemoteEvent = RemoteEvents.NotifyUser

local GameplayHUDFrame = script.Parent.Parent.GameplayHUD
local NotificationFrame = GameplayHUDFrame.Notification
local SkipFrame = GameplayHUDFrame.SkipSection
local CurrenciesFrame = GameplayHUDFrame.Currencies
local RHSGearsFrame = GameplayHUDFrame.RHSGears
local LHSUpgradesFrame = GameplayHUDFrame.LHSUpgrades

local contentParentTxtLbl = NotificationFrame.Content
local contentChildTxtLbl = contentParentTxtLbl.Content

local GemsFrame = CurrenciesFrame.Gems
local PotionFrame = CurrenciesFrame.Potion

local currencyName = "Credits"

local function changeText(txt, speed)
	speed = speed or 0.03

	contentParentTxtLbl.Text = ""
	contentChildTxtLbl.Text = ""

	for i = 1, #txt do
		local currentText = string.sub(txt, 1, i)

		contentParentTxtLbl.Text = currentText
		contentChildTxtLbl.Text = currentText

		task.wait(speed)
	end
end

local SecondLeftBeforeSkip = ReplicatedStorage.Values.SecondLeftBeforeSkip

local function showCounter()
	SkipFrame.SkippingCounter.Visible = true
	SkipFrame.SkippingCounter.Counter.Text = "Skipping in "..tostring(SecondLeftBeforeSkip.Value)
	SkipFrame.SkippingCounter.Counter.Counter.Text = "Skipping in "..tostring(SecondLeftBeforeSkip.Value)
end

SecondLeftBeforeSkip:GetPropertyChangedSignal('Value'):Connect(function()
	if SecondLeftBeforeSkip.Value > 0 then
		showCounter()
		
	else
		SkipFrame.SkippingCounter.Visible = false
	end
end)


local function CheckAutoSkip()
	if Players.LocalPlayer:GetAttribute('AutoSkip') then
		SkipFrame.Autoskip.ImageColor3 = Color3.fromRGB(255, 255, 255)
		SkipFrame.Autoskip.Txt.Text = "Auto-Skip: ON"
		SkipFrame.Autoskip.Txt.Txt.Text = "Auto-Skip: ON"
	else
		SkipFrame.SkippingCounter.Visible = false
		SkipFrame.Autoskip.ImageColor3 = Color3.fromRGB(255, 0, 0)
		SkipFrame.Autoskip.Txt.Text = "Auto-Skip: OFF"
		SkipFrame.Autoskip.Txt.Txt.Text = "Auto-Skip: OFF"
	end
end
CheckAutoSkip()

NotifyUserRemoteEvent.OnClientEvent:Connect(function(msg : string, totalTimeToShow : number)
	NotificationFrame.Visible = true
	changeText(msg)
	task.wait(totalTimeToShow or 2)
	NotificationFrame.Visible = false
end)

SkipFrame.Autoskip.Activated:Connect(function()
	ReplicatedStorage.RemoteEvents.AutoSkip:FireServer()
end)

plr:GetAttributeChangedSignal("AutoSkip"):Connect(CheckAutoSkip)

local leaderstatsFolder = plr:WaitForChild('leaderstats')
local GemsVal = leaderstatsFolder:WaitForChild(currencyName) :: IntValue

local plrData = plr:WaitForChild('plrData')
local equippedClassVal = plrData:WaitForChild('EquippedClass') :: StringValue

local ClassesInfo = require(ReplicatedStorage.Modules:WaitForChild('ClassesInfo'))

local function changeGemText()
	GemsFrame.Amount.Text = tostring(GemsVal.Value)
	GemsFrame.Amount.Amount.Text = tostring(GemsVal.Value)
end
changeGemText()

local function getClassInfoFromName(className: string)
	for _, classInfo in ipairs(ClassesInfo) do
		if classInfo.Name == className then
			return classInfo
		end
	end

	return nil
end

local SFMain = RHSGearsFrame.Holder.SFMain

local cInfo  = getClassInfoFromName(equippedClassVal.Value)

GemsVal:GetPropertyChangedSignal('Value'):Connect(changeGemText)

local function templateFiller(attackInfo, Template : GuiButton)
	local nameTxtLbl = Template:FindFirstChild('Name') :: TextLabel
	local childNameTxtLbl = nameTxtLbl:FindFirstChild('Name') :: TextLabel

	local priceTxtLbl = Template:FindFirstChild('Price') :: TextLabel
	local childPriceTxtLbl = priceTxtLbl:FindFirstChild('Price') :: TextLabel

	local iconImgLbl = Template:FindFirstChild('Icon') :: ImageLabel

	local AttackName = attackInfo['AttackName']
	local AttackDesc = attackInfo['AttackDesc']
	local AttackIconId = attackInfo['AttackIconId']
	local AttackPrice = attackInfo['AttackPrice']

	nameTxtLbl.Text = AttackName
	childNameTxtLbl.Text = AttackName

	priceTxtLbl.Text = tostring(AttackPrice)
	childPriceTxtLbl.Text = tostring(AttackPrice)

	iconImgLbl.Image = AttackIconId
end

local attackInfo = cInfo['Attacks']
templateFiller(attackInfo[1], SFMain.Template1)
templateFiller(attackInfo[2], SFMain.Template2)
templateFiller(attackInfo[3], SFMain.Template3)

local function attack1()
	
end

local function attack2()

end

local function attack3()

end



UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.E then
		
		local scale = UiAnimations.existenceChecker(SFMain.Template1, "UIScale")
		UiAnimations.tweenScale(scale, UiAnimations.CONFIG.HoverScale)
		
	elseif input.KeyCode == Enum.KeyCode.R then
		
		local scale = UiAnimations.existenceChecker(SFMain.Template2, "UIScale")
		UiAnimations.tweenScale(scale, UiAnimations.CONFIG.HoverScale)
		
	elseif input.KeyCode == Enum.KeyCode.Q then
		
		local scale = UiAnimations.existenceChecker(SFMain.Template3, "UIScale")
		UiAnimations.tweenScale(scale, UiAnimations.CONFIG.HoverScale)
		

	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.E then

		local scale = UiAnimations.existenceChecker(SFMain.Template1, "UIScale")
		UiAnimations.tweenScale(scale, 1)

	elseif input.KeyCode == Enum.KeyCode.R then

		local scale = UiAnimations.existenceChecker(SFMain.Template2, "UIScale")
		UiAnimations.tweenScale(scale, 1)

	elseif input.KeyCode == Enum.KeyCode.Q then

		local scale = UiAnimations.existenceChecker(SFMain.Template3, "UIScale")
		UiAnimations.tweenScale(scale, 1)

	end
end)

