//
//  CastledConfigsUtils.swift
//  Castled
//
//  Created by antony on 24/01/2024.
//

import Foundation

class CastledConfigsUtils: NSObject {
    static let kCastledConfigsKey = "_castledConfigs_"
    static var configs: CastledConfigs = {
        if let savedItem = CastledUserDefaults.getDataFor(CastledConfigsUtils.kCastledConfigsKey) {
            let decoder = JSONDecoder()
            if let config = try? decoder.decode(CastledConfigs.self, from: savedItem) {
                return config
            }
        }
        return CastledConfigs.initialize(appId: Castled.sharedInstance.instanceId.isEmpty ? "castled_appId" : Castled.sharedInstance.instanceId)
    }()

    // MARK: - Supporting properites

    static var appId: String? = {
        CastledUserDefaults.getString(CastledUserDefaults.kCastledAppIddKey)
    }()

    static func saveTheConfigs(config: CastledConfigs) {
        appId = Castled.sharedInstance.instanceId
        CastledConfigsUtils.configs = config

        DispatchQueue.main.async {
            let userDefaults = CastledUserDefaults.getUserDefaults()
            userDefaults.set(Castled.sharedInstance.instanceId, forKey: CastledUserDefaults.kCastledAppIddKey)
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(config) {
                userDefaults.set(data, forKey: CastledConfigsUtils.kCastledConfigsKey)
            }
            userDefaults.synchronize()
        }
    }
}
