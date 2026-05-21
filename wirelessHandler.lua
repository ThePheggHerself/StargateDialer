local modem = peripheral.find("modem", isWireless)
local computerListenPort = 28465
local pocketListenPort = 56482

LastHeartbeat = os.time("utc")

function listenModemMessage()
	if modem then
		if pocket then
			modem.open(pocketListenPort)
		else
			modem.open(computerListenPort)
		end
	end

	while true do
		local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")

		if modem then
			local validSender = false

			if pocket then
				validSender = replyChannel == computerListenPort
			else
				validSender = replyChannel == pocketListenPort
			end

			if validSender then
				local msgTable = textutils.unserialize(message)

				LastHeartbeat = msgTable.timestamp

				if not pocket then
					Helpers.log("Remote message recieved: " .. msgTable.type)
				end

				if msgTable then
					if msgTable.type == "cmd" then
						os.queueEvent("basalt_command", msgTable.content)
					elseif msgTable.type == "data_update" and pocket then
						--PocketInterface.updateGateData(msgTable.content)
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
		if pocket then
			modem.transmit(computerListenPort, pocketListenPort,  textutils.serialize(content))
		else
			modem.transmit(pocketListenPort, computerListenPort, textutils.serialize(content))
		end
       
    end
end

return {
	listenModemMessage = listenModemMessage,
	listenDataUpdate = listenDataUpdate,
	transmitMessage = transmitMessage
}