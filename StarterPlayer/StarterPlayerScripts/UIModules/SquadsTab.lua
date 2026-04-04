-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: SquadsTab
local SquadsTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Network = ReplicatedStorage:WaitForChild("Network")
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

local player = Players.LocalPlayer

local function CreateGrimPanel(parent)
	local frame = Instance.new("Frame", parent)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	frame.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(70, 70, 80)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return frame, stroke
end

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

	btn.MouseEnter:Connect(function() 
		if btn.Active then 
			btn:SetAttribute("OrigColor", btn.TextColor3)
			btn:SetAttribute("OrigStroke", stroke.Color)
			stroke.Color = UIHelpers.Colors.Gold
			btn.TextColor3 = UIHelpers.Colors.Gold 
		end
	end)
	btn.MouseLeave:Connect(function() 
		if btn.Active then 
			stroke.Color = btn:GetAttribute("OrigStroke") or Color3.fromRGB(70, 70, 80)
			btn.TextColor3 = btn:GetAttribute("OrigColor") or Color3.fromRGB(245, 245, 245)
		end
	end)
	return btn, stroke
end

local function CreateInput(parent, placeholder, size, pos)
	local input = Instance.new("TextBox", parent)
	input.Size = size
	input.Position = pos
	input.AnchorPoint = Vector2.new(0.5, 0)
	input.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	input.TextColor3 = UIHelpers.Colors.TextWhite
	input.Font = Enum.Font.GothamMedium
	input.TextSize = 14
	input.PlaceholderText = placeholder
	input.Text = ""
	local stroke = Instance.new("UIStroke", input)
	stroke.Color = UIHelpers.Colors.BorderMuted
	return input
end

function SquadsTab.Initialize(parentFrame)
	for _, child in ipairs(parentFrame:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end

	local MainFrame = Instance.new("Frame", parentFrame)
	MainFrame.Size = UDim2.new(1, 0, 1, 0)
	MainFrame.BackgroundTransparency = 1

	local mLayout = Instance.new("UIListLayout", MainFrame)
	mLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mLayout.Padding = UDim.new(0, 15)
	mLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local mPad = Instance.new("UIPadding", MainFrame)
	mPad.PaddingTop = UDim.new(0, 15)

	local Title = UIHelpers.CreateLabel(MainFrame, "STRIKE SQUADS COMMAND", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 26)
	Title.LayoutOrder = 1

	-- ==========================================
	-- SUB-NAVIGATION
	-- ==========================================
	local SubNav = Instance.new("Frame", MainFrame)
	SubNav.Size = UDim2.new(0.95, 0, 0, 45)
	SubNav.BackgroundTransparency = 1
	SubNav.LayoutOrder = 2

	local navLayout = Instance.new("UIListLayout", SubNav)
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	navLayout.Padding = UDim.new(0, 10)

	local ContentArea = Instance.new("Frame", MainFrame)
	ContentArea.Size = UDim2.new(0.95, 0, 1, -120)
	ContentArea.BackgroundTransparency = 1
	ContentArea.LayoutOrder = 3

	local subTabs = { "MY SQUAD", "SQUAD FINDER" }
	local activeSubFrames = {}
	local subBtns = {}

	for i, tabName in ipairs(subTabs) do
		local btn, stroke = CreateSharpButton(SubNav, tabName, UDim2.new(0, 160, 0, 30), Enum.Font.GothamBold, 12)
		btn.TextColor3 = UIHelpers.Colors.TextMuted
		stroke.Color = UIHelpers.Colors.BorderMuted

		local subFrame = Instance.new("Frame", ContentArea)
		subFrame.Name = tabName
		subFrame.Size = UDim2.new(1, 0, 1, 0)
		subFrame.BackgroundTransparency = 1
		subFrame.Visible = (i == 1)

		activeSubFrames[tabName] = subFrame
		subBtns[tabName] = {Btn = btn, Stroke = stroke}

		btn.MouseButton1Click:Connect(function()
			for name, frame in pairs(activeSubFrames) do frame.Visible = (name == tabName) end
			for name, bData in pairs(subBtns) do
				bData.Btn.TextColor3 = (name == tabName) and UIHelpers.Colors.Gold or UIHelpers.Colors.TextMuted
				bData.Stroke.Color = (name == tabName) and UIHelpers.Colors.Gold or UIHelpers.Colors.BorderMuted
			end
		end)
	end

	subBtns["MY SQUAD"].Btn.TextColor3 = UIHelpers.Colors.Gold
	subBtns["MY SQUAD"].Stroke.Color = UIHelpers.Colors.Gold

	-- ==========================================
	-- TAB 1: MY SQUAD
	-- ==========================================
	local MySquadTab = activeSubFrames["MY SQUAD"]

	local SplitContainer = Instance.new("Frame", MySquadTab)
	SplitContainer.Size = UDim2.new(1, 0, 1, 0)
	SplitContainer.BackgroundTransparency = 1
	local scLayout = Instance.new("UIListLayout", SplitContainer)
	scLayout.FillDirection = Enum.FillDirection.Horizontal
	scLayout.Padding = UDim.new(0, 20)

	-- LEFT PANEL: SQUAD DASHBOARD
	local LeftPanel = Instance.new("Frame", SplitContainer)
	LeftPanel.Size = UDim2.new(0.55, 0, 1, 0)
	LeftPanel.BackgroundTransparency = 1

	local DashContainer, _ = CreateGrimPanel(LeftPanel)
	DashContainer.Size = UDim2.new(1, 0, 1, 0)

	-- [[ NOT IN SQUAD - REGISTRATION FORM ]]
	local NotInSquadView = Instance.new("Frame", DashContainer)
	NotInSquadView.Size = UDim2.new(1, 0, 1, 0)
	NotInSquadView.BackgroundTransparency = 1
	NotInSquadView.Visible = false

	local niTitle = UIHelpers.CreateLabel(NotInSquadView, "SQUAD REGISTRATION", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 22)
	niTitle.Position = UDim2.new(0, 0, 0, 20)

	local niDesc = UIHelpers.CreateLabel(NotInSquadView, "Found a Strike Squad to accumulate global Contribution Points (CP) and unlock utility perks for your members.", UDim2.new(0.8, 0, 0, 40), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 13)
	niDesc.Position = UDim2.new(0.1, 0, 0, 60)
	niDesc.TextWrapped = true

	local NameInput = CreateInput(NotInSquadView, "Enter Squad Name (Max 20 Chars)", UDim2.new(0.7, 0, 0, 40), UDim2.new(0.5, 0, 0, 120))
	local DescInput = CreateInput(NotInSquadView, "Enter Squad Description / Motto", UDim2.new(0.7, 0, 0, 40), UDim2.new(0.5, 0, 0, 175))
	local LogoInput = CreateInput(NotInSquadView, "Enter Logo Image ID (e.g. 12345678)", UDim2.new(0.7, 0, 0, 40), UDim2.new(0.5, 0, 0, 230))

	local CreateBtn, cStroke = CreateSharpButton(NotInSquadView, "FOUND SQUAD (100,000 Dews)", UDim2.new(0.6, 0, 0, 50), Enum.Font.GothamBlack, 16)
	CreateBtn.Position = UDim2.new(0.5, 0, 0, 300)
	CreateBtn.AnchorPoint = Vector2.new(0.5, 0)
	CreateBtn.TextColor3 = UIHelpers.Colors.Gold
	cStroke.Color = UIHelpers.Colors.Gold

	CreateBtn.MouseButton1Click:Connect(function()
		if NameInput.Text ~= "" then
			Network:WaitForChild("SquadAction"):FireServer("Create", {
				Name = NameInput.Text,
				Desc = DescInput.Text,
				Logo = LogoInput.Text
			})
		end
	end)

	-- [[ IN SQUAD - ACTIVE DASHBOARD ]]
	local InSquadView = Instance.new("Frame", DashContainer)
	InSquadView.Size = UDim2.new(1, 0, 1, 0)
	InSquadView.BackgroundTransparency = 1
	InSquadView.Visible = true

	local SquadLogo = Instance.new("ImageLabel", InSquadView)
	SquadLogo.Size = UDim2.new(0, 80, 0, 80)
	SquadLogo.Position = UDim2.new(0, 20, 0, 20)
	SquadLogo.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	local logoStroke = Instance.new("UIStroke", SquadLogo)
	logoStroke.Color = UIHelpers.Colors.Gold
	logoStroke.Thickness = 2

	local SquadNameLbl = UIHelpers.CreateLabel(InSquadView, "SQUAD NAME", UDim2.new(1, -120, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 24)
	SquadNameLbl.Position = UDim2.new(0, 115, 0, 20); SquadNameLbl.TextXAlignment = Enum.TextXAlignment.Left

	local SquadDescLbl = UIHelpers.CreateLabel(InSquadView, "Squad Description goes here.", UDim2.new(1, -120, 0, 30), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 12)
	SquadDescLbl.Position = UDim2.new(0, 115, 0, 55); SquadDescLbl.TextXAlignment = Enum.TextXAlignment.Left; SquadDescLbl.TextWrapped = true

	local CpLabel = UIHelpers.CreateLabel(InSquadView, "TOTAL CP: 0", UDim2.new(1, -120, 0, 20), Enum.Font.GothamBlack, Color3.fromRGB(85, 170, 255), 14)
	CpLabel.Position = UDim2.new(0, 115, 0, 85); CpLabel.TextXAlignment = Enum.TextXAlignment.Left

	local RosterTitle = UIHelpers.CreateLabel(InSquadView, "ACTIVE ROSTER", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 16)
	RosterTitle.Position = UDim2.new(0, 20, 0, 130); RosterTitle.TextXAlignment = Enum.TextXAlignment.Left

	local RosterList = Instance.new("ScrollingFrame", InSquadView)
	RosterList.Size = UDim2.new(1, -40, 1, -260)
	RosterList.Position = UDim2.new(0, 20, 0, 160)
	RosterList.BackgroundTransparency = 1
	RosterList.ScrollBarThickness = 4
	RosterList.BorderSizePixel = 0

	local rlLayout = Instance.new("UIListLayout", RosterList)
	rlLayout.Padding = UDim.new(0, 8)
	rlLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() RosterList.CanvasSize = UDim2.new(0,0,0, rlLayout.AbsoluteContentSize.Y + 10) end)

	-- [[ TRUE SQUAD VAULT AREA ]]
	local VaultTitle = UIHelpers.CreateLabel(InSquadView, "SQUAD VAULT (Click to Deposit/Withdraw)", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 14)
	VaultTitle.Position = UDim2.new(0, 20, 1, -95); VaultTitle.TextXAlignment = Enum.TextXAlignment.Left

	local VaultContainer = Instance.new("Frame", InSquadView)
	VaultContainer.Size = UDim2.new(1, -40, 0, 45)
	VaultContainer.Position = UDim2.new(0, 20, 1, -65)
	VaultContainer.BackgroundTransparency = 1
	local vcLayout = Instance.new("UIGridLayout", VaultContainer)
	vcLayout.CellSize = UDim2.new(0.15, 0, 1, 0)
	vcLayout.CellPadding = UDim2.new(0.02, 0, 0, 0)

	-- Vault Deposit Popup
	local InvOverlay = Instance.new("Frame", MainFrame)
	InvOverlay.Size = UDim2.new(1, 0, 1, 0)
	InvOverlay.BackgroundColor3 = Color3.new(0,0,0)
	InvOverlay.BackgroundTransparency = 0.6
	InvOverlay.ZIndex = 50
	InvOverlay.Visible = false
	InvOverlay.Active = true

	local InvPanel, _ = CreateGrimPanel(InvOverlay)
	InvPanel.Size = UDim2.new(0, 400, 0, 500)
	InvPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	InvPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	InvPanel.ZIndex = 51

	local invTitle = UIHelpers.CreateLabel(InvPanel, "DEPOSIT ITEM", UDim2.new(1, 0, 0, 50), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 20)
	invTitle.ZIndex = 52

	local closeInvBtn, _ = CreateSharpButton(InvPanel, "X", UDim2.new(0, 40, 0, 40), Enum.Font.GothamBlack, 18)
	closeInvBtn.Position = UDim2.new(1, -10, 0, 10)
	closeInvBtn.AnchorPoint = Vector2.new(1, 0)
	closeInvBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	closeInvBtn.ZIndex = 52
	closeInvBtn.MouseButton1Click:Connect(function() InvOverlay.Visible = false end)

	local InvScroll = Instance.new("ScrollingFrame", InvPanel)
	InvScroll.Size = UDim2.new(1, -20, 1, -70)
	InvScroll.Position = UDim2.new(0, 10, 0, 60)
	InvScroll.BackgroundTransparency = 1
	InvScroll.ScrollBarThickness = 6
	InvScroll.BorderSizePixel = 0
	InvScroll.ZIndex = 52

	local invLayout = Instance.new("UIListLayout", InvScroll)
	invLayout.Padding = UDim.new(0, 10)
	invLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() InvScroll.CanvasSize = UDim2.new(0,0,0, invLayout.AbsoluteContentSize.Y + 10) end)

	local noItemsLbl = UIHelpers.CreateLabel(InvPanel, "You have no items to deposit.", UDim2.new(1, 0, 0, 50), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 14)
	noItemsLbl.Position = UDim2.new(0, 0, 0.5, 0)
	noItemsLbl.AnchorPoint = Vector2.new(0, 0.5)
	noItemsLbl.ZIndex = 52

	local activeVaultSlot = 1
	local function OpenInventorySelection(slotId)
		activeVaultSlot = slotId
		InvOverlay.Visible = true
		for _, c in ipairs(InvScroll:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end

		local foundAny = false
		local function ScanItems(dictionary)
			for itemName, _ in pairs(dictionary) do
				local safeName = itemName:gsub("[^%w]", "") .. "Count"
				local count = player:GetAttribute(safeName) or 0
				if count > 0 then
					foundAny = true
					local btn, stroke = CreateSharpButton(InvScroll, count .. "x " .. itemName, UDim2.new(1, -10, 0, 45), Enum.Font.GothamBold, 12)
					btn.ZIndex = 53
					btn.MouseButton1Click:Connect(function()
						InvOverlay.Visible = false
						Network:WaitForChild("SquadAction"):FireServer("DepositItem", {Slot = activeVaultSlot, ItemName = itemName})
					end)
				end
			end
		end

		ScanItems(ItemData.Equipment or {})
		ScanItems(ItemData.Consumables or {})

		noItemsLbl.Visible = not foundAny
	end

	local vaultBtns = {}
	for i = 1, 6 do
		local vBtn, stroke = CreateSharpButton(VaultContainer, "Empty", UDim2.new(1, 0, 1, 0), Enum.Font.GothamBold, 10)
		vBtn.TextWrapped = true

		-- Logic: Click empty to deposit, click full to withdraw
		vBtn.MouseButton1Click:Connect(function()
			local rawVault = player:GetAttribute("SquadVault")
			local squadVault = {"None", "None", "None", "None", "None", "None"}
			if rawVault and rawVault ~= "" then
				pcall(function() squadVault = HttpService:JSONDecode(rawVault) end)
			end

			if squadVault[i] == "None" then
				OpenInventorySelection(i)
			else
				Network:WaitForChild("SquadAction"):FireServer("WithdrawItem", {Slot = i})
			end
		end)
		vaultBtns[i] = {Btn = vBtn, Stroke = stroke}
	end

	-- ==========================================
	-- RIGHT PANEL: LEADERBOARDS & PERKS
	-- ==========================================
	local RightPanel = Instance.new("Frame", SplitContainer)
	RightPanel.Size = UDim2.new(0.45, -20, 1, 0)
	RightPanel.BackgroundTransparency = 1

	local LbContainer, _ = CreateGrimPanel(RightPanel)
	LbContainer.Size = UDim2.new(1, 0, 0.6, 0)

	local lbTitle = UIHelpers.CreateLabel(LbContainer, "GLOBAL SQUAD LEADERBOARD", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 18)

	local LbScroll = Instance.new("ScrollingFrame", LbContainer)
	LbScroll.Size = UDim2.new(1, -20, 1, -50)
	LbScroll.Position = UDim2.new(0, 10, 0, 40)
	LbScroll.BackgroundTransparency = 1
	LbScroll.ScrollBarThickness = 4
	LbScroll.BorderSizePixel = 0

	local lsLayout = Instance.new("UIListLayout", LbScroll)
	lsLayout.Padding = UDim.new(0, 8)
	lsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() LbScroll.CanvasSize = UDim2.new(0,0,0, lsLayout.AbsoluteContentSize.Y + 10) end)

	local PerksContainer, _ = CreateGrimPanel(RightPanel)
	PerksContainer.Size = UDim2.new(1, 0, 0.35, 0)
	PerksContainer.Position = UDim2.new(0, 0, 0.65, 0)

	local pkTitle = UIHelpers.CreateLabel(PerksContainer, "ACTIVE SQUAD PERKS", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 16)

	local pkDesc = UIHelpers.CreateLabel(PerksContainer, "Logistics II: Max Members +10\nTreasury I: Bounty Dews +10%\nArmory I: Vault Capacity +5\nAcademy I: Auto-Train Efficiency +5%", UDim2.new(1, -40, 1, -40), Enum.Font.GothamMedium, Color3.fromRGB(85, 255, 85), 13)
	pkDesc.Position = UDim2.new(0, 20, 0, 30)
	pkDesc.TextXAlignment = Enum.TextXAlignment.Left
	pkDesc.TextYAlignment = Enum.TextYAlignment.Top

	-- Check State Logic & Sync Data
	local function UpdateSquadUI()
		local mySquad = player:GetAttribute("SquadName")
		if mySquad and mySquad ~= "" and mySquad ~= "None" then
			NotInSquadView.Visible = false
			InSquadView.Visible = true
			SquadNameLbl.Text = mySquad
			SquadDescLbl.Text = player:GetAttribute("SquadDesc") or "No description set."

			local rawLogo = player:GetAttribute("SquadLogo") or ""
			if rawLogo ~= "" then
				SquadLogo.Image = string.match(rawLogo, "rbxassetid") and rawLogo or "rbxassetid://" .. rawLogo:match("%d+")
			end
			CpLabel.Text = "TOTAL CP: " .. (player:GetAttribute("SquadCP") or 0)

			task.spawn(function()
				for _, c in ipairs(RosterList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
				local rosterData = Network:WaitForChild("GetSquadRoster"):InvokeServer()
				if rosterData then
					for _, member in ipairs(rosterData) do
						local mCard, _ = CreateGrimPanel(RosterList)
						mCard.Size = UDim2.new(1, -10, 0, 40)

						local mName = UIHelpers.CreateLabel(mCard, member.Name, UDim2.new(0.6, 0, 1, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 14)
						mName.Position = UDim2.new(0, 15, 0, 0); mName.TextXAlignment = Enum.TextXAlignment.Left

						local mRole = UIHelpers.CreateLabel(mCard, member.Role, UDim2.new(0.3, 0, 1, 0), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 12)
						mRole.Position = UDim2.new(0.7, -15, 0, 0); mRole.TextXAlignment = Enum.TextXAlignment.Right
					end
				end
			end)

			-- Sync Shared Vault UI
			local rawVault = player:GetAttribute("SquadVault")
			local squadVault = {"None", "None", "None", "None", "None", "None"}
			if rawVault and rawVault ~= "" then
				pcall(function() squadVault = HttpService:JSONDecode(rawVault) end)
			end

			for i = 1, 6 do
				local storeObj = vaultBtns[i]
				local btn = storeObj.Btn
				local storedItem = squadVault[i] or "None"

				btn.Text = (storedItem == "None" and "Empty" or storedItem)
				if storedItem ~= "None" then
					storeObj.Stroke.Color = UIHelpers.Colors.Gold
					btn.TextColor3 = Color3.fromRGB(230, 230, 230)
				else 
					storeObj.Stroke.Color = UIHelpers.Colors.BorderMuted
					btn.TextColor3 = UIHelpers.Colors.TextMuted 
				end
			end
		else
			NotInSquadView.Visible = true
			InSquadView.Visible = false
		end
	end

	task.spawn(function()
		for _, c in ipairs(LbScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		local lbData = Network:WaitForChild("GetSquadLeaderboard"):InvokeServer()
		if lbData then
			for i, data in ipairs(lbData) do
				local rankCard, _ = CreateGrimPanel(LbScroll)
				rankCard.Size = UDim2.new(1, -10, 0, 35)

				local cColor = (i==1) and UIHelpers.Colors.Gold or ((i==2) and Color3.fromRGB(200, 200, 200) or UIHelpers.Colors.TextWhite)

				local rNum = UIHelpers.CreateLabel(rankCard, "#" .. data.Rank, UDim2.new(0, 30, 1, 0), Enum.Font.GothamBlack, cColor, 14)
				rNum.Position = UDim2.new(0, 10, 0, 0)

				local sName = UIHelpers.CreateLabel(rankCard, data.Name, UDim2.new(0.5, 0, 1, 0), Enum.Font.GothamBold, cColor, 14)
				sName.Position = UDim2.new(0, 50, 0, 0); sName.TextXAlignment = Enum.TextXAlignment.Left

				local sCp = UIHelpers.CreateLabel(rankCard, tostring(data.CP) .. " CP", UDim2.new(0.3, 0, 1, 0), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 12)
				sCp.Position = UDim2.new(0.7, -10, 0, 0); sCp.TextXAlignment = Enum.TextXAlignment.Right
			end
		end
	end)

	player.AttributeChanged:Connect(function(attr)
		if string.find(attr, "Squad") then 
			UpdateSquadUI() 
		end
	end)
	UpdateSquadUI()


	-- ==========================================
	-- TAB 2: SQUAD FINDER
	-- ==========================================
	local FinderTab = activeSubFrames["SQUAD FINDER"]

	local FinderContainer, _ = CreateGrimPanel(FinderTab)
	FinderContainer.Size = UDim2.new(1, 0, 1, 0)

	local finderTitle = UIHelpers.CreateLabel(FinderContainer, "PUBLIC SQUAD DIRECTORY", UDim2.new(1, -40, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 20)
	finderTitle.Position = UDim2.new(0, 20, 0, 10)
	finderTitle.TextXAlignment = Enum.TextXAlignment.Left

	local FinderScroll = Instance.new("ScrollingFrame", FinderContainer)
	FinderScroll.Size = UDim2.new(1, -40, 1, -70)
	FinderScroll.Position = UDim2.new(0, 20, 0, 50)
	FinderScroll.BackgroundTransparency = 1
	FinderScroll.ScrollBarThickness = 6
	FinderScroll.BorderSizePixel = 0

	local fsLayout = Instance.new("UIListLayout", FinderScroll)
	fsLayout.Padding = UDim.new(0, 10)
	fsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() FinderScroll.CanvasSize = UDim2.new(0,0,0, fsLayout.AbsoluteContentSize.Y + 20) end)

	local function AddSquadCard(sqName, sqDesc, sqLogo, sqLevel, memberCount, cpScore)
		local card, _ = CreateGrimPanel(FinderScroll)
		card.Size = UDim2.new(1, -10, 0, 80)
		card.BackgroundColor3 = Color3.fromRGB(25, 25, 30)

		local logo = Instance.new("ImageLabel", card)
		logo.Size = UDim2.new(0, 60, 0, 60)
		logo.Position = UDim2.new(0, 10, 0, 10)
		logo.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
		logo.Image = sqLogo
		local lStroke = Instance.new("UIStroke", logo); lStroke.Color = UIHelpers.Colors.BorderMuted; lStroke.Thickness = 1

		local nameLbl = UIHelpers.CreateLabel(card, sqName, UDim2.new(0.5, 0, 0, 25), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 16)
		nameLbl.Position = UDim2.new(0, 85, 0, 10); nameLbl.TextXAlignment = Enum.TextXAlignment.Left

		local descLbl = UIHelpers.CreateLabel(card, sqDesc, UDim2.new(0.5, 0, 0, 30), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 12)
		descLbl.Position = UDim2.new(0, 85, 0, 35); descLbl.TextXAlignment = Enum.TextXAlignment.Left; descLbl.TextWrapped = true

		local statsLbl = UIHelpers.CreateLabel(card, "Lv. " .. sqLevel .. " | " .. memberCount .. " Members | " .. cpScore .. " CP", UDim2.new(0.3, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 12)
		statsLbl.Position = UDim2.new(1, -160, 0, 10); statsLbl.AnchorPoint = Vector2.new(1, 0); statsLbl.TextXAlignment = Enum.TextXAlignment.Right

		local reqBtn, rStroke = CreateSharpButton(card, "REQUEST JOIN", UDim2.new(0, 140, 0, 35), Enum.Font.GothamBlack, 12)
		reqBtn.Position = UDim2.new(1, -15, 1, -10)
		reqBtn.AnchorPoint = Vector2.new(1, 1)
		reqBtn.TextColor3 = Color3.fromRGB(85, 170, 255)
		rStroke.Color = Color3.fromRGB(85, 170, 255)

		reqBtn.MouseButton1Click:Connect(function()
			Network:WaitForChild("SquadAction"):FireServer("RequestJoin", sqName)
			reqBtn.Text = "REQUEST SENT"
			reqBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
			rStroke.Color = UIHelpers.Colors.BorderMuted
			reqBtn.Active = false
		end)
	end

	task.spawn(function()
		local publicSquads = Network:WaitForChild("GetPublicSquads"):InvokeServer()
		if publicSquads then
			for _, sq in ipairs(publicSquads) do
				AddSquadCard(sq.Name, sq.Desc, sq.Logo, sq.Level, sq.MemberCount, sq.CP)
			end
		end
	end)

end

return SquadsTab