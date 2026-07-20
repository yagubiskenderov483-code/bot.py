--[[
	WarAndEconomyServer — экономика, исследования, войны, лидерборд, дата.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local worldReady = ReplicatedStorage:WaitForChild("WorldReady")
while not worldReady.Value do
	worldReady.Changed:Wait()
end

local CountryState = require(script.Parent:WaitForChild("CountryState"))

local function remote(name: string): RemoteEvent
	local r = remotesFolder:WaitForChild(name)
	assert(r:IsA("RemoteEvent"))
	return r
end

local RequestCountryInfo = remote("RequestCountryInfo")
local CountryInfoUpdate = remote("CountryInfoUpdate")
local DateUpdate = remote("DateUpdate")
local BuyFactory = remote("BuyFactory")
local TrainSoldiers = remote("TrainSoldiers")
local BuyResearch = remote("BuyResearch")
local DeclareWar = remote("DeclareWar")
local WarLogUpdate = remote("WarLogUpdate")
local LeaderboardUpdate = remote("LeaderboardUpdate")
local CountryListUpdate = remote("CountryListUpdate")
local ClaimCountry = remote("ClaimCountry")
local ShowBanner = remote("ShowBanner")

-- Игровая дата
local year, month, day = 1936, 1, 1
local FACTORY_BASE = 120
local SOLDIER_COST = 15
local SOLDIERS_PER_TRAIN = 5
local RESEARCH_BASE = 200
local JUSTIFY_SEC = 25
local WAR_TICK_SEC = 6
local LEADERBOARD_SEC = 8
local INCOME_SEC = 4

local activeWars: {
	[string]: {
		attacker: string,
		defender: string,
		progress: number, -- 0..1, 1 = у столицы цели
		marker: BasePart?,
		phase: string, -- "justify" | "war"
		justifyEnds: number,
	}
} = {}

local function broadcastBanner(text: string)
	ShowBanner:FireAllClients(text)
	WarLogUpdate:FireAllClients(text)
end

local function pushCountry(player: Player?, countryName: string)
	local snap = CountryState.Snapshot(countryName)
	if not snap then
		return
	end
	if player then
		CountryInfoUpdate:FireClient(player, snap)
	else
		CountryInfoUpdate:FireAllClients(snap)
	end
end

local function pushPlayerOwn(player: Player)
	local name = CountryState.GetPlayerCountry(player)
	if name then
		pushCountry(player, name)
	end
end

local function factoryPrice(st): number
	return math.floor(FACTORY_BASE * (1 + st.Factories * 0.35))
end

local function researchPrice(st): number
	return math.floor(RESEARCH_BASE * (1 + st.ResearchLevel * 0.6))
end

local function incomePerTick(st): number
	local researchBonus = 1 + st.ResearchLevel * 0.1
	return (30 + st.Factories * 18 + st.Population / 3000000) * researchBonus
end

local function armyPower(st): number
	local researchBonus = 1 + st.ResearchLevel * 0.1
	local jitter = 0.85 + math.random() * 0.3
	return st.Soldiers * researchBonus * jitter
end

local function ensureMapAPI()
	return _G.EuropeMapAPI
end

local function createArmyMarker(attackerName: string, fromPos: Vector3, color: Color3): BasePart
	local units = ensureMapAPI() and ensureMapAPI().GetUnitsFolder()
	local ball = Instance.new("Part")
	ball.Name = "Army_" .. attackerName
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(4, 4, 4)
	ball.Anchored = true
	ball.CanCollide = false
	ball.Material = Enum.Material.Neon
	ball.Color = color
	ball.Position = fromPos
	ball.Parent = units

	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 18
	light.Color = color
	light.Parent = ball

	return ball
end

local function annexCountry(attackerName: string, defenderName: string)
	local atk = CountryState.Get(attackerName)
	local def = CountryState.Get(defenderName)
	if not atk or not def then
		return
	end

	-- Экономика присоединяется
	atk.Money += def.Money * 0.5
	atk.Population += def.Population
	atk.Factories += math.max(1, math.floor(def.Factories * 0.5))
	atk.Soldiers += math.floor(def.Soldiers * 0.4)
	atk.Buildings += def.Buildings

	-- Тайлы → цвет атакующего
	local api = ensureMapAPI()
	if api then
		api.TransferTiles(defenderName, attackerName, atk.Color)
		api.RecolorCountry(attackerName, atk.Color)
	end

	-- Побеждённая страна сбрасывается (снова свободна)
	local oldOwner = def.Owner
	def.Owner = nil
	def.Money = 200
	def.Factories = 1
	def.Soldiers = 10
	def.Population = math.max(500000, math.floor(def.Population * 0.15))
	def.ResearchLevel = 0
	def.Buildings = 0
	def.AtWarWith = {}
	def.WarTarget = nil
	def.JustificationUntil = 0

	if oldOwner then
		-- владелец проигравшей теряет страну
		CountryState.ClearPlayer(oldOwner)
	end

	atk.AtWarWith[defenderName] = nil
	atk.WarTarget = nil

	broadcastBanner(("%s захватила %s!"):format(attackerName, defenderName))
	CountryListUpdate:FireAllClients(CountryState.ListSnapshot())
	for _, p in ipairs(Players:GetPlayers()) do
		pushPlayerOwn(p)
	end
end

local function endWar(key: string)
	local war = activeWars[key]
	if not war then
		return
	end
	if war.marker then
		war.marker:Destroy()
	end
	local atk = CountryState.Get(war.attacker)
	local def = CountryState.Get(war.defender)
	if atk then
		atk.AtWarWith[war.defender] = nil
		atk.WarTarget = nil
	end
	if def then
		def.AtWarWith[war.attacker] = nil
	end
	activeWars[key] = nil
end

-- === Remotes ===

RequestCountryInfo.OnServerEvent:Connect(function(player, countryName)
	if typeof(countryName) ~= "string" then
		return
	end
	pushCountry(player, countryName)
end)

ClaimCountry.OnServerEvent:Connect(function(player, countryName)
	if typeof(countryName) ~= "string" then
		return
	end
	local st = CountryState.Get(countryName)
	if not st then
		return
	end
	-- Уже владеет?
	if CountryState.GetPlayerCountry(player) then
		pushCountry(player, countryName)
		return
	end
	if st.Owner then
		pushCountry(player, countryName)
		return
	end
	if CountryState.SetOwner(countryName, player) then
		broadcastBanner(("%s стал лидером %s"):format(player.Name, countryName))
		pushCountry(player, countryName)
		CountryListUpdate:FireAllClients(CountryState.ListSnapshot())
	end
end)

BuyFactory.OnServerEvent:Connect(function(player)
	local name = CountryState.GetPlayerCountry(player)
	if not name then
		return
	end
	local st = CountryState.Get(name)
	local price = factoryPrice(st)
	if st.Money < price then
		return
	end
	st.Money -= price
	st.Factories += 1
	st.Buildings += 1
	local api = ensureMapAPI()
	if api and api.AddFactory then
		api.AddFactory(name)
	end
	pushPlayerOwn(player)
end)

TrainSoldiers.OnServerEvent:Connect(function(player)
	local name = CountryState.GetPlayerCountry(player)
	if not name then
		return
	end
	local st = CountryState.Get(name)
	local cost = SOLDIER_COST * SOLDIERS_PER_TRAIN
	if st.Money < cost then
		return
	end
	st.Money -= cost
	st.Soldiers += SOLDIERS_PER_TRAIN
	pushPlayerOwn(player)
end)

BuyResearch.OnServerEvent:Connect(function(player)
	local name = CountryState.GetPlayerCountry(player)
	if not name then
		return
	end
	local st = CountryState.Get(name)
	local price = researchPrice(st)
	if st.Money < price then
		return
	end
	st.Money -= price
	st.ResearchLevel += 1
	pushPlayerOwn(player)
end)

DeclareWar.OnServerEvent:Connect(function(player, targetName)
	if typeof(targetName) ~= "string" then
		return
	end
	local atkName = CountryState.GetPlayerCountry(player)
	if not atkName or atkName == targetName then
		return
	end
	local atk = CountryState.Get(atkName)
	local def = CountryState.Get(targetName)
	if not atk or not def then
		return
	end
	if atk.WarTarget or atk.AtWarWith[targetName] then
		return
	end
	-- Нельзя объявить войну стране без владельца? — можно (NPC)
	local key = atkName .. ">" .. targetName
	if activeWars[key] then
		return
	end

	atk.AtWarWith[targetName] = true
	def.AtWarWith[atkName] = true
	atk.WarTarget = targetName
	atk.JustificationUntil = os.clock() + JUSTIFY_SEC

	local api = ensureMapAPI()
	local fromPos = api and api.GetCapitalWorldPos(atkName) or Vector3.new(0, 3, 0)

	activeWars[key] = {
		attacker = atkName,
		defender = targetName,
		progress = 0,
		marker = nil,
		phase = "justify",
		justifyEnds = os.clock() + JUSTIFY_SEC,
	}

	broadcastBanner(("%s начала обоснование войны против %s"):format(atkName, targetName))
	pushPlayerOwn(player)
	CountryListUpdate:FireAllClients(CountryState.ListSnapshot())
end)

-- Клик по тайлу страны
task.defer(function()
	local api = ensureMapAPI()
	while not api do
		task.wait(0.5)
		api = ensureMapAPI()
	end
	local folder = api.GetCountriesFolder()
	for _, model in ipairs(folder:GetChildren()) do
		for _, part in ipairs(model:GetChildren()) do
			if part:IsA("BasePart") then
				local cd = part:FindFirstChildOfClass("ClickDetector")
				if cd then
					cd.MouseClick:Connect(function(player)
						local countryName = part:GetAttribute("Country")
						if typeof(countryName) ~= "string" then
							return
						end
						local st = CountryState.Get(countryName)
						if not st then
							return
						end
						-- Первый клик = захват, если свободна и игрок без страны
						if not CountryState.GetPlayerCountry(player) and not st.Owner then
							if CountryState.SetOwner(countryName, player) then
								broadcastBanner(("%s стал лидером %s"):format(player.Name, countryName))
								CountryListUpdate:FireAllClients(CountryState.ListSnapshot())
							end
						end
						pushCountry(player, countryName)
					end)
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	CountryState.ClearPlayer(player)
	CountryListUpdate:FireAllClients(CountryState.ListSnapshot())
end)

-- === Loops ===

-- Доход
task.spawn(function()
	while true do
		task.wait(INCOME_SEC)
		for _, st in pairs(CountryState.All()) do
			if st.Owner then
				st.Money += incomePerTick(st)
				st.Population += st.Factories * 50
			end
		end
		for _, p in ipairs(Players:GetPlayers()) do
			pushPlayerOwn(p)
		end
	end
end)

-- Дата
task.spawn(function()
	while true do
		task.wait(2)
		day += 1
		if day > 30 then
			day = 1
			month += 1
		end
		if month > 12 then
			month = 1
			year += 1
		end
		DateUpdate:FireAllClients(("%d.%02d.%d"):format(day, month, year))
	end
end)

-- Лидерборд
task.spawn(function()
	while true do
		task.wait(LEADERBOARD_SEC)
		local rows = {}
		for _, st in pairs(CountryState.All()) do
			if st.Owner then
				table.insert(rows, {
					Player = st.Owner.Name,
					Country = st.Name,
					Score = math.floor(CountryState.Score(st)),
				})
			end
		end
		table.sort(rows, function(a, b)
			return a.Score > b.Score
		end)
		local top = {}
		for i = 1, math.min(10, #rows) do
			top[i] = rows[i]
		end
		LeaderboardUpdate:FireAllClients(top)
	end
end)

-- Войны
task.spawn(function()
	while true do
		task.wait(1)
		local now = os.clock()
		for key, war in pairs(activeWars) do
			local atk = CountryState.Get(war.attacker)
			local def = CountryState.Get(war.defender)
			if not atk or not def then
				endWar(key)
				continue
			end

			if war.phase == "justify" then
				if now >= war.justifyEnds then
					war.phase = "war"
					local api = ensureMapAPI()
					local fromPos = api and api.GetCapitalWorldPos(war.attacker) or Vector3.new(0, 3, 0)
					war.marker = createArmyMarker(war.attacker, fromPos, atk.Color)
					broadcastBanner(("%s объявила войну %s!"):format(war.attacker, war.defender))
					war._nextTick = now + WAR_TICK_SEC
				end
			elseif war.phase == "war" then
				if not war._nextTick or now >= war._nextTick then
					war._nextTick = now + WAR_TICK_SEC
					local ap = armyPower(atk)
					local dp = armyPower(def)
					local attackerWins = ap >= dp

					-- потери
					atk.Soldiers = math.max(0, atk.Soldiers - math.random(1, 4))
					def.Soldiers = math.max(0, def.Soldiers - math.random(1, 5))

					if attackerWins then
						war.progress = math.min(1, war.progress + 0.12 + math.random() * 0.06)
						WarLogUpdate:FireAllClients(("%s побеждает в бою против %s"):format(war.attacker, war.defender))
					else
						war.progress = math.max(0, war.progress - 0.08 - math.random() * 0.04)
						WarLogUpdate:FireAllClients(("%s отбивает атаку %s"):format(war.defender, war.attacker))
					end

					-- Движение маркера
					local api = ensureMapAPI()
					if war.marker and api then
						local aPos = api.GetCapitalWorldPos(war.attacker)
						local dPos = api.GetCapitalWorldPos(war.defender)
						if aPos and dPos then
							local pos = aPos:Lerp(dPos, war.progress)
							war.marker.Position = pos
						end
					end

					if war.progress >= 1 then
						annexCountry(war.attacker, war.defender)
						endWar(key)
					elseif atk.Soldiers <= 0 then
						broadcastBanner(("%s проиграла войну против %s"):format(war.attacker, war.defender))
						endWar(key)
					end

					for _, p in ipairs(Players:GetPlayers()) do
						pushPlayerOwn(p)
					end
				end
			end
		end
	end
end)

-- Стартовый список стран новым игрокам
Players.PlayerAdded:Connect(function(player)
	task.wait(1)
	CountryListUpdate:FireClient(player, CountryState.ListSnapshot())
	DateUpdate:FireClient(player, ("%d.%02d.%d"):format(day, month, year))
end)

print("[Europe] WarAndEconomyServer запущен")
