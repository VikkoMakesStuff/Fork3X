local Addons = {}

local Support = require(script.Parent.Parent.SupportLibrary)
local Signal = require(script.Parent.Parent.Signal)

local OptionsData = {
	AddonsData = {},

	-- Data
	Failed = {},
	AlreadyErased = {},
	ToolsAdded = {},
	TablesCloned = {},
	HighestPriority = 0,
}

local LastAddons = {}

Addons.VariableSettings = {}
Addons.Options = {}

Addons.OptionsChanged = Signal.new()

local OriginalOptions = {}

local CanVary = {}
local IsMetatableSetUp = false

local function SetUpOptions()
	Addons.Options = Support.Mirror(Addons.Options, OriginalOptions)

	local VariableSettings = Addons.VariableSettings
	
	table.clear(VariableSettings)
	table.clear(CanVary)

	if Addons.Options.VariableSettings then
		for Key, Value in Addons.Options.VariableSettings do
			VariableSettings[Key] = Value
		end
	end

	Addons.Options.VariableSettings = nil
end

function Addons.SetCurrentOptions(Options)
	OriginalOptions = Options
	
	SetUpOptions()
end

function Addons.DidAddonFail(Addon)
	return OptionsData.Failed[Addon]
end

function Addons.WasAddonLoaded(Addon)
	return if OptionsData.Failed[Addon] then false elseif OptionsData.AddonsData[Addon] then true else false
end

function Addons.ApplyAddon(AddonFile)
	table.clear(OptionsData.Failed)
	table.clear(OptionsData.AlreadyErased)
	table.clear(OptionsData.ToolsAdded)
	table.clear(OptionsData.TablesCloned)
	
	OptionsData.HighestPriority = 0
	
	local AddonsData = OptionsData.AddonsData

	local AddonData = AddonsData[AddonFile]

	local Priority = AddonData.Priority
	local Data = AddonData.Data
	
	local PreApplication = Data.PreApplication
	local SettingsToErase = Data.Erase
	local AdvancedSetup = Data.AdvancedSetup
	local Variable = Data.VariableSettings
	local ToolsData = Data.Bridges
	
	if PreApplication then
		PreApplication(Addons.Options, OriginalOptions)
	end
	
	if SettingsToErase then
		for Name, Value in SettingsToErase do
			if OptionsData.AlreadyErased[Name] == Priority then
				warn("[FORK3X]: There is a conflict between two addons that tried to modify `" .. Name .. "`. Make sure that addons that modify the same settings have different priorities. The setting won't be changed by the latter.")
				continue
			end

			Addons.Options[Name] = Value
			OptionsData.AlreadyErased[Name] = Priority
		end
	end

	if AdvancedSetup then
		for Name, Function in AdvancedSetup do
			local CurrentValue = Addons.Options[Name]
			
			if type(CurrentValue) == "table" and not OptionsData.TablesCloned[Name] then
				CurrentValue = Support.CloneTable(CurrentValue, true)
				
				OptionsData.TablesCloned[Name] = true
			end
			
			Addons.Options[Name] = Function(CurrentValue, OptionsData.HighestPriority == Priority, Name)
		end
	end

	if Variable then
		for _, Name in Variable do
			Addons.VariableSettings[Name] = true
		end
	end

	if ToolsData and not OptionsData.ToolsAdded[AddonFile] then
		for _, Data in next, ToolsData do
			local Module = Data.Module
			local Icon = Data.Icon
			local Keybind = Data.Keybind
			
			local IsATool = Data.IsATool
			local SyncModuleFunctions = Data.SyncModuleFunctions
			
			if Module and Icon and Keybind and IsATool ~= nil then
				local IconID = Icon.ID

				if not IconID then
					warn( 
						string.format( 
							"[FORK3X]: The icon of the bridge/addon `%*` is missing. Make sure it's a table with an `ID` key and not just the icon's ID.",
							AddonFile.Name
						)
					)
					continue
				end
				
				if SyncModuleFunctions then
					local Option = Addons.Options.CustomSyncModuleFunctions
					local IsConflictPossible = Priority == OptionsData.HighestPriority

					for Name, Function in SyncModuleFunctions do
						if Option[Name] and IsConflictPossible then
							warn("[FORK3X]: The action `" .. Name .. "` has already been set by the default Options module or another addon. To avoid conflicts, the addon skipped this setting.\n\nIn order to fix this, you must remove this action in the default Options, or set the Priority attribute to a higher value.")
							
							continue
						end

						Option[Name] = Function
					end
				end

				if not Addons.Options.Bridges then
					Addons.Options.Bridges = {}
				end

				table.insert(Addons.Options.Bridges, Data)
			else
				warn( 
					string.format( 
						"[FORK3X]: The bridge/addon `%*` doesn't have the four necessary keys: Module, Icon, Keybind, and IsATool.",
						AddonFile.Name
					)
				)
			end
		end

		OptionsData.ToolsAdded[AddonFile] = true
	end
	
	OptionsData.HighestPriority = Priority
end

function Addons.ApplyAddons()
	local AddonsData = OptionsData.AddonsData
	
	for _, LastAddon in LastAddons do
		if LastAddon.Data.Unload then
			LastAddon.Data.Unload()
		end
	end
	
	LastAddons = table.clone(AddonsData)

	local AddonsList = table.create( Support.CountKeys(AddonsData) )

	for AddonFile, AddonData in AddonsData do
		table.insert(AddonsList, AddonFile)
	end

	table.sort(AddonsList, function(A, B)
		return AddonsData[A].Priority < AddonsData[B].Priority
	end)
	
	SetUpOptions()
	
	Addons.VariableSettings = Support.FlipTable(Addons.VariableSettings)
	
	for _, AddonFile in next, AddonsList do
		local Success = xpcall(
			Addons.ApplyAddon,
			function(Error)
				OptionsData.Failed[AddonFile] = true
				
				warn( 	string.format("[FORK3X]: The addon `%*` experienced an error you can find here:\n\n%*\n\nIt may be a good idea to report this error to the creator of the addon.",
							AddonFile.Name,
							debug.traceback(Error) :: string
						)
					)
			end,
			AddonFile
			)
	end
	
	Addons.VariableSettings = Support.Keys(Addons.VariableSettings)
	
	if #Addons.VariableSettings ~= 0 then
		for _, Setting in Addons.VariableSettings do
			if Addons.Options[Setting] then
				if type(Addons.Options[Setting]) ~= "function" then
					warn("[FORK3X]: `" .. Setting .. "` cannot vary because the set value isn't a function.")
					continue
				end

				CanVary[Setting] = Addons.Options[Setting]

				Addons.Options[Setting] = nil
			end
		end

		if Support.CountKeys(CanVary) ~= 0 then
			local OptionsMetatable = {}
			
			if not IsMetatableSetUp then
				IsMetatableSetUp = true
				
				setmetatable(Addons.Options, OptionsMetatable)
			end

			OptionsMetatable.__index = function(Table, Index)
				if CanVary[Index] then
					return CanVary[Index](Index)
				else
					return nil
				end
			end
		end
	end
	
	Addons.OptionsChanged:Fire()
end

function Addons.ClearAddons(Addon)
	table.clear(OptionsData.AddonsData)
end

function Addons.RemoveAddon(Addon)
	OptionsData.AddonsData[Addon] = nil
end

function Addons.AddAddon(Addon, Priority)
	local Success, Data = xpcall(
		require,
		function(Error)
			OptionsData.Failed[Addon] = true

			warn( 	string.format("[FORK3X]: The addon `%*` experienced an error you can find here:\n\n%*\n\nIt may be a good idea to report this error to the creator of the addon.",
				Addon.Name,
				debug.traceback(Error) :: string
				)
			)
		end,
		Addon)
	
	if not Success then
		return
	end

	OptionsData.AddonsData[Addon] = {
		Data = Data,
		Priority = Priority or 0
	}
end

return Addons
