local consoleTextBox = nil
local consoleInput = nil

local addressInput = nil
local idInput = nil
local displayInput = nil
local categoryInput = nil
local hiddenCheckbox = nil
local irisAutoOpenCheckbox = nil
local sirensCheckbox = nil
local restrictedCheckbox = nil

function saveAddress()
	if addressInput ~= nil then
		AddressBook.addAddress(idInput:getText(), {
			address = addressInput:getText(),
			id = idInput:getText(),
			display = displayInput:getText(),
			category = categoryInput:getText(),
			hidden = hiddenCheckbox.checked,
			security = {
				irisAutoOpen = irisAutoOpenCheckbox.checked,
				sirens = sirensCheckbox.checked,
				restricted = restrictedCheckbox.checked,
			},
		})
	end
end

function listenConsoleLogRequest()
	while true do
		local name, msg = os.pullEvent("console_log_request")

		newText = consoleTextBox:getText() .. string.format("%s\n", msg)
		consoleTextBox:setText(newText)

		if #consoleTextBox.lines - 14 > 0 then
			consoleTextBox.scrollY = #consoleTextBox.lines - 14
		end
	end
end

function listenInput()
	while true do
		local event, key, is_held = os.pullEvent("key")

		if key == keys.enter and consoleInput ~= nil then
			os.queueEvent("basalt_command", consoleInput.text)
			consoleInput.text = ""
		end
	end
end

function createAddressTab(tabControl)
	local addressTab = tabControl:newTab("Address")

	scope = {
		handleSave = function(self)
            saveAddress()
        end
	}

	-- addressTab:loadXML([[
    --     <label x="2" y="2" text="Address:" foreground="orange" />
    --     <label x="2" y="4" text="Id:" foreground="orange" />
    --     <label x="17" y="4" text="Display:" foreground="orange" />
    --     <label x="2" y="6" text="Category:" foreground="orange" />
    --     <label x="32" y="6" text="Hidden:" foreground="orange" />
    --     <label x="2" y="8" text="Security:" foreground="orange" />

    --     <label x="2" y="9" text="Iris auto open:" foreground="orange" />
    --     <label x="25" y="9" text="Sirens:" foreground="orange" />
    --     <label x="2" y="10" text="Restricted:" foreground="orange" />

    --     <button text="Save" x="2" y="16" height="1" background="green" onClick="handleSave"/>
    -- ]], scope)

    addressTab:addLabel({x=2,y=2,text="Address:",foreground=colors.orange})
    addressTab:addLabel({x=2,y=4,text="Id:",foreground=colors.orange})
    addressTab:addLabel({x=17,y=4,text="Display:",foreground=colors.orange})
    addressTab:addLabel({x=2,y=6,text="Category",foreground=colors.orange})
    addressTab:addLabel({x=32,y=6,text="Hidden",foreground=colors.orange})

    addressTab:addLabel({x=2,y=8,text="Security",foreground=colors.orange})
    addressTab:addLabel({x=2,y=9,text="Iris Auto Open:",foreground=colors.orange})
    addressTab:addLabel({x=25,y=9,text="Sirens:",foreground=colors.orange})
    addressTab:addLabel({x=2,y=10,text="Restricted:",foreground=colors.orange})

    addressTab:addButton({x=2,y=16,text="Save",height=1,background=colors.green})
        :onClick(function(self, checked) saveAddress() end)

	addressInput = addressTab:addInput({
		x = 11,
		y = 2,
		width = 30,
		background = colors.gray,
		foreground = colors.white,
	})
	idInput = addressTab:addInput({
		x = 6,
		y = 4,
		width = 10,
		background = colors.gray,
		foreground = colors.white,
	})
	displayInput = addressTab:addInput({
		x = 26,
		y = 4,
		width = 14,
		background = colors.gray,
		foreground = colors.white,
	})
	categoryInput = addressTab:addInput({
		x = 12,
		y = 6,
		width = 17,
		background = colors.gray,
		foreground = colors.white,
	})

	hiddenCheckbox = addressTab:addCheckBox({
		x = 40,
		y = 6,
		background = colors.gray,
		foreground = colors.white,
		text = "[ ]",
		checkedText = "[X]",
	})
	irisAutoOpenCheckbox = addressTab:addCheckBox({
		x = 18,
		y = 9,
		background = colors.gray,
		foreground = colors.white,
		text = "[ ]",
		checkedText = "[X]",
	})
	sirensCheckbox = addressTab:addCheckBox({
		x = 33,
		y = 9,
		background = colors.gray,
		foreground = colors.white,
		text = "[ ]",
		checkedText = "[X]",
	})
	restrictedCheckbox = addressTab:addCheckBox({
		x = 14,
		y = 10,
		background = colors.gray,
		foreground = colors.white,
		text = "[ ]",
		checkedText = "[X]",
	})
end

function createAddressListTab(tabControl)
	local addressList = tabControl:newTab("Address List")
end

function createConsoleTab(tabControl)
	local consoleTab = tabControl:newTab("Console")

	consoleTextBox = consoleTab:addTextBox({
		x = 2,
		y = 2,
		width = 47,
		height = 14,
		editable = false,
		background = colors.gray,
		foreground = colors.white,
        text="Welcome to the BasaltDialer Terminal"
	}):setSize(47, 14)
	consoleInput = consoleTab:addInput({
		x = 2,
		y = 16,
		width = 47,
		height = 1,
		background = colors.magenta,
		foreground = colors.white,
	})
end

function createInterface(basalt)
	local main = basalt.createFrame()

	main:setBackground(colors.orange)

	local tabControl = main:addTabControl({
		x = 2,
		y = 1,
		width = 49,
		height = 18,
		background = colors.black,
	})

    createConsoleTab(tabControl)
	createAddressTab(tabControl)
	--createAddressListTab(tabControl)
	

	basalt.schedule(function()
		parallel.waitForAny(listenConsoleLogRequest, listenInput)
	end)
end

return {
	createInterface = createInterface,
}
