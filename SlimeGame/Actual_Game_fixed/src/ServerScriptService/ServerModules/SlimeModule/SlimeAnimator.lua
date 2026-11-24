--!strict

local SlimeAnimator = {}
SlimeAnimator.__index = SlimeAnimator

local ANIMATION_IDS = {
	Idle = "rbxassetid://118602300916353",
	Attack = "rbxassetid://106221966739642",
	Death = "rbxassetid://107466077217491",
	Hit = "rbxassetid://79855988826367",
}

function SlimeAnimator.new(model: Model)
	local self = setmetatable({}, SlimeAnimator)

	local animationController = model:FindFirstChildWhichIsA("AnimationController", true)
	assert(animationController, "Slime model has no AnimationController")

	local animator = animationController:FindFirstChildWhichIsA("Animator")
	assert(animator, "AnimationController has no Animator")

	self.Tracks = {}
	self.CurrentTrack = nil
	self.CurrentName = nil

	for name, id in pairs(ANIMATION_IDS) do
		local animation = Instance.new("Animation")
		animation.AnimationId = id

		local track = animator:LoadAnimation(animation)
		track.Looped = name == "Idle"
		track.Looped = name == "Attack"
		
		self.Tracks[name] = track
	end

	return self
end

function SlimeAnimator:Play(name: string)
	if self.CurrentName == name then
		return
	end

	if self.CurrentTrack then
		self.CurrentTrack:Stop(0.15)
	end

	local track = self.Tracks[name]
	if not track then return end

	self.CurrentName = name
	self.CurrentTrack = track
	track:Play(0.15)
end

function SlimeAnimator:Stop()
	if self.CurrentTrack then
		self.CurrentTrack:Stop(0.15)
	end

	self.CurrentTrack = nil
	self.CurrentName = nil
end

return SlimeAnimator