if GetResourceState('ox_target') == 'started' or GetResourceState('qb-target') ~= 'started' or not Config.EnableTarget then return end

function GetModels()
    local models = {}
    for k,v in pairs(Config.TableTypes) do 
        if v.model then 
            table.insert(models, v.model)
        end
    end
    return models
end

function InteractTarget(tableIndex)
    if not tableIndex or not Tables[tableIndex] then 
        return ShowNotification("This is not a place where you can craft.")
    end
    local table = Tables[tableIndex]
    if table.activeFire then
        TriggerServerEvent("pickle_crafting:stopFire", tableIndex)
        Config.ExtinguishFire(tableIndex, table.coords)
    else
        ShowCraftingUI(tableIndex)
    end
end

function RemoveTarget(tableIndex)
    if not tableIndex or not Tables[tableIndex] or Tables[tableIndex].static or Tables[tableIndex].activeFire then 
        return ShowNotification("This is not a table you can remove.")
    end
    TriggerServerEvent("pickle_crafting:removeTable", tableIndex)
end


function InitTarget()
    local models = GetModels()
    local optionsNames = { 'Crafting Station', 'Pickup Crafting Station' }
    local options = {
        {
            type = "client",
            name = 'pickle_crafting:interactTarget',
            event = 'pickle_crafting:interactTarget',
            label = 'Crafting Station',
        },
        {
            type = "client",
            name = 'pickle_crafting:removeTarget',
            event = 'pickle_crafting:removeTarget',
            label = 'Pickup Crafting Station',
        },
    }

    exports['qb-target']:RemoveTargetModel(models, optionsNames)
    exports['qb-target']:AddTargetModel(models, {options = options, distance = 2.5})

    for k,v in pairs(Config.Tables) do 
        local cfg = Config.TableTypes[v.tableType or "default"]
        if not cfg.model then 
            exports['qb-target']:AddCircleZone("crafting_coord_" .. k, v.coords, 0.2, {name = "crafting_coord_" .. k}, {
                options = {
                    {
                        type = "client",
                        name = 'pickle_crafting:interactCoordsTarget',
                        event = 'pickle_crafting:interactCoordsTarget',
                        label = 'Crafting Station',
                    },
                    {
                        type = "client",
                        name = 'pickle_crafting:removeCoordsTarget',
                        event = 'pickle_crafting:removeCoordsTarget',
                        label = 'Pickup Crafting Station',
                    },
                },
            })
        end
    end

    RegisterNetEvent("pickle_crafting:interactTarget", function(data)
        local tableIndex = GetTableFromEntity(data.entity)
        InteractTarget(tableIndex)
    end)
    
    RegisterNetEvent("pickle_crafting:removeTarget", function(data)
        local tableIndex = GetTableFromEntity(data.entity)
        RemoveTarget(tableIndex)
    end)

    -- Coords

    RegisterNetEvent("pickle_crafting:interactCoordsTarget", function(data)
        local tableIndex = GetClosestTable(data.coords)
        InteractTarget(tableIndex)
    end)
    
    RegisterNetEvent("pickle_crafting:removeCoordsTarget", function(data)
        local tableIndex = GetClosestTable(data.coords)
        RemoveTarget(tableIndex)
    end)
end

InitTarget()