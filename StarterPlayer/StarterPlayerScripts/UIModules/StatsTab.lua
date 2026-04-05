-- @ScriptType: ModuleScript
-- Name: StatsTab
-- @ScriptType: ModuleScript
local StatsTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

local notifModule = script.Parent:WaitForChild("NotificationManager", 2)
local NotificationManager = notifModule and require(notifModule) or nil
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))

local player = Players.LocalPlayer
local MainFrame
local cachedTooltipMgr

local playerStatsList = {"Health", "Strength", "Defense", "Speed", "Gas", "Resolve"}
local titanStatsList = {"Titan_Power_Val", "Titan_Speed_Val", "Titan_Hardening_Val", "Titan_Endurance_Val", "Titan_Precision_Val", "Titan_Potential_Val"}
local statRowRefs = {}
local humanCombo = 0
local titanCombo = 0

local Suffixes = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx"}
local function AbbreviateNumber(n)
	if not n then return "0" end; n = tonumber(n) or 0
	if n < 1000 then return tostring(math.floor(n)) end
	local suffixIndex = math.floor(math.log10(n) / 3); local value = n / (10 ^ (suffixIndex * 3))
	local str = string.format("%.1f", value); str = str:gsub("%.0$", "")
	return str .. (Suffixes[suffixIndex + 1] or "")
end

-- [[ THE FIX 1: Decoupled math functions guarantee the UI never throws a 'nil' error during calculation ]]
local function SafeGetStatCap(prestige)
	return 100 + ((prestige or 0) * 10)
end

local function SafeCalculateStatCost(currentStat, baseStat, prestige)
	local baseCost = 10
	local growthFactor = 1.05
	local prestigeMultiplier = math.max(0.1, 1 - ((prestige or 0) * 0.03))
	local statDifference = math.max(0, (currentStat or 10) - (baseStat or 10))
	return math.floor(baseCost * (growthFactor ^ statDifference) * prestigeMultiplier)
end

local function ParseStat(rawStat)
	local val = tonumber(rawStat)
	if val then return val end
	if type(rawStat) == "string" and GameData.TitanRanks and GameData.TitanRanks[rawStat] then
		return GameData.TitanRanks[rawStat]
	end
	return 10
end

local function GetCombinedBonus(statName)
	local wpn = player:GetAttribute("EquippedWeapon") or "None"
	local acc = player:GetAttribute("EquippedAccessory") or "None"
	local style = player:GetAttribute("FightingStyle") or "None"
	local bonus = 0
	if ItemData.Equipment and ItemData.Equipment[wpn] and ItemData.Equipment[wpn].Bonus and ItemData.Equipment[wpn].Bonus[statName] then bonus += ItemData.Equipment[wpn].Bonus[statName] end
	if ItemData.Equipment and ItemData.Equipment[acc] and ItemData.Equipment[acc].Bonus and ItemData.Equipment[acc].Bonus[statName] then bonus += ItemData.Equipment[acc].Bonus[statName] end
	if GameData.WeaponBonuses and GameData.WeaponBonuses[style] and GameData.WeaponBonuses[style][statName] then bonus += GameData.WeaponBonuses[style][statName] end
	return bonus
end

local function GetUpgradeCosts(currentStat, cleanName, prestige)
	local base = (prestige == 0) and (GameData.BaseStats and GameData.BaseStats[cleanName] or 10) or (prestige * 5)
	return SafeCalculateStatCost(currentStat, base, prestige)
end

local function CreateStatRow(statName, parent, isTitan, layoutOrder, amtInput)
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1, 0, 0, 35); row.BackgroundTransparency = 1; row.LayoutOrder = layoutOrder

	local statLabel = UIHelpers.CreateLabel(row, "", UDim2.new(0.38, 0, 1, 0), Enum.Font.GothamBold, isTitan and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(220, 220, 220), 13)
	statLabel.TextXAlignment = Enum.TextXAlignment.Left; statLabel.RichText = true; statLabel.TextScaled = true; Instance.new("UITextSizeConstraint", statLabel).MaxTextSize = 13

	local btnContainer = Instance.new("Frame", row)
	btnContainer.Size = UDim2.new(0.62, 0, 1, 0); btnContainer.Position = UDim2.new(1, 0, 0, 0); btnContainer.AnchorPoint = Vector2.new(1, 0); btnContainer.BackgroundTransparency = 1
	local blL = Instance.new("UIListLayout", btnContainer); blL.FillDirection = Enum.FillDirection.Horizontal; blL.HorizontalAlignment = Enum.HorizontalAlignment.Right; blL.VerticalAlignment = Enum.VerticalAlignment.Center; blL.Padding = UDim.new(0.04, 0)

	local bAdd, addStroke = UIHelpers.CreateButton(btnContainer, "+", UDim2.new(0.35, 0, 0.85, 0), Enum.Font.GothamBlack, 12)
	local bMax, maxStroke = UIHelpers.CreateButton(btnContainer, "MAX", UDim2.new(0.55, 0, 0.85, 0), Enum.Font.GothamBlack, 12)

	local isUpgrading = false
	local function TryUpgrade(amt)
		if isUpgrading then return end
		isUpgrading = true

		local prestige = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige") and player.leaderstats.Prestige.Value or 0
		local statCap = SafeGetStatCap(prestige)

		local currentStat = ParseStat(player:GetAttribute(statName))
		local currentXP = isTitan and (tonumber(player:GetAttribute("TitanXP")) or 0) or (tonumber(player:GetAttribute("XP")) or 0)
		local cleanName = statName:gsub("_Val", ""):gsub("Titan_", "")
		local base = (prestige == 0) and (GameData.BaseStats and GameData.BaseStats[cleanName] or 10) or (prestige * 5)

		if currentStat >= statCap then isUpgrading = false; return end

		local cost, added, simulatedXP = 0, 0, currentXP
		local target = (amt == "MAX") and 9999 or tonumber(amt) or 1

		for i = 0, target - 1 do
			if currentStat + added >= statCap then break end
			local stepCost = SafeCalculateStatCost(currentStat + added, base, prestige)
			if simulatedXP >= stepCost then 
				simulatedXP -= stepCost; cost += stepCost; added += 1 
			else 
				break 
			end
		end

		-- [[ THE FIX 2: Chunk the MAX upgrades so the server doesn't reject massive single requests! ]]
		if added > 0 then
			task.spawn(function()
				local remaining = added
				while remaining > 0 do
					local chunk = math.min(remaining, 50)
					Network:WaitForChild("UpgradeStat"):FireServer(statName, chunk)
					remaining -= chunk
					if remaining > 0 then task.wait(0.05) end
				end
				if NotificationManager then NotificationManager.Show(cleanName:upper() .. " upgraded by +" .. added .. "!", "Success") end
				task.wait(0.15)
				isUpgrading = false
			end)
		else
			if NotificationManager then NotificationManager.Show("Not enough XP!", "Error") end
			isUpgrading = false
		end
	end

	bAdd.MouseButton1Down:Connect(function() local customAmt = tonumber(amtInput.Text) or 1; if customAmt < 1 then customAmt = 1 end; TryUpgrade(math.floor(customAmt)) end)
	bMax.MouseButton1Down:Connect(function() TryUpgrade("MAX") end)
	statRowRefs[statName] = { Label = statLabel, BtnContainer = btnContainer, BtnAdd = bAdd, AddStroke = addStroke, BtnMax = bMax, MaxStroke = maxStroke }
end

function StatsTab.Init(parentFrame, tooltipMgr)
	cachedTooltipMgr = tooltipMgr
	MainFrame = Instance.new("ScrollingFrame", parentFrame)
	MainFrame.Name = "StatsFrame"; MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1; MainFrame.Visible = true; MainFrame.ScrollBarThickness = 0; MainFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local mainLayout = Instance.new("UIListLayout", MainFrame); mainLayout.Padding = UDim.new(0, 15); mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; mainLayout.SortOrder = Enum.SortOrder.LayoutOrder; mainLayout.FillDirection = Enum.FillDirection.Vertical 
	local padding = Instance.new("UIPadding", MainFrame); padding.PaddingTop = UDim.new(0, 10); padding.PaddingBottom = UDim.new(0, 20)

	local ColumnsContainer = Instance.new("Frame", MainFrame)
	ColumnsContainer.Size = UDim2.new(1, 0, 0, 0); ColumnsContainer.AutomaticSize = Enum.AutomaticSize.Y; ColumnsContainer.BackgroundTransparency = 1; ColumnsContainer.LayoutOrder = 1
	local ccLayout = Instance.new("UIListLayout", ColumnsContainer); ccLayout.FillDirection = Enum.FillDirection.Horizontal; ccLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; ccLayout.Padding = UDim.new(0.04, 0)

	local function SetupPanel(titleTxt, statList, isTitan, parent)
		local panel = Instance.new("Frame", parent)
		panel.Size = UDim2.new(0.48, 0, 0, 0); panel.AutomaticSize = Enum.AutomaticSize.Y
		UIHelpers.ApplyGrimPanel(panel, false)

		local pLayout = Instance.new("UIListLayout", panel); pLayout.SortOrder = Enum.SortOrder.LayoutOrder; pLayout.Padding = UDim.new(0, 5); pLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		local pPad = Instance.new("UIPadding", panel); pPad.PaddingTop = UDim.new(0, 10); pPad.PaddingBottom = UDim.new(0, 15)

		local header = Instance.new("Frame", panel); header.Size = UDim2.new(1, -10, 0, 30); header.BackgroundTransparency = 1; header.LayoutOrder = 1
		local title = UIHelpers.CreateLabel(header, titleTxt, UDim2.new(0.5, 0, 1, 0), Enum.Font.GothamBlack, isTitan and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(200, 200, 220), 16)
		title.TextXAlignment = Enum.TextXAlignment.Left

		local controls = Instance.new("Frame", header); controls.Size = UDim2.new(0.5, 0, 1, 0); controls.Position = UDim2.new(0.5, 0, 0, 0); controls.BackgroundTransparency = 1
		local cLayout = Instance.new("UIListLayout", controls); cLayout.FillDirection = Enum.FillDirection.Horizontal; cLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right; cLayout.VerticalAlignment = Enum.VerticalAlignment.Center; cLayout.Padding = UDim.new(0, 5)

		local allBtn, _ = UIHelpers.CreateButton(controls, "ALL", UDim2.new(0.4, 0, 0.8, 0), Enum.Font.GothamBold, 11)

		local amtInput = Instance.new("TextBox", controls); amtInput.Size = UDim2.new(0.3, 0, 0.8, 0); amtInput.Text = "1"; amtInput.Font = Enum.Font.GothamBold; amtInput.TextColor3 = Color3.new(1,1,1); amtInput.TextSize = 11
		UIHelpers.ApplyGrimPanel(amtInput, false)

		local ptsLbl = UIHelpers.CreateLabel(controls, "0 XP", UDim2.new(0.4, 0, 0.8, 0), Enum.Font.GothamMedium, isTitan and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100), 11)
		ptsLbl.TextXAlignment = Enum.TextXAlignment.Right

		local list = Instance.new("Frame", panel); list.Size = UDim2.new(1, -20, 0, 0); list.AutomaticSize = Enum.AutomaticSize.Y; list.BackgroundTransparency = 1; list.LayoutOrder = 2
		local lLayout = Instance.new("UIListLayout", list); lLayout.SortOrder = Enum.SortOrder.LayoutOrder; lLayout.Padding = UDim.new(0, 8)

		for i, s in ipairs(statList) do CreateStatRow(s, list, isTitan, i, amtInput) end

		local isSpammingAll = false
		allBtn.MouseButton1Down:Connect(function()
			if isSpammingAll then return end
			isSpammingAll = true

			local prestige = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige") and player.leaderstats.Prestige.Value or 0
			local statCap = SafeGetStatCap(prestige)
			local currentXP = isTitan and (tonumber(player:GetAttribute("TitanXP")) or 0) or (tonumber(player:GetAttribute("XP")) or 0)
			local simXP = currentXP

			local tallies = {}; local simStats = {}
			for _, s in ipairs(statList) do
				tallies[s] = 0
				simStats[s] = ParseStat(player:GetAttribute(s))
			end

			local totalUpgrades = 0
			while true do
				local upgradedAny = false
				for _, s in ipairs(statList) do
					local cleanName = s:gsub("_Val", ""):gsub("Titan_", "")
					local base = (prestige == 0) and (GameData.BaseStats and GameData.BaseStats[cleanName] or 10) or (prestige * 5)
					if simStats[s] < statCap then
						local cost = SafeCalculateStatCost(simStats[s], base, prestige)
						if simXP >= cost then 
							simXP -= cost; simStats[s] += 1; tallies[s] += 1; upgradedAny = true; totalUpgrades += 1 
						end
					end
				end
				if not upgradedAny then break end
			end

			-- [[ THE FIX 3: Wait intervals between specific stat upgrades so server doesn't reject concurrent calls! ]]
			if totalUpgrades > 0 then
				task.spawn(function()
					for s, amt in pairs(tallies) do 
						if amt > 0 then 
							local remaining = amt
							while remaining > 0 do
								local chunk = math.min(remaining, 50)
								Network:WaitForChild("UpgradeStat"):FireServer(s, chunk)
								remaining -= chunk
								task.wait(0.05) 
							end
						end 
					end
					if NotificationManager then NotificationManager.Show("Distributed " .. totalUpgrades .. " points evenly!", "Success") end
					task.wait(0.25)
					isSpammingAll = false
				end)
			else
				if NotificationManager then NotificationManager.Show("Not enough XP to upgrade anything!", "Error") end
				isSpammingAll = false
			end
		end)

		return { Panel = panel, PtsLbl = ptsLbl }
	end

	local soldierData = SetupPanel("SOLDIER VITALITY", playerStatsList, false, ColumnsContainer)
	local titanData = SetupPanel("TITAN POTENTIAL", titanStatsList, true, ColumnsContainer)

	local TrainContainer = Instance.new("Frame", MainFrame)
	TrainContainer.Size = UDim2.new(1, 0, 0, 180); TrainContainer.BackgroundTransparency = 1; TrainContainer.LayoutOrder = 2
	local tcLayout = Instance.new("UIListLayout", TrainContainer); tcLayout.FillDirection = Enum.FillDirection.Horizontal; tcLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; tcLayout.Padding = UDim.new(0.04, 0)

	local function CreateTrainBox(isTitan)
		local box = Instance.new("Frame", TrainContainer)
		box.Size = UDim2.new(0.48, 0, 1, 0)
		box.ClipsDescendants = true
		UIHelpers.ApplyGrimPanel(box, false)

		local title = UIHelpers.CreateLabel(box, isTitan and "TITAN TRAINING" or "SOLDIER TRAINING", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, isTitan and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(200, 200, 220), 16)
		title.Position = UDim2.new(0, 10, 0, 10); title.TextXAlignment = Enum.TextXAlignment.Left; title.ZIndex = 2

		local comboLbl = UIHelpers.CreateLabel(box, "", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, isTitan and Color3.fromRGB(255, 150, 100) or Color3.fromRGB(150, 255, 100), 18)
		comboLbl.Position = UDim2.new(0, 10, 0, 40); comboLbl.TextXAlignment = Enum.TextXAlignment.Left; comboLbl.Visible = false; comboLbl.RichText = true; comboLbl.ZIndex = 2

		local missBtn = Instance.new("TextButton", box)
		missBtn.Size = UDim2.new(1, 0, 1, 0); missBtn.BackgroundTransparency = 1; missBtn.Text = ""; missBtn.ZIndex = 1

		local tBtn, _ = UIHelpers.CreateButton(box, isTitan and "TRAIN TITAN" or "TRAIN SOLDIER", UDim2.new(0.4, 0, 0, 50), Enum.Font.GothamBlack, 14)
		tBtn.AnchorPoint = Vector2.new(0.5, 0.5); tBtn.Position = UDim2.new(0.5, 0, 0.6, 0); tBtn.TextScaled = true; tBtn.ZIndex = 3
		Instance.new("UITextSizeConstraint", tBtn).MaxTextSize = 14

		if isTitan then tBtn.TextColor3 = Color3.fromRGB(255, 100, 100) else tBtn.TextColor3 = Color3.fromRGB(100, 255, 100) end

		local function CreateFloatingText(textStr, color, startPos)
			local fTxt = UIHelpers.CreateLabel(box, textStr, UDim2.new(0, 100, 0, 30), Enum.Font.GothamBlack, color, 24)
			fTxt.Position = startPos; fTxt.AnchorPoint = Vector2.new(0.5, 0.5); fTxt.ZIndex = 4
			TweenService:Create(fTxt, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = fTxt.Position - UDim2.new(0, 0, 0.3, 0), TextTransparency = 1}):Play()
			game.Debris:AddItem(fTxt, 0.6)
		end

		tBtn.MouseButton1Down:Connect(function()
			local currentPos = tBtn.Position
			if isTitan then titanCombo += 1 else humanCombo += 1 end
			local activeCombo = isTitan and titanCombo or humanCombo

			if activeCombo > 1 then 
				comboLbl.TextColor3 = isTitan and Color3.fromRGB(255, 150, 100) or Color3.fromRGB(150, 255, 100)
				comboLbl.Visible = true
				comboLbl.Text = "x" .. activeCombo .. " COMBO!" 
			end

			local prestige = player:WaitForChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige") and player.leaderstats.Prestige.Value or 0
			local totalStats = (player:GetAttribute("Strength") or 10) + (player:GetAttribute("Defense") or 10) + (player:GetAttribute("Speed") or 10) + (player:GetAttribute("Resolve") or 10)
			local baseXP = 1 + (prestige * 50) + math.floor(totalStats / 4)
			local xpGain = math.floor(baseXP * (1.0 + (activeCombo * 0.1)))

			CreateFloatingText("+" .. xpGain .. (isTitan and " T-XP" or " XP"), Color3.fromRGB(100, 255, 100), currentPos)
			tBtn.Position = UDim2.new(math.random(25, 75)/100, 0, math.random(30, 80)/100, 0)
			Network.TrainAction:FireServer(activeCombo, isTitan)
		end)

		missBtn.MouseButton1Down:Connect(function()
			if isTitan and titanCombo > 0 then
				titanCombo = 0; comboLbl.Visible = true; comboLbl.Text = "<font color='#FF5555'>COMBO DROPPED!</font>"
				task.delay(1.5, function() if titanCombo == 0 then comboLbl.Visible = false end end)
			elseif not isTitan and humanCombo > 0 then
				humanCombo = 0; comboLbl.Visible = true; comboLbl.Text = "<font color='#FF5555'>COMBO DROPPED!</font>"
				task.delay(1.5, function() if humanCombo == 0 then comboLbl.Visible = false end end)
			end
		end)
		return box
	end

	local soldierBox = CreateTrainBox(false)
	local titanBox = CreateTrainBox(true)

	local function UpdateStats()
		local prestigeObj = player:WaitForChild("leaderstats", 5) and player.leaderstats:FindFirstChild("Prestige")
		local prestige = prestigeObj and prestigeObj.Value or 0
		local hXP = tonumber(player:GetAttribute("XP")) or 0
		local tXP = tonumber(player:GetAttribute("TitanXP")) or 0
		local statCap = SafeGetStatCap(prestige)

		soldierData.PtsLbl.Text = AbbreviateNumber(hXP) .. " XP"
		titanData.PtsLbl.Text = AbbreviateNumber(tXP) .. " T-XP"

		local allStats = {}
		for _, s in ipairs(playerStatsList) do table.insert(allStats, s) end
		for _, s in ipairs(titanStatsList) do table.insert(allStats, s) end

		for _, statName in ipairs(allStats) do
			local cleanName = statName:gsub("_Val", ""):gsub("Titan_", "")
			local data = statRowRefs[statName]
			local isTitanStat = table.find(titanStatsList, statName) ~= nil
			local val = ParseStat(player:GetAttribute(statName)) 

			local cost1 = GetUpgradeCosts(val, cleanName, prestige)
			local bonusAmount = GetCombinedBonus(cleanName)
			local bonusText = bonusAmount > 0 and " <font color='#55FF55'>(+" .. bonusAmount .. ")</font>" or ""

			if val >= statCap then
				data.Label.Text = cleanName .. ": <font color='" .. (isTitanStat and "#FF5555" or "#FFFFFF") .. "'>" .. val .. "</font>" .. bonusText .. " <font color='#FF5555'>[MAX]</font>"
				data.BtnAdd.TextColor3 = UIHelpers.Colors.BorderMuted; data.AddStroke.Color = UIHelpers.Colors.BorderMuted
				data.BtnMax.TextColor3 = UIHelpers.Colors.BorderMuted; data.MaxStroke.Color = UIHelpers.Colors.BorderMuted
			else
				data.Label.Text = cleanName .. ": <font color='" .. (isTitanStat and "#FF5555" or "#FFFFFF") .. "'>" .. val .. "</font>" .. bonusText
				local function toggle(btn, stroke, canAfford)
					if canAfford then btn.TextColor3 = UIHelpers.Colors.TextWhite; stroke.Color = UIHelpers.Colors.BorderMuted
					else btn.TextColor3 = UIHelpers.Colors.BorderMuted; stroke.Color = Color3.fromRGB(40, 40, 50) end
				end
				toggle(data.BtnAdd, data.AddStroke, (isTitanStat and tXP or hXP) >= cost1)
				toggle(data.BtnMax, data.MaxStroke, (isTitanStat and tXP or hXP) >= cost1)
			end
		end
		task.delay(0.05, function() MainFrame.CanvasSize = UDim2.new(0, 0, 0, mainLayout.AbsoluteContentSize.Y + 20) end)
	end

	player.AttributeChanged:Connect(function(attr) if table.find(playerStatsList, attr) or table.find(titanStatsList, attr) or attr == "XP" or attr == "TitanXP" or attr == "Titan" then UpdateStats() end end)

	task.spawn(function()
		local ls = player:WaitForChild("leaderstats", 10)
		if ls and ls:FindFirstChild("Prestige") then ls.Prestige.Changed:Connect(UpdateStats) end
	end)
	UpdateStats()
end

function StatsTab.Show() if MainFrame then MainFrame.Visible = true end end
return StatsTab