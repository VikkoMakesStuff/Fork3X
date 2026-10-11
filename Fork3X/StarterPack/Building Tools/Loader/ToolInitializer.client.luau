local RunService = game:GetService("RunService")

if not plugin and not ( RunService:IsRunning() and RunService:IsServer() ) then
	require(script.Parent)
	script.Parent.Parent:WaitForChild("Options").Destroying:Connect(function()
		script.Parent.Parent:Destroy()
	end)
end