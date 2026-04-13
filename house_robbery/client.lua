local ESX = exports.es_extended:getSharedObject()

local activeHouse = nil
local searchedSpots = {}

local function notify(description, type)
    lib.notify({
        title = 'Rabunek domu',
        description = description,
        type = type or 'inform'
    })
end

local function getClosestHouse(coords)
    local closestHouse, closestDistance

    for _, house in ipairs(Config.Houses) do
        local distance = #(coords - house.entrance)
        if not closestDistance or distance < closestDistance then
            closestHouse = house
            closestDistance = distance
        end
    end

    return closestHouse, closestDistance
end

local function getClosestSearchSpot(coords)
    if not activeHouse then
        return nil, nil, nil
    end

    local closestIndex, closestCoords, closestDistance

    for index, spot in ipairs(activeHouse.searchSpots) do
        local distance = #(coords - spot)
        if not closestDistance or distance < closestDistance then
            closestIndex = index
            closestCoords = spot
            closestDistance = distance
        end
    end

    return closestIndex, closestCoords, closestDistance
end

local function drawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then
        return
    end

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function enterHouse(house)
    local success = lib.progressCircle({
        duration = Config.EntryDuration,
        position = 'bottom',
        label = 'Wlamywanie do domu...',
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
        notify('Przerwano wlamanie.', 'error')
        return
    end

    local canEnter = lib.callback.await('house_robbery:server:tryStartRobbery', false, house.id)
    if not canEnter then
        return
    end

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    SetEntityCoords(cache.ped, house.interior.x, house.interior.y, house.interior.z, false, false, false, false)
    SetEntityHeading(cache.ped, house.interior.w)

    Wait(500)
    DoScreenFadeIn(500)

    activeHouse = house
    searchedSpots = {}
    notify('Dostales sie do srodka. Przeszukaj dom i uciekaj.', 'success')
end

local function leaveHouse()
    if not activeHouse then
        return
    end

    local success = lib.progressCircle({
        duration = Config.ExitDuration,
        position = 'bottom',
        label = 'Wychodzenie z domu...',
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
    while not IsScreenFadedOut() do Wait(0) end

    SetEntityCoords(cache.ped, activeHouse.entrance.x, activeHouse.entrance.y, activeHouse.entrance.z, false, false, false, false)
    SetEntityHeading(cache.ped, 0.0)

    Wait(500)
    DoScreenFadeIn(500)

    TriggerServerEvent('house_robbery:server:finishRobbery', activeHouse.id)
    activeHouse = nil
    searchedSpots = {}
    notify('Opusciles dom.', 'inform')
end

local function searchSpot(index)
    if not activeHouse or searchedSpots[index] then
        return
    end

    local success = lib.progressCircle({
        duration = Config.SearchDuration,
        position = 'bottom',
        label = 'Przeszukiwanie...',
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
        notify('Przerwano przeszukiwanie.', 'error')
        return
    end

    local result = lib.callback.await('house_robbery:server:searchSpot', false, activeHouse.id, index)
    if not result then
        return
    end

    searchedSpots[index] = true

    if result.success then
        notify(result.message or 'Znalazles lup.', 'success')
    else
        notify(result.message or 'Nic tu nie bylo.', 'error')
    end
end

CreateThread(function()
    while true do
        local sleep = 1000
        local coords = GetEntityCoords(cache.ped)

        if activeHouse then
            local exitDistance = #(coords - activeHouse.exit)
            if exitDistance < 8.0 then
                sleep = 0
                DrawMarker(2, activeHouse.exit.x, activeHouse.exit.y, activeHouse.exit.z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 200, 60, 60, 180, false, true, 2, false, nil, nil, false)
                drawText3D(activeHouse.exit + vec3(0.0, 0.0, 0.3), '[E] Wyjdz z domu')

                if exitDistance < 1.2 and IsControlJustReleased(0, 38) then
                    leaveHouse()
                end
            end

            local spotIndex, spotCoords, spotDistance = getClosestSearchSpot(coords)
            if spotIndex and spotDistance < 6.0 then
                sleep = 0
                local searched = searchedSpots[spotIndex]
                local color = searched and { 120, 120, 120 } or { 60, 160, 255 }

                DrawMarker(2, spotCoords.x, spotCoords.y, spotCoords.z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.17, 0.17, 0.17, color[1], color[2], color[3], 180, false, true, 2, false, nil, nil, false)

                if searched then
                    drawText3D(spotCoords + vec3(0.0, 0.0, 0.25), 'Juz przeszukane')
                else
                    drawText3D(spotCoords + vec3(0.0, 0.0, 0.25), '[E] Przeszukaj')
                    if spotDistance < 1.2 and IsControlJustReleased(0, 38) then
                        searchSpot(spotIndex)
                    end
                end
            end
        else
            local house, distance = getClosestHouse(coords)
            if house and distance < 10.0 then
                sleep = 0
                DrawMarker(2, house.entrance.x, house.entrance.y, house.entrance.z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 255, 90, 90, 180, false, true, 2, false, nil, nil, false)
                drawText3D(house.entrance + vec3(0.0, 0.0, 0.35), ('[E] Wlam do: %s'):format(house.label))

                if distance < 1.5 and IsControlJustReleased(0, 38) then
                    enterHouse(house)
                end
            end
        end

        Wait(sleep)
    end
end)
