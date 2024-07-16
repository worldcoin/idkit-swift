import Foundation

enum BridgeResponse: Decodable {
	case success(Proof)
	case error(AppError)

	enum CodingKeys: String, CodingKey {
		case proof
		case errorCode = "error_code"
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		if let errorCode = try? container.decode(AppError.self, forKey: .errorCode) {
			self = .error(errorCode)
		} else if container.contains(.proof) {
			let proof = try Proof(from: decoder)
			self = .success(proof)
		} else {
			throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "BridgeResponse doesn't match any expected type"))
		}
	}
}

struct BridgeClient {
	struct CreateRequestResponse: Codable {
		let request_id: UUID
	}

	struct BridgeQueryResponse: Codable {
		let status: String
		let response: Optional<Payload>
	}

	static func create_request(_ data: Payload, bridgeURL: BridgeURL) async throws -> CreateRequestResponse {
    var request: URLRequest

    if #available(iOS 16.0, *) {
      request = URLRequest(url: bridgeURL.rawURL.appending(path: "/request"))
    } else {
      request = URLRequest(url: bridgeURL.rawURL.appendingPathComponent("request"))
    }

		request.httpMethod = "POST"
		request.httpBody = try JSONEncoder().encode(data)

		request.setValue("idkit-swift", forHTTPHeaderField: "User-Agent")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		let (data, _) = try await URLSession.shared.data(for: request)

		return try JSONDecoder().decode(CreateRequestResponse.self, from: data)
	}
}
