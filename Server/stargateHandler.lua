local stargate = peripheral.find("advanced_crystal_interface")
	or peripheral.find("crystal_interface")
	or peripheral.find("basic_interface")

local activeAddress = { display = "", address = "" }
local warning = ""

local chevronTable = {
	[1] = "idle",
	[2] = "idle",
	[3] = "idle",
	[4] = "idle",
	[5] = "idle",
	[6] = "idle",
	[7] = "idle",
	[8] = "idle",
	[9] = "idle",
}


-- Event Listeners

function listenStargateChevronEngaged() -- "stargate_chevron_engaged"
	while true do
		local name, periphName, chevronCount, engagedChevron, incomingConnection, encodedSymbol =
			os.pullEvent("stargate_chevron_engaged")
		if incomingConnection and engagedChevron == 1 then -- Start of an incoming connection
			Helpers.log("WARNING! Incoming Connection!")
			warning = "Offworld Activation!"

			toggleIris(false)
			RedstoneRelay.SetOutput(true) -- Toggle alarms and sirens
		end

		chevronText = "Encoded"

		if (incomingConnection and isAdvancedInterface(peripheral.getType(periphName))) or not incomingConnection then
			chevronText = "Encoded (" .. encodedSymbol .. ")"
		end

		chevronTable[engagedChevron + 1] =  chevronText
		Helpers.log(string.format("Chevron %s %s", engagedChevron, chevronText))
	end
end

function listenStargateIncomingConnection() -- "stargate_incoming_connection"
	while true do
		local name, peripheralName = os.pullEvent("stargate_incoming_connection")

		CreateDisplayLink.UpdateDisplay({content = "WARNING", xPos = 13 }, {content = "Incoming Connection", xPos = 7})
	end
end

function listenStargateIncomingWormhole() -- "stargate_incoming_wormhole"
	while true do
		local name, periphName, addressTable = os.pullEvent("stargate_incoming_wormhole")

		Helpers.log("Incoming wormhole Formed")
		local addrStr = stargate.addressToString(addressTable)
		
		if addrStr == nil then
			Helpers.log(string.format("Origin: %s (Unknown)", addrStr))
			activeAddress = { id = "unknown", display = "Unknown", address = addrStr }

			CreateDisplayLink.UpdateDisplay({content = "Incoming Wormhole", xPos = 7}, {content = "Origin Unavailable", xPos = 7 })
		
		else

		
			local address = AddressBook.getAddressFromIDOrAddress(addrStr)

			if address.id then
				Helpers.log(string.format("Origin: %s (%s)", address.address, address.display))
				activeAddress = address

				CreateDisplayLink.UpdateDisplay({content = "Incoming Wormhole", xPos = 7}, {content = address.display, xPos = 7 })
			else
				Helpers.log(string.format("Origin: %s (%s)", address.address, address.display))
				activeAddress = address

				CreateDisplayLink.UpdateDisplay({content = "Incoming Wormhole", xPos = 7}, {content = address.address, xPos = 7 })
			end
		end

		if stargate.getIris ~= nil and stargate.getIrisProgressPercentage() > 99 then
			stargate.sendStargateMessage(textutils.serialize({type="msg", content="Iris closed! Identification Required"})) -- Send through the gate to the other side, if possible
		end

		if address then
			while not stargate.isWormholeOpen() do
				sleep(0.5)
			end

			if address.security.irisAutoOpen then
				toggleIris(true)

				stargate.sendStargateMessage(textutils.serialize({type="msg", content="Iris is now open"}))
			end

			if not address.sirens then
				RedstoneRelay.SetOutput(false) -- Toggle alarms and sirens
			end
		end
	end
end

function listenStargateOutgoingWormhole() -- "stargate_outgoing_wormhole"
	while true do
		local name, periphName, address = os.pullEvent("stargate_outgoing_wormhole")

		

		CreateDisplayLink.UpdateDisplay({content = "Outgoing Wormhole", xPos = 7}, {content = stargate.addressToString(address), xPos = 7 })

		Helpers.log("Outgoing wormhole Formed")
		-- RedstoneRelay.SetOutput(true) -- Toggle alarms and sirens
	end
end

function listenStargateDisconnected() -- "stargate_disconnected"
	while true do
		local name, periphName, feedback, feedbackDescription = os.pullEvent("stargate_disconnected")
		Helpers.log(string.format("Disconnected: %s", Helpers.GateFeedbackCodes[feedback]))
	end
end

function listenStargateReset() -- "stargate_reset"
	while true do
		local name, periphName, feedback, feedbackDescription = os.pullEvent("stargate_reset")

		Helpers.log(string.format("Reset: %s", Helpers.GateFeedbackCodes[feedback]))
		activeAddress = { display = "Not Connected", address = "" }
		warning = ""

		CreateDisplayLink.UpdateDisplay({content = "Stargate Idle", xPos = 10}, {content = "Not Connected", xPos = 10 })
		RedstoneRelay.SetOutput(true) -- Toggle alarms and sirens

		chevronTable = {
			[1] = "idle",
			[2] = "idle",
			[3] = "idle",
			[4] = "idle",
			[5] = "idle",
			[6] = "idle",
			[7] = "idle",
			[8] = "idle",
			[9] = "idle",
		}
	end
end

function listenStargateDeconstructEntity() -- "stargate_deconstructing_entity"
	while true do
		local name, periphName, entityType, entityName, entityUUID, destroyed =
			os.pullEvent("stargate_deconstructing_entity")
		if destroyed then
			Helpers.log("Caution: Entity destroyed by entering incoming wormhole")
			Helpers.log("Entity: %s (%s)")
		else
			Helpers.log(string.format("Entity entered wormhole: %s (%s)", entityName, entityType))
		end
	end
end

function listenStargateReconstructEntity() -- "stargate_reconstructing_entity"
	while true do
		local name, periphName, entityType, entityName, entityUUID = os.pullEvent("stargate_reconstructing_entity")
		Helpers.log(string.format("Reconstructed entity: %s (%s)", entityName, entityUUID))
	end
end

function listenStargateMessageRecieved() -- "stargate_message_received"
	while true do
		local name, periphName, msg = os.pullEvent("stargate_message_received")
		msgTable = textutils.unserialize(msg)

		if msgTable then
			-- if (msgTable.type and msgTable.command) and (msgTable.type == "call" and msgTable.command == "info") then
			-- 	stargate.sendStargateMessage(textutils.serialize({
			-- 		isIrisClosed = stargate.getIrisProgress() ~= 0
			-- 	}))
			-- end
		end
	end
end

function listenTransmissionRecieved()
	while true do
		local name, periphName, freq, code, validOverride = os.pullEvent("transceiver_transmission_received")
		StargateTransceiver.ListenTransmissionRecieved(name, periphName, freq, code, validOverride)
	end
end

function listenDialStargate()
	while true do
		local event, address, isFast = os.pullEvent("dial_stargate")

		activeAddress = AddressBook.getAddressFromIDOrAddress(address)

		CreateDisplayLink.UpdateDisplay({content = "Dialing", xPos = 13}, {content = address, xPos = 7 })
		dialStargate(AddressBook.stringToTable(address), isFast)
	end
end


-- Loop Routines

function dataUpdater()
	while true do
		sleep(0.25) -- Prevents the "Too long without yielding" error

		if stargate then
			local basic = {
				isConnected = stargate.isStargateConnected(),
				isWormholeConnected = stargate.isWormholeOpen(),
				isDialingOut = stargate.isStargateDialingOut(),
				openTime = stargate.getOpenTime(),
				chevronsEngaged = stargate.getChevronsEngaged(),
				gateEnergy = stargate.getStargateEnergy(),
				gateEnergyTarget = stargate.getEnergyTarget(),
				interfaceEnergy = stargate.getEnergy(),
				interfaceEnergyCapacity = stargate.getEnergyCapacity(),
				generation = stargate.getStargateGeneration(),
				interface = peripheral.getType(peripheral.getName(stargate)),
				feedbackCode = Helpers.GateFeedbackCodes[stargate.getRecentFeedback()],
			}

			local advanced = {
				available = false,
			}

			if isAdvancedInterface(peripheral.getType(peripheral.getName(stargate))) then
				advanced = {
					available = true,
					localAddress = stargate.addressToString(stargate.getLocalAddress()),
					network = stargate.getNetworks(),
				}
			end

			if stargate.isStargateConnected() and advanced.available then
				activeAddress =
					AddressBook.getAddressFromIDOrAddress(stargate.addressToString(stargate.getConnectedAddress()))
			end

			local iris = {
				status = irisStatus(),
				
			}

			if stargate.getIris ~= nil then
				iris.durability = stargate.getIrisDurability()
				iris.maxDurability = stargate.getIrisMaxDurability()
			end

			os.queueEvent("data_update", {
				activeAddress = activeAddress,
				status = stargateStatus(),
				warning = warning,
				chevrons = chevronTable,
				iris = iris,
				basic = basic,
				advanced = advanced,
			})
		end
	end
end


-- Functions

function isIDCValid(freq, code,	validOverride)
	if validOverride then
		return true, "Override"
	elseif Settings.ExtraIDCs ~= nil then
		for i, c in pairs(Settings.ExtraIDCs) do
			if c.Code == code then
				return true, c.Name
			end
		end
	else
		local address = AddressBook.getAddressFromIDOrAddress(stargate.addressToString(stargate.getConnectedAddress()))

		if address.security.IDC and address.security.IDC == code then
			return true, "Local"
		end
		return false, ""
	end
end

cancelDial = false
function shouldAbortDial()
	if stargate.getRecentFeedback() == -30 then
		Helpers.log("Dialing sequence aborted due to incoming connection")
		return true
	elseif cancelDial then
		stargate.disconnectStargate()
		Helpers.log("Dialing sequence aborted")
		cancelDial = false
		return true
	end
	return false
end

function abortOrDisconnect()
	if stargate.isStargateConnected() then
		stargate.disconnectStargate()
	elseif stargate.getChevronsEngaged() > 0 then
		cancelDial = true
		Helpers.log("Dial aborted")
	else
		Helpers.log("Stargate is not dialing or connected")
	end
end

function dialStargate(addArr, isFast)
	local index = 0
	local lastSymbol = 0

	if stargate.rotateClockwise ~= nil and stargate.getCurrentSymbol ~= nil then
		lastSymbol = stargate.getCurrentSymbol()
	end

	for _, symbol in pairs(addArr) do
		if shouldAbortDial() then
			Helpers.log("Dial sequence aborted")
			stargate.disconnectStargate()
			break
		end

		if isFast and stargate.engageSymbol ~= nil then
			stargate.engageSymbol(symbol, true, true)
		else
			if stargate.rotateClockwise then
				if getRotationDirection(lastSymbol, symbol) then
					stargate.rotateClockwise(symbol)
				else
					stargate.rotateAntiClockwise(symbol)
				end

				lastSymbol = symbol

				-- now we need to wait for the gate to finish the rotation
				while not stargate.isCurrentSymbol(symbol) do
					sleep(0.2) -- we do not want to do anything while waiting
				end

				if shouldAbortDial() then
					Helpers.log("Dial sequence aborted")
					stargate.disconnectStargate()
					break
				end

				if stargate.openChevron ~= nil then
					stargate.openChevron()
					sleep(0.2)
					stargate.closeChevron()
				else
					stargate.encodeChevron()
				end
			else
				stargate.engageSymbol(symbol, true)
			end
		end

		if symbol == 0 then
			stargate.engageStargate()
		end

		index = index + 1
	end
end

-- https://github.com/Ktlo/pocket-stargate/blob/master/distributions/sgs/main.lua#L447
function getRotationDirection(current, symbol)
	local diff1 = symbol - current
	local diff2 = (symbol + 39) - current

	if symbol > current then
		diff2 = symbol - (current + 39)
	end

	if math.abs(diff1) < math.abs(diff2) then
		return diff1 < 1
	else
		return diff2 < 1
	end
end

-- Returns the status of the gate
function stargateStatus()
	if stargate.isStargateConnected() then
		if stargate.isWormholeOpen() then
			if stargate.isStargateDialingOut() then
				return "Connected (Outgoing)"
			else
				return "Connected (Incoming)"
			end
		else
			if stargate.isStargateDialingOut() then
				return "Wormhole forming"
			else
				return "Wormhole forming"
			end
		end
	elseif stargate.getChevronsEngaged() > 0 then
		return "Dialing"
	else
		return "Idle"
	end
end

-- returns the status of the Iris
function irisStatus()
	if stargate.getIris ~= nil then
		local progress = stargate.getIrisProgressPercentage()

		if progress == 0 then
			return "Iris is open"
		elseif progress == 100 then
			return "The iris is fully closed"
		else
			return "The iris is " .. math.floor(progress) .. "% closed"
		end
	else
		return "No Iris Installed"
	end
end

function toggleIris(state)
	if stargate.getIris ~= nil then
		if state then
			if stargate.getIrisProgressPercentage() > 0 then
				stargate.openIris()

				Helpers.log("Opening Iris")

				while SGHandler.stargate.getIrisProgressPercentage() > 0 do
					sleep(0.5)
				end

				Helpers.log("Iris Opened")
			else
				Helpers.log("Iris already open")
			end
		else
			if stargate.getIrisProgressPercentage() < 100 then
				stargate.closeIris()

				Helpers.log("Closing Iris")

				while SGHandler.stargate.getIrisProgressPercentage() < 100 do
					sleep(0.5)
				end
				Helpers.log("Iris closed")
			else
				Helpers.log("Iris already closed")
			end
		end
	end
end

-- Updates the Stargate's energy target
function setGateEnergyTarget(value)
	Helpers.log("Changing energy target to " .. Helpers.convertToPowerUnits(value))

	stargate.setEnergyTarget(value)
end

-- Checks if the stargate interface is an advanced crystal interface
function isAdvancedInterface(interfaceString)
	if string.find(interfaceString, "advanced_crystal_interface") then
		return true
	else
		return false
	end
end

function runListeners()
	CreateDisplayLink.UpdateDisplay({content = "Stargate Idle", xPos = 10}, {content = "Not Connected", xPos = 10 })

	parallel.waitForAny(
		listenStargateChevronEngaged,
		listenStargateIncomingConnection,
		listenStargateIncomingWormhole,
		listenStargateOutgoingWormhole,
		listenStargateDisconnected,
		listenStargateReset,
		listenStargateDeconstructEntity,
		listenStargateReconstructEntity,
		listenStargateMessageRecieved,
		listenTransmissionRecieved,
		listenDialStargate,
		dataUpdater,
		
		Wireless.listenDataUpdate,
		ServerCore.listenRequestCommand
	)
end

return {
	references = References,
	stargate = stargate,
	runListeners = runListeners,
	dialStargate = dialStargate,
	stargateStatus = stargateStatus,
	irisStatus = irisStatus,
	toggleIris = toggleIris,
	setGateEnergyTarget = setGateEnergyTarget,
	abortOrDisconnect = abortOrDisconnect,
}
