local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local cInfo = require(ReplicatedStorage.Modules:WaitForChild("ClassesInfo"))

local RightClassPropertiesFrame = script.Parent.Parent.Parent.RightClassPropertiesFrame
local ownedClassesFolder = player:WaitForChild("OwnedClasses")
local equippedClassValue = player:WaitForChild("EquippedClass")
local equipButton = RightClassPropertiesFrame.Parent:WaitForChild("EquipButton")

local BuyClassRemote = ReplicatedStorage.Remotes.BuyClass

local templates = {
	script.Parent.Template1,
	script.Parent.Template2,
	script.Parent.Template3,
	-- script.Parent.Template4 -- unused / placeholder
}

local Attacks = {
	RightClassPropertiesFrame.ContentSF.Attack1,
	RightClassPropertiesFrame.ContentSF.Attack2,
	RightClassPropertiesFrame.ContentSF.Attack3,
	RightClassPropertiesFrame.ContentSF.Attack4,
}

local selectedClassInfo = nil
local debounce = false

local function setNameOfTemp(temp: ImageButton, name: string)
	temp.NameHolder:FindFirstChild("Name").Text = name
	temp.NameHolder:FindFirstChild("Name"):FindFirstChild("Name").Text = name
end

local function playerOwnsClass(className: string)
	return ownedClassesFolder:FindFirstChild(className) ~= nil
end

local function getClassInfoFromName(className: string)
	for index, classInfo in ipairs(cInfo) do
		if classInfo.Name == className then
			return index, classInfo
		end
	end

	return nil, nil
end

local function setEquipButtonText(text: string)
	equipButton.Txt.Text = text
	equipButton.Txt.Txt.Text = text
end

local function updateEquipButton(classInfo)
	selectedClassInfo = classInfo

	if playerOwnsClass(classInfo.Name) then
		if equippedClassValue.Value == classInfo.Name then
			setEquipButtonText("Equipped")
		else
			setEquipButtonText("Equip")
		end
	else
		setEquipButtonText("Buy")
	end
end

local function setTemplateOwnership(temp: ImageButton, classInfo)
	local ownsClass = playerOwnsClass(classInfo.Name)
	local isEquipped = equippedClassValue.Value == classInfo.Name

	if isEquipped then
		temp.Buy.Visible = false
		temp.Equip.Visible = false
		temp.Equipped.Visible = true
	elseif ownsClass then
		temp.Buy.Visible = false
		temp.Equip.Visible = true
		temp.Equipped.Visible = false
	else
		temp.Buy.Visible = true
		temp.Equip.Visible = false
		temp.Equipped.Visible = false

		temp.Buy.Price.Text = tostring(classInfo.Price)
	end
end

local function refreshTemplates()
	for index, classInfo in ipairs(cInfo) do
		local temp = templates[index]

		if temp then
			setTemplateOwnership(temp, classInfo)
		end
	end
end

local function refreshCurrentButton()
	if selectedClassInfo then
		updateEquipButton(selectedClassInfo)
	end
end

local function setRightClassPropertiesFrame(className: string)
	local classIndex, classInfo = getClassInfoFromName(className)

	if not classInfo then
		warn("Class not found:", className)
		return
	end

	local function setClassTitle(name)
		RightClassPropertiesFrame.Background.Title.Text = name
		RightClassPropertiesFrame.Background.Title.Title.Text = name
	end

	setClassTitle(classInfo.Name)
	RightClassPropertiesFrame.Background.HeaderIcn.Image = classInfo.IconId

	updateEquipButton(classInfo)

	for index, attackFrame in ipairs(Attacks) do
		local data = classInfo.Attacks[index]

		if data then
			attackFrame.Visible = true

			local infoBar = attackFrame:WaitForChild("InfoBar")

			local nameLabel = infoBar:WaitForChild("Name")
			local nameShadow = nameLabel:WaitForChild("Name")

			local rarityLabel = infoBar:WaitForChild("Rarity")
			local rarityShadow = rarityLabel:WaitForChild("Rarity")

			local icon = attackFrame:WaitForChild("Icon")
			local description = attackFrame:WaitForChild("Description")

			nameLabel.Text = data.AttackName
			nameShadow.Text = data.AttackName

			rarityLabel.Text = data.AttackRarity or classInfo.Rarity
			rarityShadow.Text = data.AttackRarity or classInfo.Rarity

			icon.Image = data.AttackIconId or classInfo.IconId
			description.Text = data.AttackDesc
		else
			attackFrame.Visible = false
		end
	end
end

local function setTemplateInfo(temp: ImageButton, classInfo)
	setNameOfTemp(temp, classInfo.Name)

	temp.Rarity.Text = classInfo.Rarity
	temp.Type.Text = classInfo.Type
	temp.Icon.Image = classInfo.IconId

	setTemplateOwnership(temp, classInfo)

	temp.Activated:Connect(function()
		setRightClassPropertiesFrame(classInfo.Name)
	end)
end

for index, classInfo in ipairs(cInfo) do
	local temp = templates[index]

	if temp then
		setTemplateInfo(temp, classInfo)
	end
end

equipButton.Activated:Connect(function()
	if debounce then
		return
	end

	if not selectedClassInfo then
		return
	end

	debounce = true

	local className = selectedClassInfo.Name

	if playerOwnsClass(className) then
		if equippedClassValue.Value == className then
			print("Already equipped:", className)
			debounce = false
			return
		end

		-- Client-side first
		equippedClassValue.Value = className
		refreshTemplates()
		updateEquipButton(selectedClassInfo)

		-- Tell server to save/equip it
		BuyClassRemote:FireServer("Equip", className)

		print("Attempting to equip:", className)
	else
		setEquipButtonText("Buying...")

		-- Tell server to try buying it
		BuyClassRemote:FireServer("Buy", className)

		print("Attempting to buy:", className, "for", selectedClassInfo.Price)
	end

	task.delay(0.5, function()
		debounce = false
		refreshTemplates()
		refreshCurrentButton()
	end)
end)

ownedClassesFolder.ChildAdded:Connect(function()
	refreshTemplates()
	refreshCurrentButton()
end)

ownedClassesFolder.ChildRemoved:Connect(function()
	refreshTemplates()
	refreshCurrentButton()
end)

equippedClassValue:GetPropertyChangedSignal("Value"):Connect(function()
	refreshTemplates()
	refreshCurrentButton()
end)

refreshTemplates()
setRightClassPropertiesFrame(cInfo[1].Name)