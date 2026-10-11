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
	["EnumerateWith"]: ( {any} ) -> {string},
	["UIConfiguration"]: { [string]: any },
	["DefaultValue"]: any,
}

return function(Environment)
	
	local ExtraFeatures: {Fork3XSetting} = {
		-- ExtraFonts
		{
			-- The name of the setting
			Name = "Extra Fonts",

			-- The description of the setting
			Description = [[Allows you to add extra fonts to Fork3X. In order to add one, you must provide its ID in the window that opens.
			
If you're willing to change the font's weight and style, you must use rich text, which is explained in the manual (? button) of the text tool.]],

			-- The Fork3X setting this option edits, and also where to take the output
			Setting = "ExtraFonts",

			-- The type of UI object that will be used for this

			-- TextBox: the user inputs some text that can be transformed afterwards
			-- Toggle: a checkmark that returns a true or false value
			-- Dropdown: a button that allows the user to choose an option among others
			-- Dropbox: requests the user to give a .rbxm file
			-- Advanced: opens a window that allows an advanced setup
			Type = "TextBox",
			
			-- The function (or type, if it does the job) that returns the data in an usable format
			-- Feel free to use the current decoded value (it can be nil) to prevent useless decoding
			DecodeValue = SerializationMethods.GetDecodingFunction({ Font = "string" }),
			
			-- What happens once an input is entered
			
			-- To save a setting, call Environment.SaveSetting(Name, Value, Index?), no matter if it's exhaustive or non-exhaustive
			-- If it works, return true
			-- If it fails, return false, and an optional reason of failure
			
			OnActivated = function(self, Input)
				-- Make sure the given font is a number
				if not tonumber(Input) then
					return false, "The given ID must be a number. Make sure you copied the ID and not the link or rbxassetid URI."
				end
				
				-- Get the ID's information
				local Success, ProductInfo = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, tonumber(Input), Enum.InfoType.Asset)
				
				-- If there's no ID, abort
				if not Success then
					return false, "The given ID doesn't exist. Make sure there's no typo and that you copied the correct ID."
				end
				
				-- Make sure it's a font
				local IsAFont = ProductInfo.AssetTypeId == Enum.AssetType.FontFamily.Value
				
				-- If it's not the case, abort
				if not IsAFont then
					return false, "The given ID is not a font. Make sure you input the right ID."
				end
				
				-- If every check passed, create and add the font
				local NewFont = Font.fromId( tonumber(Input) )
				
				-- Add the new font and it's appearance
				Environment.SaveSetting(self.Setting, ProductInfo.Name, NewFont)
				
				return true, "Font successfully added!"
			end,

			-- If the user must choose one single option, or if they can have multiple ones
			NonExhaustive = true,
			
			-- The string that will be displayed when enumerating the objects with NonExhaustive
			EnumerateWith = function(Values)
				local FinalValues = {}
				
				for FontValue: Font, Name in Values do
					table.insert( FinalValues, {
						Name = string.format( [[<font family="%*">%*</font>]], FontValue.Family, Name ),
						Key = FontValue
					} )
				end
				
				table.sort(FinalValues, function(A, B)
					return Values[A.Key] < Values[B.Key]
				end)
				
				return FinalValues
			end,

			-- The UI object's configuration (aka props)
			UIConfiguration = {
				XSize = 120,
			},

			-- The setting's default value
			DefaultValue = {}
		},

		-- CustomPartTypes
		{
			-- The name of the setting
			Name = "Custom Part Types",

			-- The description of the setting
			Description = [[Allows you to add new objects to the New Part tool, and with advanced configuration to the transformation tool as well.

Two solutions exist to add a part type:

	- You can give a .rbxm file of an object, and then be able to create it via the New Part tool. .rbxm will be 
	- You can drag your selection into the button.
	
The file can also be a .luau/.rbxm file with a ModuleScript, so the part type can have an advanced configuration, which allows it to appear on the transformation tool.]],

			-- The Fork3X setting this option edits, and also where to take the output
			Setting = "CustomPartTypes",

			-- The type of UI object that will be used for this

			-- TextBox: the user inputs some text that can be transformed afterwards
			-- Toggle: a checkmark that returns a true or false value
			-- Dropdown: a button that allows the user to choose an option among others
			-- Dropbox: requests the user to give a .rbxm file
			-- Advanced: opens a window that allows an advanced setup
			Type = "Dropbox",

			-- What happens once an input is entered

			-- To save a setting, call Environment.SaveSetting(Name, Value), no matter if it's exhaustive or non-exhaustive
			-- If it works, return true
			-- If it fails, return false, and an optional reason of failure

			OnActivated = function(self, Objects)
				-- Make sure there is only one object
				if #Objects ~= 1 then
					if #Objects == 0 then
						return false, "This .rbxm file is seemingly empty. It might be corrupt."
					else
						return false, "There must be only <b>one</b> object. Make sure to group everything into one object!"
					end
				end
				
				-- Extract the object and identify it
				local Object = Objects[1]
				local IsAModuleScript = Object:IsA("ModuleScript")
				
				-- If it's a module script, make sure it is valid and add it
				if IsAModuleScript then
					local TypeContent = require(Object)
					
					if type(TypeContent) ~= "table" then
						return false, "The module script doesn't contain a table. Make sure you return a table at the end."
					elseif not TypeContent.Create then
						return false, "There must be a `Create` function inside the table."
					end
					
					-- Add the new part type
					Environment.SaveSetting(self.Setting, Object, Object.Name)
				else
					-- Add the new part type
					Environment.SaveSetting(self.Setting, Object, Object.Name)
				end
				
				return true, [[The object has been successfully added!]]
			end,
			
			DecodeValue = SerializationMethods.GetDecodingFunction({ string = "Instance" }),
			
			GetValue = function(self, Value)			
				local Objects = {}
				
				for Name, Object in Value do
					if Object:IsA("ModuleScript") then
						Objects[Name] = require(Object)
					else
						Objects[Name] = function()
							return Object:Clone()
						end
					end
				end
				
				return Objects
			end,

			-- If the user must choose one single option, or if they can have multiple ones
			NonExhaustive = true,
			
			-- The string that will be displayed when enumerating the objects with NonExhaustive
			EnumerateWith = function(Values)
				local FinalValues = {}

				for Name in Values do
					table.insert( FinalValues, {
						Name = Name,
						Key = Name
					} )
				end

				table.sort(FinalValues, function(A, B)
					return A.Name > B.Name
				end)

				return FinalValues
			end,
			
			-- The UI object's configuration (aka props)
			UIConfiguration = {
				XSize = 120,
			},
			
			-- The setting's default value
			DefaultValue = {}
		},
		
		-- AllowMaterialVariants
		{
			-- The name of the setting
			Name = "Allow Material Variants",

			-- The description of the setting
			Description = [[Determines whether material variants must be shown inside the material tool.]],

			-- The Fork3X setting this option edits, and also where to take the output
			Setting = "AllowMaterialVariants",

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
			DefaultValue = true,
		},
		
		-- AllowExtraVehicleSeatsSettings
		{
			-- The name of the setting
			Name = "Detect VehicleSeats",

			-- The description of the setting
			Description = [[When enabled, Fork3X will detect VehicleSeats inside the selection and show special settings for them in the material tool.]],

			-- The Fork3X setting this option edits, and also where to take the output
			Setting = "AllowExtraVehicleSeatsSettings",

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
			DefaultValue = true,
		},
		
		-- ManipulateAnyConstraint
		{
			-- The name of the setting
			Name = "Manipulate any Constraint",

			-- The description of the setting
			Description = [[By default, Fork3X's constraint tool will only detect, edit, and delete constraints made with Fork3X.
			
This can be annoying if you're trying to edit a map not made with Fork3X, so it's recommended to keep this on.]],

			-- The Fork3X setting this option edits, and also where to take the output
			Setting = "ManipulateAnyConstraint",

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
			DefaultValue = true,
		},
	}

	return ExtraFeatures
end