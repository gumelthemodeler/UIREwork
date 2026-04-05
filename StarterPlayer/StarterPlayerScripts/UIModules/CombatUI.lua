-- @ScriptType: ModuleScript
-- Name: CombatUI
-- @ScriptType: ModuleScript
local CombatUI = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))

local player = Players.LocalPlayer

-- UI Elements
local CombatBackdrop
local CombatWindow
local WindowScale
local LogScroll
local ActionContainer

local ActionGrid
local TargetMenu
local tHoverTitle
local tHoverDesc

local pHPBar, pGasBar, pHeatBar
local eHPBar, eGateBar
local pNameLbl, eNameLbl
local MissionInfoLbl

local PlayerStatusBox
local EnemyStatusBox

local pAvatar, eAvatar
local VFXOverlay

local pHPText, pGasText, pHeatText, eHPText, eGateText
local pHeatContainer

local currentBattleState = nil
local pendingSkillName = nil
local inputLocked = false

local InstantSkills = {
	["Maneuver"] = true,
	["Recover"] = true,
	["Fall Back"] = true,
	["Close In"] = true,
	["Retreat"] = true,
	["Transform"] = true,
	["Eject"] = true,
	["Titan Recover"] = true
}

local function CreateFlatPanel(parent)
	local frame = Instance.new("Frame", parent)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	frame.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(45, 45, 50)
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return frame, stroke
end

local function CreateMinimalButton(parent, text, size, baseColorHex)
	local btn = Instance.new("TextButton", parent)
	btn.Size = size
	btn.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Text = text

	local cColor = Color3.fromHex(baseColorHex:gsub("#", ""))
	btn.TextColor3 = cColor

	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(45, 45, 50)
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	btn.MouseEnter:Connect(function() 
		if btn.Active then 
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.2), {Color = cColor}):Play()
		end
	end)
	btn.MouseLeave:Connect(function() 
		if btn.Active then 
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(22, 22, 26)}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(45, 45, 50)}):Play()
		end
	end)
	return btn, stroke
end

local function CreateFlatBar(parent, title, colorHex, pos, size, alignRight)
	local cColor = Color3.fromHex(colorHex:gsub("#", ""))
	local shadowColor = Color3.new(cColor.R * 0.4, cColor.G * 0.4, cColor.B * 0.4)

	local container = Instance.new("Frame", parent)
	container.Size = size
	container.Position = pos
	container.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
	container.BorderSizePixel = 0

	local strk = Instance.new("UIStroke", container)
	strk.Color = Color3.fromRGB(40, 40, 45)
	strk.Thickness = 1
	strk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local fill = Instance.new("Frame", container)
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	fill.BorderSizePixel = 0

	if alignRight then
		fill.AnchorPoint = Vector2.new(1, 0)
		fill.Position = UDim2.new(1, 0, 0, 0)
	end

	local grad = Instance.new("UIGradient", fill)
	grad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, cColor),
		ColorSequenceKeypoint.new(1, shadowColor)
	}
	grad.Rotation = 90

	local txt = UIHelpers.CreateLabel(container, title .. " 100/100", UDim2.new(1, -8, 1, 0), Enum.Font.GothamBold, Color3.fromRGB(240, 240, 240), 11)
	if alignRight then
		txt.TextXAlignment = Enum.TextXAlignment.Right
	else
		txt.TextXAlignment = Enum.TextXAlignment.Left
		txt.Position = UDim2.new(0, 8, 0, 0)
	end
	txt.ZIndex = 2

	return fill, txt, container
end

local function RenderStatuses(container, combatant)
	for _, child in ipairs(container:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end

	local function addIcon(iconTxt, bgColor, strokeColor)
		local f = Instance.new("Frame", container)
		f.Size = UDim2.new(0, 24, 0, 18)
		f.BackgroundColor3 = bgColor
		Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

		local s = Instance.new("UIStroke", f)
		s.Color = strokeColor
		s.Thickness = 1
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local t = Instance.new("TextLabel", f)
		t.Size = UDim2.new(1, 0, 1, 0)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.GothamBlack
		t.Text = iconTxt
		t.TextColor3 = Color3.fromRGB(255,255,255)
		t.TextScaled = true
	end

	if combatant.Statuses then
		if combatant.Statuses.Dodge and combatant.Statuses.Dodge > 0 then addIcon("DGE", Color3.fromRGB(30, 60, 120), Color3.fromRGB(60, 100, 200)) end
		if combatant.Statuses.Transformed and combatant.Statuses.Transformed > 0 then addIcon("TTN", Color3.fromRGB(150, 40, 40), Color3.fromRGB(200, 60, 60)) end
		for sName, duration in pairs(combatant.Statuses) do
			if sName == "Telegraphing" and type(duration) == "string" then
				addIcon("WRN", Color3.fromRGB(200, 100, 0), Color3.fromRGB(255, 150, 0))
			elseif type(duration) == "number" and duration > 0 then
				if sName == "Bleed" then addIcon("BLD", Color3.fromRGB(150, 20, 20), Color3.fromRGB(255, 50, 50))
				elseif sName == "Burn" then addIcon("BRN", Color3.fromRGB(200, 80, 20), Color3.fromRGB(255, 120, 50))
				elseif sName == "Stun" then addIcon("STN", Color3.fromRGB(200, 200, 80), Color3.fromRGB(255, 255, 150))
				elseif sName == "NapeGuard" then addIcon("GRD", Color3.fromRGB(100, 60, 150), Color3.fromRGB(150, 100, 200))
				elseif sName == "Confusion" then addIcon("CNF", Color3.fromRGB(150, 80, 150), Color3.fromRGB(200, 100, 200))
				elseif sName == "Debuff_Defense" then addIcon("BRK", Color3.fromRGB(120, 60, 60), Color3.fromRGB(200, 100, 100))
				elseif sName == "Crippled" then addIcon("CRP", Color3.fromRGB(80, 80, 80), Color3.fromRGB(120, 120, 120))
				elseif sName == "Immobilized" then addIcon("IMB", Color3.fromRGB(40, 120, 40), Color3.fromRGB(80, 200, 80))
				elseif sName == "Weakened" then addIcon("WEK", Color3.fromRGB(120, 80, 40), Color3.fromRGB(200, 120, 60))
				elseif sName == "Blinded" then addIcon("BLD", Color3.fromRGB(40, 40, 40), Color3.fromRGB(80, 80, 80))
				elseif sName == "TrueBlind" then addIcon("TBL", Color3.fromRGB(20, 20, 20), Color3.fromRGB(50, 50, 50))
				elseif sName == "Buff_Strength" or sName == "Buff_Defense" then addIcon("BUF", Color3.fromRGB(20, 120, 20), Color3.fromRGB(40, 200, 40))
				end
			end
		end
	end
end

function CombatUI.Initialize(masterScreenGui)
	CombatBackdrop = Instance.new("TextButton", masterScreenGui)
	CombatBackdrop.Name = "CombatBackdrop"
	CombatBackdrop.Size = UDim2.new(1, 0, 1, 0)
	CombatBackdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	CombatBackdrop.BackgroundTransparency = 1
	CombatBackdrop.Text = ""
	CombatBackdrop.AutoButtonColor = false
	CombatBackdrop.Visible = false
	CombatBackdrop.ZIndex = 98
	CombatBackdrop.Active = true

	CombatWindow = Instance.new("Frame", masterScreenGui)
	CombatWindow.Name = "CombatWindow"
	CombatWindow.Size = UDim2.new(0, 1000, 0, 580)
	CombatWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	CombatWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	CombatWindow.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	CombatWindow.Visible = false
	CombatWindow.ZIndex = 100
	local cwStroke = Instance.new("UIStroke", CombatWindow)
	cwStroke.Color = Color3.fromRGB(45, 45, 50)
	cwStroke.Thickness = 1

	WindowScale = Instance.new("UIScale", CombatWindow)
	WindowScale.Scale = 0

	VFXOverlay = Instance.new("Frame", CombatWindow)
	VFXOverlay.Size = UDim2.new(1, 0, 1, 0)
	VFXOverlay.BackgroundTransparency = 1
	VFXOverlay.ZIndex = 105

	local Header = Instance.new("Frame", CombatWindow)
	Header.Size = UDim2.new(1, 0, 0, 40)
	Header.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	Header.BorderSizePixel = 0
	local hStroke = Instance.new("UIStroke", Header)
	hStroke.Color = Color3.fromRGB(40, 40, 45)
	hStroke.Thickness = 1
	hStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	MissionInfoLbl = UIHelpers.CreateLabel(Header, "COMBAT DEPLOYMENT", UDim2.new(1, -20, 1, 0), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 14)
	MissionInfoLbl.Position = UDim2.new(0, 15, 0, 0)
	MissionInfoLbl.TextXAlignment = Enum.TextXAlignment.Left

	-- ==========================================
	-- TOP AREA: HORIZONTAL COMBATANTS
	-- ==========================================
	local CombatantsFrame = Instance.new("Frame", CombatWindow)
	CombatantsFrame.Size = UDim2.new(1, -40, 0, 135)
	CombatantsFrame.Position = UDim2.new(0, 20, 0, 55)
	CombatantsFrame.BackgroundTransparency = 1

	-- PLAYER SIDE
	local PlayerPanel, _ = CreateFlatPanel(CombatantsFrame)
	PlayerPanel.Size = UDim2.new(0.46, 0, 1, 0)

	pAvatar = Instance.new("ImageLabel", PlayerPanel)
	pAvatar.Size = UDim2.new(0, 90, 0, 90)
	pAvatar.Position = UDim2.new(0, 15, 0, 15)
	pAvatar.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	pAvatar.Image = isReady and content or ""
	pAvatar.ScaleType = Enum.ScaleType.Crop
	local pAvatarStroke = Instance.new("UIStroke", pAvatar)
	pAvatarStroke.Color = Color3.fromRGB(85, 170, 255)
	pAvatarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	pNameLbl = UIHelpers.CreateLabel(PlayerPanel, player.Name, UDim2.new(1, -130, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 15)
	pNameLbl.Position = UDim2.new(0, 120, 0, 10)
	pNameLbl.TextXAlignment = Enum.TextXAlignment.Left

	pHPBar, pHPText = CreateFlatBar(PlayerPanel, "HP", "#44DD44", UDim2.new(0, 120, 0, 35), UDim2.new(1, -135, 0, 20), false)
	pGasBar, pGasText = CreateFlatBar(PlayerPanel, "GAS", "#AADDDD", UDim2.new(0, 120, 0, 60), UDim2.new(1, -135, 0, 20), false)
	pHeatBar, pHeatText, pHeatContainer = CreateFlatBar(PlayerPanel, "HEAT", "#FF8800", UDim2.new(0, 120, 0, 85), UDim2.new(1, -135, 0, 20), false)
	pHeatContainer.Visible = false

	PlayerStatusBox = Instance.new("Frame", PlayerPanel)
	PlayerStatusBox.Size = UDim2.new(1, -135, 0, 20)
	PlayerStatusBox.Position = UDim2.new(0, 120, 0, 110)
	PlayerStatusBox.BackgroundTransparency = 1
	local pStatLayout = Instance.new("UIListLayout", PlayerStatusBox)
	pStatLayout.FillDirection = Enum.FillDirection.Horizontal
	pStatLayout.Padding = UDim.new(0, 4)

	local vsLbl = UIHelpers.CreateLabel(CombatantsFrame, "VS", UDim2.new(0.08, 0, 1, 0), Enum.Font.GothamBlack, Color3.fromRGB(100, 100, 110), 24)
	vsLbl.Position = UDim2.new(0.46, 0, 0, 0)

	-- ENEMY SIDE
	local EnemyPanel, _ = CreateFlatPanel(CombatantsFrame)
	EnemyPanel.Size = UDim2.new(0.46, 0, 1, 0)
	EnemyPanel.Position = UDim2.new(0.54, 0, 0, 0)

	eAvatar = Instance.new("ImageLabel", EnemyPanel)
	eAvatar.Size = UDim2.new(0, 90, 0, 90)
	eAvatar.Position = UDim2.new(1, -15, 0, 15)
	eAvatar.AnchorPoint = Vector2.new(1, 0)
	eAvatar.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	eAvatar.Image = "rbxassetid://90132878979603" 
	eAvatar.ScaleType = Enum.ScaleType.Crop
	local eAvatarStroke = Instance.new("UIStroke", eAvatar)
	eAvatarStroke.Color = Color3.fromRGB(255, 85, 85)
	eAvatarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	eNameLbl = UIHelpers.CreateLabel(EnemyPanel, "UNKNOWN ABNORMAL", UDim2.new(1, -130, 0, 20), Enum.Font.GothamBold, Color3.fromRGB(255, 100, 100), 15)
	eNameLbl.Position = UDim2.new(0, 15, 0, 10)
	eNameLbl.TextXAlignment = Enum.TextXAlignment.Right

	eHPBar, eHPText = CreateFlatBar(EnemyPanel, "HP", "#DD4444", UDim2.new(0, 15, 0, 35), UDim2.new(1, -135, 0, 20), true)
	eGateBar, eGateText, eGateContainer = CreateFlatBar(EnemyPanel, "ARMOR", "#AAAAAA", UDim2.new(0, 15, 0, 60), UDim2.new(1, -135, 0, 20), true)
	eGateContainer.Visible = false

	EnemyStatusBox = Instance.new("Frame", EnemyPanel)
	EnemyStatusBox.Size = UDim2.new(1, -135, 0, 20)
	EnemyStatusBox.Position = UDim2.new(0, 15, 0, 110)
	EnemyStatusBox.BackgroundTransparency = 1
	local eStatLayout = Instance.new("UIListLayout", EnemyStatusBox)
	eStatLayout.FillDirection = Enum.FillDirection.Horizontal
	eStatLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	eStatLayout.Padding = UDim.new(0, 4)

	-- ==========================================
	-- MIDDLE AREA: COMBAT LOG
	-- ==========================================
	local LogContainer, _ = CreateFlatPanel(CombatWindow)
	LogContainer.Size = UDim2.new(1, -40, 0, 145)
	LogContainer.Position = UDim2.new(0, 20, 0, 200)

	LogScroll = Instance.new("ScrollingFrame", LogContainer)
	LogScroll.Size = UDim2.new(1, -20, 1, -20)
	LogScroll.Position = UDim2.new(0, 10, 0, 10)
	LogScroll.BackgroundTransparency = 1
	LogScroll.ScrollBarThickness = 4
	LogScroll.BorderSizePixel = 0

	local logLayout = Instance.new("UIListLayout", LogScroll)
	logLayout.Padding = UDim.new(0, 6)
	logLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	logLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
		LogScroll.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y + 10)
		LogScroll.CanvasPosition = Vector2.new(0, LogScroll.CanvasSize.Y.Offset)
	end)

	-- ==========================================
	-- BOTTOM AREA: LOADOUT & TARGET MENU
	-- ==========================================
	ActionContainer = Instance.new("Frame", CombatWindow)
	ActionContainer.Size = UDim2.new(1, -40, 0, 200)
	ActionContainer.Position = UDim2.new(0, 20, 1, -215)
	ActionContainer.BackgroundTransparency = 1

	ActionGrid = Instance.new("ScrollingFrame", ActionContainer)
	ActionGrid.Size = UDim2.new(1, 0, 1, 0)
	ActionGrid.BackgroundTransparency = 1
	ActionGrid.ScrollBarThickness = 0
	local acLayout = Instance.new("UIGridLayout", ActionGrid)
	acLayout.CellSize = UDim2.new(0, 195, 0, 45)
	acLayout.CellPadding = UDim2.new(0, 15, 0, 15)
	acLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	acLayout.VerticalAlignment = Enum.VerticalAlignment.Top

	acLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ActionGrid.CanvasSize = UDim2.new(0, 0, 0, acLayout.AbsoluteContentSize.Y + 10)
	end)

	TargetMenu = Instance.new("Frame", ActionContainer)
	TargetMenu.Size = UDim2.new(1, 0, 1, -10)
	TargetMenu.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	TargetMenu.Visible = false
	local tmStroke = Instance.new("UIStroke", TargetMenu)
	tmStroke.Color = Color3.fromRGB(40, 40, 45)
	tmStroke.Thickness = 1
	tmStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local InfoPanel = Instance.new("Frame", TargetMenu)
	InfoPanel.Size = UDim2.new(0.5, 0, 1, 0)
	InfoPanel.BackgroundTransparency = 1

	tHoverTitle = UIHelpers.CreateLabel(InfoPanel, "SELECT TARGET", UDim2.new(1, -20, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 20)
	tHoverTitle.Position = UDim2.new(0, 30, 0, 20); tHoverTitle.TextXAlignment = Enum.TextXAlignment.Left

	tHoverDesc = UIHelpers.CreateLabel(InfoPanel, "Hover over a limb to view its tactical effect.", UDim2.new(1, -20, 0, 60), Enum.Font.GothamMedium, Color3.fromRGB(180, 180, 180), 13)
	tHoverDesc.Position = UDim2.new(0, 30, 0, 60); tHoverDesc.TextXAlignment = Enum.TextXAlignment.Left; tHoverDesc.TextYAlignment = Enum.TextYAlignment.Top; tHoverDesc.TextWrapped = true

	local CancelBtn, _ = CreateMinimalButton(InfoPanel, "CANCEL", UDim2.new(0, 150, 0, 40), "#FF5555")
	CancelBtn.Position = UDim2.new(0, 30, 1, -60)
	CancelBtn.MouseButton1Click:Connect(function() 
		TargetMenu.Visible = false
		ActionGrid.Visible = true
		pendingSkillName = nil 
	end)

	local BodyContainer = Instance.new("Frame", TargetMenu)
	BodyContainer.Size = UDim2.new(0, 160, 0, 180) 
	BodyContainer.Position = UDim2.new(0.8, 0, 0.5, 0)
	BodyContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	BodyContainer.BackgroundTransparency = 1

	local function CreateFlatLimb(name, targetId, size, pos, hoverText, baseColor)
		local limb = Instance.new("TextButton", BodyContainer)
		limb.Size = size; limb.Position = pos
		limb.BackgroundColor3 = Color3.fromRGB(22, 22, 26) 
		limb.Text = name:upper()
		limb.Font = Enum.Font.GothamBlack
		limb.TextColor3 = Color3.fromRGB(255, 255, 255) 
		limb.TextSize = 10
		limb.AutoButtonColor = false
		limb.AnchorPoint = Vector2.new(0.5, 0.5)

		local strk = Instance.new("UIStroke", limb)
		strk.Color = baseColor 
		strk.Thickness = 2 
		strk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		limb.MouseEnter:Connect(function()
			strk.Color = UIHelpers.Colors.Gold
			strk.Thickness = 3
			tHoverTitle.Text = "TARGET: " .. string.upper(targetId)
			tHoverTitle.TextColor3 = baseColor
			tHoverDesc.Text = hoverText
		end)

		limb.MouseLeave:Connect(function()
			strk.Color = baseColor
			strk.Thickness = 2
			tHoverTitle.Text = "SELECT TARGET"
			tHoverTitle.TextColor3 = UIHelpers.Colors.Gold
			tHoverDesc.Text = "Hover over a limb to view its tactical effect."
		end)

		limb.MouseButton1Click:Connect(function()
			if pendingSkillName and not inputLocked then
				inputLocked = true
				TargetMenu.Visible = false
				ActionGrid.Visible = true

				for _, c in ipairs(ActionGrid:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
				local execLbl = UIHelpers.CreateLabel(ActionGrid, "EXECUTING MANEUVER...", UDim2.new(0, 200, 0, 45), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 14)

				Network:WaitForChild("CombatAction"):FireServer("Attack", {SkillName = pendingSkillName, TargetLimb = targetId})
				pendingSkillName = nil
			end
		end)
	end

	local aspect = Instance.new("UIAspectRatioConstraint", BodyContainer); aspect.AspectRatio = 0.8
	CreateFlatLimb("Eyes", "Eyes", UDim2.new(0.24, 0, 0.18, 0), UDim2.new(0.5, 0, 0.08, 0), "Deals 20% Damage. Inflicts Blinded.", Color3.fromRGB(120, 120, 180))
	CreateFlatLimb("Nape", "Nape", UDim2.new(0.24, 0, 0.06, 0), UDim2.new(0.5, 0, 0.22, 0), "Deals 150% Damage. Low accuracy.", Color3.fromRGB(220, 80, 80))
	CreateFlatLimb("Body", "Body", UDim2.new(0.48, 0, 0.38, 0), UDim2.new(0.5, 0, 0.45, 0), "Deals 100% Damage. Standard accuracy.", Color3.fromRGB(80, 160, 80))
	CreateFlatLimb("L.Arm", "Arms", UDim2.new(0.22, 0, 0.38, 0), UDim2.new(0.14, 0, 0.45, 0), "Deals 50% Damage. Inflicts Weakened.", Color3.fromRGB(180, 140, 60))
	CreateFlatLimb("R.Arm", "Arms", UDim2.new(0.22, 0, 0.38, 0), UDim2.new(0.86, 0, 0.45, 0), "Deals 50% Damage. Inflicts Weakened.", Color3.fromRGB(180, 140, 60))
	CreateFlatLimb("L.Leg", "Legs", UDim2.new(0.23, 0, 0.32, 0), UDim2.new(0.37, 0, 0.81, 0), "Deals 50% Damage. Inflicts Crippled.", Color3.fromRGB(80, 140, 180))
	CreateFlatLimb("R.Leg", "Legs", UDim2.new(0.23, 0, 0.32, 0), UDim2.new(0.63, 0, 0.81, 0), "Deals 50% Damage. Inflicts Crippled.", Color3.fromRGB(80, 140, 180))

	Network:WaitForChild("CombatUpdate").OnClientEvent:Connect(function(action, data)
		if action == "Start" or action == "StartMinigame" then
			CombatUI.Show(data)

		elseif action == "Update" then
			CombatUI.UpdateState(data)
			CombatUI.UpdateSkills()

		elseif action == "TurnStrike" then
			CombatUI.UpdateState(data)

			local VFXManager = require(script.Parent.Parent:WaitForChild("VFXManager"))
			VFXManager.PlayCombatEffect(data.SkillUsed, data.IsPlayerAttacking, pAvatar, eAvatar, data.DidHit)

			if data.ShakeType == "Heavy" then VFXManager.ScreenShake(0.5, 0.25)
			elseif data.ShakeType == "Light" then VFXManager.ScreenShake(0.2, 0.15) end

			if data.LogMsg then CombatUI.AppendLog(data.LogMsg, data.IsPlayerAttacking and "#55AAFF" or "#FF5555") end

		elseif action == "WaveComplete" then
			CombatUI.UpdateState(data)
			CombatUI.AppendLog("<b><font color='#55FF55'>WAVE CLEARED!</font></b>", "#55FF55")
			if data.LogMsg then CombatUI.AppendLog(data.LogMsg, "#FFD700") end

			inputLocked = true
			for _, c in ipairs(ActionGrid:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
			TargetMenu.Visible = false
			ActionGrid.Visible = true

			local continueBtn, _ = CreateMinimalButton(ActionGrid, "CONTINUE EXPEDITION", UDim2.new(0, 0, 0, 0), "#55FF55")
			continueBtn.MouseButton1Click:Connect(function()
				CombatUI.UpdateSkills()
			end)

			local retreatBtn, _ = CreateMinimalButton(ActionGrid, "RETREAT TO COMMAND", UDim2.new(0, 0, 0, 0), "#FF5555")
			retreatBtn.MouseButton1Click:Connect(function()
				Network:WaitForChild("CombatAction"):FireServer("Attack", {SkillName = "Retreat"})
				CombatUI.Close()
				-- [[ THE FIX: Switch back to Lobby music seamlessly when closing ]]
				local MusicManager = require(script.Parent.Parent:WaitForChild("MusicManager"))
				MusicManager.SetCategory("Lobby")
			end)

		elseif action == "Victory" then
			CombatUI.UpdateState(data)
			CombatUI.AppendLog("<b><font color='#55FF55'>VICTORY!</font></b>\nEarned " .. (data.XP or 0) .. " XP and " .. (data.Dews or 0) .. " Dews.", "#55FF55")
			if data.ExtraLog and data.ExtraLog ~= "" then CombatUI.AppendLog(data.ExtraLog) end

			-- [[ THE FIX: Play Victory Stinger (It will pause BGM automatically) ]]
			local VFXManager = require(script.Parent.Parent:WaitForChild("VFXManager"))
			VFXManager.PlaySFX("Victory", 1.0)

			inputLocked = true
			for _, c in ipairs(ActionGrid:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
			TargetMenu.Visible = false
			ActionGrid.Visible = true

			local closeBtn, _ = CreateMinimalButton(ActionGrid, "RETURN TO COMMAND", UDim2.new(0, 0, 0, 0), "#55FF55")
			closeBtn.MouseButton1Click:Connect(function() 
				CombatUI.Close() 
				-- [[ THE FIX: Switch back to Lobby music seamlessly when closing ]]
				local MusicManager = require(script.Parent.Parent:WaitForChild("MusicManager"))
				MusicManager.SetCategory("Lobby")
			end)

		elseif action == "Defeat" or action == "PathsDeath" then
			CombatUI.UpdateState(data)
			CombatUI.AppendLog("<b><font color='#FF5555'>DEFEAT...</font></b> Your forces were wiped out.", "#FF5555")

			-- [[ THE FIX: Play Defeat Stinger (It will pause BGM automatically) ]]
			local VFXManager = require(script.Parent.Parent:WaitForChild("VFXManager"))
			VFXManager.PlaySFX("Defeat", 1.0)

			inputLocked = true
			for _, c in ipairs(ActionGrid:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
			TargetMenu.Visible = false
			ActionGrid.Visible = true

			local closeBtn, _ = CreateMinimalButton(ActionGrid, "RETURN TO COMMAND", UDim2.new(0, 0, 0, 0), "#FF5555")
			closeBtn.MouseButton1Click:Connect(function() 
				CombatUI.Close() 
				-- [[ THE FIX: Switch back to Lobby music seamlessly when closing ]]
				local MusicManager = require(script.Parent.Parent:WaitForChild("MusicManager"))
				MusicManager.SetCategory("Lobby")
			end)

		elseif action == "Fled" then
			CombatUI.AppendLog("<b><font color='#AAAAAA'>YOU FLED THE BATTLE.</font></b>", "#AAAAAA")
			task.wait(1.5)
			CombatUI.Close()
			-- [[ THE FIX: Switch back to Lobby music seamlessly when closing ]]
			local MusicManager = require(script.Parent.Parent:WaitForChild("MusicManager"))
			MusicManager.SetCategory("Lobby")
		end
	end)
end

function CombatUI.UpdateSkills()
	inputLocked = false
	ActionGrid.Visible = true
	TargetMenu.Visible = false

	for _, c in ipairs(ActionGrid:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end

	local currentRange = "Close"
	local pState = currentBattleState and currentBattleState.Player or nil
	if currentBattleState and currentBattleState.Context and currentBattleState.Context.Range then
		currentRange = currentBattleState.Context.Range
	end

	local isTransformed = pState and pState.Statuses and pState.Statuses["Transformed"]
	local defaultClose = {"Basic Slash", "Heavy Slash", "None", "None"}
	local defaultLong = {"Flare Gun", "None", "None", "None"}

	if isTransformed then
		local myTitan = player:GetAttribute("Titan")
		defaultClose = {"Titan Punch", "Titan Kick", "Titan Roar", "Hardened Punch"}
		if myTitan == "Armored Titan" then defaultClose[4] = "Armored Tackle" 
		elseif myTitan == "Female Titan" then defaultClose[4] = "Crystal Kick"
		elseif myTitan == "Beast Titan" then defaultClose[4] = "Pitching Ace"
		elseif myTitan == "Colossal Titan" then defaultClose[4] = "Colossal Steam"
		end
	end

	local fallbacks = (currentRange == "Close") and defaultClose or defaultLong

	local function CreateSkillButton(skillName, customLabel, baseColor)
		if skillName == "None" then return end

		local sData = SkillData.Skills[skillName]
		local cd = (pState and pState.Cooldowns and pState.Cooldowns[skillName]) or 0
		local hasGas = true
		local hasHeat = true
		local isWrongRange = false

		if sData then
			if sData.GasCost and (pState.Gas or 0) < sData.GasCost then hasGas = false end
			if sData.EnergyCost and (pState.TitanEnergy or 0) < sData.EnergyCost then hasHeat = false end
			if sData.Range and sData.Range ~= "Any" and sData.Range ~= currentRange then
				isWrongRange = true
			end
		end

		local btnText = customLabel or string.upper(skillName)
		local btnColor = baseColor or "#DDDDDD"
		local isActive = true
		local errorReason = ""

		if cd > 0 then
			isActive = false
			errorReason = " [CD: " .. cd .. "]"
		elseif not hasGas then
			isActive = false
			errorReason = " [NO GAS]"
		elseif not hasHeat then
			isActive = false
			errorReason = " [NO HEAT]"
		elseif isWrongRange then
			btnColor = "#FFAA55"
			errorReason = " [OUT OF RANGE]"
		end

		btnText = btnText .. errorReason

		if not isActive then
			btnColor = "#555555"
		end

		local btn, stroke = CreateMinimalButton(ActionGrid, btnText, UDim2.new(0, 0, 0, 0), btnColor)

		if not isActive then
			btn.Active = false
			btn.TextColor3 = Color3.fromRGB(100, 100, 100)
			stroke.Color = Color3.fromRGB(50, 50, 50)
		else
			if isWrongRange then btn.TextColor3 = Color3.fromRGB(255, 170, 85) end
			btn.MouseButton1Click:Connect(function()
				if inputLocked then return end
				if InstantSkills[skillName] then
					inputLocked = true
					for _, c in ipairs(ActionGrid:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
					UIHelpers.CreateLabel(ActionGrid, "EXECUTING MANEUVER...", UDim2.new(0, 200, 0, 45), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 14)
					Network:WaitForChild("CombatAction"):FireServer("Attack", {SkillName = skillName})
				else
					pendingSkillName = skillName
					ActionGrid.Visible = false
					TargetMenu.Visible = true
				end
			end)
		end
	end

	-- 1. Standard Loadout Slots
	for i = 1, 4 do
		local skillName = player:GetAttribute("EquippedSkill_" .. i)
		if isTransformed or not skillName or skillName == "" or skillName == "None" then
			skillName = fallbacks[i]
		end
		CreateSkillButton(skillName)
	end

	-- 2. Innate Clan Skills (Dynamically Injected!)
	local myClan = player:GetAttribute("Clan")
	if myClan and myClan ~= "None" and not isTransformed then
		local clanSkills = {}
		for sName, sData in pairs(SkillData.Skills) do
			if sData.Type == "Style" and sData.Requirement and sData.Requirement ~= "ODM" and sData.Requirement ~= "Ultrahard Steel Blades" and sData.Requirement ~= "Thunder Spears" and sData.Requirement ~= "Anti-Personnel" then
				if string.find(myClan, sData.Requirement) then
					table.insert(clanSkills, {Name = sName, Data = sData})
				end
			end
		end
		table.sort(clanSkills, function(a, b) return (a.Data.Order or 99) < (b.Data.Order or 99) end)
		for _, cSkill in ipairs(clanSkills) do
			CreateSkillButton(cSkill.Name, "[" .. string.upper(myClan) .. "] " .. string.upper(cSkill.Name), "#CC44FF")
		end
	end

	-- 3. Universal Movement/Support Actions
	CreateSkillButton("Maneuver", "MANEUVER", "#55AAFF")

	local rSkill = isTransformed and "Titan Recover" or "Recover"
	CreateSkillButton(rSkill, string.upper(rSkill), "#55FF55")

	if currentRange == "Close" then
		CreateSkillButton("Fall Back", "FALL BACK", "#FFAA55")
	else
		CreateSkillButton("Close In", "CLOSE IN", "#FFAA55")
	end

	local hasTitan = player:GetAttribute("Titan") and player:GetAttribute("Titan") ~= "None"
	pHeatContainer.Visible = hasTitan 

	if hasTitan and not isTransformed then
		CreateSkillButton("Transform", "TRANSFORM", "#FFD700")
	elseif isTransformed then
		CreateSkillButton("Eject", "EJECT", "#FFD700")
	end

	CreateSkillButton("Retreat", "FLEE", "#FF5555")
end

function CombatUI.UpdateState(data)
	if not data or not data.Battle then return end
	currentBattleState = data.Battle
	local battle = data.Battle
	local tInfo = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

	local ctx = battle.Context
	if ctx then
		local modeStr = "UNKNOWN ENGAGEMENT"
		if ctx.IsStoryMission then modeStr = "STORY CAMPAIGN | PART " .. (ctx.TargetPart or 1) .. " - WAVE " .. (ctx.CurrentWave or 1)
		elseif ctx.IsEndless then modeStr = "ENDLESS FRONTIER | WAVE " .. (ctx.CurrentWave or 1)
		elseif ctx.IsNightmare then modeStr = "NIGHTMARE HUNT"
		elseif ctx.IsWorldBoss then modeStr = "WORLD BOSS RAID" end

		MissionInfoLbl.Text = modeStr .. "  [" .. (ctx.Range and ctx.Range:upper() or "CLOSE") .. " RANGE]"
	end

	if battle.Player.HP and battle.Player.MaxHP then
		local safeHP = math.max(0, battle.Player.HP)
		pHPText.Text = "HP " .. math.floor(safeHP) .. "/" .. math.floor(battle.Player.MaxHP)
		local hpScale = battle.Player.MaxHP > 0 and (safeHP / battle.Player.MaxHP) or 0
		TweenService:Create(pHPBar, tInfo, {Size = UDim2.new(hpScale, 0, 1, 0)}):Play()
	end
	if battle.Player.Gas and battle.Player.MaxGas then
		pGasText.Text = "GAS " .. math.floor(battle.Player.Gas) .. "/" .. math.floor(battle.Player.MaxGas)
		TweenService:Create(pGasBar, tInfo, {Size = UDim2.new(battle.Player.Gas / battle.Player.MaxGas, 0, 1, 0)}):Play()
	end
	if battle.Player.TitanEnergy and battle.Player.MaxTitanEnergy then
		pHeatText.Text = "HEAT " .. math.floor(battle.Player.TitanEnergy) .. "/" .. math.floor(battle.Player.MaxTitanEnergy)
		TweenService:Create(pHeatBar, tInfo, {Size = UDim2.new(battle.Player.TitanEnergy / battle.Player.MaxTitanEnergy, 0, 1, 0)}):Play()
	end

	if battle.Enemy.Name then eNameLbl.Text = battle.Enemy.Name:upper() end
	if battle.Enemy.HP and battle.Enemy.MaxHP then
		local safeHP = math.max(0, battle.Enemy.HP)
		eHPText.Text = "HP " .. math.floor(safeHP) .. "/" .. math.floor(battle.Enemy.MaxHP)
		local hpScale = battle.Enemy.MaxHP > 0 and (safeHP / battle.Enemy.MaxHP) or 0
		TweenService:Create(eHPBar, tInfo, {Size = UDim2.new(hpScale, 0, 1, 0)}):Play()
	end

	if battle.Enemy.MaxGateHP and battle.Enemy.MaxGateHP > 0 then
		eGateContainer.Visible = true
		local safeGate = math.max(0, battle.Enemy.GateHP or 0)
		eGateText.Text = "ARMOR " .. math.floor(safeGate) .. "/" .. math.floor(battle.Enemy.MaxGateHP)
		local gateScale = (safeGate / battle.Enemy.MaxGateHP)
		TweenService:Create(eGateBar, tInfo, {Size = UDim2.new(gateScale, 0, 1, 0)}):Play()
	else
		eGateContainer.Visible = false
	end

	RenderStatuses(PlayerStatusBox, battle.Player)
	RenderStatuses(EnemyStatusBox, battle.Enemy)
end

function CombatUI.AppendLog(message, colorHex)
	if not message or message == "" then return end

	local logColor = colorHex and Color3.fromHex(colorHex:gsub("#", "")) or UIHelpers.Colors.TextWhite

	local panel = Instance.new("Frame", LogScroll)
	panel.Size = UDim2.new(1, 0, 0, 0) 
	panel.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	panel.BackgroundTransparency = 0.3
	panel.BorderSizePixel = 0
	panel.AutomaticSize = Enum.AutomaticSize.Y
	local pStroke = Instance.new("UIStroke", panel)
	pStroke.Color = Color3.fromRGB(40, 40, 45)

	local pad = Instance.new("UIPadding", panel)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)

	local lbl = UIHelpers.CreateLabel(panel, message, UDim2.new(1, 0, 0, 0), Enum.Font.GothamMedium, logColor, 12)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.RichText = true
	lbl.TextWrapped = true
	lbl.AutomaticSize = Enum.AutomaticSize.Y

	local children = LogScroll:GetChildren()
	local logCount = 0
	for _, c in ipairs(children) do if c:IsA("Frame") then logCount += 1 end end
	if logCount > 30 then
		for _, c in ipairs(children) do
			if c:IsA("Frame") then c:Destroy() break end
		end
	end
end

function CombatUI.Show(data)
	pendingSkillName = nil
	inputLocked = false
	CombatBackdrop.Visible = true
	CombatWindow.Visible = true

	TweenService:Create(CombatBackdrop, TweenInfo.new(0.4), {BackgroundTransparency = 0.4}):Play()
	TweenService:Create(WindowScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

	for _, c in ipairs(LogScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	CombatUI.AppendLog("<b>[SYSTEM] Tactical Engagement Initiated.</b>", "#FFD700")

	if data and data.LogMsg then
		CombatUI.AppendLog(data.LogMsg)
	end

	if data and data.Battle then
		CombatUI.UpdateState(data)
	else
		CombatUI.UpdateState({
			Battle = {
				Context = {IsStoryMission = true, TargetPart = 1, CurrentWave = 1, Range = "Close"},
				Player = {HP = player:GetAttribute("Health") or 100, MaxHP = player:GetAttribute("MaxHealth") or 100, Gas = player:GetAttribute("Gas") or 50, MaxGas = 50, TitanEnergy = 0, MaxTitanEnergy = 100},
				Enemy = {Name = "Wandering Titan", HP = 500, MaxHP = 500}
			}
		})
	end
	CombatUI.UpdateSkills()
end

function CombatUI.Close()
	pendingSkillName = nil
	inputLocked = true
	local t1 = TweenService:Create(WindowScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
	local t2 = TweenService:Create(CombatBackdrop, TweenInfo.new(0.2), {BackgroundTransparency = 1})

	t1:Play(); t2:Play()
	t1.Completed:Wait()

	CombatWindow.Visible = false
	CombatBackdrop.Visible = false
	currentBattleState = nil
end

return CombatUI