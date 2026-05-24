local addressTable = {}

function serverReadTableFromFile(fileName)
	local file = fs.open(fileName, "r")
	local data = file.readAll()
	file.close()

	addressTable = textutils.unserialize(data)
end

-- Saves the Address Book
function serverWriteTableToFile(fileName, table)
	local file = fs.open(fileName, "w")
	file.write(textutils.serialize(table))
	file.close()
end

function clientSetAddressBook(newAddresses)
	addressTable = newAddresses
end

function getAddressFromAddress(addrStr)
	if addrStr == nil then
		return nil
	else
		for name, address in pairs(addressTable) do
			if address.address == addrStr or address.address == addrStr:sub(1, -3) then
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
			address = "",
			security = {
				irisAutoOpen = false,
				sirens = true,
			},
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
	srv_writeTableToFile(AddressFile, addressTable)
end

function removeAddress(id)
	addressTable[id] = nil

	srv_writeTableToFile(AddressFile, addressTable)
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

		return address
	end
end


return {
	serverReadTableFromFile = serverReadTableFromFile,
	serverWriteTableToFile = serverWriteTableToFile,
	clientSetAddressBook = clientSetAddressBook,
	getAddressFromIDOrAddress = getAddressFromIDOrAddress,
	getAddressBook = getAddressBook,
	stringToTable = stringToTable,
	addAddress = addAddress,
	removeAddress = removeAddress
}
