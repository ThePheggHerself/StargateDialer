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
	Address = nil,
	Id = nil,
	Display = nil,
	Hidden = nil,
	Security = {
		irisAutoOpen = nil,
		sirens = nil,
		restricted = nil,
	},
	openEmptyEditor = (function ()
		if AddressEditor.EditorFrame.disabled then
			AddressEditor.Address.text = ""
			AddressEditor.Id.text = ""
			AddressEditor.Id.disabled = false
			AddressEditor.Display.text = ""
			AddressEditor.Hidden.checked = false
			AddressEditor.Security.irisAutoOpen.checked = false
			AddressEditor.Security.sirens.checked = false
			AddressEditor.Security.restricted.checked = false
		
			AddressEditor.EditorFrame.disabled = false
			AddressEditor.EditorFrame.visible = true
			TerminalUI.TabControl.disabled = false
			AddressEditor.EditorFrame:focus()
		end
	end),
	openEditorWithData = (function (address)
		if AddressEditor.EditorFrame.disabled and address ~= nil then
			AddressEditor.Address.text = address.address
			AddressEditor.Id.text = address.id
			AddressEditor.Id.disabled = true
			AddressEditor.Display.text = address.display
			AddressEditor.Hidden.checked = address.hidden
			AddressEditor.Security.irisAutoOpen.checked = address.security.irisAutoOpen
			AddressEditor.Security.sirens.checked = address.security.sirens
			AddressEditor.Security.restricted.checked = address.security.restricted
		
			AddressEditor.EditorFrame.disabled = false
			AddressEditor.EditorFrame.visible = true
			TerminalUI.TabControl.disabled = false
			AddressEditor.EditorFrame:focus()
		end
	end),
	saveAddress = (function ()
		if AddressEditor.Address ~= nil then
			Wireless.transmitMessage({type = "address_creation", content = 
			{
				address = AddressEditor.Address:getText(),
				id = AddressEditor.Id:getText(),
				display = AddressEditor.Display:getText(),
				hidden = AddressEditor.Hidden.checked,
				security = {
					irisAutoOpen = AddressEditor.Security.irisAutoOpen.checked,
					sirens = AddressEditor.Security.sirens.checked,
					restricted = AddressEditor.Security.restricted.checked,
				},
			} })
		end
		Basalt.schedule(function ()
			sleep(1)
			resyncAddresses()
		end)
		AddressEditor.closeEditor()
	end),
	closeEditor = function ()
		TerminalUI.ConsoleFrame:focus()
		AddressEditor.EditorFrame.disabled = true
		AddressEditor.EditorFrame.visible = false
		TerminalUI.TabControl.disabled = false
	end,
	createEditor = function ()
		AddressEditor.EditorFrame = TerminalUI.AddressFrame:addFrame({
			x = 3,
			y = 3,
			width = 46,
			height = 13,
			background = colors.black
		})

		AddressEditor.EditorFrame:addLabel({x=1,y=1,text=" Address Details",foreground=colors.white, background=colors.cyan, width=51})
		AddressEditor.EditorFrame:addLabel({x=2,y=3,text="Display:",foreground=colors.yellow})
		AddressEditor.EditorFrame:addLabel({x=27,y=3,text="Id:",foreground=colors.yellow})
		AddressEditor.EditorFrame:addLabel({x=2,y=4,text="Address:",foreground=colors.yellow})
		AddressEditor.EditorFrame:addLabel({x=2,y=5,text="Hidden Address:",foreground=colors.yellow})

		AddressEditor.EditorFrame:addLabel({x=2,y=7,text="Security",foreground=colors.orange})
		AddressEditor.EditorFrame:addLabel({x=2,y=8,text="Iris Auto Open:",foreground=colors.yellow})
		AddressEditor.EditorFrame:addLabel({x=25,y=8,text="Sirens:",foreground=colors.yellow})
		AddressEditor.EditorFrame:addLabel({x=2,y=9,text="Restricted:",foreground=colors.yellow})

		AddressEditor.EditorFrame:addButton({x=2,y=12,text="Save",height=1,background=colors.green})
			:onClick(function(self, checked) AddressEditor.saveAddress() end)

		AddressEditor.EditorFrame:addButton({x=36,y=12,text="Cancel",height=1,background=colors.red})
			:onClick(function(self, checked) AddressEditor.closeEditor() end)

		AddressEditor.Display = AddressEditor.EditorFrame:addInput({
			x = 11,
			y = 3,
			width = 14,
			background = colors.gray,
			foreground = colors.white,
		})
		AddressEditor.Id = AddressEditor.EditorFrame:addInput({
			x = 31,
			y = 3,
			width = 10,
			background = colors.gray,
			foreground = colors.white,
		})

		AddressEditor.Address = AddressEditor.EditorFrame:addInput({
			x = 11,
			y = 4,
			width = 30,
			background = colors.gray,
			foreground = colors.white,
		})
	
		AddressEditor.Hidden = AddressEditor.EditorFrame:addCheckbox({
			x = 18,
			y = 5,
			foreground = colors.white,
		})
		AddressEditor.Security.irisAutoOpen = AddressEditor.EditorFrame:addCheckbox({
			x = 18,
			y = 8,
			foreground = colors.white,
		})
		AddressEditor.Security.sirens = AddressEditor.EditorFrame:addCheckbox({
			x = 33,
			y = 8,
			foreground = colors.white,
		})
		AddressEditor.Security.restricted = AddressEditor.EditorFrame:addCheckbox({
			x = 14,
			y = 9,
			foreground = colors.white,
		})

		AddressEditor.EditorFrame.disabled = true
		AddressEditor.EditorFrame.visible = false
	end
}

local deleteDialog = nil


function resyncAddresses()
	Wireless.clientSyncDataFromServer("addresses")
end


function createConsoleTab(tabControl, xml)
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
			{title = "ID", width = 12},
			{title = "Display", width = 18},
			{title = "", width = 19}
		},
	})

	local addrBook = AddressBook.getAddressBook()
	for i, addr in pairs(addrBook) do
		local addressTable = AddressBook.stringToTable(addr.address)
		local row = TerminalUI.AddressTable:addRow({addr.id, addr.display})
		row.background = colors.lightGray
	end

	AddressEditor.createEditor()
end

function createAddressesTab(tabControl, xml)
	TerminalUI.AddressFrame = tabControl:addTab("Addresses")

	refreshAddressesTab()

	deleteDialog = TerminalUI.AddressFrame:addDialog({
		boxWidth = 32,
		titleBackground = colors.blue,
		boxBackground = colors.lightGray,
		boxForeground = colors.black,
	})
	
	TerminalUI.AddressFrame:addButton({x=2,y=17,width=10,text="Add",height=1,background=colors.green})
	:onClick(function(self, checked) AddressEditor.openEmptyEditor() end)

	TerminalUI.AddressFrame:addButton({x=14,y=17,width=10,text="Edit",height=1,background=colors.orange})
	:onClick(function(self, checked) AddressEditor.openEditorWithData(AddressBook.getAddressFromIDOrAddress(TerminalUI.AddressTable:getSelectedRow()[1])) end)

	TerminalUI.AddressFrame:addButton({x=26,y=17,width=10,text="Delete",height=1,background=colors.red})
	:onClick(function(self, checked) confirmDelete(TerminalUI.AddressTable:getSelectedRow()) end)

	TerminalUI.AddressFrame:addButton({x=41,y=17,text="Resync",height=1,background=colors.cyan})
	:onClick(function(self, checked) resyncAddresses() end)

	AddressEditor.createEditor()
end

function confirmDelete(selectedRow)
	if selectedRow ~= nil then
		deleteDialog:confirm("Continue?", "Are you sure you want to delete " .. selectedRow[1] .. "?", function(yes)
			if yes then
				os.queueEvent("basalt_command", "addr del " .. selectedRow[1])

				Basalt.schedule(function ()
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



function createInterface(basalt)
	local main = basalt.createFrame(term.current())
	local xml = basalt.use("xml")

	TerminalUI.TabControl = main:addTabControl({
		x = 1,
		y = 1,
		width = 51,
		height = 19,
		background = colors.black,
		headerBackground = colors.gray,
		activeBackground = colors.blue,
	})

    createConsoleTab(TerminalUI.TabControl, xml)
	createAddressesTab(TerminalUI.TabControl, xml)
end

return {
	listenConsoleLogRequest = listenConsoleLogRequest,
	listenInput = listenInput,
	createInterface = createInterface,
	refreshAddressesTab = refreshAddressesTab
}
