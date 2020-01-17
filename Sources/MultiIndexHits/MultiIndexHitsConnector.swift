//
//  MultiIndexHitsConnector.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/12/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class MultiIndexHitsConnector: Connection {
  
  public let searcher: MultiIndexSearcher
  public let interactor: MultiIndexHitsInteractor
  public let filterStates: [FilterState?]
  public let filterStatesConnections: [Connection]
  public let searcherConnection: Connection
  
  public init(searcher: MultiIndexSearcher,
              interactor: MultiIndexHitsInteractor,
              filterStates: [FilterState?]) {
    self.searcher = searcher
    self.interactor = interactor
    self.filterStates = filterStates
    self.searcherConnection = interactor.connectSearcher(searcher)
    self.filterStatesConnections = zip(interactor.hitsInteractors, filterStates).compactMap { arg in
      let (interactor, filterState) = arg
      return filterState.flatMap(interactor.connectFilterState)
    }
  }
  
  public func connect() {
    searcherConnection.connect()
    filterStatesConnections.forEach { $0.connect() }
  }
  
  public func disconnect() {
    searcherConnection.disconnect()
    filterStatesConnections.forEach { $0.disconnect() }
  }
  
}

public extension MultiIndexHitsConnector {
  
  struct IndexModule {
    
    public let name: String
    public let hitsInteractor: AnyHitsInteractor
    public let filterState: FilterState?
    
    public init<Hit: Codable>(name: String,
                              hitsInteractor: HitsInteractor<Hit>,
                              filterState: FilterState? = .none) {
      self.name = name
      self.hitsInteractor = hitsInteractor
      self.filterState = filterState
    }
    
  }
  
  convenience init(appID: String, apiKey: String, indexModules: [IndexModule]) {
    let searcher = MultiIndexSearcher(appID: appID, apiKey: apiKey, indexNames: indexModules.map { $0.name })
    let interactor = MultiIndexHitsInteractor(hitsInteractors: indexModules.map { $0.hitsInteractor })
    self.init(searcher: searcher, interactor: interactor, filterStates: indexModules.map { $0.filterState })
  }
  
}
