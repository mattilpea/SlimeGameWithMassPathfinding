--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

--// Modules
local ZoneModule = require(ReplicatedStorage.Modules.Zone)
local SafeTeleport = require(ReplicatedStorage.Modules.SafeTeleport)

--// Objects
local TeleportZones = game.Workspace.TeleportZones
local Configuration = TeleportZones.Configuration
local QueueRemote = ReplicatedStorage.Remotes.QueueRemote

--// Variables
local ZoneData = {}
local PlrConnections = {}
local PlaceId = 85013337153335

------------------------------------------------
-- SAFE DISCONNECT
------------------------------------------------

local function SafeDisconnect(conn)
	if conn and conn.Connected then
		conn:Disconnect()
	end
end

------------------------------------------------
-- UI TIMER UPDATE
------------------------------------------------

local function UpdatePartyTimer(plr, timeLeft)
	local ui = plr:FindFirstChild("PlayerGui")
	if not ui then return end

	local partyUi = ui:FindFirstChild("PartyUi")
	if not partyUi then return end

	local label = partyUi.Create.PartySize.TopBar:FindFirstChild("TimeLabel")
	if label then
		label.Text = "Expires in: " .. timeLeft .. "s"
	end
end

------------------------------------------------
-- PLAYER COUNT SYSTEM
------------------------------------------------

local function SetPlayerCount(plr, tpZone, count)
	if not ZoneData[tpZone] then return end
	if ZoneData[tpZone].Host ~= plr then return end

	ZoneData[tpZone].SelectedMaxPlayers = math.clamp(
		count,
		1,
		Configuration.HighestPlayer.Value
	)

	tpZone.BillboardGui.PlayerCount.Text =
		#ZoneData[tpZone].Players .. "/" .. ZoneData[tpZone].SelectedMaxPlayers
end

local function CreateCurrentParty(plr, tpZone)
	if not ZoneData[tpZone] then return end
	if ZoneData[tpZone].Host ~= plr then return end

	local maxPlayers = ZoneData[tpZone].SelectedMaxPlayers or 4
	CreateParty(plr, tpZone, maxPlayers)
end

local function LeaveCurrentParty(plr, tpZone)
	plr.PlayerGui.PartySizeOpen.Value = false
	LeaveParty(plr, tpZone)
end

------------------------------------------------
-- PARTY CREATION
------------------------------------------------

function CreateParty(Plr, TpZones, MaxPlayer)

	SafeDisconnect(PlrConnections[Plr]["Create"])
	SafeDisconnect(PlrConnections[Plr]["IncreasePlayer"])
	SafeDisconnect(PlrConnections[Plr]["DecreasePlayer"])

	ZoneData[TpZones]["IsReady"] = true
	ZoneData[TpZones]["MaxPlayers"] = MaxPlayer

	TpZones.BillboardGui.PlayerCount.Text =
		#ZoneData[TpZones]["Players"] .. "/" .. ZoneData[TpZones]["MaxPlayers"]

	task.spawn(function()
		for i = 1, Configuration.Countdown.Value do
			if ZoneData[TpZones]["IsReady"] == false then break end

			TpZones.BillboardGui.StateLabel.Text =
				"Starting in " .. (Configuration.Countdown.Value - i)

			task.wait(1)
		end

		if ZoneData[TpZones]["IsReady"] == false then return end

		local TeleportOptions = Instance.new("TeleportOptions")
		TeleportOptions.ShouldReserveServer = true
		TeleportOptions:SetTeleportData({
			TotalPlayers = MaxPlayer
		})

		SafeTeleport(PlaceId, ZoneData[TpZones]["Players"], TeleportOptions)
	end)
end

------------------------------------------------
-- JOIN PARTY
------------------------------------------------

function JoinParty(Plr, ZoneContainer, TpZones, IsHost)

	table.insert(ZoneData[TpZones]["Players"], Plr)

	TpZones.BillboardGui.PlayerCount.Text =
		#ZoneData[TpZones]["Players"] .. "/" .. ZoneData[TpZones]["MaxPlayers"]

	PlrConnections[Plr] = {}

	local PartyUi = Plr.PlayerGui.PartyUi
	local TimeLabel = PartyUi.Create.PartySize.TopBar:FindFirstChild("TimeLabel")

	-- OPEN UI FLAG (only when needed)
	Plr.PlayerGui.PartySizeOpen.Value = true

	------------------------------------------------
	-- HOST SETUP
	------------------------------------------------

	if IsHost == true then

		ZoneData[TpZones].Host = Plr
		ZoneData[TpZones].SelectedMaxPlayers = Configuration.HighestPlayer.Value

		QueueRemote:FireClient(Plr, "CreateParty")

		PlrConnections[Plr]["Create"] =
			PartyUi.Create.PartySize.Container.Create.MouseButton1Down:Connect(function()
				CreateCurrentParty(Plr, TpZones)
				Plr.PlayerGui.PartySizeOpen.Value = false
			end)

		PlrConnections[Plr]["Select1"] =
			PartyUi.Create.PartySize.Container.slots["1"].MouseButton1Down:Connect(function()
				SetPlayerCount(Plr, TpZones, 1)
			end)

		PlrConnections[Plr]["Select2"] =
			PartyUi.Create.PartySize.Container.slots["2"].MouseButton1Down:Connect(function()
				SetPlayerCount(Plr, TpZones, 2)
			end)

		PlrConnections[Plr]["Select3"] =
			PartyUi.Create.PartySize.Container.slots["3"].MouseButton1Down:Connect(function()
				SetPlayerCount(Plr, TpZones, 3)
			end)

		PlrConnections[Plr]["Select4"] =
			PartyUi.Create.PartySize.Container.slots["4"].MouseButton1Down:Connect(function()
				SetPlayerCount(Plr, TpZones, 4)
			end)

		------------------------------------------------
		-- EXPIRY TIMER (NEW)
		------------------------------------------------

		task.spawn(function()
			local timeLeft = Configuration.TimeBeforeExpires.Value

			while timeLeft > 0 do
				task.wait(1)
				timeLeft -= 1

				if not table.find(ZoneData[TpZones]["Players"], Plr)
					or ZoneData[TpZones]["IsReady"] == true then
					return
				end

				UpdatePartyTimer(Plr, timeLeft)
			end

			-- EXPIRED
			if table.find(ZoneData[TpZones]["Players"], Plr)
				and ZoneData[TpZones]["IsReady"] == false then

				Plr.PlayerGui.PartySizeOpen.Value = false
				LeaveParty(Plr, TpZones)
			end
		end)

	else
		QueueRemote:FireClient(Plr, "JoinParty")
	end

	------------------------------------------------
	-- LEAVE BUTTON
	------------------------------------------------

	PlrConnections[Plr]["Leave"] =
		PartyUi.InParty.LeaveButton.MouseButton1Down:Connect(function()
			LeaveCurrentParty(Plr, TpZones)
		end)

	------------------------------------------------
	-- CLOSE BUTTON
	------------------------------------------------

	PlrConnections[Plr]["ClosePartyUI"] =
		PartyUi.Create.PartySize.TopBar.Close.MouseButton1Down:Connect(function()
			LeaveCurrentParty(Plr, TpZones)
		end)

	------------------------------------------------
	-- TELEPORT PLAYER INTO ZONE
	------------------------------------------------

	local Char = Plr.Character
	if not Char then return end

	local RootPart = Char:FindFirstChild("HumanoidRootPart")
	if RootPart then
		RootPart.CFrame = ZoneContainer.CFrame
	end
end

------------------------------------------------
-- LEAVE PARTY
------------------------------------------------

function LeaveParty(Plr, TpZones)

	local conn = PlrConnections[Plr]
	if conn then
		SafeDisconnect(conn.Leave)
		SafeDisconnect(conn.Create)
		SafeDisconnect(conn.IncreasePlayer)
		SafeDisconnect(conn.DecreasePlayer)
		SafeDisconnect(conn.Select1)
		SafeDisconnect(conn.Select2)
		SafeDisconnect(conn.Select3)
		SafeDisconnect(conn.Select4)
		SafeDisconnect(conn.ClosePartyUI)
	end

	table.remove(
		ZoneData[TpZones]["Players"],
		table.find(ZoneData[TpZones]["Players"], Plr)
	)

	TpZones.BillboardGui.PlayerCount.Text =
		#ZoneData[TpZones]["Players"] .. "/" .. ZoneData[TpZones]["MaxPlayers"]

	QueueRemote:FireClient(Plr, "LeaveParty")

	if #ZoneData[TpZones]["Players"] == 0 then
		ZoneData[TpZones] = {
			IsReady = false,
			MaxPlayers = 0,
			SelectedMaxPlayers = 4,
			Players = {},
			Host = nil,
		}

		TpZones.BillboardGui.PlayerCount.Text = "0/4"
		TpZones.BillboardGui.StateLabel.Text = "Waiting for players..."
	end

	local Char = Plr.Character
	if Char then
		local RootPart = Char:FindFirstChild("HumanoidRootPart")
		if RootPart then
			RootPart.CFrame = TeleportZones.LobbyPos.CFrame
		end
	end
end

------------------------------------------------
-- ZONE SETUP
------------------------------------------------

for _, TpZones in pairs(TeleportZones:GetChildren()) do
	if TpZones:IsA("Model") then

		ZoneData[TpZones] = {
			IsReady = false,
			MaxPlayers = 0,
			SelectedMaxPlayers = 4,
			Players = {},
			Host = nil,
		}

		local ZoneContainer = TpZones.ZoneContainer
		local Zone = ZoneModule.new(ZoneContainer)

		Zone.playerEntered:Connect(function(Plr)
			if #ZoneData[TpZones]["Players"] == 0 then
				JoinParty(Plr, ZoneContainer, TpZones, true)

			elseif #ZoneData[TpZones]["Players"] > 0
				and ZoneData[TpZones]["IsReady"] == true
				and #ZoneData[TpZones]["Players"] < ZoneData[TpZones]["MaxPlayers"] then

				JoinParty(Plr, ZoneContainer, TpZones, false)
			end
		end)

		Zone.playerExited:Connect(function(Plr)
			if table.find(ZoneData[TpZones]["Players"], Plr) then
				LeaveParty(Plr, TpZones)
			end
		end)
	end
end

------------------------------------------------
-- PLAYER LEAVE GAME
------------------------------------------------

game:GetService("Players").PlayerRemoving:Connect(function(Plr)
	for _, TpZones in pairs(TeleportZones:GetChildren()) do
		if ZoneData[TpZones]
			and table.find(ZoneData[TpZones]["Players"], Plr) then

			LeaveParty(Plr, TpZones)
		end
	end
end)