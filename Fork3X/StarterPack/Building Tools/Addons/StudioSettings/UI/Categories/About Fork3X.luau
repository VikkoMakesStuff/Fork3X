local Settings = {
	--["Extra Features"] = 
}

local Main = script.Parent.Parent
local Addon = Main.Parent

local Description = require(script.Description)

local PreviousCategory

local function Evaluate(Boolean)
	return if Boolean == true then "Yes" else "No"
end

local function GetAboutPage(props, Component)
	local Core = props.Core
	
	local ThemeInfo = props.ThemeInfo
	local Colors = ThemeInfo.Colors
	
	local Roact = Core.Roact
	local new = Roact.createElement

	-- Fetch the data to display on the page
	local function FetchDescription()
		local Addons = props.Core.EveryAddon
		
		-- Fork3X and plugin version
		local ToolVersion = Core.Tool.Version.Value
		local VersionChecked, IsOutdated = pcall(Core.IsVersionOutdated, ToolVersion)
		
		if VersionChecked and IsOutdated then
			ToolVersion ..= " [OUTDATED]"
		elseif not VersionChecked then
			warn(IsOutdated)
		end

		local PluginVersion = "v1.0.1 BETA"

		-- Addons (we must remove one since we exclude the studio settings)
		local BuiltInAddonsAmount = 0
		local UserAddonsAmount = 0
		
		local AddonsDetected = #Addons
		
		local AddonsEnabled = 0
		local AddonsDisabled = 0
		
		local AddonsLoaded = 0
		local AddonsWhoseLoadingFailed = 0
		
		local AddonsWaitingForRestart = 0
		local IsRestartRequired = props.IsRestartRequired
		
		-- Detect if any addon returned an error
		for _, Addon in Addons do
			-- Fetch the addon's data
			local IsBuiltIn = Addon.IsBuiltIn
			local Enabled = Addon.Enabled
			local IsLoaded = Core.AddonsModule.WasAddonLoaded(Addon.Module)
			local DidFail = Core.AddonsModule.DidAddonFail(Addon.Module)
			
			if IsBuiltIn then
				BuiltInAddonsAmount += 1
			else
				UserAddonsAmount += 1
			end
			
			if Enabled then
				AddonsEnabled += 1
			else
				AddonsDisabled += 1
			end
			
			if IsLoaded then
				AddonsLoaded += 1
			elseif DidFail then
				AddonsWhoseLoadingFailed += 1
			else
				AddonsWaitingForRestart += 1
			end
		end
		
		-- Themes
		local Themes = Core.AvailableThemes
		
		local AmountOfThemes = #Themes
		local CurrentTheme = Core.CurrentTheme and Core.CurrentTheme.Name or "Unknown?"
		
		-- Debug
		local Selection = Core.Selection
		
		local AmountOfItems = #Selection.Items
		local AmountOfParts = #Selection.Parts
		local AmountOfModels = #Selection.Models
		
		local CurrentTool = Core.CurrentTool and Core.CurrentTool.Name or "None"
		
		local CurrentStudioTheme = settings().Studio.Theme.Name
		
		-- Put everything into a table we'll unpack
		local Data = {
			-- Features
			ToolVersion,
			PluginVersion,
			
			-- Addons
			AddonsDetected,
				BuiltInAddonsAmount,
				UserAddonsAmount,
			
			AddonsEnabled,
			AddonsDisabled,
			Evaluate(IsRestartRequired),
			
			AddonsLoaded,
			AddonsWhoseLoadingFailed,
			
			-- Themes
			AmountOfThemes,
			
			CurrentTheme,
			
			-- Debug
			AmountOfItems,
				AmountOfParts,
				AmountOfModels,
			
			CurrentTool,
			
			CurrentStudioTheme
		}
		
		-- We can now return the whole string with the necessary data
		return string.format( Description, unpack(Data) )
	end
	
	return function()
		return Roact.createFragment({
			UIListLayout = new( "UIListLayout", {
				Padding = UDim.new(0, 10),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Signature = new( "TextLabel", {
				RichText = true,
				TextColor3 = Colors.HighlightedTextColor,
				Text = [[<font weight="800"><u>FORK</u>
3X</font>]],
				Size = UDim2.new(0.6, 0, 0.6, 0),
				TextWrapped = true,
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -4, 0.5, 0),
				TextSize = 12,
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal),
				TextScaled = true,
			}, {
				UISizeConstraint = new( "UISizeConstraint", {
					MaxSize = Vector2.new(150, 150),
				}),
				AspectRatio = new( "UIAspectRatioConstraint", {
					AspectRatio = 1.24,
				}),
			}),
			Credits = new( "TextLabel", {
				TextWrapped = true,
				AnchorPoint = Vector2.new(1, 0),
				TextSize = 14,
				Size = UDim2.new(1, 0, 0, 0),
				RichText = true,
				TextColor3 = Colors.TextColor,
				Text = [[Made with ❤️ by VikkoMakesStuff (aka @Vikko151)
				]],
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -42, 0, 0),
				TextYAlignment = Enum.TextYAlignment.Top,
				LayoutOrder = 1,
			}),
			Divider = new( "Frame", {
				BorderColor3 = Color3.new(0, 0, 0),
				AnchorPoint = Vector2.new(0, 1),
				Size = UDim2.new(0.3, 0, 0, 1),
				Position = UDim2.new(0, 0, 1, 0),
				BorderSizePixel = 0,
				BackgroundColor3 = Colors.DividerColor,
				LayoutOrder = 2,
			}),
			Information = new( "TextLabel", {
				TextWrapped = true,
				AnchorPoint = Vector2.new(1, 0),
				TextSize = 14,
				Size = UDim2.new(1, 0, 0, 0),
				RichText = true,
				Position = UDim2.new(1, -42, 0, 0),
				TextColor3 = Colors.TextColor,
				Text = string.format( Description, unpack( table.create(17, "...") ) ),
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 3,
				[Roact.Ref] = function(rbx)
					if rbx then
						task.spawn(function()
							rbx.Text = FetchDescription()
						end)
					end
				end,
			}),
		})
	end
end

return GetAboutPage