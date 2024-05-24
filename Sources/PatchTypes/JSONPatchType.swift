import Foundation
import PatchouliCore
import JSONPatch

// MARK: - DSL primitive that supports JSON Patch (RFC6902)
//
// We do no validation of what is passed to JSONPatch; we just relay what we are given.
// Any errors from JSONPatch are bubbled back through the reduce.
//
// https://datatracker.ietf.org/doc/html/rfc6902

public let null: Any? = nil

public typealias PatchedJSON = PatchedContent<JSONPatchType>
// beware, JSONPatch has a JSONPatch, obviously! Is this clear enough?
public typealias JSONPatchItem = AddressedPatch<JSONPatchType>

extension String {
    public var utf8Data: Data { Data(self.utf8) }
}

//public enum ContentIdea<T: PatchType> {
//    case literal(T.ContentType)
//    case fileURL(URL)
//    case bundleResource(String)
//
//    var data: T.ContentType {
//        // TODO get it
//        Data()
//    }
//}

public enum JSONContentIdea {
    case literal(Data)
    case fileURL(URL)
    case bundleResource(String)

    var data: Data {
        // TODO finish this
        switch self {
        case let .literal(data):
            return data
        default:
            assertionFailure("Implement this")
            return Data()
        }
    }
}

public struct JSONPatchType: PatchType {
    public typealias ContentType = JSONContentIdea
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
        added: { (container: ContentType, addition: ContentType, address: String) -> ContentType in
            let additionStr = String(decoding: addition.data, as: UTF8.self)
            let madeJSONPatch = Data("""
                                     [{"op": "add", "path": "\(address)", "value": \(additionStr)}]
                                     """.utf8)
            print(String(decoding: madeJSONPatch, as: UTF8.self))
            let patch = try! JSONPatch(data: madeJSONPatch)
            // so we need to change `to: container` here to use the ContentIdea and get the data from whatever src
            return try! .literal(patch.apply(to: container.data))
        },
        removed: { (container: ContentType, address: String) -> ContentType in
            let madeJSONPatch = Data("""
                                     [{"op": "remove", "path": "\(address)"}]
                                     """.utf8)
            let patch = try! JSONPatch(data: madeJSONPatch)
            return try! .literal(patch.apply(to: container.data))
        },
        replaced: { (container: ContentType, replacement: ContentType, address: String) -> ContentType in
            let replacementStr = String(decoding: replacement.data, as: UTF8.self)

            let madeJSONPatch = Data("""
                                     [{"op": "replace", "path": "\(address)", "value": \(replacementStr)}]
                                     """.utf8)
            let patch = try! JSONPatch(data: madeJSONPatch)
            return try! .literal(patch.apply(to: container.data))
        },
        copied: { (container: ContentType, fromAddress: String, toAddress: String) in
            let madeJSONPatch = Data("""
                                     [{"op": "copy", "copy": "\(fromAddress)", "path": \(toAddress)}]
                                     """.utf8)
            let patch = try! JSONPatch(data: madeJSONPatch)
            return try! .literal(patch.apply(to: container.data))
        },
        moved: { (container: ContentType, fromAddress: String, toAddress: String) in
            let madeJSONPatch = Data("""
                                     [{"op": "move", "copy": "\(fromAddress)", "path": \(toAddress)}]
                                     """.utf8)
            let patch = try! JSONPatch(data: madeJSONPatch)
            return try! .literal(patch.apply(to: container.data))
        },
        test: { (container: ContentType, value: ContentType, address: String) -> Bool in
            let madeJSONPatch = Data("""
                                     [{"op": "test", "path": "\(address)", "value": \(value)}]
                                     """.utf8)
            // TODO throw something if this doesn't work? and same for others
            let patch = try! JSONPatch(data: madeJSONPatch)
            do {
                let _ = try patch.apply(to: container)
                return true
            }
            catch {
                return false
            }
        }
    )

    static public var emptyObjectContent = JSONContentIdea.literal("{}".utf8Data)
    static public var emptyArrayContent = JSONContentIdea.literal("[]".utf8Data)

//    static public var emptyContent = emptyObjectContent
    public static var emptyContent: JSONContentIdea = emptyObjectContent

    // with json and strings, inout doesn't make much practical sense,
    // but for demonstration purposes.
//    static public var mutatingPatcher: MutatingPatchable<JSONPatchType>? = .init(
//        replace: { (container: inout Data, replacement: Data, address: String) -> Void in
//            let replacementStr = String(decoding: replacement, as: UTF8.self)
//
//            let madeJSONPatch = Data("""
//                                     [{"op": "replace", "path": "\(address)", "value": \(replacementStr)}]
//                                     """.utf8)
//
////            print(String(decoding: madeJSONPatch, as: UTF8.self))
//
//            // this is an inout func, but we're not generating result directly as inout, note!
//            let patch = try! JSONPatch(data: madeJSONPatch)
//            container = try! patch.apply(to: container)
//        }
//    )
}
