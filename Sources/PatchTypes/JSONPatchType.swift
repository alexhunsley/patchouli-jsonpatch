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

public struct JSONPatchType: PatchType {
    public typealias ContentType = Data
    public typealias AddressType = String

    /// The Protocol Witness used by the reducer
    static public var patcher = Patchable<JSONPatchType>(
        added: { (container: Data, addition: Data, address: String) in
            let additionStr = String(decoding: addition, as: UTF8.self)
            let madeJSONPatch = Data("""
                                     [{"op": "add", "path": "\(address)", "value": \(additionStr)}]
                                     """.utf8)
            let patch = try! JSONPatch(data: madeJSONPatch)
            return try! patch.apply(to: container)
        },
        replaced: { (container: Data, replacement: Data, address: String) -> Data in
            let replacementStr = String(decoding: replacement, as: UTF8.self)

            let madeJSONPatch = Data("""
                                     [{"op": "replace", "path": "\(address)", "value": \(replacementStr)}]
                                     """.utf8)
            let patch = try! JSONPatch(data: madeJSONPatch)
            return try! patch.apply(to: container)
        }
    )

    static public var emptyObjectContent = "{}".utf8Data
    static public var emptyArrayContent = "[]".utf8Data

    static public var emptyContent = emptyObjectContent

    // with json and strings, inout doesn't make much practical sense,
    // but for demonstration purposes.
//    static public var inPlacePatcher: InPlacePatchable<JSONPatchType>? = .init(
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
