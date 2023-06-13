//
//  CastledInApps.swift
//  Castled
//
//  Created by antony on 12/04/2023.
//

import Foundation
import UIKit
@objc public class CastledInApps : NSObject {
    
    internal static var sharedInstance = CastledInApps()
    internal var savedInApps = [CastledInAppObject]()
    private let castledInAppsQueue = DispatchQueue(label: "CastledInAppsQueue", qos: .background)
    
    private  override init () {
        super.init()
    }
    
    
    internal func fetchInAppNotificationWithCompletion(completion: @escaping () -> Void){
        if CastledConfigs.sharedInstance.enableInApp == false{
            completion()
            return;
        }
        Castled.fetchInAppNotification {[weak self] response in
            
            if response.success {
                
                DispatchQueue.global().async {
                    do {
                        // Create JSON Encoder
                        let encoder = JSONEncoder()
                        let data = try encoder.encode(response.result)
                        CastledUserDefaults.setObjectFor(CastledUserDefaults.kCastledInAppsList, data)
                        self?.prefetchInApps()
                        
                        
                    } catch {
                        castledLog("Unable to Encode response (\(error))")
                    }
                    completion()
                }
                
            }
            else
            {
                completion()
            }
        }
    }
    
    private func prefetchInApps()
    {
        if let savedItems = CastledUserDefaults.getDataFor(CastledUserDefaults.kCastledInAppsList) {
            let decoder = JSONDecoder()
            if let loadedInApps = try? decoder.decode([CastledInAppObject].self, from: savedItems){
                self.savedInApps.removeAll()
                self.savedInApps.append(contentsOf: loadedInApps)
                
            }
        }
    }
    
    internal func updateInappEvent(inappObject : CastledInAppObject,eventType: String,actionType : String?,btnLabel : String?,actionUri : String?){
        
        DispatchQueue.global().async {
            let teamId = "\(inappObject.teamID)"
            let sourceContext = inappObject.sourceContext
            
            var savedEventTypes = (CastledUserDefaults.getObjectFor(CastledUserDefaults.kCastledSendingInAppsEvents) as? [[String:String]]) ?? [[String:String]]()
            let existingEvents = savedEventTypes.filter { $0["eventType"] == eventType &&
                $0["sourceContext"] == sourceContext &&
                $0[CastledConstants.CastledSlugValueIdentifierKey] == CastledConstants.CastledSlugValueEventIdentifier.inapp.rawValue}
            
            if existingEvents.count == 0
            {
                let timezone = TimeZone.current
                let abbreviation = timezone.abbreviation(for: Date()) ?? "GMT"
                let epochTime = "\(Int(Date().timeIntervalSince1970))"
                
                var json = ["ts":"\(epochTime)",
                            "tz":"\(abbreviation)",
                            "teamId":teamId,
                            "eventType":eventType,
                            "sourceContext":sourceContext] as [String : String]
                
                if let value = btnLabel{
                    json["btnLabel"] = value
                }
                if let value = actionType{
                    json["actionType"] = value
                }
                if let value = actionUri{
                    json["actionUri"] = value
                }
                
                savedEventTypes.append(json)
                CastledUserDefaults.setObjectFor(CastledUserDefaults.kCastledSendingInAppsEvents, savedEventTypes)
            }
            
            
            Castled.updateInAppEvents(params: savedEventTypes, completion:{ (response: CastledResponse<[String : String]>) in
                
                if response.success {
                    //castledLog(response.result as Any)
                }
                else
                {
                    //castledLog("Error in updating inapp event ")
                }
            })
        }
    }
    
    /**
     Button action handling
     */
    
    private func getDeepLinkUrlFrom(url : String,parameters : [String : String]?) -> URL?{
        
        // Define the base URL for your deep link
        guard let baseURL = URL(string: url) else{
            castledLog("Error:❌❌❌ Invalid Deeplink URL provided")
            return nil
        }
        var queryString = ""
        
        // Create a dictionary of query parameters
        if let params = parameters {
            
            // Convert the query parameters to a query string
            queryString = params.map { key, value in
                return "\(key)=\(value)"
            }.joined(separator: "&")
        }
        
        // Construct the final deep link URL with query parameters
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.query = queryString
        
        if let deepLinkURL = components.url {
            // deepLinkURL now contains the complete deep link URL with query parameters
            return deepLinkURL
        } else {
            castledLog("Error:❌❌❌ Invalid Deeplink URL provided")
        }
        
        return nil
    }
    
    private func openURL(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    internal func performButtonActionFor(buttonAction : CIActionButton? = nil, slide:CIBannerPresentation? = nil)
    {
        var clickAction : CIButtonActionsType?
        var params: [String: String]?
        var url: String?
        
        if let action = buttonAction{
            clickAction = action.clickAction
            params = action.keyVals
            url = action.url
        }
        else if let slideUp = slide{
            clickAction = slideUp.clickAction
            params = slideUp.keyVals
            url = slideUp.url
        }
        switch clickAction?.rawValue {
        case CIButtonActionsType.deep_linking.rawValue:
            if let deeplinkUrl = getDeepLinkUrlFrom(url: url ?? "", parameters: params){
                castledLog("deeplinkUrl  ---\(deeplinkUrl)")
                openURL(deeplinkUrl)
            }
            break
        case CIButtonActionsType.rich_landing.rawValue:
            if let navigationkUrl = getDeepLinkUrlFrom(url: url ?? "", parameters: params){
                castledLog("Navigation Url  ---\(navigationkUrl)")
                openURL(navigationkUrl)
                
            }
            break
        case CIButtonActionsType.request_push_permission.rawValue:
            DispatchQueue.main.async {
                Castled.sharedInstance?.registerForPushNotifications()
            }
            break
        default: break
            
        }
    }
    
    
    /**
     Display inapp
     */
    
    private func findTriggeredInApps(inAppsArray: [CastledInAppObject]) -> CastledInAppObject? {
        
        let savedInApptriggers = (CastledUserDefaults.getObjectFor(CastledUserDefaults.kCastledSavedInappConfigs) as? [[String: String]]) ?? [[String: String]]()
        let lastGlobalDisplayedTime = Double(CastledUserDefaults.getString(CastledUserDefaults.kCastledLastInappDisplayedTime) ?? "-100000000000") ?? -100000000000
        let currentTime = Date().timeIntervalSince1970
        
        let filteredArray = inAppsArray.filter { inAppObj in
            let parentId = inAppObj.notificationID
            
            // Check if the savedInApptriggers contains the id
            if savedInApptriggers.contains(where: { Int($0[CastledConstants.InAppsConfigKeys.inAppNotificationId.rawValue] ?? "-1") == parentId }) {
                guard let savedValues = savedInApptriggers.first(where: { Int($0[CastledConstants.InAppsConfigKeys.inAppNotificationId.rawValue] ?? "") == parentId }),
                      let currentCounter = Int(savedValues[CastledConstants.InAppsConfigKeys.inAppCurrentDisplayCounter.rawValue]!),
                      let lastDiplayTime = Double(savedValues[CastledConstants.InAppsConfigKeys.inAppLastDisplayedTime.rawValue]!)
                        
                else { return false }
                return currentCounter < inAppObj.displayConfig?.displayLimit ?? 0 &&
                (currentTime - lastDiplayTime) > CGFloat(inAppObj.displayConfig?.minIntervalBtwDisplays ?? 0) &&
                (currentTime - lastGlobalDisplayedTime) > CGFloat(inAppObj.displayConfig?.minIntervalBtwDisplaysGlobal ?? 0)
            } else {
                return true
            }
        }
        
        if filteredArray.count > 0{
            
            let event = filteredArray.sorted { (lhs, rhs) -> Bool in
                let lhsPriority = CastledConstants.InDisplayPriority(rawValue: lhs.priority)
                let rhsPriority = CastledConstants.InDisplayPriority(rawValue: rhs.priority)
                return lhsPriority?.sortOrder ?? 0 > rhsPriority?.sortOrder ?? 0
            }.first
            return event
        }
        return nil
    }
    
    private func saveInappDisplayStatus(event : CastledInAppObject){
        
        let currentTime = Date().timeIntervalSince1970
        
        var savedInApptriggers = (CastledUserDefaults.getObjectFor(CastledUserDefaults.kCastledSavedInappConfigs) as? [[String: String]]) ?? [[String: String]]()
        
        if let index = savedInApptriggers.firstIndex(where: { String(event.notificationID) == $0[CastledConstants.InAppsConfigKeys.inAppNotificationId.rawValue] }) {
            
            var newValues = savedInApptriggers[index]
            var counter = Int(newValues[CastledConstants.InAppsConfigKeys.inAppCurrentDisplayCounter.rawValue] ?? "0") ?? 0
            counter += 1
            newValues[CastledConstants.InAppsConfigKeys.inAppCurrentDisplayCounter.rawValue] =  "\(counter)"
            newValues[CastledConstants.InAppsConfigKeys.inAppLastDisplayedTime.rawValue] =  "\(currentTime)"
            savedInApptriggers[index] = newValues
            
        }
        else
        {
            savedInApptriggers.append([CastledConstants.InAppsConfigKeys.inAppLastDisplayedTime.rawValue : "\(currentTime)",
                                       CastledConstants.InAppsConfigKeys.inAppCurrentDisplayCounter.rawValue : "1",
                                       CastledConstants.InAppsConfigKeys.inAppNotificationId.rawValue : String(event.notificationID)])
            
        }
        CastledUserDefaults.setObjectFor(CastledUserDefaults.kCastledSavedInappConfigs, savedInApptriggers)
        CastledUserDefaults.setString(CastledUserDefaults.kCastledLastInappDisplayedTime, "\(currentTime)")
        
    }
    
    func logAppEvent(context : UIViewController?,eventName : String,params : [String : Any]?,showLog : Bool? = true) {
        if CastledUserDefaults.getString(CastledUserDefaults.kCastledUserIdKey) == nil {
            return;
        }
        castledInAppsQueue.async { [self] in
            if savedInApps.count == 0{
                prefetchInApps()
            }
            var satisfiedEvents = [CastledInAppObject]()
            
            let filteredInApps = savedInApps.filter{ $0.trigger?.eventName == eventName}
            
            if filteredInApps.count > 0 {
                let evaluator = CastledInAppTriggerEvaluator()
                for event in filteredInApps{
                    
                    if(evaluator.shouldTriggerEvent(filter: event.trigger?.eventFilter, params: params,showLog:showLog)){
                        satisfiedEvents.append(event)
                    }
                }
                
            }
            if let event = findTriggeredInApps(inAppsArray: satisfiedEvents)
            {
                let inAppDisplaySettings = InAppDisplayConfig()
                inAppDisplaySettings.populateConfigurationsFrom(inAppObject: event)
                
                if let imageUrl = URL(string: inAppDisplaySettings.imageUrl){
                    CastledCommonClass.getImage(for: imageUrl) {  img in
                        if let image = img{
                            DispatchQueue.main.async {
                                let castle = CastledInAppDisplayViewController()
                                castle.showInAppViewControllerFromNotification(inAppObj: event,inAppDisplaySettings: inAppDisplaySettings,image: image)
                            }
                        }
                    }
                }
                saveInappDisplayStatus(event: event)
            }
        }
    }
}
