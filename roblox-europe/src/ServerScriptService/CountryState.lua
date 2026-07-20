--[[
	CountryState — runtime-состояние стран (сервер).
	Money / Factories / Population / Soldiers / Owner / AtWarWith / ResearchLevel
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EuropeCountries = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EuropeCountries"))

local CountryState = {}
CountryState.__index = CountryState

local states: { [string]: any } = {}
local playerCountry: { [number]: string } = {} -- UserId -> country name

function CountryState.Init()
	states = {}
	playerCountry = {}
	for _, c in ipairs(EuropeCountries.All()) do
		states[c.Name] = {
			Name = c.Name,
			Color = c.Color,
			Capital = c.Capital,
			Cities = table.clone(c.Cities),
			Money = c.Money,
			Factories = c.Factories,
			Soldiers = c.Soldiers,
			Population = c.Population,
			Owner = nil :: Player?,
			AtWarWith = {} :: { [string]: boolean },
			ResearchLevel = 0,
			Buildings = 0,
			JustificationUntil = 0, -- tick time
			WarTarget = nil :: string?,
		}
	end
end

function CountryState.Get(name: string)
	return states[name]
end

function CountryState.All()
	return states
end

function CountryState.GetPlayerCountry(player: Player): string?
	return playerCountry[player.UserId]
end

function CountryState.SetOwner(countryName: string, player: Player?): boolean
	local st = states[countryName]
	if not st then
		return false
	end
	if player then
		-- Игрок уже владеет другой страной?
		local old = playerCountry[player.UserId]
		if old and old ~= countryName then
			return false
		end
		if st.Owner and st.Owner ~= player then
			return false
		end
		st.Owner = player
		playerCountry[player.UserId] = countryName
	else
		local owner = st.Owner
		st.Owner = nil
		if owner then
			playerCountry[owner.UserId] = nil
		end
	end
	return true
end

function CountryState.ClearPlayer(player: Player)
	local name = playerCountry[player.UserId]
	if name and states[name] then
		states[name].Owner = nil
		states[name].AtWarWith = {}
		states[name].WarTarget = nil
		states[name].JustificationUntil = 0
	end
	playerCountry[player.UserId] = nil
end

function CountryState.Snapshot(name: string)
	local st = states[name]
	if not st then
		return nil
	end
	local wars = {}
	for enemy, _ in pairs(st.AtWarWith) do
		table.insert(wars, enemy)
	end
	return {
		Name = st.Name,
		Capital = st.Capital,
		Money = math.floor(st.Money),
		Factories = st.Factories,
		Soldiers = math.floor(st.Soldiers),
		Population = math.floor(st.Population),
		ResearchLevel = st.ResearchLevel,
		Buildings = st.Buildings,
		OwnerName = st.Owner and st.Owner.Name or nil,
		AtWarWith = wars,
		WarTarget = st.WarTarget,
		JustificationUntil = st.JustificationUntil,
		Color = { st.Color.R, st.Color.G, st.Color.B },
	}
end

function CountryState.ListSnapshot()
	local list = {}
	for name, _ in pairs(states) do
		table.insert(list, CountryState.Snapshot(name))
	end
	table.sort(list, function(a, b)
		return a.Name < b.Name
	end)
	return list
end

function CountryState.Score(st): number
	return (st.Population / 1000) + (st.Money / 10) + st.Soldiers
end

return CountryState
