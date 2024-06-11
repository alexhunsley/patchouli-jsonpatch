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

//public func Content<T: PatchType>(_ content: T.ContentType,
//                                  @AddressedPatchItemsBuilder<T> patchedBy patchItems: PatchListProducer<T> = { AddressedPatch.emptyPatchList })
//        -> PatchedContent<T> {
//
//    PatchedContent(content: content, contentPatches: patchItems())
//}

// makeContent?
//public func Content<T: PatchType>(_ content: T.ContentType,
//                                  patchList: [AddressedPatch<T>])
//        -> PatchedContent<T> {
//
//    PatchedContent(content: content, contentPatches: patchList)
//}

// We want to do loading sensibly? Don't load same thing twice, cache it somehow.
// So user can just use the two above without worrying about efficiency? hmm a bit magical...
// but we don't want to load data from a file if it's not even used!
// but if user declares that content ahead of time, and uses it in multiple places, it won't
// load until actually called (and can cache).
// Need to warn user if there's a gotcha like this.

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
            let items = array.map { buildBlock($0).asString() }
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
