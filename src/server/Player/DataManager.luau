--!strict

-- Зависимости
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Utils = require(ReplicatedStorage.Shared.Utils)
local ProfileStore = require(ServerScriptService.Packages.ProfileStore)

--
-- Шаблон данных по умолчанию
local PROFILE_TEMPLATE = {
	CoinsEarned = 0,
	CoinsSpend = 0,
	Revision = 0,
	LastPatchName = "INIT",
}

export type PlayerData = typeof(PROFILE_TEMPLATE)
type Profile = ProfileStore.Profile<PlayerData>

export type PlayerDataChangedEvent = {
	Player: Player,
	Data: PlayerData,
}

--
-- Создаем хранилище
local PlayerStore = ProfileStore.New("PlayerData", PROFILE_TEMPLATE)

-- Если в студии, включаем мок
if RunService:IsStudio() then
	PlayerStore = PlayerStore.Mock
end

local Profiles: { [Player]: Profile } = {}

--
-- Вход игрока
local function onPlayerAdded(player: Player)
	-- StartSessionAsync — актуальный API (заменил :LoadProfileAsync)
	local profile = PlayerStore:StartSessionAsync(`Player_{player.UserId}`, {
		Cancel = function()
			-- Прервать попытку загрузки, если игрок уже вышел
			return player.Parent ~= Players
		end,
	})

	-- Профиль не загрузился (игрок вышел, шатдаун, другой сервер держит лок и т.п.)
	if profile == nil then
		player:Kick("Не удалось загрузить данные. Зайдите снова.")
		return
	end

	profile:AddUserId(player.UserId) -- Для GDPR-запросов, связываем UserId с профилем
	profile:Reconcile() -- Дозаполняем недостающие поля из шаблона

	-- Если сессию перехватил другой сервер — освобождаем игрока
	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		player:Kick(
			"Сессия данных завершена. Ваши данные загружены на другом сервере."
		)
	end)

	-- Проверяем, что игрок всё ещё в игре
	if player.Parent == Players then
		Profiles[player] = profile
	else
		-- Игрок вышел, пока грузились данные — закрываем сессию
		profile:EndSession()
	end
end

--
-- Выход игрока
local function onPlayerRemoving(player: Player)
	local profile = Profiles[player]
	if profile then
		profile:EndSession() -- Сохраняет и снимает блокировку
	end
end

--
-- Обрабатываем игроков, которые уже в игре (на случай позднего запуска скрипта)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

--
-- DataManager
local DataManager = {}

local onProfileDataChanged = function(event: PlayerDataChangedEvent) end

-- Подключить callback на изменение данных
function DataManager:OnProfileDataChanged(handler: typeof(onProfileDataChanged))
	local previous = onProfileDataChanged

	onProfileDataChanged = function(event: PlayerDataChangedEvent)
		previous(event)
		handler(event)
	end
end

-- Создает копию данных пользователя
function DataManager:GetReadOnlyVersion(player: Player): PlayerData?
	local profile = Profiles[player]
	if profile == nil then
		return nil
	end

	return {
		CoinsEarned = profile.Data.CoinsEarned,
		CoinsSpend = profile.Data.CoinsSpend,
		Revision = profile.Data.Revision,
		LastPatchName = profile.Data.LastPatchName,
	}
end

-- Мутирует данные пользователя, перезапускает мутацию в случае расхождений оптимистичной блокировки
function DataManager:MutateData(
	patchName: string, -- Название применяемого патча
	player: Player, -- Игрок для которого применяется патч
	mutation: (data: PlayerData) -> () -- Патч
): boolean
	-- Получаем профиль
	local profile = Profiles[player]
	if profile == nil then
		return false
	end

	-- Фейлим операцию, если профиль неактивен
	if not profile:IsActive() then
		return false
	end

	-- Мутируем данные пользователя
	local playerData: PlayerData
	repeat
		playerData = assert(self:GetReadOnlyVersion(player), "Always not nil")
		mutation(playerData)

		-- Повторно проверяем активность пользователя
		if not profile:IsActive() then
			return false
		end
	-- Принимаем изменения только если ревизия не изменилась (оптимистичная блокировка)
	until profile.Data.Revision == playerData.Revision and profile.Data.LastPatchName == playerData.LastPatchName

	-- Системные данные в изменениях данных
	playerData.Revision += 1
	playerData.LastPatchName = patchName

	-- Сохраняем изменения
	profile.Data = playerData

	-- Публикуем изменения
	Utils:safeCall("onProfileDataChanged", function()
		onProfileDataChanged({
			Player = player,
			Data = playerData,
		})
	end)

	return true
end

--
-- Обработчики событий
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

return DataManager
