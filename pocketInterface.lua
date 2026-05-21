local basaltInit = false
--Info Tab
local consoleTextBox = nil
local consoleInput = nil

--Debug Tab
local gateGenLabel = nil
local interfaceLabel = nil
local localAddressLabel = nil
local networkLabel = nil
local fastDialCheckbox = nil

local function isFastDial()
    if fastDial.checked then
        return "fdial"
    else
        return "dial"
    end
end

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

function createDialTab(main, addressBook)

	-- Fast Dial Checkbox
	main:addLabel({
		x = 3,
		y = 1,
		text = "Fast",
		foreground = colors.orange,
	})
	fastDial = main:addCheckBox({
		x = 8,
		y = 1,
		text = "[ ]",
		checkedText = "[X]",
		foreground = colors.yellow,
	})

	main:addButton({
		x = 13,
		y = 1,
		width = 12,
		height = 1,
		text = "Disconnect",
		foreground = colors.white,
		background = colors.red
	})
	:onClick(function()
        Wireless.transmitMessage({
            type = "cmd",
            content = "disconnect"
        })
	end)

	local addressTab = main:addTabControl({
		x = 1,
		y = 2,
		width = 49,
		height = 20,
		background = colors.black,
		headerBackground = colors.cyan,
		activeTabBackground = colors.lightBlue
	})


	local localList = addressTab:newTab("7-Chev")
	local galacticList = addressTab:newTab("8-Chev")
	local directList = addressTab:newTab("9-Chev")

	local localPos = {x = 2, y = 2}
	local galacticPos = {x = 2, y = 2}
	local directPos = {x = 2, y = 2}
    local originButtonX = 2
    local secondButtonX = 14

	for i, addr in pairs(addressBook) do
		local addressTable = AddressBook.stringToTable(addr.address)

		if not addr.hidden then
			local color = colors.green
			if addr.security.restricted then
				color = colors.red
			end

            local buttonProperties = {
                width = 10,
                height = 1,
                text = addr.display,
                foreground = colors.white,
                background = color
            }

            local buttonFunction = function()
                Wireless.transmitMessage({
                    type = "cmd",
                    content =  isFastDial() .. " " .. addr.address
                })
            end
			if #addressTable == 6 then -- 7-Chevron addresses
                buttonProperties.x = localPos.x
                buttonProperties.y = localPos.y

                if localPos.x == originButtonX then
                    localPos.x = secondButtonX
                else
                    localPos.x = originButtonX
                    localPos.y = localPos.y + 1
                end

				localList:addButton(buttonProperties)
				    :onClick(buttonFunction)			
			elseif #addressTable == 7 then -- 8-Chevron addresses
                buttonProperties.x = galacticPos.x
                buttonProperties.y = galacticPos.y

                if galacticPos.x == originButtonX then
                    galacticPos.x = secondButtonX
                else
                    galacticPos.x = originButtonX
                    galacticPos.y = galacticPos.y + 1
                end

				galacticList:addButton(buttonProperties)
				    :onClick(buttonFunction)
			elseif #addressTable == 8 then -- 9-Chevron Addresses
                buttonProperties.x = directPos.x
                buttonProperties.y = directPos.y

                if directPos.x == originButtonX then
                    directPos.x = secondButtonX
                else
                    directPos.x = originButtonX
                    directPos.y = directPos.y + 1
                end

                directList:addButton(buttonProperties)
				    :onClick(buttonFunction)
			end
		end
	end
end

function createDebugTab(tabControl)
	local debugTab = tabControl:newTab("Debug")

	debugTab:addLabel({
		x = 1,
		y = 2,
		text = "Gate Info",
		foreground = colors.orange,
	})
	gateGenLabel = debugTab:addLabel({
		x = 1,
		y = 3,
		text = "Generation:",
		foreground = colors.yellow,
	})

	networkLabel = debugTab:addLabel({
		x = 1,
		y = 4,
		text = "Network:",
		foreground = colors.yellow,
	})

	debugTab:addLabel({
		x = 1,
		y = 6,
		text = "Gate Address:",
		foreground = colors.orange,
	})

	localAddressLabel = debugTab:addLabel({
		x = 1,
		y = 7,
		text = "",
		foreground = colors.yellow,
	})

	debugTab:addLabel({
		x = 1,
		y = 10,
		text = "Interface:",
		foreground = colors.orange,
	})
	interfaceLabel = debugTab:addLabel({
		x = 1,
		y = 11,
		width = 25,
		height = 2,
		text = "",
		autoSize = false,
		foreground = colors.yellow,
	})
end

function createInterface(basalt)

    local main = basalt.createFrame()
	main:setBackground(colors.gray)



	createDialTab(main, AddressBook.getAddressBook())
end

return {
	createInterface = createInterface,
}
