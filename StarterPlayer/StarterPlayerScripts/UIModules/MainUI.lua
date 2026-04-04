-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: MainUI
local MainUI = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))

local MasterGui
local MasterWindow
local WindowScale
local WindowTitle
local TabContainers = {}
local CurrentOpenTab = nil

-- Global Currency Trackers
local lblElo, lblPrestige, lblDews, lblXP
local player = Players.LocalPlayer

local function BuildEnvironment(onComplete)
	local BGFrame = Instance.new("Frame", MasterGui)
	BGFrame.Name = "TexturedBackground"
	BGFrame.Size = UDim2.new(1, 0, 1, 0)
	BGFrame.BackgroundColor3 = UIHelpers.Colors.Background
	BGFrame.ZIndex = -10

	local Texture = Instance.new("ImageLabel", BGFrame)
	Texture.Size = UDim2.new(1, 0, 1, 0)
	Texture.BackgroundTransparency = 1
	Texture.Image = "rbxassetid://6078235439" 
	Texture.ImageTransparency = 0.90
	Texture.ScaleType = Enum.ScaleType.Tile
	Texture.TileSize = UDim2.new(0, 200, 0, 200)

	if onComplete then onComplete() end
end

local function BuildMasterWindow()
	MasterWindow = Instance.new("Frame", MasterGui)
	MasterWindow.Name = "MasterWindow"
	MasterWindow.Size = UDim2.new(0, 1200, 0, 680) 
	MasterWindow.Position = UDim2.new(0.5, 0, 0.45, 0)
	MasterWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	MasterWindow.Visible = false
	UIHelpers.ApplyGrimPanel(MasterWindow, false)

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

	WindowTitle = UIHelpers.CreateLabel(Header, "OPERATIVE PROFILE", UDim2.new(0, 350, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 24)
	WindowTitle.Position = UDim2.new(0, 25, 0, 0)
	WindowTitle.TextXAlignment = Enum.TextXAlignment.Left

	-- Stats anchored to the right
	local StatsContainer = Instance.new("Frame", Header)
	StatsContainer.Size = UDim2.new(0.65, 0, 1, 0)
	StatsContainer.Position = UDim2.new(1, -20, 0, 0)
	StatsContainer.AnchorPoint = Vector2.new(1, 0)
	StatsContainer.BackgroundTransparency = 1

	local statLayout = Instance.new("UIListLayout", StatsContainer)
	statLayout.FillDirection = Enum.FillDirection.Horizontal
	statLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	statLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	statLayout.Padding = UDim.new(0, 12)

	local function CreateTopBox(title, hexColor)
		local box = Instance.new("Frame", StatsContainer)
		box.Size = UDim2.new(0, 150, 0, 36)
		UIHelpers.ApplyGrimPanel(box, false)

		local tLbl = UIHelpers.CreateLabel(box, title, UDim2.new(0.5, -5, 1, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 11)
		tLbl.Position = UDim2.new(0, 10, 0, 0); tLbl.TextXAlignment = Enum.TextXAlignment.Left

		local vLbl = UIHelpers.CreateLabel(box, "0", UDim2.new(0.5, -10, 1, 0), Enum.Font.GothamBlack, Color3.fromHex(hexColor:gsub("#","")), 15)
		vLbl.Position = UDim2.new(0.5, 0, 0, 0); vLbl.TextXAlignment = Enum.TextXAlignment.Right
		return vLbl
	end

	lblXP = CreateTopBox("XP", "#55FF55")
	lblDews = CreateTopBox("DEWS", "#FF88FF")
	lblPrestige = CreateTopBox("PRESTIGE", "#FFD700")
	lblElo = CreateTopBox("ELO RATING", "#55AAFF")

	local function UpdateCurrencies()
		local ls = player:FindFirstChild("leaderstats")
		lblPrestige.Text = tostring((ls and ls:FindFirstChild("Prestige")) and ls.Prestige.Value or 0)
		lblElo.Text = tostring((ls and ls:FindFirstChild("Elo")) and ls.Elo.Value or 1000)
		lblDews.Text = tostring(player:GetAttribute("Dews") or 0)
		lblXP.Text = tostring(player:GetAttribute("XP") or 0)
	end
	player.AttributeChanged:Connect(function(a) if a == "Dews" or a == "XP" then UpdateCurrencies() end end)
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

	local tabs = {"PROFILE", "EXPEDITIONS", "SQUADS", "SUPPLY_FORGE"}
	for _, tabName in ipairs(tabs) do
		local tabFrame = Instance.new("Frame", ContentArea)
		tabFrame.Name = tabName
		tabFrame.Size = UDim2.new(1, 0, 1, 0)
		tabFrame.BackgroundTransparency = 1
		tabFrame.Visible = false
		TabContainers[tabName] = tabFrame
	end

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
		{Name = "INHERITANCE", Module = "InheritTab"}
	}

	local activeSubFrames = {}
	local subBtns = {}

	for i, tabData in ipairs(subTabs) do
		local btn, stroke = UIHelpers.CreateButton(pSubNav, tabData.Name, UDim2.new(0, 130, 0, 30), Enum.Font.GothamBold, 12)
		btn.TextColor3 = UIHelpers.Colors.TextMuted
		stroke.Color = UIHelpers.Colors.BorderMuted

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

	-- [[ FIXED: EXPEDITIONS TAB MODULE INJECTED PROPERLY ]]
	task.spawn(function()
		local ExpMod = require(script.Parent:WaitForChild("ExpeditionsTab"))
		if ExpMod.Initialize then
			ExpMod.Initialize(TabContainers["EXPEDITIONS"])
		end
	end)

	-- STRIKE SQUADS TAB
	local squadsTab = TabContainers["SQUADS"]
	UIHelpers.CreateLabel(squadsTab, "[ STRIKE SQUADS MANAGEMENT INJECTS HERE ]", UDim2.new(1, 0, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.TextMuted, 24)

	-- [[ SUPPLY & FORGE TAB INJECTION ]]
	local sfTab = TabContainers["SUPPLY_FORGE"]
	task.spawn(function()
		local SFMod = require(script.Parent:WaitForChild("SupplyForgeTab"))
		if SFMod.Initialize then
			SFMod.Initialize(sfTab)
		end
	end)
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
	Dock.Size = UDim2.new(0, 320, 0, 70) 
	Dock.AnchorPoint = Vector2.new(0.5, 1)
	Dock.Position = UDim2.new(0.5, 0, 1, -20)
	UIHelpers.ApplyGrimPanel(Dock, false)

	local layout = Instance.new("UIListLayout", Dock)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 20)

	local dockButtons = {
		{Id = "PROFILE", Title = "OPERATIVE PROFILE", Icon = "rbxassetid://6078235439"}, 
		{Id = "EXPEDITIONS", Title = "COMBAT DEPLOYMENT", Icon = "rbxassetid://6078235439"},  
		{Id = "SQUADS", Title = "STRIKE SQUADS", Icon = "rbxassetid://6078235439"}, 
		{Id = "SUPPLY_FORGE", Title = "MARKET & FORGERY", Icon = "rbxassetid://6078235439"}  
	}

	for _, btnData in ipairs(dockButtons) do
		local btn = UIHelpers.CreateIconButton(Dock, btnData.Icon, UDim2.new(0, 50, 0, 50))
		btn.MouseButton1Click:Connect(function() OpenMasterTab(btnData.Id, btnData.Title) end)
	end
end

function MainUI.Initialize(masterScreenGui)
	MasterGui = masterScreenGui
	BuildEnvironment()
	BuildMasterWindow()
	BuildBottomBar()
end

return MainUI