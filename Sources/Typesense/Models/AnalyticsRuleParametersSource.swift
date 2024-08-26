//
// AnalyticsRuleParametersSource.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation



public struct AnalyticsRuleParametersSource: Codable {

    public var collections: [String]
    public var events: [AnalyticsRuleParametersSourceEvents]?

    public init(collections: [String], events: [AnalyticsRuleParametersSourceEvents]? = nil) {
        self.collections = collections
        self.events = events
    }


}
