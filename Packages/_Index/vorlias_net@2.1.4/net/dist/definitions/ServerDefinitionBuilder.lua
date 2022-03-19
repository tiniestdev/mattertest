-- Compiled with roblox-ts v1.2.3
local TS = require(script.Parent.Parent.TS.RuntimeLib)
local ServerAsyncFunction = TS.import(script, script.Parent.Parent, "server", "ServerAsyncFunction").default
local ServerEvent = TS.import(script, script.Parent.Parent, "server", "ServerEvent").default
local ServerFunction = TS.import(script, script.Parent.Parent, "server", "ServerFunction").default
local CollectionService = game:GetService("CollectionService")
-- Tidy up all the types here.
-- Keep the declarations fully isolated
local declarationMap = setmetatable({}, {
	__mode = "k",
})
local remoteEventCache = {}
local remoteAsyncFunctionCache = {}
local remoteFunctionCache = {}
local ServerDefinitionBuilder
do
	ServerDefinitionBuilder = setmetatable({}, {
		__tostring = function()
			return "ServerDefinitionBuilder"
		end,
	})
	ServerDefinitionBuilder.__index = ServerDefinitionBuilder
	function ServerDefinitionBuilder.new(...)
		local self = setmetatable({}, ServerDefinitionBuilder)
		return self:constructor(...) or self
	end
	function ServerDefinitionBuilder:constructor(declarations, globalMiddleware, namespace)
		if namespace == nil then
			namespace = ""
		end
		self.globalMiddleware = globalMiddleware
		self.namespace = namespace
		local _self = self
		-- ▼ Map.set ▼
		declarationMap[_self] = declarations
		-- ▲ Map.set ▲
		local _ = declarations
	end
	function ServerDefinitionBuilder:toString()
		return "[" .. "ServerDefinitionBuilder" .. "]"
	end
	function ServerDefinitionBuilder:OnEvent(name, fn)
		local result = self:Create(name)
		result:Connect(fn)
	end
	function ServerDefinitionBuilder:GetNamespace(groupId)
		local _self = self
		local group = declarationMap[_self][groupId]
		local _arg0 = group.Type == "Namespace"
		assert(_arg0)
		local _fn = group.Definitions
		local _exp = self.globalMiddleware
		local _result
		if self.namespace ~= "" then
			-- ▼ ReadonlyArray.join ▼
			local _arg0_1 = ":"
			if _arg0_1 == nil then
				_arg0_1 = ", "
			end
			-- ▲ ReadonlyArray.join ▲
			_result = table.concat({ self.namespace, groupId }, _arg0_1)
		else
			_result = groupId
		end
		return _fn:_buildServerDefinition(_exp, _result)
	end
	function ServerDefinitionBuilder:Create(remoteId)
		local _self = self
		local item = declarationMap[_self][remoteId]
		local _result
		if self.namespace ~= "" then
			-- ▼ ReadonlyArray.join ▼
			local _arg0 = ":"
			if _arg0 == nil then
				_arg0 = ", "
			end
			-- ▲ ReadonlyArray.join ▲
			_result = (table.concat({ self.namespace, remoteId }, _arg0))
		else
			_result = remoteId
		end
		remoteId = _result
		local _arg0 = item and item.Type
		local _arg1 = "'" .. remoteId .. "' is not defined in this definition."
		assert(_arg0, _arg1)
		if item.Type == "Function" then
			local func
			-- This should make certain use cases cheaper
			if remoteFunctionCache[remoteId] ~= nil then
				return remoteFunctionCache[remoteId]
			else
				if item.ServerMiddleware then
					func = ServerFunction.new(remoteId, item.ServerMiddleware)
				else
					func = ServerFunction.new(remoteId)
				end
				CollectionService:AddTag(func:GetInstance(), "NetDefinitionManaged")
				local _func = func
				-- ▼ Map.set ▼
				remoteFunctionCache[remoteId] = _func
				-- ▲ Map.set ▲
			end
			local _result_1 = self.globalMiddleware
			if _result_1 ~= nil then
				local _arg0_1 = function(mw)
					return func:_use(mw)
				end
				-- ▼ ReadonlyArray.forEach ▼
				for _k, _v in ipairs(_result_1) do
					_arg0_1(_v, _k - 1, _result_1)
				end
				-- ▲ ReadonlyArray.forEach ▲
			end
			return func
		elseif item.Type == "AsyncFunction" then
			local asyncFunction
			-- This should make certain use cases cheaper
			if remoteAsyncFunctionCache[remoteId] ~= nil then
				return remoteAsyncFunctionCache[remoteId]
			else
				if item.ServerMiddleware then
					asyncFunction = ServerAsyncFunction.new(remoteId, item.ServerMiddleware)
				else
					asyncFunction = ServerAsyncFunction.new(remoteId)
				end
				CollectionService:AddTag(asyncFunction:GetInstance(), "NetDefinitionManaged")
				local _asyncFunction = asyncFunction
				-- ▼ Map.set ▼
				remoteAsyncFunctionCache[remoteId] = _asyncFunction
				-- ▲ Map.set ▲
			end
			local _result_1 = self.globalMiddleware
			if _result_1 ~= nil then
				local _arg0_1 = function(mw)
					return asyncFunction:_use(mw)
				end
				-- ▼ ReadonlyArray.forEach ▼
				for _k, _v in ipairs(_result_1) do
					_arg0_1(_v, _k - 1, _result_1)
				end
				-- ▲ ReadonlyArray.forEach ▲
			end
			return asyncFunction
		elseif item.Type == "Event" then
			local event
			-- This should make certain use cases cheaper
			if remoteEventCache[remoteId] ~= nil then
				return remoteEventCache[remoteId]
			else
				if item.ServerMiddleware then
					event = ServerEvent.new(remoteId, item.ServerMiddleware)
				else
					event = ServerEvent.new(remoteId)
				end
				CollectionService:AddTag(event:GetInstance(), "NetDefinitionManaged")
				local _event = event
				-- ▼ Map.set ▼
				remoteEventCache[remoteId] = _event
				-- ▲ Map.set ▲
			end
			local _result_1 = self.globalMiddleware
			if _result_1 ~= nil then
				local _arg0_1 = function(mw)
					return event:_use(mw)
				end
				-- ▼ ReadonlyArray.forEach ▼
				for _k, _v in ipairs(_result_1) do
					_arg0_1(_v, _k - 1, _result_1)
				end
				-- ▲ ReadonlyArray.forEach ▲
			end
			return event
		end
		error("Invalid Type")
	end
	function ServerDefinitionBuilder:OnFunction(name, fn)
		local result = self:Create(name)
		result:SetCallback(fn)
	end
	function ServerDefinitionBuilder:__tostring()
		return self:toString()
	end
end
return {
	ServerDefinitionBuilder = ServerDefinitionBuilder,
}
