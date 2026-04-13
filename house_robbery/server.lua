local ESX = exports.es_extended:getSharedObject()

local robberyState = {}

local function notify(source, description, type)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Rabunek domu',
        description = description,
        type = type or 'inform'
    })
end

local function isPlayerNear(source, targetCoords, maxDistance)
    local ped = GetPlayerPed(source)
    if ped <= 0 then
        return false
    end

    local playerCoords = GetEntityCoords(ped)
    return #(playerCoords - targetCoords) <= maxDistance
end

local function getHouseById(houseId)
    for _, house in ipairs(Config.Houses) do
        if house.id == houseId then
            return house
        end
    end
end

local function getSpotById(house, spotId)
    for _, spot in ipairs(house.spots) do
        if spot.id == spotId then
            return spot
        end
    end
end

local function countPolice()
    local players = ESX.GetExtendedPlayers()
    local amount = 0

    for _, xPlayer in pairs(players) do
        if xPlayer.job and xPlayer.job.name == Config.DispatchJob then
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
            searchedSpots = {},
            alarmTriggered = false,
            expiresAt = 0,
            brokenStealth = 0
        }
    end

    return robberyState[houseId]
end

local function getRewardPool(poolName)
    return Config.RewardPools[poolName] or Config.RewardPools.common
end

local function rollRewards(poolName)
    local pool = getRewardPool(poolName)
    local rewards = {}

    for _, reward in ipairs(pool) do
        if math.random(1, 100) <= reward.chance then
            rewards[#rewards + 1] = {
                item = reward.item,
                count = math.random(reward.min, reward.max)
            }
        end
    end

    if #rewards == 0 and pool[1] then
        rewards[1] = {
            item = pool[1].item,
            count = pool[1].min
        }
    end

    return rewards
end

local function buildRewardMessage(rewards)
    local parts = {}

    for _, reward in ipairs(rewards) do
        parts[#parts + 1] = ('%sx %s'):format(reward.count, reward.item)
    end

    return table.concat(parts, ', ')
end

local function policeAlert(house, houseId)
    local players = ESX.GetExtendedPlayers()

    for _, xPlayer in pairs(players) do
        if xPlayer.job and xPlayer.job.name == Config.DispatchJob then
            TriggerClientEvent('house_robbery:client:policeAlert', xPlayer.source, {
                houseId = houseId,
                label = house.label,
                street = house.street,
                coords = { x = house.entry.x, y = house.entry.y, z = house.entry.z }
            })
        end
    end
end

local function triggerAlarm(houseId, reason)
    local house = getHouseById(houseId)
    local state = getState(houseId)
    if not house then
        return false
    end

    if state.alarmTriggered then
        return true
    end

    state.alarmTriggered = true

    if state.activeRobber then
        TriggerClientEvent('house_robbery:client:alarmTriggered', state.activeRobber, houseId, reason)
    end

    policeAlert(house, houseId)
    return true
end

local function registerStealthBreak(houseId, chance, reason)
    local state = getState(houseId)
    state.brokenStealth = state.brokenStealth + 1

    if math.random(1, 100) <= chance then
        return triggerAlarm(houseId, reason)
    end

    if state.brokenStealth >= Config.StealthBreakWindow then
        return triggerAlarm(houseId, 'Za duzo halasu. Alarm zostal aktywowany.')
    end

    return false
end

lib.callback.register('house_robbery:server:tryStartRobbery', function(source, houseId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local house = getHouseById(houseId)

    if not xPlayer or not house then
        return { success = false }
    end

    if not isPlayerNear(source, house.entry, Config.EntryDistance) then
        notify(source, 'Musisz podejsc pod drzwi domu.', 'error')
        return { success = false }
    end

    local state = getState(houseId)
    local currentTime = os.time()
    local hour = tonumber(os.date('%H'))

    if not Config.IsAllowedHour(hour) then
        notify(source, 'Ten dom mozesz obrabiac tylko noca.', 'error')
        return { success = false }
    end

    if state.activeRobber and state.activeRobber ~= source then
        notify(source, 'Ktos juz jest w tym domu.', 'error')
        return { success = false }
    end

    if state.cooldown > currentTime then
        local minutes = math.ceil((state.cooldown - currentTime) / 60)
        notify(source, ('Ten dom jest spalony. Wroc za %s min.'):format(minutes), 'error')
        return { success = false }
    end

    if countPolice() < Config.RequiredPolice then
        notify(source, ('Za malo policji na sluzbie. Wymagane: %s'):format(Config.RequiredPolice), 'error')
        return { success = false }
    end

    local itemCount = exports.ox_inventory:Search(source, 'count', Config.RequiredItem)
    if itemCount < 1 then
        notify(source, ('Potrzebujesz przedmiotu: %s'):format(Config.RequiredItem), 'error')
        return { success = false }
    end

    if not exports.ox_inventory:RemoveItem(source, Config.RequiredItem, 1) then
        notify(source, 'Nie udalo sie zuzyc lockpicka.', 'error')
        return { success = false }
    end

    state.activeRobber = source
    state.searchedSpots = {}
    state.expiresAt = currentTime + Config.RobberyDuration
    state.brokenStealth = 0
    state.alarmTriggered = math.random(1, 100) <= (house.alarmChance or Config.AlarmChance)

    if state.alarmTriggered then
        policeAlert(house, houseId)
    end

    return {
        success = true,
        session = {
            alarmTriggered = state.alarmTriggered,
            duration = Config.RobberyDuration
        }
    }
end)

lib.callback.register('house_robbery:server:onFailedEntry', function(source, houseId)
    local house = getHouseById(houseId)
    if not house or not isPlayerNear(source, house.entry, Config.EntryDistance + 0.5) then
        return { alarm = false }
    end

    local alarm = registerStealthBreak(houseId, Config.AlarmChanceWhenFail, 'Nieudana proba wlamania uruchomila alarm.')
    return { alarm = alarm }
end)

lib.callback.register('house_robbery:server:onFailedSearch', function(source, houseId, spotId)
    local house = getHouseById(houseId)
    local state = getState(houseId)
    if not house or state.activeRobber ~= source then
        return { alarm = false }
    end

    local spot = getSpotById(house, spotId)
    if not spot or not isPlayerNear(source, spot.coords, Config.SearchDistance + 0.5) then
        return { alarm = false }
    end

    local alarm = registerStealthBreak(houseId, Config.AlarmChanceWhenFail, 'Nieudane przeszukanie uruchomilo alarm.')
    return { alarm = alarm }
end)

lib.callback.register('house_robbery:server:searchSpot', function(source, houseId, spotId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local house = getHouseById(houseId)

    if not xPlayer or not house then
        return { success = false, message = 'Cos poszlo nie tak.' }
    end

    local state = getState(houseId)
    if state.activeRobber ~= source then
        return { success = false, message = 'Nie rabujesz teraz tego domu.' }
    end

    if state.expiresAt < os.time() then
        return { success = false, message = 'Za pozno. Okno rabunku juz minelo.' }
    end

    local spot = getSpotById(house, spotId)
    if not spot then
        return { success = false, message = 'Nie znaleziono schowka.' }
    end

    if not isPlayerNear(source, spot.coords, Config.SearchDistance) then
        return { success = false, message = 'Podejdz blizej do miejsca przeszukania.' }
    end

    if state.searchedSpots[spotId] then
        return { success = false, message = 'To miejsce zostalo juz wyczyszczone.' }
    end

    local rewards = rollRewards(spot.rewardPool or house.lootPool)

    for _, reward in ipairs(rewards) do
        if not exports.ox_inventory:CanCarryItem(source, reward.item, reward.count) then
            return { success = false, message = ('Brak miejsca na %s.'):format(reward.item) }
        end
    end

    for _, reward in ipairs(rewards) do
        exports.ox_inventory:AddItem(source, reward.item, reward.count)
    end

    state.searchedSpots[spotId] = true

    local totalItems = 0
    for _, reward in ipairs(rewards) do
        totalItems = totalItems + reward.count
    end

    local alarm = false
    if not state.alarmTriggered and math.random(1, 100) <= math.floor((house.alarmChance or Config.AlarmChance) / 2) then
        alarm = triggerAlarm(houseId, 'System alarmowy wykryl ruch w domu.')
    end

    return {
        success = true,
        alarm = alarm,
        totalItems = totalItems,
        message = ('Zabierasz: %s'):format(buildRewardMessage(rewards))
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
    state.alarmTriggered = false
    state.expiresAt = 0
    state.brokenStealth = 0
end)

AddEventHandler('playerDropped', function()
    local source = source

    for _, state in pairs(robberyState) do
        if state.activeRobber == source then
            state.activeRobber = nil
            state.cooldown = os.time() + Config.RobberyCooldown
            state.searchedSpots = {}
            state.alarmTriggered = false
            state.expiresAt = 0
            state.brokenStealth = 0
        end
    end
end)
