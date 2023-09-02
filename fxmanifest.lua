fx_version "cerulean"
use_experimental_fxv2_oal "yes"
lua54 "yes"
game "gta5"

name "esx_vehicleshop"
version "0.0.0"
description "ESX-Overextended Vehicle Shop"

dependencies {
    "es_extended",
    "ox_target"
}

shared_scripts {
    "@es_extended/imports.lua",
    "@ox_lib/init.lua",
    "shared/*.lua",
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/*.lua"
}

client_scripts {
    "client/*.lua",
}

files {
    "locales/*.json",
    "modules/**/*.lua"
}
