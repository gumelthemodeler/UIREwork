-- @ScriptType: ModuleScript
-- Name: MusicManager
-- @ScriptType: ModuleScript
local MusicManager = {}

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [[ ORGANIZE YOUR TRACKS HERE ]]
local TRACKS = {
	["Lobby"] = {
		140678692450894,
		137875069000233,
		137410307801537,
		136098872945377
	},
	["Battle"] = {
		138244292110150,
		136613944396198,
		136341071155543
	},
	["Raid"] = { 
		139939916955744,
		136977425799420
	},
	["Nightmare"] = { 
		139637448871564,
		138932123500602
	},
	-- [[ NEW: Dynamic Enrage Phase Music! ]]
	["BossEnrage"] = {
		139637448871564, -- Intense, fast-paced choir/orchestral IDs
		138932123500602 
	}
}

local TARGET_VOLUME = 0.4
local FADE_TIME = 2.0

local Player1 = Instance.new("Sound")
Player1.Name = "BGM_Player_1"
Player1.Volume = 0
Player1.Parent = SoundService

local Player2 = Instance.new("Sound")
Player2.Name = "BGM_Player_2"
Player2.Volume = 0
Player2.Parent = SoundService

local ActivePlayer = Player1
local CurrentCategory = nil
local LastTrackId = 0

local function PlayNextTrack()
	if not CurrentCategory or not TRACKS[CurrentCategory] then return end

	local trackList = TRACKS[CurrentCategory]
	local nextTrackId = trackList[math.random(1, #trackList)]

	if #trackList > 1 then
		while nextTrackId == LastTrackId do
			nextTrackId = trackList[math.random(1, #trackList)]
		end
	end
	LastTrackId = nextTrackId

	local nextPlayer = (ActivePlayer == Player1) and Player2 or Player1
	nextPlayer.SoundId = "rbxassetid://" .. tostring(nextTrackId)

	task.spawn(function()
		pcall(function() ContentProvider:PreloadAsync({nextPlayer}) end)

		if nextPlayer.SoundId == "rbxassetid://" .. tostring(nextTrackId) then
			nextPlayer:Play()
			TweenService:Create(nextPlayer, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear), {Volume = TARGET_VOLUME}):Play()

			local prevPlayer = ActivePlayer
			local fadeOut = TweenService:Create(prevPlayer, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear), {Volume = 0})
			fadeOut:Play()

			task.delay(FADE_TIME, function()
				if prevPlayer.Volume == 0 then 
					prevPlayer:Stop()
					prevPlayer.TimePosition = 0 
				end
			end)

			ActivePlayer = nextPlayer
		end
	end)
end

Player1.Ended:Connect(function() if ActivePlayer == Player1 then PlayNextTrack() end end)
Player2.Ended:Connect(function() if ActivePlayer == Player2 then PlayNextTrack() end end)

function MusicManager.SetCategory(newCategory)
	if CurrentCategory == newCategory then return end
	if not TRACKS[newCategory] then return end

	CurrentCategory = newCategory
	PlayNextTrack()
end

function MusicManager.Initialize()
	MusicManager.SetCategory("Lobby")

	local Network = ReplicatedStorage:WaitForChild("Network")
	local CombatUpdate = Network:WaitForChild("CombatUpdate")

	CombatUpdate.OnClientEvent:Connect(function(action, data)
		if not data or not data.Battle then return end
		local ctx = data.Battle.Context
		local enemy = data.Battle.Enemy

		-- [[ THE FIX: Adaptive Music shifting based on Boss HP! ]]
		local hpRatio = (enemy.HP or 1) / (enemy.MaxHP or 1)
		local isEnraged = enemy.IsBoss and hpRatio <= 0.30

		if action == "Start" or action == "StartMinigame" or action == "Update" or action == "TurnStrike" or action == "WaveComplete" then
			if enemy.IsDialogue then return end

			local targetCat = "Battle"
			if ctx.IsWorldBoss or ctx.IsRaid then targetCat = "Raid"
			elseif ctx.IsNightmare then targetCat = "Nightmare" end

			if isEnraged then targetCat = "BossEnrage" end

			MusicManager.SetCategory(targetCat)
		end
	end)
end

return MusicManager