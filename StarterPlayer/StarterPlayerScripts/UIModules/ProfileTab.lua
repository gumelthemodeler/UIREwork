-- @ScriptType: ModuleScript
-- Name: ProfileTab
local ProfileTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")

local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local CosmeticData = require(ReplicatedStorage:WaitForChild("CosmeticData"))

local notifModule = script.Parent:WaitForChild("NotificationManager", 2)
local NotificationManager = notifModule and require(notifModule) or nil
local auraModule = script.Parent:WaitForChild("UIAuraManager", 2)
local UIAuraManager = auraModule and require(auraModule) or nil
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers")) -- [[ THE FIX: Added UIHelpers ]]

local player = Players.LocalPlayer
local MainFrame, ColumnsWrapper, ContentArea, TabsWrapper

local SubTabs = {}
local SubBtns = {}

local InvGrid
local wpnLabel, accLabel, titanLabel, clanLabel, regimentLabel
local RadarContainer, regIcon, AvatarBox, AvatarAuraGlow, AvatarTitle
local toggleStatsBtn
local InvTitle 

local isShowingTitanStats = false
local MAX_INVENTORY_CAPACITY = 50
local SkillSlotLabels = {}
local currentInvFilter = "All"
local FilterBtns = {}

local RarityColors = { ["Common"] = "#AAAAAA", ["Uncommon"] = "#55FF55", ["Rare"] = "#5588FF", ["Epic"] = "#CC44FF", ["Legendary"] = "#FFD700", ["Mythical"] = "#FF3333", ["Transcendent"] = "#FF55FF" }
local RarityOrder = { Transcendent = 0, Mythical = 1, Legendary = 2, Epic = 3, Rare = 4, Uncommon = 5, Common = 6 }
local TEXT_COLORS = { PrestigeYellow = "#FFD700", EloBlue = "#55AAFF", DefaultGreen = "#55FF55", DewsPink = "#FF88FF" }
local REG_COLORS = { ["Garrison"] = "#FF5555", ["Military Police"] = "#55FF55", ["Scout Regiment"] = "#55AAFF" }

local UnlockedCosmeticsCache = { Titles = {}, Auras = {} }
local CosmeticUIUpdaters = {}

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

local function CreateSharpLabel(parent, text, size, font, color, textSize)
	local lbl = Instance.new("TextLabel", parent)
	lbl.Size = size
	lbl.BackgroundTransparency = 1
	lbl.Font = font
	lbl.TextColor3 = color
	lbl.TextSize = textSize
	lbl.Text = text
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	return lbl
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

	btn.MouseEnter:Connect(function() stroke.Color = Color3.fromRGB(225, 185, 60); btn.TextColor3 = Color3.fromRGB(225, 185, 60) end)
	btn.MouseLeave:Connect(function() stroke.Color = Color3.fromRGB(70, 70, 80); btn.TextColor3 = Color3.fromRGB(245, 245, 245) end)
	return btn, stroke
end

task.spawn(function()
	player:WaitForChild("leaderstats", 10)
	if type(CosmeticData.CheckUnlock) == "function" then
		for key, data in pairs(CosmeticData.Titles or {}) do UnlockedCosmeticsCache.Titles[key] = CosmeticData.CheckUnlock(player, data.ReqType, data.ReqValue) end
		for key, data in pairs(CosmeticData.Auras or {}) do UnlockedCosmeticsCache.Auras[key] = CosmeticData.CheckUnlock(player, data.ReqType, data.ReqValue) end
	end
end)

local function EvaluateCosmetics()
	if type(CosmeticData.CheckUnlock) ~= "function" then return end
	for key, data in pairs(CosmeticData.Titles or {}) do
		if not UnlockedCosmeticsCache.Titles[key] and CosmeticData.CheckUnlock(player, data.ReqType, data.ReqValue) then
			UnlockedCosmeticsCache.Titles[key] = true
			if NotificationManager and type(NotificationManager.Show) == "function" then NotificationManager.Show("New Title Unlocked: " .. data.Name, "Success") end
		end
	end
	for key, data in pairs(CosmeticData.Auras or {}) do
		if not UnlockedCosmeticsCache.Auras[key] and CosmeticData.CheckUnlock(player, data.ReqType, data.ReqValue) then
			UnlockedCosmeticsCache.Auras[key] = true
			if NotificationManager and type(NotificationManager.Show) == "function" then NotificationManager.Show("New Aura Unlocked: " .. data.Name, "Success") end
		end
	end
	for _, updater in ipairs(CosmeticUIUpdaters) do if type(updater) == "function" then updater() end end
end

local function DrawLineScale(parent, p1x, p1y, p2x, p2y, color, thickness, zindex)
	local dx = p2x - p1x; local dy = p2y - p1y; local dist = math.sqrt(dx*dx + dy*dy)
	local frame = Instance.new("Frame", parent)
	frame.Size = UDim2.new(0, dist, 0, thickness); frame.Position = UDim2.new(0, (p1x + p2x)/2, 0, (p1y + p2y)/2)
	frame.AnchorPoint = Vector2.new(0.5, 0.5); frame.Rotation = math.deg(math.atan2(dy, dx))
	frame.BackgroundColor3 = color; frame.BorderSizePixel = 0; frame.ZIndex = zindex or 1
	return frame
end

local function DrawUITriangle(parent, p1, p2, p3, color, transp, zIndex)
	local edges = { {p1, p2}, {p2, p3}, {p3, p1} }
	table.sort(edges, function(a, b) return (a[1]-a[2]).Magnitude > (b[1]-b[2]).Magnitude end)
	local a, b = edges[1][1], edges[1][2]; local c = edges[2][1] == a and edges[2][2] or edges[2][1]
	if c == b then c = edges[3][1] == a and edges[3][2] or edges[3][1] end
	local ab = b - a; local ac = c - a; local dir = ab.Unit; local projLen = ac:Dot(dir); local proj = dir * projLen; local h = (ac - proj).Magnitude
	local w1 = projLen; local w2 = ab.Magnitude - projLen
	local t1 = Instance.new("ImageLabel")
	t1.BackgroundTransparency = 1; t1.Image = "rbxassetid://319692171"; t1.ImageColor3 = color; t1.ImageTransparency = transp; t1.ZIndex = zIndex; t1.BorderSizePixel = 0; t1.AnchorPoint = Vector2.new(0.5, 0.5)
	local t2 = t1:Clone(); t1.Size = UDim2.new(0, w1, 0, h); t2.Size = UDim2.new(0, w2, 0, h)
	t1.Position = UDim2.new(0, a.X + proj.X/2, 0, a.Y + proj.Y/2); t2.Position = UDim2.new(0, b.X + (proj.X - ab.X)/2, 0, b.Y + (proj.Y - ab.Y)/2)
	t1.Rotation = math.deg(math.atan2(dir.Y, dir.X)); t2.Rotation = math.deg(math.atan2(-dir.Y, -dir.X))
	t1.Parent = parent; t2.Parent = parent
end

function ProfileTab.Initialize(parentFrame, tooltipMgr)
	local cachedTooltipMgr = tooltipMgr

	MainFrame = Instance.new("Frame", parentFrame)
	MainFrame.Name = "ProfileFrame"
	MainFrame.Size = UDim2.new(1, 0, 1, 0)
	MainFrame.BackgroundTransparency = 1
	MainFrame.Visible = true 

	local mLayout = Instance.new("UIListLayout", MainFrame)
	mLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mLayout.Padding = UDim.new(0, 15)
	mLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	mLayout.FillDirection = Enum.FillDirection.Vertical 
	local mPad = Instance.new("UIPadding", MainFrame); mPad.PaddingTop = UDim.new(0, 10); mPad.PaddingBottom = UDim.new(0, 10)

	ColumnsWrapper = Instance.new("Frame", MainFrame)
	ColumnsWrapper.Size = UDim2.new(1, 0, 1, 0)
	ColumnsWrapper.BackgroundTransparency = 1
	ColumnsWrapper.LayoutOrder = 1
	local cwLayout = Instance.new("UIListLayout", ColumnsWrapper); cwLayout.FillDirection = Enum.FillDirection.Horizontal; cwLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; cwLayout.Padding = UDim.new(0, 15)

	local ShowcaseCard = CreateGrimPanel(ColumnsWrapper)
	ShowcaseCard.Size = UDim2.new(0.31, 0, 1, 0); ShowcaseCard.LayoutOrder = 1
	local scLayout = Instance.new("UIListLayout", ShowcaseCard); scLayout.SortOrder = Enum.SortOrder.LayoutOrder; scLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; scLayout.Padding = UDim.new(0, 10)
	local scPad = Instance.new("UIPadding", ShowcaseCard); scPad.PaddingTop = UDim.new(0, 20); scPad.PaddingBottom = UDim.new(0, 20)

	AvatarTitle = CreateSharpLabel(ShowcaseCard, "HUMANITY'S VANGUARD", UDim2.new(1, 0, 0, 25), Enum.Font.GothamBlack, Color3.fromRGB(225, 185, 60), 16); AvatarTitle.LayoutOrder = 1

	local AvatarContainer = Instance.new("Frame", ShowcaseCard)
	AvatarContainer.Size = UDim2.new(0.45, 0, 0.45, 0); AvatarContainer.BackgroundTransparency = 1; AvatarContainer.LayoutOrder = 2
	Instance.new("UIAspectRatioConstraint", AvatarContainer).AspectRatio = 1.0

	AvatarAuraGlow = Instance.new("Frame", AvatarContainer)
	AvatarAuraGlow.Size = UDim2.new(1, 0, 1, 0); AvatarAuraGlow.Position = UDim2.new(0.5, 0, 0.5, 0); AvatarAuraGlow.AnchorPoint = Vector2.new(0.5, 0.5); AvatarAuraGlow.BackgroundTransparency = 1
	local glowCorner = Instance.new("UICorner", AvatarAuraGlow); glowCorner.CornerRadius = UDim.new(1, 0)

	AvatarBox = Instance.new("ImageLabel", AvatarContainer)
	AvatarBox.Size = UDim2.new(1, 0, 1, 0); AvatarBox.Position = UDim2.new(0.5, 0, 0.5, 0); AvatarBox.AnchorPoint = Vector2.new(0.5, 0.5)
	AvatarBox.BackgroundColor3 = Color3.fromRGB(28, 28, 34); AvatarBox.Image = "rbxthumb://type=AvatarBust&id="..player.UserId.."&w=420&h=420"
	AvatarBox.BorderSizePixel = 0; AvatarBox.ZIndex = 5
	local boxCorner = Instance.new("UICorner", AvatarBox); boxCorner.CornerRadius = UDim.new(1, 0)
	local boxStroke = Instance.new("UIStroke", AvatarBox); boxStroke.Color = Color3.fromRGB(70, 70, 80); boxStroke.Thickness = 2

	local PlayerNameLbl = CreateSharpLabel(ShowcaseCard, string.upper(player.Name), UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, Color3.fromRGB(245, 245, 245), 20); PlayerNameLbl.LayoutOrder = 3
	regIcon = Instance.new("ImageLabel", ShowcaseCard); regIcon.Size = UDim2.new(0, 100, 0, 100); regIcon.BackgroundTransparency = 1; regIcon.ZIndex = 6; regIcon.LayoutOrder = 4

	local MidCol = CreateGrimPanel(ColumnsWrapper)
	MidCol.Size = UDim2.new(0.31, 0, 1, 0); MidCol.LayoutOrder = 2
	local midLayout = Instance.new("UIListLayout", MidCol); midLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; midLayout.SortOrder = Enum.SortOrder.LayoutOrder; midLayout.Padding = UDim.new(0, 10)
	local midPad = Instance.new("UIPadding", MidCol); midPad.PaddingTop = UDim.new(0, 15); midPad.PaddingBottom = UDim.new(0, 15)

	local RadarBG = CreateGrimPanel(MidCol); RadarBG.Size = UDim2.new(0.95, 0, 0, 180); RadarBG.LayoutOrder = 1
	RadarContainer = Instance.new("Frame", RadarBG); RadarContainer.Size = UDim2.new(1, 0, 1, 0); RadarContainer.Position = UDim2.new(0.5, 0, 0.5, 0); RadarContainer.AnchorPoint = Vector2.new(0.5, 0.5); RadarContainer.BackgroundTransparency = 1
	Instance.new("UIAspectRatioConstraint", RadarContainer).AspectRatio = 1

	local StatsRect = CreateGrimPanel(MidCol); StatsRect.Size = UDim2.new(0.95, 0, 0, 0); StatsRect.AutomaticSize = Enum.AutomaticSize.Y; StatsRect.LayoutOrder = 2
	local srLayout = Instance.new("UIListLayout", StatsRect); srLayout.Padding = UDim.new(0, 6)
	local statPad = Instance.new("UIPadding", StatsRect); statPad.PaddingTop = UDim.new(0, 12); statPad.PaddingBottom = UDim.new(0, 12); statPad.PaddingLeft = UDim.new(0, 15)

	local function CreateInfoLabel(parent)
		local l = CreateSharpLabel(parent, "", UDim2.new(1, -15, 0, 24), Enum.Font.GothamBold, Color3.fromRGB(245, 245, 245), 12)
		l.TextXAlignment = Enum.TextXAlignment.Left; l.TextWrapped = true
		return l
	end

	titanLabel = CreateInfoLabel(StatsRect); titanLabel.RichText = true
	clanLabel = CreateInfoLabel(StatsRect); clanLabel.RichText = true
	regimentLabel = CreateInfoLabel(StatsRect); regimentLabel.RichText = true
	wpnLabel = CreateInfoLabel(StatsRect); wpnLabel.RichText = true
	accLabel = CreateInfoLabel(StatsRect); accLabel.RichText = true

	local LoadoutHeader = CreateSharpLabel(MidCol, "ACTIVE LOADOUT", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBlack, Color3.fromRGB(225, 185, 60), 14); LoadoutHeader.LayoutOrder = 3
	local LoadoutGrid = Instance.new("Frame", MidCol); LoadoutGrid.Size = UDim2.new(0.95, 0, 0, 65); LoadoutGrid.BackgroundTransparency = 1; LoadoutGrid.LayoutOrder = 4
	local lgLayout = Instance.new("UIGridLayout", LoadoutGrid); lgLayout.CellSize = UDim2.new(0, 65, 0, 65); lgLayout.CellPadding = UDim2.new(0, 8, 0, 0); lgLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; lgLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	for i = 1, 4 do
		local slotFrame = CreateGrimPanel(LoadoutGrid); slotFrame.ClipsDescendants = true
		local numLbl = CreateSharpLabel(slotFrame, tostring(i), UDim2.new(0, 15, 0, 15), Enum.Font.GothamBlack, Color3.fromRGB(160, 160, 175), 10); numLbl.Position = UDim2.new(0, 4, 0, 4); numLbl.TextXAlignment = Enum.TextXAlignment.Left
		local nameLbl = CreateSharpLabel(slotFrame, "EMPTY", UDim2.new(1, -6, 1, -16), Enum.Font.GothamBold, Color3.fromRGB(245, 245, 245), 14); nameLbl.Position = UDim2.new(0.5, 0, 0.5, 6); nameLbl.AnchorPoint = Vector2.new(0.5, 0.5); nameLbl.TextWrapped = true; nameLbl.TextScaled = false; nameLbl.TextXAlignment = Enum.TextXAlignment.Center; nameLbl.TextYAlignment = Enum.TextYAlignment.Center
		table.insert(SkillSlotLabels, nameLbl)
	end

	local ActionRow = Instance.new("Frame", MidCol); ActionRow.Size = UDim2.new(0.95, 0, 0, 40); ActionRow.BackgroundTransparency = 1; ActionRow.LayoutOrder = 5
	toggleStatsBtn, _ = CreateSharpButton(ActionRow, "VIEW TITAN STATS", UDim2.new(1, 0, 1, 0), Enum.Font.GothamBlack, 12)

	TabsWrapper = Instance.new("Frame", ColumnsWrapper)
	TabsWrapper.Size = UDim2.new(0.32, 0, 1, 0); TabsWrapper.BackgroundTransparency = 1; TabsWrapper.LayoutOrder = 3
	local twLayout = Instance.new("UIListLayout", TabsWrapper); twLayout.SortOrder = Enum.SortOrder.LayoutOrder; twLayout.Padding = UDim.new(0, 10)

	local TopNav = CreateGrimPanel(TabsWrapper)
	TopNav.Size = UDim2.new(1, 0, 0, 35); TopNav.LayoutOrder = 1

	local NavScroll = Instance.new("ScrollingFrame", TopNav)
	NavScroll.Size = UDim2.new(1, 0, 1, 0); NavScroll.BackgroundTransparency = 1; NavScroll.ScrollBarThickness = 0; NavScroll.ScrollingDirection = Enum.ScrollingDirection.X
	local navLayout = Instance.new("UIListLayout", NavScroll); navLayout.FillDirection = Enum.FillDirection.Horizontal; navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; navLayout.VerticalAlignment = Enum.VerticalAlignment.Center; navLayout.Padding = UDim.new(0, 8)
	local navPad = Instance.new("UIPadding", NavScroll); navPad.PaddingLeft = UDim.new(0, 10); navPad.PaddingRight = UDim.new(0, 10)
	navLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() NavScroll.CanvasSize = UDim2.new(0, navLayout.AbsoluteContentSize.X + 20, 0, 0) end)

	ContentArea = Instance.new("Frame", TabsWrapper)
	ContentArea.Size = UDim2.new(1, 0, 1, -45); ContentArea.BackgroundTransparency = 1; ContentArea.LayoutOrder = 2

	local function CreateSubNavBtn(name, text)
		local btn, subStroke = CreateSharpButton(NavScroll, text, UDim2.new(0, 95, 0, 24), Enum.Font.GothamBold, 10)
		btn.TextColor3 = Color3.fromRGB(160, 160, 175); subStroke.Color = Color3.fromRGB(70, 70, 80)
		btn.MouseButton1Click:Connect(function()
			for k, v in pairs(SubBtns) do v.TextColor3 = Color3.fromRGB(160, 160, 175); v:FindFirstChild("UIStroke").Color = Color3.fromRGB(70, 70, 80) end
			btn.TextColor3 = Color3.fromRGB(245, 245, 245); subStroke.Color = Color3.fromRGB(225, 185, 60)
			for k, frame in pairs(SubTabs) do frame.Visible = (k == name) end
		end)
		SubBtns[name] = btn; return btn
	end

	CreateSubNavBtn("Inventory", "INVENTORY")
	CreateSubNavBtn("Titles", "TITLES")
	CreateSubNavBtn("Auras", "AURAS")

	SubBtns["Inventory"].TextColor3 = Color3.fromRGB(245, 245, 245)
	SubBtns["Inventory"]:FindFirstChild("UIStroke").Color = Color3.fromRGB(225, 185, 60)

	-- [[ 3A. INVENTORY TAB ]]
	SubTabs["Inventory"] = CreateGrimPanel(ContentArea); SubTabs["Inventory"].Size = UDim2.new(1, 0, 1, 0); SubTabs["Inventory"].Visible = true
	InvTitle = CreateSharpLabel(SubTabs["Inventory"], "INVENTORY (0/50)", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, Color3.fromRGB(225, 185, 60), 14)

	local FilterFrame = Instance.new("Frame", SubTabs["Inventory"])
	FilterFrame.Size = UDim2.new(1, -20, 0, 30); FilterFrame.Position = UDim2.new(0, 10, 0, 30); FilterFrame.BackgroundTransparency = 1
	local ffLayout = Instance.new("UIListLayout", FilterFrame); ffLayout.FillDirection = Enum.FillDirection.Horizontal; ffLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left; ffLayout.Padding = UDim.new(0, 8)

	local RefreshProfile 
	local function MakeFilterBtn(id, text)
		local btn, stroke = CreateSharpButton(FilterFrame, text, UDim2.new(0, 50, 1, 0), Enum.Font.GothamBlack, 10)
		btn.TextColor3 = Color3.fromRGB(160, 160, 175)
		btn.MouseButton1Click:Connect(function()
			currentInvFilter = id
			for k, v in pairs(FilterBtns) do v.TextColor3 = Color3.fromRGB(160, 160, 175); v:FindFirstChild("UIStroke").Color = Color3.fromRGB(70, 70, 80) end
			btn.TextColor3 = Color3.fromRGB(245, 245, 245); stroke.Color = Color3.fromRGB(225, 185, 60)
			if RefreshProfile then RefreshProfile() end
		end)
		FilterBtns[id] = btn; return btn
	end
	MakeFilterBtn("All", "ALL"); MakeFilterBtn("Gear", "GEAR"); MakeFilterBtn("Items", "ITEMS")
	FilterBtns["All"].TextColor3 = Color3.fromRGB(245, 245, 245); FilterBtns["All"]:FindFirstChild("UIStroke").Color = Color3.fromRGB(225, 185, 60)

	-- [[ AUTO SELL CONFIG PANEL ]]
	local AutoSellBtn, asStroke = CreateSharpButton(FilterFrame, "AUTO-SELL", UDim2.new(0, 75, 1, 0), Enum.Font.GothamBlack, 10)
	AutoSellBtn.TextColor3 = UIHelpers.Colors.TextMuted

	local AutoSellMenu = Instance.new("Frame", SubTabs["Inventory"])
	AutoSellMenu.Size = UDim2.new(1, -20, 0, 160)
	AutoSellMenu.Position = UDim2.new(0, 10, 0, 65)
	AutoSellMenu.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	AutoSellMenu.Visible = false
	AutoSellMenu.ZIndex = 20
	Instance.new("UIStroke", AutoSellMenu).Color = UIHelpers.Colors.Gold

	local asTitle = UIHelpers.CreateLabel(AutoSellMenu, "AUTO-SELL SETTINGS", UDim2.new(1, 0, 0, 25), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 12)
	local asList = Instance.new("Frame", AutoSellMenu)
	asList.Size = UDim2.new(1, 0, 1, -30); asList.Position = UDim2.new(0, 0, 0, 25); asList.BackgroundTransparency = 1
	local asLayout = Instance.new("UIListLayout", asList); asLayout.Padding = UDim.new(0, 4); asLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local function CreateASRow(rarityName, hexColor)
		local row = Instance.new("Frame", asList); row.Size = UDim2.new(0.9, 0, 0, 25); row.BackgroundTransparency = 1
		local lbl = UIHelpers.CreateLabel(row, rarityName:upper(), UDim2.new(0.6, 0, 1, 0), Enum.Font.GothamBold, Color3.fromHex(hexColor:gsub("#","")), 12); lbl.TextXAlignment = Enum.TextXAlignment.Left

		local tBtn, tStrk = CreateSharpButton(row, "OFF", UDim2.new(0.35, 0, 1, 0), Enum.Font.GothamBlack, 10)
		tBtn.Position = UDim2.new(1, 0, 0, 0); tBtn.AnchorPoint = Vector2.new(1, 0)

		local function updateBtn()
			if player:GetAttribute("AutoSell_" .. rarityName) then
				tBtn.Text = "ON"; tBtn.TextColor3 = Color3.fromRGB(100, 255, 100); tStrk.Color = Color3.fromRGB(100, 255, 100)
			else
				tBtn.Text = "OFF"; tBtn.TextColor3 = UIHelpers.Colors.TextMuted; tStrk.Color = Color3.fromRGB(70, 70, 80)
			end
		end
		updateBtn()
		tBtn.MouseButton1Click:Connect(function() Network:WaitForChild("AutoSell"):FireServer(rarityName) end)
		player.AttributeChanged:Connect(function(attr) if attr == "AutoSell_" .. rarityName then updateBtn() end end)
	end

	CreateASRow("Common", RarityColors["Common"])
	CreateASRow("Uncommon", RarityColors["Uncommon"])
	CreateASRow("Rare", RarityColors["Rare"])
	CreateASRow("Epic", RarityColors["Epic"])

	AutoSellBtn.MouseButton1Click:Connect(function() AutoSellMenu.Visible = not AutoSellMenu.Visible end)


	InvGrid = Instance.new("ScrollingFrame", SubTabs["Inventory"])
	InvGrid.Size = UDim2.new(1, -10, 1, -70); InvGrid.Position = UDim2.new(0, 5, 0, 65); InvGrid.BackgroundTransparency = 1; InvGrid.BorderSizePixel = 0; InvGrid.ScrollBarThickness = 4
	local gl = Instance.new("UIGridLayout", InvGrid)
	gl.CellSize = UDim2.new(0, 76, 0, 76); gl.CellPadding = UDim2.new(0, 10, 0, 12); gl.HorizontalAlignment = Enum.HorizontalAlignment.Center; gl.SortOrder = Enum.SortOrder.LayoutOrder

	SubTabs["Titles"] = Instance.new("ScrollingFrame", ContentArea); SubTabs["Titles"].Size = UDim2.new(1, 0, 1, 0); SubTabs["Titles"].BackgroundTransparency = 1; SubTabs["Titles"].Visible = false; SubTabs["Titles"].ScrollBarThickness = 6; SubTabs["Titles"].BorderSizePixel = 0
	local tLayout = Instance.new("UIListLayout", SubTabs["Titles"]); tLayout.Padding = UDim.new(0, 10); tLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; local tPad = Instance.new("UIPadding", SubTabs["Titles"]); tPad.PaddingTop = UDim.new(0, 10); tPad.PaddingBottom = UDim.new(0, 20)

	SubTabs["Auras"] = Instance.new("ScrollingFrame", ContentArea); SubTabs["Auras"].Size = UDim2.new(1, 0, 1, 0); SubTabs["Auras"].BackgroundTransparency = 1; SubTabs["Auras"].Visible = false; SubTabs["Auras"].ScrollBarThickness = 6; SubTabs["Auras"].BorderSizePixel = 0
	local aLayout = Instance.new("UIListLayout", SubTabs["Auras"]); aLayout.Padding = UDim.new(0, 10); aLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; local aPad = Instance.new("UIPadding", SubTabs["Auras"]); aPad.PaddingTop = UDim.new(0, 10); aPad.PaddingBottom = UDim.new(0, 20)

	local function BuildCosmeticList(tab, typeKey, dataPool)
		local sorted = {}; for key, data in pairs(dataPool or {}) do table.insert(sorted, {Key = key, Data = data}) end
		table.sort(sorted, function(a, b) return a.Data.Order < b.Data.Order end)

		for _, item in ipairs(sorted) do
			local card = CreateGrimPanel(tab); card.Size = UDim2.new(0.95, 0, 0, 75); card.LayoutOrder = item.Data.Order
			local cColor = Color3.fromRGB(255,255,255)
			if typeKey == "Title" then cColor = Color3.fromHex((item.Data.Color or "#FFFFFF"):gsub("#", "")) else cColor = Color3.fromHex((item.Data.Color1 or "#FFFFFF"):gsub("#", "")) end

			local title = CreateSharpLabel(card, item.Data.Name, UDim2.new(1, -90, 0, 25), Enum.Font.GothamBlack, cColor, 15); title.Position = UDim2.new(0, 15, 0, 5); title.TextXAlignment = Enum.TextXAlignment.Left
			local desc = CreateSharpLabel(card, item.Data.Desc, UDim2.new(1, -90, 0, 35), Enum.Font.GothamMedium, Color3.fromRGB(160, 160, 175), 11); desc.Position = UDim2.new(0, 15, 0, 30); desc.TextWrapped = true; desc.TextXAlignment = Enum.TextXAlignment.Left; desc.TextYAlignment = Enum.TextYAlignment.Top

			local btn, btnStroke = CreateSharpButton(card, "", UDim2.new(0.22, 0, 0, 35), Enum.Font.GothamBlack, 11); btn.Position = UDim2.new(1, -15, 0.5, 0); btn.AnchorPoint = Vector2.new(1, 0.5)

			local function UpdateState()
				local isUnlocked = false
				if type(CosmeticData.CheckUnlock) == "function" then isUnlocked = CosmeticData.CheckUnlock(player, item.Data.ReqType, item.Data.ReqValue) end
				local isEquipped = (player:GetAttribute("Equipped" .. typeKey) or (typeKey == "Title" and "Cadet" or "None")) == item.Key

				if isEquipped then btn.Text = "EQUIPPED"; btn.TextColor3 = Color3.fromRGB(225, 185, 60); btnStroke.Color = Color3.fromRGB(225, 185, 60)
				elseif isUnlocked then btn.Text = "EQUIP"; btn.TextColor3 = Color3.fromRGB(245, 245, 245); btnStroke.Color = Color3.fromRGB(70, 70, 80)
				else btn.Text = "LOCKED"; btn.TextColor3 = Color3.fromRGB(70, 70, 80); btnStroke.Color = Color3.fromRGB(70, 70, 80) end
			end
			table.insert(CosmeticUIUpdaters, UpdateState)
			btn.MouseButton1Click:Connect(function() 
				if type(CosmeticData.CheckUnlock) ~= "function" or CosmeticData.CheckUnlock(player, item.Data.ReqType, item.Data.ReqValue) then 
					Network.EquipCosmetic:FireServer(typeKey, item.Key) 
				end 
			end)
			UpdateState()
		end
	end

	BuildCosmeticList(SubTabs["Titles"], "Title", CosmeticData.Titles)
	tLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() SubTabs["Titles"].CanvasSize = UDim2.new(0, 0, 0, tLayout.AbsoluteContentSize.Y + 30) end)
	BuildCosmeticList(SubTabs["Auras"], "Aura", CosmeticData.Auras)
	aLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() SubTabs["Auras"].CanvasSize = UDim2.new(0, 0, 0, aLayout.AbsoluteContentSize.Y + 30) end)

	local function RenderRadarChart()
		if not RadarContainer or RadarContainer.Parent == nil then return end
		local w = RadarContainer.AbsoluteSize.X; local h = RadarContainer.AbsoluteSize.Y
		if w == 0 then return end 
		for _, child in ipairs(RadarContainer:GetChildren()) do if not child:IsA("UIAspectRatioConstraint") then child:Destroy() end end
		local ls = player:FindFirstChild("leaderstats"); local p = ls and ls:FindFirstChild("Prestige")
		local maxVal = GameData.GetStatCap(p and p.Value or 0)
		local stats = isShowingTitanStats and { {Name = "POW", Val = player:GetAttribute("Titan_Power_Val") or 1}, {Name = "SPD", Val = player:GetAttribute("Titan_Speed_Val") or 1}, {Name = "HRD", Val = player:GetAttribute("Titan_Hardening_Val") or 1}, {Name = "END", Val = player:GetAttribute("Titan_Endurance_Val") or 1}, {Name = "STM", Val = player:GetAttribute("Titan_Precision_Val") or 1}, {Name = "POT", Val = player:GetAttribute("Titan_Potential_Val") or 1} } or { {Name = "HP", Val = player:GetAttribute("Health") or 1}, {Name = "STR", Val = player:GetAttribute("Strength") or 1}, {Name = "DEF", Val = player:GetAttribute("Defense") or 1}, {Name = "SPD", Val = player:GetAttribute("Speed") or 1}, {Name = "GAS", Val = player:GetAttribute("Gas") or 1}, {Name = "RES", Val = player:GetAttribute("Resolve") or 1} }

		local angles = {-90, -30, 30, 90, 150, 210}; local centerX, centerY = w/2, h/2; local maxRadius = math.min(w, h) * 0.35
		for ring = 1, 3 do local r = maxRadius * (ring / 3) for i = 1, 6 do local nextI = i % 6 + 1; DrawLineScale(RadarContainer, centerX + r*math.cos(math.rad(angles[i])), centerY + r*math.sin(math.rad(angles[i])), centerX + r*math.cos(math.rad(angles[nextI])), centerY + r*math.sin(math.rad(angles[nextI])), Color3.fromRGB(60, 60, 70), 1, 1) end end
		for i = 1, 6 do 
			local rad = math.rad(angles[i]); local px = centerX + maxRadius * math.cos(rad); local py = centerY + maxRadius * math.sin(rad)
			DrawLineScale(RadarContainer, centerX, centerY, px, py, Color3.fromRGB(60, 60, 70), 1, 1)
			local lbl = CreateSharpLabel(RadarContainer, stats[i].Name .. "\n" .. stats[i].Val, UDim2.new(0, 30, 0, 15), Enum.Font.GothamBold, Color3.fromRGB(160, 160, 175), 9)
			lbl.Position = UDim2.new(0, centerX + (maxRadius + 15) * math.cos(rad), 0, centerY + (maxRadius + 15) * math.sin(rad)); lbl.AnchorPoint = Vector2.new(0.5, 0.5)
		end
		local statColor = isShowingTitanStats and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
		local pts = {}
		for i = 1, 6 do local r1 = maxRadius * math.clamp(stats[i].Val / maxVal, 0.05, 1); table.insert(pts, Vector2.new(centerX + r1 * math.cos(math.rad(angles[i])), centerY + r1 * math.sin(math.rad(angles[i])))) end
		for i = 1, 6 do local nextI = i % 6 + 1; DrawLineScale(RadarContainer, pts[i].X, pts[i].Y, pts[nextI].X, pts[nextI].Y, statColor, 2, 5); DrawUITriangle(RadarContainer, Vector2.new(centerX, centerY), pts[i], pts[nextI], statColor, 0.5, 3) end
	end
	RadarContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(RenderRadarChart)
	toggleStatsBtn.MouseButton1Click:Connect(function() isShowingTitanStats = not isShowingTitanStats; toggleStatsBtn.Text = isShowingTitanStats and "VIEW HUMAN STATS" or "VIEW TITAN STATS"; RenderRadarChart() end)

	RefreshProfile = function()
		for i, lbl in ipairs(SkillSlotLabels) do 
			local rawName = player:GetAttribute("EquippedSkill_" .. i) or "EMPTY"
			lbl.Text = string.upper(rawName)
		end

		local tName = player:GetAttribute("Titan") or "None"; local cName = player:GetAttribute("Clan") or "None"; local regName = player:GetAttribute("Regiment") or "Cadet Corps"
		local hasRegData, regDataModule = pcall(function() return require(game.ReplicatedStorage:WaitForChild("RegimentData")) end)
		if hasRegData and regDataModule and regDataModule.Regiments[regName] then regIcon.Image = regDataModule.Regiments[regName].Icon else regIcon.Image = "" end

		if cName == "Ackerman" or cName == "Awakened Ackerman" then titanLabel.Text = "Titan: <font color='#FF5555'>(Titan Disabled)</font>" else titanLabel.Text = "Titan: <font color='#FF5555'>" .. tName .. "</font>" end
		clanLabel.Text = "Clan: <font color='#55FF55'>" .. cName .. "</font>"
		regimentLabel.Text = "Regiment: <font color='"..(REG_COLORS[regName] or TEXT_COLORS.DefaultGreen).."'>" .. regName .. "</font>"

		local wpnName = player:GetAttribute("EquippedWeapon") or "None"; local accName = player:GetAttribute("EquippedAccessory") or "None"
		local wpnRarity = (wpnName ~= "None" and ItemData.Equipment and ItemData.Equipment[wpnName]) and ItemData.Equipment[wpnName].Rarity or "Common"
		local accRarity = (accName ~= "None" and ItemData.Equipment and ItemData.Equipment[accName]) and ItemData.Equipment[accName].Rarity or "Common"
		wpnLabel.Text = "Weapon: <font color='"..(RarityColors[wpnRarity] or "#FFFFFF").."'>" .. wpnName .. "</font>"
		accLabel.Text = "Accessory: <font color='"..(RarityColors[accRarity] or "#FFFFFF").."'>" .. accName .. "</font>"

		RenderRadarChart()

		local pTitle = player:GetAttribute("EquippedTitle") or "Cadet"; local pAura = player:GetAttribute("EquippedAura") or "None"
		local resolvedTitleData = CosmeticData.Titles[pTitle]
		if not resolvedTitleData then for k, v in pairs(CosmeticData.Titles or {}) do if v.Name == pTitle then resolvedTitleData = v break end end end
		if resolvedTitleData then AvatarTitle.Text = string.upper(resolvedTitleData.Name); AvatarTitle.TextColor3 = Color3.fromHex((resolvedTitleData.Color or "#FFFFFF"):gsub("#", "")) end

		local resolvedAuraData = CosmeticData.Auras[pAura]
		if not resolvedAuraData then for k, v in pairs(CosmeticData.Auras or {}) do if v.Name == pAura then resolvedAuraData = v break end end end
		if UIAuraManager and type(UIAuraManager.ApplyAura) == "function" and resolvedAuraData then UIAuraManager.ApplyAura(AvatarAuraGlow, resolvedAuraData, AvatarBox) end

		for _, child in ipairs(InvGrid:GetChildren()) do 
			if child.Name == "ItemCard" then child:Destroy() end 
		end

		local inventoryItems = {}
		local currentSlotsUsed = 0

		for iName, iData in pairs(ItemData.Equipment or {}) do 
			local safeNameBase = iName:gsub("[^%w]", "")
			local count = tonumber(player:GetAttribute(safeNameBase .. "Count")) or tonumber(player:GetAttribute(iName)) or 0
			if count > 0 then 
				currentSlotsUsed += 1 
				if currentInvFilter == "All" or currentInvFilter == "Gear" then table.insert(inventoryItems, {Name = iName, Data = iData, Count = count}) end
			end
		end
		for iName, iData in pairs(ItemData.Consumables or {}) do 
			local safeNameBase = iName:gsub("[^%w]", "")
			local count = tonumber(player:GetAttribute(safeNameBase .. "Count")) or tonumber(player:GetAttribute(iName)) or 0
			if count > 0 then 
				currentSlotsUsed += 1 
				if currentInvFilter == "All" or currentInvFilter == "Items" then table.insert(inventoryItems, {Name = iName, Data = iData, Count = count}) end
			end
		end

		table.sort(inventoryItems, function(a, b) local rA = RarityOrder[a.Data.Rarity or "Common"] or 7; local rB = RarityOrder[b.Data.Rarity or "Common"] or 7; if rA == rB then return a.Name < b.Name else return rA < rB end end)

		local layoutOrderCounter = 1
		for _, item in ipairs(inventoryItems) do

			local card = CreateGrimPanel(InvGrid)
			card.Name = "ItemCard" 
			card.Size = UDim2.new(0, 76, 0, 76); card.LayoutOrder = layoutOrderCounter; layoutOrderCounter += 1

			local rarityKey = item.Data.Rarity or "Common"
			local safeNameBase = item.Name:gsub("[^%w]", "")

			if player:GetAttribute(safeNameBase .. "_Awakened") then rarityKey = "Transcendent" end
			local rarityRGB = Color3.fromHex((RarityColors[rarityKey] or "#FFFFFF"):gsub("#", ""))
			local isLocked = player:GetAttribute(safeNameBase .. "_Locked")

			card:FindFirstChild("UIStroke").Color = isLocked and UIHelpers.Colors.Gold or rarityRGB

			local bgGlow = Instance.new("Frame", card)
			bgGlow.Size = UDim2.new(1, 0, 0.5, 0); bgGlow.Position = UDim2.new(0, 0, 0.5, 0); bgGlow.BackgroundColor3 = rarityRGB; bgGlow.BackgroundTransparency = 0.92; bgGlow.BorderSizePixel = 0; bgGlow.ZIndex = 1

			local countBadge = Instance.new("Frame", card)
			countBadge.Size = UDim2.new(0, 20, 0, 12); countBadge.AnchorPoint = Vector2.new(1, 0); countBadge.Position = UDim2.new(1, -4, 0, 6); countBadge.BackgroundColor3 = Color3.fromRGB(18, 18, 22); countBadge.BorderSizePixel = 1; countBadge.BorderColor3 = rarityRGB; countBadge.ZIndex = 3
			local countTag = CreateSharpLabel(countBadge, "x" .. item.Count, UDim2.new(1, 0, 1, 0), Enum.Font.GothamBlack, Color3.fromRGB(245, 245, 245), 9); countTag.ZIndex = 4

			if isLocked then
				local lockIcon = UIHelpers.CreateLabel(card, "🔒", UDim2.new(0, 15, 0, 15), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 12)
				lockIcon.Position = UDim2.new(0, 5, 0, 5); lockIcon.ZIndex = 4
			end

			local nameLbl = CreateSharpLabel(card, item.Name, UDim2.new(0.88, 0, 0.5, 0), Enum.Font.GothamBold, Color3.fromRGB(245, 245, 245), 10)
			nameLbl.Position = UDim2.new(0.5, 0, 0.5, 2); nameLbl.AnchorPoint = Vector2.new(0.5, 0.5); nameLbl.TextScaled = true; nameLbl.TextWrapped = true; nameLbl.ZIndex = 3
			local tCon2 = Instance.new("UITextSizeConstraint", nameLbl); tCon2.MaxTextSize = 9; tCon2.MinTextSize = 6

			local rarityTag = CreateSharpLabel(card, string.sub(rarityKey, 1, 1), UDim2.new(0, 16, 0, 16), Enum.Font.GothamBlack, rarityRGB, 10)
			rarityTag.Position = UDim2.new(0, 6, 1, -20); rarityTag.TextTransparency = 0.3; rarityTag.ZIndex = 3

			local btnCover = Instance.new("TextButton", card)
			btnCover.Size = UDim2.new(1,0,1,0); btnCover.BackgroundTransparency = 1; btnCover.Text = ""; btnCover.ZIndex = 5

			local tTipStr = "<font color='" .. RarityColors[rarityKey] .. "'>[" .. rarityKey .. "]</font> <b>" .. item.Name .. "</b>"
			btnCover.MouseEnter:Connect(function() if cachedTooltipMgr and type(cachedTooltipMgr.Show) == "function" then cachedTooltipMgr.Show(tTipStr) end end)
			btnCover.MouseLeave:Connect(function() if cachedTooltipMgr and type(cachedTooltipMgr.Hide) == "function" then cachedTooltipMgr.Hide() end end)

			if not item.Data.IsGift then
				local ActionsOverlay = Instance.new("Frame", card)
				ActionsOverlay.Name = "ActionsOverlay"; ActionsOverlay.Size = UDim2.new(1, 0, 1, 0); ActionsOverlay.BackgroundColor3 = Color3.fromRGB(18, 18, 22); ActionsOverlay.BackgroundTransparency = 0.05; ActionsOverlay.Visible = false; ActionsOverlay.ZIndex = 10; ActionsOverlay.Active = true; ActionsOverlay.BorderSizePixel = 0

				local actLayout = Instance.new("UIListLayout", ActionsOverlay); actLayout.Padding = UDim.new(0, 4); actLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; actLayout.VerticalAlignment = Enum.VerticalAlignment.Center

				local buttonConsumed = false
				local function MakeOverlayBtn(text)
					local obtn, _ = CreateSharpButton(ActionsOverlay, text, UDim2.new(0.9, 0, 0, 16), Enum.Font.GothamBlack, 8)
					obtn.ZIndex = 11; return obtn
				end

				local equipBtn = MakeOverlayBtn("EQUIP")
				local sellBtn = MakeOverlayBtn("SELL 1x")
				local lockBtn = MakeOverlayBtn(isLocked and "UNLOCK" or "LOCK")

				if isLocked then
					lockBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
					sellBtn.Visible = false
				else
					lockBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
				end

				if item.Data.Type ~= nil then 
					local isEq = (player:GetAttribute("EquippedWeapon") == item.Name) or (player:GetAttribute("EquippedAccessory") == item.Name)
					if isEq then equipBtn.Text = "UNEQUIP"; equipBtn.TextColor3 = Color3.fromRGB(255, 100, 100) else equipBtn.Text = "EQUIP"; equipBtn.TextColor3 = Color3.fromRGB(245, 245, 245) end

					equipBtn.MouseButton1Click:Connect(function() 
						buttonConsumed = true
						if isEq then Network.EquipItem:FireServer("Unequip_" .. item.Data.Type) else Network.EquipItem:FireServer(item.Name) end
						ActionsOverlay.Visible = false
					end)
				elseif item.Data.Action ~= nil then 
					equipBtn.Text = "USE"; equipBtn.TextColor3 = Color3.fromRGB(200, 150, 255)
					equipBtn.MouseButton1Click:Connect(function() 
						buttonConsumed = true
						Network.ConsumeItem:FireServer(item.Name)
						ActionsOverlay.Visible = false
					end)
				else equipBtn.Visible = false end

				sellBtn.MouseButton1Click:Connect(function() buttonConsumed = true; Network.SellItem:FireServer(item.Name, false); ActionsOverlay.Visible = false end)
				lockBtn.MouseButton1Click:Connect(function() buttonConsumed = true; Network:WaitForChild("ToggleLock"):FireServer(item.Name); ActionsOverlay.Visible = false end)

				local function CloseAllOverlays()
					for _, c in ipairs(InvGrid:GetChildren()) do if c.Name == "ItemCard" then local ov = c:FindFirstChild("ActionsOverlay"); if ov then ov.Visible = false end end end
				end

				btnCover.MouseButton1Click:Connect(function()
					if buttonConsumed then buttonConsumed = false; return end
					if ActionsOverlay.Visible then ActionsOverlay.Visible = false else CloseAllOverlays(); ActionsOverlay.Visible = true end
				end)
			end
		end

		InvTitle.Text = "INVENTORY (" .. currentSlotsUsed .. "/" .. MAX_INVENTORY_CAPACITY .. ")"
		if currentSlotsUsed >= MAX_INVENTORY_CAPACITY then InvTitle.TextColor3 = Color3.fromRGB(255, 100, 100) else InvTitle.TextColor3 = Color3.fromRGB(225, 185, 60) end
		task.delay(0.05, function() InvGrid.CanvasSize = UDim2.new(0, 0, 0, math.ceil(layoutOrderCounter / 3) * 88) end)
	end

	player.AttributeChanged:Connect(function(attr)
		EvaluateCosmetics()
		RefreshProfile()
	end)
end

return ProfileTab