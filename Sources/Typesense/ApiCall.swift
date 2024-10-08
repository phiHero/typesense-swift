import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif


let APIKEYHEADERNAME = "X-Typesense-Api-Key"
let HEALTHY = true
let UNHEALTHY = false

class ApiCall {
    var nodes: [Node]
    var apiKey: String
    var nearestNode: Node? = nil
    var connectionTimeoutSeconds: Int = 10
    var healthcheckIntervalSeconds: Int = 15
    var numRetries: Int = 3
    var retryIntervalSeconds: Float = 0.1
    var sendApiKeyAsQueryParam: Bool = false
    var logger: Logger
    var currentNodeIndex = -1

    init(config: Configuration) {
        self.apiKey = config.apiKey
        self.nodes = config.nodes
        self.nearestNode = config.nearestNode
        self.connectionTimeoutSeconds = config.connectionTimeoutSeconds
        self.healthcheckIntervalSeconds = config.healthcheckIntervalSeconds
        self.numRetries = config.numRetries
        self.retryIntervalSeconds = config.retryIntervalSeconds
        self.sendApiKeyAsQueryParam = config.sendApiKeyAsQueryParam
        self.logger = config.logger

        self.initializeMetadataForNodes()
    }

    //Various request types' implementation

    func get(endPoint: String, queryParameters: [URLQueryItem]? = nil) async throws -> (Data?, URLResponse?) {
        let (data, response) = try await self.performRequest(requestType: RequestType.get, endpoint: endPoint, queryParameters: queryParameters)
        return (data, response)
    }

    func delete(endPoint: String, queryParameters: [URLQueryItem]? = nil) async throws -> (Data?, URLResponse?) {
        let (data, response) = try await self.performRequest(requestType: RequestType.delete, endpoint: endPoint, queryParameters: queryParameters)
        return (data, response)
    }

    func post(endPoint: String, body: Data, queryParameters: [URLQueryItem]? = nil) async throws -> (Data?, URLResponse?) {
        let (data, response) = try await self.performRequest(requestType: RequestType.post, endpoint: endPoint, body: body, queryParameters: queryParameters)
        return (data, response)
    }

    func put(endPoint: String, body: Data, queryParameters: [URLQueryItem]? = nil) async throws -> (Data?, URLResponse?) {
        let (data, response) = try await self.performRequest(requestType: RequestType.put, endpoint: endPoint, body: body, queryParameters: queryParameters)
        return (data, response)
    }

    func patch(endPoint: String, body: Data, queryParameters: [URLQueryItem]? = nil) async throws -> (Data?, URLResponse?) {
        let (data, response) = try await self.performRequest(requestType: RequestType.patch, endpoint: endPoint, body: body, queryParameters: queryParameters)
        return (data, response)
    }

    //Actual API Call
    func performRequest(requestType: RequestType, endpoint: String, body: Data? = nil, queryParameters: [URLQueryItem]? = nil) async throws -> (Data, URLResponse) {
        let requestNumber = Date().millisecondsSince1970
        logger.log("Request #\(requestNumber): Performing \(requestType.rawValue) request: /\(endpoint)")
        var lastError: any Error = HTTPError.clientError(code: 400, desc: "Typesense client error!")

        for numTry in 1...self.numRetries + 1 {
            //Get next healthy node
            var selectedNode = self.getNextNode(requestNumber: requestNumber)
            logger.log("Request #\(requestNumber): Attempting \(requestType.rawValue) request: Try \(numTry) to \(selectedNode)/\(endpoint)")

            //Prepare a Request
            let request = try prepareRequest(requestType: requestType, endpoint: endpoint, body: body, queryParameters: queryParameters, selectedNode: selectedNode)

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let res = response as? HTTPURLResponse {
                    if (res.statusCode >= 1 && res.statusCode <= 499) {
                        // Treat any status code > 0 and < 500 to be an indication that node is healthy
                        // We exclude 0 since some clients return 0 when request fails
                        selectedNode = setNodeHealthCheck(node: selectedNode, isHealthy: HEALTHY)
                    }

                    logger.log("Request \(requestNumber): Request to \(request.url!) was made. Response Code was \(res.statusCode)")

                    if (res.statusCode >= 200 && res.statusCode < 300) {
                        // if code is 2xx return the corresponding HTTP Response without retries
                        return (data, response)
                    }
                    else if (res.statusCode < 500) {
                        // Don't retry if code is not 5xx
                        throw HTTPClientError(data: data, statusCode: res.statusCode)
                    } else {
                        //For all other response codes (>=500) throw custom error
                        throw HTTPError.serverError(code: res.statusCode, desc: res.debugDescription)
                    }

                }
            } catch HTTPError.clientError(let code, let desc){
                throw HTTPError.clientError(code: code, desc: desc)
            } catch (let error) {
                lastError = error
                selectedNode = setNodeHealthCheck(node: selectedNode, isHealthy: UNHEALTHY)
                logger.log("Request \(requestNumber): Request to \(selectedNode)/\(endpoint) failed with error: \(error.localizedDescription)")
                logger.log("Request \(requestNumber): Sleeping for \(retryIntervalSeconds) seconds and retrying")
                let durationOfSleep = UInt64(retryIntervalSeconds * 1_000_000_000)
                try await Task.sleep(nanoseconds: durationOfSleep)
            }

        }
        throw lastError
    }

    //Bundles a URL Request
    func prepareRequest(requestType: RequestType, endpoint: String, body: Data? = nil, queryParameters: [URLQueryItem]? = nil, selectedNode: Node) throws -> URLRequest {

        let urlString = uriFor(endpoint: endpoint, node: selectedNode)
        let url = URL(string: urlString)

        guard let validURL = url else {
            throw URLError.invalidURL
        }

        var components = URLComponents(url: validURL, resolvingAgainstBaseURL: true)
        components?.queryItems = queryParameters

        guard let absoluteString = components?.string else {
            throw URLError.invalidURL
        }

        let urlWithComponents = URL(string: absoluteString)

        guard let validURLWithComponents = urlWithComponents else {
            throw URLError.invalidURL
        }

        var request = URLRequest(url: validURLWithComponents)
        request.httpMethod = requestType.rawValue

        //Set the ApiKey Header
        request.setValue(self.apiKey, forHTTPHeaderField: APIKEYHEADERNAME)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let httpBody = body {
            //Set the body of the request
            request.httpBody = httpBody
        }

        return request
    }

    //Get URL for a node combined with it's end point
    func uriFor(endpoint: String, node: Node) -> String {
        if let url = node.url{
            return "\(url)/\(endpoint)"
        }
        return "\(node.nodeProtocol!)://\(node.host!):\(node.port!)/\(endpoint)"
    }

    //Get the next healthy node from the given nodes
    func getNextNode(requestNumber: Int64 = 0) -> Node {


        //Check if nearest node exists and is healthy
        if let existingNearestNode = nearestNode {
            logger.log("Request #\(requestNumber): Nearest Node has health \(existingNearestNode.healthStatus)")

            if(existingNearestNode.isHealthy || self.nodeDueForHealthCheck(node: existingNearestNode, requestNumber: requestNumber)) {
                logger.log("Request #\(requestNumber): Updated current node to \(existingNearestNode)")
                return existingNearestNode
            }

            logger.log("Request #\(requestNumber): Falling back to individual nodes")
        }
        //Fallback to nodes as usual
        logger.log("Request #\(requestNumber): Listing health of nodes")
        let _ = self.nodes.map { node in
            logger.log("Health of \(node) is \(node.healthStatus)")
        }

        var candidateNode = nodes[0]

        for _ in 0...nodes.count {
            currentNodeIndex = (currentNodeIndex + 1) % nodes.count
            candidateNode = self.nodes[currentNodeIndex]

            if(candidateNode.isHealthy || self.nodeDueForHealthCheck(node: candidateNode, requestNumber: requestNumber)) {
                logger.log("Request #\(requestNumber): Updated current node to \(candidateNode)")
                return candidateNode
            }
        }

        return self.nodes[currentNodeIndex]
    }

    func nodeDueForHealthCheck(node: Node, requestNumber: Int64 = 0) -> Bool {
        let isDueForHealthCheck = Date().millisecondsSince1970 - node.lastAccessTimeStamp > (self.healthcheckIntervalSeconds * 1000)
        if (isDueForHealthCheck) {
            logger.log("Request #\(requestNumber): \(node) has exceeded healtcheckIntervalSeconds of \(self.healthcheckIntervalSeconds). Adding it back into rotation.")
        }

        return isDueForHealthCheck
    }

    //Set's Node's health status
    func setNodeHealthCheck(node: Node, isHealthy: Bool) -> Node {
        var thisNode = node
        thisNode.isHealthy = isHealthy
        thisNode.lastAccessTimeStamp = Date().millisecondsSince1970
        return thisNode
    }

    //Initializes a node's health status and last access time
    func initializeMetadataForNodes() {
        if let existingNearestNode = self.nearestNode {
            self.nearestNode = self.setNodeHealthCheck(node: existingNearestNode, isHealthy: HEALTHY)
        }

        for i in 0..<self.nodes.count {
            self.nodes[i] = self.setNodeHealthCheck(node: self.nodes[i], isHealthy: HEALTHY)
        }
    }

    func HTTPClientError(data: Data, statusCode: Int) -> Error {
        let decodedMessage = try? decoder.decode(ApiResponse.self, from: data)

        var errorMessage = "Request failed with HTTP code \(statusCode)"
        if let validMessage = decodedMessage{
            errorMessage += " | Server said: \(validMessage.message)"
        }

        return HTTPError.clientError(code: statusCode, desc: errorMessage)
    }

}
