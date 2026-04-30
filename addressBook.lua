function readTableFromFile(fileName)
	local file = fs.open(fileName, "r")
	local data = file.readAll()
	file.close()

	return textutils.unserialize(data)
end

-- Saves the Address Book
function writeTableToFile(fileName, table)
	local file = fs.open(fileName, "w")
	file.write(textutils.serialize(table))
	file.close()
end

local addressTable = readTableFromFile("addresses.conf") -- Addresses

function getAddressFromAddress(addrStr)
	if addrStr == nil then
		return nil
	else
		newAddrStr = addrStr:sub(1, -3)

		for name, address in pairs(addressTable) do
			if address.address == newAddrStr then
				return address
			end
		end

		return nil
	end
end

function getAddressFromID(addrStr)
	if addrStr == nil then
		return nil
	else
		return addressTable[addrStr]
	end
end

function getAddressFromIDOrAddress(addrStr)
	address = getAddressFromID(addrStr)

	if address then
		return address
	else
		address = getAddressFromAddress(addrStr)

		if address then
			return address
		else
			return convertStringToAddress(addrStr)
		end
	end
end

function getAddressBook()
	return addressTable
end

function convertStringToAddress(addrString)
	if addrString == "" or addrString == "-" then	
		return {
			display = "Not Connected",
			address = ""
		}
	else
		return {
			address = addrString,
			display = "Unknown",
			security = {
				irisAutoOpen = false,
				sirens = true,
			},
		}
	end
end

function stringToTable(input)
	local addrTable = {}

	for value in input:gmatch("[^-,]+") do
		table.insert(addrTable, tonumber(value))
	end

	return addrTable
end

function addAddress(id, address)
	addressTable[id] = address
	Helpers.writeTableToFile("addresses.conf", addressTable)
end

function removeAddress(id)
	addressTable[id] = nil

	Helpers.writeTableToFile("addresses.conf", addressTable)
end

return {
	getAddressFromIDOrAddress = getAddressFromIDOrAddress,
	getAddressBook = getAddressBook,
	stringToTable = stringToTable,
	addAddress = addAddress,
	removeAddress = removeAddress,
}
