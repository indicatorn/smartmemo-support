//
//  MemoManager.swift
//  Notification memo1
//
//  Created by 印出啓人 on 2025/09/06.
//

import Foundation
import SwiftUI
import UserNotifications

class MemoManager: ObservableObject {
    @Published var memos: [Memo] = []
    @Published var deletedMemos: [Memo] = []
    @Published var sortOption: SortOption = .manual
    @Published var showingDeletedItems = false
    
    private let userDefaults = UserDefaults.standard
    private let memosKey = "SavedMemos"
    private let deletedMemosKey = "DeletedMemos"
    
    init() {
        loadMemos()
        requestNotificationPermission()
    }
    
    // MARK: - データの永続化
    func loadMemos() {
        if let data = userDefaults.data(forKey: memosKey),
           let decodedMemos = try? JSONDecoder().decode([Memo].self, from: data) {
            self.memos = decodedMemos
        }
        
        if let data = userDefaults.data(forKey: deletedMemosKey),
           let decodedDeletedMemos = try? JSONDecoder().decode([Memo].self, from: data) {
            self.deletedMemos = decodedDeletedMemos
        }
    }
    
    func saveMemos() {
        if let encoded = try? JSONEncoder().encode(memos) {
            userDefaults.set(encoded, forKey: memosKey)
        }
        
        if let encoded = try? JSONEncoder().encode(deletedMemos) {
            userDefaults.set(encoded, forKey: deletedMemosKey)
        }
    }
    
    // MARK: - メモの操作
    func addMemo(title: String, notificationDate: Date? = nil, interval: NotificationInterval = .none) {
        let newMemo = Memo(title: title, 
                          createdDate: Date(),
                          notificationDate: notificationDate,
                          notificationInterval: interval)
        memos.append(newMemo)
        
        if let notificationDate = notificationDate, interval != .none {
            scheduleNotification(for: newMemo)
        }
        
        saveMemos()
    }
    
    func updateMemo(_ memo: Memo, title: String, notificationDate: Date? = nil, interval: NotificationInterval = .none) {
        if let index = memos.firstIndex(where: { $0.id == memo.id }) {
            memos[index].title = title
            memos[index].notificationDate = notificationDate
            memos[index].notificationInterval = interval
            
            // 既存の通知をキャンセルして新しい通知をスケジュール
            cancelNotification(for: memo)
            if let notificationDate = notificationDate, interval != .none {
                scheduleNotification(for: memos[index])
            }
            
            saveMemos()
        }
    }
    
    func toggleCompletion(for memo: Memo) {
        if let index = memos.firstIndex(where: { $0.id == memo.id }) {
            memos[index].isCompleted.toggle()
            saveMemos()
        }
    }
    
    func deleteMemo(_ memo: Memo) {
        if let index = memos.firstIndex(where: { $0.id == memo.id }) {
            var deletedMemo = memos[index]
            deletedMemo.isDeleted = true
            deletedMemos.append(deletedMemo)
            memos.remove(at: index)
            
            cancelNotification(for: memo)
            saveMemos()
        }
    }
    
    func restoreMemo(_ memo: Memo) {
        if let index = deletedMemos.firstIndex(where: { $0.id == memo.id }) {
            var restoredMemo = deletedMemos[index]
            restoredMemo.isDeleted = false
            memos.append(restoredMemo)
            deletedMemos.remove(at: index)
            
            // 通知が設定されている場合は再スケジュール
            if let notificationDate = restoredMemo.notificationDate, 
               restoredMemo.notificationInterval != .none,
               notificationDate > Date() {
                scheduleNotification(for: restoredMemo)
            }
            
            saveMemos()
        }
    }
    
    func permanentlyDelete(_ memo: Memo) {
        if let index = deletedMemos.firstIndex(where: { $0.id == memo.id }) {
            deletedMemos.remove(at: index)
            saveMemos()
        }
    }
    
    // MARK: - ソート機能
    var sortedMemos: [Memo] {
        // 手動並び替えモードのみ - 配列の順序をそのまま使用
        return memos
    }
    
    // MARK: - 並び替え機能
    func moveMemos(from source: IndexSet, to destination: Int) {
        // 配列の順序を直接変更
        memos.move(fromOffsets: source, toOffset: destination)
        saveMemos()
    }
    
    // MARK: - 通知機能
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知の許可が得られました")
            } else {
                print("通知の許可が得られませんでした")
            }
        }
    }
    
    func scheduleNotification(for memo: Memo) {
        guard let notificationDate = memo.notificationDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "リマインダー"
        content.body = memo.title
        content.sound = .default
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: memo.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知のスケジュールに失敗しました: \(error)")
            } else {
                print("通知をスケジュールしました: \(memo.title)")
            }
        }
        
        // 繰り返し通知の設定
        if let interval = memo.notificationInterval.timeInterval, memo.notificationInterval != .none {
            scheduleRepeatingNotification(for: memo, interval: interval)
        }
    }
    
    private func scheduleRepeatingNotification(for memo: Memo, interval: TimeInterval) {
        guard let notificationDate = memo.notificationDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "定期リマインダー"
        content.body = memo.title
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: true)
        let request = UNNotificationRequest(identifier: "\(memo.id.uuidString)_repeat", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotification(for memo: Memo) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [memo.id.uuidString, "\(memo.id.uuidString)_repeat"])
    }
}

