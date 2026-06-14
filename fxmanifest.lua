fx_version 'cerulean'
game 'gta5'

name 'BB Blip Creator'
author 'Baasha Bhai (BB)'
description 'BB Blip Creator - standalone premium blip manager with live in-world preview. Framework agnostic, auto-detects admins.'
version '1.0.0'

lua54 'yes'

ui_page 'html/index.html'

shared_script 'config.lua'

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/blips_data.js',
    'html/blips/*.png'
}
