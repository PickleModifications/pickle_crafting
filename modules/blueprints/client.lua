Blueprints = {}

function GetBlueprint(name)
    return (Blueprints and Blueprints[name] or false)
end 

function GetBlueprints()
    local data = {}
    for k,v in pairs(Config.Blueprints) do 
        data[k] = {
            item = v.item,
            remove = v.remove,
            label = v.label,
            image = v.image,
            enabled = GetBlueprint(k)
        }
    end
    return data
end

RegisterNetEvent("pickle_crafting:updateBlueprints", function(blueprints)
    Blueprints = blueprints
end)

RegisterNetEvent("pickle_crafting:learnBlueprint", function(index)
    local cfg = Config.Blueprints[index]
    if (cfg.learnBlueprint and cfg.learnBlueprint(index)) or (not cfg.learnBlueprint and Config.LearnBlueprint and Config.LearnBlueprint(index)) then
        TriggerServerEvent("pickle_crafting:learnBlueprint", index)
    end
end)