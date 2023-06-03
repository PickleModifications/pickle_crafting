if GetResourceState('ox_inventory') ~= 'started' then return end

Inventory = {}

Inventory.Items = {}

Inventory.Ready = false

RegisterNetEvent("pickle_crafting:setupInventory", function(data)
    Inventory.Items = data.items
    Inventory.Ready = true
end)

RegisterNetEvent("pickle_crafting:updateInventory", function(inventory) 
    RefreshInventory(inventory)
end)

function InitializeInventory()
end