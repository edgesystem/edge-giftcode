if Config.Framework == 'ESX' then
    ESX = exports["es_extended"]:getSharedObject()
elseif Config.Framework == 'QBCore' then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- Mensagem inicial no console do cliente
print("^2[Edge System]^7 🎁 EDGE PROMOTION CODES iniciado no client-side.")
print("^3[Edge System]^7 Obrigado por usar nosso script FREE 💚 https://discord.gg/jCxadac2vt")

-- =========================================
-- Comando para criar código (somente admin)
-- =========================================
RegisterCommand('codigoedge', function()
    print("[Edge System] 🧩 Comando /codigoedge executado pelo jogador.")

    local framework = Config.Framework
    local isAdminCallback = framework == 'ESX' and ESX.TriggerServerCallback or QBCore.Functions.TriggerCallback

    isAdminCallback('edge_giftcode:checkAdmin', function(isAdmin)
        if not isAdmin then
            lib.notify({ description = Config.Notify['no_perm'], type = 'error' })
            print("[Edge System] ❌ Jogador tentou criar código sem permissão.")
            return
        end

        local input = lib.inputDialog('Criar Código de Presente', {
            { type = 'input', label = 'Código', description = 'Código de Presente', required = true, min = 4, max = 16 },
            { type = 'input', label = 'Recompensa', description = 'Para tipo dinheiro (banco, dinheiro_sujo, dinheiro)', required = true },
            { type = 'number', label = 'Quantidade', description = 'Quantidade recebida', icon = 'hashtag', required = true },
            { type = 'input', label = 'Tipo de Recompensa', description = 'item, veículo, dinheiro', required = true },
            { type = 'number', label = 'Máximo de resgates', description = 'Número máximo de usos', icon = 'hashtag', required = true },
            { type = 'input', label = 'Expira em (AAAA-MM-DD)', required = true }
        })

        if input then
            print(("[Edge System] ✅ Código criado localmente, enviando para o servidor: %s"):format(input[1]))
            TriggerServerEvent('edge_giftcode:addGiftcode', input)
        else
            print("[Edge System] ⚠️ Criação de código cancelada pelo jogador.")
            lib.notify({ description = Config.Notify['cancelled_create'], type = 'error' })
        end
    end)
end, false)

-- =========================================
-- Comando para resgatar código
-- =========================================
RegisterCommand('codigo', function()
    print("[Edge System] 🧩 Comando /codigo executado pelo jogador.")

    local input = lib.inputDialog('Digite o Código de Presente', {
        { type = 'input', label = 'Código de Presente', description = 'Digite seu código', required = true, min = 4, max = 16 },
    })

    if input then
        print(("[Edge System] 📦 Jogador digitou o código: %s"):format(input[1]))
        TriggerServerEvent('edge_giftcode:redeemGiftcode', input)
    else
        print("[Edge System] ⚠️ Jogador fechou o input sem digitar código.")
    end
end, false)

-- =========================================
-- Spawn do veículo de recompensa
-- =========================================
RegisterNetEvent('edge_giftcode:SpawnVehicle')
AddEventHandler('edge_giftcode:SpawnVehicle', function(model, reward)
    print(("[Edge System] 🚗 Tentando spawnar veículo de recompensa: %s"):format(model))

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    local vehicle = model

    if Config.Framework == 'ESX' then
        ESX.Game.SpawnVehicle(vehicle, coords, heading, function(vehicle)
            local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
            SetPedIntoVehicle(playerPed, vehicle, -1)
            SetVehicleHasBeenOwnedByPlayer(playerPed, true)
            TriggerServerEvent('edge_giftcode:giveVehicle', vehicleProps)
            print("[Edge System] ✅ Veículo spawnado e entregue (ESX).")
        end)
    elseif Config.Framework == 'QBCore' then
        QBCore.Functions.SpawnVehicle(vehicle, function(vehicle)
            local vehicleProps = QBCore.Functions.GetVehicleProperties(vehicle)
            SetPedIntoVehicle(playerPed, vehicle, -1)
            SetVehicleHasBeenOwnedByPlayer(playerPed, true)
            TriggerServerEvent('edge_giftcode:giveVehicle', vehicleProps, reward)
            TriggerEvent('vehiclekeys:client:SetOwner', QBCore.Functions.GetPlate(vehicle))
            print("[Edge System] ✅ Veículo spawnado e entregue (QBCore).")
        end, coords, true)
    else
        print("[Edge System] ❌ Nenhum framework detectado. Spawn cancelado.")
    end
end)
