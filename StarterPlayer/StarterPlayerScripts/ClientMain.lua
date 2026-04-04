-- @ScriptType: LocalScript
-- @ScriptType: LocalScript
-- Name: ClientMain
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Failsafe: Destroy any existing UI to prevent duplicates if the script reloads
local existingUI = PlayerGui:FindFirstChild("AoTMasterUI")
if existingUI then
	existingUI:Destroy()
end

-- Create the Absolute Master ScreenGui
local MasterScreen = Instance.new("ScreenGui")
MasterScreen.Name = "AoTMasterUI"
MasterScreen.ResetOnSpawn = false
MasterScreen.IgnoreGuiInset = true -- Covers the entire screen, ignoring the top Roblox bar
MasterScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MasterScreen.Parent = PlayerGui

print("[AoT UI] Booting Main Interface...")

-- Route to the centralized Main UI Controller
local MainUI = require(script.Parent:WaitForChild("UIModules"):WaitForChild("MainUI"))

-- Ignite the UI
MainUI.Initialize(MasterScreen)