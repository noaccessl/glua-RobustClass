--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

	RobustClass — GLua Classes System with a kinship to C++ classes

	GitHub: https://github.com/noaccessl/glua-RobustClass

–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Prepare
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
--
-- Libraries functions
--
local Format	= string.format
local strmatch	= string.match
local strgmatch = string.gmatch

local TableCopy = table.Copy

--
-- Globals
--
local istable	= istable
local isstring	= isstring

local FindMetaTable		= FindMetaTable
local RegisterMetaTable	= RegisterMetaTable

local setmetatable = debug.setmetatable
local getmetatable = debug.getmetatable

local _G = _G

--
-- Utilities
--
local next = pairs( {} )


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	RobustClass
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
robustclass = robustclass or {

	VERSION = 250217 -- yy/mm/dd

}

local robustclass = robustclass
local _ALIAS = {}

setmetatable( robustclass, {

	__index = _ALIAS;

	__call = function( this, ... )

		return robustclass.Register( ... )

	end

} )

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: (Internal) Common __tostring-metamethod
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function __tostring_common( pObj )

	local pObj_mt = getmetatable( pObj )

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

	return Format( '%s: %p', pObj.ClassName, pObj )

end


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: (Internal) Inherits the provided base classes in the given class
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function inherit( class_t, inheritances )

	local BaseClassFormer

	for baseclassname in strgmatch( inheritances, '([%w_]+),? ?' ) do

		local baseclass_t = FindMetaTable( baseclassname )

		if ( baseclass_t ) then

			local BaseClassLatter = TableCopy( baseclass_t )

			BaseClassLatter.__tostring, BaseClassLatter.__index, BaseClassLatter.MetaName, BaseClassLatter.MetaID = nil

			if ( BaseClassFormer ) then

				BaseClassFormer.BaseClass = BaseClassLatter
				getmetatable( BaseClassFormer ).__index = BaseClassLatter

				BaseClassFormer = BaseClassLatter

			else

				class_t.BaseClass = BaseClassLatter
				BaseClassFormer = BaseClassLatter

			end

		else
			ErrorNoHalt( 'unknown inheritance \'', baseclassname, '\' for the \'', class_t.ClassName, '\' class\n' )
		end

	end

end


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: (Internal) Refines the given class
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function refine( class_t, classname, inheritances )

	for k in next, class_t do
		class_t[k] = nil
	end

	class_t.ClassName = classname
	class_t.__tostring = __tostring_common

	class_t.__index = class_t

	if ( inheritances ) then
		inherit( class_t, inheritances )
	end


	local class_mt = getmetatable( class_mt )

	if ( not class_mt ) then

		class_mt = {}
		setmetatable( class_t, class_mt )

	else

		for k in next, class_mt do
			class_mt[k] = nil
		end

	end

	function class_mt.__call( this, ... )

		return robustclass.Create( classname, ... )

	end

	if ( inheritances ) then
		class_mt.__index = class_t.BaseClass
	else
		class_t.BaseClass, class_mt.__index = nil
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


	local CLASS

	--
	-- If the class already exists, refine and return it
	--
	CLASS = FindMetaTable( classname )

	if ( CLASS ) then

		refine( CLASS, classname, inheritances )
		return CLASS

	end

	--
	-- Prepare the class
	--
	CLASS = {

		ClassName = classname;
		__tostring = __tostring_common

	}

	CLASS.__index = CLASS

	--
	-- Deal with the inheritances
	--
	if ( inheritances ) then
		inherit( CLASS, inheritances )
	end


	local CLASS_mt do

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

	-- A global create-wrapper
	_G[classname] = function( ... )

		return robustclass.Create( classname, ... )

	end

	return CLASS

end

_ALIAS.Class = robustclass.Register


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: (Internal) Constructs the given object
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function construct( pObj, class_t, classname, ignite, ... )

	local baseclass_t = class_t.BaseClass

	if ( baseclass_t ) then

		local baseclassname = baseclass_t.ClassName

		construct( pObj, baseclass_t, baseclassname, ignite, ... )

		if ( ignite ) then

			local ConstructorLatter = baseclass_t[baseclassname]

			if ( ConstructorLatter ) then
				ConstructorLatter( pObj, ... )
			end

		end

	end


	local ConstructorForemost = class_t[classname]

	if ( ConstructorForemost ) then
		ConstructorForemost( pObj, ... )
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
	local class_t = FindMetaTable( classname )

	if ( not class_t ) then

		ErrorNoHaltWithStack( false, 'class \'', classname, '\' doesn\'t exist' )
		return false

	end

	--
	-- Prepare an object
	--
	local pObj = {}
	setmetatable( pObj, class_t )

	--
	-- Allow the class to adjust/override the default creation action
	--
	local __new = class_t.__new
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

		local pObjSubstitute_mt = getmetatable( pObjSubstitute )

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
		construct( pObj, class_t, classname, nil, ... )
	end

	return pObj

end

_ALIAS.CreateObject = robustclass.Create

_ALIAS.New = robustclass.Create
_ALIAS.NewObject = robustclass.Create


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: (Internal) Destructs the given object
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function destruct( pObj, class_t, classname, ignite )

	local baseclass_t = class_t.BaseClass

	if ( baseclass_t ) then

		local baseclassname = baseclass_t.ClassName

		destruct( pObj, baseclass_t, baseclassname, ignite )

		if ( ignite ) then

			local DestructorLatter = baseclass_t[ '_' .. baseclassname ]

			if ( DestructorLatter ) then
				DestructorLatter( pObj )
			end

		end

	end


	local DestructorForemost = class_t[ '_' .. classname ]

	if ( DestructorForemost ) then
		DestructorForemost( pObj )
	end

	ignite = true

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Deletes the given object
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
function robustclass.Delete( pObj )

	local pObj_mt = getmetatable( pObj )

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

	local class_t = FindMetaTable( classname )

	if ( not class_t ) then
		return false
	end

	--
	-- Allow the class to adjust/override the default deletion action
	--
	local __delete = class_t.__delete

	if ( __delete and __delete( pObj ) == false ) then
		return false
	end

	-- Destruct
	destruct( pObj, class_t, classname, nil )

	-- Remove the metatable
	setmetatable( pObj, nil )

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

_ALIAS.DeleteObject = robustclass.Delete

_ALIAS.Destroy = robustclass.Delete
_ALIAS.DestroyObject = robustclass.Delete

_ALIAS.Remove = robustclass.Delete
_ALIAS.RemoveObject = robustclass.Delete
