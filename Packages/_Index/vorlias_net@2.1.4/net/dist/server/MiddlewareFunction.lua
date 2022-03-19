-- Compiled with roblox-ts v1.2.3
local TS = require(script.Parent.Parent.TS.RuntimeLib)
local MiddlewareFunction
do
	MiddlewareFunction = {}
	function MiddlewareFunction:constructor(middlewares)
		if middlewares == nil then
			middlewares = {}
		end
		self.middlewares = middlewares
	end
	function MiddlewareFunction:_use(middleware)
		local _exp = (self.middlewares)
		-- ▼ Array.push ▼
		_exp[#_exp + 1] = middleware
		-- ▲ Array.push ▲
	end
	function MiddlewareFunction:_processMiddleware(callback)
		local _binding = self
		local middlewares = _binding.middlewares
		local _exitType, _returns = TS.try(function()
			if #middlewares > 0 then
				local callbackFn = callback
				-- Run through each middleware
				for _, middleware in ipairs(middlewares) do
					callbackFn = middleware(callbackFn, self)
				end
				return TS.TRY_RETURN, { callbackFn }
			else
				return TS.TRY_RETURN, { callback }
			end
		end, function(e)
			warn("[rbx-net] " .. tostring(e))
		end)
		if _exitType then
			return unpack(_returns)
		end
	end
end
local default = MiddlewareFunction
return {
	default = default,
}
