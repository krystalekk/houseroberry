Config = {}

Config.RequiredPolice = 0
Config.RobberyCooldown = 45 * 60
Config.SearchDuration = 7000
Config.EntryDuration = 5000
Config.ExitDuration = 2500
Config.RequiredItem = 'lockpick'
Config.RequiredHourStart = 22
Config.RequiredHourEnd = 5

Config.Rewards = {
    { item = 'goldchain', min = 1, max = 2, chance = 60 },
    { item = 'diamond_ring', min = 1, max = 1, chance = 25 },
    { item = 'rolex', min = 1, max = 2, chance = 40 }
}

Config.Houses = {
    {
        id = 'grove_1',
        label = 'Dom na Grove Street',
        entrance = vec3(85.24, -1959.09, 21.12),
        interior = vec4(266.08, -1007.42, -101.01, 357.42),
        exit = vec3(266.08, -1007.42, -101.01),
        searchSpots = {
            vec3(265.91, -999.37, -99.01),
            vec3(261.64, -1002.52, -99.01),
            vec3(259.92, -1004.11, -99.01),
            vec3(263.85, -995.74, -99.01)
        }
    },
    {
        id = 'mirror_1',
        label = 'Dom w Mirror Park',
        entrance = vec3(1260.54, -627.31, 68.83),
        interior = vec4(346.52, -1012.41, -99.2, 2.24),
        exit = vec3(346.52, -1012.41, -99.2),
        searchSpots = {
            vec3(351.18, -994.76, -99.2),
            vec3(345.31, -995.7, -99.2),
            vec3(338.27, -996.92, -99.2),
            vec3(338.08, -1003.52, -99.2)
        }
    }
}

function Config.IsAllowedHour(hour)
    if Config.RequiredHourStart > Config.RequiredHourEnd then
        return hour >= Config.RequiredHourStart or hour < Config.RequiredHourEnd
    end

    return hour >= Config.RequiredHourStart and hour < Config.RequiredHourEnd
end
