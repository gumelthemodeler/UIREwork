-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: PrestigeTab
local PrestigeTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))

local player = Players.LocalPlayer
local MainFrame
local PointsLabel
local DetailPanel, DTitle, DDesc, DCost, DReq, UnlockBtn, UBtnStroke
local StatCardContainer
local SelectedNodeId = nil
local NodeGuis = {}

local function CreateStatCard(parent, title, valueStr, themeColorHex)
	local card = Instance.new("Frame", parent)
	card.Size = UDim2.new(0, 160, 1, 0)
	UIHelpers.ApplyGrimPanel(card, false)

	local stroke = card:FindFirstChild("UIStroke")
	stroke.Color = Color3.fromHex(themeColorHex:gsub("#", ""))
	stroke.Transparency = 0.5

	local tLbl = UIHelpers.CreateLabel(card, string.upper(title), UDim2.new(1, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 12)
	tLbl.Position = UDim2.new(0, 0, 0, 5)

	local vLbl = UIHelpers.CreateLabel(card, valueStr, UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, Color3.fromHex(themeColorHex:gsub("#", "")), 22)
	vLbl.Position = UDim2.new(0, 0, 0, 25)

	return card
end

local function DrawConnectingLine(parent, p1, p2, color)
	local dist = (p2 - p1).Magnitude
	local center = (p1 + p2) / 2
	local angle = math.atan2(p2.Y - p1.Y, p2.X - p1.X)

	local line = Instance.new("Frame", parent)
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.new(0, center.X, 0, center.Y)
	line.Size = UDim2.new(0, dist, 0, 4) -- 4px thick lines to match reference
	line.Rotation = math.deg(angle)
	line.BackgroundColor3 = color
	line.BorderSizePixel = 0
	line.ZIndex = 1
	return line
end

function PrestigeTab.Init(parentFrame)
	MainFrame = Instance.new("Frame", parentFrame)
	MainFrame.Name = "PrestigeFrame"
	MainFrame.Size = UDim2.new(1, 0, 1, 0)
	MainFrame.BackgroundTransparency = 1
	MainFrame.Visible = true

	local Title = UIHelpers.CreateLabel(MainFrame, "PRESTIGE TALENTS", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 28)

	PointsLabel = UIHelpers.CreateLabel(MainFrame, "AVAILABLE POINTS: 0", UDim2.new(1, 0, 0, 25), Enum.Font.GothamBlack, Color3.fromRGB(150, 255, 150), 16)
	PointsLabel.Position = UDim2.new(0, 0, 0, 45)

	-- [[ CRITICAL FIX: ClipsDescendants = true stops the visual bleeding ]]
	local TreeScroll = Instance.new("ScrollingFrame", MainFrame)
	TreeScroll.Size = UDim2.new(1, 0, 1, -240)
	TreeScroll.Position = UDim2.new(0, 0, 0, 75)
	TreeScroll.BackgroundColor3 = Color3.fromRGB(10, 10, 14) -- Dark backdrop for the web
	TreeScroll.ScrollBarThickness = 8
	TreeScroll.BorderSizePixel = 2
	TreeScroll.BorderColor3 = UIHelpers.Colors.BorderMuted
	TreeScroll.ClipsDescendants = true 
	TreeScroll.ScrollingDirection = Enum.ScrollingDirection.XY 
	TreeScroll.CanvasSize = UDim2.new(0, 3000, 0, 3000)

	-- Grid overlay to make it look like a map
	local gridTexture = Instance.new("ImageLabel", TreeScroll)
	gridTexture.Size = UDim2.new(1, 0, 1, 0)
	gridTexture.BackgroundTransparency = 1
	gridTexture.Image = "rbxassetid://6078235439" 
	gridTexture.ImageTransparency = 0.95
	gridTexture.ScaleType = Enum.ScaleType.Tile
	gridTexture.TileSize = UDim2.new(0, 150, 0, 150)
	gridTexture.ZIndex = 0

	-- Center the view initially
	task.delay(0.1, function()
		TreeScroll.CanvasPosition = Vector2.new(1500 - (TreeScroll.AbsoluteSize.X / 2), 1500 - (TreeScroll.AbsoluteSize.Y / 2))
	end)

	-- [[ DETAIL PANEL ]]
	DetailPanel = Instance.new("Frame", MainFrame)
	DetailPanel.Size = UDim2.new(1, 0, 0, 150); DetailPanel.Position = UDim2.new(0, 0, 1, -155); DetailPanel.Visible = false
	UIHelpers.ApplyGrimPanel(DetailPanel, false)

	DTitle = UIHelpers.CreateLabel(DetailPanel, "", UDim2.new(1, -20, 0, 35), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 24); DTitle.Position = UDim2.new(0, 20, 0, 10); DTitle.TextXAlignment = Enum.TextXAlignment.Left

	DDesc = UIHelpers.CreateLabel(DetailPanel, "", UDim2.new(0.5, 0, 0, 60), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 14); DDesc.Position = UDim2.new(0, 20, 0, 45); DDesc.TextWrapped = true; DDesc.TextXAlignment = Enum.TextXAlignment.Left; DDesc.TextYAlignment = Enum.TextYAlignment.Top

	StatCardContainer = Instance.new("Frame", DetailPanel)
	StatCardContainer.Size = UDim2.new(0.4, 0, 0, 60); StatCardContainer.Position = UDim2.new(0.55, 0, 0, 35); StatCardContainer.BackgroundTransparency = 1
	local scLayout = Instance.new("UIListLayout", StatCardContainer); scLayout.FillDirection = Enum.FillDirection.Horizontal; scLayout.Padding = UDim.new(0, 15)

	DCost = UIHelpers.CreateLabel(DetailPanel, "", UDim2.new(0.3, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 18); DCost.Position = UDim2.new(0.68, 0, 1, -45); DCost.TextXAlignment = Enum.TextXAlignment.Right

	DReq = UIHelpers.CreateLabel(DetailPanel, "", UDim2.new(0.5, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.Border, 14); DReq.Position = UDim2.new(0, 20, 1, -35); DReq.TextXAlignment = Enum.TextXAlignment.Left

	UnlockBtn, UBtnStroke = UIHelpers.CreateButton(DetailPanel, "UNLOCK", UDim2.new(0.25, 0, 0, 45), Enum.Font.GothamBlack, 16)
	UnlockBtn.Position = UDim2.new(0.98, 0, 1, -55); UnlockBtn.AnchorPoint = Vector2.new(1, 0)

	UnlockBtn.MouseButton1Click:Connect(function()
		if SelectedNodeId then Network.UnlockPrestigeNode:FireServer(SelectedNodeId) end
	end)

	local drawnLines = {}
	for id, node in pairs(GameData.PrestigeNodes) do
		local nodeAbsPos = Vector2.new(node.Pos.X.Scale * 3000, node.Pos.Y.Scale * 3000)

		if node.Req and GameData.PrestigeNodes[node.Req] then
			local reqNode = GameData.PrestigeNodes[node.Req]
			local reqAbsPos = Vector2.new(reqNode.Pos.X.Scale * 3000, reqNode.Pos.Y.Scale * 3000)

			local line = DrawConnectingLine(TreeScroll, nodeAbsPos, reqAbsPos, UIHelpers.Colors.BorderMuted)
			drawnLines[id] = line
		end

		local btn = Instance.new("TextButton", TreeScroll)
		btn.Size = UDim2.new(0, 44, 0, 44)
		btn.Position = UDim2.new(0, nodeAbsPos.X, 0, nodeAbsPos.Y)
		btn.AnchorPoint = Vector2.new(0.5, 0.5)
		btn.Text = ""
		btn.ZIndex = 3
		btn.BackgroundColor3 = UIHelpers.Colors.Background
		btn.BorderSizePixel = 2
		btn.BorderColor3 = UIHelpers.Colors.BorderMuted
		btn.Rotation = 45 

		local iconLbl = UIHelpers.CreateLabel(btn, "", UDim2.new(1, 0, 1, 0), Enum.Font.GothamBlack, UIHelpers.Colors.TextMuted, 18)
		iconLbl.ZIndex = 6
		iconLbl.Rotation = -45 
		local num = id:match("%d+")
		if num then iconLbl.Text = num else iconLbl.Text = "★" end

		btn.MouseButton1Click:Connect(function()
			SelectedNodeId = id
			DetailPanel.Visible = true; DTitle.Text = node.Name; DTitle.TextColor3 = Color3.fromHex(node.Color:gsub("#", ""))
			DDesc.Text = node.Desc; DCost.Text = node.Cost .. " PTS"

			for _, c in ipairs(StatCardContainer:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

			if node.BuffType == "FlatStat" then
				local cleanStatName = node.BuffStat:gsub("_Val", ""):gsub("_", " ")
				CreateStatCard(StatCardContainer, cleanStatName, "+" .. node.BuffValue, node.Color)
			elseif node.BuffType == "Special" then
				if node.BuffStat == "DodgeBonus" then CreateStatCard(StatCardContainer, "Dodge Chance", "+" .. node.BuffValue .. "%", node.Color)
				elseif node.BuffStat == "DmgMult" then CreateStatCard(StatCardContainer, "Total DMG", "+" .. (node.BuffValue*100) .. "%", node.Color)
				elseif node.BuffStat == "CritBonus" then CreateStatCard(StatCardContainer, "Crit Chance", "+" .. node.BuffValue .. "%", node.Color)
				elseif node.BuffStat == "IgnoreArmor" then CreateStatCard(StatCardContainer, "Armor Pen", "+" .. (node.BuffValue*100) .. "%", node.Color)
				else CreateStatCard(StatCardContainer, "Passive", "UNLOCKED", node.Color) end
			end

			local isOwned = player:GetAttribute("PrestigeNode_" .. id)
			local hasReq = node.Req == nil or player:GetAttribute("PrestigeNode_" .. node.Req)

			if isOwned then 
				DReq.Text = "OWNED"; DReq.TextColor3 = Color3.fromRGB(100, 255, 100); UnlockBtn.Text = "OWNED"
				UnlockBtn.TextColor3 = Color3.fromRGB(150, 150, 150); UBtnStroke.Color = UIHelpers.Colors.BorderMuted; UnlockBtn.Active = false
			elseif not hasReq then 
				DReq.Text = "REQUIRES: " .. GameData.PrestigeNodes[node.Req].Name; DReq.TextColor3 = UIHelpers.Colors.Border; UnlockBtn.Text = "LOCKED"
				UnlockBtn.TextColor3 = UIHelpers.Colors.Border; UBtnStroke.Color = UIHelpers.Colors.Border; UnlockBtn.Active = false
			else 
				DReq.Text = "AVAILABLE TO UNLOCK"; DReq.TextColor3 = UIHelpers.Colors.TextWhite; UnlockBtn.Text = "UNLOCK"
				UnlockBtn.TextColor3 = Color3.fromHex(node.Color:gsub("#", "")); UBtnStroke.Color = Color3.fromHex(node.Color:gsub("#", "")); UnlockBtn.Active = true 
			end
		end)

		NodeGuis[id] = { Btn = btn, Icon = iconLbl, Line = drawnLines[id], BaseColor = Color3.fromHex(node.Color:gsub("#", "")) }
	end

	local function UpdateUI()
		local pts = player:GetAttribute("PrestigePoints") or 0
		PointsLabel.Text = "AVAILABLE POINTS: " .. pts

		for id, gui in pairs(NodeGuis) do
			local isOwned = player:GetAttribute("PrestigeNode_" .. id)
			local node = GameData.PrestigeNodes[id]
			local hasReq = node.Req == nil or player:GetAttribute("PrestigeNode_" .. node.Req)

			if isOwned then
				gui.Btn.BorderColor3 = gui.BaseColor
				gui.Icon.TextColor3 = gui.BaseColor
				if gui.Line then gui.Line.BackgroundColor3 = gui.BaseColor; gui.Line.ZIndex = 2 end
			elseif hasReq then
				gui.Btn.BorderColor3 = UIHelpers.Colors.TextWhite
				gui.Icon.TextColor3 = UIHelpers.Colors.TextWhite
				if gui.Line then gui.Line.BackgroundColor3 = UIHelpers.Colors.BorderMuted; gui.Line.ZIndex = 1 end
			else
				gui.Btn.BorderColor3 = UIHelpers.Colors.BorderMuted
				gui.Icon.TextColor3 = UIHelpers.Colors.BorderMuted
				if gui.Line then gui.Line.BackgroundColor3 = UIHelpers.Colors.BorderMuted; gui.Line.ZIndex = 1 end
			end
		end

		if SelectedNodeId then
			local node = GameData.PrestigeNodes[SelectedNodeId]
			local isOwned = player:GetAttribute("PrestigeNode_" .. SelectedNodeId)
			local hasReq = node.Req == nil or player:GetAttribute("PrestigeNode_" .. node.Req)

			if isOwned then 
				DReq.Text = "OWNED"; DReq.TextColor3 = Color3.fromRGB(100, 255, 100); UnlockBtn.Text = "OWNED"
				UnlockBtn.TextColor3 = Color3.fromRGB(150, 150, 150); UBtnStroke.Color = UIHelpers.Colors.BorderMuted; UnlockBtn.Active = false
			elseif not hasReq then 
				DReq.Text = "REQUIRES: " .. GameData.PrestigeNodes[node.Req].Name; DReq.TextColor3 = UIHelpers.Colors.Border; UnlockBtn.Text = "LOCKED"
				UnlockBtn.TextColor3 = UIHelpers.Colors.Border; UBtnStroke.Color = UIHelpers.Colors.Border; UnlockBtn.Active = false
			else 
				DReq.Text = "AVAILABLE TO UNLOCK"; DReq.TextColor3 = UIHelpers.Colors.TextWhite; UnlockBtn.Text = "UNLOCK"
				UnlockBtn.TextColor3 = Color3.fromHex(node.Color:gsub("#", "")); UBtnStroke.Color = Color3.fromHex(node.Color:gsub("#", "")); UnlockBtn.Active = true 
			end
		end
	end

	player.AttributeChanged:Connect(function(attr) if string.find(attr, "Prestige") then UpdateUI() end end)
	UpdateUI()
end

return PrestigeTab