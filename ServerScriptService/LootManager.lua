-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local LootManager = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local Network = ReplicatedStorage:WaitForChild("Network")

local MAX_INVENTORY_CAPACITY = 50
local SellValues = { Common = 10, Uncommon = 25, Rare = 75, Epic = 200, Legendary = 500, Mythical = 1500, Transcendent = 0 }

local function GetUniqueSlotCount(plr)
	local count = 0
	for iName, _ in pairs(ItemData.Equipment) do
		if (plr:GetAttribute(iName:gsub("[^%w]", "") .. "Count") or 0) > 0 then count += 1 end
	end
	for iName, _ in pairs(ItemData.Consumables) do
		if (plr:GetAttribute(iName:gsub("[^%w]", "") .. "Count") or 0) > 0 then count += 1 end
	end
	return count
end

function LootManager.ProcessDrops(player, enemyDrops, isEndless, currentWave)
	local droppedItems = {}
	local autoSoldDewsCapacity = 0
	local autoSoldDewsSettings = 0
	local currentSlots = GetUniqueSlotCount(player)
	local dropMultiplier = player:GetAttribute("HasDoubleDrops") and 2 or 1

	if enemyDrops and enemyDrops.ItemChance then
		for itemName, baseChance in pairs(enemyDrops.ItemChance) do
			local iData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
			local rarity = iData and iData.Rarity or "Common"
			local finalChance = baseChance

			if rarity == "Mythical" then
				finalChance = baseChance * 1.0 
				if isEndless then finalChance += (currentWave * 0.1) end
				finalChance = math.min(finalChance, math.max(5, baseChance))
			elseif rarity == "Legendary" then
				finalChance = baseChance * 1.2
				if isEndless then finalChance += (currentWave * 0.25) end
				finalChance = math.min(finalChance, math.max(12, baseChance))
			elseif rarity == "Epic" then
				finalChance = baseChance * 2.0
				if isEndless then finalChance += (currentWave * 1.0) end
				finalChance = math.min(finalChance, math.max(40, baseChance))
			else
				finalChance = baseChance * 3.0
				if isEndless then finalChance += (currentWave * 2.5) end
				finalChance = math.min(finalChance, 100)
			end

			local roll = math.random() * 100
			if roll <= finalChance then
				local attrName = itemName:gsub("[^%w]", "") .. "Count"
				local currentAmt = player:GetAttribute(attrName) or 0
				local isAutoSellEnabled = player:GetAttribute("AutoSell_" .. rarity)

				if isAutoSellEnabled then
					-- Directly sell based on user preference
					autoSoldDewsSettings += (SellValues[rarity] or 10) * dropMultiplier
				elseif currentAmt == 0 and currentSlots >= MAX_INVENTORY_CAPACITY then
					-- Forced sell because they hit 50/50 unique items
					autoSoldDewsCapacity += (SellValues[rarity] or 10) * dropMultiplier
				else
					local nameTag = (dropMultiplier > 1) and (itemName .. " (x" .. dropMultiplier .. ")") or itemName
					table.insert(droppedItems, nameTag)
					player:SetAttribute(attrName, currentAmt + dropMultiplier)
					if currentAmt == 0 then currentSlots += 1 end
				end
			end
		end

		if isEndless and #droppedItems == 0 and autoSoldDewsCapacity == 0 and autoSoldDewsSettings == 0 and currentWave % 3 == 0 then
			local pool = {}
			for iname, _ in pairs(enemyDrops.ItemChance) do 
				local iData = ItemData.Equipment[iname] or ItemData.Consumables[iname]
				if iData and iData.Rarity ~= "Mythical" and iData.Rarity ~= "Legendary" then
					table.insert(pool, iname) 
				end
			end
			if #pool > 0 then
				local pItem = pool[math.random(1, #pool)]
				local attrName = pItem:gsub("[^%w]", "") .. "Count"
				local currentAmt = player:GetAttribute(attrName) or 0
				local iData = ItemData.Equipment[pItem] or ItemData.Consumables[pItem]
				local rarity = iData and iData.Rarity or "Common"
				local isAutoSellEnabled = player:GetAttribute("AutoSell_" .. rarity)

				if isAutoSellEnabled then
					autoSoldDewsSettings += (SellValues[rarity] or 10) * dropMultiplier
				elseif currentAmt == 0 and currentSlots >= MAX_INVENTORY_CAPACITY then
					autoSoldDewsCapacity += (SellValues[rarity] or 10) * dropMultiplier
				else
					local nameTag = (dropMultiplier > 1) and (pItem .. " (x" .. dropMultiplier .. ")") or pItem
					table.insert(droppedItems, nameTag)
					player:SetAttribute(attrName, currentAmt + dropMultiplier)
				end
			end
		end
	end

	-- [[ THE FIX: Safely separate auto-sell sources ]]
	if autoSoldDewsSettings > 0 then
		player.leaderstats.Dews.Value += autoSoldDewsSettings
		local NotificationEvent = Network:FindFirstChild("NotificationEvent")
		if NotificationEvent then
			NotificationEvent:FireClient(player, "Auto-Sold dropped items for " .. autoSoldDewsSettings .. " Dews!", "Success")
		end
	end

	if autoSoldDewsCapacity > 0 then
		player.leaderstats.Dews.Value += autoSoldDewsCapacity
	end

	-- We only return Capacity Dews, so CombatManager only prints the "Inventory Full" text if it was ACTUALLY full.
	return droppedItems, autoSoldDewsCapacity
end

return LootManager