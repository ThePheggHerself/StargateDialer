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
	[-23] = "Connection time exceeded",
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


-- Clears the terminal, and resets the cursor position to 1,1
function resetTerminal()
	term.clear()
	term.setCursorPos(1, 1)
end

-- Rounds decimal points down
function roundDecimal(number, decimals)
	local multiplier = math.pow(10, decimals or 0)
	return math.floor(number * multiplier) / multiplier
end

function ticksToMinutesSeconds(ticks)
	seconds = math.floor(ticks / 20)

	local minutes = 0

	while seconds > 60 do
		minutes = minutes + 1
		seconds = seconds - 60
	end

	return ('%dm %ds'):format(minutes, seconds)
end

-- Converts power to easily readable units (1000FE -> 1kFE)
Energy_suffixes = { "", "k", "M", "G", "T", "P" }
function convertToPowerUnits(powerAmount)
	local timesConverted = 1
	while powerAmount > 1000 do
		timesConverted = timesConverted + 1
		powerAmount = powerAmount / 1000
	end

	return string.format("%s%sFE", roundDecimal(powerAmount, 2), Energy_suffixes[timesConverted])
end

-- Gets the Address Book from the config file


function log(msg)
	if InstanceType == "server" then
		print(msg)
		Wireless.transmitMessage({
			type = "log",
			content = msg
		})
	elseif InstanceType == "client" then
		os.queueEvent("console_log_request", msg)
	end
end

return {
	resetTerminal = resetTerminal,
	roundDecimal = roundDecimal,
	ticksToMinutesSeconds = ticksToMinutesSeconds,
	convertToPowerUnits = convertToPowerUnits,
	log = log,
	GateFeedbackCodes = GateFeedbackCodes,
	GateGeneration = GateGeneration,
	FilterType = FilterType
}
