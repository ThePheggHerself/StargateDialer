CreateDisplayLink = {
    DisplayLink = peripheral.find("Create_DisplayLink"),
    UpdateDisplay = function (firstLine, secondLine)
        if CreateDisplayLink.DisplayLink then

            y, x = CreateDisplayLink.DisplayLink.getSize()

            CreateDisplayLink.DisplayLink.setCursorPos(1,1)
            CreateDisplayLink.DisplayLink.clear()
            CreateDisplayLink.DisplayLink.setCursorPos(2,1)
            CreateDisplayLink.DisplayLink.write("= = = = = = = = = = = = = = =")
            CreateDisplayLink.DisplayLink.setCursorPos(math.floor((x - string.len(firstLine.content)) /2) + 1,2)
            CreateDisplayLink.DisplayLink.write(firstLine.content)
            CreateDisplayLink.DisplayLink.setCursorPos(math.floor((x - string.len(secondLine.content)) /2) + 1 ,3)
            CreateDisplayLink.DisplayLink.write(secondLine.content)
            CreateDisplayLink.DisplayLink.setCursorPos(2,4)
            CreateDisplayLink.DisplayLink.write("= = = = = = = = = = = = = = =")

            CreateDisplayLink.DisplayLink.update()
        end
    end
}

StargateTransceiver = {
    Transceiver = peripheral.find("transceiver"),
    ListenTransmissionRecieved = function (name, periphName, freq, code, matchingIDC, stargate)
        Helpers.log(string.format("[GDO] IDC %s recieved on frequency %s", code, freq))

		if not stargate.isWormholeOpen() then
			Helpers.log("[GDO] IDC recieved but unsafe request. Waiting...")

			while not stargate.isWormholeOpen() do
				sleep(0.5)
			end

			Helpers.log("[GDO] Wormhole stabalized")
		end

		local isValid, codeName = SGHandler.isIDCValid(freq, code, matchingIDC)

		if isValid then
			Helpers.log(string.format("[GDO] Valid IDC: %s (%s)", codeName, code))
			toggleIris(true)
		else
			Helpers.log("[GDO] Invalid IDC")
		end
    end
}

RedstoneRelay = {
    Relays = { peripheral.find("redstone_relay") },
    SetOutput = function (outputState)
        if #RedstoneRelay.Relays > 0 then
            for _, relay in pairs(outputState) do
                relay.setOutput("top", outputState)
                relay.setOutput("bottom", outputState)
                relay.setOutput("front", outputState)
                relay.setOutput("back", outputState)
                relay.setOutput("left", outputState)
                relay.setOutput("right", outputState)
            end
        end
    end
}

ChatBox = {
    Chatbox = peripheral.find("chat_box"),
    SendToast = function (message)
        if ChatBox.Chatbox then
            ChatBox.Chatbox.sendToast({
                message = message,
                title = "Stargate Dialer",
                player = "PheWitch",
                prefix = "&4&lWarning",
                brackets = "()",
                bracketsColor = "&c&l",
            })
        end
    end,
    ShareAddress = function (name, address)
        local message = {
            {text = "PheWitch shared a Stargate Address: ", color = "white"},
            {
                text = name .. " [" .. address .. "]", 
                color = "yellow", 
                clickEvent = {
                    action = "copy_to_clipboard",
                    value = address .. ""
                }
            }
        }

        local options = {
            prefix = "&aDialer",
            brackets = "[]",
            bracketsColor = "&a"
        }

        local json = textutils.serialiseJSON(message)
        ChatBox.Chatbox.sendFormattedMessage(json, options)
    end
}