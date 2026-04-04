-- @ScriptType: Script
-- @ScriptType: Script
-- Name: SquadManager
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local SquadStore = DataStoreService:GetDataStore("StrikeSquads_V2")
local SquadLeaderboard = DataStoreService:GetOrderedDataStore("Global_Squad_CP_V2")

local Network = ReplicatedStorage:WaitForChild("Network")
local SquadAction = Network:FindFirstChild("SquadAction") or Instance.new("RemoteEvent", Network)
SquadAction.Name = "SquadAction"
local NotificationEvent = Network:WaitForChild("NotificationEvent")

local GetPublicSquads = Instance.new("RemoteFunction", Network); GetPublicSquads.Name = "GetPublicSquads"
local GetSquadRoster = Instance.new("RemoteFunction", Network); GetSquadRoster.Name = "GetSquadRoster"
local GetSquadLeaderboard = Instance.new("RemoteFunction", Network); GetSquadLeaderboard.Name = "GetSquadLeaderboard"

local ActiveSquads = {}

local function SaveSquadData(squadName, data)
	pcall(function()
		SquadStore:SetAsync(squadName, data)
		SquadLeaderboard:SetAsync(squadName, data.CP or 0)
	end)
end

local function UpdateOnlineMembers(sqName)
	local sqData = ActiveSquads[sqName]
	if not sqData then return end

	local vaultStr = HttpService:JSONEncode(sqData.Vault or {"None","None","None","None","None","None"})
	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("SquadName") == sqName then
			p:SetAttribute("SquadCP", sqData.CP)
			p:SetAttribute("SquadVault", vaultStr)
		end
	end
end

SquadAction.OnServerEvent:Connect(function(player, action, data)
	if action == "Create" then
		if not data.Name or string.len(data.Name) < 3 or string.len(data.Name) > 20 then
			NotificationEvent:FireClient(player, "Squad Name must be between 3 and 20 characters.", "Error")
			return
		end

		local currentSquad = player:GetAttribute("SquadName")
		if currentSquad and currentSquad ~= "None" and currentSquad ~= "" then
			NotificationEvent:FireClient(player, "You are already in a Squad!", "Error")
			return
		end

		local dews = player.leaderstats and player.leaderstats:FindFirstChild("Dews")
		if not dews or dews.Value < 100000 then
			NotificationEvent:FireClient(player, "Requires 100,000 Dews to found a Squad.", "Error")
			return
		end

		local success, existingData = pcall(function() return SquadStore:GetAsync(data.Name) end)
		if existingData then
			NotificationEvent:FireClient(player, "That Squad name is already taken!", "Error")
			return
		end

		dews.Value -= 100000
		local safeLogo = data.Logo or ""
		local numericId = safeLogo:match("%d+")
		if numericId then safeLogo = "rbxassetid://" .. numericId else safeLogo = "" end

		local newSquadData = {
			Name = data.Name,
			Desc = data.Desc or "A newly founded Strike Squad.",
			Logo = safeLogo,
			Leader = player.UserId,
			Members = { [tostring(player.UserId)] = {Role = "Leader", Name = player.Name} },
			CP = 0,
			Level = 1,
			Vault = {"None", "None", "None", "None", "None", "None"}
		}

		ActiveSquads[data.Name] = newSquadData
		SaveSquadData(data.Name, newSquadData)

		player:SetAttribute("SquadName", data.Name)
		player:SetAttribute("SquadDesc", newSquadData.Desc)
		player:SetAttribute("SquadLogo", newSquadData.Logo)
		player:SetAttribute("SquadCP", 0)
		player:SetAttribute("SquadVault", HttpService:JSONEncode(newSquadData.Vault))

		NotificationEvent:FireClient(player, "Squad '" .. data.Name .. "' officially founded!", "Success")

	elseif action == "RequestJoin" then
		local sqName = data
		local currentSquad = player:GetAttribute("SquadName")
		if currentSquad and currentSquad ~= "None" and currentSquad ~= "" then
			NotificationEvent:FireClient(player, "You must leave your current Squad first.", "Error")
			return
		end

		local sqData = ActiveSquads[sqName]
		if not sqData then
			local success, stored = pcall(function() return SquadStore:GetAsync(sqName) end)
			if success and stored then
				sqData = stored
				ActiveSquads[sqName] = stored
			end
		end

		if sqData then
			local memCount = 0
			for _, _ in pairs(sqData.Members) do memCount += 1 end
			if memCount >= 15 then
				NotificationEvent:FireClient(player, "That Squad is currently full!", "Error")
				return
			end

			sqData.Members[tostring(player.UserId)] = {Role = "Member", Name = player.Name}
			if not sqData.Vault then sqData.Vault = {"None", "None", "None", "None", "None", "None"} end

			SaveSquadData(sqName, sqData)

			player:SetAttribute("SquadName", sqName)
			player:SetAttribute("SquadDesc", sqData.Desc)
			player:SetAttribute("SquadLogo", sqData.Logo)
			player:SetAttribute("SquadCP", sqData.CP)
			player:SetAttribute("SquadVault", HttpService:JSONEncode(sqData.Vault))

			NotificationEvent:FireClient(player, "Successfully joined " .. sqName .. "!", "Success")
		else
			NotificationEvent:FireClient(player, "Squad not found.", "Error")
		end

		-- [[ THE FIX: TRUE SQUAD VAULT INVENTORY ACTIONS ]]
	elseif action == "DepositItem" then
		local slot = tonumber(data.Slot)
		local itemName = tostring(data.ItemName)
		local sqName = player:GetAttribute("SquadName")
		if not sqName or sqName == "None" then return end

		local sqData = ActiveSquads[sqName]
		if not sqData then return end

		if not sqData.Vault then sqData.Vault = {"None", "None", "None", "None", "None", "None"} end
		if sqData.Vault[slot] ~= "None" then
			NotificationEvent:FireClient(player, "That slot is already full!", "Error")
			return
		end

		local attrName = itemName:gsub("[^%w]", "") .. "Count"
		local pCount = player:GetAttribute(attrName) or 0
		if pCount <= 0 then
			NotificationEvent:FireClient(player, "You do not own this item.", "Error")
			return
		end

		-- Execute Transaction
		player:SetAttribute(attrName, pCount - 1)
		sqData.Vault[slot] = itemName
		SaveSquadData(sqName, sqData)
		UpdateOnlineMembers(sqName)
		NotificationEvent:FireClient(player, "Deposited " .. itemName .. " into Vault.", "Success")

	elseif action == "WithdrawItem" then
		local slot = tonumber(data.Slot)
		local sqName = player:GetAttribute("SquadName")
		if not sqName or sqName == "None" then return end

		local sqData = ActiveSquads[sqName]
		if not sqData then return end

		if not sqData.Vault then sqData.Vault = {"None", "None", "None", "None", "None", "None"} end
		local itemName = sqData.Vault[slot]
		if itemName == "None" then return end

		-- Execute Transaction
		local attrName = itemName:gsub("[^%w]", "") .. "Count"
		player:SetAttribute(attrName, (player:GetAttribute(attrName) or 0) + 1)
		sqData.Vault[slot] = "None"
		SaveSquadData(sqName, sqData)
		UpdateOnlineMembers(sqName)
		NotificationEvent:FireClient(player, "Withdrew " .. itemName .. " from Vault.", "Success")
	end
end)

GetPublicSquads.OnServerInvoke = function(player)
	local squads = {}
	for name, data in pairs(ActiveSquads) do
		local memCount = 0
		for _, _ in pairs(data.Members or {}) do memCount += 1 end
		table.insert(squads, {
			Name = data.Name, Desc = data.Desc,
			Logo = data.Logo ~= "" and data.Logo or "rbxassetid://100826303284945",
			Level = data.Level or 1, MemberCount = memCount .. "/15", CP = data.CP or 0
		})
	end
	table.sort(squads, function(a, b) return a.CP > b.CP end)
	return squads
end

GetSquadRoster.OnServerInvoke = function(player)
	local sqName = player:GetAttribute("SquadName")
	if not sqName or sqName == "None" or sqName == "" then return {} end

	local sqData = ActiveSquads[sqName]
	if not sqData then return {} end

	local roster = {}
	for userId, memData in pairs(sqData.Members) do
		table.insert(roster, { Name = memData.Name, Role = memData.Role })
	end
	table.sort(roster, function(a, b) 
		if a.Role == "Leader" then return true end
		if b.Role == "Leader" then return false end
		return a.Name < b.Name
	end)
	return roster
end

GetSquadLeaderboard.OnServerInvoke = function(player)
	local success, pages = pcall(function() return SquadLeaderboard:GetSortedAsync(false, 10) end)
	local top = {}
	if success and pages then
		for rank, entry in ipairs(pages:GetCurrentPage()) do
			table.insert(top, {Rank = rank, Name = entry.key, CP = entry.value})
		end
	end
	return top
end

Players.PlayerAdded:Connect(function(player)
	player:GetAttributeChangedSignal("DataLoaded"):Connect(function()
		if player:GetAttribute("DataLoaded") then
			local mySquad = player:GetAttribute("SquadName")
			if mySquad and mySquad ~= "None" and mySquad ~= "" then
				local success, sqData = pcall(function() return SquadStore:GetAsync(mySquad) end)
				if success and sqData then
					ActiveSquads[mySquad] = sqData
					player:SetAttribute("SquadDesc", sqData.Desc)
					player:SetAttribute("SquadLogo", sqData.Logo)
					player:SetAttribute("SquadCP", sqData.CP)
					local vaultStr = HttpService:JSONEncode(sqData.Vault or {"None", "None", "None", "None", "None", "None"})
					player:SetAttribute("SquadVault", vaultStr)
				else
					player:SetAttribute("SquadName", "None")
				end
			end
		end
	end)
end)