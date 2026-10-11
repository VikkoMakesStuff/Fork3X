local SyncAPI = script.Parent;
local Tool = SyncAPI.Parent;
local ServerEndpoint = SyncAPI:WaitForChild 'ServerEndpoint';
local RunService = game:GetService 'RunService'

local lplr=game:GetService("Players").LocalPlayer
local isPlugin=plugin~=nil
local syncmodule=nil

if isPlugin then
	syncmodule=require(SyncAPI:WaitForChild("SyncModule"))
end

-- Provide functionality to the local API endpoint instance
SyncAPI.OnInvoke = function (...)
	if isPlugin then
		return syncmodule.PerformAction(lplr,...)
	end
	return ServerEndpoint:InvokeServer(...)
end;
