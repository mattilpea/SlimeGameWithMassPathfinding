-- Handles all UI, loads appropriate animations, and ensures UI is in flow

--// Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiAnimations = require(ReplicatedStorage.Modules.UiAnimations)
local TagList = UiAnimations.TagList -- do notice, this is a loaded from uiAnimations and not rooted directly.

local tagToAnimation = {
	[TagList.ButtonHoverAndClick] = UiAnimations.HoverAndClick,
	[TagList.ButtonRotateHover] = UiAnimations.RotateHover,
	[TagList.ButtonClickBounce] = UiAnimations.ClickBounce,
	[TagList.ButtonColorChange] = UiAnimations.ColorChangeAnimation
}

for tag, animationFunc in pairs(tagToAnimation) do
	for _, button in pairs(CollectionService:GetTagged(tag)) do
		animationFunc(button)
	end
end



--Example usage for frame opening and closing
--task.wait(5)
--UiAnimations.Open(script.Parent.UiPackModularized.Frames.PopUp_FRM, true, true, true, true)
--task.wait(3)
--UiAnimations.Close(script.Parent.UiPackModularized.Frames.PopUp_FRM, true, true, true, true)