-- A module that manages communication between modules inside the tool
-- Somewhat my take at fixing a bunch of issues

local Tool = script.Parent
local OriginalTool = Tool:FindFirstChild("Tool")

if OriginalTool then
	OriginalTool = OriginalTool.Value
else
	OriginalTool = Tool
end

local function GetVariableLocation(Object)
	return Object and Object:IsA("ObjectValue") and Object.Value or Object
end

local Libraries = Tool:WaitForChild("Libraries")
local Options = require( OriginalTool:WaitForChild("Options") )
local LTSOptions = require( Libraries:WaitForChild("LTSOptions") )

local OptionsToReturn = LTSOptions(Options)

local Globals = {
	Tool = Tool,
	Libraries = Libraries,
	
	Interfaces = GetVariableLocation(Tool.Interfaces),
	Themes = GetVariableLocation(Tool.Themes),
	Profiles = GetVariableLocation( Tool:FindFirstChild("Profiles") ),
	UI = GetVariableLocation(Tool.UI),
	Vendor = GetVariableLocation(Tool.Vendor),
	Version = GetVariableLocation(Tool.Version),
	Addons = GetVariableLocation(Tool.Addons),
	Tools = OriginalTool:WaitForChild("Tools"),
	
	Sounds = OriginalTool:WaitForChild("Sounds"),

	Options = OptionsToReturn
}

return Globals
