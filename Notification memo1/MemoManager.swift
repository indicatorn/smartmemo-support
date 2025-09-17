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
    @Published var genres: [Genre] = Genre.defaultGenres
    @Published var selectedGenre: String = "すべてのメモ"
    @Published var selectedDeletedMemos: Set<UUID> = [] {
        didSet {
            print("selectedDeletedMemos が変更されました: \(selectedDeletedMemos.count)個選択中")
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let memosKey = "SavedMemos"
    private let deletedMemosKey = "DeletedMemos"
    private let genresKey = "SavedGenres"
    
    init() {
        loadMemos()
        loadGenres()
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
    
    func loadGenres() {
        if let data = userDefaults.data(forKey: genresKey),
           let decodedGenres = try? JSONDecoder().decode([Genre].self, from: data) {
            self.genres = decodedGenres
        } else {
            // 初回起動時はデフォルトジャンルを使用
            self.genres = Genre.defaultGenres
            saveGenres()
        }
    }
    
    func saveGenres() {
        if let encoded = try? JSONEncoder().encode(genres) {
            userDefaults.set(encoded, forKey: genresKey)
        }
    }
    
    // MARK: - メモの操作
    func addMemo(title: String, notificationDate: Date? = nil, interval: NotificationInterval = .none, genre: String = "すべてのメモ") {
        var newMemo = Memo(title: title, 
                          createdDate: Date(),
                          notificationDate: notificationDate,
                          notificationInterval: interval)
        newMemo.genre = genre
        memos.append(newMemo)
        
        if let notificationDate = notificationDate, interval != .none {
            scheduleNotification(for: newMemo)
        }
        
        saveMemos()
    }
    
    func updateMemo(_ memo: Memo, title: String, notificationDate: Date? = nil, interval: NotificationInterval = .none, genre: String = "すべてのメモ") {
        if let index = memos.firstIndex(where: { $0.id == memo.id }) {
            memos[index].title = title
            memos[index].notificationDate = notificationDate
            memos[index].notificationInterval = interval
            memos[index].genre = genre
            
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
        // 削除されていないメモのみを対象
        let activeMemos = memos.filter { !$0.isDeleted }
        let filteredMemos: [Memo]
        
        if selectedGenre == "すべてのメモ" {
            filteredMemos = activeMemos
        } else {
            filteredMemos = activeMemos.filter { $0.genre == selectedGenre }
        }
        
        // 手動並び替えモードのみ - 配列の順序をそのまま使用
        return filteredMemos
    }
    
    // 削除済みメモ（ジャンルフィルタリング適用）
    var filteredDeletedMemos: [Memo] {
        if selectedGenre == "すべてのメモ" {
            return deletedMemos
        } else {
            return deletedMemos.filter { $0.genre == selectedGenre }
        }
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
    
    // MARK: - ジャンル管理
    func addGenre(_ name: String) {
        // 重複チェック
        guard !genres.contains(where: { $0.name == name }) else { return }
        
        let newGenre = Genre(name: name)
        genres.append(newGenre)
        saveGenres()
    }
    
    func updateGenre(_ genre: Genre, newName: String) {
        // デフォルトジャンルは編集不可
        guard !genre.isDefault else { return }
        
        // 重複チェック
        guard !genres.contains(where: { $0.name == newName && $0.id != genre.id }) else { return }
        
        if let index = genres.firstIndex(where: { $0.id == genre.id }) {
            genres[index].name = newName
            
            // 該当するメモのジャンルも更新
            for i in 0..<memos.count {
                if memos[i].genre == genre.name {
                    memos[i].genre = newName
                }
            }
            
            // 選択中のジャンルが変更された場合
            if selectedGenre == genre.name {
                selectedGenre = newName
            }
            
            saveMemos()
            saveGenres()
        }
    }
    
    func deleteGenre(_ genre: Genre) {
        // デフォルトジャンルは削除不可
        guard !genre.isDefault else { return }
        
        if let index = genres.firstIndex(where: { $0.id == genre.id }) {
            genres.remove(at: index)
            
            // 該当するメモを「すべてのメモ」に移動
            for i in 0..<memos.count {
                if memos[i].genre == genre.name {
                    memos[i].genre = "すべてのメモ"
                }
            }
            
            // 選択中のジャンルが削除された場合
            if selectedGenre == genre.name {
                selectedGenre = "すべてのメモ"
            }
            
            saveMemos()
            saveGenres()
        }
    }
    
    func selectGenre(_ genreName: String) {
        selectedGenre = genreName
        showingDeletedItems = false
    }
    
    func showDeletedItems() {
        showingDeletedItems = true
    }
    
    // MARK: - 削除済みメモ選択機能
    func toggleDeletedMemoSelection(_ memo: Memo) {
        print("削除済みメモ選択切り替え: \(memo.title)")
        if selectedDeletedMemos.contains(memo.id) {
            selectedDeletedMemos.remove(memo.id)
            print("選択解除: \(memo.title)")
        } else {
            selectedDeletedMemos.insert(memo.id)
            print("選択: \(memo.title)")
        }
        print("現在の選択数: \(selectedDeletedMemos.count)")
        
        // UI更新を強制的にトリガー
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func isDeletedMemoSelected(_ memo: Memo) -> Bool {
        let isSelected = selectedDeletedMemos.contains(memo.id)
        print("削除済みメモ選択状態確認: \(memo.title) - \(isSelected) (選択中: \(selectedDeletedMemos.count)個)")
        print("選択中のID一覧: \(selectedDeletedMemos)")
        print("現在のメモID: \(memo.id)")
        return isSelected
    }
    
    func clearDeletedMemoSelection() {
        selectedDeletedMemos.removeAll()
    }
    
    func bulkRestoreSelectedDeletedMemos() {
        let selectedMemos = deletedMemos.filter { selectedDeletedMemos.contains($0.id) }
        for memo in selectedMemos {
            restoreMemo(memo)
        }
        selectedDeletedMemos.removeAll()
    }
    
    func bulkPermanentlyDeleteSelectedDeletedMemos() {
        let selectedMemos = deletedMemos.filter { selectedDeletedMemos.contains($0.id) }
        for memo in selectedMemos {
            permanentlyDelete(memo)
        }
        selectedDeletedMemos.removeAll()
    }
}

