-- @ScriptType: ModuleScript
-- Name: BountiesTab
local BountiesTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))

local player = Players.LocalPlayer

local function CreateSharpButton(parent, text, size, font, textSize)
	local btn = Instance.new("TextButton", parent)
	btn.Size = size
	btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Font = font
	btn.TextColor3 = Color3.fromRGB(245, 245, 245)
	btn.TextSize = textSize
	btn.Text = text

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(70, 70, 80)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	btn.MouseEnter:Connect(function() stroke.Color = Color3.fromRGB(225, 185, 60); btn.TextColor3 = Color3.fromRGB(225, 185, 60) end)
	btn.MouseLeave:Connect(function() stroke.Color = Color3.fromRGB(70, 70, 80); btn.TextColor3 = Color3.fromRGB(245, 245, 245) end)
	return btn, stroke
end

local function FormatBountyName(taskType, count)
	if taskType == "Kill" then return "Eliminate " .. count .. " enemies"
	elseif taskType == "Clear" then return "Clear " .. count .. " waves"
	elseif taskType == "Maneuver" then return "Perform " .. count .. " maneuvers"
	elseif taskType == "Transform" then return "Transform into a Titan " .. count .. " times"
	elseif taskType == "Dispatch" then return "Complete " .. count .. " AFK dispatches"
	end
	return "Complete objective"
end

function BountiesTab.Initialize(parentFrame)
	local ScrollContainer = Instance.new("ScrollingFrame", parentFrame)
	ScrollContainer.Size = UDim2.new(1, 0, 1, 0)
	ScrollContainer.BackgroundTransparency = 1
	ScrollContainer.ScrollBarThickness = 6
	ScrollContainer.BorderSizePixel = 0

	local slLayout = Instance.new("UIListLayout", ScrollContainer)
	slLayout.Padding = UDim.new(0, 15)
	slLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local sPad = Instance.new("UIPadding", ScrollContainer)
	sPad.PaddingTop = UDim.new(0, 20)
	sPad.PaddingBottom = UDim.new(0, 20)

	local function CreateBountyCard(bountyId, titlePrefix)
		local card = Instance.new("Frame", ScrollContainer)
		card.Size = UDim2.new(0.9, 0, 0, 80)
		card.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
		local strk = Instance.new("UIStroke", card)
		strk.Color = Color3.fromRGB(70, 70, 80); strk.Thickness = 2

		local titleLbl = UIHelpers.CreateLabel(card, titlePrefix, UDim2.new(0.6, 0, 0, 25), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 16)
		titleLbl.Position = UDim2.new(0, 15, 0, 10); titleLbl.TextXAlignment = Enum.TextXAlignment.Left

		local progBarBG = Instance.new("Frame", card)
		progBarBG.Size = UDim2.new(0.6, 0, 0, 12)
		progBarBG.Position = UDim2.new(0, 15, 0, 45)
		progBarBG.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
		local pbStroke = Instance.new("UIStroke", progBarBG); pbStroke.Color = Color3.fromRGB(50, 50, 60)

		local progFill = Instance.new("Frame", progBarBG)
		progFill.Size = UDim2.new(0, 0, 1, 0)
		progFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
		progFill.BorderSizePixel = 0

		local progText = UIHelpers.CreateLabel(card, "0 / 1", UDim2.new(0.6, 0, 0, 20), Enum.Font.GothamBold, UIHelpers.Colors.TextWhite, 12)
		progText.Position = UDim2.new(0, 15, 0, 60); progText.TextXAlignment = Enum.TextXAlignment.Left

		local actionBtn, actStroke = CreateSharpButton(card, "IN PROGRESS", UDim2.new(0, 120, 0, 36), Enum.Font.GothamBlack, 12)
		actionBtn.Position = UDim2.new(1, -15, 0.5, 0); actionBtn.AnchorPoint = Vector2.new(1, 0.5)

		local function UpdateCard()
			local task = player:GetAttribute(bountyId .. "_Task") or "Unknown"
			local prog = player:GetAttribute(bountyId .. "_Prog") or 0
			local max = player:GetAttribute(bountyId .. "_Max") or 1
			local claimed = player:GetAttribute(bountyId .. "_Claimed")

			-- [[ THE FIX: FormatBountyName correctly applied! ]]
			titleLbl.Text = titlePrefix .. ": " .. FormatBountyName(task, max)
			progText.Text = prog .. " / " .. max
			progFill.Size = UDim2.new(math.clamp(prog/max, 0, 1), 0, 1, 0)

			if claimed then
				actionBtn.Text = "CLAIMED"
				actionBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
				actStroke.Color = Color3.fromRGB(50, 50, 60)
				actionBtn.Active = false
				progFill.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			elseif prog >= max then
				actionBtn.Text = "CLAIM REWARD"
				actionBtn.TextColor3 = UIHelpers.Colors.Gold
				actStroke.Color = UIHelpers.Colors.Gold
				actionBtn.Active = true
			else
				actionBtn.Text = "IN PROGRESS"
				actionBtn.TextColor3 = UIHelpers.Colors.TextMuted
				actStroke.Color = Color3.fromRGB(70, 70, 80)
				actionBtn.Active = false
			end
		end

		actionBtn.MouseButton1Click:Connect(function()
			if actionBtn.Active and actionBtn.Text == "CLAIM REWARD" then
				Network:WaitForChild("BountyAction"):FireServer("Claim", bountyId)
			end
		end)

		player.AttributeChanged:Connect(function(attr)
			if string.match(attr, "^" .. bountyId) then UpdateCard() end
		end)
		UpdateCard()
	end

	CreateBountyCard("D1", "DAILY 1")
	CreateBountyCard("D2", "DAILY 2")
	CreateBountyCard("D3", "DAILY 3")
	CreateBountyCard("W1", "WEEKLY CHALLENGE")

	slLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, slLayout.AbsoluteContentSize.Y + 40)
	end)
end

return BountiesTab