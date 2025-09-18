//
//  Notification_memo1App.swift
//  ToDo通知
//
//  Created by 印出啓人 on 2025/09/06.
//

import SwiftUI
import UserNotifications

@main
struct Notification_memo1App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let memoManager = MemoManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // フォアグラウンドでも通知を表示
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // スヌーズ通知が表示された時に次のスヌーズ通知をスケジュール
        handleSnoozeNotification(notification: notification)
        completionHandler([.alert, .sound, .badge])
    }
    
    // 通知をタップした時の処理
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let actionIdentifier = response.actionIdentifier
        
        // スヌーズアクションの処理
        if actionIdentifier.hasPrefix("SNOOZE_") {
            handleSnoozeAction(actionIdentifier: actionIdentifier, notificationResponse: response)
        } else if actionIdentifier == "STOP_SNOOZE" {
            handleStopSnoozeAction(notificationResponse: response)
        } else {
            // 通常の通知タップまたはスヌーズ通知の処理
            handleSnoozeNotification(notification: response.notification)
        }
        
        completionHandler()
    }
    
    private func handleSnoozeNotification(notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        
        // スヌーズ通知かどうかチェック
        guard let memoIdString = userInfo["memoId"] as? String,
              let memoId = UUID(uuidString: memoIdString),
              let snoozeCount = userInfo["snoozeCount"] as? Int else {
            return
        }
        
        // メモを取得
        guard let memo = memoManager.memos.first(where: { $0.id == memoId }) else { return }
        
        // スヌーズ間隔が設定されている場合、次のスヌーズ通知をスケジュール
        if let snoozeInterval = memo.snoozeInterval.timeInterval, memo.snoozeInterval != .none {
            let nextSnoozeDate = Date().addingTimeInterval(snoozeInterval)
            memoManager.scheduleNextSnoozeNotification(for: memo, at: nextSnoozeDate, currentSnoozeCount: snoozeCount)
        }
    }
    
    private func handleSnoozeAction(actionIdentifier: String, notificationResponse: UNNotificationResponse) {
        // 通知IDからメモIDを取得
        let notificationId = notificationResponse.notification.request.identifier
        let memoIdString = notificationId.replacingOccurrences(of: "_snooze", with: "")
        
        guard let memoId = UUID(uuidString: memoIdString) else { return }
        
        // スヌーズ間隔を決定
        let snoozeInterval: SnoozeInterval
        switch actionIdentifier {
        case "SNOOZE_1MIN":
            snoozeInterval = .oneMinute
        case "SNOOZE_5MIN":
            snoozeInterval = .fiveMinutes
        case "SNOOZE_10MIN":
            snoozeInterval = .tenMinutes
        case "SNOOZE_30MIN":
            snoozeInterval = .thirtyMinutes
        case "SNOOZE_1HOUR":
            snoozeInterval = .oneHour
        default:
            return
        }
        
        // スヌーズ処理を実行
        memoManager.handleSnoozeAction(for: memoId, snoozeInterval: snoozeInterval)
    }
    
    private func handleStopSnoozeAction(notificationResponse: UNNotificationResponse) {
        // 通知IDからメモIDを取得
        let notificationId = notificationResponse.notification.request.identifier
        let memoIdString = notificationId.replacingOccurrences(of: "_snooze_", with: "").components(separatedBy: "_").first ?? ""
        
        guard let memoId = UUID(uuidString: memoIdString) else { return }
        
        // スヌーズ停止処理を実行
        memoManager.stopSnooze(for: memoId)
    }
}
