--[[
	TopBarClient — верхняя панель: деньги, фабрики, население, постройки/исследования, страна, дата.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local CountryInfoUpdate = remotes:WaitForChild("CountryInfoUpdate")
local DateUpdate = remotes:WaitForChild("DateUpdate")
local ShowBanner = remotes:WaitForChild("ShowBanner")
local LeaderboardUpdate = remotes:WaitForChild("LeaderboardUpdate")

local gui = Instance.new("ScreenGui")
gui.Name = "EuropeTopBar"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local bar = Instance.new("Frame")
bar.Name = "TopBar"
bar.Size = UDim2.new(1, 0, 0, 44)
bar.Position = UDim2.fromOffset(0, 0)
bar.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
bar.BackgroundTransparency = 0.15
bar.BorderSizePixel = 0
bar.Parent = gui

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.Parent = bar

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 16)
layout.Parent = bar

local function makeStat(name: string, defaultText: string): TextLabel
	local lbl = Instance.new("TextLabel")
	lbl.Name = name
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromOffset(140, 36)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 14
	lbl.TextColor3 = Color3.fromRGB(235, 240, 250)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = defaultText
	lbl.Parent = bar
	return lbl
end

local countryLbl = makeStat("Country", "Страна: —")
local moneyLbl = makeStat("Money", "💰 0")
local factoryLbl = makeStat("Factories", "🏭 0")
local popLbl = makeStat("Population", "👥 0")
local buildLbl = makeStat("Buildings", "🏗 0 | 🔬 0")
local dateLbl = makeStat("Date", "📅 —")
dateLbl.Size = UDim2.fromOffset(120, 36)

-- Флаг-цвет страны
local flag = Instance.new("Frame")
flag.Name = "Flag"
flag.Size = UDim2.fromOffset(22, 14)
flag.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
flag.BorderSizePixel = 0
flag.LayoutOrder = -1
flag.Parent = bar
local flagCorner = Instance.new("UICorner")
flagCorner.CornerRadius = UDim.new(0, 2)
flagCorner.Parent = flag
flag.Parent = nil
-- Вставить флаг первым
flag.Parent = bar
flag.LayoutOrder = -1
countryLbl.LayoutOrder = 0

-- Баннер войны
local banner = Instance.new("TextLabel")
banner.Name = "Banner"
banner.Size = UDim2.new(0.7, 0, 0, 36)
banner.Position = UDim2.new(0.15, 0, 0, 52)
banner.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
banner.BackgroundTransparency = 0.2
banner.Font = Enum.Font.GothamBold
banner.TextSize = 16
banner.TextColor3 = Color3.new(1, 1, 1)
banner.Visible = false
banner.Parent = gui
local bc = Instance.new("UICorner")
bc.CornerRadius = UDim.new(0, 6)
bc.Parent = banner

-- Лидерборд
local lb = Instance.new("Frame")
lb.Name = "Leaderboard"
lb.Size = UDim2.fromOffset(220, 180)
lb.Position = UDim2.new(1, -230, 0, 56)
lb.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
lb.BackgroundTransparency = 0.2
lb.BorderSizePixel = 0
lb.Parent = gui
local lbc = Instance.new("UICorner")
lbc.CornerRadius = UDim.new(0, 8)
lbc.Parent = lb

local lbTitle = Instance.new("TextLabel")
lbTitle.BackgroundTransparency = 1
lbTitle.Size = UDim2.new(1, -12, 0, 24)
lbTitle.Position = UDim2.fromOffset(8, 4)
lbTitle.Font = Enum.Font.GothamBold
lbTitle.TextSize = 14
lbTitle.TextColor3 = Color3.fromRGB(240, 220, 120)
lbTitle.TextXAlignment = Enum.TextXAlignment.Left
lbTitle.Text = "Лидерборд"
lbTitle.Parent = lb

local lbList = Instance.new("TextLabel")
lbList.BackgroundTransparency = 1
lbList.Size = UDim2.new(1, -12, 1, -32)
lbList.Position = UDim2.fromOffset(8, 28)
lbList.Font = Enum.Font.Gotham
lbList.TextSize = 13
lbList.TextColor3 = Color3.fromRGB(220, 225, 235)
lbList.TextXAlignment = Enum.TextXAlignment.Left
lbList.TextYAlignment = Enum.TextYAlignment.Top
lbList.Text = "—"
lbList.Parent = lb

local myCountry: string? = nil

local function fmtPop(n: number): string
	if n >= 1000000 then
		return string.format("%.1f млн", n / 1000000)
	end
	return tostring(math.floor(n))
end

CountryInfoUpdate.OnClientEvent:Connect(function(snap)
	if typeof(snap) ~= "table" then
		return
	end
	-- Обновляем топ-бар только для своей страны
	if snap.OwnerName == player.Name then
		myCountry = snap.Name
		countryLbl.Text = "Страна: " .. snap.Name
		moneyLbl.Text = "💰 " .. tostring(snap.Money)
		factoryLbl.Text = "🏭 " .. tostring(snap.Factories)
		popLbl.Text = "👥 " .. fmtPop(snap.Population)
		buildLbl.Text = ("🏗 %d | 🔬 %d"):format(snap.Buildings or 0, snap.ResearchLevel or 0)
		if snap.Color then
			flag.BackgroundColor3 = Color3.new(snap.Color[1], snap.Color[2], snap.Color[3])
		end
	end
end)

DateUpdate.OnClientEvent:Connect(function(dateStr)
	dateLbl.Text = "📅 " .. tostring(dateStr)
end)

ShowBanner.OnClientEvent:Connect(function(text)
	banner.Text = "  " .. tostring(text)
	banner.Visible = true
	task.delay(4, function()
		if banner.Text == "  " .. tostring(text) then
			banner.Visible = false
		end
	end)
end)

LeaderboardUpdate.OnClientEvent:Connect(function(rows)
	if typeof(rows) ~= "table" then
		return
	end
	local lines = {}
	for i, row in ipairs(rows) do
		table.insert(lines, ("%d. %s (%s) — %d"):format(i, row.Player, row.Country, row.Score))
	end
	lbList.Text = #lines > 0 and table.concat(lines, "\n") or "Нет лидеров"
end)
