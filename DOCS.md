
# Documentation
Here you can get acquainted with the main insights of this library.

## Navigation
* Objects
	* **[Info](#objects)**
* Functions
	* **[robustclass.Namespace](#robustclass-namespace)**
	* **[robustclass.Register](#robustclass-register)**
	* **[robustclass.Create](#robustclass-create)**
	* **[robustclass.Delete](#robustclass-delete)**
* Classes
	* **[CLASS](#class)**

## Objects
A single unit of the particular class.</br>
Can be either a <code>**[table]**</code> or an <code>**[userdata]**</code>.</br>
Must have `index` field in its metatable.

## Functions

<a name="robustclass-namespace"></a>

#### <code>robustclass.Namespace( **[string]** name )</code>
* **Description**</br>
	&emsp; Sets the namespace in that code location where this function is called.</br>
	&emsp; The namespace applies when registering new classes. So, class names and base class names will be prefixed with the namespace itself: `<Namespace>::<ClassName>`

* **Arguments**
	* <code>**[string]**</code> **name**</br>
		&emsp; Set to `nil` to clear the namespace

---
</br>

<a name="robustclass-register"></a>

#### <code>robustclass.Register( **[string]** reginput )</code>
* **Description**</br>
	&emsp; Registers a new class.

* **Arguments**
	* <code>**[string]**</code> **reginput**</br>
		&emsp; The string with the class name and the base class(-es).</br>
		&emsp; Must be in the following format: `<ClassName>[ : <BaseClass>[, <BaseClass2>, ...]]`

* **Returns**
	* <code>**[table]**</code>
		* **ptrDummyClass = {}** on incorrect **reginput**
		* new/existing **[CLASS](#class)** on success

<details> <summary>Aliases</summary>

* `robustclass()`
* `robustclass.Class()`
</details>

---
</br>

<a name="robustclass-create"></a>

#### <code>robustclass.Create( [string] classname, ... )</code>
* **Description**</br>
	&emsp; Creates a new specific object.

* **Arguments**
	* <code>**[string]**</code> **classname**</br>
		&emsp; The name of the needed class.

	* <code>**[vararg]**</code> **args**</br>
		&emsp; The arguments to be passed to the object's <code>**[__new-metamethod](#class-field-new)**</code> and <code>**[constructor](#class-field-constructor)**</code>.

* **Returns**
	* `any`
		1. `false`
			* if the class doesn't exist
			* if the object's <code>**[__new-metamethod](#class-field-new)**</code> **#1 return** is `false`

		2. the object or its substitute on success

<details> <summary>Aliases</summary>

* `robustclass.CreateObject()`
* `robustclass.New()`
* `robustclass.NewObject()`
</details>

---
</br>

<a name="robustclass-delete"></a>

#### <code>robustclass.Delete( [table] pObj )</code></br><code>robustclass.Delete( [userdata] pObj )</code>
* **Description**</br>
	&emsp; Deletes the given object.

* **Arguments**
	* <code>**[table] or [userdata]**</code> **pObj**</br>
		&emsp; The object to be removed.

* **Returns**
	* <code>**[boolean]**</code>
		1. `false` if
			* not an object
			* couldn't retrieve the object's class
			* the object's <code>**[__delete-metamethod](#class-field-delete)**</code> returned `false`

		2. `true` on success

<details> <summary>Aliases</summary>

* `robustclass.DeleteObject()`
* `robustclass.Destroy()`
* `robustclass.DestroyObject()`
* `robustclass.Remove()`
* `robustclass.RemoveObject()`
</details>

</br>

## Classes

### `CLASS`
* ****Description****</br>
	&emsp; The particular class itself that will be used as the metatable for the objects of that particular class.</br>
	</br>
	&emsp; The class name is stored in the global table as an alias-function for **[robustclass.Create](#robustclass-create)**.</br>
	</br>
	&emsp; The class itself, by the way, has its own metatable too for convenience and performance purposes.</br>
	&emsp; &emsp; `__call` — Serves as an alias for **[robustclass.Create](#robustclass-create)**.</br>
	&emsp; &emsp; `__index` — Subsequent access to the inherited base class(-es).</br>
	&emsp; Every previous inherited base class will be linked to the subsequent inherited base class through <code>**[__index-metafield](https://www.lua.org/pil/13.4.1.html)**</code>. See the [Source:Line 166–171](/robustclass.lua#L166-171)

* ****Members****
	* <code>**[string]**</code> **ClassName**</br>
		&emsp; The name of the class.

	* <code>**[table]**</code> **BaseClass**</br>
		&emsp; The inherited base class.</br>
		&emsp; **Default:** `nil`

	* <code>**[function]**</code> **__tostring**</br>
		&emsp; Formats the info about the object.</br>
		&emsp; **Default:** <code>**[Common __tostring-metamethod](/robustclass.lua#L62-L82)**</code>

	* <code>**[table] or [function]**</code> **__index**</br>
		&emsp; Value accessor.</br>
		&emsp; **Default:** <code>**CLASS**</code>

* **Custom Fields**

	<a name="class-field-constructor"></a>
	* <code>**[function]**</code> **Constructor**</br>
		&emsp; The function for building the object.</br>
		&emsp; (!) The name must match the class name.</br>
		</br>
		&emsp; Function Argument(-s):</br>
		&emsp; &emsp; 1. <code>**[table] or [userdata]**</code> **self** — the object itself.</br>
		&emsp; &emsp; 2. <code>**[vararg]**</code> **args** — additional arguments passed to the used `creator-function`.</br>

	* <code>**[function]**</code> **Destructor**</br>
		&emsp; The function for destroying the object.</br>
		&emsp; (!) The name must be prefixed with `_`.</br>
		</br>
		&emsp; Function Argument(-s):</br>
		&emsp; &emsp; 1. <code>**[table] or [userdata]**</code> **self** — the object itself.</br>

	<a name="class-field-new"></a>
	* <code>**[function]**</code> **__new**</br>
		&emsp; The function that is called after the object's metatable is set and before the object is constructed.</br>
		&emsp; Use it for adjusting/overriding the default creation action.</br>
		</br>
		&emsp; Function Argument(-s):</br>
		&emsp; &emsp; 1. <code>**[table] or [userdata]**</code> **self** — the object itself.</br>
		&emsp; &emsp; 2. <code>**[vararg]**</code> **args** — additional arguments passed to the used `creator-function`.</br>
		</br>
		&emsp; Function Return(-s):</br>
		&emsp; &emsp; 1. <code>**[boolean]**</code> **bContinue** — continues or prevents the creation.</br>
		&emsp; &emsp; 2. <code>**[table] or [userdata]**</code> **pObjSubstitute** — something to replace the initial object with.</br>
		&emsp; &emsp; 3. <code>**[boolean]**</code> **bConstruct** — continues or prevents the construction of the object.

	<a name="class-field-delete"></a>
	* <code>**[function]**</code> **__delete**</br>
		&emsp; The function that is called before the object gets destructed and deleted.</br>
		&emsp; Use it for adjusting/overriding the default deletion action.</br>
		</br>
		&emsp; Function Argument(-s):</br>
		&emsp; &emsp; 1. <code>**[table] or [userdata]**</code> **self** — the object itself.</br>
		</br>
		&emsp; Function Return(-s):</br>
		&emsp; &emsp; 1. <code>**[boolean]**</code> **bContinue** — continues or prevents the deletion.</br>


[function]: https://wiki.facepunch.com/gmod/function
[table]: https://wiki.facepunch.com/gmod/table
[userdata]: https://wiki.facepunch.com/gmod/userdata
[boolean]: https://wiki.facepunch.com/gmod/boolean
[string]: https://wiki.facepunch.com/gmod/string
[vararg]: https://wiki.facepunch.com/gmod/vararg
