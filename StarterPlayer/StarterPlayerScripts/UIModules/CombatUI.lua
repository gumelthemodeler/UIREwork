-- @ScriptType: ModuleScript
-- Name: CombatUI
-- @ScriptType: ModuleScript
local CombatUI = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local CombatBuilder = require(script.Parent:WaitForChild("CombatBuilder"))

local player = Players.LocalPlayer
local GUI = nil 

local currentBattleState = nil
local pendingSkillName = nil
local inputLocked = false
local isTypewriting = false
local skipTypewriting = false
local ClickSignal = Instance.new("BindableEvent")

local InstantSkills = {
	["Maneuver"] = true, ["Recover"] = true, ["Fall Back"] = true, ["Close In"] = true,
	["Retreat"] = true, ["Transform"] = true, ["Eject"] = true, ["Titan Recover"] = true
}

local function CreateMinimalButton(parent, text, size, baseColorHex)
	local btn = Instance.new("TextButton", parent)
	btn.Size = size; btn.BackgroundColor3 = Color3.fromRGB(22, 22, 26); btn.BorderSizePixel = 0
	btn.AutoButtonColor = false; btn.Font = Enum.Font.GothamBold; btn.TextSize = 13; btn.Text = text
	local cColor = Color3.fromHex(baseColorHex:gsub("#", ""))
	btn.TextColor3 = cColor
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(45, 45, 50); stroke.Thickness = 1; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	btn.MouseEnter:Connect(function() 
		if btn.Active then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}):Play(); TweenService:Create(stroke, TweenInfo.new(0.2), {Color = cColor}):Play() end
	end)
	btn.MouseLeave:Connect(function() 
		if btn.Active then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(22, 22, 26)}):Play(); TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(45, 45, 50)}):Play() end
	end)
	return btn
end

local function RenderStatuses(container, combatant)
	if not container then return end
	for _, child in ipairs(container:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	local function addIcon(iconTxt, bgColor, strokeColor)
		local f = Instance.new("Frame", container); f.Size = UDim2.new(0, 24, 0, 18); f.BackgroundColor3 = bgColor; Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
		local s = Instance.new("UIStroke", f); s.Color = strokeColor; s.Thickness = 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		local t = Instance.new("TextLabel", f); t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBlack; t.Text = iconTxt; t.TextColor3 = Color3.fromRGB(255,255,255); t.TextScaled = true
	end
	if combatant and combatant.Statuses then
		if combatant.Statuses.Dodge and combatant.Statuses.Dodge > 0 then addIcon("DGE", Color3.fromRGB(30, 60, 120), Color3.fromRGB(60, 100, 200)) end
		if combatant.Statuses.Transformed and combatant.Statuses.Transformed > 0 then addIcon("TTN", Color3.fromRGB(150, 40, 40), Color3.fromRGB(200, 60, 60)) end
		for sName, duration in pairs(combatant.Statuses) do
			if sName == "Telegraphing" and type(duration) == "string" then addIcon("WRN", Color3.fromRGB(200, 100, 0), Color3.fromRGB(255, 150, 0))
			elseif type(duration) == "number" and duration > 0 then
				if sName == "Bleed" then addIcon("BLD", Color3.fromRGB(150, 20, 20), Color3.fromRGB(255, 50, 50))
				elseif sName == "Burn" then addIcon("BRN", Color3.fromRGB(200, 80, 20), Color3.fromRGB(255, 120, 50))
				elseif sName == "Stun" then addIcon("STN", Color3.fromRGB(200, 200, 80), Color3.fromRGB(255, 255, 150))
				end
			end
		end
	end
end

local function AppendLog(message, colorHex)
	if not GUI or not GUI.LogScroll or not message or message == "" then return end
	local logColor = colorHex and Color3.fromHex(colorHex:gsub("#", "")) or UIHelpers.Colors.TextWhite
	local panel = Instance.new("Frame", GUI.LogScroll)
	panel.Size = UDim2.new(1, 0, 0, 0); panel.BackgroundColor3 = Color3.fromRGB(15, 15, 18); panel.BackgroundTransparency = 0.3; panel.BorderSizePixel = 0; panel.AutomaticSize = Enum.AutomaticSize.Y
	local pStroke = Instance.new("UIStroke", panel); pStroke.Color = Color3.fromRGB(40, 40, 45)
	local pad = Instance.new("UIPadding", panel); pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10); pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8)
	local lbl = UIHelpers.CreateLabel(panel, message, UDim2.new(1, 0, 0, 0), Enum.Font.GothamMedium, logColor, 12)
	lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.RichText = true; lbl.TextWrapped = true; lbl.AutomaticSize = Enum.AutomaticSize.Y

	local children = GUI.LogScroll:GetChildren()
	local logCount = 0; for _, c in ipairs(children) do if c:IsA("Frame") then logCount += 1 end end
	if logCount > 30 then for _, c in ipairs(children) do if c:IsA("Frame") then c:Destroy() break end end end
end

local function UpdateState(data)
	if not data or not data.Battle or not GUI then return end
	currentBattleState = data.Battle; local battle = data.Battle
	local tInfo = TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

	local ctx = battle.Context
	if ctx and GUI.MissionInfoLbl then
		local modeStr = "UNKNOWN ENGAGEMENT"
		if ctx.IsStoryMission then modeStr = "STORY CAMPAIGN | PART " .. (ctx.TargetPart or 1) .. " - WAVE " .. (ctx.CurrentWave or 1)
		elseif ctx.IsEndless then modeStr = "ENDLESS FRONTIER | WAVE " .. (ctx.CurrentWave or 1)
		elseif ctx.IsNightmare then modeStr = "NIGHTMARE HUNT"
		elseif ctx.IsWorldBoss then modeStr = "WORLD BOSS RAID" end
		GUI.MissionInfoLbl.Text = modeStr .. "  [" .. (ctx.Range and ctx.Range:upper() or "CLOSE") .. " RANGE]"
	end

	if battle.Player then
		local safeHP = math.max(0, battle.Player.HP or 0); local maxHP = battle.Player.MaxHP or 100
		GUI.pHPText.Text = "HP " .. math.floor(safeHP) .. "/" .. math.floor(maxHP)
		TweenService:Create(GUI.pHPBar, tInfo, {Size = UDim2.new(maxHP > 0 and (safeHP / maxHP) or 0, 0, 1, 0)}):Play()

		local gas = battle.Player.Gas or 0; local maxGas = battle.Player.MaxGas or 50
		GUI.pGasText.Text = "GAS " .. math.floor(gas) .. "/" .. math.floor(maxGas)
		TweenService:Create(GUI.pGasBar, tInfo, {Size = UDim2.new(maxGas > 0 and (gas / maxGas) or 0, 0, 1, 0)}):Play()

		local heat = battle.Player.TitanEnergy or 0; local maxHeat = battle.Player.MaxTitanEnergy or 100
		GUI.pHeatText.Text = "HEAT " .. math.floor(heat) .. "/" .. math.floor(maxHeat)
		TweenService:Create(GUI.pHeatBar, tInfo, {Size = UDim2.new(maxHeat > 0 and (heat / maxHeat) or 0, 0, 1, 0)}):Play()
	end

	if battle.Enemy then 
		GUI.eNameLbl.Text = (battle.Enemy.Name or "UNKNOWN"):upper() 
		local EnemyDataModule = require(ReplicatedStorage:WaitForChild("EnemyData"))
		if EnemyDataModule and EnemyDataModule.BossIcons and EnemyDataModule.BossIcons[battle.Enemy.Name] then
			GUI.eAvatar.Image = EnemyDataModule.BossIcons[battle.Enemy.Name]
		else
			GUI.eAvatar.Image = "rbxassetid://90132878979603"
		end

		if battle.Enemy.IsDialogue then
			GUI.eHPText.Parent.Visible = false
			GUI.eGateContainer.Visible = false
		else
			GUI.eHPText.Parent.Visible = true
			local safeHP = math.max(0, battle.Enemy.HP or 0); local maxHP = battle.Enemy.MaxHP or 100
			GUI.eHPText.Text = "HP " .. math.floor(safeHP) .. "/" .. math.floor(maxHP)
			TweenService:Create(GUI.eHPBar, tInfo, {Size = UDim2.new(maxHP > 0 and (safeHP / maxHP) or 0, 0, 1, 0)}):Play()

			local maxGate = battle.Enemy.MaxGateHP or 0
			if maxGate > 0 then
				GUI.eGateContainer.Visible = true
				local safeGate = math.max(0, battle.Enemy.GateHP or 0)
				GUI.eGateText.Text = "ARMOR " .. math.floor(safeGate) .. "/" .. math.floor(maxGate)
				TweenService:Create(GUI.eGateBar, tInfo, {Size = UDim2.new(safeGate / maxGate, 0, 1, 0)}):Play()
			else
				GUI.eGateContainer.Visible = false
			end
		end
	end

	RenderStatuses(GUI.PlayerStatusBox, battle.Player)
	RenderStatuses(GUI.EnemyStatusBox, battle.Enemy)
end

local function UpdateSkills()
	inputLocked = false
	if GUI.ActionGrid then GUI.ActionGrid.Visible = true end
	if GUI.TargetMenu then GUI.TargetMenu.Visible = false end
	if GUI.ActionGrid then for _, c in ipairs(GUI.ActionGrid:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end end

	local currentRange = "Close"
	local pState = currentBattleState and currentBattleState.Player or nil
	if currentBattleState and currentBattleState.Context and currentBattleState.Context.Range then currentRange = currentBattleState.Context.Range end

	local isTransformed = pState and pState.Statuses and pState.Statuses["Transformed"]
	local defaultClose = {"Basic Slash", "Heavy Slash", "None", "None"}
	local defaultLong = {"Flare Gun", "None", "None", "None"}

	if isTransformed then
		local myTitan = player:GetAttribute("Titan")
		defaultClose = {"Titan Punch", "Titan Kick", "Titan Roar", "Hardened Punch"}
		if myTitan == "Armored Titan" then defaultClose[4] = "Armored Tackle" 
		elseif myTitan == "Female Titan" then defaultClose[4] = "Crystal Kick"
		elseif myTitan == "Beast Titan" then defaultClose[4] = "Pitching Ace"
		elseif myTitan == "Colossal Titan" then defaultClose[4] = "Colossal Steam" end
	end

	local fallbacks = (currentRange == "Close") and defaultClose or defaultLong

	-- [[ THE FIX: Deduplication logic so manually added buttons don't double up! ]]
	local createdSkills = {}

	local function CreateSkillButton(skillName, customLabel, baseColor)
		if skillName == "None" or not GUI.ActionGrid then return end
		if createdSkills[skillName] then return end
		createdSkills[skillName] = true

		local sData = SkillData.Skills[skillName]
		local cd = (pState and pState.Cooldowns and pState.Cooldowns[skillName]) or 0
		local hasGas, hasHeat, isWrongRange = true, true, false

		if sData then
			if sData.GasCost and (pState.Gas or 0) < sData.GasCost then hasGas = false end
			if sData.EnergyCost and (pState.TitanEnergy or 0) < sData.EnergyCost then hasHeat = false end
			if sData.Range and sData.Range ~= "Any" and sData.Range ~= currentRange then isWrongRange = true end
		end

		local btnText = customLabel or string.upper(skillName)
		local btnColor = baseColor or "#DDDDDD"
		local isActive = true
		local errorReason = ""

		if cd > 0 then isActive = false; errorReason = " [CD: " .. cd .. "]"
		elseif not hasGas then isActive = false; errorReason = " [NO GAS]"
		elseif not hasHeat then isActive = false; errorReason = " [NO HEAT]"
		elseif isWrongRange then btnColor = "#FFAA55"; errorReason = " [OUT OF RANGE]" end

		btnText = btnText .. errorReason
		if not isActive then btnColor = "#555555" end
		local btn = CreateMinimalButton(GUI.ActionGrid, btnText, UDim2.new(0, 0, 0, 0), btnColor)

		if not isActive then
			btn.Active = false; btn.TextColor3 = Color3.fromRGB(100, 100, 100)
			local stroke = btn:FindFirstChild("UIStroke"); if stroke then stroke.Color = Color3.fromRGB(50, 50, 50) end
		else
			if isWrongRange then btn.TextColor3 = Color3.fromRGB(255, 170, 85) end
			btn.MouseButton1Click:Connect(function()
				if inputLocked then return end
				if InstantSkills[skillName] then
					inputLocked = true
					for _, c in ipairs(GUI.ActionGrid:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
					UIHelpers.CreateLabel(GUI.ActionGrid, "EXECUTING MANEUVER...", UDim2.new(0, 200, 0, 45), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 14)
					Network:WaitForChild("CombatAction"):FireServer("Attack", {SkillName = skillName})
				else
					pendingSkillName = skillName
					GUI.ActionGrid.Visible = false
					GUI.TargetMenu.Visible = true
				end
			end)
		end
	end

	for i = 1, 4 do
		local skillName = player:GetAttribute("EquippedSkill_" .. i)
		if isTransformed or not skillName or skillName == "" or skillName == "None" then skillName = fallbacks[i] end
		CreateSkillButton(skillName)
	end

	local myClan = player:GetAttribute("Clan")
	if myClan and myClan ~= "None" and not isTransformed then
		local clanSkills = {}
		for sName, sData in pairs(SkillData.Skills) do
			if sData.Type == "Style" and sData.Requirement and not string.find(sData.Requirement, "ODM") then
				if string.find(myClan, sData.Requirement) then table.insert(clanSkills, {Name = sName, Data = sData}) end
			end
		end
		table.sort(clanSkills, function(a, b) return (a.Data.Order or 99) < (b.Data.Order or 99) end)
		for _, cSkill in ipairs(clanSkills) do CreateSkillButton(cSkill.Name, "[" .. string.upper(myClan) .. "] " .. string.upper(cSkill.Name), "#CC44FF") end
	end

	CreateSkillButton("Maneuver", "MANEUVER", "#55AAFF")
	local rSkill = isTransformed and "Titan Recover" or "Recover"
	CreateSkillButton(rSkill, string.upper(rSkill), "#55FF55")

	if currentRange == "Close" then CreateSkillButton("Fall Back", "FALL BACK", "#FFAA55")
	else CreateSkillButton("Close In", "CLOSE IN", "#FFAA55") end

	local hasTitan = player:GetAttribute("Titan") and player:GetAttribute("Titan") ~= "None"
	if GUI.pHeatContainer then GUI.pHeatContainer.Visible = hasTitan end
	if hasTitan and not isTransformed then CreateSkillButton("Transform", "TRANSFORM", "#FFD700")
	elseif isTransformed then CreateSkillButton("Eject", "EJECT", "#FFD700") end

	CreateSkillButton("Retreat", "FLEE", "#FF5555")
end

local function ShowUI(data)
	pendingSkillName = nil
	inputLocked = false

	if GUI.CombatBackdrop then
		GUI.CombatBackdrop.Visible = true
		TweenService:Create(GUI.CombatBackdrop, TweenInfo.new(0.4), {BackgroundTransparency = 0.4}):Play()
	end
	if GUI.CombatWindow then GUI.CombatWindow.Visible = true end
	if GUI.CombatantsFrame then GUI.CombatantsFrame.Visible = true end
	if GUI.WindowScale then TweenService:Create(GUI.WindowScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play() end
	if GUI.LogContainer then GUI.LogContainer.Visible = true end
	if GUI.ActionContainer then GUI.ActionContainer.Visible = true end
	if GUI.DialogueBox then GUI.DialogueBox.Visible = false end
	if GUI.ClickOverlay then GUI.ClickOverlay.Visible = false end

	if GUI.LogScroll then
		for _, c in ipairs(GUI.LogScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	end

	AppendLog("<b>[SYSTEM] Tactical Engagement Initiated.</b>", "#FFD700")

	if data and data.LogMsg then AppendLog(data.LogMsg) end

	if data and data.Battle then
		if data.Battle.Enemy and data.Battle.Enemy.IsDialogue and GUI.CombatantsFrame then
			GUI.CombatantsFrame.Visible = false
		end
		UpdateState(data)
	else
		UpdateState({
			Battle = {
				Context = {IsStoryMission = true, TargetPart = 1, CurrentWave = 1, Range = "Close"},
				Player = {HP = player:GetAttribute("Health") or 100, MaxHP = player:GetAttribute("MaxHealth") or 100, Gas = player:GetAttribute("Gas") or 50, MaxGas = 50, TitanEnergy = 0, MaxTitanEnergy = 100},
				Enemy = {Name = "Wandering Titan", HP = 500, MaxHP = 500}
			}
		})
	end
	UpdateSkills()
end

local function CloseUI()
	pendingSkillName = nil
	inputLocked = true

	if GUI.WindowScale then
		local t1 = TweenService:Create(GUI.WindowScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
		t1:Play()
		t1.Completed:Wait()
	end

	if GUI.CombatBackdrop then
		local t2 = TweenService:Create(GUI.CombatBackdrop, TweenInfo.new(0.2), {BackgroundTransparency = 1})
		t2:Play()
		GUI.CombatBackdrop.Visible = false
	end

	if GUI.CombatWindow then GUI.CombatWindow.Visible = false end
	currentBattleState = nil
end

-- ==========================================
-- INITIALIZATION
-- ==========================================
function CombatUI.Initialize(masterScreenGui)
	GUI = CombatBuilder.Build(masterScreenGui, player)

	GUI.ClickOverlay.MouseButton1Click:Connect(function()
		if isTypewriting then skipTypewriting = true else ClickSignal:Fire() end
	end)

	for targetId, limbBtn in pairs(GUI.Limbs) do
		limbBtn.MouseButton1Click:Connect(function()
			if pendingSkillName and not inputLocked then
				inputLocked = true
				if GUI.TargetMenu then GUI.TargetMenu.Visible = false end
				if GUI.ActionGrid then GUI.ActionGrid.Visible = true end

				if GUI.ActionGrid then
					for _, c in ipairs(GUI.ActionGrid:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
					UIHelpers.CreateLabel(GUI.ActionGrid, "EXECUTING MANEUVER...", UDim2.new(0, 200, 0, 45), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 14)
				end
				local trueTarget = targetId
				if targetId == "LArm" or targetId == "RArm" then trueTarget = "Arms" end
				if targetId == "LLeg" or targetId == "RLeg" then trueTarget = "Legs" end
				Network:WaitForChild("CombatAction"):FireServer("Attack", {SkillName = pendingSkillName, TargetLimb = trueTarget})
				pendingSkillName = nil
			end
		end)
	end

	GUI.CancelBtn.MouseButton1Click:Connect(function()
		if GUI.TargetMenu then GUI.TargetMenu.Visible = false end
		if GUI.ActionGrid then GUI.ActionGrid.Visible = true end
		pendingSkillName = nil 
	end)

	Network:WaitForChild("CombatUpdate").OnClientEvent:Connect(function(action, data)
		if action == "Start" or action == "StartMinigame" then
			ShowUI(data)

		elseif action == "Update" then
			if GUI.CombatantsFrame then GUI.CombatantsFrame.Visible = true end
			if GUI.LogContainer then GUI.LogContainer.Visible = true end
			if GUI.ActionContainer then GUI.ActionContainer.Visible = true end
			if GUI.DialogueBox then GUI.DialogueBox.Visible = false end
			if GUI.ClickOverlay then GUI.ClickOverlay.Visible = false end
			UpdateState(data)
			UpdateSkills()

		elseif action == "Dialogue" then
			if GUI.CombatWindow and not GUI.CombatWindow.Visible then
				if GUI.CombatBackdrop then GUI.CombatBackdrop.Visible = true; TweenService:Create(GUI.CombatBackdrop, TweenInfo.new(0.4), {BackgroundTransparency = 0.4}):Play() end
				GUI.CombatWindow.Visible = true
				if GUI.WindowScale then TweenService:Create(GUI.WindowScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play() end
			end

			if GUI.CombatantsFrame then GUI.CombatantsFrame.Visible = true end
			UpdateState(data)

			inputLocked = true
			if GUI.LogContainer then GUI.LogContainer.Visible = false end
			if GUI.ActionContainer then GUI.ActionContainer.Visible = false end
			if GUI.DialogueBox then GUI.DialogueBox.Visible = true end

			task.spawn(function()
				GUI.ClickOverlay.Visible = true
				GUI.ChoicesContainer.Visible = false

				local dialoguesArray = data.Dialogues or { { Speaker = data.Speaker or "Unknown", Text = data.Text or "..." } }

				for _, line in ipairs(dialoguesArray) do
					GUI.SpeakerLbl.Text = line.Speaker or "Unknown"
					GUI.SpeakerLbl.TextColor3 = (line.Speaker == "System") and UIHelpers.Colors.TextMuted or UIHelpers.Colors.Gold

					local EnemyDataModule = require(ReplicatedStorage:WaitForChild("EnemyData"))
					if EnemyDataModule and EnemyDataModule.BossIcons and EnemyDataModule.BossIcons[line.Speaker] then
						if GUI.eAvatar then GUI.eAvatar.Image = EnemyDataModule.BossIcons[line.Speaker] end
					else
						if GUI.eAvatar then GUI.eAvatar.Image = "rbxassetid://90132878979603" end
					end
					if GUI.eNameLbl then GUI.eNameLbl.Text = string.upper(line.Speaker or "Unknown") end

					GUI.DialogueText.Text = ""
					GUI.DialogueText.Visible = true
					isTypewriting = true; skipTypewriting = false

					for charIdx = 1, #(line.Text or "") do
						if skipTypewriting then GUI.DialogueText.Text = line.Text; break end
						GUI.DialogueText.Text = string.sub(line.Text, 1, charIdx)
						if charIdx % 2 == 0 then
							local VFXManager = require(script.Parent.Parent:WaitForChild("VFXManager"))
							if VFXManager then VFXManager.PlaySFX("Click", 1.5, 0.2) end
						end
						task.wait(0.015)
					end
					isTypewriting = false
					GUI.ContinueHint.Visible = true
					ClickSignal.Event:Wait()
					GUI.ContinueHint.Visible = false
				end

				GUI.ClickOverlay.Visible = false
				GUI.DialogueText.Visible = false
				GUI.ChoicesContainer.Visible = true

				for _, c in ipairs(GUI.ChoicesContainer:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end

				local choicesArray = data.Choices or {"CONTINUE STORY"}
				for idx, choiceText in ipairs(choicesArray) do
					local btn = CreateMinimalButton(GUI.ChoicesContainer, choiceText, UDim2.new(0, 300, 0, 40), "#55FF55")
					btn.MouseButton1Click:Connect(function()
						GUI.DialogueBox.Visible = false
						if GUI.LogContainer then GUI.LogContainer.Visible = true end
						if GUI.ActionContainer then GUI.ActionContainer.Visible = true end

						local rewards = data.Battle and data.Battle.Enemy and data.Battle.Enemy.Rewards
						local rewardStr = ""
						if rewards then
							if rewards.ItemName then rewardStr = rewardStr .. " [" .. (rewards.Amount or 1) .. "x " .. rewards.ItemName .. "]" end
							if rewards.Dews then rewardStr = rewardStr .. " [" .. rewards.Dews .. " Dews]" end
							if rewards.XP then rewardStr = rewardStr .. " [" .. rewards.XP .. " XP]" end
						end

						if rewardStr ~= "" then
							AppendLog("<b><font color='#55FF55'>REWARDS OBTAINED:</font></b>\n<font color='#55FF55'>" .. rewardStr .. "</font>")
							local VFXManager = require(script.Parent.Parent:WaitForChild("VFXManager"))
							if VFXManager then VFXManager.PlaySFX("Reveal", 1) end
						end

						Network:WaitForChild("CombatAction"):FireServer("MinigameResult", { Success = true, MinigameType = "Dialogue", Choice = idx }) 
					end)
				end
			end)

		elseif action == "TurnStrike" then
			if GUI.CombatantsFrame then GUI.CombatantsFrame.Visible = true end
			UpdateState(data)

			local VFXManager = require(script.Parent.Parent:WaitForChild("VFXManager"))
			if VFXManager and data then VFXManager.PlayCombatEffect(data.SkillUsed, data.IsPlayerAttacking, GUI.pAvatar, GUI.eAvatar, data.DidHit) end

			if data and data.ShakeType == "Heavy" then if VFXManager then VFXManager.ScreenShake(0.5, 0.25) end
			elseif data and data.ShakeType == "Light" then if VFXManager then VFXManager.ScreenShake(0.2, 0.15) end end

			if data and data.LogMsg then AppendLog(data.LogMsg, data.IsPlayerAttacking and "#55AAFF" or "#FF5555") end

		elseif action == "WaveComplete" then
			if GUI.CombatantsFrame then GUI.CombatantsFrame.Visible = true end
			if GUI.LogContainer then GUI.LogContainer.Visible = true end
			if GUI.ActionContainer then GUI.ActionContainer.Visible = true end
			if GUI.DialogueBox then GUI.DialogueBox.Visible = false end
			UpdateState(data)
			AppendLog("<b><font color='#55FF55'>WAVE CLEARED!</font></b>", "#55FF55")
			if data and data.LogMsg then AppendLog(data.LogMsg, "#FFD700") end

			inputLocked = true
			if GUI.ActionGrid then
				for _, c in ipairs(GUI.ActionGrid:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
				GUI.ActionGrid.Visible = true
			end
			if GUI.TargetMenu then GUI.TargetMenu.Visible = false end

			if GUI.ActionGrid then
				local continueBtn = CreateMinimalButton(GUI.ActionGrid, "CONTINUE EXPEDITION", UDim2.new(0, 0, 0, 0), "#55FF55")
				continueBtn.MouseButton1Click:Connect(function()
					UpdateSkills()
				end)

				local retreatBtn = CreateMinimalButton(GUI.ActionGrid, "RETREAT TO COMMAND", UDim2.new(0, 0, 0, 0), "#FF5555")
				retreatBtn.MouseButton1Click:Connect(function()
					Network:WaitForChild("CombatAction"):FireServer("Attack", {SkillName = "Retreat"})
					CloseUI()
					local MusicManager = require(script.Parent.Parent:WaitForChild("MusicManager"))
					if MusicManager then MusicManager.SetCategory("Lobby") end
				end)
			end

		elseif action == "Victory" then
			if GUI.CombatantsFrame then GUI.CombatantsFrame.Visible = true end
			if GUI.LogContainer then GUI.LogContainer.Visible = true end
			if GUI.ActionContainer then GUI.ActionContainer.Visible = true end
			if GUI.DialogueBox then GUI.DialogueBox.Visible = false end
			UpdateState(data)

			local xpGained = data and data.XP or 0; local dewsGained = data and data.Dews or 0
			AppendLog("<b><font color='#55FF55'>VICTORY!</font></b>\nEarned " .. xpGained .. " XP and " .. dewsGained .. " Dews.", "#55FF55")
			if data and data.ExtraLog and data.ExtraLog ~= "" then AppendLog(data.ExtraLog) end

			local VFXManager = require(script.Parent.Parent:WaitForChild("VFXManager"))
			if VFXManager then VFXManager.PlaySFX("Victory", 1.0) end

			inputLocked = true
			if GUI.ActionGrid then
				for _, c in ipairs(GUI.ActionGrid:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
				GUI.ActionGrid.Visible = true
			end
			if GUI.TargetMenu then GUI.TargetMenu.Visible = false end

			if GUI.ActionGrid then
				if data and data.Battle and data.Battle.Context and data.Battle.Context.IsStoryMission then
					local continueCampBtn = CreateMinimalButton(GUI.ActionGrid, "CONTINUE CAMPAIGN", UDim2.new(0, 0, 0, 0), "#FFD700")
					continueCampBtn.MouseButton1Click:Connect(function()
						Network:WaitForChild("CombatAction"):FireServer("EngageStory")
					end)
				end

				local closeBtn = CreateMinimalButton(GUI.ActionGrid, "RETURN TO COMMAND", UDim2.new(0, 0, 0, 0), "#55FF55")
				closeBtn.MouseButton1Click:Connect(function() 
					CloseUI() 
					local MusicManager = require(script.Parent.Parent:WaitForChild("MusicManager"))
					if MusicManager then MusicManager.SetCategory("Lobby") end
				end)
			end

		elseif action == "Defeat" or action == "PathsDeath" then
			if GUI.CombatantsFrame then GUI.CombatantsFrame.Visible = true end
			if GUI.LogContainer then GUI.LogContainer.Visible = true end
			if GUI.ActionContainer then GUI.ActionContainer.Visible = true end
			if GUI.DialogueBox then GUI.DialogueBox.Visible = false end
			UpdateState(data)
			AppendLog("<b><font color='#FF5555'>DEFEAT...</font></b> Your forces were wiped out.", "#FF5555")

			local VFXManager = require(script.Parent.Parent:WaitForChild("VFXManager"))
			if VFXManager then VFXManager.PlaySFX("Defeat", 1.0) end

			inputLocked = true
			if GUI.ActionGrid then
				for _, c in ipairs(GUI.ActionGrid:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
				GUI.ActionGrid.Visible = true
			end
			if GUI.TargetMenu then GUI.TargetMenu.Visible = false end

			if GUI.ActionGrid then
				local closeBtn = CreateMinimalButton(GUI.ActionGrid, "RETURN TO COMMAND", UDim2.new(0, 0, 0, 0), "#FF5555")
				closeBtn.MouseButton1Click:Connect(function() 
					CloseUI() 
					local MusicManager = require(script.Parent.Parent:WaitForChild("MusicManager"))
					if MusicManager then MusicManager.SetCategory("Lobby") end
				end)
			end

		elseif action == "Fled" then
			if GUI.CombatantsFrame then GUI.CombatantsFrame.Visible = true end
			AppendLog("<b><font color='#AAAAAA'>YOU FLED THE BATTLE.</font></b>", "#AAAAAA")
			task.wait(1.5)
			CloseUI()
			local MusicManager = require(script.Parent.Parent:WaitForChild("MusicManager"))
			if MusicManager then MusicManager.SetCategory("Lobby") end
		end
	end)
end

CombatUI.UpdateSkills = UpdateSkills
CombatUI.UpdateState = UpdateState
CombatUI.AppendLog = AppendLog
CombatUI.Show = ShowUI
CombatUI.Close = CloseUI

return CombatUI