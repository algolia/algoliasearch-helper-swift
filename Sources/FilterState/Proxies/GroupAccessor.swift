//
//  GroupAccessor.swift
//  AlgoliaSearch OSX
//
//  Created by Vladislav Fitc on 24/12/2018.
//  Copyright © 2018 Algolia. All rights reserved.
//

import Foundation

protocol FiltersContainer: class {
  var filters: FiltersReadable & FiltersWritable & FilterGroupsConvertible & HierarchicalManageable { get set }
}

extension FiltersContainer {
  
  subscript(and groupName: String) -> AndGroupAccessor {
    return .init(filtersContainer: self, groupName: groupName)
  }
  
  subscript<F: FilterType>(or groupName: String, type: F.Type) -> OrGroupAccessor<F> {
    return .init(filtersContainer: self, groupName: groupName)
  }
  
  subscript<F: FilterType>(or groupName: String) -> OrGroupAccessor<F> {
    return .init(filtersContainer: self, groupName: groupName)
  }
  
  subscript(hierarchical groupName: String) -> HierarchicalGroupAccessor {
    return .init(filtersContainer: self, groupName: groupName)
  }
  
}

public class ReadOnlyFiltersContainer {
  
  let filtersContainer: FiltersContainer
  
  init(filtersContainer: FiltersContainer) {
    self.filtersContainer = filtersContainer
  }
  
  public subscript<F: FilterType>(and groupName: String) -> ReadOnlyGroupAccessor<F> {
    return ReadOnlyGroupAccessor(SpecializedAndGroupAccessor(filtersContainer[and: groupName]))
  }
  
  public subscript<F: FilterType>(or groupName: String) -> ReadOnlyGroupAccessor<F> {
    return ReadOnlyGroupAccessor(filtersContainer[or: groupName])
  }

  public subscript(hierarchical groupName: String) -> ReadOnlyGroupAccessor<Filter.Facet> {
    return ReadOnlyGroupAccessor(filtersContainer[hierarchical: groupName])
  }
  
}

/// Group accessor provides a specific type-safe interface for FilterState specialized for a concrete group
public protocol GroupAccessor {
  
  var isEmpty: Bool { get }

  func removeAll(for attribute: Attribute)
  func removeAll()
  
}

public class ReadOnlyGroupAccessor<Filter: FilterType> {
  
  var storedIsEmpty: () -> Bool
  var storedGetFilters: () -> [Filter]
  var storedGetFiltersForAttribute: (Attribute) -> [Filter]
  var storedContains: (Filter) -> Bool
  
  init<A: SpecializedGroupAccessor>(_ accessor: A) where A.Filter == Filter {
    storedIsEmpty = { accessor.isEmpty }
    storedGetFilters = { return accessor.filters() }
    storedGetFiltersForAttribute = { return accessor.filters(for: $0) }
    storedContains = { return accessor.contains($0) }
  }
  
  var isEmpty: Bool {
    return storedIsEmpty()
  }
  
  func filters() -> [Filter] {
    return storedGetFilters()
  }
  
  func filters(for attribute: Attribute) -> [Filter] {
    return storedGetFiltersForAttribute(attribute)
  }
  
  func contains(_ filter: Filter) -> Bool {
    return storedContains(filter)
  }

}

public protocol SpecializedGroupAccessor: GroupAccessor {
  
  associatedtype Filter: FilterType
  
  func filters() -> [Filter]
  func filters(for attribute: Attribute) -> [Filter]
  
  func add(_ filter: Filter)
  func addAll<S: Sequence>(_ filters: S) where S.Element == Filter
  func contains(_ filter: Filter) -> Bool
  func remove(_ filter: Filter)
  @discardableResult func removeAll<S: Sequence>(_ filters: S) -> Bool where S.Element == Filter
  func toggle(_ filter: Filter)

}
