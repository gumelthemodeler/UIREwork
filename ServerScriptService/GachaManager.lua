-- @ScriptType: Script
-- @ScriptType: Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TitanData = require(ReplicatedStorage:WaitForChild("TitanData"))
local Network = ReplicatedStorage:WaitForChild("Network")

local GachaRoll = Network:FindFirstChild("GachaRoll") or Instance.new("RemoteEvent", Network)
GachaRoll.Name = "GachaRoll"
local GachaResult = Network:FindFirstChild("GachaResult") or Instance.new("RemoteEvent", Network)
GachaResult.Name = "GachaResult"

GachaRoll.OnServerEvent:Connect(function(player, gType, isPremium)
	local attrReq = (gType == "Titan") and (isPremium and "SpinalFluidSyringeCount" or "StandardTitanSerumCount") or "ClanBloodVialCount"
	local itemsOwned = player:GetAttribute(attrReq) or 0

	if itemsOwned > 0 then
		player:SetAttribute(attrReq, itemsOwned - 1)
		local resultName, rarity

		if gType == "Titan" then
			local legPity = player:GetAttribute("TitanPity") or 0
			local mythPity = player:GetAttribute("TitanMythicalPity") or 0
			if isPremium then legPity += 100 end

			resultName, rarity = TitanData.RollTitan(legPity, mythPity)

			if rarity == "Mythical" or rarity == "Transcendent" then
				player:SetAttribute("TitanPity", 0); player:SetAttribute("TitanMythicalPity", 0)
			elseif rarity == "Legendary" then
				player:SetAttribute("TitanPity", 0); player:SetAttribute("TitanMythicalPity", mythPity + 1)
			else
				player:SetAttribute("TitanPity", legPity + 1); player:SetAttribute("TitanMythicalPity", mythPity + 1)
			end
		else
			local clanPity = player:GetAttribute("ClanPity") or 0
			if clanPity >= 100 then
				local premiumClans = {}
				for cName, w in pairs(TitanData.ClanWeights) do if w <= 4.0 then table.insert(premiumClans, cName) end end
				resultName = premiumClans[math.random(1, #premiumClans)]
				rarity = (TitanData.ClanWeights[resultName] <= 1.5) and "Mythical" or "Legendary"
				player:SetAttribute("ClanPity", 0)
			else
				resultName = TitanData.RollClan()
				local weight = TitanData.ClanWeights[resultName] or 40
				if weight <= 1.5 then rarity = "Mythical" elseif weight <= 4.0 then rarity = "Legendary" elseif weight <= 8.0 then rarity = "Epic" elseif weight <= 15.0 then rarity = "Rare" else rarity = "Common" end
				if rarity == "Legendary" or rarity == "Mythical" or rarity == "Transcendent" then player:SetAttribute("ClanPity", 0) else player:SetAttribute("ClanPity", clanPity + 1) end
			end
		end
		player:SetAttribute(gType, resultName)
		GachaResult:FireClient(player, gType, resultName, rarity)
	else
		GachaResult:FireClient(player, gType, "Error", "None")
	end
end)