//
//  Copyright (c) 2016 Algolia
//  http://www.algolia.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import AlgoliaSearch
import Foundation


/// Match level of a highlight or snippet result (internal version).
enum MatchLevel_: String {
    case Full = "full"
    case Partial = "partial"
    case None = "none"
}

/// Match level of a highlight or snippet result.
@objc public enum MatchLevel: Int {
    case Full = 2
    case Partial = 1
    case None = 0
}

/// Convert a pure Swift enum into an Objective-C bridgeable one.
func swift2Objc(matchLevel: MatchLevel_?) -> MatchLevel {
    if let level = matchLevel {
        switch level {
        case .Full: return .Full
        case .Partial: return .Partial
        case .None: return .None
        }
    }
    return .None
}

/// Highlight result for an attribute of a hit.
///
/// **Note:** Wraps the raw JSON returned by the API.
///
@objc public class HighlightResult: NSObject {
    /// The wrapped JSON object.
    @objc public let json: [String: AnyObject]
    
    /// Value of this highlight.
    @objc public var value: String? { return json["value"] as? String }
    
    /// Match level.
    @objc public var matchLevel: MatchLevel { return swift2Objc(matchLevel_) }
    
    /// List of matched words.
    @objc public var matchedWords: [String]? { return json["matchedWords"] as? [String] }
    
    var matchLevel_: MatchLevel_? {
        if let matchLevelString = json["matchLevel"] as? String {
            return MatchLevel_(rawValue: matchLevelString)
        } else {
            return nil
        }
    }
    
    init(json: [String: AnyObject]) {
        self.json = json
    }
}

/// Snippet result for an attribute of a hit.
///
/// **Note:** Wraps the raw JSON returned by the API.
///
@objc public class SnippetResult: NSObject {
    /// The wrapped JSON object.
    @objc public let json: [String: AnyObject]
    
    /// Value of this snippet.
    @objc public var value: String? { return json["value"] as? String }
    
    /// Match level.
    @objc public var matchLevel: MatchLevel { return swift2Objc(matchLevel_) }
    
    var matchLevel_: MatchLevel_? {
        if let matchLevelString = json["matchLevel"] as? String {
            return MatchLevel_(rawValue: matchLevelString)
        } else {
            return nil
        }
    }

    init(json: [String: AnyObject]) {
        self.json = json
    }
}

/// Ranking info for a hit.
///
/// **Note:** Wraps the raw JSON returned by the API.
///
@objc public class RankingInfo: NSObject {
    /// The wrapped JSON object.
    @objc public let json: [String: AnyObject]
    
    @objc public var nbTypos: Int { return json["nbTypos"] as? Int ?? 0 }
    @objc public var firstMatchedWord: Int { return json["firstMatchedWord"] as? Int ?? 0 }
    @objc public var proximityDistance: Int { return json["proximityDistance"] as? Int ?? 0 }
    @objc public var userScore: Int { return json["userScore"] as? Int ?? 0 }
    @objc public var geoDistance: Int { return json["geoDistance"] as? Int ?? 0 }
    @objc public var geoPrecision: Int { return json["geoPrecision"] as? Int ?? 0 }
    @objc public var nbExactWords: Int { return json["nbExactWords"] as? Int ?? 0 }
    @objc public var words: Int { return json["words"] as? Int ?? 0 }
    @objc public var filters: Int { return json["filters"] as? Int ?? 0 }
    
    init(json: [String: AnyObject]) {
        self.json = json
    }
}

/// A value of a given facet, together with its number of occurrences.
///
@objc public class FacetValue: NSObject {
    @objc public let value: String
    @objc public let count: Int
    
    init(value: String, count: Int) {
        self.value = value
        self.count = count
    }
}


/// Search results.
///
/// **Note:** Wraps the raw JSON returned by the API.
///
@objc public class SearchResults: NSObject {
    /// The last received JSON content.
    /// Either that passed to the initializer, or that last passed to `add()`.
    @objc public private(set) var lastContent: [String: AnyObject]
    
    /// Facets that will be treated as disjunctive (`OR`). By default, facets are conjunctive (`AND`).
    @objc public let disjunctiveFacets: [String]

    /// Hits for all the received pages.
    @objc public private(set) var hits: [[String: AnyObject]] = []
    
    /// Facets for the last results. Lazily computed; accessed through `facets()`.
    private var facets: [String: [FacetValue]] = [:]

    /// Total number of hits.
    @objc public var nbHits: Int { return lastContent["nbHits"] as? Int ?? 0 }

    /// Last returned page.
    @objc public var page: Int { return lastContent["page"] as? Int ?? 0 }

    /// Total number of pages.
    @objc public var nbPages: Int { return lastContent["nbPages"] as? Int ?? 0 }
    
    /// Number of hits per page.
    @objc public var hitsPerPage: Int { return lastContent["hitsPerPage"] as? Int ?? 0 }
    
    /// Processing time of the last query (in ms).
    @objc public var processingTimeMS: Int { return lastContent["processingTimeMS"] as? Int ?? 0 }
    
    /// Whether facet counts are exhaustive.
    @objc public var exhaustiveFacetsCount: Bool { return lastContent["exhaustiveFacetsCount"] as? Bool ?? false }
    
    /// Query corresponding to the last results.
    /// WARNING: Do not modify it!
    ///
    @objc public private(set) var lastQuery: Query = Query()

    // MARK: - Initialization, termination
    
    /// Create search results from an initial response from the API.
    init(content: [String: AnyObject], disjunctiveFacets: [String]) {
        self.lastContent = content
        self.disjunctiveFacets = disjunctiveFacets
        self.hits = content["hits"] as? [[String: AnyObject]] ?? [[String: AnyObject]]()
        super.init()
        updateLastQuery(content)
    }
    
    /// Add a new page to the results.
    func add(content: [String: AnyObject]) {
        if let hits = content["hits"] as? [[String: AnyObject]] {
            self.hits.appendContentsOf(hits)
        }
        self.facets.removeAll() // TODO: Should we really parse facets from start again?
        updateLastQuery(content)
    }
    
    private func updateLastQuery(content: [String: AnyObject]) {
        if let queryString = content["params"] as? String {
            self.lastQuery = Query.parse(queryString)
        } else {
            // TODO: Suboptimal: should propagate error.
        }
    }
    
    // MARK: - Accessors
    
    /// Retrieve the facet values for a given facet.
    ///
    /// - parameter name: Facet name.
    /// - parameter disjunctive: true if this is a disjunctive facet, false if it's a conjunctive facet (default).
    /// - returns: The corresponding facet values.
    ///
    @objc public func facets(name: String) -> [FacetValue]? {
        // Use stored values if available.
        if let values = facets[name] {
            return values
        }
        // Otherwise lazily compute the values.
        else {
            let disjunctive = disjunctiveFacets.contains(name)
            guard let returnedFacets = lastContent[disjunctive ? "disjunctiveFacets" : "facets"] as? [String: AnyObject] else { return nil }
            var values = [FacetValue]()
            let returnedValues = returnedFacets[name] as? [String: Int]
            if let returnedValues = returnedValues {
                for (value, count) in returnedValues {
                    values.append(FacetValue(value: value, count: count))
                }
            }
            // Make sure there is a value at least for the refined values.
            let queryHelper = QueryHelper(query: lastQuery)
            let facetRefinements = queryHelper.getFacetRefinements() { $0.name == name }
            for facetRefinement in facetRefinements {
                if returnedValues?[facetRefinement.value] == nil {
                    values.append(FacetValue(value: facetRefinement.value, count: 0))
                }
            }
            // Remember values for later use.
            self.facets[name] = values
            return values
        }
    }
    
    /// Get the highlight result for an attribute of a hit.
    @objc public func highlightResult(index: Int, path: String) -> HighlightResult? {
        return SearchResults.getHighlightResult(hits[index], path: path)
    }

    /// Get the snippet result for an attribute of a hit.
    @objc public func snippetResult(index: Int, path: String) -> SnippetResult? {
        return SearchResults.getSnippetResult(hits[index], path: path)
    }

    /// Get the ranking information for a hit.
    ///
    /// **Note:** Only available when `getRankingInfo` was set to true on the query.
    ///
    /// - parameter index: Index of the hit in the hits array.
    /// - returns: The corresponding ranking information, or nil if no ranking information is available.
    ///
    public func rankingInfo(index: Int) -> RankingInfo? {
        if let rankingInfo = hits[index]["_rankingInfo"] as? [String: AnyObject] {
            return RankingInfo(json: rankingInfo)
        } else {
            return nil
        }
    }
    
    // MARK: - Utils
    
    /// Retrieve the highlight result corresponding to an attribute inside the JSON representation of a hit.
    ///
    /// - parameter hit: The JSON object for a hit.
    /// - parameter path: Path of the attribute to retrieve, in dot notation.
    /// - returns: The highlight result, or nil if not available.
    ///
    public static func getHighlightResult(hit: [String: AnyObject], path: String) -> HighlightResult? {
        guard let highlights = hit["_highlightResult"] as? [String: AnyObject] else { return nil }
        guard let attribute = JSONHelper.valueForKeyPath(highlights, path: path) as? [String: AnyObject] else { return nil }
        return HighlightResult(json: attribute)
    }
    
    /// Retrieve the snippet result corresponding to an attribute inside the JSON representation of a hit.
    ///
    /// - parameter hit: The JSON object for a hit.
    /// - parameter path: Path of the attribute to retrieve, in dot notation.
    /// - returns: The snippet result, or nil if not available.
    ///
    public static func getSnippetResult(hit: [String: AnyObject], path: String) -> SnippetResult? {
        guard let snippets = hit["_snippetResult"] as? [String: AnyObject] else { return nil }
        guard let attribute = JSONHelper.valueForKeyPath(snippets, path: path) as? [String: AnyObject] else { return nil }
        return SnippetResult(json: attribute)
    }
}
