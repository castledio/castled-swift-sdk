//
//  CastledInboxitem.swift
//  CastledInboxPOC
//
//  Created by antony on 28/08/2023.
//
import Foundation
import UIKit

@objc public class CastledInboxItem: NSObject, Codable {
    public let teamID, messageId: Int
    public let sourceContext, imageUrl,title,body: String
    public let inboxType: CastledInboxType
    public let message: [String: Any]
    public let startTs: Int64
    public let aspectRatio: CGFloat
    public var isRead: Bool
    public var addedDate : Date
    public var titleTextColor: UIColor
    public var bodyTextColor: UIColor
    public var dateTextColor: UIColor
    public var containerBGColor: UIColor
    public var actionButtons : [[String : Any]]
    enum CodingKeys: String, CodingKey {
        case teamID = "teamId"
        case messageId = "messageId"
        case isRead = "read"
        case message = "message"

        case sourceContext, startTs, aspectRatio // Use messageData to decode the message
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode other fields if needed
    }
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.teamID = try container.decode(Int.self, forKey: .teamID)
        self.messageId = try container.decode(Int.self, forKey: .messageId)
        self.sourceContext = try container.decode(String.self, forKey: .sourceContext)
        self.startTs = try container.decodeIfPresent(Int64.self, forKey: .startTs) ?? 0
        self.isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? true
        self.message = try container.decode([String: Any].self, forKey: .message)

        self.addedDate = Date.from(epochTimestamp: TimeInterval(self.startTs/1000))
        self.actionButtons = (self.message["actionButtons"] as? [[String: Any]] ?? [])
        self.aspectRatio = CGFloat((self.message["aspectRatio"] as? Double) ?? Double((self.message["aspectRatio"] as? Int) ?? Int(0.0)))
        self.imageUrl = (self.message["thumbnailUrl"] as? String) ??
        (self.message["contents"] as? [[String: Any]] ?? []).first?["thumbnailUrl"] as? String ??
        (self.message["contents"] as? [[String: Any]] ?? []).first?["url"] as? String ?? ""
        self.title = (self.message["title"] as? String) ?? ""
        self.body = (self.message["body"] as? String) ?? ""
        self.inboxType = CastledInboxType(rawValue: (self.message["type"] as? String) ?? "OTHER") ?? .other

        self.titleTextColor = CastledCommonClass.hexStringToUIColor(hex: (self.message["titleFontColor"] as? String) ?? "")  ?? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        self.bodyTextColor = CastledCommonClass.hexStringToUIColor(hex: (self.message["bodyFontColor"] as? String) ?? "")  ?? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        self.dateTextColor = self.bodyTextColor
        self.containerBGColor = CastledCommonClass.hexStringToUIColor(hex: (self.message["bgColor"] as? String) ?? "")  ?? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)

    }
    static func == (lhs: CastledInboxItem, rhs: CastledInboxItem) -> Bool {
        return lhs.sourceContext == rhs.sourceContext
    }
}




