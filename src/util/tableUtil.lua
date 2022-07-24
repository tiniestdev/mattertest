-- Table Util
-- Stephen Leitnick
-- September 13, 2017

-- modified by tiniestman
-- (renamed tableUtil)
-- 7/8/2020


--[[

++	tableUtil.ToSet(list)
++  tableUtil.FlipNumeric(tab1)
++  tableUtil.GetBetweenIndex(t, value, fcomp)
++  tableUtil.Flip(tab1) --returned table with index and values flipped
++  tableUtil.HaveSameValues(tab1, tab2)
++  tableUtil.GetRepeatedValues(tab)
++  tableUtil.AppendUnique(target, source)
++ 	tableUtil.Append(target, source)
++ 	tableUtil.ToString(tab, titleText)
	tableUtil.Copy(Table tbl)
	tableUtil.CopyShallow(Table tbl)
	tableUtil.Sync(Table tbl, Table templateTbl)
	tableUtil.Print(Table tbl, String label, Boolean deepPrint)
	tableUtil.FastRemove(Table tbl, Number index)
	tableUtil.FastRemoveFirstValue(Table tbl, Variant value)
	tableUtil.Map(Table tbl, Function callback)
	tableUtil.Filter(Table tbl, Function callback)
	tableUtil.Reduce(Table tbl, Function callback [, Number initialValue])
	tableUtil.Assign(Table target, ...Table sources)
	tableUtil.IndexOf(Table tbl, Variant item)
	tableUtil.Reverse(Table tbl)
	tableUtil.Shuffle(Table tbl)
	tableUtil.IsEmpty(Table tbl)
	tableUtil.EncodeJSON(Table tbl)
	tableUtil.DecodeJSON(String json)

	--the two functions are the same
	tableUtil.BinaryInsert(Table t, Variant value, Function fcomp)
	tableUtil.SortedInsert = BinaryInsert

	EXAMPLES:

		Copy:

			Performs a deep copy of the given table. In other words,
			all nested tables will also get copied.

			local tbl = {"a", "b", "c"}
			local tblCopy = tableUtil.Copy(tbl)


		CopyShallow:

			Performs a shallow copy of the given table. In other words,
			all nested tables will not be copied, but only moved by
			reference. Thus, a nested table in both the original and
			the copy will be the same.

			local tbl = {"a", "b", "c"}
			local tblCopy = tableUtil.CopyShallow(tbl)


		Sync:

			Synchronizes a table to a template table. If the table does not have an
			item that exists within the template, it gets added. If the table has
			something that the template does not have, it gets removed.

			local tbl1 = {kills = 0; deaths = 0; points = 0}
			local tbl2 = {points = 0}
			tableUtil.Sync(tbl2, tbl1)  -- In words: "Synchronize table2 to table1"
			print(tbl2.deaths)


		Print:

			Prints out the table to the output in an easy-to-read format. Good for
			debugging tables. If deep printing, avoid cyclical references.

			local tbl = {a = 32; b = 64; c = 128; d = {x = 0; y = 1; z = 2}}
			tableUtil.Print(tbl, "My Table", true)


		FastRemove:

			Removes an item from an array at a given index. Only use this if you do
			NOT care about the order of your array. This works by simply popping the
			last item in the array and overwriting the given index with the last
			item. This is O(1), compared to table.remove's O(n) speed.

			local tbl = {"hello", "there", "this", "is", "a", "test"}
			tableUtil.FastRemove(tbl, 2)   -- Remove "there" in the array
			print(table.concat(tbl, " "))  -- > hello test is a


		FastRemoveFirstValue:

			Calls FastRemove on the first index that holds the given value.

			local tbl = {"abc", "hello", "hi", "goodbye", "hello", "hey"}
			local removed, atIndex = tableUtil.FastRemoveFirstValue(tbl, "hello")
			if (removed) then
				print("Removed at index " .. atIndex)
				print(table.concat(tbl, " "))  -- > abc hi goodbye hello hey
			else
				print("Did not find value")
			end

		
		Map:

			This allows you to construct a new table by calling the given function
			on each item in the table.

			local peopleData = {
				{firstName = "Bob"; lastName = "Smith"};
				{firstName = "John"; lastName = "Doe"};
				{firstName = "Jane"; lastName = "Doe"};
			}

			local people = tableUtil.Map(peopleData, function(item)
				return {Name = item.firstName .. " " .. item.lastName}
			end)

			-- 'people' is now an array that looks like: { {Name = "Bob Smith"}; ... }


		Filter:

			This allows you to create a table based on the given table and a filter
			function. If the function returns 'true', the item remains in the new
			table; if the function returns 'false', the item is discluded from the
			new table.

			local people = {
				{Name = "Bob Smith"; Age = 42};
				{Name = "John Doe"; Age = 34};
				{Name = "Jane Doe"; Age = 37};
			}

			local peopleUnderForty = tableUtil.Filter(people, function(item)
				return item.Age < 40
			end)


		Reduce:

			This allows you to reduce an array to a single value. Useful for quickly
			summing up an array.

			local tbl = {40, 32, 9, 5, 44}
			local tblSum = tableUtil.Reduce(tbl, function(accumulator, value)
				return accumulator + value
			end)
			print(tblSum)  -- > 130


		Assign:

			This allows you to assign values from multiple tables into one. The
			Assign function is very similar to JavaScript's Object.Assign() and
			is useful for things such as composition-designed systems.

			local function Driver()
				return {
					Drive = function(self) self.Speed = 10 end;
				}
			end

			local function Teleporter()
				return {
					Teleport = function(self, pos) self.Position = pos end;
				}
			end

			local function CreateCar()
				local state = {
					Speed = 0;
					Position = Vector3.new();
				}
				-- Assign the Driver and Teleporter components to the car:
				return tableUtil.Assign({}, Driver(), Teleporter())
			end

			local car = CreateCar()
			car:Drive()
			car:Teleport(Vector3.new(0, 10, 0))


		IndexOf:

			Returns the index of the given item in the table. If not found, this
			will return nil.

			This is the same as table.find, which Roblox added after this method
			was written. To keep backwards compatibility, this method will continue
			to exist, but will point directly to table.find.

			local tbl = {"Hello", 32, true, "abc"}
			local abcIndex = tableUtil.IndexOf(tbl, "abc")     -- > 4
			local helloIndex = tableUtil.IndexOf(tbl, "Hello") -- > 1
			local numberIndex = tableUtil.IndexOf(tbl, 64)     -- > nil


		Reverse:

			Creates a reversed version of the array. Note: This is a shallow
			copy, so existing references will remain within the new table.

			local tbl = {2, 4, 6, 8}
			local rblReversed = tableUtil.Reverse(tbl)  -- > {8, 6, 4, 2}


		Shuffle:

			Shuffles (i.e. randomizes) an array. This uses the Fisher-Yates algorithm.

			local tbl = {1, 2, 3, 4, 5, 6, 7, 8, 9}
			tableUtil.Shuffle(tbl)
			print(table.concat(tbl, ", "))  -- e.g. > 3, 6, 9, 2, 8, 4, 1, 7, 5
	
--]]



local tableUtil = {}

local http = game:GetService("HttpService")

local IndexOf = table.find


local function CopyTable(t)
	assert(type(t) == "table", "First argument must be a table")
	local tCopy = table.create(#t)
	for k,v in pairs(t) do
		if type(v) == "table" then
			tCopy[k] = CopyTable(v)
		else
			tCopy[k] = v
		end
	end
	return tCopy
end


local function CopyTableShallow(t)
	local tCopy = table.create(#t)
    for k,v in pairs(t) do 
        tCopy[k] = v 
    end
	return tCopy
end


local function Sync(tbl, templateTbl)

	assert(type(tbl) == "table", "First argument must be a table")
	assert(type(templateTbl) == "table", "Second argument must be a table")
	
	-- If 'tbl' has something 'templateTbl' doesn't, then remove it from 'tbl'
	-- If 'tbl' has something of a different type than 'templateTbl', copy from 'templateTbl'
	-- If 'templateTbl' has something 'tbl' doesn't, then add it to 'tbl'
	for k,v in pairs(tbl) do
		
		local vTemplate = templateTbl[k]
		
		-- Remove keys not within template:
		if vTemplate == nil then
			tbl[k] = nil
			
		-- Synchronize data types:
		elseif type(v) ~= type(vTemplate) then
			if type(vTemplate) == "table" then
				tbl[k] = CopyTable(vTemplate)
			else
				tbl[k] = vTemplate
			end
		
		-- Synchronize sub-tables:
		elseif type(v) == "table" then
			Sync(v, vTemplate)
		end
		
	end
	
	-- Add any missing keys:
	for k,vTemplate in pairs(templateTbl) do
		
		local v = tbl[k]
		
		if v == nil then
			if type(vTemplate) == "table" then
				tbl[k] = CopyTable(vTemplate)
			else
				tbl[k] = vTemplate
			end
		end
		
	end
	
end


local function FastRemove(t, i)
	local n = #t
	t[i] = t[n]
	t[n] = nil
end


local function Map(t, f)
	assert(type(t) == "table", "First argument must be a table")
	assert(type(f) == "function", "Second argument must be an array")
	local newT = table.create(#t)
	for k,v in pairs(t) do
		newT[k] = f(v, k, t)
	end
	return newT
end


local function Filter(t, f)
	assert(type(t) == "table", "First argument must be a table")
	assert(type(f) == "function", "Second argument must be an array")
	local newT = table.create(#t)
	if #t > 0 then
		local n = 0
		for i = 1,#t do
			local v = t[i]
			if f(v, i, t) then
				n = (n + 1)
				newT[n] = v
			end
		end
	else
		for k,v in pairs(t) do
			if f(v, k, t) then
				newT[k] = v
			end
		end
	end
	return newT
end


local function Reduce(t, f, init)
	assert(type(t) == "table", "First argument must be a table")
	assert(type(f) == "function", "Second argument must be an array")
	assert(init == nil or type(init) == "number", "Third argument must be a number or nil")
	local result = (init or 0)
	for k,v in pairs(t) do
		result = f(result, v, k, t)
	end
	return result
end


-- tableUtil.Assign(Table target, ...Table sources)
local function Assign(target, ...)
	for _,src in ipairs({...}) do
		for k,v in pairs(src) do
			target[k] = v
		end
	end
	return target
end


local function Print(tbl, label, deepPrint)

	assert(type(tbl) == "table", "First argument must be a table")
	assert(label == nil or type(label) == "string", "Second argument must be a string or nil")
	
	label = (label or "TABLE")
	
	local strTbl = {}
	local indent = " - "
	
	-- Insert(string, indentLevel)
	local function Insert(s, l)
		strTbl[#strTbl + 1] = (indent:rep(l) .. s .. "\n")
	end
	
	local function AlphaKeySort(a, b)
		return (tostring(a.k) < tostring(b.k))
	end
	
	local function PrintTable(t, lvl, lbl)
		Insert(lbl .. ":", lvl - 1)
		local nonTbls = {}
		local tbls = {}
		local keySpaces = 0
		for k,v in pairs(t) do
			if type(v) == "table" then
				table.insert(tbls, {k = k, v = v})
			else
				table.insert(nonTbls, {k = k, v = "[" .. typeof(v) .. "] " .. tostring(v)})
			end
			local spaces = #tostring(k) + 1
			if spaces > keySpaces then
				keySpaces = spaces
			end
		end
		table.sort(nonTbls, AlphaKeySort)
		table.sort(tbls, AlphaKeySort)
		for _,v in pairs(nonTbls) do
			Insert(tostring(v.k) .. ":" .. (" "):rep(keySpaces - #tostring(v.k)) .. v.v, lvl)
		end
		if deepPrint then
			for _,v in pairs(tbls) do
				PrintTable(v.v, lvl + 1, tostring(v.k) .. (" "):rep(keySpaces - #tostring(v.k)) .. " [Table]")
			end
		else
			for _,v in pairs(tbls) do
				Insert(tostring(v.k) .. ":" .. (" "):rep(keySpaces - #tostring(v.k)) .. "[Table]", lvl)
			end
		end
	end
	
	PrintTable(tbl, 1, label)
	
	print(table.concat(strTbl, ""))
	
end


local function Reverse(tbl)
	local n = #tbl
	local tblRev = table.create(n)
	for i = 1,n do
		tblRev[i] = tbl[n - i + 1]
	end
	return tblRev
end


local function Shuffle(tbl)
	assert(type(tbl) == "table", "First argument must be a table")
	local rng = Random.new()
	for i = #tbl, 2, -1 do
		local j = rng:NextInteger(1, i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end


local function IsEmpty(tbl)
	return (next(tbl) == nil)
end


local function EncodeJSON(tbl)
	return http:JSONEncode(tbl)
end


local function DecodeJSON(str)
	return http:JSONDecode(str)
end


local function FastRemoveFirstValue(t, v)
	local index = IndexOf(t, v)
	if index then
		FastRemove(t, index)
		return true, index
	end
	return false, nil
end


local fcomp_default = function( a,b )
    return a < b
end

local function GetBetweenIndex(t, value, fcomp)
	fcomp = fcomp or fcomp_default
	local iStart,iEnd,iMid,iState = 1,#t,1,0
	while iStart <= iEnd do
		-- calculate middle
		iMid = math.floor( (iStart+iEnd)/2 )
		-- compare
		if fcomp( value,t[iMid] ) then
			iEnd,iState = iMid - 1,0
		else
			iStart,iState = iMid + 1,1
		end
	end
	return (iMid+iState)
end

local function BinaryInsert(t, value, fcomp)
	local insertAtIndex = GetBetweenIndex(t, value, fcomp)
	table.insert( t,insertAtIndex,value )
	return insertAtIndex
end

--- Concats `target` with `source`
-- @tparam table target Table to append to
-- @tparam table source Table read from
-- @treturn table parameter table
local function Append(target, source)
	for _, value in pairs(source) do
		target[#target+1] = value
	end

	return target
end

--- Concats `target` with `source`
-- @tparam table target Table to append to
-- @tparam table source Table read from
-- @treturn table parameter table
local function AppendUnique(target, source)
	for _, value in pairs(source) do
		if not table.find(target, value) then
			target[#target+1] = value
		end
	end
	return target
end

local function GetRepeatedValues(tab)
	local uniqueValues = {}
	local repeatedValues = {}
	for _, value in ipairs(tab) do
		if table.find(uniqueValues, value) and not table.find(repeatedValues, value) then
			repeatedValues[#repeatedValues+1] = value
		else
			uniqueValues[#uniqueValues+1] = value
		end
	end
	return repeatedValues
end

local function HaveSameValues(tab1, tab2)
	if #tab1 ~= #tab2 then return false end
	for _,v in ipairs(tab1) do
		if not table.find(tab2, v) then
			return false
		end
	end
	for _,v in ipairs(tab2) do
		if not table.find(tab1, v) then
			return false
		end
	end
	return true
end

local function Flip(tab1)
	local newTab = {}
	for i,v in pairs(tab1) do
		newTab[v] = i
	end
	return newTab
end

local function FlipNumeric(tab1)
	local newTab = {}
	for k,v in pairs(tab1) do
		table.insert(newTab, k)
	end
	return newTab
end

local function Rotate(tab)
	local temp = tab[#tab]
	for i = #tab, 2, -1 do
		tab[i] = tab[i-1]
	end
	tab[1] = temp
	return tab
end

local function ToString(tab, titleText)
	local str = string.format("%s:\n", tostring(titleText) or "table")
	for i,v in pairs(tab) do
		str = str .. string.format("%s: %s\n", tostring(i), tostring(v))
	end
	return str
end

local function ToSet(list)
	local set = {}
	for _, v in ipairs(list) do
		set[v] = true
	end
	return set
end

tableUtil.Copy = CopyTable
tableUtil.CopyShallow = CopyTableShallow
tableUtil.Sync = Sync
tableUtil.FastRemove = FastRemove
tableUtil.FastRemoveFirstValue = FastRemoveFirstValue
tableUtil.Print = Print
tableUtil.Map = Map
tableUtil.Filter = Filter
tableUtil.Reduce = Reduce
tableUtil.Assign = Assign
tableUtil.IndexOf = IndexOf
tableUtil.Reverse = Reverse
tableUtil.Shuffle = Shuffle
tableUtil.IsEmpty = IsEmpty
tableUtil.EncodeJSON = EncodeJSON
tableUtil.DecodeJSON = DecodeJSON
tableUtil.BinaryInsert = BinaryInsert
tableUtil.GetBetweenIndex = GetBetweenIndex
tableUtil.SortedInsert = BinaryInsert
tableUtil.Append = Append
tableUtil.AppendUnique = AppendUnique
tableUtil.GetRepeatedValues = GetRepeatedValues
tableUtil.HaveSameValues = HaveSameValues
tableUtil.Flip = Flip
tableUtil.FlipNumeric = FlipNumeric
tableUtil.Rotate = Rotate
tableUtil.ToString = ToString
tableUtil.ToSet = ToSet

return tableUtil