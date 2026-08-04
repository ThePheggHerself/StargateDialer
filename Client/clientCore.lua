

function listenBasaltCommand()
	while true do
		local name, cmd = os.pullEvent("basalt_command")

		Wireless.transmitMessage({
			type = "cmd",
			content = cmd
		})
	end
end

function listenBasaltAddressUpdate()
	while true do
		local event, data = os.pullEvent("basalt_address_update")

		refreshDialTab()
		refreshAddressesTab()
	end
end

function listenConsoleLogRequest()
	while true do
		local name, msg = os.pullEvent("console_log_request")

		local lines = Strings.wrap(msg:gsub("%[cmd%]", ">"), TerminalUI.ConsoleFrame.width - 2)

		for _, line in pairs(lines) do
			TerminalUI.ConsoleFrame:addChild(TerminalUI.ConsoleFrame:addLabel({
				y = TerminalUI.Index,
				height = 1,
				text = line
			}))	

			TerminalUI.Index = TerminalUI.Index + 1
		end

		if TerminalUI.Index > 13 then
			Basalt.schedule(function ()
				sleep(0.1)
				TerminalUI.ConsoleFrame:scrollTo(0, TerminalUI.Index - 13)
			end)
		end
	end
end

function listenInput()
	while true do
		local event, key, is_held = os.pullEvent("key")

		if key == keys.enter and TerminalUI.Input ~= nil then
			os.queueEvent("basalt_command", TerminalUI.Input.text)
			TerminalUI.Input.text = ""
		end
	end
end


function startInterfaces()
	Basalt.run()
end

function run()
	TerminalInterface.createInterface(Basalt)
	MonitorInterface.createInterface(Basalt)
	
	
	Helpers.log("Welcome to the BasaltDialer Terminal")

	parallel.waitForAny(
		MonitorInterface.updateGateData,
		listenBasaltAddressUpdate,
		listenConsoleLogRequest,
		listenInput,
		listenBasaltCommand,
		startInterfaces
	)
end

return {
    run = run
}