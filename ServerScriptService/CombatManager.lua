-- @ScriptType: Script
-- @ScriptType: Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local ClanData = require(ReplicatedStorage:WaitForChild("ClanData"))
local CombatCore = require(script.Parent:WaitForChild("CombatCore"))
local LootManager = require(script.Parent:WaitForChild("LootManager")) 

local Network = ReplicatedStorage:FindFirstChild("Network") or Instance.new("Folder", ReplicatedStorage)
Network.Name = "Network"

local function GetRemote(name)
	local r = Network:FindFirstChild(name)
	if not r then r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = Network end
	return r
end

local CombatAction = GetRemote("CombatAction")
local CombatUpdate = GetRemote("CombatUpdate")
local PlayVFX = GetRemote("PlayVFX") 

local ActiveBattles = {}

local function UpdateBountyProgress(plr, taskType, amt)
	for i = 1, 3 do
		if plr:GetAttribute("D"..i.."_Task") == taskType and not plr:GetAttribute("D"..i.."_Claimed") then
			local p = plr:GetAttribute("D"..i.."_Prog") or 0
			local m = plr:GetAttribute("D"..i.."_Max") or 1
			plr:SetAttribute("D"..i.."_Prog", math.min(p + amt, m))
		end
	end
	if plr:GetAttribute("W1_Task") == taskType and not plr:GetAttribute("W1_Claimed") then
		local p = plr:GetAttribute("W1_Prog") or 0
		local m = plr:GetAttribute("W1_Max") or 1
		plr:SetAttribute("W1_Prog", math.min(p + amt, m))
	end
end

local function GetTemplate(partData, templateName)
	if partData.Templates and partData.Templates[templateName] then return partData.Templates[templateName] end
	for _, mob in ipairs(partData.Mobs) do if mob.Name == templateName then return mob end end
	return partData.Mobs[1] 
end

local function GetHPScale(targetPart, prestige)
	local chapterScale = math.pow(1.20, targetPart - 1) 
	local prestigeScale = math.pow(1.25, prestige) 
	return chapterScale * prestigeScale
end
local function GetDmgScale(targetPart, prestige)
	local chapterScale = math.pow(1.15, targetPart - 1) 
	local prestigeScale = math.pow(1.15, prestige) 
	return chapterScale * prestigeScale
end
local function GetSpdScale(targetPart, prestige)
	return 1.0 + (math.pow(targetPart, 0.5) * 0.1) + (math.pow(prestige, 0.6) * 0.2)
end
local function GetActualStyle(plr)
	local eqWpn = plr:GetAttribute("EquippedWeapon") or "None"
	if ItemData.Equipment[eqWpn] and ItemData.Equipment[eqWpn].Style then return ItemData.Equipment[eqWpn].Style end
	return "None"
end
local function ParseAwakenedStats(statString)
	local stats = { DmgMult = 1.0, DodgeBonus = 0, CritBonus = 0, HpBonus = 0, SpdBonus = 0, GasBonus = 0, HealOnKill = 0, IgnoreArmor = 0 }
	if not statString or statString == "" then return stats end
	for stat in string.gmatch(statString, "[^|]+") do
		stat = stat:match("^%s*(.-)%s*$")
		if stat:find("DMG") then stats.DmgMult += tonumber(stat:match("%d+")) / 100
		elseif stat:find("DODGE") then stats.DodgeBonus += tonumber(stat:match("%d+"))
		elseif stat:find("CRIT") then stats.CritBonus += tonumber(stat:match("%d+"))
		elseif stat:find("MAX HP") then stats.HpBonus += tonumber(stat:match("%d+"))
		elseif stat:find("SPEED") then stats.SpdBonus += tonumber(stat:match("%d+"))
		elseif stat:find("GAS CAP") then stats.GasBonus += tonumber(stat:match("%d+"))
		elseif stat:find("HEAL") then stats.HealOnKill += tonumber(stat:match("%d+")) / 100
		end
	end
	return stats
end

local function StartBattle(player, encounterType, requestedPartId)
	local currentPart = player:GetAttribute("CurrentPart") or 1
	local eTemplate, logFlavor
	local isStory, isEndless, isPaths, isWorldBoss, isNightmare = false, false, false, false, false
	local activeMissionData = nil
	local totalWaves, startingWave = 1, 1
	local targetPart = currentPart
	local prestige = player:FindFirstChild("leaderstats") and player.leaderstats.Prestige.Value or 0

	if encounterType == "EngageStory" then
		isStory = true
		targetPart = requestedPartId or currentPart
		if type(targetPart) == "number" and targetPart > currentPart then targetPart = currentPart end
		local partData = EnemyData.Parts[targetPart]
		if not partData then return end

		if targetPart == currentPart then startingWave = player:GetAttribute("CurrentWave") or 1 else startingWave = 1 end
		local missionTable = (prestige > 0 and partData.PrestigeMissions) and partData.PrestigeMissions or partData.Missions
		activeMissionData = missionTable[1]
		totalWaves = #activeMissionData.Waves
		if startingWave > totalWaves then startingWave = totalWaves end

		local waveData = activeMissionData.Waves[startingWave]
		eTemplate = GetTemplate(partData, waveData.Template)
		logFlavor = "<font color='#FFD700'>[Mission: " .. (activeMissionData.Name or "Unknown") .. "]</font>\n" .. (waveData.Flavor or "")
	else
		targetPart = math.min(8, currentPart)
		local partData = EnemyData.Parts[targetPart]
		eTemplate = partData.Mobs[math.random(1, #partData.Mobs)]
		local flavors = partData.RandomFlavor or {"You encounter a %s!"}
		logFlavor = string.format(flavors[math.random(1, #flavors)], eTemplate.Name)
	end

	local hpMult = GetHPScale(targetPart, prestige)
	local dmgMult = GetDmgScale(targetPart, prestige)
	local spdMult = GetSpdScale(targetPart, prestige)
	local dropMult = 1.0 + (targetPart * 0.1) + (prestige * 0.25)

	local wpnName = player:GetAttribute("EquippedWeapon") or "None"
	local accName = player:GetAttribute("EquippedAccessory") or "None"
	local wpnBonus = (ItemData.Equipment[wpnName] and ItemData.Equipment[wpnName].Bonus) or {}
	local accBonus = (ItemData.Equipment[accName] and ItemData.Equipment[accName].Bonus) or {}

	local safeWpnName = wpnName:gsub("[^%w]", "")
	local combinedAwakenedString = (player:GetAttribute(safeWpnName .. "_Awakened") or "") .. " | " .. (player:GetAttribute("PathsAwakened") or "")
	local awakenedStats = ParseAwakenedStats(combinedAwakenedString)

	local clanName = player:GetAttribute("Clan") or "None"
	local isAwakenedClan = string.find(tostring(clanName or ""), "Awakened") ~= nil
	local cStats = ClanData.GetClanStats(clanName, isAwakenedClan, player:GetAttribute("Titan"), false)

	local pMaxHP = ((player:GetAttribute("Health") or 10) + (wpnBonus.Health or 0) + (accBonus.Health or 0)) * 10
	pMaxHP = math.floor((pMaxHP + awakenedStats.HpBonus) * cStats.HpMult)
	local pMaxGas = (((player:GetAttribute("Gas") or 10) + (wpnBonus.Gas or 0) + (accBonus.Gas or 0)) * 10) + awakenedStats.GasBonus
	local pTotalStr = (player:GetAttribute("Strength") or 10) + (wpnBonus.Strength or 0) + (accBonus.Strength or 0)
	local pTotalDef = (player:GetAttribute("Defense") or 10) + (wpnBonus.Defense or 0) + (accBonus.Defense or 0)
	local pTotalSpd = (player:GetAttribute("Speed") or 10) + (wpnBonus.Speed or 0) + (accBonus.Speed or 0) + awakenedStats.SpdBonus
	local pTotalRes = (player:GetAttribute("Resolve") or 10) + (wpnBonus.Resolve or 0) + (accBonus.Resolve or 0)

	-- [[ THE FIX: Fully generate player context before returning dialogue, giving TotalSpeed and Stats so it cannot crash ]]
	if eTemplate.IsDialogue then
		ActiveBattles[player.UserId] = {
			IsProcessing = false,
			Context = { IsStoryMission = isStory, TargetPart = targetPart, CurrentWave = startingWave, TotalWaves = totalWaves, MissionData = activeMissionData, TurnCount = 0, Range = "Close" },
			Player = { IsPlayer = true, Name = player.Name, PlayerObj = player, Titan = player:GetAttribute("Titan") or "None", Style = GetActualStyle(player), Clan = clanName, HP = pMaxHP, MaxHP = pMaxHP, TitanEnergy = 100, MaxTitanEnergy = 100, Gas = pMaxGas, MaxGas = pMaxGas, TotalStrength = pTotalStr, TotalDefense = pTotalDef, TotalSpeed = pTotalSpd, TotalResolve = pTotalRes, Statuses = {}, Cooldowns = {}, LastSkill = "None", AwakenedStats = awakenedStats },
			Enemy = { IsMinigame = false, IsDialogue = true, Name = eTemplate.Speaker or "Story", Speaker = eTemplate.Speaker, Text = eTemplate.Text, Rewards = eTemplate.Rewards, HP = 1, MaxHP = 1, GateType = nil, GateHP = 0, MaxGateHP = 0, TotalStrength = 0, TotalDefense = 0, TotalSpeed = 0, Statuses = {}, Cooldowns = {}, Skills = {}, Drops = { XP = 0, Dews = 0, ItemChance = {} }, LastSkill = "None" }
		}
		CombatUpdate:FireClient(player, "Dialogue", { Speaker = eTemplate.Speaker or "Unknown", Text = eTemplate.Text or logFlavor, Battle = ActiveBattles[player.UserId] })
		return
	end

	local ctxRange = "Close"
	if eTemplate.Name:find("Beast Titan") or eTemplate.IsLongRange then ctxRange = "Long"; logFlavor = logFlavor .. "\n<font color='#FF5555'>" .. eTemplate.Name .. " is at LONG RANGE.</font>" end

	local eHP = math.floor((eTemplate.Health or 100) * hpMult)
	local eGateType = eTemplate.GateType
	local eGateHP = math.floor((eTemplate.GateHP or 0) * (eGateType == "Steam" and 1 or hpMult))
	local eStr = math.floor((eTemplate.Strength or 10) * dmgMult)
	local eDef = math.floor((eTemplate.Defense or 10) * dmgMult)
	local eSpd = math.floor((eTemplate.Speed or 10) * spdMult)

	ActiveBattles[player.UserId] = {
		IsProcessing = false,
		Context = { IsStoryMission = isStory, IsEndless = isEndless, IsPaths = isPaths, IsWorldBoss = isWorldBoss, IsNightmare = isNightmare, TargetPart = targetPart, CurrentWave = startingWave, TotalWaves = totalWaves, MissionData = activeMissionData, TurnCount = 0, Range = ctxRange },
		Player = { IsPlayer = true, Name = player.Name, PlayerObj = player, Titan = player:GetAttribute("Titan") or "None", Style = GetActualStyle(player), Clan = clanName, HP = pMaxHP, MaxHP = pMaxHP, TitanEnergy = 100, MaxTitanEnergy = 100, Gas = pMaxGas, MaxGas = pMaxGas, TotalStrength = pTotalStr, TotalDefense = pTotalDef, TotalSpeed = pTotalSpd, TotalResolve = pTotalRes, Statuses = {}, Cooldowns = {}, LastSkill = "None", AwakenedStats = awakenedStats },
		Enemy = { IsMinigame = eTemplate.IsMinigame, IsPlayer = false, Name = eTemplate.Name, IsHuman = isPaths and false or (eTemplate.IsHuman or false), IsNightmare = isNightmare, HP = eHP, MaxHP = eHP, GateType = eGateType, GateHP = eGateHP, MaxGateHP = eGateHP, TotalStrength = eStr, TotalDefense = eDef, TotalSpeed = eSpd, Statuses = {}, Cooldowns = {}, Skills = eTemplate.Skills or {"Brutal Swipe"}, Drops = { XP = math.floor((eTemplate.Drops and eTemplate.Drops.XP or 15) * dropMult), Dews = math.floor((eTemplate.Drops and eTemplate.Drops.Dews or 10) * dropMult), ItemChance = eTemplate.Drops and eTemplate.Drops.ItemChance or {} }, LastSkill = "None" }
	}

	if eTemplate.IsMinigame then CombatUpdate:FireClient(player, "StartMinigame", { Battle = ActiveBattles[player.UserId], LogMsg = logFlavor, MinigameType = eTemplate.IsMinigame })
	else CombatUpdate:FireClient(player, "Start", { Battle = ActiveBattles[player.UserId], LogMsg = logFlavor }) end
end

local function ProcessEnemyDeath(player, battle)
	if not player or not player:FindFirstChild("leaderstats") then return end
	local turnDelay = player:GetAttribute("HasDoubleSpeed") and 0.75 or 1.5

	if battle.Context.StoredBoss then
		local b = battle.Context.StoredBoss
		battle.Enemy.Name = b.Name; battle.Enemy.HP = b.HP; battle.Enemy.MaxHP = b.MaxHP
		battle.Enemy.GateType = b.GateType; battle.Enemy.GateHP = b.GateHP; battle.Enemy.MaxGateHP = b.MaxGateHP
		battle.Enemy.TotalStrength = b.TotalStrength; battle.Enemy.TotalDefense = b.TotalDefense; battle.Enemy.TotalSpeed = b.TotalSpeed
		battle.Enemy.Drops = b.Drops; battle.Enemy.Skills = b.Skills; battle.Enemy.Statuses = b.Statuses; battle.Enemy.Cooldowns = b.Cooldowns; battle.Enemy.LastSkill = b.LastSkill

		battle.Context.StoredBoss = nil; battle.Context.TurnCount = 0 
		CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#55FF55'>The Summoned Titan falls! The Founder is exposed!</font>", DidHit = false, ShakeType = "Heavy"})
		PlayVFX:FireClient(player, "TitanRoar", "Enemy")
		task.wait(turnDelay)
		battle.IsProcessing = false
		CombatUpdate:FireClient(player, "Update", {Battle = battle})
		return
	end

	UpdateBountyProgress(player, "Kill", 1); UpdateBountyProgress(player, "Clear", 1)

	local xpGain = battle.Enemy.Drops and battle.Enemy.Drops.XP or 0
	local dewsGain = battle.Enemy.Drops and battle.Enemy.Drops.Dews or 0
	if player:GetAttribute("HasDoubleXP") then xpGain *= 2; dewsGain *= 2 end

	local winReg = Network:FindFirstChild("WinningRegiment")
	if winReg and winReg.Value ~= "None" and player:GetAttribute("Regiment") == winReg.Value then
		xpGain = math.floor(xpGain * 1.15)
		dewsGain = math.floor(dewsGain * 1.15)
	end

	player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + xpGain)
	player:SetAttribute("TitanXP", (player:GetAttribute("TitanXP") or 0) + xpGain)
	player.leaderstats.Dews.Value += dewsGain

	local killMsg = ""
	local droppedItems, autoSoldDews = LootManager.ProcessDrops(player, battle.Enemy.Drops or {}, battle.Context.IsEndless, battle.Context.CurrentWave)

	if autoSoldDews > 0 then killMsg = killMsg .. "<br/><font color='#FFD700'>[Inventory Full: Auto-sold new drops for " .. autoSoldDews .. " Dews]</font>" end

	if battle.Player.AwakenedStats and battle.Player.AwakenedStats.HealOnKill > 0 then
		local pMax = tonumber(battle.Player.MaxHP) or 100
		local pCur = tonumber(battle.Player.HP) or 100
		local healAmt = math.floor(pMax * battle.Player.AwakenedStats.HealOnKill)
		battle.Player.HP = math.min(pMax, pCur + healAmt)
		killMsg = killMsg .. "<br/><font color='#55FF55'>[Awakened: Healed " .. healAmt .. " HP!]</font>"
		PlayVFX:FireClient(player, "Heal", "Self")
	end

	if battle.Context.IsStoryMission and battle.Context.CurrentWave < battle.Context.TotalWaves then
		battle.Context.CurrentWave += 1
		if battle.Context.TargetPart == (player:GetAttribute("CurrentPart") or 1) then player:SetAttribute("CurrentWave", battle.Context.CurrentWave) end

		local prestige = player.leaderstats.Prestige.Value
		local hpMult = GetHPScale(battle.Context.TargetPart, prestige)
		local dmgMult = GetDmgScale(battle.Context.TargetPart, prestige)
		local spdMult = GetSpdScale(battle.Context.TargetPart, prestige)

		local currentPart = battle.Context.TargetPart
		local partData = EnemyData.Parts[currentPart]
		local waveData = battle.Context.MissionData.Waves[battle.Context.CurrentWave]
		local nextEnemyTemplate = GetTemplate(partData, waveData.Template)

		-- [[ THE FIX: Fully generate Enemy table with all speed/strength stats for Dialogue advancement! ]]
		if nextEnemyTemplate.IsDialogue then
			battle.Context.TurnCount = 0; battle.Context.StoredBoss = nil
			battle.Enemy = {
				IsMinigame = false, IsDialogue = true, Name = nextEnemyTemplate.Speaker or "Story", Speaker = nextEnemyTemplate.Speaker, Text = nextEnemyTemplate.Text, Rewards = nextEnemyTemplate.Rewards,
				HP = 1, MaxHP = 1, GateType = nil, GateHP = 0, MaxGateHP = 0, TotalStrength = 0, TotalDefense = 0, TotalSpeed = 0,
				Statuses = {}, Cooldowns = {}, Skills = {}, Drops = { XP = 0, Dews = 0, ItemChance = {} }, LastSkill = "None"
			}
			battle.Player.Cooldowns = {}; battle.Player.Statuses = {} 
			battle.Player.LastSkill = "None"

			CombatUpdate:FireClient(player, "Dialogue", { Speaker = nextEnemyTemplate.Speaker or "Unknown", Text = nextEnemyTemplate.Text or (waveData.Flavor or ""), Battle = battle })
			battle.IsProcessing = false
			return
		end

		local dropMult = 1.0 + (battle.Context.TargetPart * 0.1) + (prestige * 0.25)
		local nextFinalDropXP = math.floor((nextEnemyTemplate.Drops and nextEnemyTemplate.Drops.XP or 15) * dropMult)
		local nextFinalDropDews = math.floor((nextEnemyTemplate.Drops and nextEnemyTemplate.Drops.Dews or 10) * dropMult)

		local flavorText = waveData.Flavor or ""
		if nextEnemyTemplate.Name:find("Beast Titan") or nextEnemyTemplate.IsLongRange then
			battle.Context.Range = "Long"
			flavorText = flavorText .. "\n<font color='#FF5555'>" .. nextEnemyTemplate.Name .. " is at LONG RANGE.</font>"
		else
			battle.Context.Range = "Close"
		end
		battle.Context.TurnCount = 0; battle.Context.StoredBoss = nil

		battle.Enemy = {
			IsMinigame = nextEnemyTemplate.IsMinigame, IsPlayer = false, Name = nextEnemyTemplate.Name, IsHuman = nextEnemyTemplate.IsHuman or false, IsNightmare = false,
			HP = math.floor((nextEnemyTemplate.Health or 100) * hpMult), MaxHP = math.floor((nextEnemyTemplate.Health or 100) * hpMult),
			GateType = nextEnemyTemplate.GateType, GateHP = math.floor((nextEnemyTemplate.GateHP or 0) * (nextEnemyTemplate.GateType == "Steam" and 1 or hpMult)), MaxGateHP = math.floor((nextEnemyTemplate.GateHP or 0) * (nextEnemyTemplate.GateType == "Steam" and 1 or hpMult)),
			TotalStrength = math.floor((nextEnemyTemplate.Strength or 10) * dmgMult), TotalDefense = math.floor((nextEnemyTemplate.Defense or 10) * dmgMult), TotalSpeed = math.floor((nextEnemyTemplate.Speed or 10) * spdMult),
			Statuses = {}, Cooldowns = {}, Skills = nextEnemyTemplate.Skills or {"Brutal Swipe"},
			Drops = { XP = nextFinalDropXP, Dews = nextFinalDropDews, ItemChance = nextEnemyTemplate.Drops and nextEnemyTemplate.Drops.ItemChance or {} },
			LastSkill = "None"
		}
		battle.Player.Cooldowns = {}; battle.Player.Statuses = {} 
		battle.Player.Gas = battle.Player.MaxGas; battle.Player.TitanEnergy = math.min(100, (battle.Player.TitanEnergy or 0) + 30); battle.Player.LastSkill = "None"

		if nextEnemyTemplate.IsMinigame then CombatUpdate:FireClient(player, "StartMinigame", {Battle = battle, LogMsg = "<font color='#FFD700'>[WAVE " .. battle.Context.CurrentWave .. "]</font>\n" .. flavorText, MinigameType = nextEnemyTemplate.IsMinigame})
		else CombatUpdate:FireClient(player, "WaveComplete", {Battle = battle, LogMsg = "<font color='#FFD700'>[WAVE " .. battle.Context.CurrentWave .. "]</font>\n" .. flavorText .. killMsg, XP = xpGain, Dews = dewsGain, Items = droppedItems}) end
		battle.IsProcessing = false
	else
		if battle.Context.IsStoryMission then
			player:SetAttribute("CampaignClear_Part" .. battle.Context.TargetPart, true)
			local playerCurrentPart = player:GetAttribute("CurrentPart") or 1
			if battle.Context.TargetPart == playerCurrentPart then
				local nextPart = playerCurrentPart + 1
				if EnemyData.Parts[nextPart] or nextPart == 9 then
					player:SetAttribute("CurrentPart", nextPart); player:SetAttribute("CurrentWave", 1) 
				end
			end
		end
		CombatUpdate:FireClient(player, "Victory", {Battle = battle, XP = xpGain, Dews = dewsGain, Items = droppedItems, ExtraLog = killMsg})
		ActiveBattles[player.UserId] = nil
	end
end

CombatAction.OnServerEvent:Connect(function(player, actionType, actionData)
	if actionType == "EngageStory" or actionType == "EngageWorldBoss" or actionType == "EngageNightmare" then 
		local pId = actionData and (actionData.PartId or actionData.BossId) or nil; StartBattle(player, actionType, pId); return 
	end

	if actionType == "MinigameResult" then
		local battle = ActiveBattles[player.UserId]
		if not battle then return end

		if actionData.MinigameType == "Dialogue" then
			local rewards = battle.Enemy.Rewards
			if rewards then
				if rewards.ItemName then
					local safeName = rewards.ItemName:gsub("[^%w]", "") .. "Count"
					player:SetAttribute(safeName, (player:GetAttribute(safeName) or 0) + (rewards.Amount or 1))
				end
				if rewards.Dews then player.leaderstats.Dews.Value += rewards.Dews end
				if rewards.XP then 
					player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + rewards.XP)
					player:SetAttribute("TitanXP", (player:GetAttribute("TitanXP") or 0) + rewards.XP)
				end
			end
			ProcessEnemyDeath(player, battle)
			return
		end

		if battle.Enemy.IsMinigame then
			if actionData.Success then ProcessEnemyDeath(player, battle)
			else CombatUpdate:FireClient(player, "Defeat", {Battle = battle}); ActiveBattles[player.UserId] = nil end
		end
		return
	end

	local battle = ActiveBattles[player.UserId]
	if not battle or actionType ~= "Attack" then return end
	if battle.IsProcessing then return end

	local skillName = actionData.SkillName
	local targetLimb = actionData.TargetLimb or "Body" 
	local skill = SkillData.Skills[skillName]

	if not skill or (battle.Player.Cooldowns[skillName] and battle.Player.Cooldowns[skillName] > 0) or ((battle.Player.Gas or 0) < (skill.GasCost or 0)) then 
		CombatUpdate:FireClient(player, "Update", {Battle = battle}); return 
	end

	battle.IsProcessing = true
	local turnDelay = player:GetAttribute("HasDoubleSpeed") and 0.75 or 1.5

	if skillName == "Maneuver" or skillName == "Evasive Maneuver" or skillName == "Smoke Screen" or skillName == "Advance" or skillName == "Close In" then 
		PlayVFX:FireClient(player, "Maneuver", "Self")
	end

	local function DispatchStrike(attacker, defender, strikeSkill, aimLimb)
		if attacker.HP <= 0 or defender.HP <= 0 then return end
		local success, msg, didHit, shakeType = pcall(function() 
			return CombatCore.ExecuteStrike(attacker, defender, strikeSkill, aimLimb, attacker.IsPlayer and "You" or attacker.Name, defender.IsPlayer and "you" or defender.Name, attacker.IsPlayer and "#FFFFFF" or "#FF5555", defender.IsPlayer and "#FFFFFF" or "#FF5555") 
		end)

		if success then 
			CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = msg, DidHit = didHit, ShakeType = shakeType, SkillUsed = strikeSkill, IsPlayerAttacking = attacker.IsPlayer})

			if didHit then
				if attacker.IsPlayer then
					if shakeType == "Heavy" then PlayVFX:FireClient(player, "PlayerCritical", "Enemy") else PlayVFX:FireClient(player, "PlayerSlash", "Enemy") end
				else
					if string.find(strikeSkill:lower(), "bite") then PlayVFX:FireClient(player, "TitanBite", "Self")
					elseif shakeType == "Heavy" then PlayVFX:FireClient(player, "PlayerCritical", "Self") else PlayVFX:FireClient(player, "PlayerSlash", "Self") end
				end
			else
				PlayVFX:FireClient(player, "Block", "Self")
			end
			task.wait(turnDelay) 
		else 
			CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#FF0000'>SERVER LOGIC ERROR: " .. tostring(msg) .. "</font>", DidHit = false, ShakeType = "None"}) 
		end
	end

	-- [[ THE FIX: Added 'or 10' fallback safety to totally prevent math errors! ]]
	local pRoll = (battle.Player.TotalSpeed or 10) + math.random(1, 15)
	local eRoll = (battle.Enemy.TotalSpeed or 10) + math.random(1, 15)
	local combatants = { battle.Player, battle.Enemy }
	table.sort(combatants, function(a, b) return (a.IsPlayer and pRoll or eRoll) > (b.IsPlayer and pRoll or eRoll) end)

	for _, combatant in ipairs(combatants) do
		if battle.Player.HP < 1 or battle.Enemy.HP < 1 then break end
		if combatant.HP < 1 then continue end

		if combatant.IsPlayer then
			if skill.Effect == "Flee" or skillName == "Retreat" then 
				CombatUpdate:FireClient(player, "Fled", {Battle = battle}); ActiveBattles[player.UserId] = nil; return 
			end

			if skill.GasCost then combatant.Gas = math.max(0, combatant.Gas - skill.GasCost) end
			DispatchStrike(battle.Player, battle.Enemy, skillName, targetLimb)
		else
			if not combatant.Cooldowns then combatant.Cooldowns = {} end

			local validAiSkills = {}
			for _, s in ipairs(combatant.Skills) do
				if not combatant.Cooldowns[s] or combatant.Cooldowns[s] <= 0 then table.insert(validAiSkills, s) end
			end

			battle.Context.TurnCount = (battle.Context.TurnCount or 0) + 1
			local aiSkill = "Brutal Swipe"

			if combatant.Statuses["Telegraphing"] then
				aiSkill = combatant.Statuses["Telegraphing"]; combatant.Statuses["Telegraphing"] = nil
			else
				if #validAiSkills > 0 then aiSkill = validAiSkills[math.random(1, #validAiSkills)] end

				if SkillData.Skills[aiSkill] and SkillData.Skills[aiSkill].Telegraphed then
					combatant.Statuses["Telegraphing"] = aiSkill
					local hintStr = " <font color='#55FF55'>[HINT: USE EVASIVE MANEUVER OR BLOCK!]</font>"
					CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<b><font color='#FFAA00'>WARNING: " .. combatant.Name .. " is charging up " .. aiSkill:upper() .. "!</font></b>" .. hintStr, DidHit = false, ShakeType = "Heavy"})
					PlayVFX:FireClient(player, "TitanRoar", "Enemy")
					task.wait(turnDelay)
					continue
				end
			end

			local aiTargets = {"Body", "Body", "Arms", "Legs", "Nape"}
			DispatchStrike(battle.Enemy, battle.Player, aiSkill, aiTargets[math.random(1, #aiTargets)])
		end
	end

	if battle.Player.HP < 1 then
		CombatUpdate:FireClient(player, "Defeat", {Battle = battle}); ActiveBattles[player.UserId] = nil
	elseif battle.Enemy.HP < 1 then
		ProcessEnemyDeath(player, battle)
	else
		for sName, cd in pairs(battle.Player.Cooldowns or {}) do if cd > 0 then battle.Player.Cooldowns[sName] = cd - 1 end end
		for sName, cd in pairs(battle.Enemy.Cooldowns or {}) do if cd > 0 then battle.Enemy.Cooldowns[sName] = cd - 1 end end

		battle.IsProcessing = false
		CombatUpdate:FireClient(player, "Update", {Battle = battle})
	end
end)

Players.PlayerRemoving:Connect(function(player) ActiveBattles[player.UserId] = nil end)