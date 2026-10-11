local SyncAPI = script.Parent;
local Tool = SyncAPI.Parent;
local ServerEndpoint = SyncAPI:WaitForChild 'ServerEndpoint';
local RunService = game:GetService 'RunService'

-- Provide functionality to the local API endpoint instance
SyncAPI.OnInvoke = function (...)
	return ServerEndpoint:InvokeServer(...)
end;
