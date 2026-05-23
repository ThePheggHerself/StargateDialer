local commands = {
	{
		name = "dial",
		alias = { "fdial" },
		description = "Requests the stargate to dial an address",
		func=(function (cmdTable)
			Helpers.log("Dialing: " .. cmdTable[2])
			os.queueEvent("dial_stargate", cmdTable[2], cmdTable[1] == "fdial")
		end)
	},
	{
		name = "close",
		alias = { "disconnect", "dc", "abort" },
		description = "Disconnects the stargate, or aborts if currently dialing",
		func = (function(cmdTable)
			SGHandler.abortOrDisconnect()
		end)
	},
	{
		name = "iris",
		description = "Manage the stargate's iris",
		func = (function (cmdTable)
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
		end)
	},
	{
		name = "energyintg",
		description = "Sets the stargate's energy target to 100GFE",
		func = (function(cmdTable)
			SGHandler.setGateEnergyTarget(100000000000)
		end)
	},
	{
		name = "energyints",
		description = "Sets the stargate's energy target to 200MFE",
		func = (function(cmdTable)
			SGHandler.setGateEnergyTarget(200000)
		end)
	},
	{
		name = "cmd",
		alias = {"transmit", "msg"},
		description = "Sends a message through an active stargate",
		func = (function (cmdTable)
			if not SGHandler.stargate.isWormholeOpen() then
				Helpers.log("There must be an active connection in order to send a message")
			end
	
			SGHandler.stargate.sendStargateMessage(table.concat(cmdTable, " ", 2))
		end)
	},
	{
		name = "address",
		alias = { "addr" },
		description = "Misc Address commands",
		func = (function(cmdTable)
			if cmdTable[2] == "show" and cmdTable[3] ~= nil then
				local address = AddressBook.getAddressFromIDOrAddress(cmdTable[3])
	
				if address then
					Helpers.log(string.format("Address for %s: %s", address.display, address.address))
				else
					Helpers.log("No address found for " .. cmdTable[3])
				end
			end
		end)
	}
}


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

	Helpers.log("[cmd] " .. cmd)

	for seg in string.gmatch(cmd, "[^%s]+") do
		table.insert(cmdTable, seg)
	end

	for i, c in pairs(commands) do
		if c.name == cmdTable[1] then
			c.func(cmdTable)
		elseif c.alias ~= nil then
			for j, a in pairs(c.alias) do
				if a == cmdTable[1] then
					c.func(cmdTable)
				end
			end
		end
	end	
end

function startInterfaces()
	Basalt.run()
end

function run()
	Helpers.resetTerminal()
	print("Server started")
    SGHandler.runListeners()
end

return {
    run = run,
    listenRequestCommand = listenRequestCommand
}