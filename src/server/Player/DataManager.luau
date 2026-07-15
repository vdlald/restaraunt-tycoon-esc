local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStore = require(ReplicatedStorage.Packages.ProfileStore)

-- Шаблон данных по умолчанию
local PROFILE_TEMPLATE = {
    Coins = 0,
}

local PlayerStore = ProfileStore.New("PlayerData", PROFILE_TEMPLATE)

local DataManager = {}
DataManager.Profiles = {} -- [player] = profile

function DataManager.LoadProfile(player: Player)
    -- StartSessionAsync — актуальный API (заменил :LoadProfileAsync)
    local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
        Cancel = function()
            return player.Parent ~= Players
        end,
    })

    if profile == nil then
        -- Не удалось начать сессию (другой сервер держит лок и т.п.)
        player:Kick("Не удалось загрузить данные. Зайдите снова.")
        return
    end

    profile:AddUserId(player.UserId)   -- для GDPR-запросов
    profile:Reconcile()                -- добавляет недостающие поля из шаблона

    profile.OnSessionEnd:Connect(function()
        DataManager.Profiles[player] = nil
        player:Kick("Сессия данных завершена.")
    end)

    if player.Parent == Players then
        DataManager.Profiles[player] = profile
    else
        profile:EndSession()
    end
end

function DataManager.Get(player: Player)
    return DataManager.Profiles[player]
end

Players.PlayerRemoving:Connect(function(player)
    local profile = DataManager.Profiles[player]
    if profile then
        profile:EndSession()
    end
end)

return DataManager