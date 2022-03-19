-- Compiled with roblox-ts v1.2.3
local TS = require(script.Parent.Parent.TS.RuntimeLib)
local ClientDefinitionBuilder = TS.import(script, script.Parent, "ClientDefinitionBuilder").ClientDefinitionBuilder
local ServerDefinitionBuilder = TS.import(script, script.Parent, "ServerDefinitionBuilder").ServerDefinitionBuilder
local RunService = game:GetService("RunService")
-- Isolate the definitions since we don't need to access them anywhere else.
local declarationMap = setmetatable({}, {
	__mode = "k",
})
--[[
	*
	* A namespace builder. Internally used to construct definition builders
]]
local NamespaceBuilder
do
	NamespaceBuilder = setmetatable({}, {
		__tostring = function()
			return "NamespaceBuilder"
		end,
	})
	NamespaceBuilder.__index = NamespaceBuilder
	function NamespaceBuilder.new(...)
		local self = setmetatable({}, NamespaceBuilder)
		return self:constructor(...) or self
	end
	function NamespaceBuilder:constructor(declarations)
		local _self = self
		-- ▼ Map.set ▼
		declarationMap[_self] = declarations
		-- ▲ Map.set ▲
		local _ = declarations
	end
	function NamespaceBuilder:_buildServerDefinition(globalMiddleware, namespace)
		local _arg0 = RunService:IsServer()
		assert(_arg0)
		local _self = self
		return ServerDefinitionBuilder.new(declarationMap[_self], globalMiddleware, namespace)
	end
	function NamespaceBuilder:_buildClientDefinition(namespace)
		local _arg0 = RunService:IsClient()
		assert(_arg0)
		local _self = self
		return ClientDefinitionBuilder.new(declarationMap[_self], namespace)
	end
end
return {
	NamespaceBuilder = NamespaceBuilder,
}
