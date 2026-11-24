local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiAnimations = require(ReplicatedStorage.Modules.UiAnimations)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local classesPlatform = workspace.ClassesPlatform
local classesCamPart = classesPlatform:WaitForChild('ClassesCamPart')
local rigHrp = classesPlatform.Rig.HumanoidRootPart

local button = script.Parent

local screenGui = button:FindFirstAncestorOfClass("ScreenGui")
local viewingClasses = screenGui.viewingClasses

local hudFrame = screenGui.HUDFrame
local classesFrame = screenGui.ClassesFrame

local currentTween
local previewCharacter = nil

local tweenInfo = TweenInfo.new(
	0.5,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.InOut
)

local function destroyPreviewCharacter()
	if previewCharacter then
		previewCharacter:Destroy()
		previewCharacter = nil
	end
end

local function createPreviewCharacter()
	destroyPreviewCharacter()

	local character = player.Character or player.CharacterAdded:Wait()
	character.Archivable = true

	local clone = character:Clone()
	clone.Name = player.Name .. "_ClassPreview"

	local humanoid = clone:FindFirstChildOfClass("Humanoid")
	local cloneHrp = clone:FindFirstChild("HumanoidRootPart")

	if not humanoid or not cloneHrp then
		clone:Destroy()
		return
	end

	for _, object in ipairs(clone:GetDescendants()) do
		if object:IsA("Script") or object:IsA("LocalScript") then
			object:Destroy()
		elseif object:IsA("BasePart") then
			object.Anchored = false
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false
		end
	end

	clone.Parent = classesPlatform

	clone:PivotTo(rigHrp.CFrame)
	cloneHrp.Anchored = true

	previewCharacter = clone
end

local function tweenToClasses()
	if currentTween then
		currentTween:Cancel()
	end

	camera.CameraType = Enum.CameraType.Scriptable

	currentTween = TweenService:Create(camera, tweenInfo, {
		CFrame = classesCamPart.CFrame
	})

	currentTween:Play()
end

local function tweenBackToPlayer()
	if currentTween then
		currentTween:Cancel()
	end

	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")

	local playerCamCFrame = CFrame.new(
		rootPart.Position + Vector3.new(0, 3, 8),
		rootPart.Position
	)

	currentTween = TweenService:Create(camera, tweenInfo, {
		CFrame = playerCamCFrame
	})

	currentTween:Play()

	currentTween.Completed:Once(function()
		if not viewingClasses.Value then
			camera.CameraSubject = humanoid
			camera.CameraType = Enum.CameraType.Custom
		end
	end)
end

local function updateCamera()
	if viewingClasses.Value == true then
		createPreviewCharacter()
		tweenToClasses()

		UiAnimations.Close(hudFrame, false, false, false, false)
		UiAnimations.Open(classesFrame, false, false, false, false)
	else
		destroyPreviewCharacter()
		tweenBackToPlayer()

		UiAnimations.Close(classesFrame, false, false, false, false)
		UiAnimations.Open(hudFrame, false, false, false, false)
	end
end

button.Activated:Connect(function()
	viewingClasses.Value = not viewingClasses.Value
end)

viewingClasses:GetPropertyChangedSignal("Value"):Connect(updateCamera)

classesFrame.Visible = false
hudFrame.Visible = true

updateCamera()