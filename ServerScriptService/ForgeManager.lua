-- @ScriptType: Script
-- @ScriptType: Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local TitanData = require(ReplicatedStorage:WaitForChild("TitanData"))
local Network = ReplicatedStorage:WaitForChild("Network")
local NotificationEvent = Network:WaitForChild("NotificationEvent")

local FusionRecipes = { 
	["Female Titan"] = { ["Founding Titan"] = "Founding Female Titan" }, 
	["Founding Titan"] = { ["Female Titan"] = "Founding Female Titan", ["Attack Titan"] = "Founding Attack Titan" }, 
	["Attack Titan"] = { ["Armored Titan"] = "Armored Attack Titan", ["War Hammer Titan"] = "War Hammer Attack Titan", ["Founding Titan"] = "Founding Attack Titan" }, 
	["Armored Titan"] = { ["Attack Titan"] = "Armored Attack Titan" }, 
	["War Hammer Titan"] = { ["Attack Titan"] = "War Hammer Attack Titan" }, 
	["Colossal Titan"] = { ["Jaw Titan"] = "Colossal Jaw Titan" }, 
	["Jaw Titan"] = { ["Colossal Titan"] = "Colossal Jaw Titan" } 
}

Network:WaitForChild("ForgeItem").OnServerEvent:Connect(function(player, recipeName)
	local recipe = ItemData.ForgeRecipes[recipeName]
	if not recipe then return end

	local dews = player.leaderstats.Dews.Value
	if dews < recipe.DewCost then NotificationEvent:FireClient(player, "Not enough Dews to forge this!", "Error"); return end

	local canForge = true
	for reqItemName, reqAmt in pairs(recipe.ReqItems) do
		local safeReq = reqItemName:gsub("[^%w]", "") .. "Count"
		if (player:GetAttribute(safeReq) or 0) < reqAmt then canForge = false; break end
	end
	if not canForge then NotificationEvent:FireClient(player, "Missing required materials!", "Error"); return end

	player.leaderstats.Dews.Value -= recipe.DewCost
	for reqItemName, reqAmt in pairs(recipe.ReqItems) do
		local safeReq = reqItemName:gsub("[^%w]", "") .. "Count"
		player:SetAttribute(safeReq, (player:GetAttribute(safeReq) or 0) - reqAmt)
	end
	local resSafeName = recipe.Result:gsub("[^%w]", "") .. "Count"
	player:SetAttribute(resSafeName, (player:GetAttribute(resSafeName) or 0) + 1)

	local resData = ItemData.Equipment[recipe.Result] or ItemData.Consumables[recipe.Result]
	if resData and resData.Rarity == "Transcendent" then NotificationEvent:FireAllClients("<font color='#FF55FF'><b>" .. player.Name .. " has forged the " .. recipe.Result .. "!</b></font>", "Success")
	else NotificationEvent:FireClient(player, "Forged " .. recipe.Result .. "!", "Success") end
end)

Network:WaitForChild("AwakenWeapon").OnServerEvent:Connect(function(player, weaponName)
	local extracts = player:GetAttribute("TitanHardeningExtractCount") or 0
	if extracts >= 1 then
		local safeWpn = weaponName:gsub("[^%w]", "")
		if (player:GetAttribute(safeWpn .. "Count") or 0) > 0 then
			player:SetAttribute("TitanHardeningExtractCount", extracts - 1)
			local possibleStats = { "DMG", "DODGE", "CRIT", "MAX HP", "SPEED", "GAS CAP", "IGNORE ARMOR" }
			local stat1, stat2 = possibleStats[math.random(1, #possibleStats)], possibleStats[math.random(1, #possibleStats)]
			local statStr = "+" .. math.random(5, 25) .. (stat1 == "MAX HP" and "" or "%") .. " " .. stat1 .. " | +" .. math.random(5, 25) .. (stat2 == "MAX HP" and "" or "%") .. " " .. stat2
			player:SetAttribute(safeWpn .. "_Awakened", statStr)
			NotificationEvent:FireClient(player, weaponName .. " Awakened!", "Success")
		end
	end
end)

Network:WaitForChild("AwakenAction").OnServerEvent:Connect(function(player, actionType)
	if actionType == "Clan" then
		local count = player:GetAttribute("AncestralAwakeningSerumCount") or 0
		local currentClan = player:GetAttribute("Clan") or "None"
		local validClans = {["Ackerman"] = true, ["Yeager"] = true, ["Tybur"] = true, ["Braun"] = true, ["Galliard"] = true}
		if count >= 1 and validClans[currentClan] then
			player:SetAttribute("AncestralAwakeningSerumCount", count - 1); player:SetAttribute("Clan", "Awakened " .. currentClan)
			NotificationEvent:FireClient(player, currentClan .. " Bloodline Awakened!", "Success")
		elseif count >= 1 then NotificationEvent:FireClient(player, "Your bloodline is too weak to awaken.", "Error") end
	elseif actionType == "Titan" then
		local count = player:GetAttribute("YmirsClayFragmentCount") or 0
		if count >= 1 and player:GetAttribute("Titan") == "Attack Titan" then
			player:SetAttribute("YmirsClayFragmentCount", count - 1); player:SetAttribute("Titan", "Founding Attack Titan")
			NotificationEvent:FireClient(player, "You have reached the Coordinate!", "Success")
		end
	end
end)

local FuseTitan = Network:FindFirstChild("FuseTitan") or Instance.new("RemoteEvent", Network)
FuseTitan.Name = "FuseTitan"
FuseTitan.OnServerEvent:Connect(function(player, baseSlot, sacSlot)
	if not baseSlot or not sacSlot or baseSlot == sacSlot then return end
	local validSlots = {["Equipped"] = true, ["1"] = true, ["2"] = true, ["3"] = true, ["4"] = true, ["5"] = true, ["6"] = true}
	if not validSlots[tostring(baseSlot)] or not validSlots[tostring(sacSlot)] then return end

	local dews = player.leaderstats.Dews.Value
	if dews >= 250000 then
		local baseAttr = (baseSlot == "Equipped") and "Titan" or ("Titan_Slot" .. baseSlot)
		local sacAttr = (sacSlot == "Equipped") and "Titan" or ("Titan_Slot" .. sacSlot)

		local baseTitan = player:GetAttribute(baseAttr) or "None"
		local sacTitan = player:GetAttribute(sacAttr) or "None"
		local result = FusionRecipes[baseTitan] and FusionRecipes[baseTitan][sacTitan]

		if result then
			player.leaderstats.Dews.Value -= 250000
			player:SetAttribute(baseAttr, result)
			player:SetAttribute(sacAttr, "None")
			NotificationEvent:FireClient(player, "Fusion Successful! You inherited the " .. result .. "!", "Success")
		else
			NotificationEvent:FireClient(player, "Invalid Fusion combination.", "Error")
		end
	else
		NotificationEvent:FireClient(player, "Not enough Dews to fuse!", "Error")
	end
end)

local ItemizeTitan = Network:FindFirstChild("ItemizeTitan") or Instance.new("RemoteEvent", Network)
ItemizeTitan.Name = "ItemizeTitan"
ItemizeTitan.OnServerEvent:Connect(function(player, slotId)
	if not slotId then return end
	local dews = player.leaderstats.Dews.Value
	if dews >= 100000 then
		local attrName = (slotId == "Equipped") and "Titan" or ("Titan_Slot" .. slotId)
		local titanName = player:GetAttribute(attrName) or "None"
		if titanName ~= "None" then
			player.leaderstats.Dews.Value -= 100000
			player:SetAttribute(attrName, "None")
			local safeItemName = ("Itemized " .. titanName):gsub("[^%w]", "") .. "Count"
			player:SetAttribute(safeItemName, (player:GetAttribute(safeItemName) or 0) + 1)
			NotificationEvent:FireClient(player, "Titan extracted to your inventory!", "Success")
		end
	else
		NotificationEvent:FireClient(player, "Not enough Dews to itemize!", "Error")
	end
end)