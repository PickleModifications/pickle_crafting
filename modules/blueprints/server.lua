Blueprints = {}

function GetPlayerBlueprint(source, name)
    return (Blueprints[source] and Blueprints[source][name] or false)
end

function SetPlayerBlueprint(source, name, enabled)
    InitializeBlueprints(source, function()
        local identifier = GetIdentifier(source)
        Blueprints[source][name] = enabled or nil
        TriggerClientEvent("pickle_crafting:updateBlueprints", source, Blueprints[source])
        MySQL.Async.fetchAll("SELECT * FROM player_blueprints WHERE identifier=@identifier;", {["@identifier"] = identifier}, 
        function(results)
            if not results[1] then 
                MySQL.Async.execute("INSERT INTO player_blueprints (identifier, blueprints) VALUES (@identifier, @blueprints);", {
                    ["@identifier"] = identifier,
                    ["@blueprints"] = json.encode(Blueprints[source])
                })
            else
                MySQL.Async.execute("UPDATE player_blueprints SET blueprints=@blueprints WHERE identifier=@identifier;", {
                    ["@identifier"] = identifier,
                    ["@blueprints"] = json.encode(Blueprints[source])
                })
            end
        end)
    end)
end

function InitializeBlueprints(source, cb)
    if Blueprints[source] then
        return cb()
    end
    local identifier = GetIdentifier(source)
    MySQL.Async.fetchAll("SELECT * FROM player_blueprints WHERE identifier=@identifier;", {["@identifier"] = identifier}, function(results)
        if not results[1] then 
            Blueprints[source] = {}
        else
            Blueprints[source] = json.decode(results[1].blueprints) or {}
        end
        TriggerClientEvent("pickle_crafting:updateBlueprints", source, Blueprints[source])
        if cb then 
            cb(Blueprints[source])
        end
    end)
end

RegisterNetEvent("pickle_crafting:learnBlueprint", function(index)
    local source = source
    local blueprint = Config.Blueprints[index]
    if GetPlayerBlueprint(source, index) then 
        ShowNotification(source, _L("blueprint_have"))
        return
    end
    if blueprint.item then 
        if Inventory.GetItemCount(source, blueprint.item) < 1 then 
            ShowNotification(source, _L("blueprint_not"))
            return
        end
        if blueprint.remove then 
            Inventory.RemoveItem(source, blueprint.item, 1)
        end
    end 
    ShowNotification(source, _L("blueprint_learned"))
    SetPlayerBlueprint(source, index, true)
end)

for k,v in pairs(Config.Blueprints) do 
    if v.item then 
        RegisterUsableItem(v.item, function(source)
            if GetPlayerBlueprint(source, k) then 
                ShowNotification(source, _L("blueprint_have"))
                return
            end
            TriggerClientEvent("pickle_crafting:learnBlueprint", source, k)
        end)
    end
end