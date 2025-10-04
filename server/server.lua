if Config.Framework == 'ESX' then
    ESX = exports["es_extended"]:getSharedObject()

    ESX.RegisterServerCallback('edge_giftcode:checkAdmin', function(source, cb)
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer.getGroup() == Config.AllowedGroup then
            cb(true)
        else
            cb(false)
        end
    end)

    function redeemGiftcode(xPlayer, giftcode)
        if not giftcode then
            print("[Edge System] ⚠️ Giftcode nulo detectado.")
            return
        end

        MySQL.Async.execute('UPDATE edge_giftcodes SET current_redeem = current_redeem + 1 WHERE code = @code', {
            ['@code'] = giftcode.code
        }, function(rowsChanged)
            if rowsChanged > 0 then
                print(("[Edge System] ✅ %s resgatou o código: %s"):format(xPlayer.getName(), giftcode.code))
                if giftcode.reward_type == 'money' then
                    xPlayer.addAccountMoney(giftcode.reward, giftcode.amount)
                elseif giftcode.reward_type == 'item' then
                    xPlayer.addInventoryItem(giftcode.reward, tonumber(giftcode.amount))
                elseif giftcode.reward_type == 'vehicle' then
                    TriggerClientEvent('edge_giftcode:SpawnVehicle', xPlayer.source, giftcode.reward, giftcode.reward)
                else
                    TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                        description = Config.Notify['invalid_reward'],
                        type = 'error'
                    })
                    print("[Edge System] ❌ Tipo de recompensa inválido detectado.")
                    return
                end

                TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                    description = Config.Notify['received_reward']:format(giftcode.amount, giftcode.reward),
                    type = 'success'
                })
            else
                print(("[Edge System] ❌ Falha ao atualizar número de usos do código: %s"):format(giftcode.code))
            end
        end)
    end

elseif Config.Framework == 'QBCore' then
    QBCore = exports['qb-core']:GetCoreObject()

    QBCore.Functions.CreateCallback('edge_giftcode:checkAdmin', function(source, cb)
        local Player = QBCore.Functions.HasPermission(source, Config.AllowedGroup)
        if Player or IsPlayerAceAllowed(source, 'command') then
            cb(true)
        else
            cb(false)
        end
    end)

    function redeemGiftcode(Player, giftcode)
        if not giftcode then
            print("[Edge System] ⚠️ Giftcode nulo detectado.")
            return
        end

        exports.oxmysql:execute('UPDATE edge_giftcodes SET current_redeem = current_redeem + 1 WHERE code = @code', {
            ['@code'] = giftcode.code
        }, function(result)
            local rowsChanged = result and result.affectedRows or 0

            if rowsChanged > 0 then
                print(("[Edge System] ✅ %s resgatou o código: %s"):format(Player.PlayerData.name, giftcode.code))
                if giftcode.reward_type == 'money' then
                    Player.Functions.AddMoney(giftcode.reward, giftcode.amount)
                elseif giftcode.reward_type == 'item' then
                    if Config.Inventory == 'qb-inventory' then
                        exports['qb-inventory']:AddItem(Player.PlayerData.source, giftcode.reward, tonumber(giftcode.amount))
                    elseif Config.Inventory == 'ps-inventory' then
                        exports['ps-inventory']:AddItem(Player.PlayerData.source, giftcode.reward, tonumber(giftcode.amount))
                    elseif Config.Inventory == 'ox_inventory' then
                        exports.ox_inventory:AddItem(Player.PlayerData.source, giftcode.reward, tonumber(giftcode.amount))
                    end
                elseif giftcode.reward_type == 'vehicle' then
                    TriggerClientEvent('edge_giftcode:SpawnVehicle', Player.PlayerData.source, giftcode.reward, giftcode.reward)
                else
                    print("[Edge System] ❌ Tipo de recompensa inválido.")
                    TriggerClientEvent('ox_lib:notify', Player.PlayerData.source, {
                        description = Config.Notify['invalid_reward'],
                        type = 'error'
                    })
                    return
                end

                TriggerClientEvent('ox_lib:notify', Player.PlayerData.source, {
                    description = Config.Notify['received_reward']:format(giftcode.amount, giftcode.reward),
                    type = 'success'
                })
            else
                print(("[Edge System] ❌ Falha ao atualizar número de usos do código: %s"):format(giftcode.code))
            end
        end)
    end
end


-- [[ LOGO E INTRO ]] --
print("^2[Edge System]^7 🎁 EDGE PROMOTION CODES carregado com sucesso!")
print("^3[Edge System]^7 Obrigado por usar nosso script FREE 💚  https://discord.gg/jCxadac2vt")



-- [[ CRIAÇÃO DE CÓDIGO ]] --
RegisterServerEvent('edge_giftcode:addGiftcode')
AddEventHandler('edge_giftcode:addGiftcode', function(input)
    local source = source
    local code, reward, amount, reward_type, max_redeem, expire_at =
        input[1], input[2], input[3], input[4], tonumber(input[5]), input[6]

    local year, month, day = string.match(expire_at, '(%d+)-(%d+)-(%d+)')
    if not (year and month and day) then
        TriggerClientEvent('ox_lib:notify', source, {
            description = Config.Notify['invalid_date'],
            type = 'error'
        })
        print("[Edge System] ❌ Data inválida informada.")
        return
    end

    expire_at = string.format('%s-%s-%s 00:00:00', year, month, day)

    local query = 'INSERT INTO edge_giftcodes (code, reward, amount, reward_type, max_redeem, current_redeem, expire_at) VALUES (@code, @reward, @amount, @reward_type, @max_redeem, 0, @expire_at)'
    local params = {
        ['@code'] = code,
        ['@reward'] = reward,
        ['@amount'] = amount,
        ['@reward_type'] = reward_type,
        ['@max_redeem'] = max_redeem,
        ['@expire_at'] = expire_at
    }

    if Config.Framework == 'ESX' then
        MySQL.Async.execute(query, params, function(rowsChanged)
            if rowsChanged > 0 then
                print(("[Edge System] 🧩 Novo código criado: %s | Tipo: %s | Quantidade: %s"):format(code, reward_type, amount))
            else
                print("[Edge System] ❌ Falha ao criar código de presente.")
            end
        end)
    else
        exports.oxmysql:execute(query, params, function(result)
            if result and result.affectedRows and result.affectedRows > 0 then
                print(("[Edge System] 🧩 Novo código criado: %s | Tipo: %s | Quantidade: %s"):format(code, reward_type, amount))
            else
                print("[Edge System] ❌ Falha ao criar código de presente.")
            end
        end)
    end
end)



-- [[ RESGATE DE CÓDIGO ]] --
RegisterServerEvent('edge_giftcode:redeemGiftcode')
AddEventHandler('edge_giftcode:redeemGiftcode', function(input)
    local src = source
    local code = input[1]
    print(("[Edge System] 🔍 Player %s tentou resgatar o código: %s"):format(GetPlayerName(src), code))

    local query = 'SELECT * FROM edge_giftcodes WHERE code = @code'
    local params = { ['@code'] = code }

    local function processGift(giftcode, identifier, frameworkPlayer)
        if Config.ExpireGiftcode and giftcode.expire_at then
            local expire_time = os.time({
                year = tonumber(giftcode.expire_at:sub(1, 4)),
                month = tonumber(giftcode.expire_at:sub(6, 7)),
                day = tonumber(giftcode.expire_at:sub(9, 10))
            })
            if os.time() > expire_time then
                TriggerClientEvent('ox_lib:notify', src, { description = Config.Notify['has_expired'], type = 'error' })
                print(("[Edge System] ⏰ Código expirado: %s"):format(code))
                return
            end
        end

        if Config.LimitRedeem and giftcode.current_redeem >= giftcode.max_redeem then
            TriggerClientEvent('ox_lib:notify', src, { description = Config.Notify['usage_limit'], type = 'error' })
            print(("[Edge System] ❌ Código atingiu limite: %s"):format(code))
            return
        end

        if Config.CheckUserRedeem then
            local checkQuery = 'SELECT * FROM edge_user_giftcodes WHERE identifier = @identifier AND code = @code'
            local checkParams = { ['@identifier'] = identifier, ['@code'] = code }

            exports.oxmysql:fetch(checkQuery, checkParams, function(result)
                if #result > 0 then
                    TriggerClientEvent('ox_lib:notify', src, { description = Config.Notify['already_used'], type = 'error' })
                    print(("[Edge System] ⚠️ %s já usou o código %s"):format(identifier, code))
                    return
                end

                exports.oxmysql:insert('INSERT INTO edge_user_giftcodes (identifier, code) VALUES (@identifier, @code)', checkParams)
                redeemGiftcode(frameworkPlayer, giftcode)
            end)
        else
            redeemGiftcode(frameworkPlayer, giftcode)
        end
    end

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
