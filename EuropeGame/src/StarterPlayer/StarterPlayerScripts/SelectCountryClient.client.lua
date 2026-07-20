--[[
	SelectCountryClient — стартовый экран выбора страны.
	Показывает список свободных стран, игрок выбирает одну.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local CountryListUpdate = remotes:WaitForChild("CountryListUpdate")
local CountryInfoUpdate = remotes:WaitForChild("CountryInfoUpdate")
local ClaimCountry = remotes:WaitForChild("ClaimCountry")

local gui = Instance.new("ScreenGui")
gui.Name = "EuropeSelect"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 50
gui.Parent = player:WaitForChild("PlayerGui")

local dim = Instance.new("Frame")
dim.Size = UDim2.fromScale(1, 1)
dim.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
dim.BackgroundTransparency = 0.25
dim.BorderSizePixel = 0
dim.Parent = gui

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(560, 460)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
panel.BorderSizePixel = 0
panel.Parent = dim
local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(0, 14)
pc.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -24, 0, 44)
title.Position = UDim2.fromOffset(12, 10)
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextColor3 = Color3.fromRGB(245, 245, 250)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Выбери свою страну"
title.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Size = UDim2.new(1, -24, 0, 22)
subtitle.Position = UDim2.fromOffset(12, 52)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.TextColor3 = Color3.fromRGB(170, 180, 200)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "Захвати мир, начав с одной страны"
subtitle.Parent = panel

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -24, 1, -90)
scroll.Position = UDim2.fromOffset(12, 82)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(168, 52)
grid.CellPadding = UDim2.fromOffset(8, 8)
grid.SortOrder = Enum.SortOrder.Name
grid.Parent = scroll

local chosen = false

local function makeCard(snap)
	local btn = Instance.new("TextButton")
	btn.Name = snap.Name
	btn.BackgroundColor3 = Color3.fromRGB(32, 38, 54)
	btn.AutoButtonColor = true
	btn.Text = ""
	btn.Parent = scroll
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = btn

	local flag = Instance.new("Frame")
	flag.Size = UDim2.fromOffset(26, 18)
	flag.Position = UDim2.fromOffset(8, 8)
	flag.BorderSizePixel = 0
	if snap.Color then
		flag.BackgroundColor3 = Color3.new(snap.Color[1], snap.Color[2], snap.Color[3])
	end
	flag.Parent = btn
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0, 3)
	fc.Parent = flag

	local nameLbl = Instance.new("TextLabel")
	nameLbl.BackgroundTransparency = 1
	nameLbl.Size = UDim2.new(1, -44, 0, 20)
	nameLbl.Position = UDim2.fromOffset(40, 6)
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 14
	nameLbl.TextColor3 = Color3.fromRGB(240, 240, 245)
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Text = snap.Name
	nameLbl.Parent = btn

	local info = Instance.new("TextLabel")
	info.BackgroundTransparency = 1
	info.Size = UDim2.new(1, -44, 0, 16)
	info.Position = UDim2.fromOffset(40, 28)
	info.Font = Enum.Font.Gotham
	info.TextSize = 11
	info.TextColor3 = Color3.fromRGB(160, 170, 190)
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.Text = ("🪖 %d  🏭 %d"):format(snap.Soldiers or 0, snap.Factories or 0)
	info.Parent = btn

	btn.MouseButton1Click:Connect(function()
		if chosen then
			return
		end
		chosen = true
		ClaimCountry:FireServer(snap.Name)
	end)
end

local function rebuild(list)
	if chosen then
		return
	end
	for _, ch in ipairs(scroll:GetChildren()) do
		if ch:IsA("TextButton") then
			ch:Destroy()
		end
	end
	for _, snap in ipairs(list) do
		if not snap.OwnerName then
			makeCard(snap)
		end
	end
end

CountryListUpdate.OnClientEvent:Connect(rebuild)

-- Когда игрок стал владельцем — прячем экран
CountryInfoUpdate.OnClientEvent:Connect(function(snap)
	if typeof(snap) == "table" and snap.OwnerName == player.Name then
		chosen = true
		gui.Enabled = false
	end
end)
