//
//  DisjuncitveAndHierarchicalIntegrationTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 04/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import XCTest
@testable import InstantSearchCore

class DisjuncitveAndHierarchicalIntegrationTests: OnlineTestCase {
  
  struct Item: Codable {
    let objectID: String = UUID().uuidString
    let name: String
    let color: String?
    let hierarchicalCategories: [String: String]
  }
  
  static func attribute(for level: Int) -> Attribute {
    return .init("hierarchicalCategories.lvl\(level)")
  }
  
  let lvl0 = { attribute(for: 0) }()
  let lvl1 = { attribute(for: 1) }()
  let lvl2 = { attribute(for: 2) }()
  
  var hierarchicalAttributes: [Attribute] {
    return [lvl0, lvl1, lvl2]
  }
  
  let colorAttribute: Attribute = "color"
  
  let cat1 = "Category1"
  let cat2 = "Category2"
  let cat3 = "Category3"
  
  let cat2_1 = "Category2 > SubCategory1"
  let cat2_2 = "Category2 > SubCategory2"
  let cat3_1 = "Category3 > SubCategory1"
  let cat3_2 = "Category3 > SubCategory2"
  
  let cat3_1_1 = "Category3 > SubCategory1 > SubSubCategory1"
  let cat3_1_2 = "Category3 > SubCategory1 > SubSubCategory2"
  let cat3_2_1 = "Category3 > SubCategory2 > SubSubCategory1"
  let cat3_2_2 = "Category3 > SubCategory2 > SubSubCategory2"

  
  var facetAttributes: [Attribute] {
    return hierarchicalAttributes + [colorAttribute]
  }
  
  override func setUp() {
    super.setUp()
    let exp = expectation(description: "wait for filling the index")
    let settings: [String: Any] = ["attributesForFaceting": facetAttributes.map { $0.name }]
    let items = try! [Item](jsonFile: "disjunctiveHierarchical", bundle: Bundle(for: HierarchicalTests.self))
    fillIndex(withItems: items, settings: settings, completionHandler: exp.fulfill)
    waitForExpectations(timeout: 50, handler: .none)
  }
  
  func testDisjuncitiveHierarchical() {
    
    let expectedHierarchicalFacets: [(Attribute, [Facet])] = [
      (lvl0, [
        .init(value: cat3, count: 2, highlighted: nil),
        .init(value: cat2, count: 1, highlighted: nil)
      ]),
      (lvl1, [
        .init(value: cat3_2, count: 2, highlighted: nil),
        ]),
      (lvl2, [
        .init(value: cat3_2_1, count: 1, highlighted: nil),
        .init(value: cat3_2_2, count: 1, highlighted: nil)
      ]),
    ]
    
    let expectedDisjunctiveFacets: [(Attribute, [Facet])] = [
      (colorAttribute, [
        Facet(value: "red", count: 2, highlighted: nil),
        Facet(value: "blue", count: 1, highlighted: nil),
      ])
    ]
    
    let colorFilter = Filter.Facet(attribute: colorAttribute, stringValue: "red")
    
    let hierarchicalFilter = Filter.Facet(attribute: lvl1, stringValue: cat3_2)
    
    let filterGroups: [FilterGroupType] = [
      FilterGroup.And(filters: [hierarchicalFilter], name: "_hierarchical"),
      FilterGroup.Or(filters: [colorFilter], name: "color")
    ]
    
    let hierarchicalFilters = [
      Filter.Facet(attribute: lvl0, stringValue: cat3),
      Filter.Facet(attribute: lvl1, stringValue: cat3_2)
    ]
    
    let query = Query(query: "")
    query.facets = facetAttributes.map { $0.name }
    
    let queryBuilder = QueryBuilder(query: query,
                                    filterGroups: filterGroups,
                                    hierarchicalAttributes: hierarchicalAttributes,
                                    hierachicalFilters: hierarchicalFilters)
    
    let queries = queryBuilder.build()
    
    XCTAssertEqual(queryBuilder.disjunctiveFacetingQueriesCount, 1)
    XCTAssertEqual(queryBuilder.hierarchicalFacetingQueriesCount, 3)

    let exp = expectation(description: "results")
    
    let indexQueries = queries.map { IndexQuery(index: self.index, query: $0) }
    
    client!.multipleQueries(indexQueries) { (result, error) in
      self.extract(result, error) { (results: MultiSearchResults) in
        let finalResult = try! queryBuilder.aggregate(results.searchResults)
        expectedDisjunctiveFacets.forEach { (attribute, facets) in
          XCTAssertTrue(finalResult.disjunctiveFacets?[attribute]?.equalContents(to: facets) == true)
        }
        expectedHierarchicalFacets.forEach { (attribute, facets) in
          XCTAssertTrue(finalResult.hierarchicalFacets?[attribute]?.equalContents(to: facets) == true)
        }
        exp.fulfill()
      }
    }
    
    waitForExpectations(timeout: 15, handler: .none)
    
  }
  
}
