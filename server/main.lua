local QBCore = exports['qb-core']:GetCoreObject()
local GotItems = {}
local AlarmActivated = false

RegisterNetEvent('prison:server:SetJailStatus', function(jailTime)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    Player.Functions.SetMetaData('injail', jailTime)
    if jailTime > 0 then
        if Player.PlayerData.job.name ~= 'unemployed' then
            Player.Functions.SetJob('unemployed')
            TriggerClientEvent('QBCore:Notify', src, Lang:t('info.lost_job'))
        end
    else
        GotItems[src] = nil
    end
end)

RegisterNetEvent('prison:server:SaveJailItems', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Получаем инвентарь игрока и сохраняем в метаданные
    local items = Inventory.GetInventory(src)
    Player.Functions.SetMetaData('jailitems', items)

    -- Добавляем деньги за тюрьму и очищаем инвентарь
    Player.Functions.AddMoney('cash', 80, 'jail money')
    Wait(2000)
    exports.ox_inventory:ClearInventory(src)
end)



RegisterNetEvent('prison:server:GiveJailItems', function(escaped)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if escaped then
        Player.Functions.SetMetaData('jailitems', {})
        return
    end

    local jailItems = Player.PlayerData.metadata['jailitems'] or {}
    for _, item in pairs(jailItems) do
        Inventory.AddItem(src, item.name, item.count, item.metadata)
    end
    Player.Functions.SetMetaData('jailitems', {})
end)





-- RegisterNetEvent('prison:server:ResetJailItems', function()
--     local src = source
--     local Player = QBCore.Functions.GetPlayer(src)
--     if not Player then return end
--     Player.Functions.SetMetaData('jailitems', {})
-- end)

RegisterNetEvent('prison:server:SecurityLockdown', function()
    TriggerClientEvent('prison:client:SetLockDown', -1, true)
    for _, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player then
            if Player.PlayerData.job.name == 'police' and Player.PlayerData.job.onduty then
                TriggerClientEvent('prison:client:PrisonBreakAlert', v)
            end
        end
    end
end)

RegisterNetEvent('prison:server:SetGateHit', function(key)
    TriggerClientEvent('prison:client:SetGateHit', -1, key, true)
    if math.random(1, 100) <= 50 then
        for _, v in pairs(QBCore.Functions.GetPlayers()) do
            local Player = QBCore.Functions.GetPlayer(v)
            if Player then
                if Player.PlayerData.job.name == 'police' and Player.PlayerData.job.onduty then
                    TriggerClientEvent('prison:client:PrisonBreakAlert', v)
                end
            end
        end
    end
end)

RegisterNetEvent('prison:server:CheckRecordStatus', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local CriminalRecord = Player.PlayerData.metadata['criminalrecord']
    local currentDate = os.date('*t')

    if (CriminalRecord['date'].month + 1) == 13 then
        CriminalRecord['date'].month = 0
    end

    if CriminalRecord['hasRecord'] then
        if currentDate.month == (CriminalRecord['date'].month + 1) or currentDate.day == (CriminalRecord['date'].day - 1) then
            CriminalRecord['hasRecord'] = false
            CriminalRecord['date'] = nil
        end
    end
end)

RegisterNetEvent('prison:server:JailAlarm', function()
    if AlarmActivated then return end
    local playerPed = GetPlayerPed(source)
    local coords = GetEntityCoords(playerPed)
    local middle = vec2(Config.Locations['middle'].x, Config.Locations['middle'].y)
    if #(coords.xy - middle) < 200 then return error('"prison:server:JailAlarm" triggered whilst the player was too close to the prison, cancelled event') end
    TriggerClientEvent('prison:client:JailAlarm', -1, true)
    SetTimeout(5 * 60000, function()
        TriggerClientEvent('prison:client:JailAlarm', -1, false)
    end)
end)

RegisterNetEvent('prison:server:CheckChance', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or Player.PlayerData.metadata.injail == 0 or GotItems[src] then return end
    local chance = math.random(100)
    local odd = math.random(100)
    if chance ~= odd then return end
    if not exports.ox_inventory:AddItem(src, 'phone', 1) then return end
    TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items['phone'], 'add')
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.found_phone'), 'success')
    GotItems[src] = true
end)

QBCore.Functions.CreateCallback('prison:server:IsAlarmActive', function(_, cb)
    cb(AlarmActivated)
end)
