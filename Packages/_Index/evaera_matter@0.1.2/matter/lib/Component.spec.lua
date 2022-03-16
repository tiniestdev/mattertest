local Component = require(script.Parent.Component)
local None = require(script.Parent.Parent.Llama).None
local component = Component.newComponent

return function()
	describe("Component", function()
		it("should create components", function()
			local a = component()
			local b = component()

			expect(getmetatable(a)).to.be.ok()

			expect(getmetatable(a)).to.never.equal(getmetatable(b))

			expect(typeof(a.new)).to.equal("function")
		end)

		it("should allow calling the table to construct", function()
			local a = component()

			expect(getmetatable(a())).to.equal(getmetatable(a.new()))
		end)

		it("should allow patching into a new component", function()
			local A = component()

			local a = A({
				foo = "bar",
				unset = true,
			})

			local a2 = a:patch({
				baz = "qux",
				unset = None,
			})

			expect(a2.foo).to.equal("bar")
			expect(a2.unset).to.equal(nil)
			expect(a2.baz).to.equal("qux")
		end)
	end)
end
