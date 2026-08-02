local modem = peripheral.find("modem")

LastHeartbeat = os.time("utc")

SyncableData = {
	addresses = {
		serverFunc = (function(...)
			return AddressBook.getAddressBook()
		end),
		clientFunc = (function(...)
			local addresses = ...

			print(addresses)
			
			AddressBook.clientSetAddressBook(addresses)
			os.queueEvent("basalt_address_update")
		end)
	}
}

ModemMessages = {
	cmd = {
		Instance = "server",
		func = (function(...)
			local msgTable = ...
			os.queueEvent("request_command", msgTable.content)
		end)
	},
	sync_request_from_client = {
		Instance = "server",
		func = (function(...)
			local msgTable = ...
			print("Sync request: ", msgTable.content, SyncableData[msgTable.content] == nil)

			if SyncableData[msgTable.content] then
				SyncableData[msgTable.content].serverFunc()

				print("[DSR] Responding with data")
				
				transmitMessage({type = "sync_response_from_server", content = {name = msgTable.content, data = SyncableData[msgTable.content].serverFunc()} })
			end
		end)
	},

	sync_response_from_server = {
		NotInstance = "server",
		func = (function(...)
			local msgTable = ...

			print("Sync response:", msgTable.content.name)

			os.queueEvent("client_sync_response", msgTable.content.name, msgTable.content.data)
		end)
	},
	data_update = {
		NotInstance = "server",
		func = (function(...)
			local msgTable = ...
			os.queueEvent("data_update", msgTable.content)
		end)
	},
	log = {
		NotInstance = "server",
		func = (function (...)
			local msgTable = ...
			Helpers.log(msgTable.content)
		end)
	},
	address_creation = {
		Instance = "server",
		func = (function (...)
			local addressTbl = ...

			print("Saving new address: " .. addressTbl.content.id)
			AddressBook.addAddress(addressTbl.content.id, addressTbl.content)
		end)
	}
}

function listenModemMessage()
	if modem then
		if InstanceType == "server" then
			modem.open(Settings.ServerListenPort)
		else
			modem.open(Settings.ClientListenPort)
		end
	end

	while true do
		local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")

		if modem then
			local validSender = false

			if InstanceType == "server" then
				validSender = replyChannel == Settings.ClientListenPort
			else
				validSender = replyChannel == Settings.ServerListenPort
			end

			if validSender then
				local msgTable = textutils.unserialize(message)

				if msgTable ~= nil then
					LastHeartbeat = msgTable.timestamp

					if ModemMessages[msgTable.type] then
						local mm = ModemMessages[msgTable.type]

						if (mm.Instance ~= nil and mm.Instance == InstanceType) or (mm.NotInstance ~= nil and mm.NotInstance ~= InstanceType) then
							mm.func(msgTable)
						end
					end
				end
			end
		end
	end
end

function clientSyncDataFromServer(name)
	Wireless.transmitMessage({type = "sync_request_from_client", content = name})	
	local responseRecieved = false
	
	local function waitForSyncResponse()
		while not responseRecieved do
			local event, respName, data = os.pullEvent("client_sync_response")
			if respName == name then
				responseRecieved = true
				if SyncableData[name] then
					SyncableData[name].clientFunc(data)
				end
			end
		end	
	end

	local function syncTimeout()	
		sleep(5)
		print("No sync response recieved")
	end

	parallel.waitForAny(waitForSyncResponse, syncTimeout)

	return responseRecieved
end

function listenDataUpdate()
    while true do 
        local event, data = os.pullEvent("data_update")

        transmitMessage( { type = "data_update", content = data } )
    end
end

function transmitMessage(content)
    if modem then
		content.timestamp = os.time("utc")
		
		if InstanceType == "server" then	
			modem.transmit(Settings.ClientListenPort, Settings.ServerListenPort, textutils.serialize(content))
		else
			modem.transmit(Settings.ServerListenPort, Settings.ClientListenPort, textutils.serialize(content))		
		end
       
    end
end

return {
	listenModemMessage = listenModemMessage,
	listenDataUpdate = listenDataUpdate,
	transmitMessage = transmitMessage,
	clientSyncDataFromServer = clientSyncDataFromServer
}