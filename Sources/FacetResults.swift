//
//  FacetResults.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 05/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@_exported import InstantSearchClient

/// A value of a given facet, together with its number of occurrences.
/// This struct is mainly useful when an ordered list of facet values has to be presented to the user.
///
public struct FacetValue: Codable, Equatable {
    public let value: String
    public let count: Int
    public let highlighted: String?
}

extension Dictionary where Key == String, Value == [String: Int] {
  
  init(_ facetsForAttribute: [Attribute: [FacetValue]]) {
    self = [:]
    for facetForAttribute in facetsForAttribute {
      let rawAttribute = facetForAttribute.key.description
      self[rawAttribute] = [String: Int](facetForAttribute.value)
    }
  }
  
}

extension Dictionary where Key == String, Value == Int {
  
  init(_ facetValues: [FacetValue]) {
    self = [:]
    for facetValue in facetValues {
      self[facetValue.value] = facetValue.count
    }
  }
  
}

/// Search for facet value results.
public struct FacetResults: Codable {
    
    enum CodingKeys: String, CodingKey {
        case facetHits
        case processingTimeMS
        case areFacetsCountExhaustive = "exhaustiveFacetsCount"
    }
    
    public let facetHits: [FacetValue]
    public let processingTimeMS: Int
    public let areFacetsCountExhaustive: Bool
    
}