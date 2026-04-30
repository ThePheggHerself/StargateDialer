local stargate = peripheral.find("advanced_crystal_interface")
	or peripheral.find("crystal_interface")
	or peripheral.find("basic_interface")
local transceiver = peripheral.find("transceiver")

GateFeedbackCodes = {
	[0] = "NONE",
	[1] = "Symbol Encoded",
	[2] = "Systemwide Connection Made",
	[3] = "Interstellar Connection Made",
	[4] = "Intergalactic Connection Made",
	[5] = "TRANSPORT_SUCCESSFUL",
	[6] = "ENTITY_DESTROYED",
	[7] = "Stargate Disconnected",
	[8] = "CONNECTION_ENDED.POINT_OF_ORIGIN",
	[9] = "CONNECTION_ENDED.STARGATE_NETWORK",
	[10] = "Connection Autoclosed",
	[11] = "Chevron Opened",
	[12] = "Rotating",
	[13] = "Rotation Stopped",
	[-1] = "UNKNOWN",
	[-2] = "SYMBOL_IN_ADDRESS",
	[-3] = "SYMBOL_OUT_OF_BOUNDS",
	[-4] = "ENCODE_WHEN_CONNECTED",
	[-5] = "INCOMPLETE_ADDRESS",
	[-6] = "Invalid Address",
	[-7] = "Insufficient Power",
	[-8] = "SELF_OBSTRUCTED",
	[-9] = "TARGET_OBSTRUCTED",
	[-10] = "SELF_DIAL",
	[-11] = "SAME_SYSTEM_DIAL",
	[-12] = "ALREADY_CONNECTED",
	[-13] = "NO_GALAXY",
	[-14] = "NO_DIMENSIONS",
	[-15] = "NO_STARGATES",
	[-16] = "TARGET_RESTRICTED",
	[-17] = "INVALID_8_CHEVRON_ADDRESS",
	[-18] = "INVALID_SYSTEM_WIDE_CONNECTION",
	[-19] = "WHITELISTED_TARGET",
	[-20] = "WHITELISTED_SELF",
	[-21] = "BLACKLISTED_TARGET",
	[-22] = "BLACKLISTED_SELF",
	[-23] = "EXCEEDED_CONNECTION_TIME",
	[-24] = "RAN_OUT_OF_POWER",
	[-25] = "CONNECTION_REROUTED",
	[-26] = "WRONG_DISCONNECT_SIDE",
	[-27] = "CONNECTION_FORMING",
	[-28] = "STARGATE_DESTROYED",
	[-29] = "COULD_NOT_REACH_TARGET_STARGATE",
	[-30] = "INTERRUPTED_BY_INCOMING_CONNECTION",
	[-31] = "ROTATION_BLOCKED",
	[-32] = "NOT_ROTATING",
	[-33] = "CHEVRON_ALREADY_OPENED",
	[-34] = "CHEVRON_ALREADY_CLOSED",
	[-35] = "CHEVRON_NOT_OPEN",
	[-36] = "CANNOT_ENCODE_POINT_OF_ORIGIN",
}
GateGeneration = {
	[0] = "Classic",
	[1] = "Universe",
	[2] = "Milky Way",
	[3] = "Pegasus",
	[-1] = "Unknown",
}
FilterType = {
	[-1] = "Blacklist",
	[0] = "None",
	[1] = "Whitelist",
}

local activeAddress = { id = "unknown", display = "Unknown", address = "" }
local warning = ""

function listenStargateChevronEngaged() -- "stargate_chevron_engaged"
	while true do
		local name, periphName, chevronCount, engagedChevron, incomingConnection, encodedSymbol =
			os.pullEvent("stargate_chevron_engaged")

		if incomingConnection and engagedChevron == 1 then -- Start of an incoming connection
			Helpers.log("WARNING! Incoming Connection!")
			warning = "Offworld Activation!"

			toggleIris(false)
			Helpers.log("AAAA")
			Helpers.toggleRelays(true) -- Toggle alarms and sirens
		end

		chevronText = "Encoded"

		if (incomingConnection and isAdvancedInterface(periphName)) or not incomingConnection then
			chevronText = "Encoded (" .. encodedSymbol .. ")"
		end

		os.queueEvent("basalt_chevron_update", { [engagedChevron + 1] = chevronText })
		Helpers.log(string.format("Chevron %s %s", engagedChevron, chevronText))
	end
end

function listenStargateIncomingWormhole() -- "stargate_incoming_wormhole"
	while true do
		local name, periphName, addressTable = os.pullEvent("stargate_incoming_wormhole")

		Helpers.log("Incoming wormhole Formed")
		address = nil

		if isAdvancedInterface(periphName) then
			addrStr = stargate.addressToString(addressTable)
			address = AddressBook.getAddressFromIDOrAddress(addrStr)

			if address.id then
				Helpers.log(string.format("Origin: %s (%s)", address.address, address.display))
				activeAddress = address
			else
				Helpers.log(string.format("Origin: %s (Unknown)", addrStr))
				activeAddress = { id = "unknown", display = "Unknown", address = addrStr }
			end
		else
			Helpers.log("Unknown Origin (Incompatible Hardware)")
			activeAddress = { id = "unknown", display = "Unknown", address = "" }
		end

		if stargate.getIris() and stargate.getIrisProgressPercentage() > 99 then
			--stargate.sendStargateMessage({type="msg", content="Iris closed! Identification Required"}) -- Send through the gate to the other side, if possible
		end

		if address ~= nil then
			while not stargate.isWormholeOpen() do
				sleep(0.5)
			end

			if address.security.irisAutoOpen then
				toggleIris(true)

				--stargate.sendStargateMessage("Iris is now open")
			end

			if not address.sirens then
				Helpers.toggleRelays(false)
			end
		end
	end
end

function listenStargateOutgoingWormhole() -- "stargate_outgoing_wormhole"
	while true do
		local name, periphName, address = os.pullEvent("stargate_outgoing_wormhole")

		Helpers.log("Outgoing wormhole Formed")
		--Helpers.toggleRelays(true)
	end
end

function listenStargateDisconnected() -- "stargate_disconnected"
	while true do
		local name, periphName, feedback, feedbackDescription = os.pullEvent("stargate_disconnected")
		Helpers.log(string.format("Disconnected: %s", GateFeedbackCodes[feedback]))
	end
end

function listenStargateReset() -- "stargate_reset"
	while true do
		local name, periphName, feedback, feedbackDescription = os.pullEvent("stargate_reset")

		Helpers.log(string.format("Reset: %s", GateFeedbackCodes[feedback]))
		activeAddress = { id = "unknown", display = "Unknown", address = "" }
		warning = ""

		Helpers.toggleRelays(false)

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

		os.queueEvent("basalt_chevron_update", chevronTable)
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
		local name, periphName, freq, code, matches = os.pullEvent("transceiver_transmission_received")

		Helpers.log(string.format("[GDO] IDC %s recieved on frequency %s", code, freq))

		if matches then
			Helpers.log(string.format("[GDO] Valid IDC"), code, freq)
			toggleIris(true)
		else
			Helpers.log(string.format("[GDO] Invalid IDC"), code, freq)
		end

		os.queueEvent("basalt_command", msg)
	end
end

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
				interface = peripheral.getName(stargate),
				feedbackCode = stargate.getRecentFeedback()
			}

			local advanced = {
				available = false
			}

			if isAdvancedInterface(peripheral.getName(stargate)) then
				advanced = {
					available = true,
					localAddress = stargate.addressToString(stargate.getLocalAddress()),
					network = stargate.getNetwork()
				}
			end

			os.queueEvent("data_update", {
				activeAddress = activeAddress,
				status = stargateStatus(),
				warning = warning,
				iris = irisStatus(),
				basic = basic,
				advanced = advanced				
			})
		end
	end
end

function listenRequestDial()
	while true do
		local name, address, fastDial, addPoO = os.pullEvent("request_address")

		requestAddress(address, fastDial, addPoO)
	end
end

function listenRequestLockdown()
	while true do
		local name, state = os.pullEvent("request_lockdown")

		toggleRelays(state)
	end
end


function toggleRelays(state)
	local Relay = { peripheral.find("redstone_relay") }

	if Relay then
		for _, relay in pairs(Relay) do
			relay.setOutput("top", state)
			relay.setOutput("bottom", state)
			relay.setOutput("front", state)
			relay.setOutput("back", state)
			relay.setOutput("left", state)
			relay.setOutput("right", state)
		end
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

function requestAddress(input, fastDial, addPoO)
	if stargate.isWormholeOpen() or stargate.isStargateDialingOut() or stargate.getChevronsEngaged() > 0 then
		Helpers.log("ERR: Stargate Active")
	else
		local addrTable = {}
		address = AddressBook.getAddressFromIDOrAddress(input)

		if address.security.restricted then
			Helpers.log("Access to this address is restricted.\nDialing sequence aborted")
			return
		end

		Helpers.log(string.format("Dialing Stargate for: %s", address.display))
		Helpers.log(string.format("Address: %s", address.address))
		addrTable = AddressBook.stringToTable(address.address)
		activeAddress = address

		Helpers.log(address.security.sirens)

		if address.id == nil or address.security.sirens then
			Helpers.log("AAA")
			Helpers.toggleRelays(true)
		end

		if addPoO then
			table.insert(addrTable, 0)
		end

		if #addrTable == 8 then
			Helpers.log("Increasing Energy Target")

			setGateEnergyTarget(100000000000)
		else
			setGateEnergyTarget(200000)
		end

		dialStargate(addrTable, fastDial)
	end
end

function dialStargate(addArr, isFast)
	local index = 0
	local lastSymbol = 0
	local isRotatingStargate = isRotatingStargate()

	if isRotatingStargate then
		if stargate.getCurrentSymbol() ~= nil then
			lastSymbol = stargate.getCurrentSymbol()
		end
	end

	for _, symbol in pairs(addArr) do
		if shouldAbortDial() then
			Helpers.log("Dial sequence aborted")
			stargate.disconnectStargate()
			break
		end

		if isFast and isCrystalInterface(peripheral.getName(stargate)) then
			stargate.engageSymbol(symbol)
		else
			if isRotatingStargate then
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

				if stargate.getStargateType() == "sgjourney:milky_way_stargate" then
					sleep(0.2)
					stargate.openChevron()
					sleep(0.2)
					stargate.closeChevron()
					sleep(0.2)
				else
					stargate.encodeChevron()
					sleep(0.2)
				end
			else
				sleep(0.2)
				stargate.engageSymbol(symbol)
				sleep(0.2)
			end
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

-- Is the gate capable of rotating
function isRotatingStargate()
	local stargateType = stargate.getStargateType()

	return stargateType == "sgjourney:milky_way_stargate"
		or stargateType == "sgjourney:universe_stargate"
		or stargateType == "sgjourney:classic_stargate"
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
	if stargate then
		if stargate.getIris() then
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
	else
		return "N/A"
	end
end

function toggleIris(state)
	if stargate and stargate.getIris() then
		if state then
			if stargate.getIrisProgressPercentage() > 0 then
				stargate.openIris()

				local function waitForIrisOpen()
					while SGHandler.stargate.getIrisProgressPercentage() > 0 do
						sleep(0.5)
					end
					Helpers.log("Iris Opened")
				end

				parallel.waitForAny(waitForIrisOpen, function()
					Helpers.log("Opening Iris")
				end)
			else
				Helpers.log("Iris already open")
			end
		else
			if stargate.getIrisProgressPercentage() < 100 then
				stargate.closeIris()

				local function waitForIrisClose()
					while SGHandler.stargate.getIrisProgressPercentage() < 100 do
						sleep(0.5)
					end
					Helpers.log("Iris closed")
				end

				parallel.waitForAny(waitForIrisClose, function()
					Helpers.log("Closing Iris")
				end)
			else
				Helpers.log("Iris already closed")
			end
		end
	end
end

-- Updates the Stargate's energy target
function setGateEnergyTarget(value)
	Helpers.log("Changing energy target to " .. convertToPowerUnits(value))

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

-- Checks of the stargate interface is a (advanced) crystal interface
function isCrystalInterface(interfaceString)
	if
		string.find(interfaceString, "advanced_crystal_interface") or string.find(interfaceString, "crystal_interface")
	then
		return true
	else
		return false
	end
end

function runListeners()
	parallel.waitForAny(
		listenStargateChevronEngaged,
		listenStargateIncomingWormhole,
		listenStargateOutgoingWormhole,
		listenStargateDisconnected,
		listenStargateReset,
		listenStargateDeconstructEntity,
		listenStargateReconstructEntity,
		listenStargateMessageRecieved,
		listenTransmissionRecieved,
		listenRequestDial,
		listenRequestLockdown,
		dataUpdater
	)
end

return {
	references = References,
	stargate = stargate,
	runListeners = runListeners,

	requestAddress = requestAddress,
	dialStargate = dialStargate,
	isRotatingStargate = isRotatingStargate,
	stargateStatus = stargateStatus,
	irisStatus = irisStatus,
	toggleIris = toggleIris,
	setGateEnergyTarget = setGateEnergyTarget,
}
