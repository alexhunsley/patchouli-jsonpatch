import XCTest

@testable import PatchouliCore
@testable import PatchouliJSON

// TODO some nested tests! there are some in String toy patcher tests already
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
        XCTAssertEqual(try dataResult.string(), "{\"a\":\"hello\"}")
    }

    func test_DSL_emptyContent() throws {
        // can I put emptyContent into extension on content? probably
        let patchedJSONContent: PatchedJSON = Content(JSONPatchType.emptyContent)
        let dataResult = try patchedJSONContent.reduced()
        XCTAssertEqual(try dataResult.string(), "{}")
    }

    func test_DSL_patchedJSONContent1() throws {
        let patchedJSONContent: PatchedJSON = Content(JSONPatchType.emptyContent) {
            // tODO do simpler version of this and others! but keep this verbose example too
            Add(address: "", simpleContent: .literal("\"alex\"".utf8Data))
        }
        let dataResult = try patchedJSONContent.reduced()
        XCTAssertEqual(try dataResult.string(), """
                                                  "alex"
                                                  """)
    }

    func test_DSL_patchedJSONContent2() throws {
        let patchedJSONContent: PatchedJSON = Content(JSONPatchType.emptyContent) {
            Add(address: "/", simpleContent: .literal("\"alex\"".utf8Data))
        }
        let dataResult = try patchedJSONContent.reduced()

        // try the manual encoding passing (defaults to .utf8 normally anyway)
        XCTAssertEqual(try dataResult.string(encoding: .utf8), """
                                                  {"":"alex"}
                                                  """)
    }

    func test_DSL_patchedJSONContent3() throws {
        let patchedJSONContent: PatchedJSON = Content(JSONPatchType.emptyContent) {
            Add(address: "/new", simpleContent: .literal("\"alex\"".utf8Data))
            Add(address: "/new", simpleContent: .literal("\"mike\"".utf8Data))
        }
        let dataResult = try patchedJSONContent.reduced()
        XCTAssertEqual(try dataResult.string(), """
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
        XCTAssertEqual(try dataResult.string(), """
                                                  {"myArray":["mike","alex"]}
                                                  """)
    }

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
        XCTAssertEqual(try dataResult.string(), """
                                                  {"myArray":["mike",7,1.2,[5,61,[3]],[\"foo\",\"zoo\",0],true,false,null,null]}
                                                  """)
    }

    // MARK: - 'Test' operation tests

    func test_DSL_IfTestOperationFails_thenOriginalJSONISReturned() throws {
        // NB operation failure doesn't throw an error to here,
        // it just returns the original content without patching
        let patchedJSONContent = JSONObject {
            Add(address: "/myArray", simpleContent: JSONPatchType.emptyArrayContent)
            Add(address: "/myArray/-", jsonContent: "mike")
            Test(address: "/doesNotExist", expectedSimpleContent: JSONPatchType.emptyArrayContent)
        }
        let dataResult = try patchedJSONContent.reduced()
        print("Redoid1 = ", try dataResult.string())

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

        print("Redoid2 = ", try dataResult.string())

        let expectedJSON = Data("""
                                {"myArray":"mike"}
                                """.utf8)

        // we expect the empty JSONObject to be returned, as the test will fail.
        // meaning no patching should take place
        try XCTAssertEqual(dataResult.data(), expectedJSON) // JSONPatchType.emptyObjectContent.data())
    }

    func test_stringLiteralContent() throws {
        // works
        //        let patchedJSONContent: PatchedJSON = Content(
        //            .literal("""
        //                    { "greet": "Hello", "bye": "auf wiedersehen" }
        //                    """.utf8Data)
        //        ) {
        ////            Add(address: "/users/-", jsonContent: "alex")
        //        }

        let patchedJSONContent: PatchedJSON = Content(string:
            """
            { "greet": "Hello", "bye": "auf wiedersehen", "users": [] }
            """
        ) {
            Add(address: "/users/-", jsonContent: "alex")
        }

        let dataResult = try patchedJSONContent.reduced()
        let expectedJSONData = Data("""
                                    {"greet":"Hello","bye":"auf wiedersehen","users":["alex"]}
                                    """.utf8)
        print("QIQI expected: \(expectedJSONData.string())")
        print("QIQI got: \(try dataResult.string())")
        try XCTAssertEqual(dataResult.data(), expectedJSONData)
    }

    func test_DSL_ifTestOperationIsNotLastAndFails_thenOriginalJSONISReturned() throws {
        let patchedJSONContent = JSONObject {
            Add(address: "/myArray", jsonContent: "mike")
            Test(address: "/myArray", jsonContent: "horse")
            Add(address: "/myArray2", jsonContent: "alex")
        }
        let dataResult = try patchedJSONContent.reduced()

        print("Redoid2 = ", try dataResult.string())

        let expectedJSONData = Data("""
                                    {"myArray":"mike","myArray2":"alex"}
                                    """.utf8)

        // TODO change of manual decoding calls to this:
        print("Res:|", try dataResult.string(), "|")
        print("expectedJSON:|", expectedJSONData.string(), "|")
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

        let expectedJSONData = Data("""
                                    {"myArray":"mike","myArray2":"alex"}
                                    """.utf8)

        // we expect the empty JSONObject to be returned, as the test will fail
        // and hence patching won't happen.

        try XCTAssertEqual(dataResult.data(), expectedJSONData)
    }

    // MARK: - Nested patching

    func test_DSL_nestedPatches() throws {
        
        let bundleContent = JSONContent.bundleResource(Bundle(for: Self.self), "UserList")
        
        let someJSONFileURL = URL(fileURLWithPath: "/a/b/c")
        let someJSONFileURL2 = URL(fileURLWithPath: "/a/b/d")
        
        let patchedJSONContent: PatchedJSON = Content(fileURL: someJSONFileURL) {
            Add(address: "/some_key", content: Content(fileURL: someJSONFileURL2) {
                Replace(address: "hello", jsonContent: "friend")
            })
            
            Replace(address: "goodbye", jsonContent: "auf wiedersehen")
        }
    }

    // MARK: - Bundle and file URL loading tests

    // need to depend on framework holder to use this, or have own bundle
    func testBundleLoading_helper() throws {
        // TODO might be better with this test in core
        let expectJSONContent = """
                                {"users":["alex"],"login_permitted":true,"login_count":17}
                                """

        let patchedJSONContent: PatchedJSON = Content(resource: "UserList", bundle: Bundle(for: Self.self)) {
            Add(address: "/users/-", jsonContent: "alex")
        }

        XCTAssertEqual(try patchedJSONContent.reduced().string(), expectJSONContent)
    }

    func testBundleLoading_manual() throws {
        // TODO might be better with this test in core

        // herus - nicer way than Self.self? Bundle.main ain't it!
        let bundleContent = JSONContent.bundleResource(Bundle(for: Self.self), "UserList")

        let expectJSONContent = """
                                {"users":["alex"],"login_permitted":true,"login_count":17}
                                """

        let patchedJSONContent: PatchedJSON = Content(bundleContent) {
            Add(address: "/users/-", jsonContent: "alex")
        }

        XCTAssertEqual(try patchedJSONContent.reduced().string(), expectJSONContent)

    }

    func testFileLoading_manual() throws {
        // TODO might be better with this test in core
        let jsonContent = """
                          {
                              "login_permitted": true,
                              "login_count": 17,
                              "users": []
                          }

                          """

        let tempFileURL = try XCTUnwrap(createTemporaryFile(withContent: jsonContent))

        defer {
            deleteTemporaryFile(at: tempFileURL)
        }

        let expectJSONContent = """
                                {"users":["alex"],"login_permitted":true,"login_count":17}
                                """

        let fileContent = JSONContent.fileURL(tempFileURL)

        print("Temp file: \(tempFileURL)")
        XCTAssertEqual(try fileContent.string(), jsonContent)

        let patchedJSONContent: PatchedJSON = Content(fileContent) {
            Add(address: "/users/-", jsonContent: "alex")
        }

        XCTAssertEqual(try patchedJSONContent.reduced().string(), expectJSONContent)
    }

    func testFileLoading_helper() throws {
        // TODO might be better with this test in core
        let jsonContent = """
                          {
                              "login_permitted": true,
                              "login_count": 17,
                              "users": []
                          }

                          """

        let tempFileURL = try XCTUnwrap(createTemporaryFile(withContent: jsonContent))

        defer {
            deleteTemporaryFile(at: tempFileURL)
        }

        let expectJSONContent = """
                                {"users":["alex"],"login_permitted":true,"login_count":17}
                                """

        let patchedJSONContent: PatchedJSON = Content(fileURL: tempFileURL) {
            Add(address: "/users/-", jsonContent: "alex")
        }

        XCTAssertEqual(try patchedJSONContent.reduced().string(), expectJSONContent)
    }
}

// MARK: - Helpers

extension XCTestCase {
    // Function to create a temporary file with some content
    func createTemporaryFile(withContent content: String) -> URL? {
        // Get the path to the temporary directory
        let tempDirectory = NSTemporaryDirectory()

        // Create a unique file name using UUID
        let fileName = UUID().uuidString
        let filePath = tempDirectory.appending("/\(fileName)")
        let fileURL = URL(fileURLWithPath: filePath)

        // Write content to the file
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            XCTFail("Failed to write to temporary file: \(error)")
            return nil
        }
    }

    func deleteTemporaryFile(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            XCTFail("Failed to delete temporary file: \(error)")
        }
    }
}
