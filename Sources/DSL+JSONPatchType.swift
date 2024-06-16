//
//  File.swift
//  
//
//  Created by Alex Hunsley on 11/05/2024.
//

import Foundation
import PatchouliCore

// TODO nicer way to do this?
@JSONSimpleContentBuilder func applyBuilder(_ jsonContentClosure: () -> Any?) -> Data {
    jsonContentClosure()
}

public func JSONObject(@AddressedPatchItemsBuilder<JSONPatchType> patchedBy patchItems: PatchListProducer<JSONPatchType> = { AddressedPatch.emptyPatchList }) -> PatchedJSON {
    Content(JSONPatchType.emptyObjectContent, patchedBy: patchItems)
}

public func JSONArray(@AddressedPatchItemsBuilder<JSONPatchType> patchedBy patchItems: PatchListProducer<JSONPatchType> = { AddressedPatch.emptyPatchList }) -> PatchedJSON {
    Content(JSONPatchType.emptyArrayContent, patchedBy: patchItems)
}

// convenience for resource loading from bundle
public func Content(resource resourceID: String,
                    bundle: Bundle,
                    @AddressedPatchItemsBuilder<JSONPatchType> patchedBy patchItems: PatchListProducer<JSONPatchType> = { AddressedPatch.emptyPatchList })
        -> PatchedContent<JSONPatchType> {

     PatchedContent(content: JSONContent.bundleResource(bundle, resourceID),
                   contentPatches: patchItems())
}

// convenience for loading from file
public func Content(fileURL: URL,
                    @AddressedPatchItemsBuilder<JSONPatchType> patchedBy patchItems: PatchListProducer<JSONPatchType> = { AddressedPatch.emptyPatchList })
        -> PatchedContent<JSONPatchType> {

    PatchedContent(content: JSONContent.fileURL(fileURL),
                   contentPatches: patchItems())
}

// TODO a Content like above but for jsonContent: type param as used in patches?
// -- TODO does this make any sense? I'm not sure it does!
public func Content(jsonContent jsonContentClosure: @autoclosure @escaping () -> Any?,
                    @AddressedPatchItemsBuilder<JSONPatchType> patchedBy patchItems: PatchListProducer<JSONPatchType> = { AddressedPatch.emptyPatchList })
        -> PatchedContent<JSONPatchType> {

    let retValueData = applyBuilder(jsonContentClosure)

    return PatchedContent(content: .literal(retValueData),
                          contentPatches: patchItems())
}

public func Content(string: String,
                    @AddressedPatchItemsBuilder<JSONPatchType> patchedBy patchItems: PatchListProducer<JSONPatchType> = { AddressedPatch.emptyPatchList })
        -> PatchedContent<JSONPatchType> {

            PatchedContent(content: .literal(string.utf8Data),
                   contentPatches: patchItems())
}

public func Add(address: String,
                jsonContent jsonContentClosure: @autoclosure @escaping () -> Any?,
                @AddressedPatchItemsBuilder<JSONPatchType> patchedBy patchItems: PatchListProducer<JSONPatchType> = { AddressedPatch.emptyPatchList })
            -> JSONPatchItem {

    let retValueData = applyBuilder(jsonContentClosure)

    return Add(address: address,
               content: PatchedJSON(content: .literal(retValueData),
                                    contentPatches: patchItems()))
}

public func Replace(address: String,
                jsonContent jsonContentClosure: @autoclosure @escaping () -> Any?,
                @AddressedPatchItemsBuilder<JSONPatchType> patchedBy patchItems: PatchListProducer<JSONPatchType> = { AddressedPatch.emptyPatchList })
            -> JSONPatchItem {

    let retValueData = applyBuilder(jsonContentClosure)

    return Replace(address: address,
                   withContent: PatchedJSON(content: .literal(retValueData),
                                            contentPatches: patchItems()))
}

public func Test(address: String,
                 jsonContent jsonContentClosure: @autoclosure @escaping () -> Any?,
                 @AddressedPatchItemsBuilder<JSONPatchType> patchedBy patchItems: PatchListProducer<JSONPatchType> = { AddressedPatch.emptyPatchList })
        -> JSONPatchItem {

    let retValueData = applyBuilder(jsonContentClosure)

    return Test(address: address, expectedSimpleContent: .literal(retValueData))
}

// TODO Can we use the expression builder to remove need for alt versions of methods?
//  -- could do, but not a fan of idea, makes compile time checks looser.

@resultBuilder
public struct JSONSimpleContentBuilder {
    // empty block to empty list
    public static func buildBlock() -> Data {
        Data("".utf8)
    }

    // TODO maybe use stuff in JSONPatch here? more data types?
    public static func buildBlock(item: Any?) -> Data {
        if let item {
            return buildBlock(item)
        }
        return Data("null".utf8)
    }

    // this func *can* get called with a nil parameter!
    public static func buildBlock(_ item: Any?) -> Data {

        // TODO tests still pass with this commented out.
        // Was I just allowing JSONContent as an expression?
//        if let contentIdea = item as? JSONContent {
//            switch contentIdea {
//            case let .literal(data):
//                return data
//            default:
//                assertionFailure("Impl me 4")
//                return Data()
//            }
//        }

        // TODO ensure we're doing everything just like JSONPatch does with similar `Any`
        if let str = item as? String {
            let enquotedString = "\"" + str + "\""
            return Data(enquotedString.utf8)
        }

        if let integer = item as? any Numeric {
            return Data("\(integer)".utf8)
        }

        if let boolean = item as? Bool {
            return Data("\(boolean)".utf8)
        }

        if let array = item as? any Sequence {
            let items = array.map { buildBlock($0).string() }
            let seqAsStr = "[" + items.joined(separator: ",") + "]"
            return seqAsStr.utf8Data
        }

        if item == nil {
            return Data("null".utf8)
        }

        // TODO throw error on unrecognized json content?
        return buildBlock()
    }

    public static func buildBlock(_ items: [Any]) -> [Any] {
        items
    }
    
    public static func buildBlock(_ integer: Int) -> Data {
        Data("\(integer)".utf8)
    }
}
//
