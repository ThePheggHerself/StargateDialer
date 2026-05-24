function startInterfaces()
	Basalt.run()
end

function run()
    PocketInterface.createInterface(Basalt)

    parallel.waitForAny(
        startInterfaces
    )
end

return {
    run = run
}
