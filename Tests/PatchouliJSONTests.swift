import XCTest

@testable import PatchouliCore
@testable import PatchouliJSON

//
// [ ] write test for TEST op - initially failing, of course
// [ ] impl test failure in reducer -- i.e. fail = we don't apply any changes (in-place reducer would have to work on
//     a copy for this, until we know ok! Optimisation: might not bother with making the copy if no TEST op
//     is seen in the list of items (we could check before any processing)
//

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
        XCTAssertEqual(try dataResult.asString(), "{\"a\":\"hello\"}")
    }

    func test_DSL_emptyContent() throws {
        // can I put emptyContent into extension on content? probably
        let patchedJSONContent: PatchedJSON = Content(JSONPatchType.emptyContent)
        let dataResult = try patchedJSONContent.reduced()
        XCTAssertEqual(try dataResult.asString(), "{}")
    }

    func test_DSL_patchedJSONContent1() throws {
        let patchedJSONContent: PatchedJSON = Content(JSONPatchType.emptyContent) {
            Add(address: "", simpleContent: .literal("\"alex\"".utf8Data))
        }
        let dataResult = try patchedJSONContent.reduced()
        XCTAssertEqual(try dataResult.asString(), """
                                                                    "alex"
                                                                    """)
    }

    func test_DSL_patchedJSONContent2() throws {
        let patchedJSONContent: PatchedJSON = Content(JSONPatchType.emptyContent) {
            Add(address: "/", simpleContent: .literal("\"alex\"".utf8Data))
        }
        let dataResult = try patchedJSONContent.reduced()
        XCTAssertEqual(try dataResult.asString(), """
                                                                    {"":"alex"}
                                                                    """)
    }

    func test_DSL_patchedJSONContent3() throws {
        let patchedJSONContent: PatchedJSON = Content(JSONPatchType.emptyContent) {
            Add(address: "/new", simpleContent: .literal("\"alex\"".utf8Data))
            Add(address: "/new", simpleContent: .literal("\"mike\"".utf8Data))
        }
        let dataResult = try patchedJSONContent.reduced()
        XCTAssertEqual(try dataResult.asString(), """
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
        XCTAssertEqual(try dataResult.asString(), """
                                                                    {"myArray":["mike","alex"]}
                                                                    """)
    }

    // Could add idea of 'addressMap' optional on patcher: if not nil, is applied to all
    // addresses. Similarly for contentMapper. This would allow us to wrap naked content strings in quotes
    // as a convenience.
    func test_DSL_patchedJSONContent5() throws {
        let someDouble = 1.2

        let patchedJSONContent = JSONObject {
            Add(address: "/myArray", simpleContent: JSONPatchType.emptyArrayContent)
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
        }
        let dataResult = try patchedJSONContent.reduced()
        XCTAssertEqual(try dataResult.asString(), """
                                                                    {"myArray":["mike",7,1.2,[5,61,[3]],[\"foo\",\"zoo\",0],true,false,null,null]}
                                                                    """)
    }

    func test_DSL_IfTestOperationFails_thenOriginalJSONISReturned() throws {
        // NB operation failure doesn't throw an error to here,
        // it just returns the original content without patching
        let patchedJSONContent = JSONObject {
            Add(address: "/myArray", simpleContent: JSONPatchType.emptyArrayContent)
            Add(address: "/myArray/-", jsonContent: "mike")
            Test(address: "/doesNotExist", expectedSimpleContent: JSONPatchType.emptyArrayContent)
        }
        let dataResult = try patchedJSONContent.reduced()
        print("Redoid1 = ", try dataResult.asString())

        // we expect the empty JSONObject to be returned, as the test will fail.
        // meaning no patching should take place
        try XCTAssertEqual(dataResult.data(), JSONPatchType.emptyObjectContent.data())
    }

    func test_DSL_ifTestOperationSucceeds_thenPatchedJSONISReturned() throws {
        let patchedJSONContent = JSONObject {
            Add(address: "/myArray", jsonContent: "mike")
            Test(address: "/myArray", jsonContent: "mike")
        }
        let dataResult = try patchedJSONContent.reduced()

        print("Redoid2 = ", try dataResult.asString())

        let expectedJSON = Data("""
                                {"myArray":"mike"}
                                """.utf8)

        // we expect the empty JSONObject to be returned, as the test will fail.
        // meaning no patching should take place
        try XCTAssertEqual(dataResult.data(), expectedJSON) // JSONPatchType.emptyObjectContent.data())
    }

    func test_DSL_ifTestOperationIsNotLastAndFails_thenOriginalJSONISReturned() throws {
        let patchedJSONContent = JSONObject {
            Add(address: "/myArray", jsonContent: "mike")
            Test(address: "/myArray", jsonContent: "horse")
            Add(address: "/myArray2", jsonContent: "alex")
        }
        let dataResult = try patchedJSONContent.reduced()

        print("Redoid2 = ", try dataResult.asString())

        let expectedJSONData = Data("""
                                {"myArray":"mike","myArray2":"alex"}
                                """.utf8)

        // TODO change of manual decoding calls to this:
        print("Res:|", try dataResult.asString(), "|")
        print("expectedJSON:|", expectedJSONData.asString(), "|")
        // we expect the empty JSONObject to be returned, as the test will fail.
        // meaning no patching should take place

        try XCTAssertEqual(dataResult.data(), JSONPatchType.emptyObjectContent.data())
    }

    func test_DSL_ifTestOperationIsNotLastAndSucceeds_thenPatchedJSONISReturned() throws {
        let patchedJSONContent = JSONObject {
            Add(address: "/myArray", jsonContent: "mike")
            Test(address: "/myArray", jsonContent: "mike")
            Add(address: "/myArray2", jsonContent: "alex")
        }
        let dataResult = try patchedJSONContent.reduced()

        print("Redoid2 = ", try dataResult.asString())

        let expectedJSONData = Data("""
                                {"myArray":"mike","myArray2":"alex"}
                                """.utf8)

//        print("Res:|", try dataResult.asString(), "|")
//        print("expectedJSON:|", expectedJSONData.asString(), "|")
        // we expect the empty JSONObject to be returned, as the test will fail.
        // meaning no patching should take place

        try XCTAssertEqual(dataResult.data(), expectedJSONData) // JSONPatchType.emptyObjectContent.data())
    }
}
