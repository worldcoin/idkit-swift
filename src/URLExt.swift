import Foundation

extension URL {
	var host: String? {
		guard let comps = URLComponents(url: self, resolvingAgainstBaseURL: baseURL != nil) else {
			return nil
		}

		return comps.host
	}

	func appending(queryItems params: [URLQueryItem]) -> URL {
		guard var comps = URLComponents(url: self, resolvingAgainstBaseURL: baseURL != nil) else { return self }
		comps.queryItems = params
		return comps.url ?? self
	}
}
