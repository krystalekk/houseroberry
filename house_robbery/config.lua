Config = {}

Config.Debug = false
Config.RequiredPolice = 0
Config.RequiredItem = 'lockpick'
Config.RequiredHourStart = 0
Config.RequiredHourEnd = 24
Config.EntryDistance = 2.5
Config.SearchDistance = 2.0

Config.EntryDuration = 3500
Config.ExitDuration = 2200
Config.SearchDuration = 5500
Config.RobberyDuration = 12 * 60
Config.RobberyCooldown = 45 * 60
Config.AlarmChance = 35
Config.AlarmChanceWhenFail = 75
Config.DispatchJob = 'police'
Config.UseTarget = GetResourceState('ox_target') == 'started'

Config.StealthBreakWindow = 3
Config.SafeSkillcheck = { 'medium', 'medium', 'hard' }
Config.LockpickSkillcheck = { 'easy', 'easy', 'medium' }
Config.SearchSkillcheck = { 'easy', 'medium' }

Config.SearchLabelMap = {
    drawer = 'Szuflada',
    cabinet = 'Szafka',
    bedroom = 'Sypialnia',
    kitchen = 'Kuchnia',
    office = 'Biuro',
    safe = 'Sejf'
}

Config.RewardPools = {
    common = {
        { item = 'goldchain', min = 1, max = 2, chance = 70 },
        { item = 'rolex', min = 1, max = 2, chance = 45 },
        { item = 'diamond_ring', min = 1, max = 1, chance = 25 }
    },
    premium = {
        { item = 'goldchain', min = 2, max = 4, chance = 90 },
        { item = 'rolex', min = 1, max = 3, chance = 60 },
        { item = 'diamond_ring', min = 1, max = 2, chance = 50 }
    },
    safe = {
        { item = 'diamond_ring', min = 1, max = 2, chance = 75 },
        { item = 'rolex', min = 2, max = 4, chance = 85 },
        { item = 'goldchain', min = 3, max = 6, chance = 100 }
    }
}

Config.Houses = {
    {
        id = 'grove_1',
        tier = 'standard',
        label = 'Grove Street 204',
        owner = 'Rodzina Santos',
        street = 'Grove Street',
        alarmName = 'AlarmSat Basic',
        policeRisk = 'Sredni',
        entry = vec3(85.24, -1959.09, 21.12),
        shell = vec4(266.08, -1007.42, -101.01, 357.42),
        exit = vec3(266.08, -1007.42, -101.01),
        alarmChance = 30,
        lootPool = 'common',
        spots = {
            { id = 'drawer_1', label = 'drawer', coords = vec3(265.91, -999.37, -99.01), difficulty = { 'easy', 'easy' }, duration = 4200 },
            { id = 'kitchen_1', label = 'kitchen', coords = vec3(261.64, -1002.52, -99.01), difficulty = { 'easy', 'medium' }, duration = 5000 },
            { id = 'bedroom_1', label = 'bedroom', coords = vec3(259.92, -1004.11, -99.01), difficulty = { 'medium', 'medium' }, duration = 5500 },
            { id = 'cabinet_1', label = 'cabinet', coords = vec3(263.85, -995.74, -99.01), difficulty = { 'medium', 'hard' }, duration = 6000 },
            { id = 'safe_1', label = 'safe', coords = vec3(265.81, -998.39, -99.01), safe = true, rewardPool = 'safe', difficulty = { 'medium', 'hard', 'hard' }, duration = 8000 }
        }
    },
    {
        id = 'mirror_1',
        tier = 'premium',
        label = 'Mirror Park Villa',
        owner = 'Jonathan Wood',
        street = 'West Mirror Drive',
        alarmName = 'Sentinel Secure Pro',
        policeRisk = 'Wysoki',
        entry = vec3(1260.54, -627.31, 68.83),
        shell = vec4(346.52, -1012.41, -99.2, 2.24),
        exit = vec3(346.52, -1012.41, -99.2),
        alarmChance = 45,
        lootPool = 'premium',
        spots = {
            { id = 'office_1', label = 'office', coords = vec3(351.18, -994.76, -99.2), difficulty = { 'medium', 'medium' }, duration = 5200 },
            { id = 'kitchen_1', label = 'kitchen', coords = vec3(345.31, -995.7, -99.2), difficulty = { 'easy', 'medium', 'medium' }, duration = 5500 },
            { id = 'cabinet_1', label = 'cabinet', coords = vec3(338.27, -996.92, -99.2), difficulty = { 'medium', 'hard' }, duration = 6200 },
            { id = 'bedroom_1', label = 'bedroom', coords = vec3(338.08, -1003.52, -99.2), difficulty = { 'hard', 'hard' }, duration = 6800 },
            { id = 'safe_1', label = 'safe', coords = vec3(351.99, -998.58, -99.2), safe = true, rewardPool = 'safe', difficulty = { 'medium', 'hard', 'hard' }, duration = 8500 }
        }
    }
}

function Config.IsAllowedHour(hour)
    return true
end

function Config.GetSpotLabel(spotType)
    return Config.SearchLabelMap[spotType] or 'Schowek'
end
