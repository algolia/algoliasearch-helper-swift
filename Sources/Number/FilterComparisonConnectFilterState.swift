//
//  FilterComparisonConnectFilterState.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 04/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension NumberInteractor {
  
  func connectFilterState(_ filterState: FilterState,
                          attribute: Attribute,
                          numericOperator: Filter.Numeric.Operator, 
                          operator: RefinementOperator = .and,
                          groupName: String? = nil) {

    let groupName = groupName ?? attribute.name
    
    switch `operator` {
    case .and:
      connectFilterState(filterState, attribute: attribute, numericOperator: numericOperator, via: SpecializedAndGroupAccessor(filterState[and: groupName]))
    case .or:
      connectFilterState(filterState, attribute: attribute, numericOperator: numericOperator, via: filterState[or: groupName] )
    }

  }
  
  private func connectFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                      attribute: Attribute,
                                                                      numericOperator: Filter.Numeric.Operator,
                                                                      via accessor: Accessor) where Accessor.Filter == Filter.Numeric {
    whenFilterStateChangedUpdateExpression(filterState, attribute: attribute, numericOperator: numericOperator, accessor: accessor)
    whenExpressionComputedUpdateFilterState(filterState, attribute: attribute, numericOperator: numericOperator, accessor: accessor)
  }
  
  private func whenFilterStateChangedUpdateExpression<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                          attribute: Attribute,
                                                                                          numericOperator: Filter.Numeric.Operator,
                                                                                          accessor: Accessor) where Accessor.Filter == Filter.Numeric {
    
    func extractValue(from numericFilter: Filter.Numeric) -> Number? {
      if case .comparison(numericOperator, let value) = numericFilter.value {
        return Number(value)
      } else {
        return nil
      }
    }
    
    filterState.onChange.subscribePast(with: self) { [weak self] _ in
      self?.item = accessor.filters(for: attribute).compactMap(extractValue).first
    }
    
  }
  
  private func whenExpressionComputedUpdateFilterState<P: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                    attribute: Attribute,
                                                                                    numericOperator: Filter.Numeric.Operator,
                                                                                    accessor: P) where P.Filter == Filter.Numeric {
    
    let removeCurrentItem = { [weak self] in
      guard let item = self?.item else { return }
      let filter = Filter.Numeric(attribute: attribute, operator: numericOperator, value: item.toFloat())
      accessor.remove(filter)
    }
    
    let addItem: (Number?) -> Void = { value in
      guard let value = value else { return }
      let filter = Filter.Numeric(attribute: attribute, operator: numericOperator, value: value.toFloat())
      accessor.add(filter)
    }
    
    onNumberComputed.subscribePast(with: self) { [weak filterState] computed in
      removeCurrentItem()
      addItem(computed)
      filterState?.notifyChange()
    }
    
  }
  
}
