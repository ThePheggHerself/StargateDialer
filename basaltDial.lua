Strings = require("cc.strings")
Basalt = require("basalt")
Relay = { peripheral.find("redstone_relay") }
Monitor = peripheral.find("monitor")
SGHandler = require("stargateHandler") -- Handles everything Stargate related
Helpers = require("helpers") -- Helper functions
MonitorInterface = require("monitorInterface") -- Handles the UI on the monitor
TerminalInterface = require("terminalInterface") -- Handles the UI on the terminal
AddressBook = require("addressBook")

-- Events

function listenBasaltCommand()
	while true do
		local name, cmd = os.pullEvent("basalt_command")

		commandHandler(cmd)
	end
end

-- Main Functions
function commandHandler(cmd)
	if cmd == nil then
		return
	end

	local cmdTable = {}

	Helpers.log("[cmd] " .. cmd)

	for seg in string.gmatch(cmd, "[^%s]+") do
		table.insert(cmdTable, seg)
	end

	if cmdTable[1] == "dial" or cmdTable[1] == "fdial" and cmdTable[2] ~= nil then
		Helpers.log("Dialing: " .. cmdTable[2])
		os.queueEvent("request_address", cmdTable[2], cmdTable[1] == "fdial", true)
	elseif cmdTable[1] == "close" or cmdTable[1] == "disconnect" or cmdTable[1] == "dc" then
		if not SGHandler.stargate.disconnectStargate() then
			Helpers.log("Err: Stargate cannot be disconnected")
		end
	elseif cmdTable[1] == "iris" then
		if cmdTable[2] == "open" then
			SGHandler.toggleIris(true)
		elseif cmdTable[2] == "close" then
			SGHandler.toggleIris(false)
		elseif cmdTable[2] == "status" then
			if SGHandler.stargate.getIris() then
				Helpers.log(
					string.format(
						"Iris close percentage: %i",
						SGHandler.stargate.getIrisProgressPercentage()
					)
				)
			else
				Helpers.log("Stargate has no iris")
			end
		end
	elseif cmdTable[1] == "energy" then
		Helpers.log(
			string.format(
				"Stargate Energy: %s / %s",
				Helpers.convertToPowerUnits(SGHandler.stargate.getStargateEnergy()),
				Helpers.convertToPowerUnits(SGHandler.stargate.getEnergyTarget())
			)
		)
	elseif cmdTable[1] == "energyintg" then
		Helpers.setGateEnergyTarget(Stargate, 100000000000)
	elseif cmdTable[1] == "energyints" then
		Helpers.setGateEnergyTarget(Stargate, 200000)
	elseif cmdTable[1] == "cmd" or cmdTable[1] == "transmit" or cmdTable[1] == "msg" then
		if not SGHandler.stargate.isWormholeOpen() then
			Helpers.log("There must be an active connection in order to send a message")
		end

		SGHandler.stargate.sendStargateMessage(table.concat(cmdTable, " ", 2))
	elseif cmdTable[1] == "togglealarms" and cmdTable[2] ~= nil then
		os.queueEvent("request_lockdown", cmdTable[2] == "true")
	elseif cmdTable[1] == "address" or cmdTable[1] == "addr" then
		if cmdTable[2] == "show" and cmdTable[3] ~= nil then
			local address = AddressBook.getAddressFromIDOrAddress(cmdTable[3])

			if address then
				Helpers.log(string.format("Address for %s: %s", address.display, address.address))
			else
				Helpers.log("No address found for " .. cmdTable[3])
			end
		end
	elseif cmdTable[1] == "abort" then
		if SGHandler.stargate.getChevronsEngaged() > 0 then
			cancelDial = true

			Helpers.log("Dial sequence aborted")
		else
			Helpers.log("The gate is currently not dialing")
		end
	end
end

function startInterfaces()
	Basalt.run()
end

-- Running Computer


MonitorInterface.createInterface(Basalt)
TerminalInterface.createInterface(Basalt)

Helpers.log("Welcome to the BasaltDialer Terminal")

parallel.waitForAny(
	SGHandler.runListeners,
	--Wireless.listenModemMessage,
	listenBasaltCommand,
	startInterfaces
)
