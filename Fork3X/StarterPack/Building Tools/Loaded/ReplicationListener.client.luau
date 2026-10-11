local Indicator = script.Parent;
local Tool = Indicator.Parent;

-- Wait for tool to load completely
local TotalDescendants = (Indicator:WaitForChild 'DescendantCount');

if TotalDescendants.Value == 0 then
	TotalDescendants.Changed:Wait()
end

while not (#Tool:GetDescendants() >= TotalDescendants.Value) do
	task.wait(0.001);
end;

-- Set load indicator to true upon load completion
Indicator.Value = true;