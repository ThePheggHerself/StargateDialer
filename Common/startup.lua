local args = {...}

Strings = require("cc.strings")
print("Welcome to the basalt dialer")

Settings = {}

sleep(0.5)

local settingsFile = "settings.conf"
local addressesFile = "addresses.conf"

if not fs.exists(settingsFile) then
    print("No settings file found")

    Settings = {
        AutoUpdateAddresses = true,
        ServerListenPort = 28465,
        ClientListenPort = 56482
    }

    local file = fs.open(settingsFile, "w")
	file.write(textutils.serialize(Settings))
	file.close()

    print("Default settings file created")
    
    sleep(0.5)
else
    print("Loading settings")
    local file = fs.open(settingsFile, "r")
    local data = file.readAll()
    file.close()
    Settings = textutils.unserialize(data)
end

if Settings.AutoUpdateAddresses then
    print("Updating addresses")

    if fs.exists(addressesFile) then
        fs.delete(addressesFile)
        sleep(0.5)
    end

    shell.run("wget https://raw.githubusercontent.com/ThePheggHerself/StargateDialer/refs/heads/main/addresses.conf")
    sleep(0.5)
else
    print("Address autoupdate disabled")
end

AddressBook = require("addressBook")
Wireless = require("wirelessHandler")
Helpers = require("helpers")

print("Starting in 3 seconds")

sleep(3)

if pocket then -- If it is a pocket computer
    InstanceType = "pocket"
    PocketInterface = require("pocketInterface")
    Basalt = require("basalt")

    PocketCore = require("pocketCore")
    PocketCore.run()
elseif peripheral.find("monitor") then -- If it is a client
    InstanceType = "client"

    Relay = { peripheral.find("redstone_relay") }
	Monitor = peripheral.find("monitor")
	MonitorInterface = require("clientMonitorInterface") -- Handles the UI on the monitor
	TerminalInterface = require("clientTerminalInterface") -- Handles the UI on the terminal
    Basalt = require("basalt")

    ClientCore = require("clientCore")
    ClientCore.run()
else -- Defaults to server mode
    InstanceType = "server"

    SGHandler = require("stargateHandler") -- Handles everything Stargate related

    ServerCore = require("serverCore")
    ServerCore.run()
end