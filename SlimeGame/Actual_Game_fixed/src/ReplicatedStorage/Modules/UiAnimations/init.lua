-- made by @mattilpea 

--// Services
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

--// Modules
local TagList = require(script.TagList)

--// ClassNames
local UIScale = "UIScale"

--// Config 
local CONFIG = {
	BounceUp = 0.02,
	BounceDown = -0.02,
	DefaultWaitTime = 0.1,
	HoverScale = 1.1,
	ClickScale = 0.8,
	DefaultHoverColor = Color3.fromRGB(30, 255, 221),
	DefaultFrameRotation = 15,
	FovOut = 80
}

local defaultTweenInfo = TweenInfo.new(
	CONFIG.DefaultWaitTime,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.In
)

--// State
local activeTweens = {}
local connectedFlags = {} -- prevent duplicate connections

--// Module
local UiAnimations = {}
UiAnimations.CONFIG = CONFIG
--// Utilities

function UiAnimations.existenceChecker(object, className)
	if not object then

		return nil
	end

	local found = object:FindFirstChildOfClass(className)
	if found then
		return found
	end

	local inst = Instance.new(className)
	inst.Parent = object
	return inst

end

local function existenceChecker(object, className)
	if not object then

		return nil
	end

	local found = object:FindFirstChildOfClass(className)
	if found then
		return found
	end

	local inst = Instance.new(className)
	inst.Parent = object
	return inst

end

local function safeTween(target, tweenInfo, goal)
	if activeTweens[target] then
		activeTweens[target]:Cancel()
	end
	local tween = TweenService:Create(target, tweenInfo, goal)
	activeTweens[target] = tween
	tween:Play()
	return tween
end

function UiAnimations.tweenScale(uiScale, goalScale)
	safeTween(uiScale, defaultTweenInfo, { Scale = goalScale })
end

local function tweenScale(uiScale, goalScale)
	safeTween(uiScale, defaultTweenInfo, { Scale = goalScale })
end

local function rotateButton(button, goalRotation)
	safeTween(button, defaultTweenInfo, { Rotation = goalRotation })
end

local function squeezeButtonClick(button)
	local scale = existenceChecker(button, UIScale)
	if not scale then return end
	tweenScale(scale, CONFIG.ClickScale)
	task.wait(CONFIG.DefaultWaitTime)
	tweenScale(scale, 1)
end

local function offsetTween(button, offset, originalPos)
	local newPos = UDim2.new(
		originalPos.X.Scale,
		originalPos.X.Offset,
		originalPos.Y.Scale + offset,
		originalPos.Y.Offset
	)
	return TweenService:Create(button, defaultTweenInfo, { Position = newPos })
end

local function colorChange(button : GuiButton , goalColor)
	safeTween(button, defaultTweenInfo, { BackgroundColor3 = goalColor })
end

local function playSequence(sequence)
	for _, tween in ipairs(sequence) do
		tween:Play()
		tween.Completed:Wait()
	end
end

--// Animations
function UiAnimations.HoverAndClick(button : GuiButton )
	if connectedFlags[button] then return end
	connectedFlags[button] = true

	local scale = existenceChecker(button, UIScale)
	if not scale then return end

	button.MouseEnter:Connect(function()
		tweenScale(scale, CONFIG.HoverScale)
	end)

	button.MouseLeave:Connect(function()
		tweenScale(scale, 1)
	end)

	button.MouseButton1Click:Connect(function()
		squeezeButtonClick(button)
	end)
end

function UiAnimations.RotateHover(button :GuiButton )
	if connectedFlags[button] then return end
	connectedFlags[button] = true

	button.MouseEnter:Connect(function()
		rotateButton(button, 7.5)
	end)

	button.MouseLeave:Connect(function()
		rotateButton(button, 0)
	end)

	button.MouseButton1Click:Connect(function()
		squeezeButtonClick(button)
	end)
end

function UiAnimations.ClickBounce(button :GuiButton )
	if connectedFlags[button] then return end
	connectedFlags[button] = true

	local scale = existenceChecker(button, UIScale)
	if not scale then return end
	local originalPos = button.Position

	button.MouseEnter:Connect(function()
		tweenScale(scale, CONFIG.HoverScale)
	end)

	button.MouseLeave:Connect(function()
		tweenScale(scale, 1)
	end)

	button.MouseButton1Click:Connect(function()
		local sequence = {
			offsetTween(button, CONFIG.BounceUp, originalPos),
			offsetTween(button, CONFIG.BounceDown, originalPos),
			offsetTween(button, 0, originalPos)
		}
		task.spawn(function()
			for _, tween in ipairs(sequence) do
				tween:Play()
				tween.Completed:Wait()
			end
		end)
	end)
end

function UiAnimations.ColorChangeAnimation(button : GuiButton, hoverColor)
	if connectedFlags[button] then return end
	connectedFlags[button] = true

	UiAnimations.HoverAndClick(button)

	local originalColor = button.BackgroundColor3
	local targetColor = hoverColor or CONFIG.DefaultHoverColor

	button.MouseEnter:Connect(function()
		colorChange(button, targetColor)
	end)

	button.MouseLeave:Connect(function()
		colorChange(button, originalColor)
	end)
end

function UiAnimations.Open(frame: Frame, bounce: boolean, rotate : boolean, fovChange : boolean, blur : boolean)
	local scale = existenceChecker(frame, UIScale) :: UIScale
	if not scale then return end

	if rotate then
		frame.Rotation = CONFIG.DefaultFrameRotation
	end

	frame.BackgroundTransparency = 1
	scale.Scale = 0.5
	frame.Visible = true

	local open1 = safeTween(scale, TweenInfo.new(0.2), { Scale = bounce and 1.5 or 1.3 })
	local fadeIn = safeTween(frame, TweenInfo.new(0.2), { BackgroundTransparency = 1 , Rotation = 0})
	if fovChange then
		local camFovChange = safeTween(workspace.CurrentCamera, TweenInfo.new(0.2), {FieldOfView = 80 } )
	end
	if blur then
		local blur = existenceChecker(Lighting, "BlurEffect") :: BlurEffect
		blur.Enabled = false
		blur.Size = 0
		blur.Enabled = true
		local blurTween = safeTween(blur, TweenInfo.new(0.2), {Size = 20})
	end
	open1.Completed:Wait()

	if bounce then
		playSequence({
			safeTween(scale, TweenInfo.new(0.3), { Scale = 0.8 }),
			safeTween(scale, TweenInfo.new(0.15), { Scale = 1 })
		})
	else
		safeTween(scale, TweenInfo.new(0.2), { Scale = 1 }).Completed:Wait()
	end



end

function UiAnimations.Close(frame: Frame, bounce: boolean, rotate : boolean, fovChange : boolean, blur : boolean)
	local scale = existenceChecker(frame, UIScale) :: UIScale
	if not scale then return end

	if rotate then
		frame.Rotation = 0
	end

	if bounce then
		-- Mini pop-up before shrinking
		local popUp = safeTween(scale, TweenInfo.new(0.2), { Scale = 1.3 })
		popUp.Completed:Wait()

		local shrink = safeTween(scale, TweenInfo.new(0.1), { Scale = 0.2 })
		safeTween(frame, TweenInfo.new(0.1), { BackgroundTransparency = 1 , Rotation = 15})
		shrink.Completed:Wait()
	else
		local time = 0.2
		local shrink = safeTween(scale, TweenInfo.new(time), { Scale = 0.2 })
		safeTween(frame, TweenInfo.new(time), { BackgroundTransparency = 1, Rotation = 15 })
		shrink.Completed:Wait()
	end

	local camFovChange = safeTween(workspace.CurrentCamera, TweenInfo.new(0.2), {FieldOfView = 70 } )
	local blur = existenceChecker(Lighting, "BlurEffect") :: BlurEffect
	blur.Enabled = true
	local blurTween = safeTween(blur, TweenInfo.new(0.2), {Size = 0})
	blur.Enabled = false
	frame.Visible = false
end

UiAnimations.TagList = TagList

return UiAnimations
