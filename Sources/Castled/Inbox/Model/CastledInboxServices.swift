//
//  CastledInboxServices.swift
//  Castled
//
//  Created by antony on 31/08/2023.
//

import UIKit

class CastledInboxServices: NSObject {
    private let backgroundQueue = DispatchQueue(label: "CastledInboxQueue", qos: .background)
    func reportInboxItemsRead(inboxItems: [CastledInboxItem], changeReadStatus: Bool) {
        if inboxItems.isEmpty {
            return
        }
        if changeReadStatus {
            CastledStore.saveInboxItemsRead(readItems: inboxItems)
        }
        backgroundQueue.async { [self] in
            let eventType = "READ"
            var savedEventTypes = [[String: String]]()
            for inboxObject in inboxItems {
                savedEventTypes.append(getSendingParametersFrom(eventType, inboxObject, ""))
            }
            if !savedEventTypes.isEmpty {
                updateInBoxEvents(savedEventTypes: savedEventTypes) { success, error in
                    if success {
                        CastledLog.castledLog("Inbox item read status success", logLevel: CastledLogLevel.debug)
                    }
                    else {
                        CastledLog.castledLog("Inbox item read status failed \(String(describing: error))", logLevel: CastledLogLevel.error)
                    }
                }
            }
        }
    }

    func reportInboxItemsClicked(inboxObject: CastledInboxItem, buttonTitle: String?) {
        backgroundQueue.async { [self] in
            let eventType = "CLICKED"
            self.updateInBoxEvents(savedEventTypes: [self.getSendingParametersFrom(eventType, inboxObject, buttonTitle ?? "")]) { success, error in
                if success {
                    CastledLog.castledLog("Inbox item clicked success", logLevel: CastledLogLevel.debug)
                }
                else {
                    CastledLog.castledLog("Inbox item clicked status failed \(String(describing: error))", logLevel: CastledLogLevel.error)
                }
            }
        }
    }

    func reportInboxItemsDeleted(inboxObject: CastledInboxItem, completion: @escaping (_ success: Bool, _ errorMessage: String?) -> Void) {
        backgroundQueue.async { [self] in
            let eventType = "DELETED"
            var savedEventTypes = [[String: String]]()
            savedEventTypes.append(self.getSendingParametersFrom(eventType, inboxObject, ""))
            if !savedEventTypes.isEmpty {
                updateInBoxEvents(savedEventTypes: savedEventTypes) { success, error in
                    if success {
                        CastledStore.deleteInboxItem(inboxItem: inboxObject)
                        CastledLog.castledLog("Inbox item deleted", logLevel: CastledLogLevel.debug)
                    }
                    else {
                        CastledLog.castledLog(" Delete Inbox item failed \(String(describing: error))", logLevel: CastledLogLevel.error)
                    }
                    completion(success, error)
                }
            }
        }
    }

    private func updateInBoxEvents(savedEventTypes: [[String: String]], completion: @escaping (_ success: Bool, _ errorMessage: String?) -> Void) {
        Castled.updateInboxEvents(params: savedEventTypes, completion: { (response: CastledResponse<[String: String]>) in
            completion(response.success, response.errorMessage)
        })
    }

    private func getSendingParametersFrom(_ eventType: String, _ inboxObject: CastledInboxItem, _ title: String) -> [String: String] {
        let teamId = "\(inboxObject.teamID)"
        let sourceContext = inboxObject.sourceContext
        let timezone = TimeZone.current
        let abbreviation = timezone.abbreviation(for: Date()) ?? "GMT"
        let epochTime = "\(Int(Date().timeIntervalSince1970))"
        var json = ["ts": "\(epochTime)",
                    "tz": "\(abbreviation)",
                    "teamId": teamId,
                    "eventType": eventType,
                    "sourceContext": sourceContext] as [String: String]
        json[CastledConstants.CastledNetworkRequestTypeKey] = CastledNotificationType.inbox.value()
        json["btnLabel"] = title
        return json
    }
}
