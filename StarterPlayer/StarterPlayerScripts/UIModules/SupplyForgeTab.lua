-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: SupplyForgeTab
local SupplyForgeTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

local player = Players.LocalPlayer

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

	btn.MouseEnter:Connect(function() stroke.Color = UIHelpers.Colors.Gold; btn.TextColor3 = UIHelpers.Colors.Gold end)
	btn.MouseLeave:Connect(function() stroke.Color = Color3.fromRGB(70, 70, 80); btn.TextColor3 = Color3.fromRGB(245, 245, 245) end)
	return btn, stroke
end

function SupplyForgeTab.Initialize(parentFrame)
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

	-- ==========================================
	-- SUB-NAVIGATION
	-- ==========================================
	local SubNav = Instance.new("Frame", MainFrame)
	SubNav.Size = UDim2.new(0.95, 0, 0, 45)
	SubNav.BackgroundTransparency = 1
	SubNav.LayoutOrder = 1

	local navLayout = Instance.new("UIListLayout", SubNav)
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	navLayout.Padding = UDim.new(0, 10)

	local ContentArea = Instance.new("Frame", MainFrame)
	ContentArea.Size = UDim2.new(0.95, 0, 1, -75)
	ContentArea.BackgroundTransparency = 1
	ContentArea.LayoutOrder = 2

	local subTabs = { "MARKETPLACE", "THE FORGE", "TITAN FUSION" }
	local activeSubFrames = {}
	local subBtns = {}

	for i, tabName in ipairs(subTabs) do
		local btn, stroke = UIHelpers.CreateButton(SubNav, tabName, UDim2.new(0, 160, 0, 30), Enum.Font.GothamBold, 12)
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

	subBtns["MARKETPLACE"].Btn.TextColor3 = UIHelpers.Colors.Gold
	subBtns["MARKETPLACE"].Stroke.Color = UIHelpers.Colors.Gold

	-- ==========================================
	-- 1. MARKETPLACE
	-- ==========================================
	local MarketTab = activeSubFrames["MARKETPLACE"]

	local marketTitle = UIHelpers.CreateLabel(MarketTab, "MARKETPLACE & SUPPLY", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 20)
	marketTitle.Position = UDim2.new(0, 0, 0, 0)

	local SplitContainer = Instance.new("Frame", MarketTab)
	SplitContainer.Size = UDim2.new(1, 0, 1, -40)
	SplitContainer.Position = UDim2.new(0, 0, 0, 40)
	SplitContainer.BackgroundTransparency = 1

	local scLayout = Instance.new("UIListLayout", SplitContainer)
	scLayout.FillDirection = Enum.FillDirection.Horizontal
	scLayout.Padding = UDim.new(0, 20)

	-- LEFT PANEL: Premium & Codes
	local LeftPanel = Instance.new("Frame", SplitContainer)
	LeftPanel.Size = UDim2.new(0.48, 0, 1, 0)
	LeftPanel.BackgroundTransparency = 1

	-- Premium Store
	local PremContainer = Instance.new("Frame", LeftPanel)
	PremContainer.Size = UDim2.new(1, 0, 0.65, 0)
	UIHelpers.ApplyGrimPanel(PremContainer, false)

	local pTitle = UIHelpers.CreateLabel(PremContainer, "PREMIUM STORE", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 16)

	local PremScroll = Instance.new("ScrollingFrame", PremContainer)
	PremScroll.Size = UDim2.new(1, -20, 1, -40)
	PremScroll.Position = UDim2.new(0, 10, 0, 30)
	PremScroll.BackgroundTransparency = 1
	PremScroll.ScrollBarThickness = 4
	PremScroll.BorderSizePixel = 0

	local pslayout = Instance.new("UIListLayout", PremScroll)
	pslayout.Padding = UDim.new(0, 10)
	pslayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() PremScroll.CanvasSize = UDim2.new(0,0,0, pslayout.AbsoluteContentSize.Y + 10) end)

	local passes = { "VIP PASS", "+100K DEWS", "2X EXP BOOST", "INVENTORY EXPANSION" }
	for _, pass in ipairs(passes) do
		local pCard = Instance.new("Frame", PremScroll)
		pCard.Size = UDim2.new(1, -10, 0, 80)
		pCard.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		local pStroke = Instance.new("UIStroke", pCard)
		pStroke.Color = Color3.fromRGB(80, 50, 100)
		pStroke.Thickness = 2

		local pName = UIHelpers.CreateLabel(pCard, pass, UDim2.new(1, -20, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 14)
		pName.Position = UDim2.new(0, 10, 0, 5); pName.TextXAlignment = Enum.TextXAlignment.Left

		local pDesc = UIHelpers.CreateLabel(pCard, "Purchase " .. string.lower(pass) .. " to gain immediate benefits.", UDim2.new(1, -20, 0, 20), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 11)
		pDesc.Position = UDim2.new(0, 10, 0, 25); pDesc.TextXAlignment = Enum.TextXAlignment.Left

		local btnContainer = Instance.new("Frame", pCard)
		btnContainer.Size = UDim2.new(1, -20, 0, 30)
		btnContainer.Position = UDim2.new(0, 10, 1, -35)
		btnContainer.BackgroundTransparency = 1
		local bcLayout = Instance.new("UIListLayout", btnContainer); bcLayout.FillDirection = Enum.FillDirection.Horizontal; bcLayout.Padding = UDim.new(0, 10)

		local buyBtn, _ = CreateSharpButton(btnContainer, "BUY", UDim2.new(0.48, 0, 1, 0), Enum.Font.GothamBlack, 12)
		buyBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		local giftBtn, _ = CreateSharpButton(btnContainer, "GIFT", UDim2.new(0.48, 0, 1, 0), Enum.Font.GothamBlack, 12)
		giftBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 150)

		-- Routing to Shop Manager
		buyBtn.MouseButton1Click:Connect(function() Network:WaitForChild("ShopAction"):FireServer("PromptPremium", pass) end)
		giftBtn.MouseButton1Click:Connect(function() Network:WaitForChild("ShopAction"):FireServer("PromptGift", pass) end)
	end

	-- Codes Section
	local CodeContainer = Instance.new("Frame", LeftPanel)
	CodeContainer.Size = UDim2.new(1, 0, 0.3, 0)
	CodeContainer.Position = UDim2.new(0, 0, 0.7, 0)
	UIHelpers.ApplyGrimPanel(CodeContainer, false)

	local cInput = Instance.new("TextBox", CodeContainer)
	cInput.Size = UDim2.new(0.8, 0, 0, 40)
	cInput.Position = UDim2.new(0.5, 0, 0.3, 0)
	cInput.AnchorPoint = Vector2.new(0.5, 0.5)
	cInput.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	cInput.TextColor3 = UIHelpers.Colors.Gold
	cInput.Font = Enum.Font.GothamBlack
	cInput.TextSize = 14
	cInput.PlaceholderText = "Redeem Code Here"
	cInput.Text = ""
	Instance.new("UIStroke", cInput).Color = UIHelpers.Colors.BorderMuted

	local RedeemBtn, _ = CreateSharpButton(CodeContainer, "REDEEM", UDim2.new(0.8, 0, 0, 40), Enum.Font.GothamBlack, 16)
	RedeemBtn.Position = UDim2.new(0.5, 0, 0.7, 0)
	RedeemBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	RedeemBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)

	local cHint = UIHelpers.CreateLabel(CodeContainer, "ENTER PROMO CODE:", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 12)
	cHint.Position = UDim2.new(0, 0, 1, -25)

	-- Routing to Code Manager
	RedeemBtn.MouseButton1Click:Connect(function()
		if cInput.Text ~= "" then
			Network:WaitForChild("CodeAction"):FireServer("Redeem", cInput.Text)
			cInput.Text = ""
		end
	end)

	-- RIGHT PANEL: Supply Store
	local RightPanel = Instance.new("Frame", SplitContainer)
	RightPanel.Size = UDim2.new(0.5, 0, 1, 0)
	RightPanel.BackgroundTransparency = 1

	local rrContainer = Instance.new("Frame", RightPanel)
	rrContainer.Size = UDim2.new(1, 0, 0, 45)
	rrContainer.BackgroundTransparency = 1
	local rrLayout = Instance.new("UIListLayout", rrContainer); rrLayout.FillDirection = Enum.FillDirection.Horizontal; rrLayout.Padding = UDim.new(0, 10)

	local rrDews, _ = CreateSharpButton(rrContainer, "RESTOCK (300K Dews)", UDim2.new(0.32, 0, 1, 0), Enum.Font.GothamBlack, 11)
	rrDews.BackgroundColor3 = Color3.fromRGB(50, 100, 180)
	local rrVIP, _ = CreateSharpButton(rrContainer, "FREE RESTOCK (VIP)", UDim2.new(0.32, 0, 1, 0), Enum.Font.GothamBlack, 11)
	rrVIP.BackgroundColor3 = Color3.fromRGB(150, 50, 150)
	local rrRobux, _ = CreateSharpButton(rrContainer, "RESTOCK (50 R$)", UDim2.new(0.32, 0, 1, 0), Enum.Font.GothamBlack, 11)
	rrRobux.BackgroundColor3 = Color3.fromRGB(50, 150, 50)

	-- Routing to Shop Manager
	rrDews.MouseButton1Click:Connect(function() Network:WaitForChild("ShopAction"):FireServer("Reroll", "Dews") end)
	rrVIP.MouseButton1Click:Connect(function() Network:WaitForChild("ShopAction"):FireServer("Reroll", "VIP") end)
	rrRobux.MouseButton1Click:Connect(function() Network:WaitForChild("ShopAction"):FireServer("Reroll", "Robux") end)

	local restockTimer = UIHelpers.CreateLabel(RightPanel, "RESTOCKS IN: 03:36", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBlack, Color3.fromRGB(255, 150, 100), 12)
	restockTimer.Position = UDim2.new(0, 0, 0, 50)

	local SupplyScroll = Instance.new("ScrollingFrame", RightPanel)
	SupplyScroll.Size = UDim2.new(1, 0, 1, -80)
	SupplyScroll.Position = UDim2.new(0, 0, 0, 80)
	SupplyScroll.BackgroundTransparency = 1
	SupplyScroll.ScrollBarThickness = 6
	SupplyScroll.BorderSizePixel = 0

	local ssLayout = Instance.new("UIListLayout", SupplyScroll)
	ssLayout.Padding = UDim.new(0, 8)

	local RarityColors = {
		["Common"] = Color3.fromRGB(200, 200, 200),
		["Uncommon"] = Color3.fromRGB(85, 255, 85),
		["Rare"] = Color3.fromRGB(85, 85, 255),
		["Epic"] = Color3.fromRGB(170, 85, 255),
		["Legendary"] = Color3.fromRGB(255, 215, 0),
		["Mythical"] = Color3.fromRGB(255, 85, 85),
		["Transcendent"] = Color3.fromRGB(255, 85, 255)
	}

	local function AddSupplyItem(itemName, itemData, cost)
		local rarityColor = RarityColors[itemData.Rarity or "Common"]
		local c = Instance.new("Frame", SupplyScroll)
		c.Size = UDim2.new(1, -10, 0, 70)
		c.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
		local strk = Instance.new("UIStroke", c)
		strk.Color = rarityColor
		strk.Thickness = 2

		-- Inventory-style glow matching the rarity color
		local bgGlow = Instance.new("Frame", c)
		bgGlow.Size = UDim2.new(1, 0, 0.5, 0)
		bgGlow.Position = UDim2.new(0, 0, 0.5, 0)
		bgGlow.BackgroundColor3 = rarityColor
		bgGlow.BackgroundTransparency = 0.92
		bgGlow.BorderSizePixel = 0
		bgGlow.ZIndex = 1

		local nameLbl = UIHelpers.CreateLabel(c, itemName, UDim2.new(0.6, 0, 0, 20), Enum.Font.GothamBlack, rarityColor, 14)
		nameLbl.Position = UDim2.new(0, 15, 0, 10); nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.ZIndex = 2

		local statsTxt = ""
		if itemData.Bonus then
			for k, v in pairs(itemData.Bonus) do
				local s = tostring(k):sub(1,3):upper()
				local symb = v > 0 and "+" or ""
				statsTxt = statsTxt .. symb .. v .. " " .. s .. " | "
			end
			statsTxt = statsTxt:sub(1, -3)
		else
			statsTxt = itemData.Desc or "A useful item."
		end

		local statsLbl = UIHelpers.CreateLabel(c, statsTxt, UDim2.new(0.6, 0, 0, 15), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 11)
		statsLbl.Position = UDim2.new(0, 15, 0, 30); statsLbl.TextXAlignment = Enum.TextXAlignment.Left
		statsLbl.ZIndex = 2

		local costLbl = UIHelpers.CreateLabel(c, "Cost: " .. tostring(cost) .. " Dews", UDim2.new(0.6, 0, 0, 20), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 10)
		costLbl.Position = UDim2.new(0, 15, 1, -25); costLbl.TextXAlignment = Enum.TextXAlignment.Left
		costLbl.ZIndex = 2

		local bBtn, _ = CreateSharpButton(c, "BUY", UDim2.new(0, 100, 0, 30), Enum.Font.GothamBlack, 12)
		bBtn.Position = UDim2.new(1, -15, 1, -15); bBtn.AnchorPoint = Vector2.new(1, 1)
		bBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		bBtn.ZIndex = 3

		-- Routing to Shop Manager
		bBtn.MouseButton1Click:Connect(function()
			Network:WaitForChild("ShopAction"):FireServer("BuyItem", itemName)
		end)
	end

	-- Dummy items for visual testing
	AddSupplyItem("Garrison Hip Flask", {Rarity = "Uncommon", Bonus = {Health = 10, Resolve = 5}}, 1200)
	AddSupplyItem("Titan Research Notes", {Rarity = "Rare", Desc = "Doubles all XP gained."}, 5000)
	AddSupplyItem("Scout Training Manual", {Rarity = "Common", Bonus = {Resolve = 5}}, 500)
	AddSupplyItem("Garrison Standard Blades", {Rarity = "Uncommon", Bonus = {Strength = 6, Speed = 4}}, 1200)
	AddSupplyItem("Training Dummy Sword", {Rarity = "Common", Bonus = {Strength = 1}}, 250)
	AddSupplyItem("Worn Trainee Badge", {Rarity = "Common", Bonus = {Health = 2, Resolve = 2}}, 300)

	ssLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() SupplyScroll.CanvasSize = UDim2.new(0,0,0, ssLayout.AbsoluteContentSize.Y + 10) end)

	-- ==========================================
	-- 4. THE FORGE
	-- ==========================================
	local ForgeTab = activeSubFrames["THE FORGE"]

	local RecipeList = Instance.new("ScrollingFrame", ForgeTab)
	RecipeList.Size = UDim2.new(0.3, 0, 1, 0)
	RecipeList.BackgroundTransparency = 1
	RecipeList.ScrollBarThickness = 4
	RecipeList.BorderSizePixel = 0

	local rlLayout = Instance.new("UIListLayout", RecipeList)
	rlLayout.Padding = UDim.new(0, 10)
	rlLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() RecipeList.CanvasSize = UDim2.new(0, 0, 0, rlLayout.AbsoluteContentSize.Y + 20) end)

	local BlueprintPanel = Instance.new("Frame", ForgeTab)
	BlueprintPanel.Size = UDim2.new(0.68, 0, 1, 0)
	BlueprintPanel.Position = UDim2.new(1, 0, 0, 0)
	BlueprintPanel.AnchorPoint = Vector2.new(1, 0)
	UIHelpers.ApplyGrimPanel(BlueprintPanel, false)

	local bpTitle = UIHelpers.CreateLabel(BlueprintPanel, "SELECT A BLUEPRINT", UDim2.new(1, -40, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 24)
	bpTitle.Position = UDim2.new(0, 20, 0, 20); bpTitle.TextXAlignment = Enum.TextXAlignment.Left

	local bpDesc = UIHelpers.CreateLabel(BlueprintPanel, "Select an item from the registry to view its crafting requirements.", UDim2.new(1, -40, 0, 40), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 14)
	bpDesc.Position = UDim2.new(0, 20, 0, 60); bpDesc.TextXAlignment = Enum.TextXAlignment.Left; bpDesc.TextWrapped = true; bpDesc.TextYAlignment = Enum.TextYAlignment.Top

	local ReqTitle = UIHelpers.CreateLabel(BlueprintPanel, "REQUIRED MATERIALS", UDim2.new(1, -40, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 16)
	ReqTitle.Position = UDim2.new(0, 20, 0, 140); ReqTitle.TextXAlignment = Enum.TextXAlignment.Left; ReqTitle.Visible = false

	local ReqList = Instance.new("Frame", BlueprintPanel)
	ReqList.Size = UDim2.new(1, -40, 0, 200)
	ReqList.Position = UDim2.new(0, 20, 0, 170)
	ReqList.BackgroundTransparency = 1
	local reqLayout = Instance.new("UIListLayout", ReqList); reqLayout.Padding = UDim.new(0, 8)

	local CraftBtn = UIHelpers.CreateButton(BlueprintPanel, "FORGE EQUIPMENT", UDim2.new(0.8, 0, 0, 50), Enum.Font.GothamBlack, 18)
	CraftBtn.Position = UDim2.new(0.5, 0, 1, -30); CraftBtn.AnchorPoint = Vector2.new(0.5, 1); CraftBtn.Visible = false

	-- Routing to Forge Manager
	CraftBtn.MouseButton1Click:Connect(function()
		Network:WaitForChild("ForgeAction"):FireServer("Craft", bpTitle.Text)
	end)

	for rec, _ in pairs(ItemData.ForgeRecipes or {}) do
		local rBtn = UIHelpers.CreateButton(RecipeList, rec, UDim2.new(1, -10, 0, 45), Enum.Font.GothamBold, 12)
		rBtn.MouseButton1Click:Connect(function()
			bpTitle.Text = string.upper(rec)
			bpDesc.Text = "A high-tier piece of equipment forged from rare materials."
			ReqTitle.Visible = true; CraftBtn.Visible = true

			for _, c in ipairs(ReqList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

			local function MakeReq(matName, amt)
				local rf = Instance.new("Frame", ReqList)
				rf.Size = UDim2.new(1, 0, 0, 35); rf.BackgroundColor3 = Color3.fromRGB(25, 25, 30); Instance.new("UIStroke", rf).Color = UIHelpers.Colors.BorderMuted
				local l = UIHelpers.CreateLabel(rf, amt .. "x " .. matName, UDim2.new(1, -30, 1, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 14)
				l.Position = UDim2.new(0, 15, 0, 0); l.TextXAlignment = Enum.TextXAlignment.Left
			end

			if ItemData.ForgeRecipes[rec] then
				for mat, amt in pairs(ItemData.ForgeRecipes[rec].ReqItems) do MakeReq(mat, amt) end
				MakeReq("Dews", ItemData.ForgeRecipes[rec].DewCost)
			end
		end)
	end

	-- ==========================================
	-- 5. TITAN FUSION
	-- ==========================================
	local FusionTab = activeSubFrames["TITAN FUSION"]

	local fTitle = UIHelpers.CreateLabel(FusionTab, "TITAN HYBRIDIZATION", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, Color3.fromRGB(170, 85, 255), 26)
	fTitle.Position = UDim2.new(0, 0, 0, 10)

	local fDesc = UIHelpers.CreateLabel(FusionTab, "Fuse two Pure Titans with Abyssal Blood to create a horrific Hybrid. This action is irreversible.", UDim2.new(1, 0, 0, 20), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 14)
	fDesc.Position = UDim2.new(0, 0, 0, 50)

	local SlotContainer = Instance.new("Frame", FusionTab)
	SlotContainer.Size = UDim2.new(0.8, 0, 0, 250)
	SlotContainer.Position = UDim2.new(0.5, 0, 0.45, 0)
	SlotContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	SlotContainer.BackgroundTransparency = 1

	local function CreateFusionSlot(pos, titleText, colorHex)
		local f = Instance.new("Frame", SlotContainer)
		f.Size = UDim2.new(0, 200, 0, 200)
		f.Position = pos
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		UIHelpers.ApplyGrimPanel(f, false)
		f:FindFirstChild("UIStroke").Color = Color3.fromHex(colorHex)

		local t = UIHelpers.CreateLabel(f, titleText, UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, Color3.fromHex(colorHex), 14)
		t.Position = UDim2.new(0, 0, 0, 10)

		local addBtn = UIHelpers.CreateButton(f, "+", UDim2.new(0, 60, 0, 60), Enum.Font.GothamBlack, 28)
		addBtn.Position = UDim2.new(0.5, 0, 0.5, 15)
		addBtn.AnchorPoint = Vector2.new(0.5, 0.5)

		return f
	end

	local Slot1 = CreateFusionSlot(UDim2.new(0.15, 0, 0.5, 0), "SUBJECT ALPHA", "55AAFF")
	local Slot2 = CreateFusionSlot(UDim2.new(0.85, 0, 0.5, 0), "SUBJECT OMEGA", "FF5555")
	local ResultSlot = CreateFusionSlot(UDim2.new(0.5, 0, 0.5, 0), "HYBRIDIZATION", "AA55FF")

	local line1 = Instance.new("Frame", SlotContainer); line1.Size = UDim2.new(0, 120, 0, 4); line1.Position = UDim2.new(0.32, 0, 0.5, 0); line1.AnchorPoint=Vector2.new(0.5, 0.5); line1.BackgroundColor3 = Color3.fromRGB(170, 85, 255); line1.BorderSizePixel=0
	local line2 = Instance.new("Frame", SlotContainer); line2.Size = UDim2.new(0, 120, 0, 4); line2.Position = UDim2.new(0.68, 0, 0.5, 0); line2.AnchorPoint=Vector2.new(0.5, 0.5); line2.BackgroundColor3 = Color3.fromRGB(170, 85, 255); line2.BorderSizePixel=0

	local FuseBtn = UIHelpers.CreateButton(FusionTab, "INITIATE FUSION (300,000 DEWS)", UDim2.new(0, 400, 0, 55), Enum.Font.GothamBlack, 18)
	FuseBtn.Position = UDim2.new(0.5, 0, 1, -40)
	FuseBtn.AnchorPoint = Vector2.new(0.5, 1)
	FuseBtn.TextColor3 = Color3.fromRGB(170, 85, 255)
	FuseBtn:FindFirstChild("UIStroke").Color = Color3.fromRGB(170, 85, 255)

	-- Routing to Titan Manager
	FuseBtn.MouseButton1Click:Connect(function()
		Network:WaitForChild("TitanAction"):FireServer("FuseTitans")
	end)

end

return SupplyForgeTab