TerminalUI = {
	ConsoleFrame = nil,
	TabControl = nil,
	Input = nil,
	Index = 1,
	AddressFrame = nil,
	AddressTable = nil,
}

AddressEditor = {
	EditorFrame = nil,
	openEmptyEditor = (function()
		if AddressEditor.EditorFrame.disabled then
			AddressEditor.EditorFrame:find("address_input").text = ""
			AddressEditor.EditorFrame:find("id_input").text = ""
			AddressEditor.EditorFrame:find("id_input").disabled = false
			AddressEditor.EditorFrame:find("display_input").text = ""
			AddressEditor.EditorFrame:find("hidden_checkbox").checked = false
			AddressEditor.EditorFrame:find("iris_auto_open_checkbox").checked = false
			AddressEditor.EditorFrame:find("sirens_checkbox").checked = false
			AddressEditor.EditorFrame:find("restricted_checkbox").checked = false
			AddressEditor.EditorFrame:find("idc_input").text = ""

			AddressEditor.EditorFrame.disabled = false
			AddressEditor.EditorFrame.visible = true
			TerminalUI.TabControl.disabled = false
			AddressEditor.EditorFrame:focus()
		end
	end),
	openEditorWithData = (function(selectedRow)
		if selectedRow ~= nil then
			address = AddressBook.getAddressFromIDOrAddress(selectedRow[1])
			if AddressEditor.EditorFrame.disabled and address ~= nil then
				AddressEditor.EditorFrame:find("address_input").text = address.address
				AddressEditor.EditorFrame:find("id_input").text = address.id
				AddressEditor.EditorFrame:find("id_input").disabled = true
				AddressEditor.EditorFrame:find("display_input").text = address.display
				AddressEditor.EditorFrame:find("hidden_checkbox").checked = address.hidden
				AddressEditor.EditorFrame:find("iris_auto_open_checkbox").checked = address.security.irisAutoOpen
				AddressEditor.EditorFrame:find("sirens_checkbox").checked = address.security.sirens
				AddressEditor.EditorFrame:find("restricted_checkbox").checked = address.security.restricted
				AddressEditor.EditorFrame:find("idc_input").text = address.security.IDC or ""

				AddressEditor.EditorFrame.disabled = false
				AddressEditor.EditorFrame.visible = true
				TerminalUI.TabControl.disabled = false
				AddressEditor.EditorFrame:focus()
			end
		end
	end),
	saveAddress = (function()
		if AddressEditor.EditorFrame:find("address_input"):getText() ~= nil and AddressEditor.EditorFrame:find("id_input"):getText() ~= nil then
			Wireless.transmitMessage({
				type = "address_creation",
				content = {
					address = AddressEditor.EditorFrame:find("address_input"):getText(),
					id = AddressEditor.EditorFrame:find("id_input"):getText(),
					display = AddressEditor.EditorFrame:find("display_input"):getText() or
					AddressEditor.EditorFrame:find("id_input"):getText(),
					hidden = AddressEditor.EditorFrame:find("hidden_checkbox").checked,
					security = {
						irisAutoOpen = AddressEditor.EditorFrame:find("iris_auto_open_checkbox").checked,
						sirens = AddressEditor.EditorFrame:find("sirens_checkbox").checked,
						restricted = AddressEditor.EditorFrame:find("restricted_checkbox").checked,
						IDC = AddressEditor.EditorFrame:find("idc_input"):getText()
					},
				}
			})
		end
		Basalt.schedule(function()
			sleep(1)
			resyncAddresses()
		end)
		AddressEditor.closeEditor()
	end),
	shareAddress = (function(selectedRow)
		if selectedRow ~= nil then
			address = AddressBook.getAddressFromIDOrAddress(selectedRow[1])
			if address ~= nil then
				os.queueEvent("basalt_command", "share " .. address.address)
			end
		end
	end),
	closeEditor = function()
		TerminalUI.ConsoleFrame:focus()
		AddressEditor.EditorFrame.disabled = true
		AddressEditor.EditorFrame.visible = false
		TerminalUI.TabControl.disabled = false
	end,
	createEditor = function()
		local scope = {
			saveAddress = function(self)
				AddressEditor.saveAddress()
			end,
			closeEditor = function(self)
				AddressEditor.closeEditor()
			end
		}

		AddressEditor.EditorFrame = TerminalUI.AddressFrame:addFrame({
			x = 3,
			y = 3,
			width = 47,
			height = 13,
			background = colors.black
		})

		BasaltXml.loadFile(AddressEditor.EditorFrame, "display/terminal/addresseditor.xml", scope)
		AddressEditor.EditorFrame.disabled = true
		AddressEditor.EditorFrame.visible = false
	end
}

local deleteDialog = nil


function resyncAddresses()
	Wireless.clientSyncDataFromServer("addresses")
end

function createConsoleTab(tabControl)
	local consoleTab = tabControl:addTab("Console")

	TerminalUI.ConsoleFrame = consoleTab:addFrame({
		x = 2,
		y = 2,
		width = 49,
		height = 15,
		scrollable = true,
		scrollbar = "auto",
		background = colors.gray,
		foreground = colors.white,
	})

	TerminalUI.Input = consoleTab:addInput({
		x = 2,
		y = 17,
		width = 49,
		height = 1,
		background = colors.magenta,
		foreground = colors.white,
	})

	consoleTab:focus()
end

function refreshAddressesTab()
	if TerminalUI.AddressTable ~= nil then
		TerminalUI.AddressTable:destroy()
	end

	TerminalUI.AddressTable = TerminalUI.AddressFrame:addTable({
		x = 2,
		y = 2,
		width = 49,
		height = 15,
		scrollable = true,
		scrollbar = "auto",
		columns = {
			{ title = "ID",      width = 12 },
			{ title = "Display", width = 18 },
			{ title = "",        width = 19 }
		},
	})

	local addrBook = AddressBook.getAddressBook()
	for i, addr in pairs(addrBook) do
		local addressTable = AddressBook.stringToTable(addr.address)
		local row = TerminalUI.AddressTable:addRow({ addr.id, addr.display })
		row.background = colors.lightGray
	end


	AddressEditor.createEditor()
end

function createAddressesTab(tabControl)
	TerminalUI.AddressFrame = tabControl:addTab("Addresses")

	refreshAddressesTab()

	deleteDialog = TerminalUI.AddressFrame:addDialog({
		boxWidth = 32,
		titleBackground = colors.blue,
		boxBackground = colors.lightGray,
		boxForeground = colors.black,
	})

	TerminalUI.AddressFrame:addButton({ x = 2, y = 17, width = 8, text = "Add", height = 1, background = colors.green })
		:onClick(function(self, checked) AddressEditor.openEmptyEditor() end)

	TerminalUI.AddressFrame:addButton({
		x = 11,
		y = 17,
		width = 8,
		text = "Edit",
		height = 1,
		background = colors
			.orange
	})
		:onClick(function(self, checked) AddressEditor.openEditorWithData(TerminalUI.AddressTable:getSelectedRow()) end)

	TerminalUI.AddressFrame:addButton({ x = 20, y = 17, width = 8, text = "Share", height = 1, background = colors.cyan })
		:onClick(function(self, checked) AddressEditor.shareAddress(TerminalUI.AddressTable:getSelectedRow()) end)

	TerminalUI.AddressFrame:addButton({ x = 29, y = 17, width = 8, text = "Delete", height = 1, background = colors.red })
		:onClick(function(self, checked) confirmDelete(TerminalUI.AddressTable:getSelectedRow()) end)


	TerminalUI.AddressFrame:addButton({ x = 41, y = 17, text = "Resync", height = 1, background = colors.purple })
		:onClick(function(self, checked) resyncAddresses() end)

	AddressEditor.createEditor()
end

function confirmDelete(selectedRow)
	if selectedRow ~= nil then
		deleteDialog:confirm("Continue?", "Are you sure you want to delete " .. selectedRow[1] .. "?", function(yes)
			if yes then
				os.queueEvent("basalt_command", "addr del " .. selectedRow[1])

				Basalt.schedule(function()
					sleep(0.5)
					resyncAddresses()
				end)
			else
				deleteDialog:close()
			end
		end)
		deleteDialog:focus()
	end
end

function createInterface()
	local main = Basalt.createFrame(term.current())

	TerminalUI.TabControl = main:addTabControl({
		x = 1,
		y = 1,
		width = 51,
		height = 19,
		background = colors.black,
		headerBackground = colors.gray,
		activeBackground = colors.blue,
	})

	createConsoleTab(TerminalUI.TabControl)
	createAddressesTab(TerminalUI.TabControl)
end

return {
	listenConsoleLogRequest = listenConsoleLogRequest,
	listenInput = listenInput,
	createInterface = createInterface,
	refreshAddressesTab = refreshAddressesTab
}
