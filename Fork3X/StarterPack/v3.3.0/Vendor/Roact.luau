-- Wrapper to allow full compatibility with React Lua

-- Require RoactCompat
local RoactCompat = table.clone( require(script.ReactLua.RoactCompat) )
local React = require(script.ReactLua.React)

-- Define the table with every theme component
local ComponentsTable

-- Change what needs to be changed for compatibility

-- Remember the original function
local createElement = RoactCompat.createElement

-- Replace the createElement function
RoactCompat.createElement = function(Type, Main, Children, ScriptName, Environment)
	if ComponentsTable and ScriptName and Environment then
		
		if ComponentsTable[ScriptName] then

			for Name, Function in ComponentsTable[ScriptName] do
				if Children then
					Children[Name] = Function(Environment)
				elseif Main[RoactCompat.Children] then
					Children[Name] = Function(Environment)
				end
			end
		end
	end
	
	local HasTags = false
	local TagValue = ""
	
	if Main then
		for Property, Value in Main do
			if string.sub( tostring(Property), 1, 7 ) == "RBXTAG_" then		
				Main[Property] = nil

				if Value == true then
					if HasTags then
						TagValue ..= " "
					end

					HasTags = true

					TagValue ..= string.sub( Property, 8, #Property )
				end
			elseif string.sub( tostring(Property), 1,  14 ) == "RoactHostEvent" then
				local ValueType = type(Value)

				if ValueType == "table" then
					local Parameters = table.clone(Value)

					table.remove(Parameters, 1)

					local MainFunction = Value[1]

					Main[Property] = function(...)
						MainFunction( ..., unpack(Parameters) )
					end
				end
			elseif Property == RoactCompat.Children then
				Children = Value

				Main[Property] = nil
			end
		end
	end
	
	if HasTags then
		Main[React.Tag] = TagValue
	end
	
	return createElement(Type, Main, Children)
end

-- Add components support
RoactCompat.setComponentsTable = function(Table)
	ComponentsTable = Table
end

return RoactCompat
