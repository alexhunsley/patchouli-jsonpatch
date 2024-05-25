import XCTest

@testable import PatchouliCore
@testable import PatchouliJSON

final class PatchouliJSONTests: XCTestCase {

    // MARK: - JSON Patch spec instantiation (DSL)

    func test_DSL_JSONPatchInstantiationAndReduce() throws {

        let json = Data("""
                        {"a": [] }
                        """.utf8)

        let jsonInsert = Data("""
                              "hello"
                              """.utf8)

        let patchedJSONContent: PatchedJSON = Content(.literal(json)) {
            Replace(address: "/a", withContent: PatchedContent(content: .literal(jsonInsert)))
        }

        // TODO same as for string test: testReducers()
        let dataResult = try patchedJSONContent.reduced()
        XCTAssertEqual(String(decoding: try dataResult.data(), as: UTF8.self), "{\"a\":\"hello\"}")
    }

    func test_DSL_emptyContent() throws {
        // can I put emptyContent into extension on content? probably
        let patchedJSONContent: PatchedJSON = Content(JSONPatchType.emptyContent)
        let dataResult = try patchedJSONContent.reduced()
        XCTAssertEqual(String(decoding: try dataResult.data(), as: UTF8.self), "{}")
    }

    func test_DSL_patchedJSONContent1() throws {
        let patchedJSONContent: PatchedJSON = Content(JSONPatchType.emptyContent) {
            Add(address: "", simpleContent: .literal("\"alex\"".utf8Data))
        }
        let dataResult = try patchedJSONContent.reduced()
        XCTAssertEqual(String(decoding: try dataResult.data(), as: UTF8.self), """
                                                                    "alex"
                                                                    """)
    }

    func test_DSL_patchedJSONContent2() throws {
        let patchedJSONContent: PatchedJSON = Content(JSONPatchType.emptyContent) {
            Add(address: "/", simpleContent: .literal("\"alex\"".utf8Data))
        }
        let dataResult = try patchedJSONContent.reduced()
        XCTAssertEqual(String(decoding: try dataResult.data(), as: UTF8.self), """
                                                                    {"":"alex"}
                                                                    """)
    }

    func test_DSL_patchedJSONContent3() throws {
        let patchedJSONContent: PatchedJSON = Content(JSONPatchType.emptyContent) {
            Add(address: "/new", simpleContent: .literal("\"alex\"".utf8Data))
            Add(address: "/new", simpleContent: .literal("\"mike\"".utf8Data))
        }
        let dataResult = try patchedJSONContent.reduced()
        XCTAssertEqual(String(decoding: try dataResult.data(), as: UTF8.self), """
                                                                    {"new":"mike"}
                                                                    """)
    }

    func test_DSL_patchedJSONContent4() throws {
        let patchedJSONContent: PatchedJSON = Content(JSONPatchType.emptyContent) {
            Add(address: "/myArray", simpleContent: .literal("[]".utf8Data))
            Add(address: "/myArray/-", simpleContent: .literal("\"mike\"".utf8Data))
            Add(address: "/myArray/-", simpleContent: .literal("\"alex\"".utf8Data))
        }
        let dataResult = try patchedJSONContent.reduced()
        XCTAssertEqual(String(decoding: try dataResult.data(), as: UTF8.self), """
                                                                    {"myArray":["mike","alex"]}
                                                                    """)
    }

    // Could add idea of 'addressMap' optional on patcher: if not nil, is applied to all
    // addresses. Similarly for contentMapper. This would allow us to wrap naked content strings in quotes
    // as a convenience.
    func test_DSL_patchedJSONContent5() throws {
        let someDouble = 1.2

//        let patchedJSONContent: PatchedJSON = Content(JSONPatchType.emptyContent) {

        // why not just make JSONObject an anlias for patchedJSONContent as per below?
//        let patchedJSONContent: JSONContent = JSONObject {
        let patchedJSONContent = JSONObject {
//            public func Add(address: String,
//                            @JSONSimpleContentBuilder jsonContent: () -> Data,
//                            @AddressedPatchItemsBuilder<JSONPatchType> patchedBy patchItems: PatchListProducer<JSONPatchType> = { AddressedPatch.emptyPatchList })
//                        -> JSONPatchItem {


            Add(address: "/myArray", simpleContent: JSONPatchType.emptyArrayContent)
//            Add(address: "/myArray", simpleContent: JSONPatchType.emptyObjectContent)
            Add(address: "/myArray/-", jsonContent: "mike") // this works with manual quotes
            Add(address: "/myArray/-", jsonContent: 7)
            Add(address: "/myArray/-", jsonContent: someDouble)
            Add(address: "/myArray/-", jsonContent: [5,61,[3]])

            Add(address: "/myArray/-", jsonContent: ["foo","zoo",0])
            // TODO problematic! '[nil]' or '[null]' becomes '[]' due to a filtering step.
            // One approach is to not make null a var for .nil directly, but
            // keep it as something more abstract for later changing.
//            Add(address: "/myArray/-", jsonContent: [null])
            Add(address: "/myArray/-", jsonContent: true)
            Add(address: "/myArray/-", jsonContent: false)
            Add(address: "/myArray/-", jsonContent: nil)  // becomes 'null'
            Add(address: "/myArray/-", jsonContent: null) // becomes 'null'

//            Add(address: "/myArray/0", simpleContent: "\"alex\"".utf8Data)
            // note how we use the simpleString helper here: it adds the quotes into the string and calls .utf8 for us
//            Add(address: "/myArray/0", simpleString: "bob")
        }
        let dataResult = try patchedJSONContent.reduced()
        XCTAssertEqual(String(decoding: try dataResult.data(), as: UTF8.self), """
                                                                    {"myArray":["mike",7,1.2,[5,61,[3]],[\"foo\",\"zoo\",0],true,false,null,null]}
                                                                    """)
    }
}
