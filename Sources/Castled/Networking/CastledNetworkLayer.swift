//
//  CastledNetworkLayer.swift
//  CastledPusher
//
//  Created by Antony Joe Mathew.
//
//Reference : https://medium.com/nerd-for-tech/using-url-sessions-with-swift-5-5-aysnc-await-codable-8935fe55fbfc

import Foundation

@objc class CastledNetworkLayer : NSObject {
    
    let retryLimit = 5
    static var shared = CastledNetworkLayer()
    private var request: URLRequest?
    private override init () {}
    
    private func createGetRequestWithURLComponents(url:URL,endpoint: CastledEndpoint) -> URLRequest? {
        var components = URLComponents(string: url.absoluteString)!
        if let parameters = endpoint.parameters {
            var queryItems: [URLQueryItem] = []
            for (key, value) in parameters {
                let queryItem = URLQueryItem(name: key, value: "\(value)")
                queryItems.append(queryItem)
            }
            components.queryItems = queryItems
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        request = URLRequest(url: components.url ?? url)
        request?.httpMethod = endpoint.method.rawValue
        return request
    }
    
    private func createPostRequestWithBody(url:URL,endpoint: CastledEndpoint) -> URLRequest? {
        request = URLRequest(url: url)
        request?.httpMethod = endpoint.method.rawValue
        request?.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request?.addValue("application/json", forHTTPHeaderField: "Accept")
        if let requestBody = getParameterBody(with: endpoint.parameters!) {
            request?.httpBody = requestBody
        }
        return request
    }
    
    private func createPutRequestWithBody(url:URL, endpoint: CastledEndpoint) -> URLRequest? {
        request = URLRequest(url: url)
        request?.httpMethod = endpoint.method.rawValue
        request?.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request?.addValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
    
    private func getParameterBody(with parameters: [String:Any]) -> Data? {
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            return nil
        }
        return httpBody
    }
    
    func createRequest(with endpoint: CastledEndpoint) -> URLRequest? {
        guard let url = constructURL(for: endpoint) else {
            print("Invalid URL")
            return nil
        }
        
        switch endpoint.method{
        case .get:
            return createGetRequestWithURLComponents(url: url,endpoint :endpoint)
        case .post:
            return createPostRequestWithBody(url: url,endpoint :endpoint)
        case .put :
            return createPutRequestWithBody(url: url,endpoint :endpoint)
        }
    }

    func constructURL(for endpoint: CastledEndpoint) -> URL? {
        let urlString = endpoint.baseURL + endpoint.baseURLEndPoint + endpoint.path
        return URL(string: urlString)
    }
    
    func sendRequest<T:Any>(model: T.Type,endpoint: CastledEndpoint,retryAttempt: Int? = 0) async -> Result<[String:Any], Error> {
        if #available(iOS 13.0, *) {
            do {
                if CastledReachability.isConnectedToNetwork() == false{
                    return .failure(CastledException.Error(CastledExceptionMessages.common.rawValue))
                }
                
                guard let urlRequest = createRequest(with : endpoint) else {
                    return .failure(CastledException.Error(CastledExceptionMessages.paramsMisMatch.rawValue))
                }
                if #available(iOS 13.0, *) {
                    let (data, response) = try await URLSession.shared.data(for: urlRequest)
                    do {
                        switch endpoint.method {
                        case .post,.put:
                            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                                return .success(["success":"1"])
                            }
                        default:
                            break
                        }
                        
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            
                            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                                return .success(json)
                            }
                            else
                            {
                                if let error_message = json["message"]{
                                    
                                    let err =  CastledException.Error(error_message as! String)
                                    return .failure(err)
                                }
                                else{
                                    let err =  CastledException.Error(CastledExceptionMessages.common.rawValue)
                                    return .failure(err)
                                }
                            }
                        }
                    } catch let error as NSError {
                        return .failure(error)
                        
                    }
                } else {
                    // Fallback on earlier versions
                }
                
            }
            catch {
                
                if retryAttempt! < retryLimit{
                    return await CastledNetworkLayer.shared.sendRequest(model: model, endpoint: endpoint,retryAttempt: retryAttempt!+1)
                }
                return .failure(CastledException.Error(CastledExceptionMessages.common.rawValue))
            }
        }
        return .failure(CastledException.Error(CastledExceptionMessages.iOS13Less.rawValue))
    }
    
    func sendRequestFoFetch<T:Codable>(model: T.Type,endpoint: CastledEndpoint,retryAttempt: Int? = 0) async -> CastledResponse<T> {
        if #available(iOS 13.0, *) {
            do {
                if CastledReachability.isConnectedToNetwork() == false{
                    return CastledResponse<T>(error: CastledExceptionMessages.common.rawValue, statusCode: 0)
                }
                
                guard let urlRequest = createRequest(with: endpoint) else {
                    return CastledResponse<T>(error: CastledExceptionMessages.paramsMisMatch.rawValue, statusCode: 0)
                }
                if #available(iOS 13.0, *) {
                    let (data, response) = try await URLSession.shared.data(for: urlRequest)
                    
                    if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                        do {
                            
                            let decoder = JSONDecoder()
                            decoder.keyDecodingStrategy = .convertFromSnakeCase
                            let result = try decoder.decode(T.self, from: data)
                            return CastledResponse(response: result)
                            
                        } catch {
                            // Inspect any thrown errors here.
                            return CastledResponse<T>(error: error.localizedDescription, statusCode: 0)
                            
                        }
                    }
                    else
                    {
                        
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            
                            if let error_message = json["message"]{
                                return CastledResponse<T>(error: error_message as! String, statusCode: 0)
                                
                            }
                        }
                        return CastledResponse<T>(error: CastledExceptionMessages.common.rawValue, statusCode: 0)
                    }
                } else {
                    // Fallback on earlier versions
                }
            }
            catch {
                
                if retryAttempt! < retryLimit{
                    return await  CastledNetworkLayer.shared.sendRequestFoFetch(model: model, endpoint : endpoint,retryAttempt: retryAttempt!+1)
                    
                }
                return CastledResponse<T>(error: CastledExceptionMessages.common.rawValue, statusCode: 0)
            }
        }
        return CastledResponse<T>(error: CastledExceptionMessages.iOS13Less.rawValue, statusCode: 0)
    }
}

