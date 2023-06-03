function StartNextQueue(tableIndex)
    local table = Tables[tableIndex]
    if (not table) then return end
    if (not table.crafting) then return end
    local queue = SortCraftingQueue(Tables[tableIndex].crafting)
    if (#queue < 1) then 
        return
    end
    for i=1, #queue do
        local queueItem = queue[i]
        local queueIndex = queueItem.index
        local item = table.items[queueIndex]
        if (queueItem.finishTime ~= nil and queueItem.finishTime - os.time() <= 0) then 
            if not item.destroyTime or Tables[tableIndex].crafting[queueIndex].cooked then
                return
            end
            Tables[tableIndex].crafting[queueIndex].cooked = true
            ShowNotification(Tables[tableIndex].crafting[queueIndex].source, _L("cooked"))
            SetTimeout(1000 * item.destroyTime, function()
                if Tables[tableIndex] and Tables[tableIndex].crafting[queueIndex] and Tables[tableIndex].crafting[queueIndex].finishTime == queueItem.finishTime then
                    if item.destroyFire then 
                        local source = Tables[tableIndex].crafting[queueIndex].source
                        Tables[tableIndex].activeFire = true
                        ShowNotification(source, _L(item.explodeOnBurn and "exploded" or "destroyed"))
                        Tables[tableIndex].crafting = {}
                        UpdateTables(tableIndex)
                        TriggerClientEvent("pickle_crafting:startCraftingFire", -1, tableIndex, item.explodeOnBurn, source)
                        if not table.static then
                            if item.explodeOnBurn and Config.RemoveTableSettings.explosion then 
                            RemoveTable(tableIndex)
                            elseif not item.explodeOnBurn then
                                SetTimeout(1000 * Config.RemoveTableSettings.fire, function() 
                                    if Tables[tableIndex].activeFire then 
                                        RemoveTable(tableIndex)
                                    end 
                                end)
                            end
                        end
                    else
                        ShowNotification(Tables[tableIndex].crafting[queueIndex].source, _L("burned"))
                        RemoveQueue(tableIndex, index)
                    end
                end
            end)
        elseif (queueItem.finishTime ~= nil) then 
            return
        else
            local quantity = Tables[tableIndex].crafting[queueIndex].quantity
            Tables[tableIndex].crafting[queueIndex].finishTime = os.time() + (quantity * item.time)
            TriggerClientEvent("pickle_crafting:startCraftingQueue", -1, tableIndex, queueIndex, Tables[tableIndex], os.time())
            SetTimeout((1000 * (quantity * item.time)) + 1000, function()
                StartNextQueue(tableIndex)
            end)
            break
        end
    end
    UpdateTables(tableIndex)
    return true
end

function RemoveQueue(tableIndex, index)
    Tables[tableIndex].crafting[index] = nil
    TriggerClientEvent("pickle_crafting:removeCraftingQueue", -1, tableIndex, index)
end

function CheckParts(source, quantity, parts)
    if not parts or #parts < 1 then return true end
    local success = true
    local missingItems = {}
    for i=1, #parts do 
        local part = parts[i]
        if (not part.type or part.type == "item") then
            local remaining = Inventory.GetItemCount(source, part.name) - (part.amount * quantity)
            if remaining < 0 then 
                success = false
                missingItems[#missingItems + 1] = {index = i, name = part.name, count = remaining}
            end
        elseif (part.type == "weapon" and not Inventory.HasWeapon(source, part.name)) then
            success = false
            missingItems[#missingItems + 1] = {index = i, name = part.name, count = remaining}
        end
    end
    return success, missingItems
end

function TakeParts(source, quantity, parts)
    if not parts or #parts < 1 then return end
    for i=1, #parts do 
        local part = parts[i]
        if (part.remove == nil or part.remove) then
            if (not part.type or part.type == "item") then
                Inventory.RemoveItem(source, part.name, part.amount * quantity)
            elseif (part.type == "weapon") then
                Inventory.RemoveWeapon(source, part.name, part.amount * quantity)
            end
        end
    end
end

function GiveParts(source, quantity, parts)
    if not parts or #parts < 1 then return end
    for i=1, #parts do 
        local part = parts[i]
        if (part.remove == nil or part.remove) then
            if (not part.type or part.type == "item") then
                Inventory.AddItem(source, part.name, part.amount * quantity)
            elseif (part.type == "weapon") then
                Inventory.AddWeapon(source, part.name, part.amount * quantity)
            end
        end
    end
end

function CheckRewards(source, quantity, craftingData, rewards)
    local success = true
    local cantCarry = {}
    if (not reward.type or reward.type == "item") and not Inventory.CanCarryItem(source, craftingData.item.name, craftingData.item.amount * quantity) then 
        success = false
        cantCarry[#cantCarry + 1] = {index = 1, name = craftingData.item.name, amount = craftingData.item.amount * quantity}
    elseif (reward.type == "weapon" and Inventory.HasWeapon(source, part.name)) then
        success = false
        cantCarry[#cantCarry + 1] = {index = 1, name = craftingData.item.name, amount = craftingData.item.amount * quantity}
    end
    if not rewards or #rewards < 1 then 
        return success, missingItems 
    end
    for i=1, #rewards do 
        local reward = rewards[i]
        if (not reward.type or reward.type == "item") and not Inventory.CanCarryItem(source, reward.name, reward.amount * quantity) then 
            success = false
            cantCarry[#cantCarry + 1] = {index = i + 1, name = reward.name, amount = reward.amount * quantity}
        end
    end
    return success, missingItems
end

function GiveRewards(source, quantity, craftingData, rewards)
    if craftingData.item.chance then 
        local result = math.random(1, 100)
        if craftingData.item.chance < result then 
            ShowNotification(source, _L("crafting_failed"))
        end
    end
    Inventory.AddItem(source, craftingData.item.name, craftingData.item.amount * quantity, craftingData.item.createItem and craftingData.item.createItem(craftingData) or nil)
    if not rewards or #rewards < 1 then 
        return success, missingItems 
    end
    for i=1, #rewards do 
        local reward = rewards[i]
        if not reward.type or reward.type == "item" then
            Inventory.AddItem(source, reward.name, reward.amount * quantity, reward.createItem and reward.createItem(craftingData) or nil)
        elseif reward.type == "weapon" then
            Inventory.AddWeapon(source, reward.name, reward.amount * quantity, reward.createItem and reward.createItem(craftingData) or nil)
        elseif Config.XPEnabled and reward.type == "xp" then 
            AddPlayerXP(source, reward.name, reward.amount * quantity)
        end
    end
end

RegisterCallback("pickle_crafting:getTime", function(source, cb) 
    cb(os.time())
end)

RegisterCallback("pickle_crafting:canCraft", function(source, cb, tableIndex, index, quantity)
    local source = source
    local table = Tables[tableIndex]
    if (not table) then return cb(false) end
    if (table.crafting and table.crafting[index]) then 
        ShowNotification(source, _L("crafting_already"))
        return cb(false)
    end
    local item = table.items[index]
    if item.blueprint and not GetPlayerBlueprint(source, item.blueprint) then 
        ShowNotification(source, _L("blueprint_not_learned"))
        return cb(false)
    end
    if Config.XPEnabled and item.xp and not (GetPlayerLevel(source, item.xp.name) >= item.xp.level) then 
        ShowNotification(source, _L("xp_not_level"))
        return cb(false)
    end
    if not item.time or item.time <= 0 then 
        local success, missing = CheckParts(source, quantity, item.parts)
        if success then 
            local craftingData = {tableIndex = tableIndex, index = index, tableType = table.tableType, item = item}
            local success, cantCarry = CheckRewards(source, quantity, craftingData, item.rewards)
            if not success then 
                ShowNotification(source, _L("no_room"))
                return cb(false)
            end
        else 
            ShowNotification(source, _L("parts_missing"))
            return cb(false)
        end
    end
    local success, missing = CheckParts(source, quantity, item.parts)
    if not success then 
        ShowNotification(source, _L("parts_missing"))
        return cb(false)
    end
    cb(true)
end)

RegisterNetEvent("pickle_crafting:addCraftingQueue", function(tableIndex, index, quantity)
    local source = source
    local table = Tables[tableIndex]
    if (not table) then return end
    if (table.crafting and table.crafting[index]) then 
        ShowNotification(source, _L("crafting_already"))
        return 
    end
    if (not table.crafting) then Tables[tableIndex].crafting = {} end
    local item = table.items[index]
    if item.blueprint and not GetPlayerBlueprint(source, item.blueprint) then 
        ShowNotification(source, _L("blueprint_not_learned"))
        return
    end
    if Config.XPEnabled and item.xp and not (GetPlayerLevel(source, item.xp.name) >= item.xp.level) then 
        ShowNotification(source, _L("xp_not_level"))
        return
    end
    if not item.time or item.time <= 0 then 
        local success, missing = CheckParts(source, quantity, item.parts)
        if success then 
            local craftingData = {tableIndex = tableIndex, index = index, tableType = table.tableType, item = item}
            local success, cantCarry = CheckRewards(source, quantity, craftingData, item.rewards)
            if success then 
                TakeParts(source, quantity, item.parts)
                GiveRewards(source, quantity, craftingData, item.rewards)
            else 
                ShowNotification(source, _L("no_room"))
            end
        else 
            ShowNotification(source, _L("parts_missing"))
        end
        return
    end
    local success, missing = CheckParts(source, quantity, item.parts)
    if success then 
        TakeParts(source, quantity, item.parts)
    else 
        ShowNotification(source, _L("parts_missing"))
        return
    end
    Tables[tableIndex].crafting[index] = {
        source = source,
        quantity = quantity,
        queueTime = os.time()
    }
    local queue = SortCraftingQueue(Tables[tableIndex].crafting)
    if #queue == 1 then 
        Tables[tableIndex].crafting[index].finishTime = os.time() + (quantity * item.time)
        TriggerClientEvent("pickle_crafting:startCraftingQueue", -1, tableIndex, index, Tables[tableIndex], os.time())
        SetTimeout((1000 * (quantity * item.time)) + 1000, function()
            StartNextQueue(tableIndex)
        end)
    else
        TriggerClientEvent("pickle_crafting:addCraftingQueue", -1, tableIndex, index, Tables[tableIndex])
    end
    UpdateTables(tableIndex)
end)

RegisterNetEvent("pickle_crafting:removeCraftingQueue", function(tableIndex, index)
    local source = source
    local table = Tables[tableIndex]
    if not table then return end
    local item = table.items[index]
    if not item then return end
    local crafting = table.crafting[index]
    if not crafting then return end
    if crafting.source ~= source and Table.TheftDistance > 0 and (#(GetEntityCoords(PlayerPedId()) - table.coords) > Table.TheftDistance) then
        ShowNotification(source, _L("crafting_player_near"))
        return
    end
    RemoveQueue(tableIndex, index)
    GiveParts(source, crafting.quantity, item.parts)
    if not StartNextQueue(tableIndex) then
        UpdateTables(tableIndex)
    end
end)

RegisterNetEvent("pickle_crafting:collectCraftingQueue", function(tableIndex, index)
    local source = source
    local table = Tables[tableIndex]
    if not table then return end
    local item = table.items[index]
    if not item then return end
    local crafting = table.crafting[index]
    if not crafting then return end
    local craftingData = {tableIndex = tableIndex, index = index, tableType = table.tableType, item = item}
    RemoveQueue(tableIndex, index)
    GiveRewards(source, crafting.quantity, craftingData, item.rewards)
    if not StartNextQueue(tableIndex) then
        UpdateTables(tableIndex)
    end
end)