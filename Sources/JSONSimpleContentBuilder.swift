//
//  JSONSimpleContentBuilder.swift
//  PatchouliJSON
//
//  Created by Alex Hunsley on 19/06/2024.
//

import Foundation

/// Helper for constructing common JSON primitives from e.g. lists, plain strings, etc.
@resultBuilder
public struct JSONSimpleContentBuilder {
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

@JSONSimpleContentBuilder func applyBuilder(_ jsonContentClosure: () -> Any?) -> Data {
    jsonContentClosure()
}

