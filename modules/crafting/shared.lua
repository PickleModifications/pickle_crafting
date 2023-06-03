function SortCraftingQueue(queue)
    local array = {}
    for k,v in pairs(queue) do 
        local data = v
        data.index = k
        array[#array + 1] = data
    end
    table.sort(array, function(a, b) return a.queueTime < b.queueTime end)
    return array
end