--[[
	EuropeCountries — данные стран Европы для стратегии.
]]

local DATA = {
	{ Name = "Россия", Color = Color3.fromRGB(200, 40, 40), Capital = "Москва", Cities = { "Санкт-Петербург", "Казань", "Новосибирск", "Волгоград" }, Money = 1200, Factories = 4, Soldiers = 80, Population = 145000000 },
	{ Name = "Германия", Color = Color3.fromRGB(50, 50, 50), Capital = "Берлин", Cities = { "Мюнхен", "Гамбург", "Кёльн", "Франкфурт" }, Money = 1100, Factories = 5, Soldiers = 55, Population = 83000000 },
	{ Name = "Франция", Color = Color3.fromRGB(50, 90, 200), Capital = "Париж", Cities = { "Лион", "Марсель", "Тулуза", "Бордо" }, Money = 1000, Factories = 4, Soldiers = 50, Population = 67000000 },
	{ Name = "Великобритания", Color = Color3.fromRGB(180, 50, 90), Capital = "Лондон", Cities = { "Манчестер", "Бирмингем", "Эдинбург", "Ливерпуль" }, Money = 950, Factories = 4, Soldiers = 45, Population = 67000000 },
	{ Name = "Италия", Color = Color3.fromRGB(40, 160, 70), Capital = "Рим", Cities = { "Милан", "Неаполь", "Турин", "Флоренция" }, Money = 850, Factories = 3, Soldiers = 40, Population = 59000000 },
	{ Name = "Испания", Color = Color3.fromRGB(220, 160, 40), Capital = "Мадрид", Cities = { "Барселона", "Валенсия", "Севилья", "Бильбао" }, Money = 800, Factories = 3, Soldiers = 35, Population = 47000000 },
	{ Name = "Польша", Color = Color3.fromRGB(220, 80, 100), Capital = "Варшава", Cities = { "Краков", "Гданьск", "Вроцлав" }, Money = 700, Factories = 3, Soldiers = 40, Population = 38000000 },
	{ Name = "Украина", Color = Color3.fromRGB(40, 120, 200), Capital = "Киев", Cities = { "Харьков", "Одесса", "Львов", "Днепр" }, Money = 650, Factories = 3, Soldiers = 45, Population = 41000000 },
	{ Name = "Турция", Color = Color3.fromRGB(180, 30, 40), Capital = "Анкара", Cities = { "Стамбул", "Измир", "Анталья" }, Money = 750, Factories = 3, Soldiers = 50, Population = 85000000 },
	{ Name = "Швеция", Color = Color3.fromRGB(40, 100, 180), Capital = "Стокгольм", Cities = { "Гётеборг", "Мальмё" }, Money = 600, Factories = 2, Soldiers = 20, Population = 10000000 },
	{ Name = "Норвегия", Color = Color3.fromRGB(180, 40, 50), Capital = "Осло", Cities = { "Берген", "Тронхейм" }, Money = 550, Factories = 2, Soldiers = 15, Population = 5400000 },
	{ Name = "Финляндия", Color = Color3.fromRGB(80, 140, 200), Capital = "Хельсинки", Cities = { "Тампере", "Турку" }, Money = 500, Factories = 2, Soldiers = 18, Population = 5500000 },
	{ Name = "Румыния", Color = Color3.fromRGB(200, 180, 40), Capital = "Бухарест", Cities = { "Клуж", "Тимишоара" }, Money = 480, Factories = 2, Soldiers = 25, Population = 19000000 },
	{ Name = "Чехия", Color = Color3.fromRGB(40, 70, 150), Capital = "Прага", Cities = { "Брно", "Острава" }, Money = 520, Factories = 2, Soldiers = 18, Population = 10700000 },
	{ Name = "Австрия", Color = Color3.fromRGB(200, 200, 220), Capital = "Вена", Cities = { "Зальцбург", "Грац" }, Money = 540, Factories = 2, Soldiers = 15, Population = 9000000 },
	{ Name = "Венгрия", Color = Color3.fromRGB(120, 60, 100), Capital = "Будапешт", Cities = { "Дебрецен", "Сегед" }, Money = 460, Factories = 2, Soldiers = 20, Population = 9700000 },
	{ Name = "Греция", Color = Color3.fromRGB(60, 120, 200), Capital = "Афины", Cities = { "Салоники", "Патрас" }, Money = 420, Factories = 2, Soldiers = 22, Population = 10400000 },
	{ Name = "Португалия", Color = Color3.fromRGB(40, 140, 70), Capital = "Лиссабон", Cities = { "Порту", "Брага" }, Money = 400, Factories = 2, Soldiers = 16, Population = 10300000 },
	{ Name = "Нидерланды", Color = Color3.fromRGB(220, 100, 40), Capital = "Амстердам", Cities = { "Роттердам", "Гаага" }, Money = 580, Factories = 3, Soldiers = 18, Population = 17500000 },
	{ Name = "Бельгия", Color = Color3.fromRGB(200, 180, 60), Capital = "Брюссель", Cities = { "Антверпен", "Гент" }, Money = 500, Factories = 2, Soldiers = 14, Population = 11500000 },
	{ Name = "Швейцария", Color = Color3.fromRGB(200, 40, 40), Capital = "Берн", Cities = { "Цюрих", "Женева" }, Money = 700, Factories = 2, Soldiers = 12, Population = 8700000 },
	{ Name = "Дания", Color = Color3.fromRGB(180, 40, 50), Capital = "Копенгаген", Cities = { "Орхус", "Оденсе" }, Money = 480, Factories = 2, Soldiers = 12, Population = 5800000 },
	{ Name = "Ирландия", Color = Color3.fromRGB(40, 140, 70), Capital = "Дублин", Cities = { "Корк", "Голуэй" }, Money = 450, Factories = 2, Soldiers = 10, Population = 5000000 },
	{ Name = "Сербия", Color = Color3.fromRGB(100, 40, 60), Capital = "Белград", Cities = { "Нови-Сад", "Ниш" }, Money = 350, Factories = 1, Soldiers = 20, Population = 6800000 },
	{ Name = "Болгария", Color = Color3.fromRGB(80, 140, 80), Capital = "София", Cities = { "Пловдив", "Варна" }, Money = 340, Factories = 1, Soldiers = 18, Population = 6800000 },
	{ Name = "Хорватия", Color = Color3.fromRGB(40, 80, 160), Capital = "Загреб", Cities = { "Сплит", "Риека" }, Money = 360, Factories = 1, Soldiers = 14, Population = 4000000 },
	{ Name = "Словакия", Color = Color3.fromRGB(40, 100, 180), Capital = "Братислава", Cities = { "Кошице", "Прешов" }, Money = 380, Factories = 1, Soldiers = 12, Population = 5400000 },
	{ Name = "Литва", Color = Color3.fromRGB(200, 160, 40), Capital = "Вильнюс", Cities = { "Каунас", "Клайпеда" }, Money = 320, Factories = 1, Soldiers = 10, Population = 2800000 },
	{ Name = "Латвия", Color = Color3.fromRGB(140, 40, 60), Capital = "Рига", Cities = { "Даугавпилс", "Лиепая" }, Money = 300, Factories = 1, Soldiers = 8, Population = 1900000 },
	{ Name = "Эстония", Color = Color3.fromRGB(40, 80, 160), Capital = "Таллин", Cities = { "Тарту", "Нарва" }, Money = 290, Factories = 1, Soldiers = 7, Population = 1300000 },
	{ Name = "Беларусь", Color = Color3.fromRGB(80, 140, 80), Capital = "Минск", Cities = { "Гомель", "Брест", "Витебск" }, Money = 400, Factories = 2, Soldiers = 30, Population = 9400000 },
	{ Name = "Молдова", Color = Color3.fromRGB(40, 100, 160), Capital = "Кишинёв", Cities = { "Тирасполь", "Бельцы" }, Money = 250, Factories = 1, Soldiers = 8, Population = 2600000 },
}

local EuropeCountries = {}
local byName = {}
for _, c in ipairs(DATA) do
	byName[c.Name] = c
end

function EuropeCountries.Get(name: string)
	return byName[name]
end

function EuropeCountries.All()
	return DATA
end

return EuropeCountries
