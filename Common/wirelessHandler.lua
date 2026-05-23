local modem = peripheral.find("modem", isWireless)

LastHeartbeat = os.time("utc")

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

					if InstanceType == "server" then
						Helpers.log("Remote message recieved: " .. msgTable.type)
					end

					if msgTable then
						if msgTable.type == "cmd" then
							os.queueEvent("request_command", msgTable.content)
						elseif msgTable.type == "data_update" then
							os.queueEvent("data_update", msgTable.content)
							--PocketInterface.updateGateData(msgTable.content)
						elseif msgTable.type == "log" and InstanceType ~= "server" then
							Helpers.log(msgTable.content)
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

        transmitMessage( { type = "data_update", content = data } )
    end
end

function transmitMessage(content)
    if modem then
		content.timestamp = os.time("utc")

		if InstanceType == "server" then		
			modem.transmit(Settings.ClientListenPort, Settings.ServerListenPort, textutils.serialize(content))
		else
			modem.transmit(Settings.ServerListenPort, Settings.ClientListenPort,  textutils.serialize(content))		
		end
       
    end
end

return {
	listenModemMessage = listenModemMessage,
	listenDataUpdate = listenDataUpdate,
	transmitMessage = transmitMessage
}