//
//  FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 10/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public struct FilterState {
  
  var groups: [FilterGroup.ID: Set<Filter>]
  
  public init() {
    self.groups = [:]
  }
  
  /// Copy constructor
  
  public init(_ filterState: FilterState) {
    self = filterState
  }
  
  private mutating func update(_ filters: Set<Filter>, forGroupWithID groupID: FilterGroup.ID) {
    groups[groupID] = filters.isEmpty ? nil : filters
  }
  
}

// MARK: - Public interface

public extension FilterState {
    
  /// A Boolean value indicating whether FilterState contains at least on filter
  
  var isEmpty: Bool {
    return groups.isEmpty
  }
  
  /// Tests whether FilterState contains a filter
  /// - parameter filter: desired filter
  
  func contains<T: FilterType>(_ filter: T) -> Bool {
    guard let filter = Filter(filter) else { return false }
    return getFilters().contains(filter)
  }
  
  /// Checks whether specified group contains a filter
  /// - parameter filter: filter to check
  /// - parameter groupID: target group ID
  /// - returns: true if filter is contained by specified group
  
  func contains<T: FilterType>(_ filter: T, inGroupWithID groupID: FilterGroup.ID) -> Bool {
    guard
      let filter = Filter(filter),
      let filtersForGroup = groups[groupID] else {
        return false
    }
    return filtersForGroup.contains(filter)
  }

  /// Returns a set of filters in group with specified ID
  /// - parameter groupID: target group ID
  
  func getFilters(forGroupWithID groupID: FilterGroup.ID) -> Set<Filter> {
    return groups[groupID] ?? []
  }
  
  /// Returns a set of filters for attribute
  /// - parameter attribute: target attribute
  
  func getFilters(for attribute: Attribute) -> Set<Filter> {
    let filtersArray = getFilters()
      .filter { $0.filter.attribute == attribute }
    return Set(filtersArray)
  }
  
  /// Returns a set of all the filters contained by all the groups
  
  private func getFilters() -> Set<Filter> {
    return groups.values.reduce(Set<Filter>(), { $0.union($1) })
  }

}

// MARK: - Public mutating interface

public extension FilterState {
  
  /// Adds filter to a specified group
  /// - parameter filter: filter to add
  /// - parameter groupID: target group ID
  
  mutating func add<T: FilterType>(_ filter: T, toGroupWithID groupID: FilterGroup.ID) {
    addAll(filters: [filter], toGroupWithID: groupID)
  }
  
  /// Adds a sequence of filters to a specified group
  /// - parameter filters: sequence of filters to add
  /// - parameter groupID: target group ID
  
  mutating func addAll<T: FilterType, S: Sequence>(filters: S, toGroupWithID groupID: FilterGroup.ID) where S.Element == T {
    let existingFilters = groups[groupID] ?? []
    let updatedFilters = existingFilters.union(filters.compactMap(Filter.init))
    update(updatedFilters, forGroupWithID: groupID)
  }
  
  /// Removes filter from a specified group
  /// - parameter filter: filter to remove
  /// - parameter groupID: target group ID
  /// - returns: true if removal succeeded, otherwise returns false

  @discardableResult mutating func remove<T: FilterType>(_ filter: T, fromGroupWithID groupID: FilterGroup.ID) -> Bool {
    return removeAll([filter], fromGroupWithID: groupID)
  }
  
  /// Removes a sequence of filters from a specified group
  /// - parameter filters: sequence of filters to remove
  /// - parameter groupID: target group ID
  /// - returns: true if at least one filter in filters sequence is contained by a specified group and so has been removed, otherwise returns false

  @discardableResult mutating func removeAll<T: FilterType, S: Sequence>(_ filters: S, fromGroupWithID groupID: FilterGroup.ID) -> Bool where S.Element == T {
    let filtersToRemove = filters.compactMap(Filter.init)
    guard let existingFilters = groups[groupID], !existingFilters.isDisjoint(with: filtersToRemove) else {
      return false
    }
    let updatedFilters = existingFilters.subtracting(filtersToRemove)
    update(updatedFilters, forGroupWithID: groupID)
    return true
  }
  
  /// Removes all filters from a specifed group
  /// - parameter group: target group ID
  
  mutating func removeAll(fromGroupWithID groupID: FilterGroup.ID) {
    groups.removeValue(forKey: groupID)
  }
  
  /// Removes filter from all the groups
  /// - parameter filter: filter to remove
  /// - returns: true if specified filter has been removed from at least one group, otherwise returns false

  @discardableResult mutating func remove<T: FilterType>(_ filter: T) -> Bool {
    return groups.map { remove(filter, fromGroupWithID: $0.key) }.reduce(false) { $0 || $1 }
  }
  
  /// Removes a sequence of filters from all the groups
  /// - parameter filters: sequence of filters to remove
  
  mutating func removeAll<T: FilterType, S: Sequence>(_ filters: S) where S.Element == T {
    let anyFilters = filters.compactMap(Filter.init)
    groups.keys.forEach { group in
      let existingFilters = groups[group] ?? []
      let updatedFilters = existingFilters.subtracting(anyFilters)
      update(updatedFilters, forGroupWithID: group)
    }
  }
  
  /// Removes all filters with specified attribute in a specified group
  /// - parameter attribute: target attribute
  /// - parameter groupID: target group ID
  
  mutating func removeAll(for attribute: Attribute, fromGroupWithID groupID: FilterGroup.ID) {
    guard let filtersForGroup = groups[groupID] else { return }
    let updatedFilters = filtersForGroup.filter { $0.filter.attribute != attribute }
    update(updatedFilters, forGroupWithID: groupID)
  }
  
  /// Removes all filters with specified attribute in all the groups
  /// - parameter attribute: target attribute
  
  mutating func removeAll(for attribute: Attribute) {
    groups.keys.forEach { group in
      removeAll(for: attribute, fromGroupWithID: group)
    }
  }
  
  /// Removes all filters from all the groups
  
  mutating func removeAll() {
    groups.removeAll()
  }
  
  /// Removes filter from group if contained by it, otherwise adds filter to group
  /// - parameter filter: filter to toggle
  /// - parameter groupID: target group ID
  
  mutating func toggle<T: FilterType>(_ filter: T, inGroupWithID groupID: FilterGroup.ID) {
    if contains(filter, inGroupWithID: groupID) {
      remove(filter, fromGroupWithID: groupID)
    } else {
      add(filter, toGroupWithID: groupID)
    }
  }
  
}

// MARK: Convenient methods for search for facet values and search disjunctive faceting

extension FilterState {
  
  /// Returns a set of attributes suitable for disjunctive faceting
  func getDisjunctiveFacetsAttributes() -> Set<Attribute> {
    let attributes = groups
      .filter { $0.key.isDisjunctive }
      .compactMap { $0.value }
      .flatMap { $0 }
      .map { $0.filter.attribute }
    return Set(attributes)
    
  }
  
  /// Returns a Boolean value indicating if FilterState contains attributes suitable for disjunctive faceting
  func isDisjunctiveFacetingAvailable() -> Bool {
    return !getDisjunctiveFacetsAttributes().isEmpty
  }
  
  /// Returns a dictionary of all facet filters with their associated values
  func getFacetFilters() -> [Attribute: Set<Filter.Facet.ValueType>] {
    let facetFilters: [Filter.Facet] = groups
      .compactMap { $0.value }
      .flatMap { $0 }.compactMap { filter in
        guard case .facet(let filterFacet) = filter else {
          return nil
        }
        return filterFacet
    }
    var refinements: [Attribute: Set<Filter.Facet.ValueType>] = [:]
    for filter in facetFilters {
      let existingValues = refinements[filter.attribute, default: []]
      let updatedValues = existingValues.union([filter.value])
      refinements[filter.attribute] = updatedValues
    }
    return refinements
  }
  
  /// Returns a raw representaton of all facet filters with their associated values
  func getRawFacetFilters() -> [String: [String]] {
    return getFacetFilters()
      .map { ($0.key.name, $0.value.map { $0.description }) }
      .reduce([String: [String]]()) { (refinements, arg1) in
        let (attribute, values) = arg1
        return refinements.merging([attribute: values], uniquingKeysWith: { (_, new) -> [String] in
          new
        })
      }
  }
  
}

public extension FilterState {
  
  func getFilterGroups() -> [FilterGroupType] {
    
    // There is a need to sort groups and filters in them for
    // getting a constant output of converters
    
    let filterComparator: (Filter, Filter) -> Bool = {
      let converter = SQLFilterConverter()
      let lhsString = converter.convert($0)
      let rhsString = converter.convert($1)
      return lhsString < rhsString
    }
    
    let groupIDComparator: (FilterGroup.ID, FilterGroup.ID) -> Bool = {
      guard $0.name != $1.name else {
        switch ($0, $1) {
        case (.or, .and):
          return true
        default:
          return false
        }
      }
      return $0.name < $1.name
    }
    
    let transform: (FilterGroup.ID, Set<Filter>) -> FilterGroupType? = { (groupID, filters) in
      guard let firstFilter = filters.first else {
        return nil
      }
      
      let sortedFilters = filters.sorted(by: filterComparator)
      
      switch groupID {
      case .and:
        return FilterGroup.And(filters: sortedFilters.map { $0.filter })
      case .or:
        switch firstFilter {
        case .facet:
          return FilterGroup.Or(filters: sortedFilters.compactMap { $0.filter as? Filter.Facet })
        case .numeric:
          return FilterGroup.Or(filters: sortedFilters.compactMap { $0.filter as? Filter.Numeric })
        case .tag:
          return FilterGroup.Or(filters: sortedFilters.compactMap { $0.filter as? Filter.Tag })
        }
      }
    }
    
    return groups
      .sorted(by: { groupIDComparator($0.key, $1.key) })
      .compactMap(transform)
    
  }
  
}
