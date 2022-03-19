-- Compiled with roblox-ts v1.2.3
local TS = require(script.Parent.Parent.TS.RuntimeLib)
local ClientAsyncFunction = TS.import(script, script.Parent.Parent, "client", "ClientAsyncFunction").default
local ClientEvent = TS.import(script, script.Parent.Parent, "client", "ClientEvent").default
local ClientFunction = TS.import(script, script.Parent.Parent, "client", "ClientFunction").default
-- Keep the declarations fully isolated
local declarationMap = setmetatable({}, {
	__mode = "k",
})
local ClientDefinitionBuilder
do
	ClientDefinitionBuilder = setmetatable({}, {
		__tostring = function()
			return "ClientDefinitionBuilder"
		end,
	})
	ClientDefinitionBuilder.__index = ClientDefinitionBuilder
	function ClientDefinitionBuilder.new(...)
		local self = setmetatable({}, ClientDefinitionBuilder)
		return self:constructor(...) or self
	end
	function ClientDefinitionBuilder:constructor(declarations, namespace)
		if namespace == nil then
			namespace = ""
		end
		self.namespace = namespace
		local _self = self
		-- ▼ Map.set ▼
		declarationMap[_self] = declarations
		-- ▲ Map.set ▲
	end
	function ClientDefinitionBuilder:toString()
		return "[" .. "ClientDefinitionBuilder" .. "]"
	end
	function ClientDefinitionBuilder:Get(remoteId)
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
			return ClientFunction.new(remoteId)
		elseif item.Type == "AsyncFunction" then
			return ClientAsyncFunction.new(remoteId)
		elseif item.Type == "Event" then
			return ClientEvent.new(remoteId)
		end
		error("Invalid Type")
	end
	function ClientDefinitionBuilder:GetNamespace(groupName)
		local _self = self
		local group = declarationMap[_self][groupName]
		local _arg0 = group.Type == "Namespace"
		assert(_arg0)
		local _fn = group.Definitions
		local _result
		if self.namespace ~= "" then
			-- ▼ ReadonlyArray.join ▼
			local _arg0_1 = ":"
			if _arg0_1 == nil then
				_arg0_1 = ", "
			end
			-- ▲ ReadonlyArray.join ▲
			_result = table.concat({ self.namespace, groupName }, _arg0_1)
		else
			_result = groupName
		end
		return _fn:_buildClientDefinition(_result)
	end
	ClientDefinitionBuilder.WaitFor = TS.async(function(self, remoteId)
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
			return ClientFunction:Wait(remoteId)
		elseif item.Type == "Event" then
			return ClientEvent:Wait(remoteId)
		elseif item.Type == "AsyncFunction" then
			return ClientAsyncFunction:Wait(remoteId)
		end
		error("Invalid Type")
	end)
	function ClientDefinitionBuilder:OnEvent(name, fn)
		local result = self:Get(name)
		result:Connect(fn)
	end
	function ClientDefinitionBuilder:OnFunction(name, fn)
		local result = self:Get(name)
		result:SetCallback(fn)
	end
	function ClientDefinitionBuilder:__tostring()
		return self:toString()
	end
end
return {
	ClientDefinitionBuilder = ClientDefinitionBuilder,
}
