Strings = require("cc.strings")
SettingsFile = "settings.conf"
AddressFile = "addresses.conf"
Settings = {}

function LoadSettings()
    if not fs.exists(SettingsFile) then
        print("No settings file found")
    
        Settings = {
            AutoUpdateAddresses = true,
            ServerListenPort = 28465,
            ClientListenPort = 56482
        }
    
        local file = fs.open(SettingsFile, "w")
        file.write(textutils.serialize(Settings))
        file.close()
    
        print("Default settings file created")
        
        sleep(0.5)
    else
        print("Loading settings")
        local file = fs.open(SettingsFile, "r")
        local data = file.readAll()
        file.close()
        Settings = textutils.unserialize(data)
    end
end

function UpdateAddresses()
    if Settings.AutoUpdateAddresses then
        print("Updating addresses")

        if fs.exists(AddressFile) then
            fs.delete(AddressFile)
            sleep(0.5)
        end

        shell.run("wget https://raw.githubusercontent.com/ThePheggHerself/StargateDialer/refs/heads/main/addresses.conf")
        sleep(0.5)
    else
        print("Address autoupdate disabled")
    end
end

sleep(0.5)

print("Welcome to the basalt dialer")

if pocket then
    InstanceType = "pocket"
elseif peripheral.find("monitor") then
    InstanceType = "client"
else
    InstanceType = "server"
end

print("InstanceType set to: " .. InstanceType)

LoadSettings()

AddressBook = require("addressBook")
Wireless = require("wirelessHandler")
Helpers = require("helpers")
require("peripherals")

local function Startup()
    
end

local instanceStart = {
    pocket = (function(...)
        PocketInterface = require("pocketInterface")
        Basalt = require("basalt")

        print("Waiting 3 seconds to sync")

        sleep(3)

        print("Syncing data with server")
        local synced = Wireless.clientSyncDataFromServer("addresses")

        if synced then
            print("Successfully synced addresses with server")

            PocketCore = require("pocketCore")
            PocketCore.run()
            else
                print("Unable to sync with server. Startup aborted")
            end
        end),
    client = (function (...)
        Monitor = peripheral.find("monitor")
        MonitorInterface = require("clientMonitorInterface") -- Handles the UI on the monitor
        TerminalInterface = require("clientTerminalInterface") -- Handles the UI on the terminal
        Basalt = require("basalt")

        print("Waiting 3 seconds to sync")

        sleep(3)

        print("Syncing data with server")    
        local synced = Wireless.clientSyncDataFromServer("addresses")
        if synced then
            print("Successfully synced addresses with server")
    
            ClientCore = require("clientCore")
            ClientCore.run()
        else
            print("Unable to sync with server. Startup aborted")
        end
    end),
    server = (function (...)
        UpdateAddresses()
        AddressBook.serverReadTableFromFile(AddressFile)

        SGHandler = require("stargateHandler") -- Handles everything Stargate related

        ServerCore = require("serverCore")
        ServerCore.run()
    end)
}

parallel.waitForAll(
    instanceStart[InstanceType],
    Wireless.listenModemMessage
)