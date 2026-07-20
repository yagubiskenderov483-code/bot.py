--[[
	Bootstrap — создаёт Remotes, отключает автоспавн до готовности карты.
	Должен запускаться ПЕРВЫМ (имя Bootstrap — раньше World/War по алфавиту).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Критично: не спавнить в пустоте до построения карты
Players.CharacterAutoLoads = false

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

local modules = ensureFolder(ReplicatedStorage, "Modules")
local remotes = ensureFolder(ReplicatedStorage, "Remotes")

local REMOTE_NAMES = {
	"RequestCountryInfo",
	"CountryInfoUpdate",
	"DateUpdate",
	"BuyFactory",
	"TrainSoldiers",
	"BuyResearch",
	"DeclareWar",
	"WarLogUpdate",
	"LeaderboardUpdate",
	"CountryListUpdate",
	"ClaimCountry",
	"MapReady",
	"ShowBanner",
}

for _, name in ipairs(REMOTE_NAMES) do
	if not remotes:FindFirstChild(name) then
		local re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = remotes
	end
end

-- Флаг готовности мира
local ready = Instance.new("BoolValue")
ready.Name = "WorldReady"
ready.Value = false
ready.Parent = ReplicatedStorage

print("[Europe] Bootstrap: Remotes готовы, CharacterAutoLoads=false")
