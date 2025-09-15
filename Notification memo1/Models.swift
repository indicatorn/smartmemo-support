//
//  Models.swift
//  Notification memo1
//
//  Created by 印出啓人 on 2025/09/06.
//

import Foundation
import SwiftUI

// メモのデータモデル
struct Memo: Identifiable, Codable {
    let id = UUID()
    var title: String
    var createdDate: Date
    var notificationDate: Date?
    var isCompleted: Bool = false
    var isDeleted: Bool = false
    var notificationInterval: NotificationInterval = .none
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: createdDate)
    }
    
    var formattedNotificationDate: String {
        guard let notificationDate = notificationDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: notificationDate)
    }
}

// 通知の間隔設定
enum NotificationInterval: String, CaseIterable, Codable {
    case none = "なし"
    case thirtyMinutes = "30分"
    case oneHour = "1時間"
    case daily = "毎日"
    case weekly = "毎週"
    case monthly = "毎月"
    
    var timeInterval: TimeInterval? {
        switch self {
        case .none:
            return nil
        case .thirtyMinutes:
            return 30 * 60
        case .oneHour:
            return 60 * 60
        case .daily:
            return 24 * 60 * 60
        case .weekly:
            return 7 * 24 * 60 * 60
        case .monthly:
            return 30 * 24 * 60 * 60
        }
    }
}

// ソート方法
enum SortOption: String, CaseIterable {
    case manual = "手動並び替え"
}

