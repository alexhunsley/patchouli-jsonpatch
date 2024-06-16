# Patchouli JSON Patcher
is a JSONPatch library for Swift featuring an ergonomic DSL. 

Example:

(TODO loading json file/bundle mid-patch, as a child?)

```
    import PatchouliJSON

    // Use the DSL to construct a patch on a file's JSON content.
    // This step doesn't do the actual patching!

    let patchedJSONContent: PatchedJSON = Content(fileURL: someJSONFileURL) {
        Add(address: "/users/-", jsonContent: "alex")

        Remove(address: "/temp/log")

        Replace(address: "/user_type", jsonContent: "admin")

        Move(fromAddress: "/v1/last_login", toAddress: "/v2/last_login")

        Copy(fromAddress: "/v1/login_count", toAddress: "/v2/login_count")

        Test(address: "/magic_string", jsonContent: "0xdeadbeef")
    }

    // This is where the patching happens
    let resultJSONContent: JSONContent = try content.reduced()

    // Get the result in various forms
    let jsonData = try dataResult.data()
    let jsonString = try dataResult.string() // defaults to UTF8
    let jsonStringUTF16 = try dataResult.string(encoding: utf16)
```

You can also fetch JSON content from bundles:

```
    // loads User.json from the main bundle
    let patchedJSONContent: PatchedJSON = Content(resource: "User", bundle: Bundle.main) {
        Add(address: "/users/-", jsonContent: "alex")
        ...
```

And you can use string literals for your source json:

```
    let patchedJSONContent: PatchedJSON = Content(string:
        """
        { "greet": "Hello", "bye": "auf wiedersehen", "users": [] }
        """
    ) {
        Add(address: "/users/-", jsonContent: "alex")
        ...
```

# Re-using patches

If you want to use the same patch multiple times on different JSON sources, you can separate it
from the content it is applied to:

```
    JSONPatchContent
```

# DSL features: If, If-else, for, for-in 

The DSL can handle these constructs:

```
    let patchedJSONContent: PatchedJSON = Content(fileURL: someJSONFileURL) {
        for index in 0...5 {
            if someCheck(index) {
                Add(address: "/abc", jsonContent: "\(index)")
            } else {
                Remove(address: "/cde")
            } 
            patches[index]
        }

        Add(address: "/users/-", jsonContent: "alex")

        Remove(address: "/temp/log")

        Replace(address: "/user_type", jsonContent: "admin")

        Move(fromAddress: "/v1/last_login", toAddress: "/v2/last_login")

        Copy(fromAddress: "/v1/login_count", toAddress: "/v2/login_count")

        Test(address: "/magic_string", jsonContent: "0xdeadbeef")
    }

```

# Nested patches

The DSL can handle nesting, which means you can have patches-within-patches:

```
    let patchedJSONContent: PatchedJSON = Content(fileURL: someJSONFileURL) {

        Add(address: "/some_key", content: Content(fileURL: someJSONFileURLInner) {
            Replace(address: "hello", jsonContent: "friend")
        })
        
        Remove(address: "/remove_me")
    }
```

Note that with nested patching, the deepest operations are resolved first: in the above, the `Replace` at is patched onto the contents of `someJSONFileURLInner`. The result of that is then added at `/some_key` in the content from `someJSONFileURL`. 

Finally, the `Remove` is peformed.

# Separating the patch from the source data

# Note: Independence from JSONPatch library

There is code in PathcouliJSON that does similar things to code in the JSONPatch library it uses.
We're deliberately not just re-using code from JSONPatch library (at present) as that would tie us to JSONPatch more than I'd like; changes to that lib might break PatchouliJSON.

#

# From the ground up

Here's the simplest possible use of Patchouli JSON:

```
  // empty JSON object with no patches applied
  let emptyObject = JSONObject()   // note: there's also a JSONArray()
  let jsonData: Data = try emptyObject.reduced()

  // helper for getting a UTF8 string from the data
  print(try dataResult.asString())
```

The call to `reduced()` is the point at which we actually perform the JSON patching.




# Patchouli cookbook

Here are some examples of using Patchouli, starting from the very simple:




# Old leading stuff to put later

The patching engine is *generic* so it can be used to patch other kinds of data.
 
It was inspired by a practical question: "How can I ergonomically create lots of similar JSON payloads for testing without lots of tedious repetition?". And then a follow-on question: "Can I represent patching *anything* in a generic way?".

Here's a toy example, for simplicity, of using the DSL to patch a String using the built-in string replacement patcher:

```
// Input: "Hello World"
// Patched result: "Goodbye my friend"

let stringPatchContent: StringPatchContent = Content("Hello World") {
    Patch(address: "Hello", with: "Goodbye")
    Patch(address: "World", with: "my friend")
}

let result: String = try stringPatchContent.reduce()
```

Patchouli's DSL is generic and is designed to be able to patch anything, hence the use of `address:`. An address is some data that can point to one (or more) locations inside some content. In the context of the string patcher, an address is a string to match.

Patchouli is written with Swift's ResultBuilder, so it handles recursion just fine:

```
// Result: "Ciao cat"

let result: String = Content("Hello World") {
    Patch(address: "Hello", with: "Ciao")
    Patch(address: "World", with: "dog") {
        Patch(address: "dog", with: "cat")
    }
}
.reduce(Patchouli.stringMatchPatchable)
```

(Recursive patching like this with strings might seem daft, but imagine this was dealing with JSON read from a file.)



# How Patchouli works

It has two major parts: a DSL that feels similar to SwiftUI, for constructing the patch, and a tree reducer which then performs the patching using appropriate functions.

The representation of patchable data and the DSL are both generic, which means that you can write a patch spec for *anything* out of the box, without writing any extra code:

```
let patchSpec = Content(["Alex", "Hunsley"]) {
    Patch(address: 4, with: ["Cheese"])
}
```

This compiles just fine. It makes a patch spec for content of type `[String]` with addresses that are `Int`.

But that's as far as it goes. If you want to actually 'collapse' the patch spec into a result, you've got to decide what patching actually means in this context, and write a reducer for it.



Will be written using protocol witness, just for the goodness.

WIP, baby.

# Example

The simplest possible patcher is a string patcher: it just does search and replace on strings.

The DSL looks like this:

```
let rootContent = “alex hunsley is here”

Patch(rootContent) {
    Replace(“lex”, “xle”)
    Replace(“hunsley”, “goober”)
    Replace(“here”) {
        Patch(“somewhere”) {
            Replace(“some”, “any”)
        }
    }
}
```

The result:

```
“axle goober is anywhere”
```

# Supported actions

* replace
* insert
* delete

Other actions may be appropriate in some contexts, eg `append` if dealing with JSON.

# Sketch of the notocol

```
struct Patchable<A, Address> {
    // first A patched with second A at Address.
    // could maybe do patch() with inout,
    // but for now, KISS
    let replaced: (A, A, Address) -> A
    // insert A at Address
    let inserted: (A, Address) -> A
    // delete at Address
    let deleted: (Address) -> A   
}
```

in case you're wondering: a notocol is the beast that sits in between a protocol and witness to it: it's a generic struct.
