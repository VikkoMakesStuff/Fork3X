local Tool = script:FindFirstAncestorWhichIsA('Tool')
local Core = require(Tool.Core)

local Globals = require(Tool.Globals)

local UI = Globals.UI
local Vendor = Globals.Vendor

-- Libraries
local Roact = require(Vendor:WaitForChild('Roact'))
local ToolManualWindow = require(UI:WaitForChild('ToolManualWindow'))

local function ListenForManualWindowTrigger(Text, ThemeColor, SignatureButton)
    local HelpButton = SignatureButton:WaitForChild('HelpButton')

	local IsManualOpen = false
	local ManualHandle = nil
	
	local function ToggleManual()

		-- Go through the inputs and data
		local TagMethod = IsManualOpen and script.RemoveTag or script.AddTag
		
		TagMethod(HelpButton, "STATE_Open")

        -- Close manual if open
        if IsManualOpen then
		--	EndHover()
			IsManualOpen = false
			ManualHandle = Roact.unmount(ManualHandle)
			

        -- Open manual if closed
        else
		--	BeginHover()
			IsManualOpen = true
			local ManualElement = Roact.createElement(ToolManualWindow, {
				Text = Text;
				ThemeColor = ThemeColor;
				CloseCallback = function()
					IsManualOpen = false
					
					Roact.unmount(ManualHandle)
				end,
			})
			ManualHandle = Roact.mount(ManualElement, Core.UI, 'ToolManualWindow')
		end
	end

	-- Enable help button
	SignatureButton.Activated:Connect(ToggleManual)
	HelpButton.Activated:Connect(ToggleManual)
end

return ListenForManualWindowTrigger