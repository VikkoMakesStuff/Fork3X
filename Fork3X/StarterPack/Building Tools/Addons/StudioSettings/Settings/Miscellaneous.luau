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

	local Miscellaneous: {Fork3XSetting} = {
		-- CollisionFidelity
		{
			-- The name of the setting
			Name = "Collision Fidelity",

			-- The description of the setting
			Description = [[Determines how precise the hitboxes of unions and MeshParts are. The more precise they're, the more performance issues it may cause.
			
- Box: self-explanatory. The hitbox is simply a box that overlaps the object. Ideal for very small objects or objects you won't interact with.
- Hull: inaccurate yet performant hitboxes. Good for small objects.
- Default: balanced hitboxes that offer both accuracy and acceptable performance. Suitable to most scenarios.
- Precise Convex Decomposition: extremely accurate hitboxes, with a high performance cost. Must only be used when Default causes issues.]],

			-- The Fork3X setting this option edits, and also where to take the output
			Setting = "CollisionFidelity",

			-- The type of UI object that will be used for this

			-- TextBox: the user inputs some text that can be transformed afterwards
			-- Toggle: a checkmark that returns a true or false value
			-- Dropdown: a button that allows the user to choose an option among others
			-- Dropbox: requests the user to give a .rbxm file
			-- Advanced: opens a window that allows an advanced setup
			Type = "Dropdown",
			
			DecodeValue = SerializationMethods.GetDecodingFunction(Enum.CollisionFidelity),

			-- What happens once an input is entered

			-- To save a setting, call Environment.SaveSetting(Name, Value), no matter if it's exhaustive or non-exhaustive
			-- If it works, return true
			-- If it fails, return false, and an optional reason of failure

			OnActivated = "Default",

			-- If the user must choose one single option, or if they can have multiple ones
			NonExhaustive = false,

			-- The UI object's configuration (aka props)
			UIConfiguration = {
				XSize = 120,
				Options = {
					Box = Enum.CollisionFidelity.Box,
					Hull = Enum.CollisionFidelity.Hull,
					Default = Enum.CollisionFidelity.Default,
					["Precise Convex Decomposition"] = Enum.CollisionFidelity.PreciseConvexDecomposition
				}
			},

			-- The setting's default value
			DefaultValue = Enum.CollisionFidelity.Default,
		},
		
		{
			-- The name of the setting
			Name = "Render Fidelity",

			-- The description of the setting
			Description = [[Determines if Fork3X can allow Roblox to reduce MeshParts and unions' visual precision.
			
- Performance will drastically reduce the number of tris displayed at medium-high distances, which may impact visuals.
- Automatic will reduce tris based on various factors, mostly if the mesh already has a low tri count.
- Precise will never allow the tri count to be reduced. This may impact performance, so use this carefully!]],

			-- The Fork3X setting this option edits, and also where to take the output
			Setting = "PartRenderFidelity",

			-- The type of UI object that will be used for this

			-- TextBox: the user inputs some text that can be transformed afterwards
			-- Toggle: a checkmark that returns a true or false value
			-- Dropdown: a button that allows the user to choose an option among others
			-- Dropbox: requests the user to give a .rbxm file
			-- Advanced: opens a window that allows an advanced setup
			Type = "Dropdown",

			DecodeValue = SerializationMethods.GetDecodingFunction(Enum.RenderFidelity),

			-- What happens once an input is entered

			-- To save a setting, call Environment.SaveSetting(Name, Value), no matter if it's exhaustive or non-exhaustive
			-- If it works, return true
			-- If it fails, return false, and an optional reason of failure

			OnActivated = "Default",

			-- If the user must choose one single option, or if they can have multiple ones
			NonExhaustive = false,

			-- The UI object's configuration (aka props)
			UIConfiguration = {
				XSize = 120,
				Options = {
					Performance = Enum.RenderFidelity.Performance,
					Automatic = Enum.RenderFidelity.Automatic,
					Precise = Enum.RenderFidelity.Precise
				}
			},

			-- The setting's default value
			DefaultValue = Enum.RenderFidelity.Automatic,
		},
	}

	return Miscellaneous
end