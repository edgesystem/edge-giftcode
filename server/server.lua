-- ====================================================
-- 🎁 EDGE PROMOTION CODES | SERVER-SIDE
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

print("^2[Edge System]^7 🎁 EDGE PROMOTION CODES iniciado no server-side.")
print("^3[Edge System]^7 Obrigado por usar nosso script FREE 💚  https://discord.gg/jCxadac2vt")

-- ====================================================
-- 🔠 Tradutor de Tipos (suporte multilíngue)
-- ====================================================
local TypeMap = {
    ["dinheiro"] = "money",
    ["money"] = "money",
    ["cash"] = "money",
    ["bank"] = "money",
    ["veiculo"] = "vehicle",
    ["carro"] = "vehicle",
    ["vehicle"] = "vehicle",
    ["item"] = "item"
}

-- ====================================================
-- 🧠 Callback: Verificar se o jogador é admin
-- ====================================================
if Config.Framework == 'ESX' then
    ESX.RegisterServerCallback('edge_giftcode:checkAdmin', function(source, cb)
        local xPlayer = ESX.GetPlayerFromId(source)
        cb(xPlayer and xPlayer.getGroup() == Config.AllowedGroup)
    end)
else
    QBCore.Functions.CreateCallback('edge_giftcode:checkAdmin', function(source, cb)
        local Player = QBCore.Functions.GetPlayer(source)
        cb(Player and (QBCore.Functions.HasPermission(source, Config.AllowedGroup) or IsPlayerAceAllowed(source, 'command')))
    end)
end

-- ====================================================
-- 🧩 Criar novo código de presente
-- ====================================================
RegisterNetEvent('edge_giftcode:addGiftcode')
AddEventHandler('edge_giftcode:addGiftcode', function(input)
    local src = source
    local code, reward, amount, reward_type, max_redeem, expire_at =
        input[1], input[2], tonumber(input[3]), tostring(input[4]):lower(), tonumber(input[5]), input[6]

    reward_type = TypeMap[reward_type] or reward_type

    local year, month, day = string.match(expire_at, '(%d+)-(%d+)-(%d+)')
    if not (year and month and day) then
        TriggerClientEvent('ox_lib:notify', src, { description = Config.Notify['invalid_date'], type = 'error' })
        print("[Edge System] ❌ Data inválida informada.")
        return
    end

    expire_at = string.format('%s-%s-%s 00:00:00', year, month, day)

    local query = [[
        INSERT INTO edge_giftcodes (code, reward, amount, reward_type, max_redeem, current_redeem, expire_at)
        VALUES (@code, @reward, @amount, @reward_type, @max_redeem, 0, @expire_at)
    ]]
    local params = {
        ['@code'] = code,
        ['@reward'] = reward,
        ['@amount'] = amount,
        ['@reward_type'] = reward_type,
        ['@max_redeem'] = max_redeem,
        ['@expire_at'] = expire_at
    }

    exports.oxmysql:execute(query, params, function(result)
        print(("[Edge System] 🧩 Novo código criado: %s | Tipo: %s | Quantidade: %s | Expira em: %s"):format(code, reward_type, amount, expire_at))
        TriggerClientEvent('ox_lib:notify', src, { description = '✅ Código criado com sucesso: ' .. code, type = 'success' })
    end)
end)

-- ====================================================
-- 🎟️ Resgatar código
-- ====================================================
RegisterNetEvent('edge_giftcode:redeemGiftcode')
AddEventHandler('edge_giftcode:redeemGiftcode', function(input)
    local src = source
    local code = input[1]
    if not code then return end

    print(("[Edge System] 🔍 Player %s tentou resgatar o código: %s"):format(GetPlayerName(src), code))

    local query = 'SELECT * FROM edge_giftcodes WHERE code = @code'
    local params = { ['@code'] = code }

    local function processGift(giftcode, identifier, frameworkPlayer)
        -- ✅ Filtro de tipo inválido (anti-crash)
        giftcode.expire_at = type(giftcode.expire_at) == "string" and giftcode.expire_at or nil

        -- 🕒 Validação de expiração
        if Config.ExpireGiftcode and giftcode.expire_at then
            local year = tonumber(giftcode.expire_at:sub(1, 4))
            local month = tonumber(giftcode.expire_at:sub(6, 7))
            local day = tonumber(giftcode.expire_at:sub(9, 10))

            if year and month and day then
                local expire_time = os.time({ year = year, month = month, day = day })
                if os.time() > expire_time then
                    TriggerClientEvent('ox_lib:notify', src, { description = Config.Notify['has_expired'], type = 'error' })
                    print(("[Edge System] ⏰ Código expirado: %s (expirou em %s)"):format(code, giftcode.expire_at))
                    return
                end
            else
                print(("[Edge System] ⚠️ Campo expire_at inválido: %s"):format(tostring(giftcode.expire_at)))
            end
        end

        -- 🔁 Limite global
        if Config.LimitRedeem and giftcode.current_redeem >= giftcode.max_redeem then
            TriggerClientEvent('ox_lib:notify', src, { description = Config.Notify['usage_limit'], type = 'error' })
            print(("[Edge System] ❌ Código atingiu limite máximo de uso: %s"):format(code))
            return
        end

        -- 👤 Identificador único
        if Config.CheckUserRedeem then
            local checkQuery = 'SELECT * FROM edge_user_giftcodes WHERE identifier = @identifier AND code = @code'
            local checkParams = { ['@identifier'] = identifier, ['@code'] = code }

            exports.oxmysql:fetch(checkQuery, checkParams, function(result)
                if result and #result > 0 then
                    TriggerClientEvent('ox_lib:notify', src, { description = Config.Notify['already_used'], type = 'error' })
                    print(("[Edge System] ⚠️ %s já resgatou o código %s"):format(identifier, code))
                    return
                end

                exports.oxmysql:insert('INSERT INTO edge_user_giftcodes (identifier, code) VALUES (@identifier, @code)', checkParams)
                redeemGiftcode(frameworkPlayer, giftcode)
            end)
        else
            redeemGiftcode(frameworkPlayer, giftcode)
        end
    end

    -- 🔄 Processamento por framework
    if Config.Framework == 'ESX' then
        local xPlayer = ESX.GetPlayerFromId(src)
        MySQL.Async.fetchAll(query, params, function(result)
            if #result > 0 then
                processGift(result[1], xPlayer.identifier, xPlayer)
            else
                TriggerClientEvent('ox_lib:notify', src, { description = Config.Notify['giftcode_invalid'], type = 'error' })
                print(("[Edge System] ❌ Código inválido: %s"):format(code))
            end
        end)
    else
        local Player = QBCore.Functions.GetPlayer(src)
        exports.oxmysql:fetch(query, params, function(result)
            if result and #result > 0 then
                processGift(result[1], Player.PlayerData.citizenid, Player)
            else
                TriggerClientEvent('ox_lib:notify', src, { description = Config.Notify['giftcode_invalid'], type = 'error' })
                print(("[Edge System] ❌ Código inválido: %s"):format(code))
            end
        end)
    end
end)

-- ====================================================
-- 🎁 Função: Entregar Recompensa
-- ====================================================
function redeemGiftcode(player, giftcode)
    if not giftcode then
        print("[Edge System] ⚠️ Giftcode nulo detectado.")
        return
    end

    giftcode.reward_type = TypeMap[giftcode.reward_type] or giftcode.reward_type

    -- Atualizar contador global
    exports.oxmysql:execute('UPDATE edge_giftcodes SET current_redeem = current_redeem + 1 WHERE code = @code', { ['@code'] = giftcode.code })

    if Config.Framework == 'ESX' then
        if giftcode.reward_type == 'money' then
            player.addAccountMoney(giftcode.reward, tonumber(giftcode.amount))
        elseif giftcode.reward_type == 'item' then
            player.addInventoryItem(giftcode.reward, tonumber(giftcode.amount))
        elseif giftcode.reward_type == 'vehicle' then
            TriggerClientEvent('edge_giftcode:SpawnVehicle', player.source, giftcode.reward, giftcode.reward)
        else
            print("[Edge System] ❌ Tipo de recompensa inválido.")
            return
        end
        print(("[Edge System] ✅ %s resgatou o código: %s"):format(player.getName(), giftcode.code))

    elseif Config.Framework == 'QBCore' then
        if giftcode.reward_type == 'money' then
            player.Functions.AddMoney(giftcode.reward, tonumber(giftcode.amount))
        elseif giftcode.reward_type == 'item' then
            if Config.Inventory == 'qb-inventory' then
                exports['qb-inventory']:AddItem(player.PlayerData.source, giftcode.reward, tonumber(giftcode.amount))
            elseif Config.Inventory == 'ps-inventory' then
                exports['ps-inventory']:AddItem(player.PlayerData.source, giftcode.reward, tonumber(giftcode.amount))
            elseif Config.Inventory == 'ox_inventory' then
                exports.ox_inventory:AddItem(player.PlayerData.source, giftcode.reward, tonumber(giftcode.amount))
            end
        elseif giftcode.reward_type == 'vehicle' then
            TriggerClientEvent('edge_giftcode:SpawnVehicle', player.PlayerData.source, giftcode.reward, giftcode.reward)
        else
            print("[Edge System] ❌ Tipo de recompensa inválido.")
            return
        end
        print(("[Edge System] ✅ %s resgatou o código: %s"):format(player.PlayerData.name, giftcode.code))
    end

    TriggerClientEvent('ox_lib:notify', player.source, {
        description = Config.Notify['received_reward']:format(giftcode.amount, giftcode.reward),
        type = 'success'
    })
end

-- ====================================================
-- 🚗 Receber veículo do client e registrar no banco de dados
-- ====================================================
RegisterNetEvent('edge_giftcode:giveVehicle')
AddEventHandler('edge_giftcode:giveVehicle', function(vehicleProps, vehicleModel)
    local src = source
    
    if not vehicleProps then
        print("[Edge System] ❌ Propriedades do veículo não recebidas.")
        return
    end

    print(("[Edge System] 🚗 Registrando veículo no banco de dados para o jogador %s"):format(GetPlayerName(src)))

    if Config.Framework == 'ESX' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then
            print("[Edge System] ❌ Jogador não encontrado (ESX).")
            return
        end

        local plate = vehicleProps.plate
        local identifier = xPlayer.identifier

        local query = [[
            INSERT INTO owned_vehicles (owner, plate, vehicle, stored, type, job)
            VALUES (@owner, @plate, @vehicle, @stored, @type, @job)
        ]]
        
        local params = {
            ['@owner'] = identifier,
            ['@plate'] = plate,
            ['@vehicle'] = json.encode(vehicleProps),
            ['@stored'] = 1,
            ['@type'] = 'car',
            ['@job'] = 'civ'
        }

        exports.oxmysql:execute(query, params, function(result)
            if result then
                print(("[Edge System] ✅ Veículo %s registrado no banco de dados (ESX) para %s (placa: %s)"):format(vehicleModel or 'desconhecido', xPlayer.getName(), plate))
                TriggerClientEvent('ox_lib:notify', src, {
                    description = Config.Notify['received_vehicle']:format(vehicleModel or 'veículo'),
                    type = 'success'
                })
            else
                print("[Edge System] ❌ Erro ao inserir veículo no banco de dados (ESX).")
            end
        end)

    elseif Config.Framework == 'QBCore' then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then
            print("[Edge System] ❌ Jogador não encontrado (QBCore).")
            return
        end

        local plate = vehicleProps.plate
        local citizenid = Player.PlayerData.citizenid

        local query = [[
            INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state)
            VALUES (@license, @citizenid, @vehicle, @hash, @mods, @plate, @state)
        ]]
        
        local params = {
            ['@license'] = Player.PlayerData.license,
            ['@citizenid'] = citizenid,
            ['@vehicle'] = vehicleModel or 'unknown',
            ['@hash'] = GetHashKey(vehicleModel or 'adder'),
            ['@mods'] = json.encode(vehicleProps),
            ['@plate'] = plate,
            ['@state'] = 1
        }

        exports.oxmysql:execute(query, params, function(result)
            if result then
                print(("[Edge System] ✅ Veículo %s registrado no banco de dados (QBCore) para %s (placa: %s)"):format(vehicleModel or 'desconhecido', Player.PlayerData.name, plate))
                TriggerClientEvent('ox_lib:notify', src, {
                    description = Config.Notify['received_vehicle']:format(vehicleModel or 'veículo'),
                    type = 'success'
                })
            else
                print("[Edge System] ❌ Erro ao inserir veículo no banco de dados (QBCore).")
            end
        end)
    else
        print("[Edge System] ❌ Framework não detectado. Veículo não registrado.")
    end
end)
