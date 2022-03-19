return setmetatable({
	SignalUtils = require(script.Shared.SignalUtils);
	Signal = require(script.Shared.Signal);
}, {
	__index = require(script.Shared.Signal);
})