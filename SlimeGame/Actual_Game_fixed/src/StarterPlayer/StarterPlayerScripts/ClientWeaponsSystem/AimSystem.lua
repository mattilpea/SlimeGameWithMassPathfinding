local AimSystem = {}

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = plr:GetMouse()

local function refreshMouseTargetFilter()
	local currentMap = workspace:FindFirstChild("CurrentMap")
	local mapBorders = currentMap and currentMap:FindFirstChild("MapBorders", true)
	mouse.TargetFilter = mapBorders
end

refreshMouseTargetFilter()

workspace.DescendantAdded:Connect(function(instance)
	if string.lower(instance.Name) == "mapborders" then
		refreshMouseTargetFilter()
	end
end)

workspace.DescendantRemoving:Connect(function(instance)
	if instance == mouse.TargetFilter then
		task.defer(refreshMouseTargetFilter)
	end
end)

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

local fireConn: RBXScriptConnection

function AimSystem:LockPlayer(bool : boolean, fireCallback)
	if bool then
		local currentDevice = DetectDevice()
		if not currentDevice then warn("could not detect current device") return nil end -- ROBLOX FIX YOUR CRAPPY API
		if currentDevice == pc then
			conn = RunService.RenderStepped:Connect(function()
				rotateCharacterPC()
			end)
			local aimGui = plr.PlayerGui:FindFirstChild("AimSytemGui")
			if aimGui then
				aimGui.Enabled = false
			end
			
		else
			local aimGui = plr.PlayerGui:WaitForChild("AimSytemGui", 5)
			if not aimGui then
				warn("AimSytemGui was not available for mobile aiming")
				return
			end
			aimGui.Enabled = true
			
			local fireButton = aimGui.MobileFrame.Fire
			local CameraLock = aimGui.MobileFrame["Camera Lock"]
			
			CameraLock.Activated:Connect(function()
				script.mobileLock.Value = not script.mobileLock.Value
				mobileShiftlock(script.mobileLock.Value)
			end)
			
			UserInputService.TouchTap:Connect(function()
				rotateCharacterPC()
			end)
			
			fireConn = fireButton.Activated:Connect(fireCallback)
			
		end
		
		
	else
		mobileShiftlock(false)
		if conn then
			conn:Disconnect()
		end
		
		if fireConn then
			fireConn:Disconnect()
		end
		local aimGui = plr.PlayerGui:FindFirstChild("AimSytemGui")
		if aimGui then
			aimGui.Enabled = false
		end
	end
end


return AimSystem

