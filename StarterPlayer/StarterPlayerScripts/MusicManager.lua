-- @ScriptType: ModuleScript
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
	["Raid"] = { -- Used for World Bosses and Raids
		139939916955744,
		136977425799420
	},
	["Nightmare"] = { -- Used for Nightmare Hunts / Abyssal Bosses
		139637448871564,
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
		pcall(function()
			ContentProvider:PreloadAsync({nextPlayer})
		end)

		-- Ensure another play call hasn't already fired and replaced us while loading
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

Player1.Ended:Connect(function()
	if ActivePlayer == Player1 then PlayNextTrack() end
end)

Player2.Ended:Connect(function()
	if ActivePlayer == Player2 then PlayNextTrack() end
end)

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
		-- [[ THE FIX: Intercept "Dialogue" nodes so they correctly trigger battle music, not just "Start" events! ]]
		if action == "Start" or action == "StartMinigame" or action == "Dialogue" then
			local ctx = data.Battle and data.Battle.Context
			if ctx then
				if ctx.IsWorldBoss or ctx.IsRaid then MusicManager.SetCategory("Raid")
				elseif ctx.IsNightmare then MusicManager.SetCategory("Nightmare")
				else MusicManager.SetCategory("Battle") end
			else
				MusicManager.SetCategory("Battle")
			end
		end
	end)
end

return MusicManager