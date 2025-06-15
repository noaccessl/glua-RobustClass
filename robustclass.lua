--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

	https://github.com/noaccessl/glua-RobustClass

–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Prepare
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
--
-- Functions
--
local Format = string.format
local strmatch = string.match
local strgmatch = string.gmatch

local TableCopy = table.Copy
local istable = istable
local isstring = isstring

local FindMetaTable = FindMetaTable
local RegisterMetaTable = RegisterMetaTable

local setmetatable = setmetatable
local getmetatable = getmetatable

local forcesetmetatable = debug.setmetatable
local forcegetmetatable = debug.getmetatable

local next = pairs( {} )

--
-- Globals
--
local _G = _G


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Init
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
robustclass = robustclass or {}

robustclass.VERSION = 250615 -- YY/MM/DD

setmetatable( robustclass, {

	__call = function( this, ... )

		return robustclass.Register( ... )

	end

} )


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: (Internal) Common __tostring-metamethod
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function fnCommonToString( pObj )

	local pObj_mt = forcegetmetatable( pObj )

	if ( not pObj_mt ) then
		return nil
	end

	if ( not pObj_mt.__index ) then
		return nil
	end

	local classname = pObj.ClassName

	if ( not classname ) then
		return nil
	end

	return Format( '%s: %p', classname, pObj )

end


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: (Internal) Inherits the provided base classes in the given class
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function inherit( class, inheritances )

	local pPrevBaseClass

	for baseclassname in strgmatch( inheritances, '([%w_]+),? ?' ) do

		local BaseClassMeta = FindMetaTable( baseclassname )

		if ( BaseClassMeta ) then

			local tPertinentBaseClass = TableCopy( BaseClassMeta )

			tPertinentBaseClass.__tostring, tPertinentBaseClass.__index, tPertinentBaseClass.MetaName, tPertinentBaseClass.MetaID = nil

			if ( pPrevBaseClass ) then

				pPrevBaseClass.BaseClass = tPertinentBaseClass
				getmetatable( pPrevBaseClass ).__index = tPertinentBaseClass

				pPrevBaseClass = tPertinentBaseClass

			else

				class.BaseClass = tPertinentBaseClass
				pPrevBaseClass = tPertinentBaseClass

			end

		else
			ErrorNoHalt( 'unknown inheritance \'', baseclassname, '\' for the \'', class.ClassName, '\' class\n' )
		end

	end

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: (Internal) Refines the given class
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function refine( class, classname, inheritances )

	for k in next, class do
		class[k] = nil
	end

	class.ClassName = classname
	class.__tostring = fnCommonToString

	class.__index = class

	if ( inheritances ) then
		inherit( class, inheritances )
	end

	local class_mt = getmetatable( class )

	if ( not class_mt ) then

		class_mt = {}
		setmetatable( class, class_mt )

	else

		for k in next, class_mt do
			class_mt[k] = nil
		end

	end

	function class_mt.__call( this, ... )

		return robustclass.Create( classname, ... )

	end

	if ( inheritances ) then
		class_mt.__index = class.BaseClass
	else
		class.BaseClass, class_mt.__index = nil
	end

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Registers a new class
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local ptrDummyClass = {}

function robustclass.Register( reginput )

	if ( not isstring( reginput ) ) then

		ErrorNoHaltWithStack( '\'reginput\' (#1) to \'Register\' should be a string; format: \'<ClassName>[ : <BaseClass>[, <BaseClass2>, ...]]\'\n' )
		return ptrDummyClass

	end

	--
	-- Retrieve the class name and the base classes if provided
	--
	local classname = strmatch( reginput, '([%w_]+)' )

	if ( not classname ) then

		ErrorNoHaltWithStack( '\'reginput\' (#1) to \'Register\' should be a string; format: \'<ClassName>[ : <BaseClass1>[, <BaseClass2>, ...]]\'\n' )
		return ptrDummyClass

	end

	local inheritances = strmatch( reginput, ' : (.+)' )

	local CLASS = FindMetaTable( classname )

	--
	-- If the class already exists, refine and return it
	--
	if ( CLASS ) then

		refine( CLASS, classname, inheritances )
		return CLASS

	end

	--
	-- Prepare the class
	--
	CLASS = {

		ClassName = classname;
		__tostring = fnCommonToString

	}

	CLASS.__index = CLASS

	--
	-- Deal with the inheritances
	--
	if ( inheritances ) then
		inherit( CLASS, inheritances )
	end

	--
	-- The metatable of the class itself
	--
	local CLASS_mt; do

		CLASS_mt = {}

		function CLASS_mt.__call( this, ... )

			return robustclass.Create( classname, ... )

		end

		CLASS_mt.__index = CLASS.BaseClass --[[

			Allows you to do cool Lua affairs without much performance loss

			local a = robustclass( 'a' )
			a.test = 'Hello World!'

			local b = robustclass( 'b : a' )
			local c = robustclass( 'c : b' )

			print( c.test ) -- Output: Hello World!

			local obj = robustclass.Create( 'c' )
			print( obj.test ) -- Output: Hello World!

			-- What happens internally (figuratively) — c.BaseClass.BaseClass.test

		]]--

		setmetatable( CLASS, CLASS_mt )

	end

	-- Store the class in the registry
	RegisterMetaTable( classname, CLASS )

	-- A global create-function wrap
	_G[classname] = function( ... )

		return robustclass.Create( classname, ... )

	end

	return CLASS

end

robustclass.Class = robustclass.Register


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: (Internal) Constructs the given object
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function construct( pObj, class, classname, ignite, ... )

	local baseclass = class.BaseClass

	if ( baseclass ) then

		local baseclassname = baseclass.ClassName

		construct( pObj, baseclass, baseclassname, ignite, ... )

		if ( ignite ) then

			local pfnNextConstructor = baseclass[baseclassname]

			if ( pfnNextConstructor ) then
				pfnNextConstructor( pObj, ... )
			end

		end

	end

	local pfnForemostConstructor = class[classname]

	if ( pfnForemostConstructor ) then
		pfnForemostConstructor( pObj, ... )
	end

	ignite = true

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Creates a new specific object
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
function robustclass.Create( classname, ... )

	if ( not isstring( classname ) ) then
		assert( false, '\'classname\' (#1) to \'Create\' should be a string' )
	end

	--
	-- Retrieve the class
	--
	local class = FindMetaTable( classname )

	if ( not class ) then

		ErrorNoHaltWithStack( false, 'class \'', classname, '\' doesn\'t exist' )
		return false

	end

	--
	-- Prepare an object
	--
	local pObj = {}
	setmetatable( pObj, class )

	--
	-- Allow the class to adjust/override the default creation action
	--
	local __new = class.__new
	local bContinue, pObjSubstitute, bConstruct = true, nil, true

	if ( __new ) then
		bContinue, pObjSubstitute, bConstruct = __new( pObj, ... )
	end

	if ( bContinue == false ) then

		-- Remove the metatable
		setmetatable( pObj, nil )

		-- Purge the object
		for key in next, pObj do pObj[key] = nil end

		return false

	end

	if ( pObjSubstitute ~= nil ) then

		local pObjSubstitute_mt = forcegetmetatable( pObjSubstitute )

		if ( not pObjSubstitute_mt ) then
			return nil
		end

		if ( pObjSubstitute_mt.__index ) then

			setmetatable( pObj, nil )

			for key in next, pObj do
				pObj[key] = nil
			end

			pObj = pObjSubstitute

		end

	end

	--
	-- Construct
	--
	if ( bConstruct == true ) then
		construct( pObj, class, classname, nil, ... )
	end

	return pObj

end

robustclass.CreateObject = robustclass.Create

robustclass.New = robustclass.Create
robustclass.NewObject = robustclass.Create


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: (Internal) Destructs the given object
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function destruct( pObj, class, classname, ignite )

	local baseclass = class.BaseClass

	if ( baseclass ) then

		local baseclassname = baseclass.ClassName

		destruct( pObj, baseclass, baseclassname, ignite )

		if ( ignite ) then

			local pfnNextDestructor = baseclass[ '_' .. baseclassname ]

			if ( pfnNextDestructor ) then
				pfnNextDestructor( pObj )
			end

		end

	end

	local pfnForemostDestructor = class[ '_' .. classname ]

	if ( pfnForemostDestructor ) then
		pfnForemostDestructor( pObj )
	end

	ignite = true

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Deletes the given object
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
function robustclass.Delete( pObj )

	local pObj_mt = forcegetmetatable( pObj )

	if ( not pObj_mt ) then
		return false
	end

	if ( not pObj_mt.__index ) then
		return false
	end

	local classname = pObj.ClassName

	if ( not classname ) then
		return false
	end

	local class = FindMetaTable( classname )

	if ( not class ) then
		return false
	end

	--
	-- Allow the class to adjust/override the default deletion action
	--
	local __delete = class.__delete

	if ( __delete and __delete( pObj ) == false ) then
		return false
	end

	-- Destruct
	destruct( pObj, class, classname, nil )

	-- Remove the metatable
	forcesetmetatable( pObj, nil )

	--
	-- Purge the object
	--
	if ( istable( pObj ) ) then

		for key in next, pObj do
			pObj[key] = nil
		end

	end

	return true

end

robustclass.DeleteObject = robustclass.Delete

robustclass.Destroy = robustclass.Delete
robustclass.DestroyObject = robustclass.Delete

robustclass.Remove = robustclass.Delete
robustclass.RemoveObject = robustclass.Delete
