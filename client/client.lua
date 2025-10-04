-- ====================================================
-- 🎁 EDGE PROMOTION CODES | CLIENT-SIDE
-- Developed by: Edge System | Mestre Edge
-- ====================================================

-- Detect Framework
if Config.Framework == 'ESX' then
    ESX = exports["es_extended"]:getSharedObject()
elseif Config.Framework == 'QBCore' then
    QBCore = exports['qb-core']:GetCoreObject()
else
    print("[Edge System] ⚠️ Nenhum framework detectado! Verifique o config.lua.")
end

-- Mensagem inicial
print("^2[Edge System]^7 🎁 EDGE PROMOTION CODES iniciado no client-side.")
print("^3[Edge System]^7 Obrigado por usar nosso script FREE 💚 https://discord.gg/jCxadac2vt")

-- ====================================================
-- 👑 Comando: /codigoedge (Criar código - admin only)
-- ====================================================
RegisterCommand('codigoedge', function()
    print("[Edge System] 🧩 Comando /codigoedge executado pelo jogador.")

    local framework = Config.Framework
    local callback = framework == 'ESX' and ESX.TriggerServerCallback or QBCore.Functions.TriggerCallback

    callback('edge_giftcode:checkAdmin', function(isAdmin)
        if not isAdmin then
            lib.notify({ description = Config.Notify['no_perm'] or "Você não tem permissão para isso.", type = 'error' })
            print("[Edge System] ❌ Jogador tentou criar código sem permissão.")
            return
        end

        local input = lib.inputDialog('Criar Código de Presente', {
            { type = 'input', label = 'Código', description = 'Exemplo: EDGE2025', required = true, min = 4, max = 16 },
            { type = 'input', label = 'Recompensa', description = 'Item, conta (bank) ou nome do veículo', required = true },
            { type = 'number', label = 'Quantidade', description = 'Exemplo: 1, 5000', icon = 'hashtag', required = true },
            { type = 'input', label = 'Tipo de Recompensa', description = 'item, vehicle, money', required = true },
            { type = 'number', label = 'Máximo de resgates', description = 'Número máximo de usos', icon = 'hashtag', required = true },
            { type = 'input', label = 'Expira em (AAAA-MM-DD)', required = true }
        })

        if input then
            print(("[Edge System] ✅ Código criado localmente, enviando para o servidor: %s"):format(input[1]))
            TriggerServerEvent('edge_giftcode:addGiftcode', input)
        else
            lib.notify({ description = Config.Notify['cancelled_create'] or "Criação cancelada.", type = 'error' })
            print("[Edge System] ⚠️ Criação de código cancelada pelo jogador.")
        end
    end)
end, false)

-- ====================================================
-- 🎟️ Comando: /codigo (Resgatar código)
-- ====================================================
RegisterCommand('codigo', function()
    print("[Edge System] 🧩 Comando /codigo executado pelo jogador.")

    local input = lib.inputDialog('Digite o Código de Presente', {
        { type = 'input', label = 'Código de Presente', description = 'Digite o código recebido', required = true, min = 4, max = 16 },
    })

    if input then
        print(("[Edge System] 📦 Jogador digitou o código: %s"):format(input[1]))
        TriggerServerEvent('edge_giftcode:redeemGiftcode', input)
    else
        print("[Edge System] ⚠️ Jogador fechou o input sem digitar código.")
    end
end, false)

-- ====================================================
-- 🚗 Evento: Spawn de veículo de recompensa
-- ====================================================
RegisterNetEvent('edge_giftcode:SpawnVehicle')
AddEventHandler('edge_giftcode:SpawnVehicle', function(model, reward)
    model = tostring(model):lower()
    print(("[Edge System] 🚗 Tentando spawnar veículo de recompensa: %s"):format(model))

    -- Validação de modelo
    if not IsModelInCdimage(model) or not IsModelAVehicle(model) then
        print(("[Edge System] ❌ Modelo de veículo inválido ou não encontrado: %s"):format(model))
        lib.notify({ description = 'Modelo de veículo inválido ou não encontrado: ' .. model, type = 'error' })
        return
    end

    -- Carrega o modelo
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(10)
        timeout = timeout + 1
        if timeout > 500 then
            print(("[Edge System] ❌ Timeout ao carregar o modelo: %s"):format(model))
            lib.notify({ description = 'Falha ao carregar modelo do veículo: ' .. model, type = 'error' })
            return
        end
    end

    -- Coordenadas e spawn
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)

    if not veh or veh == 0 then
        print("[Edge System] ❌ Falha ao criar o veículo.")
        lib.notify({ description = 'Falha ao spawnar veículo.', type = 'error' })
        return
    end

    SetPedIntoVehicle(playerPed, veh, -1)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleDirtLevel(veh, 0.0)
    SetModelAsNoLongerNeeded(model)

    -- Framework: integração final
    if Config.Framework == 'QBCore' then
        local plate = QBCore.Functions.GetPlate(veh)
        local props = QBCore.Functions.GetVehicleProperties(veh)
        TriggerServerEvent('edge_giftcode:giveVehicle', props, reward)
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
        print(("[Edge System] ✅ Veículo '%s' spawnado e entregue (QBCore)."):format(model))
        lib.notify({ description = '🚗 Veículo entregue com sucesso!', type = 'success' })
    elseif Config.Framework == 'ESX' then
        local props = ESX.Game.GetVehicleProperties(veh)
        TriggerServerEvent('edge_giftcode:giveVehicle', props)
        print(("[Edge System] ✅ Veículo '%s' spawnado e entregue (ESX)."):format(model))
        lib.notify({ description = '🚗 Veículo entregue com sucesso!', type = 'success' })
    else
        print("[Edge System] ❌ Nenhum framework detectado. Spawn cancelado.")
        lib.notify({ description = 'Erro interno: nenhum framework detectado.', type = 'error' })
    end
end)
