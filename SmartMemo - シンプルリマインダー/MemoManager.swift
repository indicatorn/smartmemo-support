//
//  MemoManager.swift
//  ToDo通知
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
    @Published var selectedMemos: Set<UUID> = []
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
        setupNotificationCategories()
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
            
            // 既存データに「メモ」タグがない場合は追加
            if !self.genres.contains(where: { $0.name == "メモ" }) {
                let memoGenre = Genre(name: "メモ", isDefault: true)
                self.genres.append(memoGenre)
            }
            
            // 無効なジャンル（空文字列や無題）をクリーンアップ
            self.genres = self.genres.filter { !$0.name.isEmpty && $0.name != "無題" }
            
            saveGenres()
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
    func addMemo(title: String, notificationDate: Date? = nil, interval: NotificationInterval = .none, snoozeInterval: SnoozeInterval = .none, genre: String = "すべてのメモ") {
        var newMemo = Memo(title: title, 
                          createdDate: Date(),
                          notificationDate: notificationDate,
                          notificationInterval: interval,
                          snoozeInterval: snoozeInterval)
        
        // ジャンルが存在しない場合の処理
        if !genres.contains(where: { $0.name == genre }) {
            // 無効なジャンル名（空文字列、無題）の場合は「メモ」に変更
            if genre.isEmpty || genre == "無題" {
                newMemo.genre = "メモ"
            } else {
                // 有効なジャンル名の場合は自動的にシートを追加
                addGenre(genre)
                newMemo.genre = genre
            }
        } else {
            newMemo.genre = genre
        }
        
        memos.append(newMemo)
        
        if let notificationDate = notificationDate {
            scheduleNotification(for: newMemo)
        }
        
        saveMemos()
    }
    
    func updateMemo(_ memo: Memo, title: String, notificationDate: Date? = nil, interval: NotificationInterval = .none, snoozeInterval: SnoozeInterval = .none, genre: String = "すべてのメモ") {
        if let index = memos.firstIndex(where: { $0.id == memo.id }) {
            memos[index].title = title
            memos[index].notificationDate = notificationDate
            memos[index].notificationInterval = interval
            memos[index].snoozeInterval = snoozeInterval
            
            // ジャンルが存在しない場合の処理
            if !genres.contains(where: { $0.name == genre }) {
                // 無効なジャンル名（空文字列、無題）の場合は「メモ」に変更
                if genre.isEmpty || genre == "無題" {
                    memos[index].genre = "メモ"
                } else {
                    // 有効なジャンル名の場合は自動的にシートを追加
                    addGenre(genre)
                    memos[index].genre = genre
                }
            } else {
                memos[index].genre = genre
            }
            
            // 既存の通知をキャンセルして新しい通知をスケジュール
            cancelNotification(for: memo)
            if let notificationDate = notificationDate {
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
            print("🗑️ メモ削除開始: \(memo.title)")
            print("🗑️ 通知設定: 間隔=\(memo.notificationInterval), スヌーズ=\(memo.snoozeInterval)")
            
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
            
            // ジャンルが存在しない場合の処理
            if restoredMemo.genre != "すべてのメモ" && !genres.contains(where: { $0.name == restoredMemo.genre }) {
                // 無効なジャンル名（空文字列、無題）の場合は「メモ」に変更
                if restoredMemo.genre.isEmpty || restoredMemo.genre == "無題" {
                    restoredMemo.genre = "メモ"
                } else {
                    // 有効なジャンル名の場合は自動的にシートを追加
                    addGenre(restoredMemo.genre)
                }
            }
            
            memos.append(restoredMemo)
            deletedMemos.remove(at: index)
            
            // 通知が設定されている場合は再スケジュール
            if let notificationDate = restoredMemo.notificationDate,
               notificationDate > Date() {
                scheduleNotification(for: restoredMemo)
            }
            
            // 選択状態からも削除
            selectedDeletedMemos.remove(memo.id)
            
            saveMemos()
        }
    }
    
    func permanentlyDelete(_ memo: Memo) {
        if let index = deletedMemos.firstIndex(where: { $0.id == memo.id }) {
            print("🗑️ 完全削除開始: \(memo.title)")
            print("🗑️ 通知設定: 間隔=\(memo.notificationInterval), スヌーズ=\(memo.snoozeInterval)")
            
            deletedMemos.remove(at: index)
            
            // 選択状態からも削除
            selectedDeletedMemos.remove(memo.id)
            
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
    
    func moveDeletedMemos(from source: IndexSet, to destination: Int) {
        // 削除済みメモの配列の順序を直接変更
        deletedMemos.move(fromOffsets: source, toOffset: destination)
        saveMemos()
    }
    
    // MARK: - 通知機能
    func setupNotificationCategories() {
        // スヌーズアクションを作成
        let snooze1Min = UNNotificationAction(identifier: "SNOOZE_1MIN", title: "1分後にスヌーズ", options: [])
        let snooze5Min = UNNotificationAction(identifier: "SNOOZE_5MIN", title: "5分後にスヌーズ", options: [])
        let snooze10Min = UNNotificationAction(identifier: "SNOOZE_10MIN", title: "10分後にスヌーズ", options: [])
        let snooze30Min = UNNotificationAction(identifier: "SNOOZE_30MIN", title: "30分後にスヌーズ", options: [])
        let snooze1Hour = UNNotificationAction(identifier: "SNOOZE_1HOUR", title: "1時間後にスヌーズ", options: [])
        let stopSnoozeAction = UNNotificationAction(identifier: "STOP_SNOOZE", title: "スヌーズ停止", options: [.destructive])
        let dismissAction = UNNotificationAction(identifier: "DISMISS", title: "閉じる", options: [.destructive])
        
        // スヌーズカテゴリを作成
        let snoozeCategory = UNNotificationCategory(
            identifier: "SNOOZE_CATEGORY",
            actions: [snooze1Min, snooze5Min, snooze10Min, snooze30Min, snooze1Hour, stopSnoozeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // スヌーズ停止カテゴリを作成（自動スヌーズ用）
        let snoozeStopCategory = UNNotificationCategory(
            identifier: "SNOOZE_STOP_CATEGORY",
            actions: [stopSnoozeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // カテゴリを登録
        UNUserNotificationCenter.current().setNotificationCategories([snoozeCategory, snoozeStopCategory])
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if !granted {
                    print("通知の許可が得られませんでした: \(error?.localizedDescription ?? "不明なエラー")")
                }
            }
        }
    }
    
    
    func scheduleNotification(for memo: Memo) {
        guard let notificationDate = memo.notificationDate else { return }
        
        // 初回通知をスケジュール
        scheduleInitialNotification(for: memo, at: notificationDate)
        
        // スヌーズ間隔が設定されている場合、スヌーズ通知もスケジュール
        if let snoozeInterval = memo.snoozeInterval.timeInterval, memo.snoozeInterval != .none {
            print("🔔 スヌーズ通知スケジュール条件: 間隔=\(memo.snoozeInterval), 時間=\(snoozeInterval)")
            let snoozeDate = notificationDate.addingTimeInterval(snoozeInterval)
            print("🔔 スヌーズ通知日時計算: \(notificationDate) + \(snoozeInterval) = \(snoozeDate)")
            scheduleSnoozeNotification(for: memo, at: snoozeDate, snoozeCount: 1)
        } else {
            print("🔔 スヌーズ通知スケジュール条件: 間隔=\(memo.snoozeInterval), スケジュールしない")
        }
        
        // 繰り返し通知の設定
        if let interval = memo.notificationInterval.timeInterval, memo.notificationInterval != .none {
            scheduleRepeatingNotification(for: memo, interval: interval)
        }
    }
    
    private func scheduleInitialNotification(for memo: Memo, at date: Date) {
        // 過去の日時の場合はスケジュールしない
        if date <= Date() {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "SmartMemo"
        content.body = memo.title
        content.sound = .default
        
        // スヌーズが「なし」のメモのみにスヌーズボタンを追加
        if memo.snoozeInterval == .none {
            content.categoryIdentifier = "SNOOZE_CATEGORY"
        }
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: memo.id.uuidString, content: content, trigger: trigger)
        
        print("🔔 通知スケジュール実行: \(memo.title)")
        print("🔔 通知ID: \(memo.id.uuidString)")
        print("🔔 通知日時: \(date)")
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知のスケジュールに失敗しました: \(error)")
            } else {
                print("🔔 通知スケジュール成功: \(memo.id.uuidString)")
            }
        }
    }
    
    // 月末日を自動調整する関数
    private func getLastDayOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: date)!
        let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth)!
        return lastDayOfMonth
    }
    
    // 日付が月末日かどうかをチェックする関数
    private func isLastDayOfMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let lastDay = calendar.range(of: .day, in: .month, for: date)?.upperBound ?? 32
        return day == lastDay - 1
    }
    
    private func scheduleRepeatingNotification(for memo: Memo, interval: TimeInterval) {
        guard let notificationDate = memo.notificationDate else { return }
        
        // 毎月の場合は特別な処理
        if memo.notificationInterval == .monthly {
            scheduleMonthlyNotification(for: memo, at: notificationDate)
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "SmartMemo"
        content.body = memo.title
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: true)
        let request = UNNotificationRequest(identifier: "\(memo.id.uuidString)_repeat", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // 毎月の通知をスケジュール（月末日調整付き）
    private func scheduleMonthlyNotification(for memo: Memo, at date: Date) {
        let calendar = Calendar.current
        let originalDay = calendar.component(.day, from: date)
        let originalHour = calendar.component(.hour, from: date)
        let originalMinute = calendar.component(.minute, from: date)
        
        // 12ヶ月分の通知をスケジュール
        for monthOffset in 1...12 {
            guard let targetDate = calendar.date(byAdding: .month, value: monthOffset, to: date) else { continue }
            
            var finalDate = targetDate
            
            // 31日設定で月末日を超える場合は月末日に調整
            if originalDay == 31 {
                let lastDayOfMonth = getLastDayOfMonth(for: targetDate)
                let lastDay = calendar.component(.day, from: lastDayOfMonth)
                if lastDay < 31 {
                    // 月末日に調整
                    finalDate = lastDayOfMonth
                }
            }
            
            // 時刻を設定
            finalDate = calendar.date(bySettingHour: originalHour, minute: originalMinute, second: 0, of: finalDate) ?? finalDate
            
            let content = UNMutableNotificationContent()
            content.title = "SmartMemo"
            content.body = memo.title
            content.sound = .default
            
            let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "\(memo.id.uuidString)_monthly_\(monthOffset)", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func cancelNotification(for memo: Memo) {
        print("🔔 通知キャンセル開始: \(memo.title)")
        
        // 基本の通知ID
        var identifiers = [memo.id.uuidString, "\(memo.id.uuidString)_repeat"]
        
        // 毎月の通知IDを追加
        for i in 1...12 {
            identifiers.append("\(memo.id.uuidString)_monthly_\(i)")
        }
        
        // スヌーズ通知IDを追加
        for i in 1...100 {
            identifiers.append("\(memo.id.uuidString)_snooze_\(i)")
        }
        
        print("🔔 キャンセル対象ID数: \(identifiers.count)")
        print("🔔 キャンセル対象ID: \(identifiers.prefix(5))...")
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        
        // キャンセル後の保留中通知を確認
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                print("🔔 キャンセル後の保留中通知数: \(requests.count)")
                let relatedNotifications = requests.filter { request in
                    request.identifier.contains(memo.id.uuidString)
                }
                print("🔔 関連する通知が残っているか: \(relatedNotifications.count > 0)")
            }
        }
    }
    
    private func scheduleSnoozeNotification(for memo: Memo, at date: Date, snoozeCount: Int) {
        // 上限100回まで
        guard snoozeCount <= 100 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "SmartMemo - スヌーズ (\(snoozeCount)/100回目)"
        content.body = memo.title
        content.sound = .default
        
        // スヌーズ停止ボタンを追加
        content.categoryIdentifier = "SNOOZE_STOP_CATEGORY"
        
        // ユーザー情報にスヌーズ回数とメモIDを保存
        content.userInfo = [
            "memoId": memo.id.uuidString,
            "snoozeCount": snoozeCount
        ]
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "\(memo.id.uuidString)_snooze_\(snoozeCount)", content: content, trigger: trigger)
        
        print("🔔 スヌーズ通知スケジュール実行: \(memo.title)")
        print("🔔 スヌーズ通知ID: \(memo.id.uuidString)_snooze_\(snoozeCount)")
        print("🔔 スヌーズ通知日時: \(date)")
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("スヌーズ通知のスケジュールに失敗しました: \(error)")
            } else {
                print("スヌーズ通知をスケジュールしました: \(memo.title) at \(date) (\(snoozeCount)回目)")
            }
        }
    }
    
    // 次のスヌーズ通知をスケジュール（外部から呼び出し可能）
    func scheduleNextSnoozeNotification(for memo: Memo, at date: Date, currentSnoozeCount: Int) {
        let nextSnoozeCount = currentSnoozeCount + 1
        scheduleSnoozeNotification(for: memo, at: date, snoozeCount: nextSnoozeCount)
    }
    
    // スヌーズアクション処理
    func handleSnoozeAction(for memoId: UUID, snoozeInterval: SnoozeInterval) {
        guard let memo = memos.first(where: { $0.id == memoId }) else { return }
        
        // 現在の時刻からスヌーズ間隔を加算
        let snoozeDate = Date().addingTimeInterval(snoozeInterval.timeInterval ?? 0)
        
        // スヌーズ通知をスケジュール
        scheduleSnoozeNotification(for: memo, at: snoozeDate, snoozeCount: 1)
    }
    
    // スヌーズ停止処理
    func stopSnooze(for memoId: UUID) {
        // 該当メモのすべてのスヌーズ通知をキャンセル
        let identifiers = (1...100).map { "\(memoId.uuidString)_snooze_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        
        print("スヌーズを停止しました: \(memoId)")
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
            
            // 該当するメモを削除済みに移動（タグを維持）
            let memosToDelete = memos.filter { $0.genre == genre.name }
            for memo in memosToDelete {
                // タグを維持したまま削除済みに移動
                var deletedMemo = memo
                deletedMemo.isDeleted = true
                deletedMemos.append(deletedMemo)
                
                // 元のメモを削除
                if let index = memos.firstIndex(where: { $0.id == memo.id }) {
                    memos.remove(at: index)
                }
                
                // 通知をキャンセル
                cancelNotification(for: memo)
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
    
    // MARK: - 全ての削除済みメモを復元
    func restoreAllDeletedMemos() {
        let allDeletedMemos = filteredDeletedMemos
        for memo in allDeletedMemos {
            restoreMemo(memo)
        }
    }
    
    // MARK: - 全ての削除済みメモを完全削除
    func permanentlyDeleteAllDeletedMemos() {
        let allDeletedMemos = filteredDeletedMemos
        for memo in allDeletedMemos {
            permanentlyDelete(memo)
        }
    }
    
    // MARK: - 通常モード用の選択機能
    func toggleMemoSelection(_ memo: Memo) {
        if selectedMemos.contains(memo.id) {
            selectedMemos.remove(memo.id)
        } else {
            selectedMemos.insert(memo.id)
        }
        DispatchQueue.main.async { self.objectWillChange.send() }
    }
    
    func isMemoSelected(_ memo: Memo) -> Bool {
        return selectedMemos.contains(memo.id)
    }
    
    func clearMemoSelection() {
        selectedMemos.removeAll()
    }
    
    // MARK: - 選択されたメモを一括削除
    func bulkDeleteSelectedMemos() {
        print("📱 一括削除開始: \(selectedMemos.count)個のメモ")
        let selectedMemosList = memos.filter { selectedMemos.contains($0.id) }
        for memo in selectedMemosList {
            print("📱 一括削除対象: \(memo.title)")
            deleteMemo(memo)
        }
        selectedMemos.removeAll()
    }
    
    // MARK: - 選択されたメモを指定されたジャンルに移動
    func moveSelectedMemosToGenre(_ genreName: String) {
        let selectedMemosList = memos.filter { selectedMemos.contains($0.id) }
        for memo in selectedMemosList {
            // ジャンルが存在しない場合の処理
            if !genres.contains(where: { $0.name == genreName }) {
                // 無効なジャンル名（空文字列、無題）の場合は「メモ」に変更
                if genreName.isEmpty || genreName == "無題" {
                    updateMemoGenre(memo, genre: "メモ")
                } else {
                    // 有効なジャンル名の場合は自動的にシートを追加
                    addGenre(genreName)
                    updateMemoGenre(memo, genre: genreName)
                }
            } else {
                updateMemoGenre(memo, genre: genreName)
            }
        }
        selectedMemos.removeAll()
    }
    
    // MARK: - メモのジャンルを更新
    private func updateMemoGenre(_ memo: Memo, genre: String) {
        if let index = memos.firstIndex(where: { $0.id == memo.id }) {
            memos[index].genre = genre
            saveMemos()
        }
    }
}

