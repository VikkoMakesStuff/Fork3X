local RunService = game:GetService("RunService")

if plugin and not ( RunService:IsRunning() and RunService:IsServer() ) then
    require(script.Parent)
end