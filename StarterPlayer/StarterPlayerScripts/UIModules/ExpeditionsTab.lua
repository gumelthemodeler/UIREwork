-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: ExpeditionsTab
local ExpeditionsTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))

local player = Players.LocalPlayer

-- Using the Decal IDs from your original BattleTab reference
local DECALS = {
	Campaign = "rbxassetid://80153476985849",
	AFK = "rbxassetid://114506098039778",
	Raid = "rbxassetid://119392967268687",
	Squads = "rbxassetid://100826303284945", -- Placeholder (Old PvP icon)
	Nightmare = "rbxassetid://90132878979603"
}

function ExpeditionsTab.Initialize(parentFrame)
	-- Clear any placeholder data
	for _, child in ipairs(parentFrame:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end

	-- Title Header
	local Title = UIHelpers.CreateLabel(parentFrame, "COMBAT DEPLOYMENT", UDim2.new(1, 0, 0, 40), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 22)
	Title.Position = UDim2.new(0, 0, 0, 10)

	-- Scrollable Grid Container
	local GridContainer = Instance.new("ScrollingFrame", parentFrame)
	GridContainer.Size = UDim2.new(1, -20, 1, -60)
	GridContainer.Position = UDim2.new(0, 10, 0, 50)
	GridContainer.BackgroundTransparency = 1
	GridContainer.ScrollBarThickness = 4
	GridContainer.BorderSizePixel = 0

	local gridLayout = Instance.new("UIGridLayout", GridContainer)
	gridLayout.CellSize = UDim2.new(0, 400, 0, 180) -- Large, cinematic cards
	gridLayout.CellPadding = UDim2.new(0, 20, 0, 20)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

	-- Dynamic canvas resizing
	gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		GridContainer.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 40)
	end)

	-- Card Generator
	local function CreateModeCard(title, desc, imageId, layoutOrder, onClick)
		local cardBtn = Instance.new("TextButton", GridContainer)
		cardBtn.LayoutOrder = layoutOrder
		cardBtn.Text = ""
		cardBtn.AutoButtonColor = false
		cardBtn.ClipsDescendants = true
		UIHelpers.ApplyGrimPanel(cardBtn, false)

		-- Background Image
		local bg = Instance.new("ImageLabel", cardBtn)
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundTransparency = 1
		bg.Image = imageId
		bg.ScaleType = Enum.ScaleType.Crop
		bg.ZIndex = 1

		-- Fade-to-black Gradient for text readability
		local gradFrame = Instance.new("Frame", cardBtn)
		gradFrame.Size = UDim2.new(1, 0, 1, 0)
		gradFrame.BackgroundColor3 = Color3.new(0,0,0)
		gradFrame.BorderSizePixel = 0
		gradFrame.ZIndex = 2
		local grad = Instance.new("UIGradient", gradFrame)
		grad.Rotation = 90
		grad.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.9),   -- Mostly clear at the top
			NumberSequenceKeypoint.new(0.5, 0.6),
			NumberSequenceKeypoint.new(1, 0.1)    -- Dark at the bottom
		}

		local lblTitle = UIHelpers.CreateLabel(cardBtn, title, UDim2.new(1, -30, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.TextWhite, 20)
		lblTitle.Position = UDim2.new(0, 15, 1, -70)
		lblTitle.TextXAlignment = Enum.TextXAlignment.Left
		lblTitle.ZIndex = 3

		local lblDesc = UIHelpers.CreateLabel(cardBtn, desc, UDim2.new(1, -30, 0, 35), Enum.Font.GothamBold, UIHelpers.Colors.TextMuted, 13)
		lblDesc.Position = UDim2.new(0, 15, 1, -40)
		lblDesc.TextXAlignment = Enum.TextXAlignment.Left
		lblDesc.TextYAlignment = Enum.TextYAlignment.Top
		lblDesc.TextWrapped = true
		lblDesc.ZIndex = 3

		-- Hover effects (Zoom image & turn border Gold)
		local stroke = cardBtn:FindFirstChild("UIStroke")
		cardBtn.MouseEnter:Connect(function()
			if stroke then stroke.Color = UIHelpers.Colors.Gold end
			lblTitle.TextColor3 = UIHelpers.Colors.Gold
			TweenService:Create(bg, TweenInfo.new(0.3), {Size = UDim2.new(1.1, 0, 1.1, 0), Position = UDim2.new(-0.05, 0, -0.05, 0)}):Play()
		end)
		cardBtn.MouseLeave:Connect(function()
			if stroke then stroke.Color = UIHelpers.Colors.BorderMuted end
			lblTitle.TextColor3 = UIHelpers.Colors.TextWhite
			TweenService:Create(bg, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)}):Play()
		end)

		cardBtn.MouseButton1Click:Connect(onClick)
	end

	-- Injecting the Modes
	CreateModeCard("STANDARD CAMPAIGN", "Progress through the main story and face the Titans.", DECALS.Campaign, 1, function()
		print("Opening Campaign Menu...")
		-- Network:WaitForChild("CombatAction"):FireServer("EngageStory")
	end)

	CreateModeCard("AFK EXPEDITIONS", "Send your units beyond the walls to gather resources passively.", DECALS.AFK, 2, function()
		print("Opening AFK Expeditions...")
		-- Network:WaitForChild("CombatAction"):FireServer("EngageEndless")
	end)

	CreateModeCard("NIGHTMARE HUNTS", "Face corrupted Titans to obtain legendary Cursed Weapons.", DECALS.Nightmare, 3, function()
		print("Opening Nightmare Hunts...")
	end)

	CreateModeCard("MULTIPLAYER RAIDS", "Deploy your party to take down Colossal threats.", DECALS.Raid, 4, function()
		print("Opening Raid Menu...")
	end)

	CreateModeCard("STRIKE SQUADS (GROUPS)", "Manage your Player Group. Compete for Ymir's Favor.", DECALS.Squads, 5, function()
		print("Opening Strike Squads / Player Groups Menu...")
	end)
end

return ExpeditionsTab