//
//  PlaceTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 30/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest


class TestPlaces: XCTestCase {
  
  func testDecoding() {
    
    do {
      let place = try Place(jsonFile: "PlaceHit", bundle: Bundle(for: TestPlaces.self))
      XCTAssertEqual(place.localeNames, ["Aarhus"])
      XCTAssertEqual(place.country, "Denmark")
      XCTAssertEqual(place.county, ["Aarhus Municipality"])
      XCTAssertEqual(place.administrative, ["Region Midtjylland"])
      XCTAssertEqual(place.geolocation, Place.Geolocation(latitude: 56.1496, longitude: 10.2134))
    } catch let error {
      XCTFail("\(error)")
    }

  }
  
  func testHitDecoding() {
    
    do {
      let placeHit = try Hit<Place>(jsonFile: "PlaceHit", bundle: Bundle(for: TestPlaces.self))
      XCTAssertEqual(placeHit.object.localeNames, ["Aarhus"])
      XCTAssertEqual(placeHit.object.country, "Denmark")
      XCTAssertEqual(placeHit.object.county, ["Aarhus Municipality"])
      XCTAssertEqual(placeHit.object.administrative, ["Region Midtjylland"])
      XCTAssertEqual(placeHit.object.geolocation, Place.Geolocation(latitude: 56.1496, longitude: 10.2134))
      XCTAssertEqual(placeHit.objectID, "2624652")
      guard let highlightResult = placeHit.highlightResult else {
        XCTFail("missing highlight result")
        return
      }
      let highlightKeysSet = Set(highlightResult.keys)
      XCTAssertEqual(highlightKeysSet, ["country", "postcode", "county", "administrative", "locale_names"])
    } catch let error {
      XCTFail("\(error)")
    }
    
  }
  
  func testSearchResultPlaceDecoding() {
    
    do {
      
      let placesResult = try SearchResults(jsonFile: "PlacesResult", bundle: Bundle(for: TestPlaces.self))
      
      XCTAssertEqual(placesResult.stats.totalHitsCount, 5)
      XCTAssertEqual(placesResult.stats.query, "aa")
      XCTAssertEqual(placesResult.stats.processingTimeMS, 1)
      XCTAssertEqual(placesResult.hits.count, 5)
      
    } catch let error {
      XCTFail("\(error)")
    }
    
  }
  
}
