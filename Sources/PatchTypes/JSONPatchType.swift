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

extension String {
    public var utf8Data: Data { Data(self.utf8) }
}

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

    public func asString() throws -> String {
        String(decoding: try data(), as: UTF8.self)
    }

    /// Convenience to make a literal from various types
    public static func make(_ value: @autoclosure @escaping () -> Any?) -> JSONContent {
        .literal(applyBuilder(value))
    }

    // helper to get the data from this content.
    // AH it's just the above, dope!
//    func deriveData(dataResult: JSONContent) -> Data {
//        switch dataResult {
//        case let .literal(data):
//            return data
//        case .fileURL(_):
//            // TODO
//            assertionFailure("Impl me2")
//            return Data()
//        case .bundleResource(_, _):
//            // TODO
//            assertionFailure("Impl me3")
//            return Data()
//        }
//    }
}

public struct JSONPatchType: PatchType {
    public typealias ContentType = JSONContent
//    public typealias ContentType = Data
    public typealias AddressType = String

//    public typealias AddedHandler = @Sendable (C, C, A) -> C
//    public typealias RemovedHandler = @Sendable (C, A) -> C
//    public typealias ReplacedHandler = @Sendable (C, C, A) -> C
//    public typealias CopiedHandler = @Sendable (C, A, A) -> C
//    public typealias MovedHandler = @Sendable (C, A, A) -> C
//    public typealias TestHandler = @Sendable (C, A) -> Bool
//
    /// The Protocol Witness used by the reducer
    static public var patcher = Patchable<JSONPatchType>(
        added: { (container: ContentType, addition: ContentType, address: String) throws -> ContentType in
            let additionStr = try addition.asString()
            let madeJSONPatchData = Data("""
                                     [{"op": "add", "path": "\(address)", "value": \(additionStr)}]
                                     """.utf8)
            print(madeJSONPatchData.asString())
            let patch = try! JSONPatch(data: madeJSONPatchData)

            let x = try container.data()
            print("Data = \(x)")

            // so we need to change `to: container` here to use the ContentIdea and get the data from whatever src
            return try! .literal(patch.apply(to: container.data()))
        },
        removed: { (container: ContentType, address: String) -> ContentType in
            let madeJSONPatchData = Data("""
                                     [{"op": "remove", "path": "\(address)"}]
                                     """.utf8)
            let patch = try! JSONPatch(data: madeJSONPatchData)
            return try! .literal(patch.apply(to: container.data()))
        },
        replaced: { (container: ContentType, replacement: ContentType, address: String) throws -> ContentType in
            let replacementStr = try replacement.asString()

            let madeJSONPatchData = Data("""
                                     [{"op": "replace", "path": "\(address)", "value": \(replacementStr)}]
                                     """.utf8)
            let patch = try! JSONPatch(data: madeJSONPatchData)
            return try! .literal(patch.apply(to: container.data()))
        },
        copied: { (container: ContentType, fromAddress: String, toAddress: String) throws in
            let madeJSONPatchData = Data("""
                                     [{"op": "copy", "from": "\(fromAddress)", "path": "\(toAddress)"}]
                                     """.utf8)
            let patch = try! JSONPatch(data: madeJSONPatchData)
            return try! .literal(patch.apply(to: container.data()))
        },
        moved: { (container: ContentType, fromAddress: String, toAddress: String) throws in
            let madeJSONPatchData = Data("""
                                     [{"op": "move", "from": "\(fromAddress)", "path": "\(toAddress)"}]
                                     """.utf8)
            let patch = try! JSONPatch(data: madeJSONPatchData)
            return try! .literal(patch.apply(to: container.data()))
        },
        test: { (container: ContentType, value: ContentType, address: String) throws in
            let valueData = try value.data()
            let valueStr = valueData.asString()

            //                                     [{"op": "test", "path": "\(address)", "value": "\(valueStr)"}]
            let madeJSONPatchData = Data("""
                                     [{"op": "test", "path": "\(address)", "value": \(valueStr)}]
                                     """.utf8)

            print("Container: \(try container.asString())")
            print(madeJSONPatchData.asString())

            let patch = try! JSONPatch(data: madeJSONPatchData)
            do {
                return try .literal(patch.apply(to: container.data()))
//                return true
            }
            catch let error {
                print("\(error)")
                // must throw, not ret changed content!
//                return container
                throw PatchouliError<JSONPatchType>.testFailed(container, address, value)
//                // NB if test fails, then the patch as a whole should not apply!
//                // this shouldn't actually throw an error! It's just for not applying the patch.
//                //
//                // Hmm. My whole approach is doing each step as its own json_patch, but I should be gathering into
//                // one piece?
//                // So reduce should build up a collection of commands, NOT the actual result!
////                return false
            }
        }
    )// [{"op": "test", "path": "/myArray", "value": []}]

    // TODO use our helper, rather than utf8 directly, then can kill the above utf8Data helper?
    // -- hmm, issues.
//    static public var emptyObjectContent = JSONContent.make("{}")
//    static public var emptyArrayContent = JSONContent.make("[]")
    static public var emptyObjectContent: JSONContent = .literal("{}".utf8Data)
    static public var emptyArrayContent: JSONContent = .literal("[]".utf8Data)

    public static var emptyContent: JSONContent = emptyObjectContent
}
