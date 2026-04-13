local ESX = exports.es_extended:getSharedObject()
ESX.PlayerData = ESX.GetPlayerData() or {}

local activeHouse
local activeContract
local robberyState = {
    active = false,
    searched = 0,
    total = 0,
    loot = 0,
    alarm = false,
    expiresAt = 0
}

local entryTargetHandles = {}
local robberyTargetHandles = {}
local brokerTargetHandle
local contractBlip
local brokerPed

local function notify(description, type)
    lib.notify({
        title = 'Rabunek domu',
        description = description,
        type = type or 'inform'
    })
end

local function setUiVisible(visible, payload)
    SendNUIMessage({
        action = visible and 'show' or 'hide',
        data = payload
    })
end

local function updateUi()
    if not activeHouse then
        setUiVisible(false)
        return
    end

    local remaining = math.max(0, robberyState.expiresAt - GetGameTimer())
    setUiVisible(true, {
        label = activeHouse.label,
        owner = activeHouse.owner,
        street = activeHouse.street,
        tier = activeHouse.tier,
        searched = robberyState.searched,
        total = robberyState.total,
        loot = robberyState.loot,
        alarm = robberyState.alarm,
        timer = math.ceil(remaining / 1000)
    })
end

local function getClosestHouse(coords)
    local closestHouse, closestDistance

    for _, house in ipairs(Config.Houses) do
        local distance = #(coords - house.entry)
        if not closestDistance or distance < closestDistance then
            closestHouse = house
            closestDistance = distance
        end
    end

    return closestHouse, closestDistance
end

local function getClosestSpot(coords)
    if not activeHouse then
        return nil, nil, nil
    end

    local closestSpot, closestIndex, closestDistance

    for index, spot in ipairs(activeHouse.spots) do
        local distance = #(coords - spot.coords)
        if not closestDistance or distance < closestDistance then
            closestSpot = spot
            closestIndex = index
            closestDistance = distance
        end
    end

    return closestSpot, closestIndex, closestDistance
end

local function drawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then
        return
    end

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 220)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function pulseAlarm(enabled)
    robberyState.alarm = enabled or robberyState.alarm
    updateUi()

    if robberyState.alarm then
        PlaySoundFrontend(-1, '5_Second_Timer', 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', true)
    end
end

local function clearObjectiveBlip()
    if contractBlip and DoesBlipExist(contractBlip) then
        RemoveBlip(contractBlip)
    end

    contractBlip = nil
end

local function setObjectiveBlip(contract)
    clearObjectiveBlip()

    if not contract or not contract.entry then
        return
    end

    contractBlip = AddBlipForCoord(contract.entry.x, contract.entry.y, contract.entry.z)
    SetBlipSprite(contractBlip, 40)
    SetBlipScale(contractBlip, 0.85)
    SetBlipColour(contractBlip, 5)
    SetBlipRoute(contractBlip, true)
    SetBlipRouteColour(contractBlip, 5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(('Kontrakt: %s'):format(contract.label))
    EndTextCommandSetBlipName(contractBlip)
end

local function setContract(contract, silent)
    activeContract = contract

    if contract then
        setObjectiveBlip(contract)
        if not silent then
            notify(('Nowy kontrakt: %s'):format(contract.label), 'success')
        end
    else
        clearObjectiveBlip()
    end
end

local function clearEntryTargets()
    if not Config.UseTarget then
        return
    end

    for _, id in ipairs(entryTargetHandles) do
        exports.ox_target:removeZone(id)
    end

    entryTargetHandles = {}
end

local function clearRobberyTargets()
    if not Config.UseTarget then
        return
    end

    for _, id in ipairs(robberyTargetHandles) do
        exports.ox_target:removeZone(id)
    end

    robberyTargetHandles = {}
end

local function finishLocalRobbery()
    activeHouse = nil
    robberyState = {
        active = false,
        searched = 0,
        total = 0,
        loot = 0,
        alarm = false,
        expiresAt = 0
    }

    clearRobberyTargets()
    setUiVisible(false)
end

local function canInteractHouse(house)
    if not Config.RequireContract then
        return true
    end

    return activeContract and activeContract.houseId == house.id
end

local function createHouseTargets()
    if not Config.UseTarget then
        return
    end

    clearEntryTargets()

    for _, house in ipairs(Config.Houses) do
        entryTargetHandles[#entryTargetHandles + 1] = exports.ox_target:addSphereZone({
            coords = house.entry,
            radius = 1.2,
            debug = false,
            options = {
                {
                    icon = 'fa-solid fa-user-ninja',
                    label = ('Wlam do %s'):format(house.label),
                    canInteract = function()
                        return canInteractHouse(house)
                    end,
                    onSelect = function()
                        TriggerEvent('house_robbery:client:enterHouse', house.id)
                    end
                }
            }
        })
    end
end

local function createRobberyTargets(house)
    if not Config.UseTarget then
        return
    end

    clearRobberyTargets()

    robberyTargetHandles[#robberyTargetHandles + 1] = exports.ox_target:addSphereZone({
        coords = house.exit,
        radius = 1.2,
        debug = false,
        options = {
            {
                icon = 'fa-solid fa-right-from-bracket',
                label = 'Wyjdz z domu',
                onSelect = function()
                    TriggerEvent('house_robbery:client:leaveHouse')
                end
            }
        }
    })

    for index, spot in ipairs(house.spots) do
        robberyTargetHandles[#robberyTargetHandles + 1] = exports.ox_target:addSphereZone({
            coords = spot.coords,
            radius = 0.9,
            debug = false,
            options = {
                {
                    icon = spot.safe and 'fa-solid fa-vault' or 'fa-solid fa-box-open',
                    label = ('Przeszukaj: %s'):format(Config.GetSpotLabel(spot.label)),
                    canInteract = function()
                        return activeHouse and not spot.done
                    end,
                    onSelect = function()
                        TriggerEvent('house_robbery:client:searchSpot', index)
                    end
                }
            }
        })
    end
end

local function runSkillcheck(sequence)
    return lib.skillCheck(sequence, { 'w', 'a', 's', 'd' })
end

local function getHouseById(houseId)
    for _, house in ipairs(Config.Houses) do
        if house.id == houseId then
            return house
        end
    end
end

local function refreshContract(silent)
    local contract = lib.callback.await('house_robbery:server:getContract', false)
    setContract(contract, silent)
end

local function openBrokerMenu()
    local options = {
        {
            title = 'Wez nowe zlecenie',
            description = 'Broker przypisze Ci wolny dom do obrabowania.',
            icon = 'user-secret',
            onSelect = function()
                local response = lib.callback.await('house_robbery:server:requestContract', false)
                if not response or not response.success then
                    notify((response and response.message) or 'Nie udalo sie pobrac kontraktu.', 'error')
                    return
                end

                setContract(response.contract)
                SetNewWaypoint(response.contract.entry.x, response.contract.entry.y)

                if response.reused then
                    notify('Masz juz aktywny kontrakt. Wyznaczam Ci trase.', 'inform')
                else
                    notify(('Dostales robote na: %s'):format(response.contract.label), 'success')
                end
            end
        }
    }

    if activeContract then
        options[#options + 1] = {
            title = 'Pokaz aktywny kontrakt',
            description = ('Cel: %s | %s'):format(activeContract.label, activeContract.street),
            icon = 'location-dot',
            onSelect = function()
                setObjectiveBlip(activeContract)
                SetNewWaypoint(activeContract.entry.x, activeContract.entry.y)
                notify('Trasa do kontraktu ustawiona.', 'inform')
            end
        }

        options[#options + 1] = {
            title = 'Anuluj kontrakt',
            description = 'Usuwa aktualne zlecenie i odblokowuje nowe.',
            icon = 'xmark',
            onSelect = function()
                lib.callback.await('house_robbery:server:cancelContract', false)
                setContract(nil)
                notify('Kontrakt anulowany.', 'inform')
            end
        }
    end

    lib.registerContext({
        id = 'house_robbery_broker',
        title = 'Broker zlecen',
        options = options
    })

    lib.showContext('house_robbery_broker')
end

local function spawnBrokerPed()
    if not Config.UseMissionBroker then
        return
    end

    if brokerPed and DoesEntityExist(brokerPed) then
        return
    end

    local model = joaat(Config.MissionBroker.ped)
    lib.requestModel(model, 10000)

    brokerPed = CreatePed(0, model, Config.MissionBroker.coords.x, Config.MissionBroker.coords.y, Config.MissionBroker.coords.z - 1.0, Config.MissionBroker.heading, false, true)
    SetEntityAsMissionEntity(brokerPed, true, true)
    SetEntityInvincible(brokerPed, true)
    FreezeEntityPosition(brokerPed, true)
    SetBlockingOfNonTemporaryEvents(brokerPed, true)

    if Config.MissionBroker.scenario and Config.MissionBroker.scenario ~= '' then
        TaskStartScenarioInPlace(brokerPed, Config.MissionBroker.scenario, 0, true)
    end

    if Config.UseTarget then
        brokerTargetHandle = exports.ox_target:addSphereZone({
            coords = Config.MissionBroker.coords,
            radius = 1.3,
            debug = false,
            options = {
                {
                    icon = Config.MissionBroker.icon,
                    label = 'Otworz zlecenia',
                    onSelect = function()
                        openBrokerMenu()
                    end
                }
            }
        })
    end
end

local function enterHouse(houseId)
    local house = getHouseById(houseId)
    if not house or activeHouse then
        return
    end

    if Config.RequireContract and (not activeContract or activeContract.houseId ~= house.id) then
        notify('Najpierw wez kontrakt na ten dom.', 'error')
        return
    end

    local lockpickPassed = runSkillcheck(Config.LockpickSkillcheck)
    if not lockpickPassed then
        notify('Lockpick pekl. Musisz sprobowac jeszcze raz.', 'error')
        local failResult = lib.callback.await('house_robbery:server:onFailedEntry', false, house.id)
        if failResult and failResult.alarm then
            pulseAlarm(true)
            notify('Alarm odpalil sie po nieudanej probie.', 'error')
        end
        return
    end

    local success = lib.progressCircle({
        duration = Config.EntryDuration,
        position = 'bottom',
        label = 'Ciche obchodzenie zamka...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            combat = true,
            move = true
        },
        anim = {
            dict = 'mini@safe_cracking',
            clip = 'dial_turn_anti_fast_1'
        }
    })

    if not success then
        notify('Przerwano wejscie.', 'error')
        return
    end

    local result = lib.callback.await('house_robbery:server:tryStartRobbery', false, house.id)
    if not result or not result.success then
        return
    end

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    SetEntityCoords(cache.ped, house.shell.x, house.shell.y, house.shell.z, false, false, false, false)
    SetEntityHeading(cache.ped, house.shell.w)

    Wait(350)
    DoScreenFadeIn(500)

    activeHouse = house
    robberyState.active = true
    robberyState.searched = 0
    robberyState.total = #house.spots
    robberyState.loot = 0
    robberyState.alarm = result.session.alarmTriggered
    robberyState.expiresAt = GetGameTimer() + (result.session.duration * 1000)

    for _, spot in ipairs(activeHouse.spots) do
        spot.done = false
    end

    createRobberyTargets(house)
    updateUi()

    notify('Jestes w srodku. Bierz loot i pilnuj czasu.', 'success')

    if result.session.alarmTriggered then
        pulseAlarm(true)
        notify('Alarm jest aktywny. Policja moze byc juz w drodze.', 'error')
    end
end

local function leaveHouse()
    if not activeHouse then
        return
    end

    local houseId = activeHouse.id
    local success = lib.progressCircle({
        duration = Config.ExitDuration,
        position = 'bottom',
        label = 'Wychodzenie z posesji...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            combat = true,
            move = true
        }
    })

    if not success then
        return
    end

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    SetEntityCoords(cache.ped, activeHouse.entry.x, activeHouse.entry.y, activeHouse.entry.z, false, false, false, false)
    SetEntityHeading(cache.ped, 0.0)

    Wait(350)
    DoScreenFadeIn(500)

    TriggerServerEvent('house_robbery:server:finishRobbery', houseId)
    finishLocalRobbery()
    setContract(nil)
    notify('Wyszedles z domu i zamknales kontrakt.', 'inform')
end

local function searchSpot(index)
    if not activeHouse then
        return
    end

    local spot = activeHouse.spots[index]
    if not spot or spot.done then
        return
    end

    local passedSkillcheck = runSkillcheck(spot.difficulty or Config.SearchSkillcheck)
    if not passedSkillcheck then
        notify('Za glosno. Szukanie nie wyszlo.', 'error')
        local failResult = lib.callback.await('house_robbery:server:onFailedSearch', false, activeHouse.id, spot.id)
        if failResult and failResult.alarm then
            pulseAlarm(true)
            notify('Nieudane przeszukanie wzbudzilo alarm.', 'error')
        end
        return
    end

    local success = lib.progressCircle({
        duration = spot.duration or Config.SearchDuration,
        position = 'bottom',
        label = spot.safe and 'Lamanie sejfu...' or ('Przeszukiwanie: %s'):format(Config.GetSpotLabel(spot.label)),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            combat = true,
            move = true
        },
        anim = {
            dict = 'amb@prop_human_bum_bin@idle_b',
            clip = 'idle_d'
        }
    })

    if not success then
        notify('Przeszukiwanie anulowane.', 'error')
        return
    end

    if spot.safe and not runSkillcheck(Config.SafeSkillcheck) then
        notify('Sejf nie puscil.', 'error')
        local failResult = lib.callback.await('house_robbery:server:onFailedSearch', false, activeHouse.id, spot.id)
        if failResult and failResult.alarm then
            pulseAlarm(true)
        end
        return
    end

    local result = lib.callback.await('house_robbery:server:searchSpot', false, activeHouse.id, spot.id)
    if not result then
        return
    end

    if result.alarm then
        pulseAlarm(true)
    end

    if not result.success then
        notify(result.message or 'Nic nie znaleziono.', 'error')
        return
    end

    spot.done = true
    robberyState.searched = robberyState.searched + 1
    robberyState.loot = robberyState.loot + (result.totalItems or 0)
    updateUi()

    notify(result.message or 'Loot zabrany.', 'success')
end

RegisterNetEvent('house_robbery:client:enterHouse', enterHouse)
RegisterNetEvent('house_robbery:client:leaveHouse', leaveHouse)
RegisterNetEvent('house_robbery:client:searchSpot', searchSpot)

RegisterNetEvent('house_robbery:client:alarmTriggered', function(houseId, reason)
    if activeHouse and activeHouse.id == houseId then
        pulseAlarm(true)
    end

    notify(reason or 'Alarm zostal aktywowany.', 'error')
end)

RegisterNetEvent('house_robbery:client:policeAlert', function(data)
    local playerJob = ESX.PlayerData and ESX.PlayerData.job
    if not playerJob or playerJob.name ~= Config.DispatchJob then
        return
    end

    lib.notify({
        id = ('house-robbery-%s'):format(data.houseId),
        title = 'Wlamanie do domu',
        description = ('%s | %s'):format(data.street, data.label),
        icon = 'house',
        duration = 15000,
        position = 'top'
    })

    SetNewWaypoint(data.coords.x, data.coords.y)
end)

RegisterNetEvent('esx:setJob', function(job)
    ESX.PlayerData.job = job
end)

RegisterNetEvent('esx:playerLoaded', function(playerData)
    ESX.PlayerData = playerData or ESX.GetPlayerData() or {}
    refreshContract(true)
    createHouseTargets()
    spawnBrokerPed()
end)

CreateThread(function()
    while true do
        if ESX.IsPlayerLoaded and ESX.IsPlayerLoaded() then
            break
        end

        if ESX.PlayerLoaded then
            break
        end

        Wait(500)
    end

    ESX.PlayerData = ESX.GetPlayerData() or {}
    refreshContract(true)
    createHouseTargets()
    spawnBrokerPed()
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local coords = GetEntityCoords(cache.ped)

        if activeContract and activeContract.expiresAt <= os.time() then
            setContract(nil)
            notify('Kontrakt wygasl. Wroc do brokera po nowy.', 'error')
        end

        if activeHouse then
            updateUi()

            local timeLeft = robberyState.expiresAt - GetGameTimer()
            if timeLeft <= 0 then
                notify('Czas na rabunek minal. Musisz uciekac.', 'error')
                leaveHouse()
                goto continue
            end

            local exitDistance = #(coords - activeHouse.exit)
            if not Config.UseTarget and exitDistance < 7.0 then
                sleep = 0
                DrawMarker(2, activeHouse.exit.x, activeHouse.exit.y, activeHouse.exit.z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.18, 0.18, 0.18, 255, 120, 120, 180, false, true, 2, false, nil, nil, false)
                drawText3D(activeHouse.exit + vec3(0.0, 0.0, 0.3), '[E] Wyjdz')

                if exitDistance < 1.2 and IsControlJustReleased(0, 38) then
                    leaveHouse()
                end
            end

            local spot, spotIndex, spotDistance = getClosestSpot(coords)
            if spot and not Config.UseTarget and spotDistance < 5.0 then
                sleep = 0
                local searched = spot.done
                local color = searched and { 130, 130, 130 } or (spot.safe and { 255, 204, 102 } or { 85, 160, 255 })

                DrawMarker(2, spot.coords.x, spot.coords.y, spot.coords.z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.16, 0.16, 0.16, color[1], color[2], color[3], 200, false, true, 2, false, nil, nil, false)
                drawText3D(spot.coords + vec3(0.0, 0.0, 0.22), searched and 'Przeszukane' or ('[E] %s'):format(Config.GetSpotLabel(spot.label)))

                if not searched and spotDistance < 1.2 and IsControlJustReleased(0, 38) then
                    searchSpot(spotIndex)
                end
            end
        else
            if Config.UseMissionBroker then
                local brokerDistance = #(coords - Config.MissionBroker.coords)
                if not Config.UseTarget and brokerDistance < 8.0 then
                    sleep = 0
                    DrawMarker(2, Config.MissionBroker.coords.x, Config.MissionBroker.coords.y, Config.MissionBroker.coords.z + 0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 255, 215, 90, 180, false, true, 2, false, nil, nil, false)
                    drawText3D(Config.MissionBroker.coords + vec3(0.0, 0.0, 0.45), '[E] Broker zlecen')

                    if brokerDistance < 1.6 and IsControlJustReleased(0, 38) then
                        openBrokerMenu()
                    end
                end
            end

            local house, distance = getClosestHouse(coords)
            if house and distance < 12.0 and not Config.UseTarget then
                sleep = 0
                local canUse = canInteractHouse(house)
                local color = canUse and { 255, 90, 90 } or { 110, 110, 110 }
                local text = canUse and ('[E] Wlam do %s'):format(house.label) or 'Ten dom nie jest z Twojego kontraktu'

                DrawMarker(2, house.entry.x, house.entry.y, house.entry.z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.20, 0.20, 0.20, color[1], color[2], color[3], 200, false, true, 2, false, nil, nil, false)
                drawText3D(house.entry + vec3(0.0, 0.0, 0.35), text)

                if canUse and distance < 1.5 and IsControlJustReleased(0, 38) then
                    enterHouse(house.id)
                end
            end
        end

        ::continue::
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    setUiVisible(false)
    clearEntryTargets()
    clearRobberyTargets()
    clearObjectiveBlip()

    if brokerTargetHandle and Config.UseTarget then
        exports.ox_target:removeZone(brokerTargetHandle)
    end

    if brokerPed and DoesEntityExist(brokerPed) then
        DeleteEntity(brokerPed)
    end
end)
