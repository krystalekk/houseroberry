fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'house_robbery'
author 'Codex'
description 'Advanced ESX + ox_lib + ox_inventory house robbery script for FiveM'
version '2.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}

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
