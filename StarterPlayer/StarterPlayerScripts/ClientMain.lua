-- @ScriptType: LocalScript
-- Name: ClientMain
-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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

-- ==========================================
-- SEAMLESS LOADING SCREEN SETUP
-- ==========================================
local LoadScreen = Instance.new("Frame", MasterScreen)
LoadScreen.Size = UDim2.new(1, 0, 1, 0)
LoadScreen.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
LoadScreen.ZIndex = 99999 -- Ensure it is on top of absolutely everything

-- Custom Background Image
local BGImage = Instance.new("ImageLabel", LoadScreen)
BGImage.Size = UDim2.new(1, 0, 1, 0)
BGImage.BackgroundTransparency = 1
BGImage.ScaleType = Enum.ScaleType.Crop
BGImage.Image = "rbxassetid://125800917140688"
BGImage.ImageTransparency = 0.4
BGImage.ZIndex = 100000

-- Game Logo
local LogoImage = Instance.new("ImageLabel", LoadScreen)
LogoImage.Size = UDim2.new(0, 400, 0, 200) 
LogoImage.Position = UDim2.new(0.5, 0, 0.45, 0)
LogoImage.AnchorPoint = Vector2.new(0.5, 0.5)
LogoImage.BackgroundTransparency = 1
LogoImage.ScaleType = Enum.ScaleType.Fit
LogoImage.Image = "rbxassetid://121131619457251"
LogoImage.ZIndex = 100001

-- Spinning Loading Ring
local SpinnerContainer = Instance.new("Frame", LoadScreen)
SpinnerContainer.Size = UDim2.new(0, 75, 0, 75) 
SpinnerContainer.Position = UDim2.new(0.5, 0, 0.85, 0)
SpinnerContainer.AnchorPoint = Vector2.new(0.5, 0.5)
SpinnerContainer.BackgroundTransparency = 1
SpinnerContainer.ZIndex = 100001

local SpinnerRing = Instance.new("ImageLabel", SpinnerContainer)
SpinnerRing.Size = UDim2.new(1, 0, 1, 0)
SpinnerRing.BackgroundTransparency = 1
SpinnerRing.ScaleType = Enum.ScaleType.Fit 
SpinnerRing.Image = "rbxassetid://6331335348" 
SpinnerRing.ImageColor3 = Color3.fromRGB(255, 85, 85) -- Changed to a sharp crimson red tint
SpinnerRing.ZIndex = 100002

-- Start the spinning animation and smooth logo hover
local spinConn = RunService.RenderStepped:Connect(function()
	local t = os.clock()
	SpinnerRing.Rotation = SpinnerRing.Rotation + 4
	-- Adds a smooth vertical bobbing offset to the logo's Y position
	LogoImage.Position = UDim2.new(0.5, 0, 0.45, math.sin(t * 3) * 10)
end)

-- [[ CRITICAL FIX: Force Roblox to render the loading screen BEFORE the thread freezes! ]]
task.wait() 

-- ==========================================
-- HEAVY LIFTING & INITIALIZATION
-- ==========================================

-- 1. Wait until the actual game map and core instances are loaded
if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- 2. Require the MainUI Module (This normally causes the lag spike)
local MainUI = require(script.Parent:WaitForChild("UIModules"):WaitForChild("MainUI"))

-- 3. Ignite the UI (Builds all the frames and grids)
MainUI.Initialize(MasterScreen)

-- ==========================================
-- ARTIFICIAL DELAY & SMOOTH FADE OUT
-- ==========================================
-- Hold the loading screen for a comfortable duration (5 seconds)
task.wait(5) 

-- Stop the animations
spinConn:Disconnect()

-- Smoothly fade out everything
local fadeTime = 0.8
local fadeInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

TweenService:Create(LoadScreen, fadeInfo, {BackgroundTransparency = 1}):Play()
TweenService:Create(BGImage, fadeInfo, {ImageTransparency = 1}):Play()
TweenService:Create(LogoImage, fadeInfo, {ImageTransparency = 1}):Play()
TweenService:Create(SpinnerRing, fadeInfo, {ImageTransparency = 1}):Play()

-- Destroy the loading screen completely once it's invisible
task.wait(fadeTime)
LoadScreen:Destroy()