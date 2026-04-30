local basaltInit = false
--Info Tab
local warningLabel = nil
local statusLabel = nil
local chevronsLabel = nil
local displayLabel = nil
local addressLabel = nil
local openTimeLabel = nil
local irisLabel = nil
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
	local scope = {
		closeIris = function(self)
			os.queueEvent("basalt_command", "iris close")
		end,
		openIris = function(self)
			os.queueEvent("basalt_command", "iris open")
		end,
		disconnect = function(self)
			os.queueEvent("basalt_command", "disconnect")
		end,
		toggleSirens = function(self)
			os.queueEvent("basalt_command", "togglealarms false")
		end
	}
	local infoTab = tabControl:newTab("Info")
	:addScrollFrame({x = 1,y = 1, width = 29, height = 50, background = colors.black })
	:loadXML([[
		<label x="2" y="4" text="Stargate Status:" foreground="orange"/>
		<label x="2" y="12" text="Iris Status:" foreground="orange"/>
		<button x="2" y="15" width="10" height="1" text="Close" background="red" foreground="white" onClick="closeIris"/>
		<button x="14" y="15" width="10" height="1" text="Open" background="green" foreground="white" onClick="openIris"/>
		<label x="2" y="17" text="Energy Info" foreground="orange"/>

		<button x="2" y="20" width="13" height="1" text="Disconnect" background="red" foreground="white" onClick="disconnect"/>
		<button x="16" y="20" width="10" height="1" text="Sirens" background="red" foreground="white" onClick="toggleSirens"/>

		<label x="2" y="23" text="Feedback Status:" foreground="orange"/>
	]], scope)

	warningLabel = infoTab:addLabel({ x = 2, y = 2, foreground = colors.red, text = "" })
	chevronsLabel = infoTab:addLabel({ x = 2, y = 5, text = "Chevrons:", foreground = colors.yellow })
	openTimeLabel = infoTab:addLabel({ x = 2, y = 6, text = "Open ticks:", foreground = colors.yellow })
	statusLabel = infoTab:addLabel({ x = 2, y = 8, text = "Idle", foreground = colors.yellow })
	displayLabel = infoTab:addLabel({ x = 2, y = 9, text = "Origin: ", foreground = colors.yellow })
	addressLabel = infoTab:addLabel({ x = 2, y = 10, text = "Address: N/A", foreground = colors.yellow })	
	irisLabel = infoTab:addLabel({x = 2,y = 13,text = "N/A",foreground = colors.yellow,})

	energyLabel = infoTab:addLabel({x = 2,y = 18,text = "Energy: ",foreground = colors.yellow})

	feedbackLabel = infoTab:addLabel({ x = 2, y = 24, text = "", foreground = colors.yellow })
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
	fastDial = dialTab:addCheckBox({
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
				scrollFrame:addButton({
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
		interfaceLabel:setText(data.basic.interface:sub(1, -2))

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
