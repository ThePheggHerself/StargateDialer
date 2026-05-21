function listenRequestCommand()
    while true do
        local event, command = os.pullEvent("request_command")
		commandHandler(command)
    end
end

function commandHandler(cmd)
	if cmd == nil then
		return
	end

	local cmdTable = {}

	print("[cmd] " .. cmd)

	for seg in string.gmatch(cmd, "[^%s]+") do
		table.insert(cmdTable, seg)
	end

	if cmdTable[1] == "dial" or cmdTable[1] == "fdial" and cmdTable[2] ~= nil then
		local addrTable = {}

		for value in cmdTable[2]:gmatch("[^-,]+") do
			table.insert(addrTable, tonumber(value))
		end
	
		print("Dialing: " .. cmdTable[2])

		os.queueEvent("dial_stargate", addrTable, cmdTable[1] == "fdial")
	elseif cmdTable[1] == "close" or cmdTable[1] == "disconnect" or cmdTable[1] == "dc" or cmdTable[1] == "abort" then
		SGHandler.abortOrDisconnect()
	elseif cmdTable[1] == "iris" then
		if cmdTable[2] == "open" then
			SGHandler.toggleIris(true)
		elseif cmdTable[2] == "close" then
			SGHandler.toggleIris(false)
		elseif cmdTable[2] == "status" then
			if SGHandler.stargate.getIris() then
				print(
					string.format(
						"Iris close percentage: %i",
						SGHandler.stargate.getIrisProgressPercentage()
					)
				)
			else
				print("Stargate has no iris")
			end
		end
	elseif cmdTable[1] == "energyintg" then
		SGHandler.setGateEnergyTarget(Stargate, 100000000000)
	elseif cmdTable[1] == "energyints" then
		SGHandler.setGateEnergyTarget(Stargate, 200000)
	elseif cmdTable[1] == "cmd" or cmdTable[1] == "transmit" or cmdTable[1] == "msg" then
		if not SGHandler.stargate.isWormholeOpen() then
			print("There must be an active connection in order to send a message")
		end

		SGHandler.stargate.sendStargateMessage(table.concat(cmdTable, " ", 2))
	elseif cmdTable[1] == "togglealarms" and cmdTable[2] ~= nil then
		os.queueEvent("request_lockdown", cmdTable[2] == "true")
	elseif cmdTable[1] == "address" or cmdTable[1] == "addr" then
		if cmdTable[2] == "show" and cmdTable[3] ~= nil then
			local address = AddressBook.getAddressFromIDOrAddress(cmdTable[3])

			if address then
				print(string.format("Address for %s: %s", address.display, address.address))
			else
				print("No address found for " .. cmdTable[3])
			end
		end
	end
end

function startInterfaces()
	Basalt.run()
end

function run()
    SGHandler.runListeners()
end

return {
    run = run,
    listenRequestCommand = listenRequestCommand
}