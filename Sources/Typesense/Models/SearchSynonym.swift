//
// SearchSynonym.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation



public struct SearchSynonym: Codable {

    /** For 1-way synonyms, indicates the root word that words in the &#x60;synonyms&#x60; parameter map to. */
    public var root: String?
    /** Array of words that should be considered as synonyms. */
    public var synonyms: [String]
    public var _id: String
    /** Locale for the synonym, leave blank to use the standard tokenizer. */
    public var locale: String?
    /** By default, special characters are dropped from synonyms. Use this attribute to specify which special characters should be indexed as is. */
    public var symbolsToIndex: [String]?

    public init(root: String? = nil, synonyms: [String], _id: String, locale: String? = nil, symbolsToIndex: [String]? = nil) {
        self.root = root
        self.synonyms = synonyms
        self._id = _id
        self.locale = locale
        self.symbolsToIndex = symbolsToIndex
    }

    public enum CodingKeys: String, CodingKey {
        case _id = "id"
        case root
        case synonyms
        case locale
        case symbolsToIndex = "symbols_to_index"
    }

}
