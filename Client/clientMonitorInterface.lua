MonitorUI = {
	InfoFrame = nil,
	AddressFrame = nil,
	DebugFrame = nil
}

local fastDialCheckbox = nil
local chevronTable = nil


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
	MonitorUI.InfoFrame = tabControl:addTab("Info")
	BasaltXml.loadFile(MonitorUI.InfoFrame, "display/monitor/infotab.xml", scope)
end

function createDialTab(tabControl)
	DialTab = tabControl:addTab("Dial")

	-- Fast Dial Checkbox
	DialTab:addLabel({
		x = 2,
		y = 2,
		text = "Fast Dial:",
		foreground = colors.orange,
	})
	fastDialCheckbox = DialTab:addCheckbox({
		x = 13,
		y = 2,
		text = "[ ]",
		checkedText = "[X]",
		foreground = colors.yellow,
		checked = true
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

function createDebugTab(tabControl)
	MonitorUI.DebugFrame = tabControl:addTab("Debug")
	BasaltXml.loadFile(MonitorUI.DebugFrame, "display/monitor/debugtab.xml")

	chevronTable = MonitorUI.DebugFrame
		:addTable({
			x = 2,
			y = 18,
			height = 11,
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


function refreshDialTab()
	local addressBook = AddressBook.getAddressBook()

	if MonitorUI.AddressFrame ~= nil then
		MonitorUI.AddressFrame:destroy()
	end

	MonitorUI.AddressFrame = DialTab:addTabControl({
		x = 2,
		y = 4,
		width = 34,
		height = 34,
		background = colors.gray,
		headerBackground = colors.cyan,
		activeTabBackground = colors.lightBlue
	})

	local localList = MonitorUI.AddressFrame:addTab("7-Chevron")
	local galacticList = MonitorUI.AddressFrame:addTab("8-Chevron")
	local directList = MonitorUI.AddressFrame:addTab("9-Chevron")

	local localPos = { x = 2, y = 2 }
	local galacticPos = { x = 2, y = 2 }
	local directPos = { x = 2, y = 2 }


	local addressBook = AddressBook.getAddressBook()
	local tempAddrTable = {}

	for _, address in pairs(addressBook) do
		table.insert(tempAddrTable, { address.id, address.display })
	end

	local function sortingFunction(tAddr1, tAddr2)
		return tAddr1[2] < tAddr2[2]
	end

	table.sort(tempAddrTable, sortingFunction)

	for i, tempAddr in pairs(tempAddrTable) do
		local addr = addressBook[tempAddr[1]]
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

function refreshGateData() -- "data_update"
	while true do
		local event, data = os.pullEvent("data_update")

		MonitorUI.InfoFrame:find("warning_label"):setText(data.warning)
		MonitorUI.InfoFrame:find("status_label"):setText(data.status)

		if data.status ~= "Missing" then
			--Info Tab
			MonitorUI.InfoFrame:find("chevrons_label"):setText("Chevrons Engaged: " .. (data.basic.chevronsEngaged or "N/A"))
			MonitorUI.InfoFrame:find("display_label"):setText(data.activeAddress.display)
			MonitorUI.InfoFrame:find("address_label"):setText(data.activeAddress.address:sub(2, -2))
			MonitorUI.InfoFrame:find("open_time_label"):setText("Open Time: " .. (Helpers.ticksToMinutesSeconds(data.basic.openTime) or "N/A"))
			MonitorUI.InfoFrame:find("iris_label"):setText(data.iris.status)

			if data.iris.maxDurability ~= nil and data.iris.maxDurability > 0 then
				MonitorUI.InfoFrame:find("iris_durability_label"):setText(
					string.format(
						"Durability: %d%%",
						math.floor(data.iris.durability / data.iris.maxDurability * 100)
					)
				)
			end


			MonitorUI.InfoFrame:find("gate_energy_label"):setText(
				string.format(
					"Gate Energy: %s/%s",
					Helpers.convertToPowerUnits(data.basic.gateEnergy) or "N/A",
					Helpers.convertToPowerUnits(data.basic.gateEnergyTarget) or "N/A"
				)
			)
			MonitorUI.InfoFrame:find("interface_energy_label"):setText(
				string.format(
					"Interface Energy: %s/%s",
					Helpers.convertToPowerUnits(data.basic.interfaceEnergy) or "N/A",
					Helpers.convertToPowerUnits(data.basic.interfaceEnergyCapacity) or "N/A"
				)
			)
			MonitorUI.InfoFrame:find("feedback_label"):setText(data.basic.feedbackCode or "N/A")

			--Debug Tab
			MonitorUI.DebugFrame:find("gate_generation_label"):setText("Generation: " .. GateGeneration[data.basic.generation or -1])
			MonitorUI.DebugFrame:find("interface_label"):setText(data.basic.interface or "N/A")

			if data.advanced.available then
				MonitorUI.DebugFrame:find("gate_address_label"):setText(data.advanced.localAddress or "N/A")
				MonitorUI.DebugFrame:find("gate_networks_label"):setText("Networks: [" .. (table.concat(data.advanced.network, ", ") or "N/A") .. "]")
			else
				MonitorUI.DebugFrame:find("gate_address_label"):setText("Unavailable")
				MonitorUI.DebugFrame:find("gate_networks_label"):setText("Network: Unavailable")
			end

			for i, state in pairs(data.chevrons) do
				chevronTable:updateCell(i, 2, state)
			end
		end
	end
end


function createInterface()
	Monitor.setTextScale(0.5)

	local x, y = Monitor.getSize()

	local main = Basalt.createFrame(Monitor)

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
end

return {
	createInterface = createInterface,
	refreshGateData = refreshGateData,
	listenBasaltAddressUpdate = listenBasaltAddressUpdate
}
