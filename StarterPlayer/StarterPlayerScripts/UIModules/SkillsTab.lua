-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: SkillsTab
local SkillsTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")

local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local hasSkillData, SkillData = pcall(function() return require(ReplicatedStorage:WaitForChild("SkillData")) end)

local player = Players.LocalPlayer
local MainFrame, TopLoadoutGrid, SkillLibraryScroll
local SkillSlotLabels = {}

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

function SkillsTab.Initialize(parentFrame)
	MainFrame = Instance.new("Frame", parentFrame)
	MainFrame.Size = UDim2.new(1, 0, 1, 0)
	MainFrame.BackgroundTransparency = 1
	MainFrame.Visible = true

	local mLayout = Instance.new("UIListLayout", MainFrame)
	mLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mLayout.Padding = UDim.new(0, 15)
	mLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local mPad = Instance.new("UIPadding", MainFrame)
	mPad.PaddingTop = UDim.new(0, 15)

	-- [[ TOP: ACTIVE LOADOUT ]]
	local HeaderContainer = Instance.new("Frame", MainFrame)
	HeaderContainer.Size = UDim2.new(0.95, 0, 0, 130)
	HeaderContainer.BackgroundTransparency = 1
	HeaderContainer.LayoutOrder = 1

	local HeaderLabel = CreateSharpLabel(HeaderContainer, "ACTIVE LOADOUT", UDim2.new(1, 0, 0, 20), Enum.Font.GothamBlack, Color3.fromRGB(225, 185, 60), 16)
	HeaderLabel.TextXAlignment = Enum.TextXAlignment.Left

	TopLoadoutGrid = Instance.new("Frame", HeaderContainer)
	TopLoadoutGrid.Size = UDim2.new(1, 0, 0, 95)
	TopLoadoutGrid.Position = UDim2.new(0, 0, 0, 30)
	TopLoadoutGrid.BackgroundTransparency = 1

	local lgLayout = Instance.new("UIListLayout", TopLoadoutGrid)
	lgLayout.FillDirection = Enum.FillDirection.Horizontal
	lgLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	lgLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	lgLayout.Padding = UDim.new(0, 15)

	for i = 1, 4 do
		local slotFrame = CreateGrimPanel(TopLoadoutGrid)
		slotFrame.Size = UDim2.new(0, 95, 0, 95)
		slotFrame.ClipsDescendants = true

		local ar = Instance.new("UIAspectRatioConstraint", slotFrame)
		ar.AspectRatio = 1.0 

		local numLbl = CreateSharpLabel(slotFrame, "SLOT " .. i, UDim2.new(0, 50, 0, 15), Enum.Font.GothamBlack, Color3.fromRGB(160, 160, 175), 11)
		numLbl.Position = UDim2.new(0, 8, 0, 8)
		numLbl.TextXAlignment = Enum.TextXAlignment.Left

		local nameLbl = CreateSharpLabel(slotFrame, "EMPTY", UDim2.new(1, -16, 1, -25), Enum.Font.GothamBold, Color3.fromRGB(245, 245, 245), 14)
		nameLbl.Position = UDim2.new(0.5, 0, 0.5, 10)
		nameLbl.AnchorPoint = Vector2.new(0.5, 0.5)
		nameLbl.TextWrapped = true
		nameLbl.TextScaled = true
		local tCon = Instance.new("UITextSizeConstraint", nameLbl)
		tCon.MaxTextSize = 16
		tCon.MinTextSize = 8

		table.insert(SkillSlotLabels, nameLbl)
	end

	local sep = Instance.new("Frame", MainFrame)
	sep.Size = UDim2.new(0.95, 0, 0, 2)
	sep.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
	sep.BorderSizePixel = 0
	sep.LayoutOrder = 2

	-- [[ BOTTOM: SKILL LIBRARY GRID ]]
	local LibHeader = CreateSharpLabel(MainFrame, "SKILL LIBRARY", UDim2.new(0.95, 0, 0, 30), Enum.Font.GothamBlack, Color3.fromRGB(245, 245, 245), 20)
	LibHeader.LayoutOrder = 3
	LibHeader.TextXAlignment = Enum.TextXAlignment.Left

	SkillLibraryScroll = Instance.new("ScrollingFrame", MainFrame)
	SkillLibraryScroll.Size = UDim2.new(0.98, 0, 1, -220)
	SkillLibraryScroll.BackgroundTransparency = 1
	SkillLibraryScroll.ScrollBarThickness = 6
	SkillLibraryScroll.BorderSizePixel = 0
	SkillLibraryScroll.LayoutOrder = 4

	local libLayout = Instance.new("UIListLayout", SkillLibraryScroll)
	libLayout.Padding = UDim.new(0, 20)
	libLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	libLayout.SortOrder = Enum.SortOrder.LayoutOrder

	-- THE SCROLL FIX: Let Roblox automatically expand the scroll container size based on internal elements
	libLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		SkillLibraryScroll.CanvasSize = UDim2.new(0, 0, 0, libLayout.AbsoluteContentSize.Y + 40)
	end)

	local function RefreshSkills()
		for _, c in ipairs(SkillLibraryScroll:GetChildren()) do if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end end

		if not hasSkillData or type(SkillData) ~= "table" then return end
		local tData = SkillData.Skills or SkillData

		local categorizedSkills = {}
		local defaultMoves = {}
		local allowedRequirements = {
			["ODM"] = "BASE ODM",
			["Ultrahard Steel Blades"] = "ULTRAHARD BLADES",
			["Thunder Spears"] = "THUNDER SPEARS",
			["Anti-Personnel"] = "ANTI-PERSONNEL"
		}

		for sName, sData in pairs(tData) do
			if type(sData) == "table" and sData.Type == "Style" and allowedRequirements[sData.Requirement] then
				local reqGroup = allowedRequirements[sData.Requirement]
				local hasWeapon = false

				if sData.Requirement == "ODM" then
					hasWeapon = true 
					table.insert(defaultMoves, sName)
				else
					for iName, iData in pairs(ItemData.Equipment or {}) do
						if iData.Style == sData.Requirement then
							local safeNameBase = iName:gsub("[^%w]", "")
							local wCount = tonumber(player:GetAttribute(safeNameBase .. "Count")) or tonumber(player:GetAttribute(iName)) or 0
							if wCount > 0 then
								hasWeapon = true
								break
							end
						end
					end
				end

				local cat = reqGroup .. " SKILLS"
				if not categorizedSkills[cat] then categorizedSkills[cat] = { HasUnlocked = false, Skills = {} } end
				if hasWeapon then categorizedSkills[cat].HasUnlocked = true end
				table.insert(categorizedSkills[cat].Skills, {Name = sName, Data = sData, HasWep = hasWeapon})
			end
		end

		table.sort(defaultMoves)

		for i, lbl in ipairs(SkillSlotLabels) do 
			local rawName = player:GetAttribute("EquippedSkill_" .. i)
			local sData = tData[rawName]

			if not rawName or rawName == "" or not sData or sData.Type == "Basic" or sData.Type == "Titan" or sData.IsBasic or sData.IsTitan then
				rawName = defaultMoves[i] or "EMPTY"
			end
			lbl.Text = string.upper(rawName) 
		end

		local sortedCats = {}
		for k, _ in pairs(categorizedSkills) do table.insert(sortedCats, k) end

		table.sort(sortedCats, function(a, b)
			local aUnlocked = categorizedSkills[a].HasUnlocked
			local bUnlocked = categorizedSkills[b].HasUnlocked
			if aUnlocked ~= bUnlocked then
				return aUnlocked and not bUnlocked
			end
			return a < b
		end)

		local sOrderCount = 1
		for _, catName in ipairs(sortedCats) do
			local skills = categorizedSkills[catName].Skills
			if #skills > 0 then
				local catHeader = CreateSharpLabel(SkillLibraryScroll, "- " .. catName .. " -", UDim2.new(0.95, 0, 0, 30), Enum.Font.GothamBlack, Color3.fromRGB(225, 185, 60), 16)
				catHeader.LayoutOrder = sOrderCount; sOrderCount += 1
				catHeader.TextXAlignment = Enum.TextXAlignment.Left

				local GridContainer = Instance.new("Frame", SkillLibraryScroll)
				GridContainer.BackgroundTransparency = 1
				GridContainer.LayoutOrder = sOrderCount; sOrderCount += 1 

				local uigrid = Instance.new("UIGridLayout", GridContainer)
				-- [[ THE VISUAL FIX: Compact Box Layout (180x220) ]]
				uigrid.CellSize = UDim2.new(0, 180, 0, 220) 
				uigrid.CellPadding = UDim2.new(0, 12, 0, 15)
				uigrid.FillDirection = Enum.FillDirection.Horizontal
				uigrid.SortOrder = Enum.SortOrder.LayoutOrder
				uigrid.HorizontalAlignment = Enum.HorizontalAlignment.Left 

				-- Automatically sizes the category container to fit the exact boxes
				uigrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					GridContainer.Size = UDim2.new(0.95, 0, 0, uigrid.AbsoluteContentSize.Y)
				end)

				table.sort(skills, function(a, b) return (a.Data.Order or 99) < (b.Data.Order or 99) end)

				for i, item in ipairs(skills) do
					local sName = item.Name; local sData = item.Data; local hasWep = item.HasWep
					local sCard = CreateGrimPanel(GridContainer)
					sCard.LayoutOrder = i

					local wepText = ""
					if sData.Requirement == "ODM" then wepText = "[ BASE SKILL ]"
					else wepText = "[ REQ: " .. string.upper(sData.Requirement) .. " ]" end

					-- Title Top Centered
					local sTitle = CreateSharpLabel(sCard, string.upper(sName), UDim2.new(1, -20, 0, 35), Enum.Font.GothamBlack, Color3.fromRGB(245, 245, 245), 14)
					sTitle.Position = UDim2.new(0.5, 0, 0, 10); sTitle.AnchorPoint = Vector2.new(0.5, 0)
					sTitle.TextWrapped = true; sTitle.TextScaled = true
					local tc = Instance.new("UITextSizeConstraint", sTitle); tc.MaxTextSize = 14; tc.MinTextSize = 9

					-- Tag Just Below Title
					local sReq = CreateSharpLabel(sCard, wepText, UDim2.new(1, -10, 0, 15), Enum.Font.GothamBold, (hasWep and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(255, 85, 85)), 10)
					sReq.Position = UDim2.new(0.5, 0, 0, 48); sReq.AnchorPoint = Vector2.new(0.5, 0)

					-- Description Center Justified
					local desc = CreateSharpLabel(sCard, sData.Desc or "A powerful technique.", UDim2.new(1, -20, 0, 70), Enum.Font.GothamMedium, Color3.fromRGB(160, 160, 175), 11)
					desc.Position = UDim2.new(0.5, 0, 0, 68); desc.AnchorPoint = Vector2.new(0.5, 0)
					desc.TextWrapped = true; desc.TextYAlignment = Enum.TextYAlignment.Top

					-- Equip Button Spanning Bottom
					local eqBtn, eqStroke = CreateSharpButton(sCard, "EQUIP", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, 11)
					eqBtn.Position = UDim2.new(0.5, 0, 1, -10); eqBtn.AnchorPoint = Vector2.new(0.5, 1)

					-- Synergy (If exists)
					if sData.ComboReq then
						local synText = "Synergy: After " .. string.upper(sData.ComboReq)
						local syn = CreateSharpLabel(sCard, synText, UDim2.new(1, -10, 0, 30), Enum.Font.GothamBold, Color3.fromRGB(225, 185, 60), 10)
						syn.Position = UDim2.new(0.5, 0, 1, -45); syn.AnchorPoint = Vector2.new(0.5, 1)
						syn.TextWrapped = true
					end

					local isEquipped = false
					for j=1,4 do 
						local slotWep = player:GetAttribute("EquippedSkill_"..j)
						if not slotWep or slotWep == "" or slotWep == "EMPTY" then slotWep = defaultMoves[j] end
						if slotWep == sName then isEquipped = true break end 
					end

					if isEquipped then 
						eqBtn.Text = "EQUIPPED"; eqBtn.TextColor3 = Color3.fromRGB(225, 185, 60); eqStroke.Color = Color3.fromRGB(225, 185, 60)
					elseif not hasWep then
						eqBtn.Text = "LOCKED"; eqBtn.TextColor3 = Color3.fromRGB(100, 100, 100); eqStroke.Color = Color3.fromRGB(70, 70, 80)
					else 
						eqBtn.Text = "EQUIP"; eqBtn.TextColor3 = Color3.fromRGB(245, 245, 245); eqStroke.Color = Color3.fromRGB(70, 70, 80) 
					end

					if hasWep then
						local ActionsOverlay = Instance.new("Frame", sCard)
						ActionsOverlay.Size = UDim2.new(1, 0, 1, 0); ActionsOverlay.BackgroundColor3 = Color3.fromRGB(18, 18, 22); ActionsOverlay.BackgroundTransparency = 0.1; ActionsOverlay.Visible = false; ActionsOverlay.ZIndex = 10; ActionsOverlay.Active = true; ActionsOverlay.BorderSizePixel = 0

						-- Vertical stack layout for the 4 slots and Cancel button inside the card
						local actLayout = Instance.new("UIListLayout", ActionsOverlay)
						actLayout.FillDirection = Enum.FillDirection.Vertical
						actLayout.Padding = UDim.new(0, 6)
						actLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
						actLayout.VerticalAlignment = Enum.VerticalAlignment.Center

						for sIndex = 1, 4 do
							local slotBtn, _ = CreateSharpButton(ActionsOverlay, "SLOT " .. sIndex, UDim2.new(0.8, 0, 0, 26), Enum.Font.GothamBlack, 11); slotBtn.ZIndex = 11
							slotBtn.MouseButton1Click:Connect(function()
								Network.EquipSkill:FireServer(sIndex, sName)
								player:SetAttribute("EquippedSkill_"..sIndex, sName) 
								ActionsOverlay.Visible = false
								RefreshSkills()
							end)
						end

						local closeBtn, _ = CreateSharpButton(ActionsOverlay, "CANCEL", UDim2.new(0.8, 0, 0, 26), Enum.Font.GothamBlack, 11)
						closeBtn.ZIndex = 11; closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
						closeBtn.MouseButton1Click:Connect(function() ActionsOverlay.Visible = false end)

						eqBtn.MouseButton1Click:Connect(function() 
							if ActionsOverlay.Visible then ActionsOverlay.Visible = false else
								for _, sc in ipairs(SkillLibraryScroll:GetDescendants()) do if sc.Name == "ActionsOverlay" then sc.Visible = false end end
								ActionsOverlay.Visible = true 
							end
						end) 
					end
				end
			end
		end
	end

	player.AttributeChanged:Connect(function(attr) if string.match(attr, "^EquippedSkill") then RefreshSkills() end end)
	RefreshSkills()
end

return SkillsTab