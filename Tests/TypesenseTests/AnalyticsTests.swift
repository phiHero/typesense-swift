import XCTest
@testable import Typesense

final class AnalyticsTests: XCTestCase {
    override func setUp() async throws  {
        try await createCollection()
        try await createAnalyticRule()
    }

    override func tearDown() async throws  {
       try await tearDownAnalyticsRules()
       try await tearDownCollections()
    }

    func testAnalyticsRuleCreate() async {
        let destination = AnalyticsRuleParametersDestination(collection: "product_queries")
        let source = AnalyticsRuleParametersSource(collections: ["products"])
        let schema = AnalyticsRuleSchema(name: "product_queries_aggregation", type: .popularQueries, params: AnalyticsRuleParameters(source: source, destination: destination, limit: 1000))
        do {
            let (rule, _) = try await client.analytics().rules().upsert(params: schema)
            XCTAssertNotNil(rule)
            guard let validRule = rule else {
                throw DataError.dataNotFound
            }
            print(validRule)
            XCTAssertEqual(validRule.name, schema.name)
            XCTAssertEqual(validRule.params.limit, schema.params.limit)
            XCTAssertEqual(validRule.params.destination.collection, schema.params.destination.collection)
        } catch (let error) {
            print(error.localizedDescription)
            XCTAssertTrue(false)
        }
    }

    func testAnalyticsRuleRetrieve() async {
        do {
            let (rule, _) = try await client.analytics().rule(id: "product_queries_aggregation").retrieve()
            guard let validRule = rule else {
                throw DataError.dataNotFound
            }
            print(validRule)
            XCTAssertEqual(validRule.name, "product_queries_aggregation")
        } catch (let error) {
            print(error.localizedDescription)
            XCTAssertTrue(false)
        }
    }

    func testAnalyticsRuleRetrieveAll() async {
        do {
            let (rules, _) = try await client.analytics().rules().retrieveAll()
            XCTAssertNotNil(rules)
            guard let validRules = rules?.rules else {
                throw DataError.dataNotFound
            }
            print(validRules)
            XCTAssertEqual(validRules[0].name, "product_queries_aggregation")
        }  catch (let error) {
            print(error.localizedDescription)
            XCTAssertTrue(false)
        }
    }

    func testAnalyticsRuleDelete() async {
        do {
            let (deletedRule, _) = try await client.analytics().rule(id: "product_queries_aggregation").delete()
            XCTAssertNotNil(deletedRule)
            guard let validRule = deletedRule else {
                throw DataError.dataNotFound
            }
            print(validRule)
            XCTAssertEqual(validRule.name, "product_queries_aggregation")
        }  catch (let error) {
            print(error.localizedDescription)
            XCTAssertTrue(false)
        }
    }

    func testAnalyticsEventsCreate() async {
        do {
            let (res, _) = try await client.analytics().events().create(params: AnalyticsEventCreateSchema(
                type: "click",
                name: "products_click_event",
                data: [
                  "q": "nike shoes",
                  "doc_id": "1024",
                  "user_id": "111112"
                ]
            ))
            guard let validRes = res else {
                throw DataError.dataNotFound
            }
            print(validRes)
            XCTAssertTrue(validRes.ok)
        }  catch (let error) {
            print(error.localizedDescription)
            XCTAssertTrue(false)
        }
    }
}
