import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif


public struct Documents {
    var apiCall: ApiCall
    var collectionName: String

    init(apiCall: ApiCall, collectionName: String) {
        self.apiCall = apiCall
        self.collectionName = collectionName
    }

    public func create(document: Data, options: DocumentIndexParameters? = nil) async throws -> (Data?, URLResponse?) {
        let queryParams = try createURLQuery(forSchema: options)
        let (data, response) = try await apiCall.post(endPoint: endpointPath(), body: document, queryParameters: queryParams)
        return (data, response)
    }

    public func upsert(document: Data, options: DocumentIndexParameters? = nil) async throws -> (Data?, URLResponse?) {
        var queryParams = try createURLQuery(forSchema: options)
        queryParams.append(URLQueryItem(name: "action", value: "upsert"))
        let (data, response) = try await apiCall.post(endPoint: endpointPath(), body: document, queryParameters: queryParams)
        return (data, response)
    }

    public func update<T: Codable>(document: T, options: DocumentIndexParameters? = nil) async throws -> (T?, URLResponse?) {
        var queryParams = try createURLQuery(forSchema: options)
        queryParams.append(URLQueryItem(name: "action", value: "update"))
        let jsonData = try encoder.encode(document)
        let (data, response) = try await apiCall.post(endPoint: endpointPath(), body: jsonData, queryParameters: queryParams)
        if let validData = data {
            let decodedData = try decoder.decode(T.self, from: validData)
            return (decodedData, response)
        }
        return (nil, response)
    }

    public func update<T: Encodable>(document: T, options: UpdateDocumentsByFilterParameters) async throws -> (UpdateByFilterResponse?, URLResponse?) {
        let queryParams = try createURLQuery(forSchema: options)
        let jsonData = try encoder.encode(document)
        let (data, response) = try await apiCall.patch(endPoint: endpointPath(), body: jsonData, queryParameters: queryParams)
        if let validData = data {
            let decodedData = try decoder.decode(UpdateByFilterResponse.self, from: validData)
            return (decodedData, response)
        }
        return (nil, response)
    }

    public func delete(options: DeleteDocumentsParameters) async throws -> (DeleteDocumentsResponse?, URLResponse?) {
        let queryParams = try createURLQuery(forSchema: options)
        let (data, response) = try await apiCall.delete(endPoint: endpointPath(), queryParameters: queryParams)
        if let validData = data {
            let decodedData = try decoder.decode(DeleteDocumentsResponse.self, from: validData)
            return (decodedData, response)
        }
        return (nil, response)
    }

    @available(*, deprecated, message: "Use `delete(options: DeleteDocumentsParameters)` instead!")
    public func delete(filter: String, batchSize: Int? = nil) async throws -> (Data?, URLResponse?) {
        var deleteQueryParams: [URLQueryItem] =
        [
            URLQueryItem(name: "filter_by", value: filter)
        ]
        if let givenBatchSize = batchSize {
            deleteQueryParams.append(URLQueryItem(name: "batch_size", value: String(givenBatchSize)))
        }
        let (data, response) = try await apiCall.delete(endPoint: endpointPath(), queryParameters: deleteQueryParams)
        return (data, response)

    }

    public func search(_ searchParameters: SearchParameters) async throws -> (Data?, URLResponse?) {
        let queryParams = try createURLQuery(forSchema: searchParameters)
        return try await apiCall.get(endPoint: endpointPath("search"), queryParameters: queryParams)
    }

    public func search<T>(_ searchParameters: SearchParameters, for: T.Type) async throws -> (SearchResult<T>?, URLResponse?) {
        var searchQueryParams: [URLQueryItem] = []

        if let q = searchParameters.q {
            searchQueryParams.append(URLQueryItem(name: "q", value: q))
        }

        if let queryBy = searchParameters.queryBy {
            searchQueryParams.append(URLQueryItem(name: "query_by", value: queryBy))
        }

        if let queryByWeights = searchParameters.queryByWeights {
            searchQueryParams.append(URLQueryItem(name: "query_by_weights", value: queryByWeights))
        }

        if let textMatchType = searchParameters.textMatchType {
            searchQueryParams.append(URLQueryItem(name: "text_match_type", value: textMatchType))
        }

        if let _prefix = searchParameters._prefix {
            searchQueryParams.append(URLQueryItem(name: "prefix", value: _prefix))
        }

        if let _infix = searchParameters._infix {
            searchQueryParams.append(URLQueryItem(name: "infix", value: _infix))
        }

        if let maxExtraPrefix = searchParameters.maxExtraPrefix {
            searchQueryParams.append(URLQueryItem(name: "max_extra_prefix", value: String(maxExtraPrefix)))
        }

        if let maxExtraSuffix = searchParameters.maxExtraSuffix {
            searchQueryParams.append(URLQueryItem(name: "max_extra_suffix", value: String(maxExtraSuffix)))
        }

        if let filterBy = searchParameters.filterBy {
            searchQueryParams.append(URLQueryItem(name: "filter_by", value: filterBy))
        }

        if let sortBy = searchParameters.sortBy {
            searchQueryParams.append(URLQueryItem(name: "sort_by", value: sortBy))
        }

        if let facetBy = searchParameters.facetBy {
            searchQueryParams.append(URLQueryItem(name: "facet_by", value: facetBy))
        }

        if let maxFacetValues = searchParameters.maxFacetValues {
            searchQueryParams.append(URLQueryItem(name: "max_facet_values", value: String(maxFacetValues)))
        }

        if let facetQuery = searchParameters.facetQuery {
            searchQueryParams.append(URLQueryItem(name: "facet_query", value: facetQuery))
        }

        if let numTypos = searchParameters.numTypos {
            searchQueryParams.append(URLQueryItem(name: "num_typos", value: String(numTypos)))
        }

        if let page = searchParameters.page {
            searchQueryParams.append(URLQueryItem(name: "page", value: String(page)))
        }

        if let perPage = searchParameters.perPage {
            searchQueryParams.append(URLQueryItem(name: "per_page", value: String(perPage)))
        }

        if let limit = searchParameters.limit {
            searchQueryParams.append(URLQueryItem(name: "limit", value: String(limit)))
        }

        if let offset = searchParameters.offset {
            searchQueryParams.append(URLQueryItem(name: "offset", value: String(offset)))
        }

        if let groupBy = searchParameters.groupBy {
            searchQueryParams.append(URLQueryItem(name: "group_by", value: groupBy))
        }

        if let groupLimit = searchParameters.groupLimit {
            searchQueryParams.append(URLQueryItem(name: "group_limit", value: String(groupLimit)))
        }

        if let groupMissingValues = searchParameters.groupMissingValues {
            searchQueryParams.append(URLQueryItem(name: "group_missing_values", value: String(groupMissingValues)))
        }

        if let includeFields = searchParameters.includeFields {
            searchQueryParams.append(URLQueryItem(name: "include_fields", value: includeFields))
        }

        if let excludeFields = searchParameters.excludeFields {
            searchQueryParams.append(URLQueryItem(name: "exclude_fields", value: excludeFields))
        }

        if let highlightFullFields = searchParameters.highlightFullFields {
            searchQueryParams.append(URLQueryItem(name: "highlight_full_fields", value: highlightFullFields))
        }

        if let highlightAffixNumTokens = searchParameters.highlightAffixNumTokens {
            searchQueryParams.append(URLQueryItem(name: "highlight_affix_num_tokens", value: String(highlightAffixNumTokens)))
        }

        if let highlightStartTag = searchParameters.highlightStartTag {
            searchQueryParams.append(URLQueryItem(name: "highlight_start_tag", value: highlightStartTag))
        }

        if let highlightEndTag = searchParameters.highlightEndTag {
            searchQueryParams.append(URLQueryItem(name: "highlight_end_tag", value: highlightEndTag))
        }

        if let enableHighlightV1 = searchParameters.enableHighlightV1 {
            searchQueryParams.append(URLQueryItem(name: "enable_highlight_v1", value: String(enableHighlightV1)))
        }

        if let snippetThreshold = searchParameters.snippetThreshold {
            searchQueryParams.append(URLQueryItem(name: "snippet_threshold", value: String(snippetThreshold)))
        }

        if let dropTokensThreshold = searchParameters.dropTokensThreshold {
            searchQueryParams.append(URLQueryItem(name: "drop_tokens_threshold", value: String(dropTokensThreshold)))
        }

        if let typoTokensThreshold = searchParameters.typoTokensThreshold {
            searchQueryParams.append(URLQueryItem(name: "typo_tokens_threshold", value: String(typoTokensThreshold)))
        }

        if let pinnedHits = searchParameters.pinnedHits {
            searchQueryParams.append(URLQueryItem(name: "pinned_hits", value: pinnedHits))
        }

        if let hiddenHits = searchParameters.hiddenHits {
            searchQueryParams.append(URLQueryItem(name: "hidden_hits", value: hiddenHits))
        }

        if let overrideTags = searchParameters.overrideTags {
            searchQueryParams.append(URLQueryItem(name: "override_tags", value: overrideTags))
        }

        if let highlightFields = searchParameters.highlightFields {
            searchQueryParams.append(URLQueryItem(name: "highlight_fields", value: highlightFields))
        }

        if let splitJoinTokens = searchParameters.splitJoinTokens {
            searchQueryParams.append(URLQueryItem(name: "split_join_tokens", value: splitJoinTokens))
        }

        if let preSegmentedQuery = searchParameters.preSegmentedQuery {
            searchQueryParams.append(URLQueryItem(name: "pre_segmented_query", value: String(preSegmentedQuery)))
        }

        if let preset = searchParameters.preset {
            searchQueryParams.append(URLQueryItem(name: "preset", value: preset))
        }

        if let enableOverrides = searchParameters.enableOverrides {
            searchQueryParams.append(URLQueryItem(name: "enable_overrides", value: String(enableOverrides)))
        }

        if let prioritizeExactMatch = searchParameters.prioritizeExactMatch {
            searchQueryParams.append(URLQueryItem(name: "prioritize_exact_match", value: String(prioritizeExactMatch)))
        }

        if let maxCandidates = searchParameters.maxCandidates {
            searchQueryParams.append(URLQueryItem(name: "max_candidates", value: String(maxCandidates)))
        }

        if let prioritizeTokenPosition = searchParameters.prioritizeTokenPosition {
            searchQueryParams.append(URLQueryItem(name: "prioritize_token_position", value: String(prioritizeTokenPosition)))
        }

        if let prioritizeNumMatchingFields = searchParameters.prioritizeNumMatchingFields {
            searchQueryParams.append(URLQueryItem(name: "prioritize_num_matching_fields", value: String(prioritizeNumMatchingFields)))
        }

        if let enableTyposForNumericalTokens = searchParameters.enableTyposForNumericalTokens {
            searchQueryParams.append(URLQueryItem(name: "enable_typos_for_numerical_tokens", value: String(enableTyposForNumericalTokens)))
        }

        if let exhaustiveSearch = searchParameters.exhaustiveSearch {
            searchQueryParams.append(URLQueryItem(name: "exhaustive_search", value: String(exhaustiveSearch)))
        }

        if let searchCutoffMs = searchParameters.searchCutoffMs {
            searchQueryParams.append(URLQueryItem(name: "search_cutoff_ms", value: String(searchCutoffMs)))
        }

        if let useCache = searchParameters.useCache {
            searchQueryParams.append(URLQueryItem(name: "use_cache", value: String(useCache)))
        }

        if let cacheTtl = searchParameters.cacheTtl {
            searchQueryParams.append(URLQueryItem(name: "cache_ttl", value: String(cacheTtl)))
        }

        if let minLen1typo = searchParameters.minLen1typo {
            searchQueryParams.append(URLQueryItem(name: "min_len1type", value: String(minLen1typo)))
        }

        if let minLen2typo = searchParameters.minLen2typo {
            searchQueryParams.append(URLQueryItem(name: "min_len2type", value: String(minLen2typo)))
        }

        if let vectorQuery = searchParameters.vectorQuery {
            searchQueryParams.append(URLQueryItem(name: "vector_query", value: vectorQuery))
        }

        if let remoteEmbeddingTimeoutMS = searchParameters.remoteEmbeddingTimeoutMs {
            searchQueryParams.append(URLQueryItem(name: "remote_embedding_timeout_ms", value: String(remoteEmbeddingTimeoutMS)))
        }

        if let remoteEmbeddingNumTries = searchParameters.remoteEmbeddingNumTries {
            searchQueryParams.append(URLQueryItem(name: "remote_embedding_num_tries", value: String(remoteEmbeddingNumTries)))
        }

        if let facetStrategy = searchParameters.facetStrategy {
            searchQueryParams.append(URLQueryItem(name: "facet_strategy", value: facetStrategy))
        }

        if let stopwords = searchParameters.stopwords {
            searchQueryParams.append(URLQueryItem(name: "stopwords", value: stopwords))
        }

        if let facetReturnParent = searchParameters.facetReturnParent {
            searchQueryParams.append(URLQueryItem(name: "facet_strategy", value: facetReturnParent))
        }

        let (data, response) = try await apiCall.get(endPoint: endpointPath("search"), queryParameters: searchQueryParams)

        if let validData = data {
            let searchRes = try decoder.decode(SearchResult<T>.self, from: validData)
            return (searchRes, response)
        }

        return (nil, response)
    }

    public func importBatch(_ documents: Data, options: ImportDocumentsParameters) async throws -> (Data?, URLResponse?) {
        let queryParams = try createURLQuery(forSchema: options)
        let (data, response) = try await apiCall.post(endPoint: endpointPath("import"), body: documents, queryParameters: queryParams)
        return (data, response)
    }

    @available(*, deprecated, message: "Use `importBatch(_ documents: Data, options: ImportDocumentsParameters)` instead!")
    public func importBatch(_ documents: Data, action: ActionModes? = ActionModes.create) async throws -> (Data?, URLResponse?) {
        var importAction = URLQueryItem(name: "action", value: "create")
        if let specifiedAction = action {
            importAction.value = specifiedAction.rawValue
        }
        let (data, response) = try await apiCall.post(endPoint: endpointPath("import"), body: documents, queryParameters: [importAction])
        return (data, response)
    }

    public func export(options: ExportDocumentsParameters? = nil) async throws -> (Data?, URLResponse?) {
        let searchQueryParams = try createURLQuery(forSchema: options)
        let (data, response) = try await apiCall.get(endPoint: endpointPath("export"), queryParameters: searchQueryParams)
        return (data, response)
    }

    private func endpointPath(_ operation: String? = nil) throws -> String {
        let baseEndpoint = try "collections/\(collectionName.encodeURL())/documents"
        if let operation: String = operation {
            return "\(baseEndpoint)/\(operation)"
        } else {
            return baseEndpoint
        }
    }
}
