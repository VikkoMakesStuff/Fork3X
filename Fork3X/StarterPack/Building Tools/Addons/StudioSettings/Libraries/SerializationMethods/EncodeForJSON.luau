local Encode = {}

local SerializationService = game:GetService("SerializationService")
local EncodingService = game:GetService("EncodingService")

local function Concat(MainTable, ...)
	local NewTable = table.clone(MainTable)
	
	local Tables = {...}
	
	for _, Table in next, Tables do
		for Index, Key in Table do
			table.insert(NewTable, Key)
		end
	end
	
	return NewTable
end

local Types = {
	Instance = function(Object: Instance)
		local SerialisedData = SerializationService:SerializeInstancesAsync( {Object} )

		local Base64EncodedBuffer = EncodingService:Base64Encode(SerialisedData)
		local JSONCompliantString = buffer.tostring(Base64EncodedBuffer)

		return JSONCompliantString
	end,
	EnumItem = function(EnumItem: EnumItem)
		return EnumItem.Value
	end,
	Font = function(Font: Font)
		return Font.Family
	end,
}

local function Encode(Data: any)
	local Type = typeof(Data)
	
	if Types[Type] then
		return Types[Type](Data)
	else
		return Data
	end
end

return Encode
