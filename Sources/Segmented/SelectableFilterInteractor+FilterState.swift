//
//  SelectableSegmentInteractor+Filter+FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public struct SelectableFilterInteractorFilterStateConnection<Filter: FilterType>: Connection {
  
  public typealias Interactor = SelectableSegmentInteractor<Int, Filter>
  
  public let interactor: Interactor
  public let filterState: FilterState
  public let attribute: Attribute
  public let `operator`: RefinementOperator
  public let groupName: String
  
  public init(interactor: Interactor,
              filterState: FilterState,
              attribute: Attribute,
              `operator`: RefinementOperator,
              groupName: String? = nil) {
    self.interactor = interactor
    self.filterState = filterState
    self.attribute = attribute
    self.operator = `operator`
    self.groupName = groupName ?? attribute.name
  }
  
  public func connect() {
    switch `operator` {
    case .and:
      connectFilterState(filterState, to: interactor, via: SpecializedAndGroupAccessor(filterState[and: groupName]))
    case .or:
      connectFilterState(filterState, to: interactor, via: filterState[or: groupName])
    }
  }
  
  public func disconnect() {
    interactor.onSelectedComputed.cancelSubscription(for: filterState)
    filterState.onChange.cancelSubscription(for: interactor)
  }
  
  private func connectFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                      to interactor: Interactor,
                                                              
                                                                      via accessor: Accessor) where Accessor.Filter == Filter {
    whenSelectedComputedThenUpdateFilterState(interactor: interactor, filterState: filterState, via: accessor)
    whenFilterStateChangedThenUpdateSelected(interactor: interactor, filterState: filterState, via: accessor)
  }
  
  private func whenSelectedComputedThenUpdateFilterState<Accessor: SpecializedGroupAccessor>(interactor: Interactor,
                                                                                             filterState: FilterState,
                                                                                     
                                                                                             via accessor: Accessor) where Accessor.Filter == Filter {
    
    let removeSelectedItem = { [weak interactor] in
      interactor?.selected.flatMap { interactor?.items[$0] }.flatMap(accessor.remove)
    }
    
    let addItem: (Int?) -> Void = { [weak interactor] itemKey in
      itemKey.flatMap { interactor?.items[$0] }.flatMap { accessor.add($0) }
    }
    
    interactor.onSelectedComputed.subscribePast(with: filterState) { filterState, computedSelectionKey in
      removeSelectedItem()
      addItem(computedSelectionKey)
      filterState.notifyChange()
    }
    
  }
  
  private func whenFilterStateChangedThenUpdateSelected<Accessor: SpecializedGroupAccessor>(interactor: Interactor,
                                                                                            filterState: FilterState,
                                                                                            via accessor: Accessor) where Accessor.Filter == Filter {
    let onChange: (Interactor, ReadOnlyFiltersContainer) -> Void = { interactor, _ in
      interactor.selected = interactor.items.first(where: { accessor.contains($0.value) })?.key
    }
    
    onChange(interactor, ReadOnlyFiltersContainer(filtersContainer: filterState))
    
    filterState.onChange.subscribePast(with: interactor, callback: onChange)
  }

}

public extension SelectableSegmentInteractor where SegmentKey == Int, Segment: FilterType {

  @discardableResult func connectFilterState(_ filterState: FilterState,
                                             attribute: Attribute,
                                             operator: RefinementOperator,
                                             groupName: String? = nil) -> SelectableFilterInteractorFilterStateConnection<Segment> {
    let connection = SelectableFilterInteractorFilterStateConnection(interactor: self, filterState: filterState, attribute: attribute, operator: `operator`, groupName: groupName)
    connection.connect()
    return connection
  }
  
}
