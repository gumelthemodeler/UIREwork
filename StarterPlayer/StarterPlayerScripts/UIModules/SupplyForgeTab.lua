-- @ScriptType: ModuleScript
-- Name: SupplyForgeTab
local SupplyForgeTab = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Network = ReplicatedStorage:WaitForChild("Network")
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local TitanData = require(ReplicatedStorage:WaitForChild("TitanData")) -- [[ THE FIX: Added TitanData! ]]

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

	local LeftPanel = Instance.new("Frame", SplitContainer)
	LeftPanel.Size = UDim2.new(0.48, 0, 1, 0)
	LeftPanel.BackgroundTransparency = 1

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

	local function CreatePremiumCard(titleText, descText, buyAction, giftAction)
		local pCard = Instance.new("Frame", PremScroll)
		pCard.Size = UDim2.new(1, -10, 0, 80)
		pCard.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		local pStroke = Instance.new("UIStroke", pCard)
		pStroke.Color = Color3.fromRGB(80, 50, 100)
		pStroke.Thickness = 2

		local pName = UIHelpers.CreateLabel(pCard, string.upper(titleText), UDim2.new(1, -20, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 14)
		pName.Position = UDim2.new(0, 10, 0, 5); pName.TextXAlignment = Enum.TextXAlignment.Left

		local pDesc = UIHelpers.CreateLabel(pCard, descText or "A premium item.", UDim2.new(1, -20, 0, 20), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 11)
		pDesc.Position = UDim2.new(0, 10, 0, 25); pDesc.TextXAlignment = Enum.TextXAlignment.Left

		local btnContainer = Instance.new("Frame", pCard)
		btnContainer.Size = UDim2.new(1, -20, 0, 30)
		btnContainer.Position = UDim2.new(0, 10, 1, -35)
		btnContainer.BackgroundTransparency = 1
		local bcLayout = Instance.new("UIListLayout", btnContainer); bcLayout.FillDirection = Enum.FillDirection.Horizontal; bcLayout.Padding = UDim.new(0, 10)

		if giftAction then
			local buyBtn, buyStroke = CreateSharpButton(btnContainer, "BUY", UDim2.new(0.48, 0, 1, 0), Enum.Font.GothamBlack, 12)
			buyBtn.TextColor3 = Color3.fromRGB(85, 255, 85)
			buyStroke.Color = Color3.fromRGB(85, 255, 85)
			buyBtn.MouseButton1Click:Connect(buyAction)

			local giftBtn, giftStroke = CreateSharpButton(btnContainer, "GIFT", UDim2.new(0.48, 0, 1, 0), Enum.Font.GothamBlack, 12)
			giftBtn.TextColor3 = Color3.fromRGB(200, 100, 255)
			giftStroke.Color = Color3.fromRGB(200, 100, 255)
			giftBtn.MouseButton1Click:Connect(giftAction)
		else
			local buyBtn, buyStroke = CreateSharpButton(btnContainer, "BUY", UDim2.new(1, 0, 1, 0), Enum.Font.GothamBlack, 12)
			buyBtn.TextColor3 = Color3.fromRGB(85, 255, 85)
			buyStroke.Color = Color3.fromRGB(85, 255, 85)
			buyBtn.MouseButton1Click:Connect(buyAction)
		end
	end

	if ItemData.Gamepasses then
		for _, gp in ipairs(ItemData.Gamepasses) do
			CreatePremiumCard(gp.Name, gp.Desc, 
				function() MarketplaceService:PromptGamePassPurchase(player, gp.ID) end,
				gp.GiftID and function() MarketplaceService:PromptProductPurchase(player, gp.GiftID) end or nil
			)
		end
	end

	if ItemData.Products then
		for _, prod in ipairs(ItemData.Products) do
			if not prod.IsReroll and not string.find(prod.Name, "Gift:") then
				CreatePremiumCard(prod.Name, prod.Desc, 
					function() MarketplaceService:PromptProductPurchase(player, prod.ID) end, nil
				)
			end
		end
	end

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

	local RedeemBtn, redeemStroke = CreateSharpButton(CodeContainer, "REDEEM", UDim2.new(0.8, 0, 0, 40), Enum.Font.GothamBlack, 16)
	RedeemBtn.Position = UDim2.new(0.5, 0, 0.7, 0)
	RedeemBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	RedeemBtn.TextColor3 = Color3.fromRGB(85, 170, 255)
	redeemStroke.Color = Color3.fromRGB(85, 170, 255)

	local cHint = UIHelpers.CreateLabel(CodeContainer, "ENTER PROMO CODE:", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 12)
	cHint.Position = UDim2.new(0, 0, 1, -25)

	RedeemBtn.MouseButton1Click:Connect(function()
		if cInput.Text ~= "" then
			Network:WaitForChild("RedeemCode"):FireServer(cInput.Text)
			cInput.Text = ""
		end
	end)

	local RightPanel = Instance.new("Frame", SplitContainer)
	RightPanel.Size = UDim2.new(0.5, 0, 1, 0)
	RightPanel.BackgroundTransparency = 1

	local rrContainer = Instance.new("Frame", RightPanel)
	rrContainer.Size = UDim2.new(1, 0, 0, 45)
	rrContainer.BackgroundTransparency = 1
	local rrLayout = Instance.new("UIListLayout", rrContainer); rrLayout.FillDirection = Enum.FillDirection.Horizontal; rrLayout.Padding = UDim.new(0, 10)

	local rrDews, rrDewsStroke = CreateSharpButton(rrContainer, "RESTOCK (300K Dews)", UDim2.new(0.48, 0, 1, 0), Enum.Font.GothamBlack, 12)
	rrDews.TextColor3 = Color3.fromRGB(85, 170, 255)
	rrDewsStroke.Color = Color3.fromRGB(85, 170, 255)

	local rrPremium, rrPremStroke = CreateSharpButton(rrContainer, "RESTOCK (50 R$)", UDim2.new(0.48, 0, 1, 0), Enum.Font.GothamBlack, 12)

	local isFreeRestock = false
	local function UpdateRerollButton()
		local hasVIP = player:GetAttribute("HasVIP")
		local lastRoll = player:GetAttribute("LastFreeReroll") or 0

		if hasVIP and (os.time() - lastRoll) >= 86400 then
			rrPremium.Text = "FREE RESTOCK (VIP)"
			rrPremium.TextColor3 = Color3.fromRGB(200, 100, 255)
			rrPremStroke.Color = Color3.fromRGB(200, 100, 255)
			isFreeRestock = true
		else
			rrPremium.Text = "RESTOCK (50 R$)"
			rrPremium.TextColor3 = Color3.fromRGB(85, 255, 85)
			rrPremStroke.Color = Color3.fromRGB(85, 255, 85)
			isFreeRestock = false
		end
	end
	UpdateRerollButton()

	rrDews.MouseButton1Click:Connect(function() Network:WaitForChild("VIPFreeReroll"):FireServer(true) end)

	rrPremium.MouseButton1Click:Connect(function()
		if isFreeRestock then
			Network:WaitForChild("VIPFreeReroll"):FireServer(false)
		else
			local rerollId = nil
			if ItemData.Products then
				for _, prod in ipairs(ItemData.Products) do
					if prod.IsReroll then rerollId = prod.ID break end
				end
			end
			if rerollId then MarketplaceService:PromptProductPurchase(player, rerollId) end
		end
	end)

	local restockTimer = UIHelpers.CreateLabel(RightPanel, "RESTOCKS IN: 00:00", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBlack, Color3.fromRGB(255, 150, 100), 12)
	restockTimer.Position = UDim2.new(0, 0, 0, 50)

	local SupplyScroll = Instance.new("ScrollingFrame", RightPanel)
	SupplyScroll.Size = UDim2.new(1, 0, 1, -80)
	SupplyScroll.Position = UDim2.new(0, 0, 0, 80)
	SupplyScroll.BackgroundTransparency = 1
	SupplyScroll.ScrollBarThickness = 6
	SupplyScroll.BorderSizePixel = 0

	local ssLayout = Instance.new("UIListLayout", SupplyScroll)
	ssLayout.Padding = UDim.new(0, 8)
	ssLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() SupplyScroll.CanvasSize = UDim2.new(0,0,0, ssLayout.AbsoluteContentSize.Y + 10) end)

	local RarityColors = {
		["Common"] = Color3.fromRGB(200, 200, 200), ["Uncommon"] = Color3.fromRGB(85, 255, 85),
		["Rare"] = Color3.fromRGB(85, 85, 255), ["Epic"] = Color3.fromRGB(170, 85, 255),
		["Legendary"] = Color3.fromRGB(255, 215, 0), ["Mythical"] = Color3.fromRGB(255, 85, 85),
		["Transcendent"] = Color3.fromRGB(255, 85, 255)
	}

	local function AddSupplyItem(itemName, itemData, cost, isSoldOut)
		local rarityColor = RarityColors[itemData.Rarity or "Common"] or Color3.fromRGB(200, 200, 200)

		local c, cStroke = CreateGrimPanel(SupplyScroll)
		c.Size = UDim2.new(1, -10, 0, 70)
		cStroke.Color = rarityColor
		cStroke.Thickness = 2

		local bgGlow = Instance.new("Frame", c)
		bgGlow.Size = UDim2.new(1, 0, 1, 0)
		bgGlow.BackgroundColor3 = rarityColor
		bgGlow.BorderSizePixel = 0
		bgGlow.ZIndex = 1
		local grad = Instance.new("UIGradient", bgGlow)
		grad.Rotation = 90
		grad.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.95), NumberSequenceKeypoint.new(1, 0.7) }

		local nameLbl = UIHelpers.CreateLabel(c, itemName, UDim2.new(0.6, 0, 0, 20), Enum.Font.GothamBlack, rarityColor, 16)
		nameLbl.Position = UDim2.new(0, 15, 0, 10); nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.ZIndex = 2

		local statsTxt = ""
		if itemData.Bonus then
			for k, v in pairs(itemData.Bonus) do
				local s = tostring(k):sub(1,3):upper()
				statsTxt = statsTxt .. (v > 0 and "+" or "") .. v .. " " .. s .. " | "
			end
			statsTxt = statsTxt:sub(1, -3)
		else statsTxt = itemData.Desc or "A useful item." end

		local statsLbl = UIHelpers.CreateLabel(c, statsTxt, UDim2.new(0.6, 0, 0, 15), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 12)
		statsLbl.Position = UDim2.new(0, 15, 0, 30); statsLbl.TextXAlignment = Enum.TextXAlignment.Left; statsLbl.ZIndex = 2

		local costLbl = UIHelpers.CreateLabel(c, "Cost: " .. tostring(cost) .. " Dews", UDim2.new(0.6, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 11)
		costLbl.Position = UDim2.new(0, 15, 1, -25); costLbl.TextXAlignment = Enum.TextXAlignment.Left; costLbl.ZIndex = 2

		local actionText = isSoldOut and "SOLD" or "BUY"
		local buyBtn, buyStroke = CreateSharpButton(c, actionText, UDim2.new(0, 100, 0, 34), Enum.Font.GothamBlack, 12)
		buyBtn.Position = UDim2.new(1, -15, 0.5, 0); buyBtn.AnchorPoint = Vector2.new(1, 0.5); buyBtn.ZIndex = 3

		if isSoldOut then
			buyBtn.TextColor3 = Color3.fromRGB(100, 100, 100); buyStroke.Color = Color3.fromRGB(70, 70, 80); buyBtn.Active = false
		else
			buyBtn.TextColor3 = Color3.fromRGB(85, 255, 85); buyStroke.Color = Color3.fromRGB(85, 255, 85)
			buyBtn.MouseButton1Click:Connect(function() Network:WaitForChild("ShopAction"):FireServer("BuyItem", itemName) end)
		end
	end

	local isShopTimerActive = false
	local function RefreshShop()
		local shopData = Network:WaitForChild("GetShopData"):InvokeServer()
		if not shopData or not shopData.Items then return end

		for _, c in ipairs(SupplyScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

		for _, item in ipairs(shopData.Items) do
			local itemDef = ItemData.Equipment[item.Name] or ItemData.Consumables[item.Name]
			if itemDef then AddSupplyItem(item.Name, itemDef, item.Cost, item.SoldOut) end
		end

		local timeLeft = shopData.TimeLeft or 600

		isShopTimerActive = false 
		task.wait(1.1)
		isShopTimerActive = true

		task.spawn(function()
			while timeLeft > 0 and isShopTimerActive do
				local m = math.floor(timeLeft / 60)
				local s = timeLeft % 60
				restockTimer.Text = string.format("RESTOCKS IN: %02d:%02d", m, s)
				task.wait(1); timeLeft -= 1
			end
			if isShopTimerActive then RefreshShop() end
		end)
	end

	player.AttributeChanged:Connect(function(attr)
		if attr == "ShopPurchases_Data" or attr == "PersonalShopSeed" then RefreshShop() end
		if attr == "LastFreeReroll" or attr == "HasVIP" then UpdateRerollButton() end
	end)
	RefreshShop()

	-- ==========================================
	-- 2. THE FORGE (WITH ACTIVE STRIKING MINIGAME)
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

	-- Blueprint Info View
	local InfoView = Instance.new("Frame", BlueprintPanel)
	InfoView.Size = UDim2.new(1, 0, 1, 0)
	InfoView.BackgroundTransparency = 1

	local bpTitle = UIHelpers.CreateLabel(InfoView, "SELECT A BLUEPRINT", UDim2.new(1, -40, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 24)
	bpTitle.Position = UDim2.new(0, 20, 0, 20); bpTitle.TextXAlignment = Enum.TextXAlignment.Left

	local bpDesc = UIHelpers.CreateLabel(InfoView, "Select an item from the registry to view its crafting requirements.", UDim2.new(1, -40, 0, 40), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 14)
	bpDesc.Position = UDim2.new(0, 20, 0, 60); bpDesc.TextXAlignment = Enum.TextXAlignment.Left; bpDesc.TextWrapped = true; bpDesc.TextYAlignment = Enum.TextYAlignment.Top

	local ReqTitle = UIHelpers.CreateLabel(InfoView, "REQUIRED MATERIALS", UDim2.new(1, -40, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 16)
	ReqTitle.Position = UDim2.new(0, 20, 0, 140); ReqTitle.TextXAlignment = Enum.TextXAlignment.Left; ReqTitle.Visible = false

	local ReqList = Instance.new("Frame", InfoView)
	ReqList.Size = UDim2.new(1, -40, 0, 200)
	ReqList.Position = UDim2.new(0, 20, 0, 170)
	ReqList.BackgroundTransparency = 1
	local reqLayout = Instance.new("UIListLayout", ReqList); reqLayout.Padding = UDim.new(0, 8)

	local CraftBtn, CraftStroke = CreateSharpButton(InfoView, "FORGE EQUIPMENT", UDim2.new(0.8, 0, 0, 50), Enum.Font.GothamBlack, 18)
	CraftBtn.Position = UDim2.new(0.5, 0, 1, -30); CraftBtn.AnchorPoint = Vector2.new(0.5, 1); CraftBtn.Visible = false
	CraftBtn.TextColor3 = Color3.fromRGB(225, 185, 60)
	CraftStroke.Color = Color3.fromRGB(225, 185, 60)

	-- Minigame View
	local MinigameView = Instance.new("Frame", BlueprintPanel)
	MinigameView.Size = UDim2.new(1, 0, 1, 0)
	MinigameView.BackgroundTransparency = 1
	MinigameView.Visible = false

	local mgTitle = UIHelpers.CreateLabel(MinigameView, "ACTIVE FORGE", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, Color3.fromRGB(255, 100, 100), 24)
	mgTitle.Position = UDim2.new(0, 0, 0, 20)

	local mgInst = UIHelpers.CreateLabel(MinigameView, "Strike when the heat aligns perfectly. (0/3)", UDim2.new(1, 0, 0, 20), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 14)
	mgInst.Position = UDim2.new(0, 0, 0, 60)

	local BarContainer = Instance.new("Frame", MinigameView)
	BarContainer.Size = UDim2.new(0.8, 0, 0, 40)
	BarContainer.Position = UDim2.new(0.5, 0, 0.4, 0)
	BarContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	BarContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	local bcStroke = Instance.new("UIStroke", BarContainer); bcStroke.Color = UIHelpers.Colors.BorderMuted; bcStroke.Thickness = 2

	local SweetSpot = Instance.new("Frame", BarContainer)
	SweetSpot.Size = UDim2.new(0.15, 0, 1, 0)
	SweetSpot.Position = UDim2.new(0.425, 0, 0, 0)
	SweetSpot.BackgroundColor3 = Color3.fromRGB(85, 255, 85)
	SweetSpot.BorderSizePixel = 0

	local Cursor = Instance.new("Frame", BarContainer)
	Cursor.Size = UDim2.new(0.02, 0, 1.4, 0)
	Cursor.Position = UDim2.new(0, 0, 0.5, 0)
	Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
	Cursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Cursor.BorderSizePixel = 0

	local StrikeBtn, StrikeStroke = CreateSharpButton(MinigameView, "STRIKE", UDim2.new(0.5, 0, 0, 60), Enum.Font.GothamBlack, 22)
	StrikeBtn.Position = UDim2.new(0.5, 0, 0.8, 0)
	StrikeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	StrikeBtn.TextColor3 = Color3.fromRGB(255, 85, 85)
	StrikeStroke.Color = Color3.fromRGB(255, 85, 85)

	local mgActive = false
	local mgConn = nil
	local strikes = 0
	local totalAccuracy = 0

	local function EndMinigame()
		mgActive = false
		if mgConn then mgConn:Disconnect() mgConn = nil end

		local finalQuality = "Standard"
		local avg = totalAccuracy / 3
		if avg >= 0.85 then finalQuality = "Flawless"
		elseif avg >= 0.5 then finalQuality = "Masterwork" end

		mgInst.Text = "Forge Complete! Quality: " .. finalQuality
		task.wait(1.5)
		MinigameView.Visible = false
		InfoView.Visible = true

		Network:WaitForChild("ForgeAction"):FireServer("Craft", bpTitle.Text, finalQuality)
	end

	StrikeBtn.MouseButton1Click:Connect(function()
		if not mgActive then return end
		local cursorPos = Cursor.Position.X.Scale
		local targetCenter = 0.5
		local dist = math.abs(cursorPos - targetCenter)

		local accuracy = math.clamp(1 - (dist / 0.15), 0, 1)
		totalAccuracy += accuracy
		strikes += 1

		mgInst.Text = "Strike when the heat aligns perfectly. (" .. strikes .. "/3)"

		if strikes >= 3 then
			EndMinigame()
		else
			mgActive = false
			task.wait(0.5)
			mgActive = true
		end
	end)

	CraftBtn.MouseButton1Click:Connect(function()
		InfoView.Visible = false
		MinigameView.Visible = true
		strikes = 0
		totalAccuracy = 0
		mgInst.Text = "Strike when the heat aligns perfectly. (0/3)"
		mgActive = true

		local speed = 2.5
		local t = 0
		if mgConn then mgConn:Disconnect() end
		mgConn = RunService.RenderStepped:Connect(function(dt)
			if mgActive then
				t += dt * (speed + (strikes * 0.5))
				local pos = (math.sin(t) + 1) / 2
				Cursor.Position = UDim2.new(pos, 0, 0.5, 0)
			end
		end)
	end)

	for rec, _ in pairs(ItemData.ForgeRecipes or {}) do
		local rBtn, _ = CreateSharpButton(RecipeList, rec, UDim2.new(1, -10, 0, 45), Enum.Font.GothamBold, 12)
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
	-- 3. TITAN FUSION
	-- ==========================================
	local FusionTab = activeSubFrames["TITAN FUSION"]

	local fTitle = UIHelpers.CreateLabel(FusionTab, "TITAN HYBRIDIZATION", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, Color3.fromRGB(170, 85, 255), 26)
	fTitle.Position = UDim2.new(0, 0, 0, 10)

	local fDesc = UIHelpers.CreateLabel(FusionTab, "Fuse two Pure Titans with Abyssal Blood to create a horrific Hybrid. This action is irreversible.", UDim2.new(1, 0, 0, 20), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 14)
	fDesc.Position = UDim2.new(0, 0, 0, 50)

	local SlotContainer = Instance.new("Frame", FusionTab)
	SlotContainer.Size = UDim2.new(0.8, 0, 0, 250)
	SlotContainer.Position = UDim2.new(0.5, 0, 0.40, 0)
	SlotContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	SlotContainer.BackgroundTransparency = 1

	local function CreateFusionSlot(pos, titleText, colorHex, isResult)
		local f, fStroke = CreateGrimPanel(SlotContainer)
		f.Size = UDim2.new(0, 200, 0, 200)
		f.Position = pos
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		fStroke.Color = Color3.fromHex(colorHex)

		local t = UIHelpers.CreateLabel(f, titleText, UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, Color3.fromHex(colorHex), 14)
		t.Position = UDim2.new(0, 10, 0, 10)
		t.TextScaled = true
		local tCon = Instance.new("UITextSizeConstraint", t)
		tCon.MaxTextSize = 14
		tCon.MinTextSize = 8

		if isResult then
			local qLbl = UIHelpers.CreateLabel(f, "?", UDim2.new(1, 0, 1, -40), Enum.Font.GothamBlack, Color3.fromHex(colorHex), 60)
			qLbl.Position = UDim2.new(0, 0, 0, 40)
			return f, t, qLbl, nil
		end

		local addBtn, addStroke = CreateSharpButton(f, "+", UDim2.new(0, 60, 0, 60), Enum.Font.GothamBlack, 28)
		addBtn.Position = UDim2.new(0.5, 0, 0.5, 15)
		addBtn.AnchorPoint = Vector2.new(0.5, 0.5)

		local overBtn = Instance.new("TextButton", f)
		overBtn.Size = UDim2.new(1, 0, 1, 0)
		overBtn.BackgroundTransparency = 1
		overBtn.Text = ""
		overBtn.ZIndex = 10

		overBtn.MouseEnter:Connect(function()
			fStroke.Color = UIHelpers.Colors.Gold
			t.TextColor3 = UIHelpers.Colors.Gold
			if addBtn.Visible then
				addStroke.Color = UIHelpers.Colors.Gold
				addBtn.TextColor3 = UIHelpers.Colors.Gold
			end
		end)

		overBtn.MouseLeave:Connect(function()
			fStroke.Color = Color3.fromHex(colorHex)
			t.TextColor3 = Color3.fromHex(colorHex)
			if addBtn.Visible then
				addStroke.Color = Color3.fromRGB(70, 70, 80)
				addBtn.TextColor3 = Color3.fromRGB(245, 245, 245)
			end
		end)

		return f, t, addBtn, overBtn
	end

	local Slot1, Slot1Title, Slot1AddBtn, Slot1OverBtn = CreateFusionSlot(UDim2.new(0.15, 0, 0.5, 0), "SUBJECT ALPHA", "55AAFF", false)
	local Slot2, Slot2Title, Slot2AddBtn, Slot2OverBtn = CreateFusionSlot(UDim2.new(0.85, 0, 0.5, 0), "SUBJECT OMEGA", "FF5555", false)
	local ResultSlot, ResultTitle, ResultLbl = CreateFusionSlot(UDim2.new(0.5, 0, 0.5, 0), "HYBRIDIZATION", "AA55FF", true)

	local line1 = Instance.new("Frame", SlotContainer); line1.Size = UDim2.new(0, 120, 0, 4); line1.Position = UDim2.new(0.32, 0, 0.5, 0); line1.AnchorPoint=Vector2.new(0.5, 0.5); line1.BackgroundColor3 = Color3.fromRGB(170, 85, 255); line1.BorderSizePixel=0
	local line2 = Instance.new("Frame", SlotContainer); line2.Size = UDim2.new(0, 120, 0, 4); line2.Position = UDim2.new(0.68, 0, 0.5, 0); line2.AnchorPoint=Vector2.new(0.5, 0.5); line2.BackgroundColor3 = Color3.fromRGB(170, 85, 255); line2.BorderSizePixel=0

	local FuseBtn, FuseStroke = CreateSharpButton(FusionTab, "INITIATE FUSION (300,000 DEWS)", UDim2.new(0, 400, 0, 55), Enum.Font.GothamBlack, 18)
	FuseBtn.Position = UDim2.new(0.5, 0, 1, -20)
	FuseBtn.AnchorPoint = Vector2.new(0.5, 1)
	FuseBtn.TextColor3 = Color3.fromRGB(170, 85, 255)
	FuseStroke.Color = Color3.fromRGB(170, 85, 255)

	local PopupOverlay = Instance.new("Frame", MainFrame)
	PopupOverlay.Size = UDim2.new(1, 0, 1, 0)
	PopupOverlay.BackgroundColor3 = Color3.new(0,0,0)
	PopupOverlay.BackgroundTransparency = 0.6
	PopupOverlay.ZIndex = 50
	PopupOverlay.Visible = false
	PopupOverlay.Active = true

	local PopupPanel, _ = CreateGrimPanel(PopupOverlay)
	PopupPanel.Size = UDim2.new(0, 400, 0, 500)
	PopupPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	PopupPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	PopupPanel.ZIndex = 51

	local popTitle = UIHelpers.CreateLabel(PopupPanel, "SELECT A TITAN", UDim2.new(1, 0, 0, 50), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 20)
	popTitle.ZIndex = 52

	local closeBtn, _ = CreateSharpButton(PopupPanel, "X", UDim2.new(0, 40, 0, 40), Enum.Font.GothamBlack, 18)
	closeBtn.Position = UDim2.new(1, -10, 0, 10)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	closeBtn.ZIndex = 52
	closeBtn.MouseButton1Click:Connect(function() PopupOverlay.Visible = false end)

	local TitanScroll = Instance.new("ScrollingFrame", PopupPanel)
	TitanScroll.Size = UDim2.new(1, -20, 1, -70)
	TitanScroll.Position = UDim2.new(0, 10, 0, 60)
	TitanScroll.BackgroundTransparency = 1
	TitanScroll.ScrollBarThickness = 6
	TitanScroll.BorderSizePixel = 0
	TitanScroll.ZIndex = 52

	local tsLayout = Instance.new("UIListLayout", TitanScroll)
	tsLayout.Padding = UDim.new(0, 10)
	tsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() TitanScroll.CanvasSize = UDim2.new(0,0,0, tsLayout.AbsoluteContentSize.Y + 10) end)

	local noTitansLbl = UIHelpers.CreateLabel(PopupPanel, "No Titans found in Vault.", UDim2.new(1, 0, 0, 50), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 14)
	noTitansLbl.Position = UDim2.new(0, 0, 0.5, 0)
	noTitansLbl.AnchorPoint = Vector2.new(0, 0.5)
	noTitansLbl.ZIndex = 52

	local selectedAlpha = nil
	local selectedOmega = nil
	local activeSlotIndex = 1

	local function UpdateFusionUI()
		if selectedAlpha then
			Slot1Title.Text = string.upper(selectedAlpha.Name)
			Slot1AddBtn.Visible = false
		else
			Slot1Title.Text = "SUBJECT ALPHA"
			Slot1AddBtn.Visible = true
		end

		if selectedOmega then
			Slot2Title.Text = string.upper(selectedOmega.Name)
			Slot2AddBtn.Visible = false
		else
			Slot2Title.Text = "SUBJECT OMEGA"
			Slot2AddBtn.Visible = true
		end
	end

	local function OpenTitanSelection(slotId)
		activeSlotIndex = slotId
		PopupOverlay.Visible = true
		for _, c in ipairs(TitanScroll:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end

		local foundAny = false
		for i = 1, 6 do
			local tName = player:GetAttribute("Titan_Slot" .. i)
			if tName and tName ~= "" and tName ~= "None" then
				if (slotId == 1 and selectedOmega and selectedOmega.Slot == i) or (slotId == 2 and selectedAlpha and selectedAlpha.Slot == i) then
					continue 
				end

				foundAny = true

				local rarityColor = Color3.fromRGB(200, 200, 200)
				if TitanData.Titans[tName] then
					local tRarity = TitanData.Titans[tName].Rarity
					local RarityColors = {
						["Common"] = Color3.fromRGB(200, 200, 200), ["Uncommon"] = Color3.fromRGB(85, 255, 85),
						["Rare"] = Color3.fromRGB(85, 85, 255), ["Epic"] = Color3.fromRGB(170, 85, 255),
						["Legendary"] = Color3.fromRGB(255, 215, 0), ["Mythical"] = Color3.fromRGB(255, 85, 85),
						["Transcendent"] = Color3.fromRGB(255, 85, 255)
					}
					rarityColor = RarityColors[tRarity] or rarityColor
				end

				local tBtn, tBtnStroke = CreateSharpButton(TitanScroll, "SLOT " .. i .. ": " .. string.upper(tName), UDim2.new(1, -10, 0, 50), Enum.Font.GothamBlack, 14)
				tBtn.ZIndex = 53
				tBtn.TextColor3 = rarityColor
				tBtnStroke.Color = rarityColor

				tBtn.MouseButton1Click:Connect(function()
					if activeSlotIndex == 1 then
						selectedAlpha = {Slot = i, Name = tName}
					else
						selectedOmega = {Slot = i, Name = tName}
					end
					PopupOverlay.Visible = false
					UpdateFusionUI()
				end)
			end
		end

		noTitansLbl.Visible = not foundAny
	end

	Slot1OverBtn.MouseButton1Click:Connect(function() OpenTitanSelection(1) end)
	Slot2OverBtn.MouseButton1Click:Connect(function() OpenTitanSelection(2) end)

	FuseBtn.MouseButton1Click:Connect(function()
		if not selectedAlpha or not selectedOmega then
			local Notif = Network:FindFirstChild("NotificationEvent")
			if Notif then Notif:FireClient(player, "Requires two Subjects to initiate Fusion.", "Error") end
			return
		end

		Network:WaitForChild("TitanAction"):FireServer("FuseTitans", selectedAlpha.Slot, selectedOmega.Slot)

		selectedAlpha = nil
		selectedOmega = nil
		UpdateFusionUI()
	end)

end

return SupplyForgeTab