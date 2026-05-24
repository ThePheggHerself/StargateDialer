local basaltInit = false
--Info Tab
local warningLabel = nil
local statusLabel = nil
local chevronsLabel = nil
local displayLabel = nil
local addressLabel = nil
local openTimeLabel = nil
local irisLabel = nil
local irisDuraLabel = nil
local energyLabel = nil
local interfaceEnergyLabel = nil
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
		:addScrollFrame({ x = 1, y = 1, width = 29, height = 50, background = colors.black })
		:loadXML([[
		<label x="2" y="4" text="Stargate Status:" foreground="orange"/>
		<label x="2" y="12" text="Iris Status:" foreground="orange"/>
		<button x="2" y="16" width="10" height="1" text="Close" background="red" foreground="white" onClick="closeIris"/>
		<button x="14" y="16" width="10" height="1" text="Open" background="green" foreground="white" onClick="openIris"/>

		<label x="2" y="18" text="Controls:"/>
		<button x="2" y="20" width="13" height="1" text="Disconnect" background="red" foreground="white" onClick="disconnect"/>
		<button x="16" y="20" width="10" height="1" text="Sirens" background="red" foreground="white" onClick="toggleSirens"/>


		<label x="2" y="22" text="Energy Info" foreground="orange"/>

		

		<label x="2" y="26" text="Feedback Status:" foreground="orange"/>
	]], scope)

	warningLabel = infoTab:addLabel({ x = 2, y = 2, foreground = colors.red, text = "" })
	chevronsLabel = infoTab:addLabel({ x = 2, y = 5, text = "Chevrons:", foreground = colors.yellow })
	openTimeLabel = infoTab:addLabel({ x = 2, y = 6, text = "Open ticks:", foreground = colors.yellow })
	statusLabel = infoTab:addLabel({ x = 2, y = 8, text = "Idle", foreground = colors.yellow })
	displayLabel = infoTab:addLabel({ x = 2, y = 9, text = "Origin: ", foreground = colors.yellow })
	addressLabel = infoTab:addLabel({ x = 2, y = 10, text = "Address: N/A", foreground = colors.yellow })
	irisLabel = infoTab:addLabel({ x = 2, y = 13, text = "N/A", foreground = colors.yellow, })
	irisDuraLabel = infoTab:addLabel({ x = 2, y = 14, width = 38, text = "", foreground = colors.yellow, })

	energyLabel = infoTab:addLabel({ x = 2, y = 23, text = "Gate Energy: ", foreground = colors.yellow })
	interfaceEnergyLabel = infoTab:addLabel({ x = 2, y = 24, text = "Interface Energy: ", foreground = colors.yellow })

	feedbackLabel = infoTab:addLabel({ x = 2, y = 27, text = "", foreground = colors.yellow })
end

function createDialTab(tabControl)
	DialTab = tabControl:newTab("Dial")

	-- Fast Dial Checkbox
	DialTab:addLabel({
		x = 2,
		y = 2,
		text = "Fast Dial:",
		foreground = colors.orange,
	})
	fastDialCheckbox = DialTab:addCheckBox({
		x = 13,
		y = 2,
		text = "[ ]",
		checkedText = "[X]",
		foreground = colors.yellow,
	})

	DialTab:addButton({
		x = 17,
		y = 2,
		width = 19,
		height = 1,
		text = "Abort/Disconnect",
		foreground = colors.white,
		background = colors.red
	})
		:onClick(function()
			os.queueEvent("basalt_command", "disconnect")
		end)

	refreshDialTab()
end

function listenBasaltAddressUpdate()
	while true do
		local event, data = os.pullEvent("basalt_address_update")

		if DialTab == nil then
			return
		end

		AddressTab:clear()

		refreshDialTab()
	end
end

function refreshDialTab()
	local addressBook = AddressBook.getAddressBook()

	AddressTab = DialTab:addTabControl({
		x = 2,
		y = 4,
		width = 34,
		height = 34,
		background = colors.gray,
		headerBackground = colors.cyan,
		activeTabBackground = colors.lightBlue
	})

	local localList = AddressTab:newTab("7-Chevron")
	local galacticList = AddressTab:newTab("8-Chevron")
	local directList = AddressTab:newTab("9-Chevron")

	local localPos = { x = 2, y = 2 }
	local galacticPos = { x = 2, y = 2 }
	local directPos = { x = 2, y = 2 }

	for i, addr in pairs(addressBook) do
		local addressTable = AddressBook.stringToTable(addr.address)

		if not addr.hidden then
			local color = colors.green
			if addr.security.restricted then
				color = colors.red
			end

			if #addressTable == 7 then -- 7-Chevron addresses
				localList:addButton({
					x = localPos.x,
					y = localPos.y,
					width = 15,
					height = 1,
					text = addr.display,
					foreground = colors.white,
					background = color
				})
					:onClick(function()
						if fastDialCheckbox.checked then
							os.queueEvent("basalt_command", "fdial " .. addr.address)
						else
							os.queueEvent("basalt_command", "dial " .. addr.address)
						end
					end)

				if localPos.x == 2 then
					localPos.x = 19
				else
					localPos.x = 2
					localPos.y = localPos.y + 1
				end
			elseif #addressTable == 8 then -- 8-Chevron addresses
				galacticList:addButton({
					x = galacticPos.x,
					y = galacticPos.y,
					width = 15,
					height = 1,
					text = addr.display,
					foreground = colors.white,
					background = color
				})
					:onClick(function()
						if fastDialCheckbox.checked then
							os.queueEvent("basalt_command", "fdial " .. addr.address)
						else
							os.queueEvent("basalt_command", "dial " .. addr.address)
						end
					end)

				if galacticPos.x == 2 then
					galacticPos.x = 19
				else
					galacticPos.x = 2
					galacticPos.y = galacticPos.y + 1
				end
			elseif #addressTable == 9 then -- 9-Chevron Addresses
				directList:addButton({
					x = directPos.x,
					y = directPos.y,
					width = 15,
					height = 1,
					text = addr.display,
					foreground = colors.white,
					background = color
				})
					:onClick(function()
						if fastDialCheckbox.checked then
							os.queueEvent("basalt_command", "fdial " .. addr.address)
						else
							os.queueEvent("basalt_command", "dial " .. addr.address)
						end
					end)

				if directPos.x == 2 then
					directPos.x = 19
				else
					directPos.x = 2
					directPos.y = directPos.y + 1
				end
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
			{ name = "Status",  width = 8 },
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

function updateGateData() -- "data_update"
	while true do
		local event, data = os.pullEvent("data_update")

		--Info Tab
		warningLabel:setText(data.warning)
		statusLabel:setText(data.status)
		chevronsLabel:setText("Chevrons Engaged: " .. data.basic.chevronsEngaged)
		displayLabel:setText(data.activeAddress.display)
		addressLabel:setText(data.activeAddress.address:sub(2, -2))
		openTimeLabel:setText("Open Time: " .. Helpers.ticksToMinutesSeconds(data.basic.openTime))
		irisLabel:setText(data.iris.status)

		if data.iris.maxDurability ~= nil and data.iris.maxDurability > 0 then
			irisDuraLabel:setText(
				string.format(
					"Durability: %d%%",
					math.floor(data.iris.durability / data.iris.maxDurability * 100)
				)
			)
		end


		energyLabel:setText(
			string.format(
				"Gate Energy: %s/%s",
				Helpers.convertToPowerUnits(data.basic.gateEnergy),
				Helpers.convertToPowerUnits(data.basic.gateEnergyTarget)
			)
		)
		interfaceEnergyLabel:setText(
			string.format(
				"Interface Energy: %s/%s",
				Helpers.convertToPowerUnits(data.basic.interfaceEnergy),
				Helpers.convertToPowerUnits(data.basic.interfaceEnergyCapacity)
			)
		)
		feedbackLabel:setText(data.basic.feedbackCode)

		--Debug Tab
		gateGenLabel:setText("Generation: " .. GateGeneration[data.basic.generation])
		interfaceLabel:setText(data.basic.interface)

		if data.advanced.available then
			localAddressLabel:setText(data.advanced.localAddress)
			networkLabel:setText("Network: " .. data.advanced.network)
		else
			localAddressLabel:setText("Unavailable")
			networkLabel:setText("Network: Unavailable")
		end

		for i, state in pairs(data.chevrons) do
			chevronTable:updateCell(i, 2, state)
		end
	end
end

function createInterface(basalt)
	Monitor.setTextScale(0.5)

	local x, y = Monitor.getSize()

	local main = basalt.createFrame():setTerm(Monitor)

	local tabControl = main:addTabControl({
		x = 1,
		y = 1,
		width = x,
		height = y,
		background = colors.black,
		headerBackground = colors.cyan,
		activeTabBackground = colors.lightBlue
	})

	createInfoTab(tabControl)
	createDialTab(tabControl)
	createDebugTab(tabControl)

	basalt.schedule(function()
		parallel.waitForAny(updateGateData, refreshDialTab)
	end)
end

return {
	createInterface = createInterface,
	updateGateData = updateGateData
}
