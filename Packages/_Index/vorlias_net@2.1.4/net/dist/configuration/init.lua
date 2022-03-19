-- Compiled with roblox-ts v1.2.3
local TS = require(script.Parent.TS.RuntimeLib)
local IS_CLIENT = TS.import(script, script.Parent, "internal").IS_CLIENT
local runService = game:GetService("RunService")
local IS_SERVER = runService:IsServer()
local Configuration = {
	ServerThrottleResetTimer = 60,
	EnableDebugMessages = "production" == "development",
	ServerThrottleMessage = "Request limit exceeded ({limit}) by {player} via {remote}",
}
local NetConfig = {}
do
	local _container = NetConfig
	-- * @internal
	local DebugEnabled = "production" == "development"
	_container.DebugEnabled = DebugEnabled
	local function SetClient(config)
		assert(IS_CLIENT, "Use SetClient on the client!")
		local _ptr = {}
		for _k, _v in pairs(Configuration) do
			_ptr[_k] = _v
		end
		for _k, _v in pairs(config) do
			_ptr[_k] = _v
		end
		Configuration = _ptr
	end
	_container.SetClient = SetClient
	local function Set(config)
		assert(IS_SERVER, "Use Set on the server!")
		local _ptr = {}
		for _k, _v in pairs(Configuration) do
			_ptr[_k] = _v
		end
		for _k, _v in pairs(config) do
			_ptr[_k] = _v
		end
		Configuration = _ptr
	end
	_container.Set = Set
	local function Get()
		return Configuration
	end
	_container.Get = Get
	--[[
		*
		* @deprecated
		* @rbxts client
	]]
	local function SetClientConfiguration(key, value)
		assert(IS_CLIENT, "Use SetConfiguration on the server!")
		if key == "EnableDebugMessages" then
			Configuration.EnableDebugMessages = value
		end
	end
	_container.SetClientConfiguration = SetClientConfiguration
	--[[
		*
		* @rbxts server
		* @deprecated
		*
	]]
	local function SetConfiguration(key, value)
		assert(IS_SERVER, "Cannot set configuration on client!")
		Configuration[key] = value
	end
	_container.SetConfiguration = SetConfiguration
	--[[
		*
		* @deprecated
	]]
	local function GetConfiguration(key)
		return Configuration[key]
	end
	_container.GetConfiguration = GetConfiguration
	-- * @internal
	local function DebugWarn(...)
		local message = { ... }
		if DebugEnabled then
			warn("[rbx-net-debug]", unpack(message))
		end
	end
	_container.DebugWarn = DebugWarn
	-- * @internal
	local function DebugLog(...)
		local message = { ... }
		if DebugEnabled then
			print("[rbx-net-debug]", unpack(message))
		end
	end
	_container.DebugLog = DebugLog
end
return NetConfig
