-- Compiled with roblox-ts v1.2.3
local TS = require(script.TS.RuntimeLib)
local NetServerContext = TS.import(script, script, "server")
local NetClientContext = TS.import(script, script, "client")
local NetDefinitions = TS.import(script, script, "definitions").default
local NetMiddleware = TS.import(script, script, "middleware").NetMiddleware
local NetSerialization = TS.import(script, script, "serialization")
local BUILD_TYPE = "Luau"
--[[
	*
	* Networking Library for Roblox
	* @version 2.0
]]
local Net = {}
do
	local _container = Net
	--[[
		*
		* An object that contains a `Serialize` method.
		* @internal Still in development
	]]
	--[[
		*
		* A serialized representation of the object
		* @internal Still in development
	]]
	--[[
		*
		* Legacy client API for Net
	]]
	local Client = NetClientContext
	_container.Client = Client
	--[[
		*
		* Legacy server API for Net
	]]
	local Server = NetServerContext
	_container.Server = Server
	--[[
		*
		* The definitions API for Net
	]]
	local Definitions = NetDefinitions
	_container.Definitions = Definitions
	--[[
		*
		* The version of RbxNet
	]]
	local VERSION = "2.1.4" .. " (" .. ("production" == "development" and "DEV " .. BUILD_TYPE or BUILD_TYPE) .. ")"
	_container.VERSION = VERSION
	--[[
		*
		* Built-in middlewares
	]]
	local Middleware = NetMiddleware
	_container.Middleware = Middleware
	--[[
		*
		* Middleware function type for Net
	]]
	--[[
		*
		* Network serialization namespace
		* @internal Still in development
	]]
	local Serialization = NetSerialization
	_container.Serialization = Serialization
end
return Net
