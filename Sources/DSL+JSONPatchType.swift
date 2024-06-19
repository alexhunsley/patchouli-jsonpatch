//
//  File.swift
//  
//
//  Created by Alex Hunsley on 11/05/2024.
//

import Foundation
import PatchouliCore

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

public func EmptyJSONObject(@AddressedPatchItemsBuilder<JSONPatchType> patchedBy patchItems: PatchListProducer<JSONPatchType> = { AddressedPatch.emptyPatchList })
        -> PatchedContent<JSONPatchType> {

    PatchedContent(content: JSONPatchType.emptyObjectContent, contentPatches: patchItems())
}

public func EmptyJSONArray(@AddressedPatchItemsBuilder<JSONPatchType> patchedBy patchItems: PatchListProducer<JSONPatchType> = { AddressedPatch.emptyPatchList })
        -> PatchedContent<JSONPatchType> {

    PatchedContent(content: JSONPatchType.emptyArrayContent, contentPatches: patchItems())
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
