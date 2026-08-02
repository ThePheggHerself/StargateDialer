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
		Wireless.transmitMessage({type = "address_creation", content = 
		{
			address = addressInput:getText(),
			id = idInput:getText(),
			display = displayInput:getText(),
			hidden = hiddenCheckbox.checked,
			security = {
				irisAutoOpen = irisAutoOpenCheckbox.checked,
				sirens = sirensCheckbox.checked,
				restricted = restrictedCheckbox.checked,
			},
		} })
	end
end

function resyncAddresses()
	Wireless.clientSyncDataFromServer("addresses")
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

	addressTab:addLabel({x=2,y=2,text="Address Details",foreground=colors.orange})
    addressTab:addLabel({x=2,y=3,text="Address:",foreground=colors.yellow})
    addressTab:addLabel({x=2,y=5,text="Id:",foreground=colors.yellow})
    addressTab:addLabel({x=17,y=5,text="Display:",foreground=colors.yellow})
    addressTab:addLabel({x=2,y=7,text="Hidden Address:",foreground=colors.yellow})

    addressTab:addLabel({x=2,y=9,text="Security",foreground=colors.orange})
    addressTab:addLabel({x=2,y=10,text="Iris Auto Open:",foreground=colors.yellow})
    addressTab:addLabel({x=25,y=10,text="Sirens:",foreground=colors.yellow})
    addressTab:addLabel({x=2,y=11,text="Restricted:",foreground=colors.yellow})

    addressTab:addButton({x=2,y=17,text="Save",height=1,background=colors.green})
        :onClick(function(self, checked) saveAddress() end)

	addressTab:addButton({x=41,y=17,text="Resync",height=1,background=cyan})
        :onClick(function(self, checked) resyncAddresses() end)

	addressInput = addressTab:addInput({
		x = 11,
		y = 3,
		width = 30,
		background = colors.gray,
		foreground = colors.white,
	})
	idInput = addressTab:addInput({
		x = 6,
		y = 5,
		width = 10,
		background = colors.gray,
		foreground = colors.white,
	})
	displayInput = addressTab:addInput({
		x = 26,
		y = 5,
		width = 14,
		background = colors.gray,
		foreground = colors.white,
	})
	hiddenCheckbox = addressTab:addCheckBox({
		x = 18,
		y = 7,
		background = colors.gray,
		foreground = colors.white,
		text = "[ ]",
		checkedText = "[X]",
	})
	irisAutoOpenCheckbox = addressTab:addCheckBox({
		x = 18,
		y = 10,
		background = colors.gray,
		foreground = colors.white,
		text = "[ ]",
		checkedText = "[X]",
	})
	sirensCheckbox = addressTab:addCheckBox({
		x = 33,
		y = 10,
		background = colors.gray,
		foreground = colors.white,
		text = "[ ]",
		checkedText = "[X]",
	})
	restrictedCheckbox = addressTab:addCheckBox({
		x = 14,
		y = 11,
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
		width = 49,
		height = 14,
		editable = false,
		background = colors.gray,
		foreground = colors.white,
        text="Welcome to the BasaltDialer Terminal"
	}):setSize(49, 15)
	consoleInput = consoleTab:addInput({
		x = 2,
		y = 17,
		width = 49,
		height = 1,
		background = colors.magenta,
		foreground = colors.white,
	})
end

function createInterface(basalt)
	local main = basalt.createFrame()

	local tabControl = main:addTabControl({
		x = 1,
		y = 1,
		width = 51,
		height = 19,
		background = colors.black,
	})

    createConsoleTab(tabControl)
	createAddressTab(tabControl)
	--createAddressListTab(tabControl)
end

return {
	listenConsoleLogRequest = listenConsoleLogRequest,
	listenInput = listenInput,
	createInterface = createInterface,
}
