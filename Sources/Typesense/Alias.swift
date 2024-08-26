import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public struct Alias {
    var apiCall: ApiCall
    let RESOURCEPATH = "aliases"

    init(apiCall: ApiCall) {
        self.apiCall = apiCall
    }

    public func upsert(name: String, collection: CollectionAliasSchema) async throws -> (CollectionAlias?, URLResponse?) {
        let schemaData: Data?

        schemaData = try encoder.encode(collection)

        if let validSchema = schemaData {
            let (data, response) = try await apiCall.put(endPoint: "\(RESOURCEPATH)/\(name)", body: validSchema)
            if let result = data {
                let alias = try decoder.decode(CollectionAlias.self, from: result)
                return (alias, response)
            }
        }
        return (nil, nil)
    }

    public func retrieve(name: String) async throws -> (CollectionAlias?, URLResponse?) {
        let (data, response) = try await apiCall.get(endPoint: "\(RESOURCEPATH)/\(name)")
        if let result = data {
            let alias = try decoder.decode(CollectionAlias.self, from: result)
            return (alias, response)
        }
        return (nil, nil)
    }

    public func retrieve() async throws -> (CollectionAliasesResponse?, URLResponse?) {
        let (data, response) = try await apiCall.get(endPoint: "\(RESOURCEPATH)")
        if let result = data {
            let aliases = try decoder.decode(CollectionAliasesResponse.self, from: result)
            return (aliases, response)
        }
        return (nil, nil)
    }

    public func delete(name: String) async throws -> (CollectionAlias?, URLResponse?) {
        let (data, response) = try await apiCall.delete(endPoint: "\(RESOURCEPATH)/\(name)")
        if let result = data {
            let alias = try decoder.decode(CollectionAlias.self, from: result)
            return (alias, response)
        }
        return (nil, nil)
    }


}
