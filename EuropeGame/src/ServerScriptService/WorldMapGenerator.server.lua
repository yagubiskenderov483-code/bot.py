--[[
	WorldMapGenerator — строит EuropeMap из EuropeGrid + EuropeCountries.
	Вода = фон Ocean; страны = стыкующиеся тайлы; города/столицы = маркеры.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Ждём Bootstrap
local worldReady = ReplicatedStorage:WaitForChild("WorldReady", 30)
local Modules = ReplicatedStorage:WaitForChild("Modules")
local EuropeCountries = require(Modules:WaitForChild("EuropeCountries"))
local EuropeGrid = require(Modules:WaitForChild("EuropeGrid"))
local CountryState = require(script.Parent:WaitForChild("CountryState"))

local function ensureFolder(parent: Instance, name: string): Folder
	local f = parent:FindFirstChild(name)
	if f and f:IsA("Folder") then
		return f
	end
	if f then
		f:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function clearChildren(folder: Folder)
	for _, ch in ipairs(folder:GetChildren()) do
		ch:Destroy()
	end
end

CountryState.Init()

local europeMap = ensureFolder(Workspace, "EuropeMap")
local countriesFolder = ensureFolder(europeMap, "Countries")
local citiesFolder = ensureFolder(europeMap, "Cities")
local terrainFolder = ensureFolder(europeMap, "Terrain")
local unitsFolder = ensureFolder(europeMap, "Units")
clearChildren(countriesFolder)
clearChildren(citiesFolder)
clearChildren(terrainFolder)
clearChildren(unitsFolder)

local cellSize = EuropeGrid.CellSize
local cols, rows = EuropeGrid.Cols, EuropeGrid.Rows

-- Океан — единый фон
local ocean = Instance.new("Part")
ocean.Name = "Ocean"
ocean.Anchored = true
ocean.CanCollide = true
ocean.Material = Enum.Material.SmoothPlastic
ocean.Color = Color3.fromRGB(25, 70, 130)
ocean.Size = Vector3.new(cols * cellSize + 40, 1, rows * cellSize + 40)
ocean.Position = Vector3.new(0, -0.6, 0)
ocean.Parent = terrainFolder

-- Группируем клетки по стране
local byCountry: { [string]: { { number, number } } } = {}
for _, cell in ipairs(EuropeGrid.Cells) do
	local c, r, name = cell[1], cell[2], cell[3]
	byCountry[name] = byCountry[name] or {}
	table.insert(byCountry[name], { c, r })
end

local countryModels: { [string]: Model } = {}
local tileLookup: { [string]: Part } = {} -- "Country:c,r"

for name, cells in pairs(byCountry) do
	local data = EuropeCountries.Get(name)
	local color = data and data.Color or Color3.fromRGB(120, 120, 120)

	local model = Instance.new("Model")
	model.Name = name
	model.Parent = countriesFolder
	countryModels[name] = model

	for _, cr in ipairs(cells) do
		local col, row = cr[1], cr[2]
		local part = Instance.new("Part")
		part.Name = ("T_%d_%d"):format(col, row)
		part.Anchored = true
		part.CanCollide = true
		part.Material = Enum.Material.SmoothPlastic
		part.Color = color
		-- Без зазоров: размер = CellSize, стык встык
		part.Size = Vector3.new(cellSize, 1.2, cellSize)
		local pos = EuropeGrid.CellToWorld(col, row)
		part.Position = Vector3.new(pos.X, 0.1, pos.Z)
		part:SetAttribute("Country", name)
		part:SetAttribute("Col", col)
		part:SetAttribute("Row", row)
		part.Parent = model
		tileLookup[name .. ":" .. col .. "," .. row] = part

		-- ClickDetector для выбора страны
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 500
		cd.Parent = part
	end
end

-- Маркеры городов
local capitalSet: { [string]: boolean } = {}
for _, c in ipairs(EuropeCountries.All()) do
	capitalSet[c.Capital] = true
end

local function makeLabel(adornee: BasePart, text: string, maxDist: number, textSize: number, color: Color3?)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Label"
	bb.Adornee = adornee
	bb.Size = UDim2.fromOffset(170, 28)
	bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = maxDist
	bb.Parent = adornee

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = textSize
	lbl.TextColor3 = color or Color3.new(1, 1, 1)
	lbl.TextStrokeTransparency = 0.3
	lbl.Text = text
	lbl.Parent = bb
end

-- Плоская 5-конечная звезда из тонких брусков (вровень с землёй)
local function makeStar(pos: Vector3, color: Color3): Model
	local star = Instance.new("Model")
	star.Name = "Star"
	local center = Instance.new("Part")
	center.Anchored = true
	center.CanCollide = false
	center.Material = Enum.Material.Neon
	center.Color = color
	center.Shape = Enum.PartType.Cylinder
	center.Size = Vector3.new(0.3, 1.6, 1.6)
	center.CFrame = CFrame.new(pos.X, 0.7, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
	center.Parent = star
	for i = 0, 4 do
		local ray = Instance.new("Part")
		ray.Anchored = true
		ray.CanCollide = false
		ray.Material = Enum.Material.Neon
		ray.Color = color
		ray.Size = Vector3.new(2.6, 0.3, 0.7)
		local ang = math.rad(i * 72 - 90)
		ray.CFrame = CFrame.new(pos.X, 0.7, pos.Z)
			* CFrame.Angles(0, ang, 0)
			* CFrame.new(1.2, 0, 0)
		ray.Parent = star
	end
	star.PrimaryPart = center
	return star
end

for cityName, cell in pairs(EuropeGrid.CityCells) do
	local col, row = cell[1], cell[2]
	local pos = EuropeGrid.CellToWorld(col, row)
	local isCapital = capitalSet[cityName] == true

	if isCapital then
		-- Жёлтая звезда (настоящая, 5 лучей) вровень с землёй
		local star = makeStar(pos, Color3.fromRGB(255, 214, 40))
		star.Name = cityName
		if star.PrimaryPart then
			star.PrimaryPart:SetAttribute("IsCapital", true)
			star.PrimaryPart:SetAttribute("City", cityName)
			makeLabel(star.PrimaryPart, "★ " .. cityName, 160, 16, Color3.fromRGB(255, 226, 120))
		end
		star.Parent = citiesFolder
	else
		-- Плоский круглый диск вровень с землёй
		local marker = Instance.new("Part")
		marker.Name = cityName
		marker.Anchored = true
		marker.CanCollide = false
		marker.Material = Enum.Material.SmoothPlastic
		marker.Shape = Enum.PartType.Cylinder
		marker.Size = Vector3.new(0.25, 2.0, 2.0)
		marker.Color = Color3.fromRGB(235, 235, 240)
		marker.CFrame = CFrame.new(pos.X, 0.72, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
		marker:SetAttribute("IsCapital", false)
		marker:SetAttribute("City", cityName)
		makeLabel(marker, cityName, 70, 13)
		marker.Parent = citiesFolder
	end
end

-- SpawnLocation на суше (Париж / Франция)
local spawnCol, spawnRow = EuropeGrid.GetFirstLandCell()
local spawnPos = EuropeGrid.CellToWorld(spawnCol, spawnRow)

local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
if not spawn then
	spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Parent = Workspace
end
spawn.Anchored = true
spawn.Duration = 0
spawn.Neutral = true
spawn.Size = Vector3.new(6, 1, 6)
spawn.Position = Vector3.new(spawnPos.X, 2, spawnPos.Z)
spawn.BrickColor = BrickColor.new("Bright green")
spawn.Transparency = 0.3

-- API для перекраски при захвате
local MapAPI = {}

function MapAPI.RecolorCountry(countryName: string, color: Color3)
	local model = countriesFolder:FindFirstChild(countryName)
	if not model then
		return
	end
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") then
			part.Color = color
		end
	end
end

function MapAPI.TransferTiles(fromCountry: string, toCountry: string, color: Color3)
	local fromModel = countriesFolder:FindFirstChild(fromCountry)
	local toModel = countriesFolder:FindFirstChild(toCountry)
	if not fromModel or not toModel then
		return
	end
	for _, part in ipairs(fromModel:GetChildren()) do
		if part:IsA("BasePart") then
			part.Color = color
			part:SetAttribute("Country", toCountry)
			part.Parent = toModel
		end
	end
end

function MapAPI.GetCapitalWorldPos(countryName: string): Vector3?
	local st = CountryState.Get(countryName)
	if not st then
		return nil
	end
	local cell = EuropeGrid.CityCells[st.Capital]
	if not cell then
		return nil
	end
	local p = EuropeGrid.CellToWorld(cell[1], cell[2])
	return Vector3.new(p.X, 3, p.Z)
end

function MapAPI.GetUnitsFolder(): Folder
	return unitsFolder
end

function MapAPI.GetCountriesFolder(): Folder
	return countriesFolder
end

-- Заводы: маленькие здания вокруг столицы
local factoriesFolder = ensureFolder(europeMap, "Factories")
clearChildren(factoriesFolder)
local factoryCounts: { [string]: number } = {}

function MapAPI.AddFactory(countryName: string)
	local st = CountryState.Get(countryName)
	if not st then
		return
	end
	local cell = EuropeGrid.CityCells[st.Capital]
	if not cell then
		return
	end
	local base = EuropeGrid.CellToWorld(cell[1], cell[2])
	local n = (factoryCounts[countryName] or 0)
	factoryCounts[countryName] = n + 1

	-- расставляем заводы по спирали вокруг столицы
	local ring = math.floor(n / 8) + 1
	local idx = n % 8
	local ang = math.rad(idx * 45)
	local dist = 2.5 * ring
	local fx = base.X + math.cos(ang) * dist
	local fz = base.Z + math.sin(ang) * dist

	local b = Instance.new("Part")
	b.Name = "Factory_" .. countryName .. "_" .. n
	b.Anchored = true
	b.CanCollide = false
	b.Material = Enum.Material.Metal
	b.Color = Color3.fromRGB(90, 90, 100)
	b.Size = Vector3.new(1.6, 1.8, 1.6)
	b.Position = Vector3.new(fx, 1.0, fz)
	b.Parent = factoriesFolder

	local roof = Instance.new("Part")
	roof.Anchored = true
	roof.CanCollide = false
	roof.Material = Enum.Material.Metal
	roof.Color = Color3.fromRGB(140, 60, 40)
	roof.Size = Vector3.new(1.7, 0.4, 1.7)
	roof.Position = Vector3.new(fx, 2.0, fz)
	roof.Parent = factoriesFolder
end

function MapAPI.RenderInitialFactories()
	for name, st in pairs(CountryState.All()) do
		local count = st.Factories or 0
		for _ = 1, count do
			MapAPI.AddFactory(name)
		end
	end
end

_G.EuropeMapAPI = MapAPI
MapAPI.RenderInitialFactories()

if worldReady and worldReady:IsA("BoolValue") then
	worldReady.Value = true
end

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local mapReady = remotes and remotes:FindFirstChild("MapReady")

-- Загрузка персонажей после карты
local function loadPlayer(player: Player)
	task.defer(function()
		if not player.Parent then
			return
		end
		player:LoadCharacter()
	end)
end

Players.PlayerAdded:Connect(function(player)
	if worldReady and worldReady.Value then
		loadPlayer(player)
		if mapReady then
			mapReady:FireClient(player)
		end
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	loadPlayer(player)
	if mapReady then
		mapReady:FireClient(player)
	end
end

print("[Europe] Карта построена. Стран:", #EuropeCountries.All(), "клеток:", #EuropeGrid.Cells)
