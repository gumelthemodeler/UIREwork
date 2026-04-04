-- @ScriptType: ModuleScript
-- Name: RegimentsTab
local RegimentsTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local UIHelpers = require(script.Parent:WaitForChild("UIHelpers"))
local RegimentData = require(ReplicatedStorage:WaitForChild("RegimentData"))

local player = Players.LocalPlayer

local REG_COLORS = {
	["Garrison"] = "#FF5555",
	["Military Police"] = "#55FF55",
	["Scout Regiment"] = "#55AAFF"
}

local SWAP_COST = 50000

-- [[ THE FIX: Re-added the missing FormatNumber function! ]]
local function FormatNumber(n)
	if not n then return "0" end
	n = tostring(n)
	return n:reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

local function CreateGrimPanel(parent)
	local frame = Instance.new("Frame", parent)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	frame.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(70, 70, 80)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return frame, stroke
end

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

	btn.MouseEnter:Connect(function() 
		if btn.Active then
			stroke.Color = Color3.fromRGB(225, 185, 60)
			btn.TextColor3 = Color3.fromRGB(225, 185, 60) 
		end
	end)
	btn.MouseLeave:Connect(function() 
		if btn.Active then
			stroke.Color = btn:GetAttribute("OrigStroke") or Color3.fromRGB(70, 70, 80)
			btn.TextColor3 = btn:GetAttribute("OrigColor") or Color3.fromRGB(245, 245, 245)
		end
	end)
	return btn, stroke
end

function RegimentsTab.Initialize(parentFrame)
	for _, child in ipairs(parentFrame:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end

	local HeaderFrame = Instance.new("Frame", parentFrame)
	HeaderFrame.Size = UDim2.new(1, 0, 0, 60)
	HeaderFrame.BackgroundTransparency = 1

	local Title = UIHelpers.CreateLabel(HeaderFrame, "REGIMENT HEADQUARTERS", UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, UIHelpers.Colors.Gold, 24)
	Title.Position = UDim2.new(0, 0, 0, 0)
	Title.TextXAlignment = Enum.TextXAlignment.Center

	local Subtitle = UIHelpers.CreateLabel(HeaderFrame, "Pledge your allegiance to a military branch for global passive buffs.", UDim2.new(1, 0, 0, 20), Enum.Font.GothamMedium, UIHelpers.Colors.TextMuted, 14)
	Subtitle.Position = UDim2.new(0, 0, 0, 35)
	Subtitle.TextXAlignment = Enum.TextXAlignment.Center

	local CardContainer = Instance.new("Frame", parentFrame)
	CardContainer.Size = UDim2.new(1, 0, 1, -80)
	CardContainer.Position = UDim2.new(0, 0, 0, 80)
	CardContainer.BackgroundTransparency = 1

	local listLayout = Instance.new("UIListLayout", CardContainer)
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.Padding = UDim.new(0, 30)

	local function CreateRegimentCard(name, desc)
		local dataReg = RegimentData.Regiments[name]
		if not dataReg then return end

		local colorHex = REG_COLORS[name] or "#FFFFFF"
		local regColor = Color3.fromHex(colorHex:gsub("#",""))

		local card, cardStroke = CreateGrimPanel(CardContainer)
		card.Size = UDim2.new(0.3, 0, 0, 420)

		local icon = Instance.new("ImageLabel", card)
		icon.Size = UDim2.new(0, 150, 0, 150)
		icon.Position = UDim2.new(0.5, 0, 0, 30)
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.BackgroundTransparency = 1
		icon.Image = dataReg.Icon
		icon.ScaleType = Enum.ScaleType.Fit

		local nameLbl = UIHelpers.CreateLabel(card, string.upper(name), UDim2.new(1, 0, 0, 30), Enum.Font.GothamBlack, regColor, 20)
		nameLbl.Position = UDim2.new(0, 0, 0, 190)

		local descLbl = UIHelpers.CreateLabel(card, desc, UDim2.new(1, -30, 0, 50), Enum.Font.GothamMedium, UIHelpers.Colors.TextWhite, 13)
		descLbl.Position = UDim2.new(0, 15, 0, 230)
		descLbl.TextWrapped = true
		descLbl.TextYAlignment = Enum.TextYAlignment.Top

		local buffBox = Instance.new("Frame", card)
		buffBox.Size = UDim2.new(0.8, 0, 0, 40)
		buffBox.Position = UDim2.new(0.5, 0, 0, 290)
		buffBox.AnchorPoint = Vector2.new(0.5, 0)
		buffBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
		local bbStroke = Instance.new("UIStroke", buffBox); bbStroke.Color = Color3.fromRGB(50, 50, 60)

		local buffLbl = UIHelpers.CreateLabel(buffBox, dataReg.Buff, UDim2.new(1, 0, 1, 0), Enum.Font.GothamBold, Color3.fromRGB(100, 255, 100), 12)

		local PldBtn, pStrk = CreateSharpButton(card, "", UDim2.new(0.8, 0, 0, 45), Enum.Font.GothamBlack, 14)
		PldBtn.Position = UDim2.new(0.5, 0, 1, -25)
		PldBtn.AnchorPoint = Vector2.new(0.5, 1)

		local function UpdateBtn()
			local currentReg = player:GetAttribute("Regiment") or "Cadet Corps"

			if currentReg == name then
				PldBtn.Text = "PLEDGED"
				PldBtn.TextColor3 = regColor
				pStrk.Color = regColor
				PldBtn:SetAttribute("OrigColor", regColor)
				PldBtn:SetAttribute("OrigStroke", regColor)
				PldBtn.Active = false
			elseif currentReg == "Cadet Corps" then
				PldBtn.Text = "JOIN (FREE)"
				PldBtn.TextColor3 = UIHelpers.Colors.TextWhite
				pStrk.Color = Color3.fromRGB(70, 70, 80)
				PldBtn:SetAttribute("OrigColor", UIHelpers.Colors.TextWhite)
				PldBtn:SetAttribute("OrigStroke", Color3.fromRGB(70, 70, 80))
				PldBtn.Active = true
			else
				PldBtn.Text = "SWAP (" .. FormatNumber(SWAP_COST) .. " DEWS)"
				PldBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
				pStrk.Color = Color3.fromRGB(100, 50, 50)
				PldBtn:SetAttribute("OrigColor", Color3.fromRGB(255, 100, 100))
				PldBtn:SetAttribute("OrigStroke", Color3.fromRGB(100, 50, 50))
				PldBtn.Active = true
			end
		end

		player.AttributeChanged:Connect(function(attr) if attr == "Regiment" then UpdateBtn() end end)
		UpdateBtn()

		PldBtn.MouseButton1Click:Connect(function()
			if not PldBtn.Active then return end
			Network:WaitForChild("JoinRegiment"):FireServer(name)
		end)
	end

	CreateRegimentCard("Garrison", "The defenders of the walls, maintaining order and fortifying humanity's last stronghold.")
	CreateRegimentCard("Scout Regiment", "The vanguard of humanity's expansion, seeking freedom outside the walls.")
	CreateRegimentCard("Military Police", "The royal guard maintaining inner peace and protecting the king.")
end

return RegimentsTab