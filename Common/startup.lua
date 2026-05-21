local args = {...}

Strings = require("cc.strings")
Basalt = require("basalt")
AddressBook = require("addressBook")
Wireless = require("wirelessHandler")

print("Welcome to the basalt dialer")

local disableAutoUpdate = false

for i, arg in pairs(args) do
    if arg == "noupdate" then
        disableAutoUpdate = true
    end
end

if not disableAutoUpdate then
    print("Updating addresses")

    shell.run("delete addresses.conf")
    shell.run("wget https://raw.githubusercontent.com/ThePheggHerself/StargateDialer/refs/heads/main/addresses.conf")
    
    print("Waiting to startup")

    sleep(1)
end



if pocket then -- If it is a pocket computer
    InstanceType = "pocket"
    PocketInterface = require("pocketInterface")
    
    PocketCore = require("pocketCore")
    PocketCore.run()
elseif peripheral.find("monitor") then -- If it is a client
    InstanceType = "client"
    
    Relay = { peripheral.find("redstone_relay") }
	Monitor = peripheral.find("monitor")
	Helpers = require("helpers") -- Helper functions
	MonitorInterface = require("clientMonitorInterface") -- Handles the UI on the monitor
	TerminalInterface = require("clientTerminalInterface") -- Handles the UI on the terminal
    

    ClientCore = require("clientCore")
    ClientCore.run()
else -- Defaults to server mode
    InstanceType = "server"

    SGHandler = require("stargateHandler") -- Handles everything Stargate related

    ServerCore = require("serverCore")
    ServerCore.run()
end