--[[
==============================
NOTE ABOUT FORK3X ADD-ONS
==============================

At the time being, a Fork3X addon is just a module that modifies the options module in order to enhance people's experience

They're meant for NOTHING ELSE. Any setting in Advanced Setup must only return a new value.

MAKE SURE the add-on you're currently using has the Sandboxed property set to "true" and solely has the "Basic" capability on. If this is not the case, it may be a virus!
]]

-- Libraries
local Libraries = script.Libraries

local SerializationMethods = require(Libraries.SerializationMethods)

-- Settings
local PluginSettings = {}

local SettingsName = {}

local EverySetting = {}

local SettingsToErase = {}

local DefaultValue = {}

local SettingsFolder = script.Settings:GetChildren()

-- Addon's shared content
local SaveSettings

local WidgetWindow, SettingsButton

local Connections = {}

local Tasks = {}

local DeleteWhenUnloading = {}

local DidAddonsUpdate = false

local function CloneSetting(Value)
	if type(Value) == "table" then
		return table.clone(Value)
	else
		return Value
	end
end

local function GetSetting(Name)
	return PluginSettings[Name]
end

for _, Module in SettingsFolder do
	local Data = require(Module)({})
	
	for _, Setting in Data do
		local SettingName = Setting.Setting
		
		table.insert(SettingsName, SettingName)
		
		EverySetting[SettingName] = Setting
		
		SettingsToErase[SettingName] = Setting.GetValue and function()
			return Setting.GetValue(Setting, PluginSettings[SettingName])
		end or GetSetting
		
		DefaultValue[SettingName] = CloneSetting(Setting.DefaultValue)
		
		PluginSettings[SettingName] = CloneSetting(Setting.DefaultValue)
	end
end

local Addon = {
	-- You can use this function if you need to set up stuff beforehand
	PreApplication = function(Options, OriginalOptions)
		for Name in SettingsToErase do
			if Options[Name] ~= OriginalOptions[Name] then
				DefaultValue[Name] = Options[Name]
				
				PluginSettings[Name] = Options[Name]
			end
		end
	end,
	
	-- Put the name of the settings
	-- You mustn't put them in their categories, else the addon won't work!

	-- This erases the given settings
	Erase = SettingsToErase,

	-- You can use this to assemble settings together
	-- The function gives the current setting 
	AdvancedSetup = {
		CustomCoreConnections = function(OriginalValue, IsConflictPossible)
			return function(Core)
				if not Core.Plugin then
					return OriginalValue(Core)
				end
				
				local Roact = Core.Roact
				
				local Toolbar = Core.PluginToolbar
				local WidgetVisible = false
				
				-- ==================================
				-- ADDONS
				-- ==================================

				-- Just an addon type to make it simpler
				type AddonData = {
					["Module"]: ModuleScript,
					["Priority"]: number,
					["Enabled"]: boolean,
					["IsBuiltIn"]: boolean,
				}

				local HighestPriority = 0

				local AddonsModule = require(Core.Libraries.LTSOptions.Addons)
				local EveryAddon = {}

				local SavedAddons = Core.Plugin:GetSetting("Addons") or {}
				local DisabledAddons = Core.Plugin:GetSetting("DisabledAddons") or {}

				-- Decompress the addon list
				local BuiltInAddons = Core.AddonsFolder:GetChildren()

				for _, Addon in BuiltInAddons do
					if Addon == script then
						continue
					end

					local Priority = Addon:GetAttribute("Priority") or 0

					if Priority >= HighestPriority then
						HighestPriority = Priority
					end

					local AddonData: AddonData = {
						Module = Addon,
						Priority = Priority,
						Enabled = if DisabledAddons[Addon.Name] then false else true,
						IsBuiltIn = true,
					}

					table.insert(EveryAddon, AddonData)
				end
				
				Core.BuiltInHighestPriority = HighestPriority

				for Index, SavedAddonData in SavedAddons do
					local AddonData: AddonData = {
						Module = SerializationMethods.Decode(SavedAddonData.Module, "Instance"),
						Priority = HighestPriority + #SavedAddons - Index + 1,
						Enabled = SavedAddonData.Enabled,
						IsBuiltIn = false,
					}

					table.insert(EveryAddon, AddonData)
				end

				table.sort(EveryAddon, function(A, B)
					return A.Priority < B.Priority
				end)

				Core.EveryAddon = EveryAddon
				
				Core.ApplyAddons = function()
					AddonsModule.ClearAddons()
					
					for _, Addon in EveryAddon do
						if Addon.Enabled then
							AddonsModule.AddAddon(Addon.Module, Addon.Priority)
						end
					end
					
					AddonsModule.AddAddon(script, script:GetAttribute("Priority") or 9999)
					
					--Core.EquipTool()
					
					--Core.Disable()

					AddonsModule.ApplyAddons()
				end
				
				if DidAddonsUpdate == false then
					DidAddonsUpdate = true

					Core.ApplyAddons()
					
					return OriginalValue(Core)
				end
				
				-- ==================================
				-- THEMES
				-- ==================================

				Core.AvailableThemes = {}
				
				local SavedThemes = Core.Plugin:GetSetting("SavedThemes") or {}
				
				local DefaultData = {
					Name = function(Theme)
						return Theme.Name
					end,
					Description = function(Theme)
						return "This theme has no description."
					end,
					
					StyleSheet = function(Theme)
						return Theme:FindFirstChildOfClass("StyleSheet") 
							or Theme:FindFirstChildOfClass("StyleLink") 
							and Theme:FindFirstChildOfClass("StyleLink").StyleSheet
					end,
					StyleToken = function(Theme)
						local TokensFolder = Theme:FindFirstChild("Tokens")
						
						if not TokensFolder then
							return nil
						end
						
						return TokensFolder:FindFirstChildOfClass("StyleSheet") 
							or TokensFolder:FindFirstChildOfClass("StyleLink") 
							and TokensFolder:FindFirstChildOfClass("StyleLink").StyleSheet
					end,
					Components = function(Theme)
						return Theme:FindFirstChild("Components")
					end,
				}
				
				Core.AddTheme = function(Theme, GUID)
					local ThemeDataModule = Theme:FindFirstChild("Data")
					local ThemeData = {}
					
					if ThemeDataModule then
						ThemeData = require(ThemeDataModule :: ModuleScript) 
					end
						
					for Name, Function in DefaultData do
						if ThemeData[Name] == nil then
							ThemeData[Name] = Function(Theme)
							
							if not ThemeData[Name] then
								return false, string.format("The theme wasn't added because it has no %*.", Name)
							end
						end
					end
					
					ThemeData.Theme = Theme
					
					if not GUID then
						GUID = Core.Services.HttpService:GenerateGUID(false)
					end
					
					Core.AvailableThemes[ GUID ] = ThemeData
					
					return true, "The theme was successfully added!"
				end
				
				Core.SetUpCustomTheme = function(Theme)
					Theme.Parent = Core.Themes

					DeleteWhenUnloading[Theme] = true
				end
				
				for _, Theme in Core.Themes:GetChildren() do
					Core.AddTheme(Theme, Theme.Name)

					Core.AvailableThemes[Theme.Name].IsBuiltIn = true
				end
				
				for GUID, SavedTheme in SavedThemes do
					local ThemeFolder = SerializationMethods.Decode(SavedTheme, "Instance")

					Core.SetUpCustomTheme(ThemeFolder)
					
					Core.AddTheme(ThemeFolder, GUID)
	
					Core.AvailableThemes[GUID].IsBuiltIn = false
				end
				
				local CurrentTheme = Core.Plugin:GetSetting("CurrentTheme")
				
				if CurrentTheme then
					local CurrentThemeData = Core.AvailableThemes[CurrentTheme]
					
					if CurrentThemeData then
						local StyleSheet = CurrentThemeData.StyleSheet
						local StyleToken = CurrentThemeData.StyleToken
						local Components = CurrentThemeData.Components
						
						Core.CheckTheme(StyleSheet, StyleToken, Components)
						
						Core.CurrentThemeGUID = CurrentTheme
					end
				end
				
				-- ==================================
				-- SETTINGS
				-- ==================================
				
				local SavedSettings = Core.Plugin:GetSetting("Settings") or {}
				
				for Name, Value in SavedSettings do
					local Setting = EverySetting[Name]
					
					if Setting then
						local FinalValue = Value
						
						if Setting.DecodeValue then
							local Success, Value = pcall(Setting.DecodeValue, Value)
							
							if Success then
								FinalValue = Value
							else
								FinalValue = Setting.DefaultValue
							end
						end
						
						PluginSettings[Name] = FinalValue
					end
				end
				
				Core.SettingChanged = Core.Signal.new()
				
				Core.SettingsModified = {}
				
				Core.GetSetting = function(Name)
					return PluginSettings[Name]
				end
				
				Core.SetSetting = function(Name, Value)
					PluginSettings[Name] = Value
					
					Core.SettingsModified[Name] = true
					
					Core.SettingChanged:Fire(Name, Value)
				end
				
				Core.ResetSetting = function(Name)
					PluginSettings[Name] = DefaultValue[Name]
					
					Core.SettingsModified[Name] = false

					Core.SettingChanged:Fire(Name, DefaultValue[Name])
				end
				
				SaveSettings = function()
					for Setting, IsNewValue in Core.SettingsModified do
						if not IsNewValue then
							SavedSettings[Setting] = nil
						else
							if type(PluginSettings[Setting]) == "table" then
								
								SavedSettings[Setting] = SerializationMethods.EncodeTable(
									PluginSettings[Setting]
								) or PluginSettings[Setting]
							else
								
								SavedSettings[Setting] = SerializationMethods.Encode(
									PluginSettings[Setting]
								) or PluginSettings[Setting]
							end
						end
					end
					
					Core.Plugin:SetSetting("Settings", SavedSettings)
					Core.Plugin:SetSetting("CurrentTheme", Core.CurrentThemeGUID)
				end
				
				Tasks.AutoSave = Core.Support.ScheduleRecurringTask(SaveSettings, 120)
				
				Connections.AutoSave = Core.Plugin.Unloading:Connect(SaveSettings)

				-- ==================================
				-- WIDGET
				-- ==================================
				
				local WidgetHandler
				
				local WidgetSettings = DockWidgetPluginGuiInfo.new(
					Enum.InitialDockState.Right,
					false,
					false,
					300,
					400,
					200,
					300
				)
				
				SettingsButton = SettingsButton or Core.PluginToolbar:CreateButton(
					Core.Services.HttpService:GenerateGUID(false),
					'Opens a window where you can configure Fork3X',
					"rbxassetid://7121121188",
					"Fork3X Settings"
				);
				
				SettingsButton.ClickableWhenViewportHidden = true
				
				-- Connect the button to the system
				Connections.SettingsButton = SettingsButton.Click:Connect(function ()
					WidgetVisible = not WidgetVisible
					
					SettingsButton:SetActive(WidgetVisible);
					
					if not Core.WidgetWindow or Core.WidgetWindow.Parent == nil then
						WidgetWindow = Core.Plugin:CreateDockWidgetPluginGuiAsync(
							"FORK3X_PluginEditor",
							WidgetSettings
						)
						
						Core.WidgetWindow = WidgetWindow
						
						Core.WidgetWindow.Title = "Fork3X - Plugin Editor"
						Core.WidgetWindow.Name = "Fork3XPlugin"
						Core.WidgetWindow.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
						
						local WidgetContent = Roact.createElement( require(script.UI)({
							Core = Core,
							Connections = Connections,
							Tasks = Tasks
						}) )
						
						WidgetHandler = Roact.mount(WidgetContent, Core.WidgetWindow, "DockWidget")
					end
					
					Core.WidgetWindow.Enabled = WidgetVisible
				end);
				
				OriginalValue(Core)
			end
		end,
	},

	VariableSettings = SettingsName,
	
	Unload = function()
		if SaveSettings then
			SaveSettings()
		end
		
		if WidgetWindow then
			WidgetWindow:Destroy()
			WidgetWindow = nil
		end
		
		if SettingsButton then
			SettingsButton:SetActive(false)
		end
		
		for Name, Connection in Connections do
			Connection:Disconnect()
			Connections[Name] = nil
		end
		
		for Object in DeleteWhenUnloading do
			Object.Parent = nil
			
			DeleteWhenUnloading[Object] = nil
		end
		
		for Name, Task in Tasks do
			Task:Stop()
			Tasks[Name] = nil
		end
	end,
}

return Addon