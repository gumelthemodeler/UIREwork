-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: MainUI
local MainUI = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))

local MasterGui
local MasterWindow
local WindowScale
local WindowTitle
local TabContainers = {}
local CurrentOpenTab = nil

-- Global Currency Trackers
local lblElo, lblPrestige, lblDews, lblXP, lblTitanXP
local player = Players.LocalPlayer

-- Admin Verification Check
local isAdmin = player:GetAttribute("IsAdmin") or player.Name == "girthbender1209"

local function BuildEnvironment(onComplete)
	local BGFrame = Instance.new("Frame", MasterGui)
	BGFrame.Name = "TexturedBackground"
	BGFrame.Size = UDim2.new(1, 0, 1, 0)
	BGFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	BGFrame.ZIndex = -10

	local Texture = Instance.new("ImageLabel", BGFrame)
	Texture.Size = UDim2.new(1, 0, 1, 0)
	Texture.BackgroundTransparency = 1
	Texture.Image = "rbxassetid://125800917140688" 
	Texture.ImageTransparency = 0.50
	Texture.ScaleType = Enum.ScaleType.Crop 
	Texture.ZIndex = -9

	if onComplete then onComplete() end
end

local function FormatAbbreviation(value)
	local num = tonumber(value)
	if not num then return "0" end

	if num >= 1e9 then
		return string.format("%.1fB", num / 1e9):gsub("%.0B", "B")
	elseif num >= 1e6 then
		return string.format("%.1fM", num / 1e6):gsub("%.0M", "M")
	elseif num >= 1e3 then
		return string.format("%.1fK", num / 1e3):gsub("%.0K", "K")
	else
		return tostring(num)
	end
end

local function BuildMasterWindow()
	MasterWindow = Instance.new("Frame", MasterGui)
	MasterWindow.Name = "MasterWindow"
	MasterWindow.Size = UDim2.new(0, 1200, 0, 680) 
	MasterWindow.Position = UDim2.new(0.5, 0, 0.45, 0)
	MasterWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	MasterWindow.Visible = false

	MasterWindow.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	MasterWindow.BorderSizePixel = 0
	local mwStroke = Instance.new("UIStroke", MasterWindow)
	mwStroke.Color = Color3.fromRGB(70, 70, 80)
	mwStroke.Thickness = 2
	mwStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local sizeConstraint = Instance.new("UISizeConstraint", MasterWindow)
	sizeConstraint.MaxSize = Vector2.new(1400, 850)
	sizeConstraint.MinSize = Vector2.new(1000, 600)

	WindowScale = Instance.new("UIScale", MasterWindow)
	WindowScale.Scale = 0

	local Header = Instance.new("Frame", MasterWindow)
	Header.Size = UDim2.new(1, 0, 0, 60)
	Header.BackgroundColor3 = UIHelpers.Colors.Surface
	Header.BorderSizePixel = 0

	local headerStroke = Instance.new("UIStroke", Header)
	headerStroke.Color = UIHelpers.Colors.BorderMuted
	headerStroke.Thickness = 2
	headerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	WindowTitle = UIHelpers.CreateLabel(Header, "COMMAND CENTER", UDim2.new(0, 350, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 24)
	WindowTitle.Position = UDim2.new(0, 25, 0, 0)
	WindowTitle.TextXAlignment = Enum.TextXAlignment.Left

	-- Universal Close Button
	local CloseBtn = Instance.new("TextButton", Header)
	CloseBtn.Size = UDim2.new(0, 40, 0, 40)
	CloseBtn.Position = UDim2.new(1, -10, 0.5, 0)
	CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
	CloseBtn.BackgroundColor3 = Color3.fromRGB(25, 20, 20)
	CloseBtn.Text = "X"
	CloseBtn.Font = Enum.Font.GothamBlack
	CloseBtn.TextSize = 18
	CloseBtn.TextColor3 = Color3.fromRGB(255, 85, 85)
	local cbStroke = Instance.new("UIStroke", CloseBtn)
	cbStroke.Color = Color3.fromRGB(255, 85, 85)
	cbStroke.Thickness = 2

	CloseBtn.MouseButton1Click:Connect(function()
		CurrentOpenTab = nil
		local t = TweenService:Create(WindowScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
		t:Play()
		t.Completed:Wait()
		MasterWindow.Visible = false
	end)

	local StatsContainer = Instance.new("Frame", Header)
	StatsContainer.Size = UDim2.new(0.70, 0, 1, 0)
	StatsContainer.Position = UDim2.new(1, -65, 0, 0)
	StatsContainer.AnchorPoint = Vector2.new(1, 0)
	StatsContainer.BackgroundTransparency = 1

	local statLayout = Instance.new("UIListLayout", StatsContainer)
	statLayout.FillDirection = Enum.FillDirection.Horizontal
	statLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	statLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	statLayout.Padding = UDim.new(0, 8)

	local function CreateTopBox(title, hexColor)
		local box = Instance.new("Frame", StatsContainer)
		box.Size = UDim2.new(0, 130, 0, 36)
		box.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
		local bStroke = Instance.new("UIStroke", box)
		bStroke.Color = Color3.fromRGB(70, 70, 80)
		bStroke.Thickness = 2

		local tLbl = UIHelpers.CreateLabel(box, title, UDim2.new(0.5, -5, 1, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 10)
		tLbl.Position = UDim2.new(0, 5, 0, 0); tLbl.TextXAlignment = Enum.TextXAlignment.Left

		local vLbl = UIHelpers.CreateLabel(box, "0", UDim2.new(0.5, -5, 1, 0), Enum.Font.GothamBlack, Color3.fromHex(hexColor:gsub("#","")), 13)
		vLbl.Position = UDim2.new(0.5, 0, 0, 0); vLbl.TextXAlignment = Enum.TextXAlignment.Right
		return vLbl
	end

	lblXP = CreateTopBox("XP", "#55FF55")
	lblTitanXP = CreateTopBox("TITAN XP", "#FF5555")
	lblDews = CreateTopBox("DEWS", "#FF88FF")
	lblPrestige = CreateTopBox("PRESTIGE", "#FFD700")
	lblElo = CreateTopBox("ELO RATING", "#55AAFF")

	local function UpdateCurrencies()
		local ls = player:FindFirstChild("leaderstats")
		lblPrestige.Text = FormatAbbreviation((ls and ls:FindFirstChild("Prestige")) and ls.Prestige.Value or 0)
		lblElo.Text = FormatAbbreviation((ls and ls:FindFirstChild("Elo")) and ls.Elo.Value or 1000)
		lblDews.Text = FormatAbbreviation(player:GetAttribute("Dews") or 0)
		lblXP.Text = FormatAbbreviation(player:GetAttribute("XP") or 0)
		lblTitanXP.Text = FormatAbbreviation(player:GetAttribute("TitanXP") or 0)
	end

	player.AttributeChanged:Connect(function(a) 
		if a == "Dews" or a == "XP" or a == "TitanXP" then UpdateCurrencies() end 
	end)

	task.spawn(function()
		local ls = player:WaitForChild("leaderstats", 10)
		if ls then
			for _, child in ipairs(ls:GetChildren()) do
				if child:IsA("IntValue") then child.Changed:Connect(UpdateCurrencies) end
			end
		end
		UpdateCurrencies()
	end)

	local ContentArea = Instance.new("Frame", MasterWindow)
	ContentArea.Size = UDim2.new(1, 0, 1, -60)
	ContentArea.Position = UDim2.new(0, 0, 0, 60)
	ContentArea.BackgroundTransparency = 1

	local tabs = {"HOME", "PROFILE", "EXPEDITIONS", "SQUADS", "SUPPLY_FORGE", "REGIMENTS"}

	-- [[ ADMIN TAB INJECTION ]]
	if isAdmin then table.insert(tabs, "ADMIN") end

	for _, tabName in ipairs(tabs) do
		local tabFrame = Instance.new("Frame", ContentArea)
		tabFrame.Name = tabName
		tabFrame.Size = UDim2.new(1, 0, 1, 0)
		tabFrame.BackgroundTransparency = 1
		tabFrame.Visible = false
		TabContainers[tabName] = tabFrame
	end

	-- ==========================================
	-- THE "HOME" (DEFAULT) TAB INJECTION
	-- ==========================================
	local function BuildHomeTab()
		local hTab = TabContainers["HOME"]

		local hSplit = Instance.new("Frame", hTab)
		hSplit.Size = UDim2.new(1, -40, 1, -40)
		hSplit.Position = UDim2.new(0, 20, 0, 20)
		hSplit.BackgroundTransparency = 1
		local hsLayout = Instance.new("UIListLayout", hSplit)
		hsLayout.FillDirection = Enum.FillDirection.Horizontal
		hsLayout.Padding = UDim.new(0, 20)

		local hLeft = Instance.new("Frame", hSplit)
		hLeft.Size = UDim2.new(0.35, 0, 1, 0)
		hLeft.BackgroundTransparency = 1

		local GameIcon = Instance.new("ImageLabel", hLeft)
		GameIcon.Size = UDim2.new(0, 240, 0, 240)
		GameIcon.Position = UDim2.new(0.5, 0, 0.22, 0)
		GameIcon.AnchorPoint = Vector2.new(0.5, 0.5) 
		GameIcon.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
		GameIcon.Image = "rbxassetid://129999765135567" 
		GameIcon.ScaleType = Enum.ScaleType.Fit 

		local giAspect = Instance.new("UIAspectRatioConstraint", GameIcon)
		giAspect.AspectRatio = 1.0 

		local giStroke = Instance.new("UIStroke", GameIcon)
		giStroke.Color = UIHelpers.Colors.Gold
		giStroke.Thickness = 2

		local ChangeLogBox = Instance.new("Frame", hLeft)
		ChangeLogBox.Size = UDim2.new(1, 0, 0.5, 0)
		ChangeLogBox.Position = UDim2.new(0, 0, 0.5, 0)
		ChangeLogBox.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
		local clStroke = Instance.new("UIStroke", ChangeLogBox)
		clStroke.Color = Color3.fromRGB(70, 70, 80)
		clStroke.Thickness = 2

		local clTitle = UIHelpers.CreateLabel(ChangeLogBox, "CHANGELOG & CODES", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 16)
		clTitle.Position = UDim2.new(0, 10, 0, 10)
		clTitle.TextXAlignment = Enum.TextXAlignment.Left

		local clText = UIHelpers.CreateLabel(ChangeLogBox, "<b>v1.5.0 - The Global Update</b>\n\n• Added Strike Squads & Global Leaderboards.\n• Overhauled Market & Forge UI.\n• Added Item Locking & Auto-Sell.\n• Dedicated Regiments Tab.\n\n<b>ACTIVE CODES:</b>\n[MULTIPLAYERPART2]\n[NIGHTMAREMODE]\n[BUGFIX]", UDim2.new(1, -20, 1, -50), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 14)
		clText.Position = UDim2.new(0, 10, 0, 45)
		clText.TextXAlignment = Enum.TextXAlignment.Left
		clText.TextYAlignment = Enum.TextYAlignment.Top
		clText.RichText = true
		clText.TextWrapped = true

		local hRight = Instance.new("Frame", hSplit)
		hRight.Size = UDim2.new(0.65, -20, 1, 0)
		hRight.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
		local hrStroke = Instance.new("UIStroke", hRight)
		hrStroke.Color = Color3.fromRGB(70, 70, 80)
		hrStroke.Thickness = 2

		local lbHeader = UIHelpers.CreateLabel(hRight, "GLOBAL APEX LEADERBOARDS", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 20)
		lbHeader.Position = UDim2.new(0, 15, 0, 15)
		lbHeader.TextXAlignment = Enum.TextXAlignment.Left

		local LbNav = Instance.new("Frame", hRight)
		LbNav.Size = UDim2.new(1, -30, 0, 35)
		LbNav.Position = UDim2.new(0, 15, 0, 50)
		LbNav.BackgroundTransparency = 1
		local lnLayout = Instance.new("UIListLayout", LbNav)
		lnLayout.FillDirection = Enum.FillDirection.Horizontal
		lnLayout.Padding = UDim.new(0, 10)

		local LbScroll = Instance.new("ScrollingFrame", hRight)
		LbScroll.Size = UDim2.new(1, -30, 1, -110)
		LbScroll.Position = UDim2.new(0, 15, 0, 95)
		LbScroll.BackgroundTransparency = 1
		LbScroll.ScrollBarThickness = 6
		LbScroll.BorderSizePixel = 0
		local lsLayout = Instance.new("UIListLayout", LbScroll)
		lsLayout.Padding = UDim.new(0, 5)

		local lbTabs = {"PRESTIGE", "ELO RATING", "SQUAD CP"}
		local lbBtns = {}

		local function FetchLeaderboard(typeKey)
			for _, c in ipairs(LbScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

			for k, v in pairs(lbBtns) do
				v.Btn.TextColor3 = (k == typeKey) and UIHelpers.Colors.Gold or UIHelpers.Colors.TextMuted
				v.Stroke.Color = (k == typeKey) and UIHelpers.Colors.Gold or UIHelpers.Colors.BorderMuted
			end

			task.spawn(function()
				local data = {}
				if typeKey == "SQUAD CP" then
					data = Network:WaitForChild("GetSquadLeaderboard"):InvokeServer()
				else
					local rawKey = (typeKey == "ELO RATING") and "Elo" or "Prestige"
					data = Network:WaitForChild("GetLeaderboardData"):InvokeServer(rawKey)
				end

				if data then
					for i, entry in ipairs(data) do
						local card = Instance.new("Frame", LbScroll)
						card.Size = UDim2.new(1, -10, 0, 40)
						card.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
						local cStroke = Instance.new("UIStroke", card)
						cStroke.Color = UIHelpers.Colors.BorderMuted

						local cColor = (i==1) and UIHelpers.Colors.Gold or ((i==2) and Color3.fromRGB(200, 200, 200) or UIHelpers.Colors.TextWhite)

						local rLbl = UIHelpers.CreateLabel(card, "#" .. entry.Rank, UDim2.new(0, 40, 1, 0), Enum.Font.GothamBlack, cColor, 16)
						local nLbl = UIHelpers.CreateLabel(card, entry.Name, UDim2.new(0.6, 0, 1, 0), Enum.Font.GothamBold, cColor, 15)
						nLbl.Position = UDim2.new(0, 50, 0, 0); nLbl.TextXAlignment = Enum.TextXAlignment.Left

						local valText = (typeKey == "SQUAD CP") and (entry.CP .. " CP") or tostring(entry.Value)
						local vLbl = UIHelpers.CreateLabel(card, valText, UDim2.new(0.3, 0, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.TextMuted, 14)
						vLbl.Position = UDim2.new(1, -10, 0, 0); vLbl.AnchorPoint = Vector2.new(1, 0); vLbl.TextXAlignment = Enum.TextXAlignment.Right
					end
					LbScroll.CanvasSize = UDim2.new(0, 0, 0, lsLayout.AbsoluteContentSize.Y + 10)
				end
			end)
		end

		for _, tName in ipairs(lbTabs) do
			local btn = Instance.new("TextButton", LbNav)
			btn.Size = UDim2.new(0, 120, 1, 0)
			btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
			btn.Font = Enum.Font.GothamBold
			btn.Text = tName
			btn.TextSize = 12
			local strk = Instance.new("UIStroke", btn)
			lbBtns[tName] = {Btn = btn, Stroke = strk}

			btn.MouseButton1Click:Connect(function() FetchLeaderboard(tName) end)
		end

		FetchLeaderboard("PRESTIGE")
	end
	BuildHomeTab()


	-- PROFILE TAB ROUTING
	local profileTab = TabContainers["PROFILE"]
	local pSubNav = Instance.new("Frame", profileTab)
	pSubNav.Size = UDim2.new(1, 0, 0, 45)
	pSubNav.BackgroundTransparency = 1
	local pNavLayout = Instance.new("UIListLayout", pSubNav)
	pNavLayout.FillDirection = Enum.FillDirection.Horizontal
	pNavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	pNavLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	pNavLayout.Padding = UDim.new(0, 10)

	local pContent = Instance.new("Frame", profileTab)
	pContent.Size = UDim2.new(1, 0, 1, -45)
	pContent.Position = UDim2.new(0, 0, 0, 45)
	pContent.BackgroundTransparency = 1

	local subTabs = {
		{Name = "IDENTITY", Module = "ProfileTab"},
		{Name = "ATTRIBUTES", Module = "StatsTab"},
		{Name = "SKILLS", Module = "SkillsTab"}, 
		{Name = "PRESTIGE", Module = "PrestigeTab"},
		{Name = "INHERITANCE", Module = "InheritTab"},
		{Name = "BOUNTIES", Module = "BountiesTab"} 
	}

	local activeSubFrames = {}
	local subBtns = {}

	for i, tabData in ipairs(subTabs) do
		local btn = Instance.new("TextButton", pSubNav)
		btn.Size = UDim2.new(0, 115, 0, 30)
		btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
		btn.Font = Enum.Font.GothamBold
		btn.Text = tabData.Name
		btn.TextSize = 11
		btn.TextColor3 = UIHelpers.Colors.TextMuted
		local stroke = Instance.new("UIStroke", btn)
		stroke.Color = UIHelpers.Colors.BorderMuted
		stroke.Thickness = 2

		local subFrame = Instance.new("Frame", pContent)
		subFrame.Size = UDim2.new(1, 0, 1, 0)
		subFrame.BackgroundTransparency = 1
		subFrame.Visible = (i == 1)

		activeSubFrames[tabData.Name] = subFrame
		subBtns[tabData.Name] = {Btn = btn, Stroke = stroke}

		task.spawn(function()
			local mod = require(script.Parent:WaitForChild(tabData.Module))
			if mod.Init then mod.Init(subFrame, nil) 
			elseif mod.Initialize then mod.Initialize(subFrame, nil) end
		end)

		btn.MouseButton1Click:Connect(function()
			for name, frame in pairs(activeSubFrames) do frame.Visible = (name == tabData.Name) end
			for name, bData in pairs(subBtns) do
				bData.Btn.TextColor3 = (name == tabData.Name) and UIHelpers.Colors.Gold or UIHelpers.Colors.TextMuted
				bData.Stroke.Color = (name == tabData.Name) and UIHelpers.Colors.Gold or UIHelpers.Colors.BorderMuted
			end
		end)
	end

	subBtns["IDENTITY"].Btn.TextColor3 = UIHelpers.Colors.Gold
	subBtns["IDENTITY"].Stroke.Color = UIHelpers.Colors.Gold

	-- INJECT REMAINING TABS
	task.spawn(function()
		local ExpMod = require(script.Parent:WaitForChild("ExpeditionsTab"))
		if ExpMod.Initialize then ExpMod.Initialize(TabContainers["EXPEDITIONS"]) end
	end)

	task.spawn(function()
		local SquadsMod = require(script.Parent:WaitForChild("SquadsTab"))
		if SquadsMod.Initialize then SquadsMod.Initialize(TabContainers["SQUADS"]) end
	end)

	task.spawn(function()
		local SFMod = require(script.Parent:WaitForChild("SupplyForgeTab"))
		if SFMod.Initialize then SFMod.Initialize(TabContainers["SUPPLY_FORGE"]) end
	end)

	task.spawn(function()
		local RegMod = require(script.Parent:WaitForChild("RegimentsTab"))
		if RegMod.Initialize then RegMod.Initialize(TabContainers["REGIMENTS"]) end
	end)

	-- [[ ADMIN TAB INJECTION ]]
	if isAdmin then
		task.spawn(function()
			local AdminMod = require(script.Parent:WaitForChild("AdminTab"))
			if AdminMod.Initialize then AdminMod.Initialize(TabContainers["ADMIN"]) end
		end)
	end
end

local function OpenMasterTab(tabName, displayTitle)
	if CurrentOpenTab == tabName and MasterWindow.Visible then
		CurrentOpenTab = nil
		local t = TweenService:Create(WindowScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
		t:Play()
		t.Completed:Wait()
		MasterWindow.Visible = false
		return
	end

	for name, frame in pairs(TabContainers) do frame.Visible = (name == tabName) end
	CurrentOpenTab = tabName
	if WindowTitle then WindowTitle.Text = displayTitle end

	if not MasterWindow.Visible then
		MasterWindow.Visible = true
		TweenService:Create(WindowScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	end
end

local function BuildBottomBar()
	local Dock = Instance.new("Frame", MasterGui)
	Dock.AnchorPoint = Vector2.new(0.5, 1)
	Dock.Position = UDim2.new(0.5, 0, 1, -20)

	Dock.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	local dStroke = Instance.new("UIStroke", Dock)
	dStroke.Color = Color3.fromRGB(70, 70, 80)
	dStroke.Thickness = 2

	local layout = Instance.new("UIListLayout", Dock)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 20)

	local dockButtons = {
		{Id = "HOME", Title = "COMMAND CENTER", Icon = "rbxassetid://129528574378357"},
		{Id = "PROFILE", Title = "OPERATIVE PROFILE", Icon = "rbxassetid://106161709171988"}, 
		{Id = "EXPEDITIONS", Title = "COMBAT DEPLOYMENT", Icon = "rbxassetid://115407261158495"},  
		{Id = "SQUADS", Title = "STRIKE SQUADS COMMAND", Icon = "rbxassetid://111674249930782"}, 
		{Id = "SUPPLY_FORGE", Title = "MARKET & FORGERY", Icon = "rbxassetid://108619507999123"},
		{Id = "REGIMENTS", Title = "REGIMENT HEADQUARTERS", Icon = "rbxassetid://74069077964164"} 
	}

	-- Add Admin Button and expand Dock width dynamically
	if isAdmin then
		table.insert(dockButtons, {Id = "ADMIN", Title = "ADMIN DEBUG PANEL", Icon = "rbxassetid://100709766417970"})
		Dock.Size = UDim2.new(0, 540, 0, 70) 
	else
		Dock.Size = UDim2.new(0, 460, 0, 70) 
	end

	for _, btnData in ipairs(dockButtons) do
		local btn = UIHelpers.CreateIconButton(Dock, btnData.Icon, UDim2.new(0, 50, 0, 50))
		btn.MouseButton1Click:Connect(function() OpenMasterTab(btnData.Id, btnData.Title) end)

		if btnData.Id == "REGIMENTS" then
			local function UpdateRegimentIcon()
				local currentReg = player:GetAttribute("Regiment") or "Cadet Corps"
				local hasRegData, regDataModule = pcall(function() return require(game.ReplicatedStorage:WaitForChild("RegimentData")) end)
				local newIcon = "rbxassetid://74069077964164" 

				if hasRegData and regDataModule and regDataModule.Regiments[currentReg] then
					newIcon = regDataModule.Regiments[currentReg].Icon
				end

				if btn:IsA("ImageButton") or btn:IsA("ImageLabel") then
					btn.Image = newIcon
				else
					local imgChild = btn:FindFirstChildOfClass("ImageLabel")
					if imgChild then imgChild.Image = newIcon end
				end
			end

			player.AttributeChanged:Connect(function(attr)
				if attr == "Regiment" then UpdateRegimentIcon() end
			end)
			UpdateRegimentIcon()
		end
	end
end

function MainUI.Initialize(masterScreenGui)
	MasterGui = masterScreenGui
	BuildEnvironment()
	BuildMasterWindow()
	BuildBottomBar()

	task.spawn(function()
		local CombatMod = require(script.Parent:WaitForChild("CombatUI"))
		if CombatMod.Initialize then CombatMod.Initialize(MasterGui) end
	end)

	OpenMasterTab("HOME", "COMMAND CENTER")
end

return MainUI