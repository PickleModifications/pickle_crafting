Tables = {}

function UpdateTables(index, source)
    local data
    if index then 
        data = Tables[index]
    else
        data = Tables
    end
    TriggerClientEvent("pickle_crafting:updateTables", source and source or -1, index, data)
end

function AddTable(data)
    local newIndex
    repeat
        newIndex = math.random(1, 2147483646)
    until not Tables[newIndex]
    local cfg = Config.TableTypes[data.tableType]
    if not cfg then return end
    Tables[newIndex] = {
        static = data.static or false,
        coords = data.coords,
        heading = data.heading,
        tableType = data.tableType,
        item = cfg.item,
        model = cfg.model,
        categories = cfg.categories,
        items = cfg.items,
        bucket = data.bucket
    }
    UpdateTables(newIndex)
    return newIndex
end

function RemoveTable(index)
    Tables[index] = nil
    UpdateTables(index)
end

function InitializePlayer(source)
    TriggerClientEvent("pickle_crafting:setupInventory", source, {items = Inventory.Items})
    InitializeBlueprints(source)
    SetTimeout(1000, function()
        UpdateTables(nil, source)
    end)
end

function AwaitInventory(cb)
    CreateThread(function()
        while not Inventory.Ready do 
            Wait(10)
        end
        print("[Pickle's Crafting] Initialized Inventory")
        cb()
    end)
end

RegisterNetEvent("pickle_crafting:placeTable", function(index, coords, heading) 
    local source = source
    local tableType = Config.TableTypes[index]
    if not index or not coords or not heading then return end
    if not tableType or not tableType.item then return end
    if Inventory.GetItemCount(source, tableType.item) < 1 then return end
    Inventory.RemoveItem(source, tableType.item, 1)
    AddTable({
        coords = coords,
        heading = heading,
        tableType = index,
        bucket = GetPlayerRoutingBucket(source)
    })
end)

RegisterNetEvent("pickle_crafting:initializePlayer", function()
    local source = source
    if not Inventory.Ready then 
        AwaitInventory(function()
            InitializePlayer(source)
        end)
    else
        InitializePlayer(source)
    end
end)

RegisterNetEvent("pickle_crafting:removeTable", function(index)
    local table = Tables[index]
    if not table or table.static then return end
    if (table.crafting) then 
        local crafting = false
        for k,v in pairs(table.crafting) do 
            crafting = true
            break
        end
        if crafting then return end
    end
    if table.item then 
        Inventory.AddItem(source, table.item, 1)
    end
    RemoveTable(index)
end)

RegisterNetEvent("pickle_crafting:stopFire", function(index)
    if not Tables[index] then return end
    Tables[index].activeFire = false
    UpdateTables(index)
end)

RegisterCallback("pickle_crafting:getBucket", function(source, cb)
    cb(GetPlayerRoutingBucket(source))
end)

for i=1, #Config.Tables do 
    local data = Config.Tables[i]
    data.static = true
    local index = AddTable(data)
end

for k,v in pairs(Config.TableTypes) do 
    if v.item then 
        RegisterUsableItem(v.item, function(source)
            TriggerClientEvent("pickle_crafting:placeTable", source, k)
        end)
    end
end

exports("AddTable", AddTable)
exports("RemoveTable", RemoveTable)