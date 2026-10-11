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
	Instance = function(Data: string)
		local DataBuffer = buffer.fromstring(Data)
		
		local Base64DecodedData = EncodingService:Base64Decode(DataBuffer)
		
		local DesializedInstances = SerializationService:DeserializeInstancesAsync(Base64DecodedData)
		
		return DesializedInstances[1]
	end,
	EnumItem = function(Data: string, Enum: Enum)
		local Object = Enum:FromValue( tonumber(Data) )
		
		print(Object)
		
		return Object
	end,
	Font = function(Data: string)
		return Font.new(Data)
	end,
}

local function Decode(Data: any, Type: string, ...)
	if Types[Type] then
		return Types[Type](Data, ...)
	else
		return Data
	end
end

return Decode
