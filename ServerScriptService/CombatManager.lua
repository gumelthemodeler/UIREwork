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

local function GetValidEndlessMob(partData)
	local valid = {}
	for _, mob in ipairs(partData.Mobs) do
		if not string.find(mob.Name, "Dummy") and not string.find(mob.Name, "Wall Titan") then
			table.insert(valid, mob)
		end
	end
	if #valid > 0 then return valid[math.random(1, #valid)] end
	return partData.Mobs[1]
end

local function GetHPScale(targetPart, prestige)
	local chapterScale = 1.0 + ((targetPart - 1) * 0.15) 
	local prestigeScale = 1.0 + (prestige * 0.20) 
	return chapterScale * prestigeScale
end
local function GetDmgScale(targetPart, prestige)
	local chapterScale = 1.0 + ((targetPart - 1) * 0.10) 
	local prestigeScale = 1.0 + (prestige * 0.15) 
	return chapterScale * prestigeScale
end
local function GetSpdScale(targetPart, prestige)
	return 1.0 + (math.pow(targetPart, 0.6) * 0.05) + (math.pow(prestige, 0.7) * 0.1)
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

	local cTerrain = "City"
	local cWeather = "Clear"

	if encounterType == "EngageStory" then
		isStory = true
		targetPart = requestedPartId or currentPart
		if type(targetPart) == "number" and targetPart > currentPart then targetPart = currentPart end
		local partData = EnemyData.Parts[targetPart]
		if not partData then return end

		if partData.DefaultEnv then
			cTerrain = partData.DefaultEnv.Terrain or "City"
			cWeather = partData.DefaultEnv.Weather or "Clear"
		end

		if targetPart == currentPart then startingWave = player:GetAttribute("CurrentWave") or 1 else startingWave = 1 end
		local missionTable = (prestige > 0 and partData.PrestigeMissions) and partData.PrestigeMissions or partData.Missions
		activeMissionData = missionTable[1]
		totalWaves = #activeMissionData.Waves
		if startingWave > totalWaves then startingWave = totalWaves end

		local waveData = activeMissionData.Waves[startingWave]
		eTemplate = GetTemplate(partData, waveData.Template)

		local flavorText = waveData.Flavor
		if not flavorText or flavorText == "" then flavorText = "Prepare to engage " .. (eTemplate.Name or "the enemy") .. "!" end
		logFlavor = "<font color='#FFD700'>[Mission: " .. (activeMissionData.Name or "Unknown") .. "]</font>\n" .. flavorText

	elseif encounterType == "EngageWorldBoss" then
		isWorldBoss = true
		eTemplate = EnemyData.WorldBosses[requestedPartId]
		if not eTemplate then return end
		logFlavor = "<font color='#FFAA00'>[WORLD EVENT]</font>\n" .. eTemplate.Name .. " has appeared!"
		targetPart = 1 

	elseif encounterType == "EngageNightmare" then
		isNightmare = true
		eTemplate = EnemyData.NightmareHunts[requestedPartId]
		if not eTemplate then return end
		logFlavor = "<font color='#FF5555'>[NIGHTMARE HUNT]</font>\n" .. eTemplate.Name .. " approaches!"
		targetPart = 1 

	elseif encounterType == "EngageRaid" then
		eTemplate = EnemyData.RaidBosses[requestedPartId]
		if not eTemplate then return end
		logFlavor = "<font color='#FF5555'>[RAID BOSS]</font>\n" .. eTemplate.Name .. " blocks your path!"
		targetPart = 1

	elseif encounterType == "EngageEndless" then
		isEndless = true
		local maxPart = math.min(8, currentPart)
		targetPart = math.random(1, maxPart)
		local partData = EnemyData.Parts[targetPart]
		eTemplate = GetValidEndlessMob(partData)
		logFlavor = "<font color='#AA55FF'>[ENDLESS EXPEDITION]</font>\nYou have encountered a " .. eTemplate.Name .. "!"

		local terrains = {"City", "Forest", "Plains", "Caverns"}
		local weathers = {"Clear", "Rain", "Night"}
		cTerrain = terrains[math.random(1, #terrains)]
		cWeather = weathers[math.random(1, #weathers)]

	elseif encounterType == "EngagePaths" then
		isPaths = true
		local floor = player:GetAttribute("PathsFloor") or 1
		targetPart = 1 
		local maxMemoryIndex = math.min(#EnemyData.PathsMemories, math.max(1, math.ceil(floor / 3)))
		eTemplate = EnemyData.PathsMemories[math.random(1, maxMemoryIndex)]
		logFlavor = "<font color='#55FFFF'>[THE PATHS - MEMORY " .. floor .. "]</font>\nA manifestation of " .. eTemplate.Name .. " emerges from the sand..."
		cTerrain = "Plains"
		cWeather = "Night"
	else
		targetPart = math.min(8, currentPart)
		local partData = EnemyData.Parts[targetPart]
		eTemplate = partData.Mobs[math.random(1, #partData.Mobs)]
		local flavors = partData.RandomFlavor or {"You encounter a %s!"}
		logFlavor = string.format(flavors[math.random(1, #flavors)], eTemplate.Name)
	end

	if not eTemplate.IsDialogue then
		local envFlavors = {
			["City"] = "The tight alleyways offer standard ODM mobility.",
			["Forest"] = "The giant trees provide perfect anchors. Maneuvering costs 50% less gas and boosts evasion.",
			["Plains"] = "The open terrain is a death trap. Maneuvers cost 50% more gas and evasion plummets.",
			["Caverns"] = "The glowing crystals amplify Titan Hardening defensive capabilities."
		}
		local weatherFlavors = {
			["Clear"] = "",
			["Rain"] = "Heavy rain obscures vision. Both sides lose Accuracy. Fire extinguishes faster.",
			["Night"] = "The lack of sunlight drastically reduces Pure Titan speed."
		}
		logFlavor = logFlavor .. "\n<font color='#AAAAAA'>[" .. string.upper(cTerrain) .. "] " .. envFlavors[cTerrain] .. "</font>"
		if cWeather ~= "Clear" then
			logFlavor = logFlavor .. "\n<font color='#5588FF'>[" .. string.upper(cWeather) .. "] " .. weatherFlavors[cWeather] .. "</font>"
		end
	end

	local hpMult = GetHPScale(targetPart, prestige)
	local dmgMult = GetDmgScale(targetPart, prestige)
	local spdMult = GetSpdScale(targetPart, prestige)
	local dropMult = 1.0 + (targetPart * 0.1) + (prestige * 0.25)

	if isEndless then 
		hpMult *= 1.3; dmgMult *= 1.25; dropMult *= 1.5 
	elseif isPaths then
		local floor = player:GetAttribute("PathsFloor") or 1
		local pathScale = math.pow(1.10, floor - 1) 
		hpMult = hpMult * (0.60 * pathScale) 
		dmgMult = dmgMult * (1.10 * pathScale)
		dropMult = 1.0 + (prestige * 0.25) + (floor * 0.1)
	end

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

	if eTemplate.IsDialogue then
		ActiveBattles[player.UserId] = {
			IsProcessing = false,
			Context = { IsStoryMission = isStory, TargetPart = targetPart, CurrentWave = startingWave, TotalWaves = totalWaves, MissionData = activeMissionData, TurnCount = 0, Range = "Close" },
			Player = { IsPlayer = true, Name = player.Name, PlayerObj = player, Titan = player:GetAttribute("Titan") or "None", Style = GetActualStyle(player), Clan = clanName, HP = pMaxHP, MaxHP = pMaxHP, TitanEnergy = 100, MaxTitanEnergy = 100, Gas = pMaxGas, MaxGas = pMaxGas, TotalStrength = pTotalStr, TotalDefense = pTotalDef, TotalSpeed = pTotalSpd, TotalResolve = pTotalRes, Statuses = {}, Cooldowns = {}, LastSkill = "None", AwakenedStats = awakenedStats },
			Enemy = { IsMinigame = false, IsDialogue = true, Name = "Story", Dialogues = eTemplate.Dialogues, Choices = eTemplate.Choices, Rewards = eTemplate.Rewards, HP = 1, MaxHP = 1, GateType = nil, GateHP = 0, MaxGateHP = 0, TotalStrength = 0, TotalDefense = 0, TotalSpeed = 0, Statuses = {}, Cooldowns = {}, Skills = {}, Drops = { XP = 0, Dews = 0, ItemChance = {} }, LastSkill = "None" }
		}
		CombatUpdate:FireClient(player, "Dialogue", { Dialogues = eTemplate.Dialogues, Choices = eTemplate.Choices, Battle = ActiveBattles[player.UserId] })
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
	local enemyAwakenedStats = nil

	local isDynamicBoss = (encounterType == "EngageWorldBoss" or encounterType == "EngageNightmare" or encounterType == "EngageRaid")
	if isDynamicBoss then
		local groupMult = 1
		if encounterType == "EngageWorldBoss" then groupMult = math.clamp(#Players:GetPlayers(), 1, 15)
		elseif encounterType == "EngageRaid" then
			local getPartyFunc = Network:FindFirstChild("GetPlayerParty")
			if getPartyFunc then
				local partyData = getPartyFunc:Invoke(player)
				if partyData and partyData.Members then groupMult = #partyData.Members end
			end
		end

		local baseDifficulty = 1.0
		if encounterType == "EngageWorldBoss" then baseDifficulty = 2.0
		elseif encounterType == "EngageNightmare" then baseDifficulty = 1.5
		elseif encounterType == "EngageRaid" then baseDifficulty = 1.2 end

		local effectivePlayerDmg = math.max(10, pTotalStr * (awakenedStats.DmgMult or 1.0) * (1 + (prestige * 0.1)))
		local bossHPRatio = math.clamp(eTemplate.Health / 4000, 0.5, 2.5) 
		eHP = math.floor(effectivePlayerDmg * 15 * baseDifficulty * math.pow(groupMult, 0.75) * bossHPRatio)

		if eGateType == "Steam" then eGateHP = eTemplate.GateHP 
		elseif eGateType then
			local gateRatio = (eTemplate.GateHP or 0) / eTemplate.Health
			eGateHP = math.floor(eHP * gateRatio)
		end

		local effectivePlayerDurability = pMaxHP + (pTotalDef * 2)
		local bossDmgRatio = math.clamp(eTemplate.Strength / 300, 0.5, 2.0) 
		eStr = math.floor((effectivePlayerDurability / 8) * baseDifficulty * bossDmgRatio)

		local bossDefRatio = math.clamp(eTemplate.Defense / 150, 0.5, 2.0)
		eDef = math.floor(pTotalStr * 0.5 * bossDefRatio * baseDifficulty)
		eSpd = math.floor(pTotalSpd * 1.1)

		logFlavor = logFlavor .. "\n<font color='#AAAAAA'>[Dynamic Encounter: Attuned to Group Size " .. groupMult .. "x]</font>"
	end

	if isPaths then
		local mutators = {"Armored", "Frenzied", "Elusive", "Colossal"}
		local selectedMutator = mutators[math.random(1, #mutators)]
		if selectedMutator == "Armored" then
			eGateType = "Reinforced Skin"; eGateHP = math.floor(eHP * 0.3)
			logFlavor = logFlavor .. "\n<font color='#AAAAAA'>[MUTATOR: ARMORED] Target has extreme hardening!</font>"
		elseif selectedMutator == "Frenzied" then
			eSpd = eSpd * 1.5; eStr = eStr * 1.2
			logFlavor = logFlavor .. "\n<font color='#FF5555'>[MUTATOR: FRENZIED] Target is moving at terrifying speeds!</font>"
		elseif selectedMutator == "Elusive" then
			enemyAwakenedStats = { DodgeBonus = 15 }
			logFlavor = logFlavor .. "\n<font color='#55FF55'>[MUTATOR: ELUSIVE] Target is incredibly hard to hit!</font>"
		elseif selectedMutator == "Colossal" then
			eHP = eHP * 1.5; eStr = eStr * 1.5; eSpd = math.floor(eSpd * 0.5)
			logFlavor = logFlavor .. "\n<font color='#FFAA00'>[MUTATOR: COLOSSAL] Target is massive and deals lethal damage!</font>"
		end
	end

	local eSkills = eTemplate.Skills or {"Brutal Swipe"}
	local initCooldowns = {}
	for _, s in ipairs(eSkills) do
		local sd = SkillData.Skills[s]
		if sd and sd.Telegraphed then initCooldowns[s] = math.random(2, 4) end
	end

	ActiveBattles[player.UserId] = {
		IsProcessing = false,
		Context = { IsStoryMission = isStory, IsEndless = isEndless, IsPaths = isPaths, IsWorldBoss = isWorldBoss, IsNightmare = isNightmare, TargetPart = targetPart, CurrentWave = startingWave, TotalWaves = totalWaves, MissionData = activeMissionData, TurnCount = 0, Range = ctxRange, Terrain = cTerrain, Weather = cWeather },
		Player = { IsPlayer = true, Name = player.Name, PlayerObj = player, Titan = player:GetAttribute("Titan") or "None", Style = GetActualStyle(player), Clan = clanName, HP = pMaxHP, MaxHP = pMaxHP, TitanEnergy = 100, MaxTitanEnergy = 100, Gas = pMaxGas, MaxGas = pMaxGas, TotalStrength = pTotalStr, TotalDefense = pTotalDef, TotalSpeed = pTotalSpd, TotalResolve = pTotalRes, Statuses = {}, Cooldowns = {}, LastSkill = "None", AwakenedStats = awakenedStats },
		Enemy = { IsMinigame = eTemplate.IsMinigame, IsPlayer = false, Name = eTemplate.Name, IsHuman = isPaths and false or (eTemplate.IsHuman or false), IsNightmare = isNightmare, IsBoss = eTemplate.IsBoss or false, HP = eHP, MaxHP = eHP, GateType = eGateType, GateHP = eGateHP, MaxGateHP = eGateHP, TotalStrength = eStr, TotalDefense = eDef, TotalSpeed = eSpd, Statuses = {}, Cooldowns = initCooldowns, Skills = eSkills, Drops = { XP = math.floor((eTemplate.Drops and eTemplate.Drops.XP or 15) * dropMult), Dews = math.floor((eTemplate.Drops and eTemplate.Drops.Dews or 10) * dropMult), ItemChance = eTemplate.Drops and eTemplate.Drops.ItemChance or {} }, AwakenedStats = enemyAwakenedStats, LastSkill = "None" }
	}

	if eTemplate.IsMinigame then CombatUpdate:FireClient(player, "StartMinigame", { Battle = ActiveBattles[player.UserId], LogMsg = logFlavor, MinigameType = eTemplate.IsMinigame })
	else CombatUpdate:FireClient(player, "Start", { Battle = ActiveBattles[player.UserId], LogMsg = logFlavor }) end
end

local function ProcessEnemyDeath(player, battle, dialogueRewards)
	if not player or not player:FindFirstChild("leaderstats") then return end
	local turnDelay = player:GetAttribute("HasDoubleSpeed") and 0.75 or 1.5
	local wasDialogue = battle.Enemy.IsDialogue

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

	if battle.Enemy.IsBoss and not battle.Context.ExecutionTriggered then
		battle.Context.ExecutionTriggered = true
		CombatUpdate:FireClient(player, "ExecutionPhase", {Battle = battle})
		battle.IsProcessing = false
		return
	end

	UpdateBountyProgress(player, "Kill", 1); UpdateBountyProgress(player, "Clear", 1)

	local xpGain = (battle.Enemy.Drops and battle.Enemy.Drops.XP or 0) + (dialogueRewards and dialogueRewards.XP or 0)
	local dewsGain = (battle.Enemy.Drops and battle.Enemy.Drops.Dews or 0) + (dialogueRewards and dialogueRewards.Dews or 0)

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

	if dialogueRewards and dialogueRewards.ItemName then
		local safeName = dialogueRewards.ItemName:gsub("[^%w]", "") .. "Count"
		local amountGiven = dialogueRewards.Amount or 1
		player:SetAttribute(safeName, (player:GetAttribute(safeName) or 0) + amountGiven)
		table.insert(droppedItems, {Name = dialogueRewards.ItemName, Amount = amountGiven})
	end

	if autoSoldDews > 0 then killMsg = killMsg .. "<br/><font color='#FFD700'>[Inventory Full: Auto-sold new drops for " .. autoSoldDews .. " Dews]</font>" end

	if battle.Player.AwakenedStats and battle.Player.AwakenedStats.HealOnKill > 0 then
		local pMax = tonumber(battle.Player.MaxHP) or 100
		local pCur = tonumber(battle.Player.HP) or 100
		local healAmt = math.floor(pMax * battle.Player.AwakenedStats.HealOnKill)
		battle.Player.HP = math.min(pMax, pCur + healAmt)
		killMsg = killMsg .. "<br/><font color='#55FF55'>[Awakened: Healed " .. healAmt .. " HP!]</font>"
		PlayVFX:FireClient(player, "Heal", "Self")
	end

	if battle.Context.IsPaths then
		local floor = player:GetAttribute("PathsFloor") or 1
		local dustGain = math.floor(1 + (floor * 0.2)) 
		player:SetAttribute("PathDust", (player:GetAttribute("PathDust") or 0) + dustGain)
		player:SetAttribute("PathsFloor", floor + 1)

		local rewardStr = "<font color='#55FFFF'>Memory Cleared! +" .. dustGain .. " Path Dust</font>"
		local prestige = player.leaderstats.Prestige.Value

		local maxMemoryIndex = math.min(#EnemyData.PathsMemories, math.max(1, math.ceil((floor + 1) / 3)))
		local nextEnemyTemplate = EnemyData.PathsMemories[math.random(1, maxMemoryIndex)]

		local pathScale = math.pow(1.10, floor)
		local hpMult = GetHPScale(1, prestige) * (0.60 * pathScale)
		local dmgMult = GetDmgScale(1, prestige) * (1.10 * pathScale)
		local spdMult = GetSpdScale(1, prestige)
		local dropMult = 1.0 + (prestige * 0.25) + ((floor + 1) * 0.1)

		local eHP = math.floor(nextEnemyTemplate.Health * hpMult)
		local eGateType = nextEnemyTemplate.GateType
		local eGateHP = math.floor((nextEnemyTemplate.GateHP or 0) * (eGateType == "Steam" and 1 or hpMult))
		local eStr = math.floor(nextEnemyTemplate.Strength * dmgMult)
		local eDef = math.floor(nextEnemyTemplate.Defense * dmgMult)
		local eSpd = math.floor(nextEnemyTemplate.Speed * spdMult)

		local enemyAwakenedStats = nil
		local mutators = {"Armored", "Frenzied", "Elusive", "Colossal"}
		local selectedMutator = mutators[math.random(1, #mutators)]
		local flavorText = "<font color='#55FFFF'>[THE PATHS - MEMORY " .. (floor + 1) .. "]</font>\nA manifestation of " .. nextEnemyTemplate.Name .. " emerges from the sand..."

		if selectedMutator == "Armored" then
			eGateType = "Reinforced Skin"; eGateHP = math.floor(eHP * 0.3)
			flavorText = flavorText .. "\n<font color='#AAAAAA'>[MUTATOR: ARMORED] Target has extreme hardening!</font>"
		elseif selectedMutator == "Frenzied" then
			eSpd = eSpd * 1.5; eStr = eStr * 1.2
			flavorText = flavorText .. "\n<font color='#FF5555'>[MUTATOR: FRENZIED] Target is moving at terrifying speeds!</font>"
		elseif selectedMutator == "Elusive" then
			enemyAwakenedStats = { DodgeBonus = 15 }
			flavorText = flavorText .. "\n<font color='#55FF55'>[MUTATOR: ELUSIVE] Target is incredibly hard to hit!</font>"
		elseif selectedMutator == "Colossal" then
			eHP = eHP * 1.5; eStr = eStr * 1.5; eSpd = math.floor(eSpd * 0.5)
			flavorText = flavorText .. "\n<font color='#FFAA00'>[MUTATOR: COLOSSAL] Target is massive and deals lethal damage!</font>"
		end

		if nextEnemyTemplate.Name:find("Beast Titan") or nextEnemyTemplate.IsLongRange then
			battle.Context.Range = "Long"
			flavorText = flavorText .. "\n<font color='#FF5555'>" .. nextEnemyTemplate.Name .. " is at LONG RANGE.</font>"
		else battle.Context.Range = "Close" end

		local eSkills = nextEnemyTemplate.Skills or {"Brutal Swipe"}
		local initCooldowns = {}
		for _, s in ipairs(eSkills) do
			local sd = SkillData.Skills[s]
			if sd and sd.Telegraphed then initCooldowns[s] = math.random(2, 4) end
		end

		battle.Enemy = {
			IsMinigame = nextEnemyTemplate.IsMinigame, IsPlayer = false, Name = nextEnemyTemplate.Name, IsHuman = false, IsNightmare = false, IsBoss = nextEnemyTemplate.IsBoss or false,
			HP = eHP, MaxHP = eHP, GateType = eGateType, GateHP = eGateHP, MaxGateHP = eGateHP, TotalStrength = eStr, TotalDefense = eDef, TotalSpeed = eSpd,
			Statuses = {}, Cooldowns = initCooldowns, Skills = eSkills,
			Drops = { XP = math.floor((nextEnemyTemplate.Drops and nextEnemyTemplate.Drops.XP or 15) * dropMult), Dews = math.floor((nextEnemyTemplate.Drops and nextEnemyTemplate.Drops.Dews or 10) * dropMult), ItemChance = nextEnemyTemplate.Drops and nextEnemyTemplate.Drops.ItemChance or {} },
			LastSkill = "None", AwakenedStats = enemyAwakenedStats
		}
		battle.Player.Cooldowns = {}; battle.Player.Statuses = {} 
		battle.Player.HP = battle.Player.MaxHP; battle.Player.Gas = battle.Player.MaxGas; battle.Player.TitanEnergy = math.min(100, (battle.Player.TitanEnergy or 0) + 30); battle.Player.LastSkill = "None"

		if nextEnemyTemplate.IsMinigame then CombatUpdate:FireClient(player, "StartMinigame", {Battle = battle, LogMsg = flavorText .. "\n" .. rewardStr .. killMsg, MinigameType = nextEnemyTemplate.IsMinigame})
		else CombatUpdate:FireClient(player, "WaveComplete", {Battle = battle, LogMsg = flavorText .. "\n" .. rewardStr .. killMsg, XP = xpGain, Dews = dewsGain, Items = droppedItems}) end
		battle.IsProcessing = false
		return
	end

	if battle.Context.IsEndless then
		battle.Context.CurrentWave += 1
		local nextWave = battle.Context.CurrentWave
		local prestige = player.leaderstats.Prestige.Value
		local maxPart = math.min(8, player:GetAttribute("CurrentPart") or 1)
		local targetPart = math.random(1, maxPart)
		local partData = EnemyData.Parts[targetPart]
		local nextEnemyTemplate = GetValidEndlessMob(partData)

		local hpMult = GetHPScale(targetPart, prestige) * 1.3
		local dmgMult = GetDmgScale(targetPart, prestige) * 1.25
		local spdMult = GetSpdScale(targetPart, prestige)
		local dropMult = (1.0 + (targetPart * 0.1) + (prestige * 0.25)) * 1.5

		local eHP = math.floor(nextEnemyTemplate.Health * hpMult)
		local eGateType = nextEnemyTemplate.GateType
		local eGateHP = math.floor((nextEnemyTemplate.GateHP or 0) * (eGateType == "Steam" and 1 or hpMult))
		local eStr = math.floor(nextEnemyTemplate.Strength * dmgMult)
		local eDef = math.floor(nextEnemyTemplate.Defense * dmgMult)
		local eSpd = math.floor(nextEnemyTemplate.Speed * spdMult)

		local flavorText = "<font color='#AA55FF'>[ENDLESS EXPEDITION - WAVE " .. nextWave .. "]</font>\nYou encounter a " .. nextEnemyTemplate.Name .. "!"

		battle.Context.Range = "Close"
		if nextEnemyTemplate.Name:find("Beast Titan") or nextEnemyTemplate.IsLongRange then
			battle.Context.Range = "Long"
			flavorText = flavorText .. "\n<font color='#FF5555'>" .. nextEnemyTemplate.Name .. " is at LONG RANGE.</font>"
		end

		local eSkills = nextEnemyTemplate.Skills or {"Brutal Swipe"}
		local initCooldowns = {}
		for _, s in ipairs(eSkills) do
			local sd = SkillData.Skills[s]
			if sd and sd.Telegraphed then initCooldowns[s] = math.random(2, 4) end
		end

		battle.Context.TurnCount = 0; battle.Context.StoredBoss = nil
		battle.Enemy = {
			IsMinigame = nextEnemyTemplate.IsMinigame, IsPlayer = false, Name = nextEnemyTemplate.Name, IsHuman = nextEnemyTemplate.IsHuman or false, IsNightmare = false, IsBoss = nextEnemyTemplate.IsBoss or false,
			HP = eHP, MaxHP = eHP, GateType = eGateType, GateHP = eGateHP, MaxGateHP = eGateHP, TotalStrength = eStr, TotalDefense = eDef, TotalSpeed = eSpd,
			Statuses = {}, Cooldowns = initCooldowns, Skills = eSkills,
			Drops = { XP = math.floor((nextEnemyTemplate.Drops and nextEnemyTemplate.Drops.XP or 15) * dropMult), Dews = math.floor((nextEnemyTemplate.Drops and nextEnemyTemplate.Drops.Dews or 10) * dropMult), ItemChance = nextEnemyTemplate.Drops and nextEnemyTemplate.Drops.ItemChance or {} },
			LastSkill = "None"
		}
		battle.Player.Cooldowns = {}; battle.Player.Statuses = {} 
		battle.Player.HP = battle.Player.MaxHP; battle.Player.Gas = battle.Player.MaxGas; battle.Player.TitanEnergy = math.min(100, (battle.Player.TitanEnergy or 0) + 30); battle.Player.LastSkill = "None"

		if nextEnemyTemplate.IsMinigame then CombatUpdate:FireClient(player, "StartMinigame", {Battle = battle, LogMsg = flavorText .. "\n" .. killMsg, MinigameType = nextEnemyTemplate.IsMinigame})
		else CombatUpdate:FireClient(player, "WaveComplete", {Battle = battle, LogMsg = flavorText .. "\n" .. killMsg, XP = xpGain, Dews = dewsGain, Items = droppedItems}) end
		battle.IsProcessing = false
		return
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

		if nextEnemyTemplate.IsDialogue then
			battle.Context.TurnCount = 0; battle.Context.StoredBoss = nil
			battle.Enemy = {
				IsMinigame = false, IsDialogue = true, Name = "Story", Dialogues = nextEnemyTemplate.Dialogues, Choices = nextEnemyTemplate.Choices, Rewards = nextEnemyTemplate.Rewards,
				HP = 1, MaxHP = 1, GateType = nil, GateHP = 0, MaxGateHP = 0, TotalStrength = 0, TotalDefense = 0, TotalSpeed = 0,
				Statuses = {}, Cooldowns = {}, Skills = {}, Drops = { XP = 0, Dews = 0, ItemChance = {} }, LastSkill = "None"
			}
			battle.Player.Cooldowns = {}; battle.Player.Statuses = {} 
			battle.Player.LastSkill = "None"

			CombatUpdate:FireClient(player, "Dialogue", { Dialogues = nextEnemyTemplate.Dialogues, Choices = nextEnemyTemplate.Choices, Battle = battle })
			battle.IsProcessing = false
			return
		end

		local dropMult = 1.0 + (battle.Context.TargetPart * 0.1) + (prestige * 0.25)
		local nextFinalDropXP = math.floor((nextEnemyTemplate.Drops and nextEnemyTemplate.Drops.XP or 15) * dropMult)
		local nextFinalDropDews = math.floor((nextEnemyTemplate.Drops and nextEnemyTemplate.Drops.Dews or 10) * dropMult)

		local flavorText = waveData.Flavor
		if not flavorText or flavorText == "" then flavorText = "Prepare to engage " .. (nextEnemyTemplate.Name or "the enemy") .. "!" end

		if nextEnemyTemplate.Name:find("Beast Titan") or nextEnemyTemplate.IsLongRange then
			battle.Context.Range = "Long"
			flavorText = flavorText .. "\n<font color='#FF5555'>" .. nextEnemyTemplate.Name .. " is at LONG RANGE.</font>"
		else
			battle.Context.Range = "Close"
		end

		local eSkills = nextEnemyTemplate.Skills or {"Brutal Swipe"}
		local initCooldowns = {}
		for _, s in ipairs(eSkills) do
			local sd = SkillData.Skills[s]
			if sd and sd.Telegraphed then initCooldowns[s] = math.random(2, 4) end
		end

		battle.Context.TurnCount = 0; battle.Context.StoredBoss = nil
		battle.Enemy = {
			IsMinigame = nextEnemyTemplate.IsMinigame, IsPlayer = false, Name = nextEnemyTemplate.Name, IsHuman = nextEnemyTemplate.IsHuman or false, IsNightmare = false, IsBoss = nextEnemyTemplate.IsBoss or false,
			HP = math.floor((nextEnemyTemplate.Health or 100) * hpMult), MaxHP = math.floor((nextEnemyTemplate.Health or 100) * hpMult),
			GateType = nextEnemyTemplate.GateType, GateHP = math.floor((nextEnemyTemplate.GateHP or 0) * (nextEnemyTemplate.GateType == "Steam" and 1 or hpMult)), MaxGateHP = math.floor((nextEnemyTemplate.GateHP or 0) * (nextEnemyTemplate.GateType == "Steam" and 1 or hpMult)),
			TotalStrength = math.floor((nextEnemyTemplate.Strength or 10) * dmgMult), TotalDefense = math.floor((nextEnemyTemplate.Defense or 10) * dmgMult), TotalSpeed = math.floor((nextEnemyTemplate.Speed or 10) * spdMult),
			Statuses = {}, Cooldowns = initCooldowns, Skills = eSkills,
			Drops = { XP = nextFinalDropXP, Dews = nextFinalDropDews, ItemChance = nextEnemyTemplate.Drops and nextEnemyTemplate.Drops.ItemChance or {} },
			LastSkill = "None"
		}
		battle.Player.Cooldowns = {}; battle.Player.Statuses = {} 
		battle.Player.Gas = battle.Player.MaxGas; battle.Player.TitanEnergy = math.min(100, (battle.Player.TitanEnergy or 0) + 30); battle.Player.LastSkill = "None"

		if nextEnemyTemplate.IsMinigame then 
			CombatUpdate:FireClient(player, "StartMinigame", {Battle = battle, LogMsg = "<font color='#FFD700'>[WAVE " .. battle.Context.CurrentWave .. "]</font>\n" .. flavorText, MinigameType = nextEnemyTemplate.IsMinigame})
		else 
			if wasDialogue then
				CombatUpdate:FireClient(player, "Start", {Battle = battle, LogMsg = "<font color='#FFD700'>[WAVE " .. battle.Context.CurrentWave .. "]</font>\n" .. flavorText .. killMsg})
			else
				CombatUpdate:FireClient(player, "WaveComplete", {Battle = battle, LogMsg = "<font color='#FFD700'>[WAVE " .. battle.Context.CurrentWave .. "]</font>\n" .. flavorText .. killMsg, XP = xpGain, Dews = dewsGain, Items = droppedItems}) 
			end
		end
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
	if actionType == "EngageStory" or actionType == "EngageWorldBoss" or actionType == "EngageNightmare" or actionType == "EngageRaid" or actionType == "EngageEndless" or actionType == "EngagePaths" then 
		local pId = actionData and (actionData.PartId or actionData.BossId) or nil; StartBattle(player, actionType, pId); return 
	end

	if actionType == "ExecutionComplete" then
		local battle = ActiveBattles[player.UserId]
		if not battle or not battle.Context.ExecutionTriggered then return end
		ProcessEnemyDeath(player, battle, battle.Enemy.Rewards)
		return
	end

	if actionType == "MinigameResult" then
		local battle = ActiveBattles[player.UserId]
		if not battle then return end

		if actionData.MinigameType == "Dialogue" then
			ProcessEnemyDeath(player, battle, battle.Enemy.Rewards)
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

	local hasGas = true
	if skill and skill.GasCost then
		local actualCost = skill.GasCost
		if battle.Context.Terrain == "Forest" then actualCost = math.ceil(actualCost * 0.5)
		elseif battle.Context.Terrain == "Plains" then actualCost = math.ceil(actualCost * 1.5) end

		if not (battle.Player.Statuses and battle.Player.Statuses["Transformed"]) then
			if (battle.Player.Gas or 0) < actualCost then hasGas = false end
		end
	end

	if skillName ~= "Retreat" and (not skill or (battle.Player.Cooldowns[skillName] and battle.Player.Cooldowns[skillName] > 0) or not hasGas) then 
		CombatUpdate:FireClient(player, "Update", {Battle = battle}); return 
	end

	battle.IsProcessing = true
	local turnDelay = player:GetAttribute("HasDoubleSpeed") and 0.75 or 1.5

	if skillName == "Maneuver" or skillName == "Evasive Maneuver" or skillName == "Smoke Screen" then 
		PlayVFX:FireClient(player, "Maneuver", "Self")
	elseif skillName == "Close In" or skillName == "Advance" or skillName == "Charge" then
		if not (battle.Player.Statuses and battle.Player.Statuses["Transformed"]) then
			PlayVFX:FireClient(player, "Maneuver", "Self")
		end
	end

	local function DispatchStrike(attacker, defender, strikeSkill, aimLimb)
		if attacker.HP <= 0 or defender.HP <= 0 then return end

		-- [[ THE FIX: Validating the Gap Close logically before execution so State saves! ]]
		local skillObj = SkillData.Skills[strikeSkill]
		if skillObj then
			if skillObj.Effect == "CloseGap" or strikeSkill == "Close In" or strikeSkill == "Advance" or strikeSkill == "Charge" then
				battle.Context.Range = "Close"
			elseif skillObj.Effect == "FallBack" or strikeSkill == "Fall Back" then
				battle.Context.Range = "Long"
			end
		end

		local success, msg, didHit, shakeType = pcall(function() 
			return CombatCore.ExecuteStrike(attacker, defender, strikeSkill, aimLimb, attacker.IsPlayer and "You" or attacker.Name, defender.IsPlayer and "you" or defender.Name, attacker.IsPlayer and "#FFFFFF" or "#FF5555", defender.IsPlayer and "#FFFFFF" or "#FF5555", battle.Context) 
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

	local pRoll = (battle.Player.TotalSpeed or 10) + math.random(1, 15)
	local eRoll = (battle.Enemy.TotalSpeed or 10) + math.random(1, 15)

	if skill.Effect == "Block" or skill.Effect == "FallBack" or skill.Effect == "CloseGap" or skillName == "Maneuver" or skillName == "Evasive Maneuver" then
		pRoll += 10000 
	end

	if battle.Enemy.Statuses and battle.Enemy.Statuses["Telegraphing"] then
		eRoll -= 10000 
	end

	if battle.Enemy.Statuses and battle.Enemy.Statuses["Enraged"] then
		eRoll += 50 
	end

	local combatants = { battle.Player, battle.Enemy }
	table.sort(combatants, function(a, b) return (a.IsPlayer and pRoll or eRoll) > (b.IsPlayer and pRoll or eRoll) end)

	for _, combatant in ipairs(combatants) do
		if battle.Player.HP < 1 or battle.Enemy.HP < 1 then break end
		if combatant.HP < 1 then continue end

		-- [[ THE FIX: TRUE BOSS ENRAGE - Healing and total immunity applied! ]]
		if not combatant.IsPlayer and combatant.IsBoss and not combatant.EnragedOnce then
			local hpRatio = combatant.HP / combatant.MaxHP
			if hpRatio <= 0.30 then
				combatant.EnragedOnce = true
				if not combatant.Statuses then combatant.Statuses = {} end
				combatant.Statuses["Enraged"] = 999
				combatant.Statuses["Stun"] = nil
				combatant.Statuses["Bleed"] = nil
				combatant.Statuses["Burn"] = nil
				combatant.Statuses["Blinded"] = nil
				combatant.Statuses["TrueBlind"] = nil
				combatant.Statuses["Crippled"] = nil
				combatant.Statuses["Weakened"] = nil
				combatant.Statuses["Debuff_Defense"] = nil
				combatant.Statuses["Telegraphing"] = nil

				combatant.HP = math.floor(combatant.MaxHP * 0.5)
				if combatant.MaxGateHP and combatant.MaxGateHP > 0 then
					combatant.GateHP = combatant.MaxGateHP
				end

				local enrageMsg = "<font color='#FF0000'><b>[CRITICAL WARNING]</b></font>\n<font color='#FFAA00'>" .. combatant.Name .. " roars in absolute fury! All debuffs cleansed! HP Restored to 50%! Armor Regenerated! Damage & Speed massively increased!</font>"

				CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = enrageMsg, DidHit = false, ShakeType = "Heavy", EnrageTrigger = true})
				task.wait(turnDelay)
				continue 
			end
		end

		local dotDamage, dotLog = CombatCore.TickStatuses(combatant)

		if dotDamage > 0 then
			local targetName = combatant.IsPlayer and "You" or combatant.Name
			CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = targetName .. " took damage from status effects!" .. dotLog, DidHit = false, ShakeType = "None"})
			task.wait(turnDelay)
			if combatant.HP < 1 then continue end 
		end

		if combatant.Statuses and (combatant.Statuses["Blinded"] or combatant.Statuses["TrueBlind"] or combatant.Statuses["Stun"]) then

			-- [[ THE FIX: Bosses ignore CC while telegraphing! ]]
			if combatant.IsBoss and combatant.Statuses["Telegraphing"] then
				CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#FF0000'><b>" .. combatant.Name .. " shrugs off the crowd control and continues charging!</b></font>", DidHit = false, ShakeType = "None"})
				task.wait(turnDelay)
			else
				if combatant.Statuses["Telegraphing"] then
					combatant.Statuses["Telegraphing"] = nil 
					CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#55FF55'><b>" .. combatant.Name .. "'s charge up was INTERRUPTED!</b></font>", DidHit = false, ShakeType = "Heavy"})
					task.wait(turnDelay)
				end

				local denyMsg = combatant.IsPlayer and "<font color='#555555'>You are INCAPACITATED and lost your turn!</font>" or "<font color='#555555'>" .. combatant.Name .. " is INCAPACITATED and lost their turn!</font>"
				CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = denyMsg, DidHit = false, ShakeType = "None"})
				task.wait(turnDelay)

				if not combatant.IsPlayer and not combatant.IsHuman then
					if not (combatant.Statuses and combatant.Statuses["Burn"]) then
						local regenAmt = math.min(math.floor(combatant.MaxHP * 0.05), 100)
						combatant.HP = math.min(combatant.MaxHP, combatant.HP + regenAmt)
					end
				end
				continue
			end
		end

		if combatant.IsPlayer then
			if skillName == "Retreat" then 
				CombatUpdate:FireClient(player, "Fled", {Battle = battle}); ActiveBattles[player.UserId] = nil; return 
			end

			if skill and skill.GasCost then
				local actualCost = skill.GasCost
				if battle.Context.Terrain == "Forest" then actualCost = math.ceil(actualCost * 0.5)
				elseif battle.Context.Terrain == "Plains" then actualCost = math.ceil(actualCost * 1.5) end
				combatant.Gas = math.max(0, combatant.Gas - actualCost) 
			end
			DispatchStrike(battle.Player, battle.Enemy, skillName, targetLimb)
		else
			local pRatio = (battle.Player.HP or 0) / (battle.Player.MaxHP or 100)
			if pRatio <= 0.30 and not battle.Context.AllyIntervened then
				local intChance = 35
				if string.find(battle.Enemy.Name, "Founding Titan") or string.find(battle.Enemy.Name, "Ymir") or string.find(battle.Enemy.Name, "Doomsday") then
					intChance = 75 
				end

				if math.random(1, 100) <= intChance then
					battle.Context.AllyIntervened = true
					local getPartyFunc = Network:FindFirstChild("GetPlayerParty")
					local partyData = getPartyFunc and getPartyFunc:Invoke(player) or {Members = {}}

					local friends = {}
					for _, mem in ipairs(partyData.Members) do
						if mem.UserId ~= player.UserId then table.insert(friends, mem) end
					end

					local allyName, allyQuote, allySkill, allyUserId, chunkDmg

					if #friends > 0 then
						local savior = friends[math.random(1, #friends)]
						allyName = savior.Name
						allyUserId = savior.UserId
						allyQuote = "I've got your back, " .. player.Name .. "!"
						allySkill = "Team Takedown"

						local fStr = (savior:GetAttribute("Strength") or 10)
						chunkDmg = math.max(fStr * 15, math.floor((battle.Enemy.MaxHP or 1000) * 0.15))
					else
						local allyKeys = {}
						for k, _ in pairs(EnemyData.Allies) do table.insert(allyKeys, k) end
						local allyKey = allyKeys[math.random(1, #allyKeys)]
						local allyData = EnemyData.Allies[allyKey]

						allyName = allyData.Name
						allySkill = allyData.Skills and allyData.Skills[math.random(1, #allyData.Skills)] or "Basic Slash"
						chunkDmg = math.max(allyData.Strength * 10, math.floor((battle.Enemy.MaxHP or 1000) * 0.15))

						local allyQuotes = {
							["Levi Ackerman"] = "Tch. Try not to die on me, brat.",
							["Mikasa Ackerman"] = "I won't let you die. Not here.",
							["Erwin Smith"] = "Advance! Dedicate your heart!",
							["Hange Zoe"] = "Ooh, a new test subject! Leave it to me!",
							["Armin Arlert"] = "I'll cover you! Strike now!"
						}
						allyQuote = allyQuotes[allyData.Name] or "I've got your back!"
					end

					local _, hitGate, gateBroken, actualDmg, gateName = CombatCore.TakeDamage(battle.Enemy, chunkDmg, "Ultrahard Steel Blades")

					local hitMsg = "<font color='#55FFFF'><b>[ALLY INTERVENTION!]</b></font>\n<font color='#55FFFF'>" .. allyName .. "</font> swooped in to assist you!\n<font color='#55FFFF'>" .. allyName .. "</font> used <b>" .. allySkill .. "</b> on " .. battle.Enemy.Name .. " for " .. actualDmg .. " dmg!"
					if hitGate then hitMsg = hitMsg .. " <font color='#DDDDDD'>[Hit " .. tostring(gateName) .. "!]</font>" end
					if gateBroken then hitMsg = hitMsg .. " <font color='#FFFFFF'><b>[" .. tostring(gateName):upper() .. " SHATTERED!]</b></font>" end

					CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = hitMsg, DidHit = true, ShakeType = "Heavy", SkillUsed = allySkill, IsPlayerAttacking = true, AllyIntervention = allyName, AllyQuote = allyQuote, AllyUserId = allyUserId})
					task.wait(turnDelay)

					if battle.Enemy.HP < 1 then break end 

					if battle.Enemy.Statuses and battle.Enemy.Statuses["Telegraphing"] then
						battle.Enemy.Statuses["Telegraphing"] = nil 
						CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#55FF55'><b>" .. battle.Enemy.Name .. "'s charge up was INTERRUPTED!</b></font>", DidHit = false, ShakeType = "Heavy"})
						task.wait(turnDelay)
					end

					CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#AAAAAA'>" .. battle.Enemy.Name .. " is reeling from the surprise attack and loses their turn!</font>", DidHit = false, ShakeType = "None"})
					task.wait(turnDelay)
					continue
				end
			end

			local validAiSkills = {}
			for _, s in ipairs(combatant.Skills) do
				local sd = SkillData.Skills[s]
				local isReady = not combatant.Cooldowns or not combatant.Cooldowns[s] or combatant.Cooldowns[s] <= 0
				local inRange = true
				if sd and sd.Range and sd.Range ~= "Any" then
					inRange = (sd.Range == battle.Context.Range)
				end
				if isReady and inRange then table.insert(validAiSkills, s) end
			end

			battle.Context.TurnCount = (battle.Context.TurnCount or 0) + 1
			local aiSkill = "Brutal Swipe"

			if combatant.Statuses and combatant.Statuses["Telegraphing"] then
				aiSkill = combatant.Statuses["Telegraphing"]; combatant.Statuses["Telegraphing"] = nil

				local sd = SkillData.Skills[aiSkill]
				if sd and sd.Range and sd.Range ~= "Any" and sd.Range ~= battle.Context.Range then
					CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#AAAAAA'>" .. combatant.Name .. " attempted to use <b>" .. aiSkill .. "</b>, but you changed range! The attack missed entirely!</font>", DidHit = false, ShakeType = "None"})
					task.wait(turnDelay)
					continue
				end
			else
				if #validAiSkills > 0 then aiSkill = validAiSkills[math.random(1, #validAiSkills)] end

				if SkillData.Skills[aiSkill] and SkillData.Skills[aiSkill].Telegraphed then
					if not combatant.Statuses then combatant.Statuses = {} end
					combatant.Statuses["Telegraphing"] = aiSkill
					local hintStr = " <font color='#55FF55'>[HINT: USE EVASIVE MANEUVER OR BLOCK!]</font>"
					CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<b><font color='#FFAA00'>WARNING: " .. combatant.Name .. " is charging up " .. aiSkill:upper() .. "!</font></b>" .. hintStr, DidHit = false, ShakeType = "Heavy"})
					PlayVFX:FireClient(player, "TitanRoar", "Enemy")
					task.wait(turnDelay)
					continue
				end
			end

			if aiSkill == "Idle" then
				CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#AAAAAA'>" .. combatant.Name .. " stands completely still.</font>", DidHit = false, ShakeType = "None"})
				task.wait(turnDelay)
			else
				local aiTargets = {"Body", "Body", "Arms", "Legs", "Nape"}
				DispatchStrike(battle.Enemy, battle.Player, aiSkill, aiTargets[math.random(1, #aiTargets)])
			end
		end
	end

	if battle.Player.HP < 1 then
		CombatUpdate:FireClient(player, "Defeat", {Battle = battle}); ActiveBattles[player.UserId] = nil
	elseif battle.Enemy.HP < 1 then
		ProcessEnemyDeath(player, battle)
	else
		battle.IsProcessing = false
		CombatUpdate:FireClient(player, "Update", {Battle = battle})
	end
end)

Players.PlayerRemoving:Connect(function(player) ActiveBattles[player.UserId] = nil end)