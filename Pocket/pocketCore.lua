function startInterfaces()
	Basalt.run()
end

function run()
    PocketInterface.createInterface(Basalt)

    parallel.waitForAny(
        Wireless.listenModemMessage,
        startInterfaces
    )
end

return {
    run = run
}
