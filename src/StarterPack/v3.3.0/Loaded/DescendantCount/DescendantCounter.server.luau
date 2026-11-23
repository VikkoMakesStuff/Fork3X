local Count = script.Parent;
local Tool = Count.Parent.Parent;

-- Provide total count of all descendants
Count.Value = #Tool:GetDescendants();