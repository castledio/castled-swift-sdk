//
//  CastledSessions.swift
//  Castled
//
//  Created by antony on 21/05/2024.
//

import Foundation

class CastledSessions: NSObject {
    @objc static var sharedInstance = CastledSessions()
    var userId = ""
    let castledConfig = Castled.sharedInstance.getCastledConfig()
    private var isInitilized = false

    override private init() {}

    @objc public func initializeSessions() {
        if isInitilized {
            return
        }
        CastledRequestHelper.sharedInstance.requestHandlerRegistry[CastledConstants.CastledNetworkRequestType.sessionTracking.rawValue] = CastledSessionsRequestHandler.self
        isInitilized = true
        CastledSessionsController.sharedInstance.initialize()
        //  CastledLog.castledLog("Sessions module initialized..", logLevel: CastledLogLevel.info)
    }

    func reportSessionEvents(params: [[String: Any]]) {
        if userId.isEmpty {
            return
        }
        CastledSessionRepository.reportSessionEvents(params: params)
    }
}
