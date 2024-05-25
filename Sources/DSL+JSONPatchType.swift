//
//  File.swift
//  
//
//  Created by Alex Hunsley on 11/05/2024.
//

import Foundation
import PatchouliCore

// TODO nicer way to do this
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

public func Add(address: String,
                jsonContent jsonContentClosure: @autoclosure @escaping () -> Any?,
//                jsonContent: Any?,
                @AddressedPatchItemsBuilder<JSONPatchType> patchedBy patchItems: PatchListProducer<JSONPatchType> = { AddressedPatch.emptyPatchList })
            -> JSONPatchItem {

//    @JSONSimpleContentBuilder var goob: Data = { jsonContent }()

    let retValueData = applyBuilder(jsonContentClosure)
//    print("jsonCont: \(String(decoding: retValueData, as: UTF8.self))")

    return Add(address: address,
               content: PatchedJSON(content: .literal(retValueData),
                                    contentPatches: patchItems()))

    // alt version thart uses JSONContent.make - means we don't need the autoclosure for caller of this.
                // hmm, problems with double quoting! come back to this idea
//    return Add(address: address,
//               content: PatchedJSON(content: JSONContent.make(jsonContent),
//                                    contentPatches: patchItems()))
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

@resultBuilder
public struct JSONSimpleContentBuilder {
    // If we can use variadics, we're not prone to the "<= 10 items" limitation seen
    // in SwiftUI (due to needing implementation by lots of funcs to match all possible param counts)

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

    public static func buildBlock(_ item: Any?) -> Data {

        // herus
        if let contentIdea = item as? JSONContent {
            switch contentIdea {
            case let .literal(data):
                return data
            default:
                assertionFailure("Impl me 4")
                return Data()
            }
        }

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
            let items = array.map { String(decoding: buildBlock($0), as: UTF8.self) }
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
