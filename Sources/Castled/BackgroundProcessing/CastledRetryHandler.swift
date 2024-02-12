//
//  CastledRetryHandler.swift
//  Castled
//
//  Created by antony on 28/04/2023.
//

import Foundation

class CastledRetryHandler {
    static let shared = CastledRetryHandler()
    private let castledSemaphore = DispatchSemaphore(value: 1)
    private let castledGroup = DispatchGroup()
    private var isResending = false
    private init() {}

    func retrySendingAllFailedEvents(completion: (() -> Void)? = nil) {
        if isResending {
            return
        }
        isResending = true
        CastledStore.castledStoreQueue.async { [weak self] in
            let failedItems = CastledStore.getAllFailedItemss()
            var shouldCallRegister = false
            let pushToken = CastledUserDefaults.shared.apnsToken
            if pushToken != nil && CastledUserDefaults.shared.userId != nil && !CastledUserDefaults.getBoolean(CastledUserDefaults.kCastledIsTokenRegisteredKey) {
                shouldCallRegister = true
            }
            guard !failedItems.isEmpty || shouldCallRegister else {
                completion?()
                self?.isResending = false
                return
            }
            let requestHandlerRegistry = Dictionary(grouping: failedItems, by: { dictionary in
                dictionary[CastledConstants.CastledNetworkRequestTypeKey] as? String ?? ""
            })
            for (key, value) in requestHandlerRegistry {
                switch key {
                    case CastledConstants.CastledNetworkRequestType.pushRequest.rawValue:
                        let savedEvents = value
                        self?.castledSemaphore.wait()
                        self?.castledGroup.enter()
                        CastledNetworkManager.reportPushEvents(params: savedEvents, completion: { [weak self] _ in
                            self?.castledSemaphore.signal()
                            self?.castledGroup.leave()
                        })

                    case CastledConstants.CastledNetworkRequestType.inappRequest.rawValue:
                        let savedEvents = value
                        self?.castledSemaphore.wait()
                        self?.castledGroup.enter()
                        CastledNetworkManager.reportInAppEvents(params: savedEvents, completion: { [weak self] (_: CastledResponse<[String: String]>) in
                            self?.castledSemaphore.signal()
                            self?.castledGroup.leave()

                        })
                    case CastledConstants.CastledNetworkRequestType.inboxRequest.rawValue:
                        let savedEvents = value
                        self?.castledSemaphore.wait()
                        self?.castledGroup.enter()
                        CastledNetworkManager.reportInboxEvents(params: savedEvents, completion: { [weak self] (_: CastledResponse<[String: String]>) in
                            self?.castledSemaphore.signal()
                            self?.castledGroup.leave()
                        })

                    case CastledConstants.CastledNetworkRequestType.deviceInfoRequest.rawValue:
                        if let savedEvents = value as? [[String: String]] {
                            for info in savedEvents {
                                self?.castledSemaphore.wait()
                                self?.castledGroup.enter()
                                CastledNetworkManager.reportDeviceInfo(deviceInfo: info) { [weak self] (_: CastledResponse<[String: String]>) in
                                    self?.castledSemaphore.signal()
                                    self?.castledGroup.leave()
                                }
                            }
                        }
                    case CastledConstants.CastledNetworkRequestType.productEventRequest.rawValue:
                        let savedEvents = value
                        self?.castledSemaphore.wait()
                        self?.castledGroup.enter()
                        CastledNetworkManager.reportCustomEvents(params: savedEvents, completion: { [weak self] (_: CastledResponse<[String: String]>) in
                            self?.castledSemaphore.signal()
                            self?.castledGroup.leave()
                        })
                    case CastledConstants.CastledNetworkRequestType.sessionTracking.rawValue:
                        let savedEvents = value
                        self?.castledSemaphore.wait()
                        self?.castledGroup.enter()
                        CastledNetworkManager.reportSessions(params: savedEvents, completion: { [weak self] (_: CastledResponse<[String: String]>) in
                            self?.castledSemaphore.signal()
                            self?.castledGroup.leave()
                        })
                    case CastledConstants.CastledNetworkRequestType.userEventRequest.rawValue:
                        let savedEvents = value
                        self?.castledSemaphore.wait()
                        self?.castledGroup.enter()
                        CastledNetworkManager.reportUserEvents(params: savedEvents, completion: { [weak self] (_: CastledResponse<[String: String]>) in
                            self?.castledSemaphore.signal()
                            self?.castledGroup.leave()
                        })

                    case CastledConstants.CastledNetworkRequestType.userAttributes.rawValue:
                        let savedEvents = value
                        for info in savedEvents {
                            self?.castledSemaphore.wait()
                            self?.castledGroup.enter()
                            CastledNetworkManager.reportUserAttributes(params: info) { [weak self] (_: CastledResponse<[String: String]>) in
                                self?.castledSemaphore.signal()
                                self?.castledGroup.leave()
                            }
                        }
                    case CastledConstants.CastledNetworkRequestType.logoutUser.rawValue:
                        let savedEvents = value
                        self?.castledSemaphore.wait()
                        self?.castledGroup.enter()
                        if let params = savedEvents.first {
                            CastledNetworkManager.logoutUser(params: params)
                        }
                        self?.castledSemaphore.signal()
                        self?.castledGroup.leave()

                    default:
                        break
                }
            }
            if shouldCallRegister == true {
                self?.castledSemaphore.wait()
                self?.castledGroup.enter()
                CastledNetworkManager.api_RegisterUser(userId: CastledUserDefaults.shared.userId ?? "", apnsToken: pushToken ?? "") { _ in
                    self?.castledSemaphore.signal()
                    self?.castledGroup.leave()
                }
            }
            self?.castledGroup.notify(queue: .main) {
                self?.isResending = false
                completion?()
            }
        }
    }
}
