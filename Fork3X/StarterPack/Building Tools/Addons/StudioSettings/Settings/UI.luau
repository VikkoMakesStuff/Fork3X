local MarketplaceService = game:GetService("MarketplaceService")
local SerializationMethods = require(script.Parent.Parent.Libraries.SerializationMethods)

type Fork3XSetting = {
	["Name"]: string,
	["Description"]: string,
	["Setting"]: string,
	["Type"]: string,
	["DecodeValue"]: (any) -> (any) | string,
	["OnActivated"]: (Fork3XSetting, string | {string} | boolean) -> (boolean, string?),
	["NonExhaustive"]: boolean,
	["EnumerateWith"]: ( {any} ) -> {string}?,
	["UIConfiguration"]: { [string]: any },
	["DefaultValue"]: any,
}

return function(Environment)

	local Miscellaneous: {Fork3XSetting} = {
		-- CollisionFidelity
		{
			-- The name of the setting
			Name = "Ignore Handles with Camera",

			-- The description of the setting
			Description = [[When enabled, the drag handles (aka drag bubbles) will no longer prevent you from moving the camera when pressing the right mouse button.
			
Do note you might experience bugs with this feature, so make sure to report them in this is the case.]],

			-- The Fork3X setting this option edits, and also where to take the output
			Setting = "IgnoreHandlesWithCamera",

			-- The type of UI object that will be used for this
			
			-- TextBox: the user inputs some text that can be transformed afterwards
			-- Toggle: a checkmark that returns a true or false value
			-- Dropdown: a button that allows the user to choose an option among others
			-- Dropbox: requests the user to give a .rbxm file
			-- Advanced: opens a window that allows an advanced setup
			Type = "Toggle",

			-- What happens once an input is entered

			-- To save a setting, call Environment.SaveSetting(Name, Value), no matter if it's exhaustive or non-exhaustive
			-- If it works, return true
			-- If it fails, return false, and an optional reason of failure

			OnActivated = "Default",

			-- If the user must choose one single option, or if they can have multiple ones
			NonExhaustive = false,

			-- The UI object's configuration (aka props)
			UIConfiguration = {},

			-- The setting's default value
			DefaultValue = false,
		},
	}

	return Miscellaneous
end