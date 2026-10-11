local EncodingDecoding = {}

EncodingDecoding.Decode = require(script.DecodeForJSON)
EncodingDecoding.Encode = require(script.EncodeForJSON)

function EncodingDecoding.GetDecodingFunction(Type)
	if type(Type) == "table" then
		local FirstKey, FirstValue = next(Type)
		
		local KeyFunction = function(Key)
			return EncodingDecoding.Decode(Key, FirstKey)
		end
		
		local ValueFunction = function(Value)
			return EncodingDecoding.Decode(Value, FirstValue)
		end
		
		return function(Table)
			local DecodedTable = {}
			
			for Key, Value in Table do
				DecodedTable[ KeyFunction(Key) ] = ValueFunction(Value)
			end
			
			return DecodedTable
		end
	elseif typeof(Type) == "Enum" then
		return function(Value)
			return EncodingDecoding.Decode(Value, "EnumItem", Type)
		end
	else
		return function(Value)
			return EncodingDecoding.Decode(Value, Type)
		end
	end
end

function EncodingDecoding.EncodeTable(Table)
	local DecodedTable = {}

	for Key, Value in Table do
		DecodedTable[ EncodingDecoding.Encode(Key) ] = EncodingDecoding.Encode(Value)
	end

	return DecodedTable
end

return EncodingDecoding
