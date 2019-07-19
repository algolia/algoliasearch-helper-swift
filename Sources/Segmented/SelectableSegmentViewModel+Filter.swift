//
//  SelectableSegmentViewModel+Filter.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 13/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension SelectableSegmentViewModel where SegmentKey == Int, Segment: FilterType {

  func connectSearcher(_ searcher: SingleIndexSearcher, attribute: Attribute) {
    searcher.indexSearchData.query.updateQueryFacets(with: attribute)
  }
  
  func connectFilterState(_ filterState: FilterState,
                          attribute: Attribute,
                          operator: RefinementOperator,
                          groupName: String? = nil) {
    
    let groupName = groupName ?? attribute.name
    
    switch `operator` {
    case .and:
      connectFilterState(filterState, via: SpecializedAndGroupAccessor(filterState[and: groupName]))
    case .or:
      connectFilterState(filterState, via: filterState[or: groupName])
    }

  }
  
  private func connectFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                      via accessor: Accessor) where Accessor.Filter == Segment {
    whenSelectedComputedThenUpdateFilterState(filterState, via: accessor)
    whenFilterStateChangedThenUpdateSelected(filterState, via: accessor)
  }
  
  private func whenSelectedComputedThenUpdateFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                             via accessor: Accessor) where Accessor.Filter == Segment {
    
    let removeSelectedItem = { [weak self] in
      self?.selected.flatMap { self?.items[$0] }.flatMap(accessor.remove)
    }
    
    let addItem: (SegmentKey?) -> Void = { [weak self] itemKey in
      itemKey.flatMap { self?.items[$0] }.flatMap(accessor.add)
    }
    
    onSelectedComputed.subscribePast(with: self) { [weak filterState] computedSelectionKey in
      removeSelectedItem()
      addItem(computedSelectionKey)
      filterState?.notifyChange()
    }
    
  }
    
  private func whenFilterStateChangedThenUpdateSelected<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                            via accessor: Accessor) where Accessor.Filter == Segment {
    let onChange: (ReadOnlyFiltersContainer) -> Void = { [weak self] _ in
      self?.selected = self?.items.first(where: { accessor.contains($0.value) })?.key
    }
    
    onChange(ReadOnlyFiltersContainer(filtersContainer: filterState))
    
    filterState.onChange.subscribePast(with: self, callback: onChange)
  }
  
}

public extension SelectableSegmentViewModel where Segment: FilterType {
  
  func connectController<C: SelectableSegmentController>(_ controller: C, presenter: FilterPresenter? = .none) where C.SegmentKey == SegmentKey {
    
    func setControllerItems(with items: [SegmentKey: Segment]) {
      let presenter = presenter ?? DefaultFilterPresenter.present
      let itemsToPresent = items
        .map { ($0.key, presenter(Filter($0.value))) }
        .reduce(into: [:]) { $0[$1.0] = $1.1 }
      controller.setItems(items: itemsToPresent)
    }
    
    setControllerItems(with: items)
    controller.setSelected(selected)
    controller.onClick = computeSelected(selecting:)
    onSelectedChanged.subscribePast(with: controller, callback: controller.setSelected)
    onItemsChanged.subscribePast(with: controller, callback: setControllerItems)
    
  }
  
}
