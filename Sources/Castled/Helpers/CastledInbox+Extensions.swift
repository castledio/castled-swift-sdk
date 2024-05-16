//
//  Castled+Inbox.swift
//  Castled
//
//  Created by antony on 31/08/2023.
//

import Foundation
import RealmSwift
import UIKit

public extension Castled {
    /**
     Inbox : Function that will returns the unread message count
     */
    @objc func observeUnreadCountChanges(listener: @escaping (Int) -> Void) {
        inboxUnreadCountCallback = listener
        inboxUnreadCountCallback?(inboxUnreadCount)
    }

    @objc func getInboxUnreadCount() -> Int {
        return inboxUnreadCount
    }

    /**
     Inbox : Function to get inbox items array
     */
    @objc func getInboxItems(completion: @escaping (_ success: Bool, _ items: [CastledInboxItemOld]?, _ errorMessage: String?) -> Void) {
        CastledStore.castledStoreQueue.async {
            if Castled.sharedInstance.instanceId.isEmpty {
                completion(false, [], CastledExceptionMessages.notInitialised.rawValue)
                CastledLog.castledLog("GetInboxItems failed: \(CastledExceptionMessages.notInitialised.rawValue)", logLevel: .error)
                return
            }
            else if !CastledConfigsUtils.configs.enableAppInbox {
                completion(false, [], CastledExceptionMessages.appInboxDisabled.rawValue)
                CastledLog.castledLog("GetInboxItems failed: \(CastledExceptionMessages.appInboxDisabled.rawValue)", logLevel: .error)
                return
            }
            guard let _ = CastledUserDefaults.shared.userId else {
                CastledLog.castledLog("GetInboxItems failed: \(CastledExceptionMessages.userNotRegistered.rawValue)", logLevel: .error)
                completion(false, [], CastledExceptionMessages.userNotRegistered.rawValue)
                return
            }
            do {
                if let backgroundRealm = CastledDBManager.shared.getRealm() {
                    let cachedInboxObjects = backgroundRealm.objects(CAppInbox.self).filter("isDeleted == false")

                    let liveInboxItems: [CastledInboxItemOld] = cachedInboxObjects.map {
                        let inboxItem = CastledInboxResponseConverter.convertToInboxItem(appInbox: $0)
                        return inboxItem
                    }
                    DispatchQueue.main.async {
                        completion(true, liveInboxItems, nil)
                    }
                }
                else {
                    DispatchQueue.main.async {
                        completion(true, [], nil)
                    }
                }
            }
        }
    }

    /**
     Inbox : Function to mark inbox items as read
     */
    @objc func logInboxItemsRead(_ inboxItems: [CastledInboxItemOld]) {
        CastledInboxServices().reportInboxItemsRead(inboxItems: inboxItems, changeReadStatus: true)
    }

    /**
     Inbox : Function to mark inbox item as clicked
     */
    @objc func logInboxItemClicked(_ inboxItem: CastledInboxItemOld, buttonTitle: String?) {
        CastledInboxServices().reportInboxItemsClicked(inboxObject: inboxItem, buttonTitle: buttonTitle)
    }

    /**
     Inbox : Function to delete an inbox item
     */
    @objc func deleteInboxItem(_ inboxItem: CastledInboxItemOld) {
        CastledInboxServices().reportInboxItemsDeleted(inboxObject: inboxItem)
    }

    /**
     Inbox : Function to dismiss CastledInboxViewController
     */
    @objc func dismissInboxViewController() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first(where: { $0.isKeyWindow })
        {
            if let topViewController = window.rootViewController {
                var currentViewController = topViewController
                while let presentedViewController = currentViewController.presentedViewController {
                    currentViewController = presentedViewController
                }

                // Check if the topmost view controller is a UINavigationController
                if let navigationController = currentViewController as? UINavigationController {
                    // Check if the top view controller of the navigation stack is a CastledInboxViewController
                    if let inboxViewController = navigationController.topViewController as? OldCastledInboxViewController {
                        // Pop to the root view controller of the navigation stack
                        inboxViewController.removeObservers()
                        inboxViewController.navigationController?.popViewController(animated: true)
                    }
                }
                else if let tabBarController = currentViewController as? UITabBarController {
                    if let selectedNavigationController = tabBarController.selectedViewController as? UINavigationController, let inboxViewController = selectedNavigationController.topViewController as? OldCastledInboxViewController {
                        inboxViewController.removeObservers()
                        inboxViewController.navigationController?.popViewController(animated: true)
                    }
                }
                else if let inboxViewController = currentViewController as? OldCastledInboxViewController {
                    // Dismiss the CastledInboxViewController if it's not embedded in a UINavigationController
                    inboxViewController.removeObservers()
                    inboxViewController.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}
