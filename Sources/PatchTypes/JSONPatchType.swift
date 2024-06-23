import Foundation
import PatchouliCore
import JSONPatch
//import PatchouliDemoAppResources

// MARK: - DSL primitive that supports JSON Patch (RFC6902)
//
// We do no validation of what is passed to JSONPatch; we just relay what we are given.
// Any errors from JSONPatch are bubbled back through the reduce.
//
// https://datatracker.ietf.org/doc/html/rfc6902

/// An explicit type for JSON null. Trying to use 'nil' for this would be a bad
/// idea because our ResultBuilders use nil internally when simplifying.
public let null: Any? = nil

public typealias PatchedJSON = PatchedContent<JSONPatchType>
// beware, JSONPatch has a JSONPatch, obviously! Is this clear enough?
public typealias JSONPatchItem = AddressedPatch<JSONPatchType>

public typealias JSONPatchList = [JSONPatchItem]

public typealias JSONPatchListBuilder = AddressedPatchItemsBuilder<JSONPatchType>

public struct JSONPatchType: PatchType {
    public typealias ContentType = JSONContent
    // just make one-step for now
    public typealias EncodedContentType = JSONContent
    public typealias AddressType = String

    /// The Protocol Witness used by the reducer
    static public var patcher = Patchable<JSONPatchType>(
        added: { (container: ContentType?, addition: ContentType, address: String) throws -> EncodedContentType in
            guard let container else { throw("No container in JSONPatchType! 1") }
            let additionStr = try addition.string()
            let madeJSONPatchData = Data("""
                                     [{"op": "add", "path": "\(address)", "value": \(additionStr)}]
                                     """.utf8)

            let patch = try! JSONPatch(data: madeJSONPatchData)
            return try! .literal(patch.apply(to: container.data()))
        },
        removed: { (container: ContentType?, address: String) -> EncodedContentType in
            guard let container else { throw("No container in JSONPatchType! 2") }
            let madeJSONPatchData = Data("""
                                     [{"op": "remove", "path": "\(address)"}]
                                     """.utf8)
            let patch = try! JSONPatch(data: madeJSONPatchData)
            return try! .literal(patch.apply(to: container.data()))
        },
        replaced: { (container: ContentType?, replacement: ContentType, address: String) throws -> EncodedContentType in
            guard let container else { throw("No container in JSONPatchType! 3") }

            let replacementStr = try replacement.string()

            let madeJSONPatchData = Data("""
                                     [{"op": "replace", "path": "\(address)", "value": \(replacementStr)}]
                                     """.utf8)
            let patch = try! JSONPatch(data: madeJSONPatchData)
            return try! .literal(patch.apply(to: container.data()))
        },
        copied: { (container: ContentType?, fromAddress: String, toAddress: String) throws in
            guard let container else { throw("No container in JSONPatchType! 4") }

            let madeJSONPatchData = Data("""
                                     [{"op": "copy", "from": "\(fromAddress)", "path": "\(toAddress)"}]
                                     """.utf8)
            let patch = try! JSONPatch(data: madeJSONPatchData)
            return try! .literal(patch.apply(to: container.data()))
        },
        moved: { (container: ContentType?, fromAddress: String, toAddress: String) throws in
            guard let container else { throw("No container in JSONPatchType! 5") }

            let madeJSONPatchData = Data("""
                                     [{"op": "move", "from": "\(fromAddress)", "path": "\(toAddress)"}]
                                     """.utf8)
            let patch = try! JSONPatch(data: madeJSONPatchData)
            return try! .literal(patch.apply(to: container.data()))
        },
        test: { (container: ContentType?, value: ContentType, address: String) throws in
            guard let container else { throw("No container in JSONPatchType! 6") }

            let valueData = try value.data()
            let valueStr = valueData.string()

            let madeJSONPatchData = Data("""
                                     [{"op": "test", "path": "\(address)", "value": \(valueStr)}]
                                     """.utf8)

            let patch = try! JSONPatch(data: madeJSONPatchData)
            do {
                return try .literal(patch.apply(to: container.data()))
            }
            catch let error {
                throw PatchouliError<JSONPatchType>.testFailed(container, address, value)
            }
        }
    )

    static public var emptyObjectContent: JSONContent = .literal("{}".utf8Data)
    static public var emptyArrayContent: JSONContent = .literal("[]".utf8Data)

    public static var emptyContent: JSONContent = emptyObjectContent
}


//public struct JSONTwoStagePatchType: PatchType {
//    public typealias ContentType = JSONContent
//    // just make one-step for now
//    public typealias EncodedContentType = Data
//    public typealias AddressType = String
//
//    /// The Protocol Witness used by the reducer
//    public static var patcher = PatchouliCore.Patchable<JSONTwoStagePatchType>(
////        added: JSONPatchType.patcher.added
//        added: { (container: ContentType?, addition: ContentType, address: String) throws -> EncodedContentType in
//            guard let container else { throw("No container in JSONPatchType! 1") }
//            let additionStr = try addition.string()
//            let madeJSONPatchData = Data("""
//                                     [{"op": "add", "path": "\(address)", "value": \(additionStr)}]
//                                     """.utf8)
//            return madeJSONPatchData
//        }
////        removed: JSONPatchType.patcher.removed,
////        replaced: JSONPatchType.patcher.replaced,
////        copied: JSONPatchType.patcher.copied,
////        moved: JSONPatchType.patcher.moved,
////        test: JSONPatchType.patcher.test
//    )
//
////    Patchable<JSONPatchType>(
////        added: { (container: ContentType?, addition: ContentType, address: String) throws -> EncodedContentType in
////            guard let container else { throw("No container in JSONPatchType! 1") }
////            let additionStr = try addition.string()
////            let madeJSONPatchData = Data("""
////                                     [{"op": "add", "path": "\(address)", "value": \(additionStr)}]
////                                     """.utf8)
////
////            let patch = try! JSONPatch(data: madeJSONPatchData)
////            return try! .literal(patch.apply(to: container.data()))
////        },
////        removed: { (container: ContentType?, address: String) -> EncodedContentType in
////            guard let container else { throw("No container in JSONPatchType! 2") }
////            let madeJSONPatchData = Data("""
////                                     [{"op": "remove", "path": "\(address)"}]
////                                     """.utf8)
////            let patch = try! JSONPatch(data: madeJSONPatchData)
////            return try! .literal(patch.apply(to: container.data()))
////        },
////        replaced: { (container: ContentType?, replacement: ContentType, address: String) throws -> EncodedContentType in
////            guard let container else { throw("No container in JSONPatchType! 3") }
////
////            let replacementStr = try replacement.string()
////
////            let madeJSONPatchData = Data("""
////                                     [{"op": "replace", "path": "\(address)", "value": \(replacementStr)}]
////                                     """.utf8)
////            let patch = try! JSONPatch(data: madeJSONPatchData)
////            return try! .literal(patch.apply(to: container.data()))
////        },
////        copied: { (container: ContentType?, fromAddress: String, toAddress: String) throws in
////            guard let container else { throw("No container in JSONPatchType! 4") }
////
////            let madeJSONPatchData = Data("""
////                                     [{"op": "copy", "from": "\(fromAddress)", "path": "\(toAddress)"}]
////                                     """.utf8)
////            let patch = try! JSONPatch(data: madeJSONPatchData)
////            return try! .literal(patch.apply(to: container.data()))
////        },
////        moved: { (container: ContentType?, fromAddress: String, toAddress: String) throws in
////            guard let container else { throw("No container in JSONPatchType! 5") }
////
////            let madeJSONPatchData = Data("""
////                                     [{"op": "move", "from": "\(fromAddress)", "path": "\(toAddress)"}]
////                                     """.utf8)
////            let patch = try! JSONPatch(data: madeJSONPatchData)
////            return try! .literal(patch.apply(to: container.data()))
////        },
////        test: { (container: ContentType?, value: ContentType, address: String) throws in
////            guard let container else { throw("No container in JSONPatchType! 6") }
////
////            let valueData = try value.data()
////            let valueStr = valueData.string()
////
////            let madeJSONPatchData = Data("""
////                                     [{"op": "test", "path": "\(address)", "value": \(valueStr)}]
////                                     """.utf8)
////
////            let patch = try! JSONPatch(data: madeJSONPatchData)
////            do {
////                return try .literal(patch.apply(to: container.data()))
////            }
////            catch let error {
////                throw PatchouliError<JSONPatchType>.testFailed(container, address, value)
////            }
////        }
////    )
//
//    static public var emptyObjectContent: JSONContent = .literal("{}".utf8Data)
//    static public var emptyArrayContent: JSONContent = .literal("[]".utf8Data)
//
//    public static var emptyContent: JSONContent = emptyObjectContent
//}

public enum JSONContent {
    case literal(Data)
    case fileURL(URL)
    case bundleResource(Bundle, String)

    public func data() throws -> Data {
        switch self {
        case let .literal(data):
            return data
        case let .bundleResource(bundle, bundleResourceName):
            // maybe do caching later? if feeling excessive. prolly OTT though
            guard let fileURL = bundle.url(forResource: bundleResourceName, withExtension: "json") else {
                assertionFailure("Didn't find the json resource")
                return Data()
            }
            return try Data(contentsOf: fileURL)
        case let .fileURL(fileURL):
            return try Data(contentsOf: fileURL)
        }
    }

    public func string(encoding: String.Encoding = .utf8) throws -> String {
        let data = try self.data()
        return String(data: data, encoding: encoding) ?? "Decoding failed" // TODO throw error on nil?
    }
}

//-------------------------------------------------

public struct JSONPatchTwoStageType: PatchType {
    public typealias ContentType = JSONContent
    // just make one-step for now
    public typealias EncodedContentType = Data
    public typealias AddressType = String

    /// The Protocol Witness used by the reducer
    static public var patcher = Patchable<JSONPatchTwoStageType>(
        added: { (container: ContentType?, addition: ContentType, address: String) throws -> EncodedContentType in
            let additionStr = try addition.string()
            // NB have removed the '[ ]' from around these Datas! Not needed here for two-stage (we call JSONPatch one-shot)
            let madeJSONPatchData = Data("""
                                     {"op": "add", "path": "\(address)", "value": \(additionStr)}
                                     """.utf8)
            return madeJSONPatchData
        },
        removed: { (container: ContentType?, address: String) -> EncodedContentType in
            let madeJSONPatchData = Data("""
                                     {"op": "remove", "path": "\(address)"}
                                     """.utf8)
            return madeJSONPatchData
        },
        replaced: { (container: ContentType?, replacement: ContentType, address: String) throws -> EncodedContentType in
            let replacementStr = try replacement.string()

            let madeJSONPatchData = Data("""
                                     {"op": "replace", "path": "\(address)", "value": \(replacementStr)}
                                     """.utf8)
            return madeJSONPatchData
        },
        copied: { (container: ContentType?, fromAddress: String, toAddress: String) throws in
            let madeJSONPatchData = Data("""
                                     {"op": "copy", "from": "\(fromAddress)", "path": "\(toAddress)"}
                                     """.utf8)
            return madeJSONPatchData
        },
        moved: { (container: ContentType?, fromAddress: String, toAddress: String) throws in
            let madeJSONPatchData = Data("""
                                     {"op": "move", "from": "\(fromAddress)", "path": "\(toAddress)"}
                                     """.utf8)
            return madeJSONPatchData
        },
        test: { (container: ContentType?, value: ContentType, address: String) throws in
            let valueData = try value.data()
            let valueStr = valueData.string()
            let madeJSONPatchData = Data("""
                                     {"op": "test", "path": "\(address)", "value": \(valueStr)}
                                     """.utf8)
            return madeJSONPatchData
        },
        listCombiner: { (content: ContentType, encodedContentTypeList: [EncodedContentType]) throws -> ContentType in
            // don't pointlessly invoke JSONPatch if the list is empty
            if encodedContentTypeList.isEmpty {
                return content
            }

            let combinedData = try combineDataArray(encodedContentTypeList)
            print("Patch json: \(combinedData.string())")
            let patch = try! JSONPatch(data: combinedData)
            return try! .literal(patch.apply(to: content.data()))
        }
    )

    static public var emptyObjectContent: JSONContent = .literal("{}".utf8Data)
    static public var emptyArrayContent: JSONContent = .literal("[]".utf8Data)

    public static var emptyContent: JSONContent = emptyObjectContent
}

func combineDataArray(_ dataArray: [Data]) throws -> Data {
    // Convert each Data to a String
    let stringArray = dataArray.compactMap { String(data: $0, encoding: .utf8) }

    // Join the strings with ","
    let combinedString = "[" + stringArray.joined(separator: ",") + "]"

    // Convert the combined string back to Data
    guard let combinedStringData = combinedString.data(using: .utf8) else {
        throw "Couldn't make string in combineDataArray()"
    }
    return combinedStringData
}
