# Patchouli JSON Patcher
is a JSON Patcher library for Swift featuring an ergonomic DSL (similar to writing SwiftUI code). The patching engine is *generic* so it can be used to patch other kinds of data.

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
// Result: "Goodbye my enemy"

let result: String = Content("Hello World") {
    Patch(address: "Hello", with: "Goodbye")
    Patch(address: "World", with: "my friend") {
        Patch(address: "friend", with: "enemy")
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

We expect this result:

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
