local basaltInit = false
	--Info Tab
local warningLabel = nil
local statusLabel = nil
local chevronsLabel = nil
local displayLabel = nil
local addressLabel = nil
local openTimeLabel = nil
local irisLabel = nil
local lockdownCheckbox = nil
local energyLabel = nil
local energyTagetLabel = nil
local feedbackLabel = nil

local chevronTable = nil

--Debug Tab
local gateGenLabel = nil
local interfaceLabel = nil
local localAddressLabel = nil
local networkLabel = nil
local fastDialCheckbox = nil


function createInfoTab(tabControl)
	local infoTabMaster = tabControl:newTab("Info")
	
	local infoTabControl = infoTabMaster:addTabControl({
		x = 1,
		y = 1,
		width = 29,
		height = 25,
		background = colors.black,
	})

	local infoStargate = infoTabControl:newTab("Stargate")


	warningLabel = infoStargate:addLabel({
		x = 2,
		y = 2,
		foreground = colors.red,
		text = "",
	})
	infoStargate:addLabel({
		x = 2,
		y = 4,
		text = "Stargate Status:",
		foreground = colors.orange,
	})
	chevronsLabel = infoStargate:addLabel({
		x = 2,
		y = 5,
		text = "Chevrons:",
		foreground = colors.yellow
	})
	openTimeLabel = infoStargate:addLabel({
		x = 2,
		y = 6,
		text = "Open ticks:",
		foreground = colors.yellow
	})
	statusLabel = infoStargate:addLabel({
		x = 2,
		y = 8,
		text = "Idle",
		foreground = colors.yellow,
	})
	displayLabel = infoStargate:addLabel({
		x = 2,
		y = 9,
		text = "Origin: ",
		foreground = colors.yellow,
	})
	addressLabel = infoStargate:addLabel({
		x = 2,
		y = 10,
		text = "Address: N/A",
		foreground = colors.yellow,
	})

	infoStargate:addLabel({
		x = 2,
		y = 23,
		text = "Feedback: ",
		foreground = colors.orange,
	})
	feedbackLabel = infoStargate:addLabel({
		x = 2,
		y = 24,
		width = 25,
		height = 2,
		text = "",
		autoSize = false,
		foreground = colors.yellow,
	})

	local infoSecurity = infoTabControl:newTab("Security")

	infoSecurity:addLabel({
		x = 2,
		y = 12,
		text = "Security",
		foreground = colors.orange,
	})

	irisLabel = infoSecurity:addLabel({
		x = 2,
		y = 13,
		text = "N/A",
		foreground = colors.yellow,
	})

	IrisCloseButton = infoSecurity:addButton({
			x = 2,
			y = 14,
			width = 6,
			height = 1,
			text = "Close",
			foreground = colors.white,
			background = colors.red,
		})
		:setBackgroundState("clicked", colors.lightBlue)
		:onClick(function()
			os.queueEvent("basalt_command", "iris close")
		end)

	IrisOpenButton = infoSecurity:addButton({
			x = 10,
			y = 14,
			width = 6,
			height = 1,
			text = "Open",
			foreground = colors.white,
			background = colors.green,
		})
		:setBackgroundState("clicked", colors.lightBlue)
		:onClick(function()
			os.queueEvent("basalt_command", "iris open")
		end)
	lockdownCheckbox = infoSecurity:addCheckBox({
			x = 2,
			y = 16,
			height = 1,
			text = "Lockdown: Inactive",
			checkedText = "Lockdown: Active",
			foreground = colors.yellow
		})
		:onChange("checked", function(self, checked)
			os.queueEvent("basalt_command", string.format("togglealarms %s", tostring(checked)))
		end)


	local infoEnergy = infoTabControl:newTab("Energy")	

	infoEnergy:addLabel({
		x = 2,
		y = 18,
		text = "Energy Info",
		foreground = colors.orange,
	})
	energyLabel = infoEnergy:addLabel({
		x = 2,
		y = 19,
		text = "Energy: ",
		foreground = colors.yellow,
	})

	infoEnergy:addButton({
			x = 2,
			y = 20,
			width = 13,
			height = 1,
			text = "Disconnect",
			foreground = colors.white,
			background = colors.red,
		})
		:setBackgroundState("clicked", colors.lightBlue)
		:onClick(function()
			os.queueEvent("basalt_command", "disconnect")
		end)
end

function createDialTab(tabControl, addressBook)
	local dialTab = tabControl:newTab("Dial")

	-- Fast Dial Checkbox
	dialTab:addLabel({
		x = 2,
		y = 2,
		text = "Fast Dial:",
		foreground = colors.orange,
	})
	fastDial = dialTab
		:addCheckBox({
			x = 13,
			y = 2,
			text = "[ ]",
			checkedText = "[X]",
			foreground = colors.yellow,
		})

	local addressList = {}

	for i, addr in pairs(addressBook) do
		if not addr.hidden then
			if addressList[addr.category] == nil then
				addressList[addr.category] = { addr }
			else
				table.insert(addressList[addr.category], addr)
			end
		end
	end

	local scrollFrame = dialTab:addScrollFrame({
		x = 2,
		y = 3,
		width = 27,
		height = 22,
		background = colors.gray,
	})

	posX = 2
	posY = 1

	for category, addresses in pairs(addressList) do
		posX = 2
		posY = posY + 1

		scrollFrame:addLabel({
			x = posX,
			y = posY,
			text = category,
			foreground = colors.orange,
		})
		posY = posY + 1

		--print(category[1] .. " " .. #category[2])

		for i, address in pairs(addresses) do
			scrollFrame
				:addButton({
					x = posX,
					y = posY,
					width = 10,
					height = 1,
					text = address.display,
					foreground = colors.white,
					background = colors.blue,
				})
				:setBackgroundState("clicked", colors.lightBlue)
				:onClick(function()
					if fastDial.checked then
						os.queueEvent("basalt_command", "fdial " .. address.id)
					else
						os.queueEvent("basalt_command", "dial " .. address.id)
					end
				end)

			if posX == 2 then
				posX = 13
			else
				posX = 2
				posY = posY + 1
			end
		end
	end
end

function createDebugTab(tabControl)
	local debugTab = tabControl:newTab("Debug")

	debugTab:addLabel({
		x = 2,
		y = 2,
		text = "Gate Info",
		foreground = colors.orange,
	})
	gateGenLabel = debugTab:addLabel({
		x = 2,
		y = 3,
		text = "Generation:",
		foreground = colors.yellow,
	})

	networkLabel = debugTab:addLabel({
		x = 2,
		y = 4,
		text = "Network:",
		foreground = colors.yellow,
	})

	debugTab:addLabel({
		x = 2,
		y = 6,
		text = "Gate Address:",
		foreground = colors.orange,
	})

	localAddressLabel = debugTab:addLabel({
		x = 2,
		y = 7,
		text = "",
		foreground = colors.yellow,
	})

	debugTab:addLabel({
		x = 2,
		y = 10,
		text = "Interface:",
		foreground = colors.orange,
	})
	interfaceLabel = debugTab:addLabel({
		x = 2,
		y = 11,
		width = 25,
		height = 2,
		text = "",
		autoSize = false,
		foreground = colors.yellow,
	})

	chevronTable = debugTab
		:addTable({
			x = 2,
			y = 14,
			background = colors.black,
			foreground = colors.yellow,
		})
		:setColumns({
			{ name = "Chevron", width = 12 },
			{ name = "Status", width = 8 },
		})
		:addRow("Chevron 1", "Idle")
		:addRow("Chevron 2", "Idle")
		:addRow("Chevron 3", "Idle")
		:addRow("Chevron 4", "Idle")
		:addRow("Chevron 5", "Idle")
		:addRow("Chevron 6", "Idle")
		:addRow("Chevron 7", "Idle")
		:addRow("Chevron 8", "Idle")
		:addRow("Chevron 9", "Idle")
end

function listenBasaltDataUpdate() -- "data_update"
	while true do
		local event, data = os.pullEvent("data_update")

		--Info Tab
		warningLabel:setText(data.warning)
		statusLabel:setText(data.status)
		chevronsLabel:setText("Chevrons Engaged: " .. data.basic.chevronsEngaged)
		displayLabel:setText(data.activeAddress.display)
		addressLabel:setText(data.activeAddress.address:sub(2, -2))
		openTimeLabel:setText("Open Time: " .. Helpers.ticksToMinutesSeconds(data.basic.openTime))
		irisLabel:setText(data.iris)
		energyLabel:setText(
			string.format(
				"Energy: %s/%s",
				Helpers.convertToPowerUnits(data.basic.gateEnergy),
				Helpers.convertToPowerUnits(data.basic.gateEnergyTarget)
			)
		)
		feedbackLabel:setText(GateFeedbackCodes[data.basic.feedbackCode])

		--Debug Tab
		gateGenLabel:setText("Generation: " .. GateGeneration[data.basic.generation])
		interfaceLabel:setText(data.basic.interface:sub(1,-2))

		if data.advanced.available then
			localAddressLabel:setText(data.advanced.localAddress)
			networkLabel:setText("Network: " .. data.advanced.network)
		else
			localAddressLabel:setText("Unavailable")
			networkLabel:setText("Network: Unavailable")
		end
		
	end
end

function listenBasaltChevronUpdate() -- "basalt_chevron_update"
	while true do
		local event, data = os.pullEvent("basalt_chevron_update")

		for i, state in pairs(data) do
			chevronTable:updateCell(i, 2, state)
		end
	end
end

function createInterface(basalt)
	local main = basalt.createFrame():setTerm(Monitor)

	local tabControl = main:addTabControl({
		x = 1,
		y = 1,
		width = 29,
		height = 26,
		background = colors.black,
	})

	createInfoTab(tabControl)
	createDialTab(tabControl, AddressBook.getAddressBook())
	createDebugTab(tabControl)

	basalt.schedule(function()
		parallel.waitForAny(listenBasaltDataUpdate, listenBasaltChevronUpdate)
	end)
end

return {
	createInterface = createInterface,
}
