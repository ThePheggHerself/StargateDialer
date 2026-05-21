local modem = peripheral.find("modem", isWireless)
local serverListenPort = 28465
local clientListenPort = 56482

LastHeartbeat = os.time("utc")

function listenModemMessage()
	if modem then
		if InstanceType == "server" then
			modem.open(serverListenPort)
		else
			modem.open(clientListenPort)
		end
	end

	while true do
		local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")

		if modem then
			local validSender = false

			if InstanceType == "server" then
				validSender = replyChannel == clientListenPort				
			else
				validSender = replyChannel == serverListenPort
			end

			

			if validSender then
				local msgTable = textutils.unserialize(message)

				if msgTable ~= nil then
					LastHeartbeat = msgTable.timestamp

					if InstanceType == "server" then
						print("Remote message recieved: " .. msgTable.type)
					end

					if msgTable then
						if msgTable.type == "cmd" then
							os.queueEvent("request_command", msgTable.content)
						elseif msgTable.type == "data_update" then
							os.queueEvent("data_update", msgTable.content)
							--PocketInterface.updateGateData(msgTable.content)
						end
					end
				end
			end
		end
	end
end

function listenDataUpdate()
    while true do 
        local event, data = os.pullEvent("data_update")

        transmitMessage( { type = "data_update", content = data})
    end
end

function transmitMessage(content)
    if modem then
		content.timestamp = os.time("utc")

		if InstanceType == "server" then		
			modem.transmit(clientListenPort, serverListenPort, textutils.serialize(content))
		else
			modem.transmit(serverListenPort, clientListenPort,  textutils.serialize(content))		
		end
       
    end
end

return {
	listenModemMessage = listenModemMessage,
	listenDataUpdate = listenDataUpdate,
	transmitMessage = transmitMessage
}