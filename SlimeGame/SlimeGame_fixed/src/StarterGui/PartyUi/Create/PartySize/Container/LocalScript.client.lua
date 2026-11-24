local slots = script.Parent.slots

local OnImageId = "rbxassetid://86939925635105"
local OffImageId = "rbxassetid://101366179428654"

local buttons = {
	slots["1"],
	slots["2"],
	slots["3"],
	slots["4"],
}

local selected = nil

local function setActive(index)
	selected = index

	for i, button in ipairs(buttons) do
		if i == index then
			button.Image = OffImageId
		else
			button.Image = OnImageId
		end
	end
end

-- connections
for i, button in ipairs(buttons) do
	button.Activated:Connect(function()
		setActive(i)
	end)
end

-- optional default state
setActive(1)