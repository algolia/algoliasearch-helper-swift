//
//  SingleIndexSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import AlgoliaSearchClientSwift
/** An entity performing search queries targeting one index
*/

public class SingleIndexSearcher: Searcher, SequencerDelegate, SearchResultObservable {
  
  public typealias SearchResult = SearchResults
  
  public var query: String? {

    set {
      let oldValue = indexQueryState.query.query
      guard oldValue != newValue else { return }
      cancel()
      indexQueryState.query.query = newValue
      indexQueryState.query.page = 0
      onQueryChanged.fire(newValue)
    }
    
    get {
      return indexQueryState.query.query
    }

  }
  
  public let client: Client
  
  /// Current index & query tuple
  public var indexQueryState: IndexQueryState {
    didSet {
      if oldValue.index != indexQueryState.index {
        onIndexChanged.fire(indexQueryState.index)
      }
    }
  }
  
  public let isLoading: Observer<Bool>
  
  public let onResults: Observer<SearchResults>
  
  /// Triggered when an error occured during search query execution
  /// - Parameter: a tuple of query and error
  public let onError: Observer<(Query, Error)>
  
  public let onQueryChanged: Observer<String?>
  
  /// Triggered when an index of Searcher changed
  /// - Parameter: equals to a new index value
  public let onIndexChanged: Observer<Index>
  
  /// Custom request options
  public var requestOptions: RequestOptions?
  
  /// Delegate providing a necessary information for disjuncitve faceting
  public weak var disjunctiveFacetingDelegate: DisjunctiveFacetingDelegate?
  
  /// Delegate providing a necessary information for hierarchical faceting
  public weak var hierarchicalFacetingDelegate: HierarchicalFacetingDelegate?
  
  /// Flag defining if disjunctive faceting is enabled
  /// - Default value: true
  public var isDisjunctiveFacetingEnabled = true
  
  /// Sequencer which orders and debounce redundant search operations
  internal let sequencer: Sequencer
  
  private let processingQueue: OperationQueue
  
  /**
   - Parameters:
      - appID: Application ID
      - apiKey: API Key
      - indexName: Name of the index in which search will be performed
      - query: Instance of Query. By default a new empty instant of Query will be created.
      - requestOptions: Custom request options. Default is `nil`.
  */
  public convenience init(appID: ApplicationID,
                          apiKey: APIKey,
                          indexName: IndexName,
                          query: Query = .init(),
                          requestOptions: RequestOptions? = nil) {
    let client = Client(appID: appID, apiKey: apiKey)
    let index = client.index(withName: indexName)
    self.init(client: client, index: index, query: query, requestOptions: requestOptions)
  }
  
  /**
   - Parameters:
      - index: Index value in which search will be performed
      - query: Instance of Query. By default a new empty instant of Query will be created.
      - requestOptions: Custom request options. Default is nil.
  */
  public init(client: Client,
              index: Index,
              query: Query = .init(),
              requestOptions: RequestOptions? = nil) {
    self.client = client
    indexQueryState = .init(index: index, query: query)
    self.requestOptions = requestOptions
    sequencer = .init()
    isLoading = .init()
    onResults = .init()
    onError = .init()
    onQueryChanged = .init()
    onIndexChanged = .init()
    processingQueue = .init()
    sequencer.delegate = self
    onResults.retainLastData = true
    onError.retainLastData = false
    isLoading.retainLastData = true
    updateClientUserAgents()
    processingQueue.maxConcurrentOperationCount = 1
    processingQueue.qualityOfService = .userInitiated
  }
  
  /**
   - Parameters:
      - indexQueryState: Instance of `IndexQueryState` encapsulating index value in which search will be performed and a `Query` instance.
      - requestOptions: Custom request options. Default is nil.
   */
  public convenience init(client: Client,
                          indexQueryState: IndexQueryState,
                          requestOptions: RequestOptions? = nil) {
    self.init(client: client,
              index: indexQueryState.index,
              query: indexQueryState.query,
              requestOptions: requestOptions)
  }
  
  public func search() {
  
    let query = indexQueryState.query
    
    let operation: Operation

    if isDisjunctiveFacetingEnabled {
      let filterGroups = disjunctiveFacetingDelegate?.toFilterGroups() ?? []
      let hierarchicalAttributes = hierarchicalFacetingDelegate?.hierarchicalAttributes ?? []
      let hierarchicalFilters = hierarchicalFacetingDelegate?.hierarchicalFilters ?? []
      var queriesBuilder = QueryBuilder(query: query,
                                        filterGroups: filterGroups,
                                        hierarchicalAttributes: hierarchicalAttributes,
                                        hierachicalFilters: hierarchicalFilters)
      queriesBuilder.keepSelectedEmptyFacets = true
      let queries = queriesBuilder.build().map { (indexQueryState.index.name, query: $0) }
      operation = client.multipleQueries(queries: queries) { [weak self] result in
        guard let searcher = self else { return }
        
        searcher.processingQueue.addOperation {
            let indexName = searcher.indexQueryState.index.name

            switch result {
            case .failure(let error):
              Logger.Results.failure(searcher: searcher, indexName: indexName, error)
              searcher.onError.fire((queriesBuilder.query, error))
              
            case .success(let results):
              do {
                let result = try queriesBuilder.aggregate(results.results)
                Logger.Results.success(searcher: searcher, indexName: indexName, results: result)
                searcher.onResults.fire(result)
              } catch let error {
                Logger.Results.failure(searcher: searcher, indexName: indexName, error)
                searcher.onError.fire((queriesBuilder.query, error))
              }
            }
        }
      }
    } else {
      operation = indexQueryState.index.search(query, requestOptions: requestOptions, completionHandler: handle(for: query))
    }
    
    sequencer.orderOperation(operationLauncher: { return operation })
  }
  
  public func cancel() {
    sequencer.cancelPendingOperations()
  }
  
}

private extension SingleIndexSearcher {
  
  func handle(for query: Query) -> (_ value: [String: Any]?, _ error: Error?) -> Void {
    return { [weak self] value, error in
      guard let searcher = self, searcher.query == query.query else { return }
      
      searcher.processingQueue.addOperation {
        let result = Result<SearchResults, Error>(rawValue: value, error: error)
  
        let indexName = searcher.indexQueryState.index.name
        
        switch result {
        case .success(let results):
          Logger.Results.success(searcher: searcher, indexName: indexName.rawValue, results: results)
          searcher.onResults.fire(results)
          
        case .failure(let error):
          Logger.Results.failure(searcher: searcher, indexName: indexName, error)
          searcher.onError.fire((query, error))
        }
      }
    }
  }
  
  func handleDisjunctiveFacetingResponse(for queryBuilder: QueryBuilder) -> (_ value: [String: Any]?, _ error: Error?) -> Void {
    return { [weak self] value, error in
      guard let searcher = self, searcher.query == queryBuilder.query.query else { return }
      
      searcher.processingQueue.addOperation {
        let result = Result<MultiSearchResults, Error>(rawValue: value, error: error)

        let indexName = searcher.indexQueryState.index.name

        switch result {
        case .failure(let error):
          Logger.Results.failure(searcher: searcher, indexName: indexName, error)
          searcher.onError.fire((queryBuilder.query, error))
          
        case .success(let results):
          do {
            let result = try queryBuilder.aggregate(results.searchResults)
            Logger.Results.success(searcher: searcher, indexName: indexName, results: result)
            searcher.onResults.fire(result)
          } catch let error {
            Logger.Results.failure(searcher: searcher, indexName: indexName, error)
            searcher.onError.fire((queryBuilder.query, error))
          }
        }
      }
      
    }
  }
  
}
