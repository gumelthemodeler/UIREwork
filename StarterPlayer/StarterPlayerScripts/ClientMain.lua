-- @ScriptType: LocalScript
-- Name: ClientMain
-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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
MasterScreen.IgnoreGuiInset = true 
MasterScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MasterScreen.Parent = PlayerGui

print("[AoT UI] Booting Main Interface...")

-- ==========================================
-- SEAMLESS LOADING SCREEN SETUP
-- ==========================================
local LoadScreen = Instance.new("Frame", MasterScreen)
LoadScreen.Size = UDim2.new(1, 0, 1, 0)
LoadScreen.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
LoadScreen.ZIndex = 99999 

local BGImage = Instance.new("ImageLabel", LoadScreen)
BGImage.Size = UDim2.new(1, 0, 1, 0)
BGImage.BackgroundTransparency = 1
BGImage.ScaleType = Enum.ScaleType.Crop
BGImage.Image = "rbxassetid://125800917140688"
BGImage.ImageTransparency = 0.4
BGImage.ZIndex = 100000

local LogoImage = Instance.new("ImageLabel", LoadScreen)
LogoImage.Size = UDim2.new(0, 400, 0, 200) 
LogoImage.Position = UDim2.new(0.5, 0, 0.45, 0)
LogoImage.AnchorPoint = Vector2.new(0.5, 0.5)
LogoImage.BackgroundTransparency = 1
LogoImage.ScaleType = Enum.ScaleType.Fit
LogoImage.Image = "rbxassetid://121131619457251"
LogoImage.ZIndex = 100001

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
SpinnerRing.ImageColor3 = Color3.fromRGB(255, 85, 85) 
SpinnerRing.ZIndex = 100002

local spinConn = RunService.RenderStepped:Connect(function()
	local t = os.clock()
	SpinnerRing.Rotation = SpinnerRing.Rotation + 4
	LogoImage.Position = UDim2.new(0.5, 0, 0.45, math.sin(t * 3) * 10)
end)

task.wait() 

-- ==========================================
-- HEAVY LIFTING & INITIALIZATION
-- ==========================================
if not game:IsLoaded() then game.Loaded:Wait() end

-- [[ INITIALIZE AUDIO, VFX, & MUSIC MODULES BEFORE UI ]]
local VFXManager = require(script.Parent:WaitForChild("VFXManager"))
VFXManager.Initialize()

local MusicManager = require(script.Parent:WaitForChild("MusicManager"))
MusicManager.Initialize()

-- [[ DEVICE ROUTING ]]
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

if isMobile then
	print("[AoT UI] Mobile Device Detected. Booting MobileUI...")
	local MobileUI = require(script.Parent:WaitForChild("MobileUI"):WaitForChild("MobileMainUI"))
	MobileUI.Initialize(MasterScreen)
else
	print("[AoT UI] PC Device Detected. Booting Standard UI...")
	local MainUI = require(script.Parent:WaitForChild("UIModules"):WaitForChild("MainUI"))
	MainUI.Initialize(MasterScreen)
end

-- ==========================================
-- ARTIFICIAL DELAY & SMOOTH FADE OUT
-- ==========================================
task.wait(5) 

spinConn:Disconnect()

local fadeTime = 0.8
local fadeInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

TweenService:Create(LoadScreen, fadeInfo, {BackgroundTransparency = 1}):Play()
TweenService:Create(BGImage, fadeInfo, {ImageTransparency = 1}):Play()
TweenService:Create(LogoImage, fadeInfo, {ImageTransparency = 1}):Play()
TweenService:Create(SpinnerRing, fadeInfo, {ImageTransparency = 1}):Play()

task.wait(fadeTime)
LoadScreen:Destroy()