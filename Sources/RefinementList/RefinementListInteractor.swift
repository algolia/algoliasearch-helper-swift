//
//  RefinementListFilterHandler.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 28/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol RefinementListInteractorDelegate {
  func didSelect(value: String, operator: RefinementListViewModel.Settings.RefinementOperator)
  func isRefined(value: String, operator: RefinementListViewModel.Settings.RefinementOperator) -> Bool
  func selectedValues(operator: RefinementListViewModel.Settings.RefinementOperator) -> [String]
}

/// Business logic for the different actions on the Refinement list related to filtering.
/// Mainly, the onSelect action, and determining if a certain value is selected or not.
class RefinementListInteractor: RefinementListInteractorDelegate {

  let filterState: FilterState
  let attribute: Attribute
  let group: Group

  private var orGroup: FilterGroup.Or<Filter.Facet>.ID {
    return FilterGroup.Or.ID(name: group.name)
  }

  private var andGroup: FilterGroup.And.ID {
    return FilterGroup.And.ID(name: group.name)
  }

  public init(attribute: Attribute, filterState: FilterState, group: Group) {
    self.filterState = filterState
    self.group = group
    self.attribute = attribute
  }

  public func didSelect(value: String, operator: RefinementListViewModel.Settings.RefinementOperator) {
    let filterFacet = Filter.Facet(attribute: attribute, stringValue: value)

    switch `operator` {
    case .or:
      filterState.toggle(filterFacet, in: orGroup)
    case .and(.multiple):
      filterState.toggle(filterFacet, in: andGroup)
    case .and(selection: .single):
      if filterState.contains(filterFacet, in: orGroup) {
        filterState.remove(filterFacet, from: orGroup)
      } else {
        filterState.removeAll(from: orGroup)
        filterState.add(filterFacet, to: orGroup)
      }
    }
  }

  public func isRefined(value: String, operator: RefinementListViewModel.Settings.RefinementOperator) -> Bool {
    let filterFacet = Filter.Facet(attribute: attribute, stringValue: value)

    switch `operator` {
    case .or, .and(selection: .single):
      return filterState.contains(filterFacet, in: orGroup)
    case .and(selection: .multiple):
      return filterState.contains(filterFacet, in: andGroup)
    }
  }

  public func selectedValues(operator: RefinementListViewModel.Settings.RefinementOperator) -> [String] {
    let refinedFilterFacets: [Filter.Facet]
    switch `operator` {
    case .or, .and(selection: .single):
      refinedFilterFacets = filterState.getFilter(for: orGroup).compactMap { $0.filter as? Filter.Facet }
    case .and(selection: .multiple):
      refinedFilterFacets = filterState.getFilter(for: andGroup).compactMap { $0.filter as? Filter.Facet }
    }
    return refinedFilterFacets.map { $0.value.description }
  }
}