local ESX = exports.es_extended:getSharedObject()

local robberyState = {}

local function notify(source, description, type)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Rabunek domu',
        description = description,
        type = type or 'inform'
    })
end

local function getHouseById(houseId)
    for _, house in ipairs(Config.Houses) do
        if house.id == houseId then
            return house
        end
    end
end

local function countPolice()
    local players = ESX.GetExtendedPlayers()
    local amount = 0

    for _, xPlayer in pairs(players) do
        if xPlayer.job and xPlayer.job.name == 'police' then
            amount = amount + 1
        end
    end

    return amount
end

local function getState(houseId)
    if not robberyState[houseId] then
        robberyState[houseId] = {
            cooldown = 0,
            activeRobber = nil,
            searchedSpots = {}
        }
    end

    return robberyState[houseId]
end

local function randomReward()
    local available = {}

    for _, reward in ipairs(Config.Rewards) do
        if math.random(1, 100) <= reward.chance then
            available[#available + 1] = {
                item = reward.item,
                count = math.random(reward.min, reward.max)
            }
        end
    end

    if #available == 0 then
        return nil
    end

    return available[math.random(1, #available)]
end

lib.callback.register('house_robbery:server:tryStartRobbery', function(source, houseId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local house = getHouseById(houseId)

    if not xPlayer or not house then
        return false
    end

    local state = getState(houseId)
    local currentTime = os.time()
    local hour = tonumber(os.date('%H'))

    if not Config.IsAllowedHour(hour) then
        notify(source, 'Ten dom mozesz obrabiac tylko noca.', 'error')
        return false
    end

    if state.activeRobber and state.activeRobber ~= source then
        notify(source, 'Ktos juz jest w tym domu.', 'error')
        return false
    end

    if state.cooldown > currentTime then
        local minutes = math.ceil((state.cooldown - currentTime) / 60)
        notify(source, ('Ten dom jest spalony. Wroc za %s min.'):format(minutes), 'error')
        return false
    end

    if countPolice() < Config.RequiredPolice then
        notify(source, ('Za malo policji na sluzbie. Wymagane: %s'):format(Config.RequiredPolice), 'error')
        return false
    end

    local itemCount = exports.ox_inventory:Search(source, 'count', Config.RequiredItem)
    if itemCount < 1 then
        notify(source, ('Potrzebujesz przedmiotu: %s'):format(Config.RequiredItem), 'error')
        return false
    end

    exports.ox_inventory:RemoveItem(source, Config.RequiredItem, 1)

    state.activeRobber = source
    state.searchedSpots = {}
    notify(source, 'Zamek puscil. Masz malo czasu, wiec dzialaj szybko.', 'success')
    return true
end)

lib.callback.register('house_robbery:server:searchSpot', function(source, houseId, spotIndex)
    local xPlayer = ESX.GetPlayerFromId(source)
    local house = getHouseById(houseId)

    if not xPlayer or not house then
        return { success = false, message = 'Cos poszlo nie tak.' }
    end

    local state = getState(houseId)
    if state.activeRobber ~= source then
        return { success = false, message = 'Nie rabujesz teraz tego domu.' }
    end

    if state.searchedSpots[spotIndex] then
        return { success = false, message = 'To miejsce juz zostalo przeszukane.' }
    end

    state.searchedSpots[spotIndex] = true

    local reward = randomReward()
    if not reward then
        return { success = false, message = 'Nic wartosciowego tu nie bylo.' }
    end

    local canCarry = exports.ox_inventory:CanCarryItem(source, reward.item, reward.count)
    if not canCarry then
        return { success = false, message = 'Nie masz miejsca w ekwipunku.' }
    end

    exports.ox_inventory:AddItem(source, reward.item, reward.count)
    return {
        success = true,
        message = ('Zdobywasz %sx %s.'):format(reward.count, reward.item)
    }
end)

RegisterNetEvent('house_robbery:server:finishRobbery', function(houseId)
    local source = source
    local state = getState(houseId)

    if state.activeRobber ~= source then
        return
    end

    state.activeRobber = nil
    state.cooldown = os.time() + Config.RobberyCooldown
    state.searchedSpots = {}
end)

AddEventHandler('playerDropped', function()
    local source = source

    for _, state in pairs(robberyState) do
        if state.activeRobber == source then
            state.activeRobber = nil
            state.cooldown = os.time() + Config.RobberyCooldown
            state.searchedSpots = {}
        end
    end
end)
