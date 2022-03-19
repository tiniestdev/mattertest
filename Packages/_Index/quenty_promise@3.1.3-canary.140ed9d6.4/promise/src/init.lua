return setmetatable({
	-- Core
	PromiseUtils = require(script.Shared.PromiseUtils);
	Promise = require(script.Shared.Promise);

	-- Utility
	PendingPromiseTracker = require(script.Shared.Utility.PendingPromiseTracker);
	PromiseInstanceUtils = require(script.Shared.Utility.PromiseInstanceUtils);
	promiseChild = require(script.Shared.Utility.promiseChild);
	promisePropertyValue = require(script.Shared.Utility.promisePropertyValue);
	promiseWait = require(script.Shared.Utility.promiseWait);
}, {
	__index = require(script.Shared.Promise);
})