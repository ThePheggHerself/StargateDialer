local modem = peripheral.find("ender_modem") or peripheral.find("modem")
local computerListenPort = 28465
local pocketListenPort = 56482

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
				local msgTable = textutils.unserialize(msg)

				if msgTable then
					if msgTable.type == "cmd" then
						os.queueEvent("basalt_command", msgTable.content)
					elseif msgTable.type == "data_update" then
						os.queueEvent("data_update", msgTable.content)
					end
				end
			end
		end
	end
end

function listenDataUpdate()
    while true do 
        local event, data = os.pullEvent("data_update")

        transmitMessage(data)
    end
end

function transmitMessage(content)
    if modem then
        modem.transmit(pocketListenPort, computerListenPort, textutils.serialize(content))
    end
end