-- Clears the terminal, and resets the cursor position to 1,1
function resetTerminal(term)
	term.clear()
	term.setCursorPos(1, 1)
end

-- Rounds decimal points down
function roundDecimal(number, decimals)
	local multiplier = math.pow(10, decimals or 0)
	return math.floor(number * multiplier) / multiplier
end

function ticksToMinutesSeconds(ticks)
	seconds = math.floor(ticks / 60)

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
	if not pocket then
		os.queueEvent("console_log_request", msg)
	end
end

return {
	resetTerminal = resetTerminal,
	roundDecimal = roundDecimal,
	ticksToMinutesSeconds = ticksToMinutesSeconds,
	convertToPowerUnits = convertToPowerUnits,
	log = log,
}
