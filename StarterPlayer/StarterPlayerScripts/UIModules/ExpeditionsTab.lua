-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: ExpeditionsTab
local ExpeditionsTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))

local player = Players.LocalPlayer

local DECALS = {
	Campaign = "rbxassetid://80153476985849",
	AFK = "rbxassetid://114506098039778",
	Raid = "rbxassetid://119392967268687",
	PvP = "rbxassetid://100826303284945", 
	Nightmare = "rbxassetid://90132878979603",
	WorldBoss = "rbxassetid://129655150803684" 
}

-- Party State
local CurrentParty = {}
local IsInParty = false
local IsPartyLeader = false
local PendingInvites = {}
local isListening = false

local function CreateSharpButton(parent, text, size, font, textSize)
	local btn = Instance.new("TextButton", parent)
	btn.Size = size
	btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Font = font
	btn.TextColor3 = Color3.fromRGB(245, 245, 245)
	btn.TextSize = textSize
	btn.Text = text

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(70, 70, 80)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	btn.MouseEnter:Connect(function() stroke.Color = Color3.fromRGB(225, 185, 60); btn.TextColor3 = Color3.fromRGB(225, 185, 60) end)
	btn.MouseLeave:Connect(function() stroke.Color = Color3.fromRGB(70, 70, 80); btn.TextColor3 = Color3.fromRGB(245, 245, 245) end)
	return btn, stroke
end

function ExpeditionsTab.Initialize(parentFrame)
	for _, child in ipairs(parentFrame:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end

	local MasterLayout = Instance.new("UIListLayout", parentFrame)
	MasterLayout.FillDirection = Enum.FillDirection.Horizontal
	MasterLayout.SortOrder = Enum.SortOrder.LayoutOrder
	MasterLayout.Padding = UDim.new(0, 20)

	-- ==========================================
	-- LEFT PANEL: MISSIONS GRID (Adjusted for perfect centering)
	-- ==========================================
	local MissionsPanel = Instance.new("Frame", parentFrame)
	MissionsPanel.Size = UDim2.new(0.68, 0, 1, 0)
	MissionsPanel.BackgroundTransparency = 1
	MissionsPanel.LayoutOrder = 1

	-- Perfect padding to balance the split layout
	local mPad = Instance.new("UIPadding", MissionsPanel)
	mPad.PaddingLeft = UDim.new(0.02, 0)

	local HeaderFrame = Instance.new("Frame", MissionsPanel)
	HeaderFrame.Size = UDim2.new(1, 0, 0, 50)
	HeaderFrame.BackgroundTransparency = 1

	local Title = UIHelpers.CreateLabel(HeaderFrame, "COMBAT DEPLOYMENT", UDim2.new(1, -60, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 22)
	Title.Position = UDim2.new(0, 0, 0, 0)
	Title.TextXAlignment = Enum.TextXAlignment.Left

	local BackBtn, BackStroke = CreateSharpButton(HeaderFrame, "< BACK", UDim2.new(0, 80, 0, 30), Enum.Font.GothamBlack, 12)
	BackBtn.Position = UDim2.new(1, 0, 0.5, 0)
	BackBtn.AnchorPoint = Vector2.new(1, 0.5)
	BackBtn.Visible = false

	local Pages = {}
	local function ShowPage(pageName, titleText)
		for name, frame in pairs(Pages) do
			frame.Visible = (name == pageName)
		end
		Title.Text = titleText
		BackBtn.Visible = (pageName ~= "Main")
	end

	BackBtn.MouseButton1Click:Connect(function()
		ShowPage("Main", "COMBAT DEPLOYMENT")
	end)

	-- ==========================================
	-- DYNAMIC CARD GENERATOR
	-- ==========================================
	local function CreateModeCard(parent, title, desc, imageId, layoutOrder, onClick)
		local cardBtn = Instance.new("TextButton", parent)
		cardBtn.LayoutOrder = layoutOrder
		cardBtn.Text = ""
		cardBtn.AutoButtonColor = false
		cardBtn.ClipsDescendants = true
		UIHelpers.ApplyGrimPanel(cardBtn, false)

		local bg = Instance.new("ImageLabel", cardBtn)
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundTransparency = 1
		bg.Image = imageId
		bg.ScaleType = Enum.ScaleType.Crop
		bg.ZIndex = 1

		local gradFrame = Instance.new("Frame", cardBtn)
		gradFrame.Size = UDim2.new(1, 0, 1, 0)
		gradFrame.BackgroundColor3 = Color3.new(0,0,0)
		gradFrame.BorderSizePixel = 0
		gradFrame.ZIndex = 2
		local grad = Instance.new("UIGradient", gradFrame)
		grad.Rotation = 90
		grad.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.9),   
			NumberSequenceKeypoint.new(0.5, 0.6),
			NumberSequenceKeypoint.new(1, 0.1)    
		}

		local lblTitle = UIHelpers.CreateLabel(cardBtn, title, UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 18)
		lblTitle.Position = UDim2.new(0, 10, 1, -70)
		lblTitle.TextXAlignment = Enum.TextXAlignment.Left
		lblTitle.TextScaled = true
		local tCon = Instance.new("UITextSizeConstraint", lblTitle)
		tCon.MaxTextSize = 18
		tCon.MinTextSize = 12
		lblTitle.ZIndex = 3

		local lblDesc = UIHelpers.CreateLabel(cardBtn, desc, UDim2.new(1, -20, 0, 35), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 12)
		lblDesc.Position = UDim2.new(0, 10, 1, -40)
		lblDesc.TextXAlignment = Enum.TextXAlignment.Left
		lblDesc.TextYAlignment = Enum.TextYAlignment.Top
		lblDesc.TextWrapped = true
		lblDesc.ZIndex = 3

		local stroke = cardBtn:FindFirstChild("UIStroke")
		cardBtn.MouseEnter:Connect(function()
			if stroke then stroke.Color = UIHelpers.Colors.Gold end
			lblTitle.TextColor3 = UIHelpers.Colors.Gold
			TweenService:Create(bg, TweenInfo.new(0.3), {Size = UDim2.new(1.1, 0, 1.1, 0), Position = UDim2.new(-0.05, 0, -0.05, 0)}):Play()
		end)
		cardBtn.MouseLeave:Connect(function()
			if stroke then stroke.Color = UIHelpers.Colors.BorderMuted end
			lblTitle.TextColor3 = UIHelpers.Colors.TextWhite
			TweenService:Create(bg, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)}):Play()
		end)

		cardBtn.MouseButton1Click:Connect(onClick)
	end

	-- ==========================================
	-- PAGE: MAIN SELECTION
	-- ==========================================
	local GridContainer = Instance.new("ScrollingFrame", MissionsPanel)
	GridContainer.Size = UDim2.new(1, 0, 1, -60)
	GridContainer.Position = UDim2.new(0, 0, 0, 50)
	GridContainer.BackgroundTransparency = 1
	GridContainer.ScrollBarThickness = 6
	GridContainer.BorderSizePixel = 0
	Pages["Main"] = GridContainer

	local gridLayout = Instance.new("UIGridLayout", GridContainer)
	gridLayout.CellSize = UDim2.new(0.48, 0, 0, 160) 
	gridLayout.CellPadding = UDim2.new(0.03, 0, 0, 15)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

	gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		GridContainer.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 40)
	end)

	CreateModeCard(GridContainer, "STORY CAMPAIGN", "Progress through the main storyline and conquer the threat.", DECALS.Campaign, 1, function() print("Deploy Campaign") end)
	CreateModeCard(GridContainer, "MULTIPLAYER RAIDS", "Deploy your party to take down Colossal threats.", DECALS.Raid, 2, function() ShowPage("Raids", "MULTIPLAYER RAIDS") end)
	CreateModeCard(GridContainer, "WORLD BOSSES", "A catastrophic threat has appeared. Intercept immediately.", DECALS.WorldBoss, 3, function() ShowPage("WorldBoss", "WORLD BOSSES") end)
	CreateModeCard(GridContainer, "PVP ARENA", "Test your ODM combat skills against other players.", DECALS.PvP, 4, function() ShowPage("PvP", "PVP ARENA") end)
	CreateModeCard(GridContainer, "NIGHTMARE HUNTS", "Face corrupted Titans to obtain legendary Cursed Weapons.", DECALS.Nightmare, 5, function() ShowPage("Nightmare", "NIGHTMARE HUNTS") end)
	CreateModeCard(GridContainer, "AFK EXPEDITIONS", "Send scouts into the wilderness to gather resources while you rest.", DECALS.AFK, 6, function() print("Deploy AFK") end)

	-- ==========================================
	-- PAGE: NIGHTMARE HUNTS (TALL GRID)
	-- ==========================================
	local NightmarePage = Instance.new("ScrollingFrame", MissionsPanel)
	NightmarePage.Size = UDim2.new(1, 0, 1, -60)
	NightmarePage.Position = UDim2.new(0, 0, 0, 50)
	NightmarePage.BackgroundTransparency = 1
	NightmarePage.ScrollBarThickness = 6
	NightmarePage.BorderSizePixel = 0
	NightmarePage.Visible = false
	Pages["Nightmare"] = NightmarePage

	local nmLayout = Instance.new("UIGridLayout", NightmarePage)
	nmLayout.CellSize = UDim2.new(0.31, 0, 0, 240) 
	nmLayout.CellPadding = UDim2.new(0.02, 0, 0, 15)
	nmLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	nmLayout.SortOrder = Enum.SortOrder.LayoutOrder

	nmLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		NightmarePage.CanvasSize = UDim2.new(0, 0, 0, nmLayout.AbsoluteContentSize.Y + 40)
	end)

	local nIndex = 1
	for id, boss in pairs(EnemyData.NightmareHunts) do
		local icon = EnemyData.BossIcons[id] or DECALS.Nightmare
		CreateModeCard(NightmarePage, string.upper(boss.Name), boss.Desc or "Eliminate the corrupted Titan.", icon, nIndex, function()
			Network:WaitForChild("CombatAction"):FireServer("EngageNightmare", {BossId = id})
		end)
		nIndex = nIndex + 1
	end

	-- ==========================================
	-- PAGE: WORLD BOSSES (TALL GRID)
	-- ==========================================
	local WorldBossPage = Instance.new("ScrollingFrame", MissionsPanel)
	WorldBossPage.Size = UDim2.new(1, 0, 1, -60)
	WorldBossPage.Position = UDim2.new(0, 0, 0, 50)
	WorldBossPage.BackgroundTransparency = 1
	WorldBossPage.ScrollBarThickness = 6
	WorldBossPage.BorderSizePixel = 0
	WorldBossPage.Visible = false
	Pages["WorldBoss"] = WorldBossPage

	local wbLayout = Instance.new("UIGridLayout", WorldBossPage)
	wbLayout.CellSize = UDim2.new(0.31, 0, 0, 240) 
	wbLayout.CellPadding = UDim2.new(0.02, 0, 0, 15)
	wbLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	wbLayout.SortOrder = Enum.SortOrder.LayoutOrder

	wbLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		WorldBossPage.CanvasSize = UDim2.new(0, 0, 0, wbLayout.AbsoluteContentSize.Y + 40)
	end)

	local wIndex = 1
	for id, boss in pairs(EnemyData.WorldBosses) do
		local icon = EnemyData.BossIcons[id] or DECALS.WorldBoss
		CreateModeCard(WorldBossPage, string.upper(boss.Name), boss.Desc or "A massive threat approaches.", icon, wIndex, function()
			Network:WaitForChild("CombatAction"):FireServer("EngageWorldBoss", {BossId = id})
		end)
		wIndex = wIndex + 1
	end

	-- ==========================================
	-- PAGE: MULTIPLAYER RAIDS (TALL GRID)
	-- ==========================================
	local RaidPage = Instance.new("ScrollingFrame", MissionsPanel)
	RaidPage.Size = UDim2.new(1, 0, 1, -60)
	RaidPage.Position = UDim2.new(0, 0, 0, 50)
	RaidPage.BackgroundTransparency = 1
	RaidPage.ScrollBarThickness = 6
	RaidPage.BorderSizePixel = 0
	RaidPage.Visible = false
	Pages["Raids"] = RaidPage

	local rLayout = Instance.new("UIGridLayout", RaidPage)
	rLayout.CellSize = UDim2.new(0.31, 0, 0, 240) 
	rLayout.CellPadding = UDim2.new(0.02, 0, 0, 15)
	rLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rLayout.SortOrder = Enum.SortOrder.LayoutOrder

	rLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		RaidPage.CanvasSize = UDim2.new(0, 0, 0, rLayout.AbsoluteContentSize.Y + 40)
	end)

	local raidList = {}
	for id, boss in pairs(EnemyData.RaidBosses) do
		table.insert(raidList, {Id = id, Data = boss})
	end
	table.sort(raidList, function(a, b) return a.Id < b.Id end)

	for i, rInfo in ipairs(raidList) do
		local id = rInfo.Id
		local boss = rInfo.Data
		local icon = EnemyData.BossIcons[id] or DECALS.Raid

		CreateModeCard(RaidPage, string.upper(boss.Name), "Requires a Party. Coordinate strikes and manage aggro.", icon, i, function()
			Network:WaitForChild("RaidAction"):FireServer("DeployParty", {RaidId = id})
		end)
	end

	-- ==========================================
	-- PAGE: PVP ARENA (UNCHANGED)
	-- ==========================================
	local PvPPage = Instance.new("Frame", MissionsPanel)
	PvPPage.Size = UDim2.new(1, 0, 1, -60)
	PvPPage.Position = UDim2.new(0, 0, 0, 50)
	PvPPage.BackgroundTransparency = 1
	PvPPage.Visible = false
	Pages["PvP"] = PvPPage

	local PvPQueuePanel = Instance.new("Frame", PvPPage)
	PvPQueuePanel.Size = UDim2.new(1, 0, 0, 150)
	UIHelpers.ApplyGrimPanel(PvPQueuePanel, false)

	local pqTitle = UIHelpers.CreateLabel(PvPQueuePanel, "RANKED MATCHMAKING", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 20)
	pqTitle.Position = UDim2.new(0, 0, 0, 15)

	local pqDesc = UIHelpers.CreateLabel(PvPQueuePanel, "Battle other players to increase your Elo Rating. Higher Elo grants better seasonal rewards.", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 14)
	pqDesc.Position = UDim2.new(0, 0, 0, 50)

	local QueueBtn = CreateSharpButton(PvPQueuePanel, "ENTER QUEUE", UDim2.new(0, 200, 0, 40), Enum.Font.GothamBlack, 16)
	QueueBtn.Position = UDim2.new(0.5, 0, 0, 90)
	QueueBtn.AnchorPoint = Vector2.new(0.5, 0)
	local inQueue = false

	QueueBtn.MouseButton1Click:Connect(function()
		inQueue = not inQueue
		if inQueue then
			QueueBtn.Text = "LEAVE QUEUE"
			QueueBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
			Network:WaitForChild("PvPAction"):FireServer("JoinQueue")
		else
			QueueBtn.Text = "ENTER QUEUE"
			QueueBtn.TextColor3 = UIHelpers.Colors.TextWhite
			Network:WaitForChild("PvPAction"):FireServer("LeaveQueue")
		end
	end)

	local PvPMatchesTitle = UIHelpers.CreateLabel(PvPPage, "ACTIVE SPECTATOR MATCHES", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 18)
	PvPMatchesTitle.Position = UDim2.new(0, 0, 0, 170)
	PvPMatchesTitle.TextXAlignment = Enum.TextXAlignment.Left

	local SpectateScroll = Instance.new("ScrollingFrame", PvPPage)
	SpectateScroll.Size = UDim2.new(1, 0, 1, -210)
	SpectateScroll.Position = UDim2.new(0, 0, 0, 210)
	SpectateScroll.BackgroundTransparency = 1
	SpectateScroll.ScrollBarThickness = 6
	SpectateScroll.BorderSizePixel = 0

	local specLayout = Instance.new("UIListLayout", SpectateScroll)
	specLayout.Padding = UDim.new(0, 10)
	specLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	specLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		SpectateScroll.CanvasSize = UDim2.new(0, 0, 0, specLayout.AbsoluteContentSize.Y + 20)
	end)

	local phLabel = UIHelpers.CreateLabel(SpectateScroll, "Fetching live matches...", UDim2.new(1, 0, 0, 50), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 14)

	-- ==========================================
	-- RIGHT PANEL: PARTY SYSTEM (28% Width)
	-- ==========================================
	local PartyPanel = Instance.new("Frame", parentFrame)
	PartyPanel.Size = UDim2.new(0.28, 0, 1, -20)
	PartyPanel.Position = UDim2.new(0, 0, 0, 10)
	PartyPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	PartyPanel.LayoutOrder = 2
	local pStroke = Instance.new("UIStroke", PartyPanel)
	pStroke.Color = UIHelpers.Colors.BorderMuted
	pStroke.Thickness = 2

	local PartyContent = Instance.new("Frame", PartyPanel)
	PartyContent.Size = UDim2.new(1, -30, 1, -30)
	PartyContent.Position = UDim2.new(0, 15, 0, 15)
	PartyContent.BackgroundTransparency = 1

	local function RenderPartyUI()
		for _, child in ipairs(PartyContent:GetChildren()) do child:Destroy() end

		local pLayout = Instance.new("UIListLayout", PartyContent)
		pLayout.SortOrder = Enum.SortOrder.LayoutOrder
		pLayout.Padding = UDim.new(0, 15)
		pLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

		if IsInParty then
			local Header = UIHelpers.CreateLabel(PartyContent, "STRIKE TEAM (" .. #CurrentParty .. "/3)", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 18)
			Header.LayoutOrder = 1; Header.TextXAlignment = Enum.TextXAlignment.Left

			-- Member Roster
			local RosterFrame = Instance.new("Frame", PartyContent)
			RosterFrame.Size = UDim2.new(1, 0, 0, #CurrentParty * 50)
			RosterFrame.BackgroundTransparency = 1
			RosterFrame.LayoutOrder = 2
			local rLayout = Instance.new("UIListLayout", RosterFrame); rLayout.Padding = UDim.new(0, 8)

			for _, member in ipairs(CurrentParty) do
				local mCard = Instance.new("Frame", RosterFrame)
				mCard.Size = UDim2.new(1, 0, 0, 42)
				mCard.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
				local mStroke = Instance.new("UIStroke", mCard); mStroke.Color = UIHelpers.Colors.BorderMuted

				local mName = UIHelpers.CreateLabel(mCard, member.Name, UDim2.new(1, -45, 1, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 14)
				mName.Position = UDim2.new(0, 15, 0, 0); mName.TextXAlignment = Enum.TextXAlignment.Left

				if member.IsLeader then
					local crown = UIHelpers.CreateLabel(mCard, "👑", UDim2.new(0, 30, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 16)
					crown.Position = UDim2.new(1, -35, 0, 0)
				end
			end

			-- Leader Controls
			if IsPartyLeader then
				local InviteContainer = Instance.new("Frame", PartyContent)
				InviteContainer.Size = UDim2.new(1, 0, 0, 80)
				InviteContainer.BackgroundTransparency = 1
				InviteContainer.LayoutOrder = 3

				local invHeader = UIHelpers.CreateLabel(InviteContainer, "INVITE PLAYER", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 12)
				invHeader.TextXAlignment = Enum.TextXAlignment.Left

				local NameInput = Instance.new("TextBox", InviteContainer)
				NameInput.Size = UDim2.new(1, 0, 0, 35)
				NameInput.Position = UDim2.new(0, 0, 0, 25)
				NameInput.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
				NameInput.TextColor3 = UIHelpers.Colors.TextWhite
				NameInput.Font = Enum.Font.GothamMedium
				NameInput.TextSize = 14
				NameInput.PlaceholderText = "Enter Username..."
				NameInput.Text = ""
				local inStroke = Instance.new("UIStroke", NameInput); inStroke.Color = UIHelpers.Colors.BorderMuted

				local InvBtn = CreateSharpButton(InviteContainer, "SEND", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, 12)
				InvBtn.Position = UDim2.new(0, 0, 0, 65)
				InvBtn.MouseButton1Click:Connect(function()
					if NameInput.Text ~= "" then
						Network:WaitForChild("PartyAction"):FireServer("Invite", NameInput.Text)
						NameInput.Text = ""
					end
				end)
			end

			local LeaveBtn = CreateSharpButton(PartyContent, "LEAVE TEAM", UDim2.new(1, 0, 0, 35), Enum.Font.GothamBlack, 14)
			LeaveBtn.LayoutOrder = 4
			LeaveBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
			LeaveBtn.MouseButton1Click:Connect(function() Network:WaitForChild("PartyAction"):FireServer("Leave") end)

		else
			-- Solo View
			local Header = UIHelpers.CreateLabel(PartyContent, "SOLO DEPLOYMENT", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextMuted, 18)
			Header.LayoutOrder = 1; Header.TextXAlignment = Enum.TextXAlignment.Left

			local CreateBtn = CreateSharpButton(PartyContent, "CREATE STRIKE TEAM", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, 14)
			CreateBtn.LayoutOrder = 2
			CreateBtn.MouseButton1Click:Connect(function() Network:WaitForChild("PartyAction"):FireServer("Create") end)

			-- Incoming Invites
			local inviteCount = 0
			for k, v in pairs(PendingInvites) do inviteCount = inviteCount + 1 end

			if inviteCount > 0 then
				local invHeader = UIHelpers.CreateLabel(PartyContent, "INCOMING INVITES", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBold, UIHelpers.Colors.Gold, 12)
				invHeader.LayoutOrder = 3; invHeader.TextXAlignment = Enum.TextXAlignment.Left

				local InvList = Instance.new("ScrollingFrame", PartyContent)
				InvList.Size = UDim2.new(1, 0, 1, -130)
				InvList.BackgroundTransparency = 1
				InvList.ScrollBarThickness = 4
				InvList.BorderSizePixel = 0
				InvList.LayoutOrder = 4
				local ilLayout = Instance.new("UIListLayout", InvList); ilLayout.Padding = UDim.new(0, 8)

				for inviterName, _ in pairs(PendingInvites) do
					local iCard = Instance.new("Frame", InvList)
					iCard.Size = UDim2.new(1, 0, 0, 40)
					iCard.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
					Instance.new("UIStroke", iCard).Color = UIHelpers.Colors.BorderMuted

					local iName = UIHelpers.CreateLabel(iCard, inviterName, UDim2.new(0.6, 0, 1, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 12)
					iName.Position = UDim2.new(0, 10, 0, 0); iName.TextXAlignment = Enum.TextXAlignment.Left

					local accBtn = CreateSharpButton(iCard, "JOIN", UDim2.new(0.35, 0, 0, 26), Enum.Font.GothamBlack, 10)
					accBtn.Position = UDim2.new(1, -5, 0.5, 0); accBtn.AnchorPoint = Vector2.new(1, 0.5)
					accBtn.TextColor3 = UIHelpers.Colors.Gold

					accBtn.MouseButton1Click:Connect(function()
						Network:WaitForChild("PartyAction"):FireServer("AcceptInvite", inviterName)
						PendingInvites[inviterName] = nil
						RenderPartyUI()
					end)
				end
			end
		end
	end

	if not isListening then
		isListening = true
		local PartyUpdate = Network:WaitForChild("PartyUpdate")
		PartyUpdate.OnClientEvent:Connect(function(action, data)
			if action == "UpdateList" then
				IsInParty = true
				CurrentParty = data
				IsPartyLeader = false
				for _, mem in ipairs(CurrentParty) do
					if mem.UserId == player.UserId and mem.IsLeader then IsPartyLeader = true end
				end
				PendingInvites = {} 
				RenderPartyUI()
			elseif action == "IncomingInvite" then
				PendingInvites[data] = true
				RenderPartyUI()
			elseif action == "Disbanded" then
				IsInParty = false
				CurrentParty = {}
				IsPartyLeader = false
				RenderPartyUI()
			end
		end)
	end

	RenderPartyUI()
end

return ExpeditionsTab