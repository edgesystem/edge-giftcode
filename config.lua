Config = {}

Config.Framework = 'QBCore' -- ou 'ESX'
Config.CheckUserRedeem = true   -- Impede o mesmo player de usar o código mais de uma vez
Config.LimitRedeem = true       -- Limita o número total de usos do código
Config.ExpireGiftcode = true    -- Ativa o sistema de expiração
Config.AllowedGroup = 'admin'   -- Permissão mínima para criar códigos
Config.Inventory = 'ox_inventory' -- Suporte a ox_inventory / qb-inventory / ps-inventory


Config.Notify = {
    ['cancelled_create'] = 'A criação do código de presente foi cancelada.',
    ['no_perm'] = 'Você não tem permissão para usar este comando.',
    ['invalid_date'] = 'Formato de data inválido',
    ['create_success'] = 'Código de presente criado com sucesso.',
    ['enter_success'] = 'Código de presente inserido com sucesso.',
    ['cannot_create'] = 'Não é possível criar o código de presente.',
    ['has_expired'] = 'O código de presente expirou',
    ['usage_limit'] = 'O código de presente atingiu seu limite de uso',
    ['already_used'] = 'Você já usou este código de presente',
    ['giftcode_invalid'] = 'Código de presente inválido ou já foi usado',
    ['received_reward'] = 'Você recebeu sua recompensa %s %s',
    ['received_vehicle'] = 'Você recebeu seu veículo %s',
    ['invalid_reward'] = 'Tipo de recompensa inválido.',
    ['unable_update'] = 'Não foi possível atualizar o número de usos do código de presente.',
}