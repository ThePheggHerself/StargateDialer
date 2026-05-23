local stargate = peripheral.find("advanced_crystal_interface")
	or peripheral.find("crystal_interface")
	or peripheral.find("basic_interface")
local transceiver = peripheral.find("transceiver")

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

function listenStargateChevronEngaged() -- "stargate_chevron_engaged"
	while true do
		local name, periphName, chevronCount, engagedChevron, incomingConnection, encodedSymbol =
			os.pullEvent("stargate_chevron_engaged")

		if incomingConnection and engagedChevron == 1 then -- Start of an incoming connection
			Helpers.log("WARNING! Incoming Connection!")
			warning = "Offworld Activation!"

			toggleIris(false)
			--toggleRelays(true) -- Toggle alarms and sirens
		end

		chevronText = "Encoded"

		if (incomingConnection and isAdvancedInterface(periphName)) or not incomingConnection then
			chevronText = "Encoded (" .. encodedSymbol .. ")"
		end

		chevronTable[engagedChevron + 1] =  chevronText
		Helpers.log(string.format("Chevron %s %s", engagedChevron, chevronText))
	end
end

function listenStargateIncomingWormhole() -- "stargate_incoming_wormhole"
	while true do
		local name, periphName, addressTable = os.pullEvent("stargate_incoming_wormhole")

		Helpers.log("Incoming wormhole Formed")

		local addrStr = stargate.addressToString(addressTable)
		local address = AddressBook.getAddressFromIDOrAddress(addrStr)

		if address.id then
			Helpers.log(string.format("Origin: %s (%s)", address.address, address.display))
			activeAddress = address
		else
			Helpers.log(string.format("Origin: %s (Unknown)", addrStr))
			activeAddress = { id = "unknown", display = "Unknown", address = addrStr }
		end

		if stargate.getIris() and stargate.getIrisProgressPercentage() > 99 then
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
				--toggleRelays(false)
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
		Helpers.log(string.format("Disconnected: %s", feedback))
	end
end

function listenStargateReset() -- "stargate_reset"
	while true do
		local name, periphName, feedback, feedbackDescription = os.pullEvent("stargate_reset")

		Helpers.log(string.format("Reset: %s", feedback))
		activeAddress = { display = "Not Connected", address = "" }
		warning = ""

		--toggleRelays(false)

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

function listenTransmissionRecieved()
	while true do
		local name, periphName, freq, code, validOverride = os.pullEvent("transceiver_transmission_received")

		Helpers.log(string.format("[GDO] IDC %s recieved on frequency %s", code, freq))

		if not stargate.isWormholeOpen() then
			Helpers.log("[GDO] IDC recieved but unsafe request. Waiting...")

			while not stargate.isWormholeOpen() do
				sleep(0.5)
			end

			Helpers.log("[GDO] Wormhole stabalized")
		end

		local isValid, codeName = isIDCValid(freq, code, validOverride)

		if isValid then
			Helpers.log(string.format("[GDO] Valid IDC: %s (%s)", codeName, code))
			toggleIris(true)
		else
			Helpers.log("[GDO] Invalid IDC")
		end
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
				feedbackCode = stargate.getRecentFeedback(),
			}

			local advanced = {
				available = false,
			}

			if isAdvancedInterface(peripheral.getName(stargate)) then
				advanced = {
					available = true,
					localAddress = stargate.addressToString(stargate.getLocalAddress()),
					network = stargate.getNetwork(),
				}
			end

			if stargate.isStargateConnected() and advanced.available then
				activeAddress =
					AddressBook.getAddressFromIDOrAddress(stargate.addressToString(stargate.getConnectedAddress()))
			end

			local iris = {
				status = irisStatus(),
				durability = stargate.getIrisDurability(),
				maxDurability = stargate.getIrisMaxDurability(),
			}

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

function listenDialStargate()
	while true do
		local event, address, isFast = os.pullEvent("dial_stargate")

		activeAddress = AddressBook.getAddressFromIDOrAddress(address)

		dialStargate(AddressBook.stringToTable(address), isFast)
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
		listenDialStargate,
		dataUpdater,
		

		Wireless.listenModemMessage,
		Wireless.listenDataUpdate,
		ServerCore.listenRequestCommand
	)
end

return {
	references = References,
	stargate = stargate,
	runListeners = runListeners,

	dialStargate = dialStargate,
	isRotatingStargate = isRotatingStargate,
	stargateStatus = stargateStatus,
	irisStatus = irisStatus,
	toggleIris = toggleIris,
	setGateEnergyTarget = setGateEnergyTarget,
	abortOrDisconnect = abortOrDisconnect,
}
