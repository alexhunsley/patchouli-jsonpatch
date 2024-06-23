# Patchouli JSON Patcher

[![Apache 2 License](https://img.shields.io/badge/license-Apache%202-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Swift compatability](https://img.shields.io/badge/Swift%20compatability-5-red.svg)](http://developer.apple.com)
[![Supported Platforms](https://img.shields.io/badge/platform-macos%20%7C%20ios%20%7C%20tvos%20%7C%20watchos-lightgreen.svg)](http://developer.apple.com)
[![Build System](https://img.shields.io/badge/dependency%20management-spm-yellow.svg)](https://swift.org/package-manager/)

This is a [JSON Patch](https://jsonpatch.com) library for Swift featuring an ergonomic DSL. It is built with the [Patchouli Core](https://github.com/alexhunsley/patchouli-core) engine and uses [JSONPatch](https://github.com/raymccrae/swift-jsonpatch) lib for the patch execution.

## Installation

To install via SPM, add a dependency for `https://github.com/alexhunsley/patchouli-jsonpatch`.

## Usage

```swift
    import PatchouliJSON

    // Use the DSL to construct a patch on a file's JSON content.
    // This step doesn't do the actual patching!

    let patchedJSONContent: PatchedJSON = Content(fileURL: someJSONFileURL) {

        Add(address: "/users/-", jsonContent: "alex")

        Add(address: "/users/-", jsonContent: [1, "hi", 5.0])

        // note: please use `null` (and never `nil`) to represent JSON's `null`
        Add(address: "/users/-", jsonContent: null)

        Remove(address: "/temp/log")

        Replace(address: "/user_type", jsonContent: "admin")

        Move(fromAddress: "/v1/last_login", toAddress: "/v2/last_login")

        Copy(fromAddress: "/v1/login_count", toAddress: "/v2/login_count")

        Test(address: "/magic_string", jsonContent: "0xdeadbeef")
    }

    // execute the patch
    let resultJSONContent: JSONContent = try content.reduced()

    // Get the result in various forms
    let jsonData = try dataResult.data()
    let jsonString = try dataResult.string() // defaults to UTF8
    let jsonStringUTF16 = try dataResult.string(encoding: utf16)
```

You can also fetch JSON content from bundles:

```swift
    // loads User.json from the main bundle
    let patchedJSONContent: PatchedJSON = Content(resource: "User", bundle: Bundle.main) {
        Add(address: "/users/-", jsonContent: "alex")
        ...
```

And you can use string literals for your source json (utf8 is assumed):

```swift
    let patchedJSONContent: PatchedJSON = Content(string:
        """
        { "greet": "Hello", "bye": "auf wiedersehen", "users": [] }
        """
    ) {
        Add(address: "/users/-", jsonContent: "alex")
        ...
```

You can also use an empty JSON object or array as your starting point:

```swift
        let patchedEmptyObject = EmptyJSONObject {
            Add(address: "/asdf", jsonContent: "Hello")
        }

        let patchedEmptyArray1 = EmptyJSONArray {
            Add(address: "/-", jsonContent: "xyz")
            Add(address: "/-", jsonContent: "abc")
        }
```

You can use `@JSONPatchListBuilder` in the same way as SwiftUI's `@ViewBuilder` to break up your patch declarations:

```swift
    @JSONPatchListBuilder
    func builderFunc(name: String) -> JSONPatchList {
        Add(address: "/asdf", jsonContent: "Hello \(name)")
        Add(address: "/qwer", jsonContent: "Bye \(name)")
    }

    @JSONPatchListBuilder
    var builderVar: JSONPatchList {
        Add(address: "/addr1", jsonContent: "Hello")
        Add(address: "/addr2", jsonContent: "Bye")
        builderFunc(name: "boo")
    }

    func useBuilderHelpers() throws {
        let patchedJSONContent = Content(JSONPatchType.emptyObjectContent) {
            builderFunc(name: "fred")
            builderVar
        }
```

This is particularly useful if you want to declare a patch list just once for use on multiple different bits of JSON.

## DSL features

The DSL can handle `if`, `if-else`, `for`, `for-in`, and optionals. For example:

```swift
    let patchedJSONContent: PatchedJSON = Content(fileURL: someJSONFileURL) {
        for index in 0...5 {
            if someCheck(index) {
                Add(address: "/abc", jsonContent: "\(index)")
            }

            if someCondition {
                Add(address: "/cde", jsonContent: "\(index)")
            } else {
                Remove(address: "/cde")
            } 
        }

        for user in users {
            Add(address: "/usernames/-", jsonContent: "\(user.username)")
        }
    }

```

## Nested patches

The DSL can handle nesting, which means you can have patches-within-patches:

```swift
    let patchedJSONContent: PatchedJSON = Content(fileURL: jsonFile1URL) {

        Add(address: "/some_key", content: Content(fileURL: jsonFile2URL) {
            Replace(address: "hello", jsonContent: "friend")
        })
        
        Remove(address: "/remove_me")
    }
```

Note that with nested patching, the deepest operations are resolved first: in the above, the `Replace` patch is applied to the contents of JSON file 2. The result of that is then added at `/some_key` in the content from JSON file 1. And finally the `Remove` is peformed on what we have.

# Built on top of Patchouli, a generic patching engine

Patchouli JSON is built on top of [Patchouli Core](https://github.com/alexhunsley/patchouli-core), a generic patching engine. You can use Pathcouli Core to make patchers for other kinds of data.

# Project Keywords

```
resultbuilder, protocol witness, generics, json, jsonpatch
```
