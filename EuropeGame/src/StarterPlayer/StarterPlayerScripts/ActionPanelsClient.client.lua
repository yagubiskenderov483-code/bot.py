--[[
	ActionPanelsClient — панели: инфо о стране, рынок, исследования, объявление войны.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local CountryInfoUpdate = remotes:WaitForChild("CountryInfoUpdate")
local BuyFactory = remotes:WaitForChild("BuyFactory")
local TrainSoldiers = remotes:WaitForChild("TrainSoldiers")
local BuyResearch = remotes:WaitForChild("BuyResearch")
local DeclareWar = remotes:WaitForChild("DeclareWar")
local WarLogUpdate = remotes:WaitForChild("WarLogUpdate")
local CountryListUpdate = remotes:WaitForChild("CountryListUpdate")
local ClaimCountry = remotes:WaitForChild("ClaimCountry")
local RequestCountryInfo = remotes:WaitForChild("RequestCountryInfo")

local gui = Instance.new("ScreenGui")
gui.Name = "EuropeActions"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "CountryPanel"
panel.Size = UDim2.fromOffset(280, 360)
panel.Position = UDim2.new(0, 12, 0.5, -180)
panel.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -16, 0, 28)
title.Position = UDim2.fromOffset(8, 8)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(245, 245, 250)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Страна"
title.Parent = panel

local info = Instance.new("TextLabel")
info.Name = "Info"
info.BackgroundTransparency = 1
info.Size = UDim2.new(1, -16, 0, 120)
info.Position = UDim2.fromOffset(8, 40)
info.Font = Enum.Font.Gotham
info.TextSize = 14
info.TextColor3 = Color3.fromRGB(210, 215, 230)
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.Text = ""
info.Parent = panel

local function makeButton(name: string, text: string, y: number, color: Color3): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(1, -24, 0, 32)
	btn.Position = UDim2.fromOffset(12, y)
	btn.BackgroundColor3 = color
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 14
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Text = text
	btn.AutoButtonColor = true
	btn.Parent = panel
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = btn
	return btn
end

local claimBtn = makeButton("Claim", "Стать лидером", 170, Color3.fromRGB(40, 120, 80))
local factoryBtn = makeButton("Factory", "Купить фабрику", 208, Color3.fromRGB(50, 90, 160))
local trainBtn = makeButton("Train", "Нанять солдат (+5)", 246, Color3.fromRGB(120, 70, 40))
local researchBtn = makeButton("Research", "Исследование", 284, Color3.fromRGB(90, 50, 140))
local warBtn = makeButton("War", "Объявить войну", 322, Color3.fromRGB(160, 40, 40))

-- Лог войны
local logFrame = Instance.new("Frame")
logFrame.Name = "WarLog"
logFrame.Size = UDim2.fromOffset(320, 100)
logFrame.Position = UDim2.new(0.5, -160, 1, -120)
logFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
logFrame.BackgroundTransparency = 0.25
logFrame.BorderSizePixel = 0
logFrame.Parent = gui
local lc = Instance.new("UICorner")
lc.CornerRadius = UDim.new(0, 8)
lc.Parent = logFrame

local logTitle = Instance.new("TextLabel")
logTitle.BackgroundTransparency = 1
logTitle.Size = UDim2.new(1, -10, 0, 20)
logTitle.Position = UDim2.fromOffset(8, 4)
logTitle.Font = Enum.Font.GothamBold
logTitle.TextSize = 13
logTitle.TextColor3 = Color3.fromRGB(220, 180, 100)
logTitle.TextXAlignment = Enum.TextXAlignment.Left
logTitle.Text = "Военный журнал"
logTitle.Parent = logFrame

local logText = Instance.new("TextLabel")
logText.BackgroundTransparency = 1
logText.Size = UDim2.new(1, -12, 1, -28)
logText.Position = UDim2.fromOffset(8, 24)
logText.Font = Enum.Font.Gotham
logText.TextSize = 12
logText.TextColor3 = Color3.fromRGB(210, 215, 225)
logText.TextXAlignment = Enum.TextXAlignment.Left
logText.TextYAlignment = Enum.TextYAlignment.Top
logText.Text = ""
logText.TextWrapped = true
logText.Parent = logFrame

local logLines: { string } = {}
local selectedCountry: string? = nil
local myCountry: string? = nil
local lastSnap: any = nil

local function factoryPrice(factories: number): number
	return math.floor(120 * (1 + factories * 0.35))
end

local function researchPrice(level: number): number
	return math.floor(200 * (1 + level * 0.6))
end

local function refreshPanel(snap)
	lastSnap = snap
	selectedCountry = snap.Name
	panel.Visible = true
	title.Text = snap.Name
	local owner = snap.OwnerName or "свободна"
	local wars = snap.AtWarWith and #snap.AtWarWith > 0 and table.concat(snap.AtWarWith, ", ") or "нет"
	info.Text = table.concat({
		"Столица: " .. tostring(snap.Capital),
		"Владелец: " .. owner,
		("Деньги: %d"):format(snap.Money),
		("Фабрики: %d | Солдаты: %d"):format(snap.Factories, snap.Soldiers),
		("Население: %d"):format(snap.Population),
		("Исследования: ур.%d"):format(snap.ResearchLevel or 0),
		"Войны: " .. wars,
	}, "\n")

	local isMine = snap.OwnerName == player.Name
	local canClaim = snap.OwnerName == nil and myCountry == nil
	claimBtn.Visible = canClaim
	factoryBtn.Visible = isMine
	trainBtn.Visible = isMine
	researchBtn.Visible = isMine
	warBtn.Visible = isMine == false and myCountry ~= nil and snap.Name ~= myCountry

	if isMine then
		factoryBtn.Text = ("Купить фабрику (%d💰)"):format(factoryPrice(snap.Factories))
		researchBtn.Text = ("Исследование (%d💰)"):format(researchPrice(snap.ResearchLevel or 0))
	end
end

CountryInfoUpdate.OnClientEvent:Connect(function(snap)
	if typeof(snap) ~= "table" then
		return
	end
	if snap.OwnerName == player.Name then
		myCountry = snap.Name
	end
	if selectedCountry == snap.Name or snap.OwnerName == player.Name then
		refreshPanel(snap)
	end
end)

CountryListUpdate.OnClientEvent:Connect(function(_list)
	-- можно расширить список стран в UI позже
end)

WarLogUpdate.OnClientEvent:Connect(function(text)
	table.insert(logLines, 1, tostring(text))
	while #logLines > 5 do
		table.remove(logLines)
	end
	logText.Text = table.concat(logLines, "\n")
end)

claimBtn.MouseButton1Click:Connect(function()
	if selectedCountry then
		ClaimCountry:FireServer(selectedCountry)
	end
end)

factoryBtn.MouseButton1Click:Connect(function()
	BuyFactory:FireServer()
end)

trainBtn.MouseButton1Click:Connect(function()
	TrainSoldiers:FireServer()
end)

researchBtn.MouseButton1Click:Connect(function()
	BuyResearch:FireServer()
end)

warBtn.MouseButton1Click:Connect(function()
	if selectedCountry then
		DeclareWar:FireServer(selectedCountry)
	end
end)

-- Закрытие панели на Escape
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.Escape then
		panel.Visible = false
	end
end)

-- Подсказка
local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(1, 0, 0, 24)
hint.Position = UDim2.new(0, 0, 1, -28)
hint.Font = Enum.Font.Gotham
hint.TextSize = 13
hint.TextColor3 = Color3.fromRGB(200, 205, 220)
hint.Text = "Клик по стране — инфо / захват  |  Esc — закрыть панель"
hint.Parent = gui
