function startInterfaces()
	Basalt.run()
end

function listenBasaltCommand()
	while true do
		local name, cmd = os.pullEvent("basalt_command")

		Wireless.transmitMessage({
			type = "cmd",
			content = cmd
		})
	end
end

function run()
	MonitorInterface.createInterface(Basalt)
	TerminalInterface.createInterface(Basalt)
	
	Helpers.log("Welcome to the BasaltDialer Terminal")

	parallel.waitForAny(
		listenBasaltCommand,
		startInterfaces
	)
end

return {
    run = run
}