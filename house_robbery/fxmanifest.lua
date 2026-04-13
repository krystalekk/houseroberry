fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'house_robbery'
author 'Codex'
description 'ESX + ox_lib + ox_inventory house robbery script for FiveM'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_inventory'
}
