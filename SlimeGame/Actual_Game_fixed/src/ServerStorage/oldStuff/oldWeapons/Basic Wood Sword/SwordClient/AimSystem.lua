local AimSystem = {}

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer
local camera = workspace.CurrentCamera

local pc = "pc"
local mobile = "mobile"

local function DetectDevice()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled then
		return mobile
	elseif not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
		return pc
	end
end

local function rotateCharacterPC()
	local mouse = plr:GetMouse()
	local char = plr.Character

	if not char then
		return
	end

	local root = char:FindFirstChild("HumanoidRootPart")

	if not root then
		return
	end

	local mousePos = mouse.Hit.Position

	local targetPos = Vector3.new(
		mousePos.X,
		root.Position.Y,
		mousePos.Z
	)

	root.CFrame = CFrame.lookAt(
		root.Position,
		targetPos
	)
end

local conn = nil

Players.PlayerAdded:Connect(function(sPlar)
	if sPlar == plr then
		sPlar.CharacterAdded:Connect(function()
			if conn ~= nil then
				conn:Disconnect()
				print("DONE")
			end
		end)
	end
end)

local function mobileShiftlock(enabled: boolean)
	if enabled then
		if conn then
			conn:Disconnect()
		end

		conn = RunService.RenderStepped:Connect(function()
			local char = plr.Character
			if not char then return end

			local root = char:FindFirstChild("HumanoidRootPart")
			local humanoid = char:FindFirstChildOfClass("Humanoid")

			if not root or not humanoid then return end

			humanoid.AutoRotate = false

			local look = camera.CFrame.LookVector

			-- flatten to XZ plane
			local flatLook = Vector3.new(look.X, 0, look.Z)

			if flatLook.Magnitude == 0 then return end

			root.CFrame = CFrame.lookAt(
				root.Position,
				root.Position + flatLook.Unit
			)
		end)
	else
		if conn then
			conn:Disconnect()
			conn = nil
		end

		local char = plr.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.AutoRotate = true
			end
		end
	end
end


function AimSystem.LockPlayer(bool : boolean)
	if bool then
		local currentDevice = DetectDevice()
		if not currentDevice then warn("could not detect current device") return nil end -- ROBLOX FIX YOUR CRAPPY API
		if currentDevice == pc then
			conn = RunService.RenderStepped:Connect(function()
				rotateCharacterPC()
			end)
			plr.PlayerGui.AimSytemGui.Enabled = false
			
		else
			plr.PlayerGui.AimSytemGui.Enabled = true
			
			local fireButton = plr.PlayerGui.AimSytemGui.MobileFrame.Fire
			local CameraLock = plr.PlayerGui.AimSytemGui.MobileFrame["Camera Lock"]
			
			CameraLock.Activated:Connect(function()
				script.mobileLock.Value = not script.mobileLock.Value
				mobileShiftlock(script.mobileLock.Value)
			end)
			
			UserInputService.TouchTap:Connect(function()
				rotateCharacterPC()
			end)
		end
		
		
	else
		mobileShiftlock(false)
		if conn then
			conn:Disconnect()
		end
		plr.PlayerGui.AimSytemGui.Enabled = false
	end
end


return AimSystem

