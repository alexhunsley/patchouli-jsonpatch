//
//  File.swift
//  
//
//  Created by Alex Hunsley on 11/05/2024.
//

import Foundation
import PatchouliCore

//struct ResultBuilderHelper<T> {
//    let input: () -> String
//
//    @JSONSimpleContentBuilder var jsonCont: Data {
//        input()
//    }
//    // = jsonContentClosure()
//}

// TODO there must be a nicer way to do this!
@JSONSimpleContentBuilder func doIt(_ ss: () -> Any?) -> Data {
    ss()
}

public func JSONObject(@AddressedPatchItemsBuilder<JSONPatchType> patchedBy patchItems: PatchListProducer<JSONPatchType> = { AddressedPatch.emptyPatchList }) -> PatchedJSON {
    Content(JSONPatchType.emptyObjectContent, patchedBy: patchItems)
}

public func JSONArray(@AddressedPatchItemsBuilder<JSONPatchType> patchedBy patchItems: PatchListProducer<JSONPatchType> = { AddressedPatch.emptyPatchList }) -> PatchedJSON {
    Content(JSONPatchType.emptyArrayContent, patchedBy: patchItems)
}

//public func EmptyArray(JSONPatchType.emptyContent) {
//
//}

public func Add(address: String,
//                @JSONSimpleContentBuilder jsonContent: () -> Data,
                jsonContent jsonContentClosure: @autoclosure @escaping () -> Any?, // Data,
//                jsonContent: String, // Data,
                @AddressedPatchItemsBuilder<JSONPatchType> patchedBy patchItems: PatchListProducer<JSONPatchType> = { AddressedPatch.emptyPatchList })
            -> JSONPatchItem {

//    @JSONSimpleContentBuilder var goob: Data = { jsonContent }()

//    let resultBuilderHelper: ResultBuilderHelper<String> = ResultBuilderHelper<String>(jsonCont: jsonContentClosure)

//    let retValue = resultBuilderHelper.jsonCont

//    let retValueData = doIt(jsonContentClosure())

    let retValueData = doIt(jsonContentClosure)

//    let jsonContData = Data(retValue.utf8)

    print("jsonCont: \(String(decoding: retValueData, as: UTF8.self))")

    return Add(address: address,
               content: PatchedJSON(content: retValueData,
                                    contentPatches: patchItems()))
}

// general DSL bit:
//
//public func Add<T: PatchType>(address: T.AddressType,
//                              content: PatchedContent<T>)
//            -> AddressedPatch<T> {
//
//    return AddressedPatch(patchSpec: PatchSpec.add(address),
//                          contentPatch: content)
//}
//
//public func Add<T: PatchType>(address: T.AddressType,
//                              simpleContent: T.ContentType,
//                              @AddressedPatchItemsBuilder<T> patchedBy patchItems: PatchListProducer<T> = { AddressedPatch.emptyPatchList })
//            -> AddressedPatch<T> {
//
//    Add(address: address,
//        content: PatchedContent(content: simpleContent,
//                                contentPatches: patchItems()))
//}

@resultBuilder
public struct JSONSimpleContentBuilder {
    // If we can use variadics, we're not prone to the "<= 10 items" limitation seen
    // in SwiftUI (due to needing implementation by lots of funcs to match all possible param counts!)

    // empty block to empty list
    public static func buildBlock() -> Data {
        Data("".utf8)
    }

    public static func buildBlock(item: Any?) -> Data {
        if let item {
            return buildBlock(item)
        }
        return Data("null".utf8)
    }

    public static func buildBlock(_ item: Any?) -> Data {
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
