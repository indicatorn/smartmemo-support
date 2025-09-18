//
//  AddEditMemoView.swift
//  ToDo通知
//
//  Created by 印出啓人 on 2025/09/06.
//

import SwiftUI

struct AddEditMemoView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var memoManager: MemoManager
    
    let editingMemo: Memo?
    
    @State private var title: String = ""
    @State private var hasNotification: Bool = true
    @State private var notificationDate: Date = Date()
    @State private var notificationInterval: NotificationInterval = .none
    @State private var snoozeInterval: SnoozeInterval = .none
    @State private var selectedGenre: String = ""
    
    init(memoManager: MemoManager, editingMemo: Memo? = nil) {
        self.memoManager = memoManager
        self.editingMemo = editingMemo
        
        if let memo = editingMemo {
            _title = State(initialValue: memo.title)
            _hasNotification = State(initialValue: memo.notificationDate != nil)
            _notificationDate = State(initialValue: memo.notificationDate ?? Date())
            _notificationInterval = State(initialValue: memo.notificationInterval)
            _snoozeInterval = State(initialValue: memo.snoozeInterval)
            _selectedGenre = State(initialValue: memo.genre)
        } else {
            // 新しいメモの場合、現在選択されているシートをデフォルトタグとして設定
            let defaultGenre = memoManager.selectedGenre == "すべてのメモ" ? "メモ" : memoManager.selectedGenre
            _selectedGenre = State(initialValue: defaultGenre)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                headerView
                
                // コンテンツ
                contentView
                
                Spacer()
            }
            .background(Color(red: 0.95, green: 0.95, blue: 0.95))
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - ヘッダービュー
    private var headerView: some View {
        HStack {
            Button("キャンセル") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.black)
            
            Spacer()
            
            Text(editingMemo == nil ? "新規メモ" : "メモを編集")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Spacer()
            
            Button("保存") {
                saveMemo()
            }
            .foregroundColor(.black)
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color(red: 0.302, green: 0.8, blue: 0.416))
    }
    
    // MARK: - コンテンツビュー
    private var contentView: some View {
        VStack(spacing: 20) {
            // タイトル入力
            VStack(alignment: .leading, spacing: 8) {
                Text("メモ内容")
                    .font(.headline)
                    .foregroundColor(Color.black)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $title)
                        .frame(minHeight: 80, maxHeight: 120)
                        .font(.system(size: 16))
                        .padding(8)
                    
                    if title.isEmpty {
                        Text("メモを入力してください")
                            .font(.system(size: 16))
                            .foregroundColor(Color.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
                .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            
            // 通知設定
            VStack(alignment: .leading, spacing: 12) {
                Toggle("通知を設定", isOn: $hasNotification)
                    .font(.headline)
                    .foregroundColor(Color.black)
                    .tint(Color(red: 0.302, green: 0.8, blue: 0.416))
                
                if hasNotification {
                    VStack(spacing: 12) {
                        // 通知日時
                        VStack(alignment: .leading, spacing: 8) {
                            Text("通知日時")
                                .font(.subheadline)
                                .foregroundColor(Color.gray)
                            
                            DatePicker("", selection: $notificationDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "ja_JP"))
                        }
                        
                        // 通知間隔
                        VStack(alignment: .leading, spacing: 8) {
                            Text("繰り返し")
                                .font(.subheadline)
                                .foregroundColor(Color.gray)
                            
                            Picker("通知間隔", selection: $notificationInterval) {
                                ForEach(NotificationInterval.allCases, id: \.self) { interval in
                                    Text(interval.rawValue).tag(interval)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // スヌーズ間隔
                        VStack(alignment: .leading, spacing: 8) {
                            Text("スヌーズ")
                                .font(.subheadline)
                                .foregroundColor(Color.gray)
                            
                            Picker("スヌーズ間隔", selection: $snoozeInterval) {
                                ForEach(SnoozeInterval.allCases, id: \.self) { interval in
                                    Text(interval.rawValue).tag(interval)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                    .padding()
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .cornerRadius(8)
                }
            }
            
            // ジャンル選択
            VStack(alignment: .leading, spacing: 8) {
                Text("ジャンル")
                    .font(.headline)
                    .foregroundColor(Color.black)
                
                Picker("ジャンル", selection: $selectedGenre) {
                    // メモ（最初に表示）
                    if let memoGenre = memoManager.genres.first(where: { $0.name == "メモ" }) {
                        Text(memoGenre.name).tag(memoGenre.name)
                    }
                    
                    // ユーザーが作成したジャンル（メモ以外のデフォルトでないジャンル）
                    ForEach(memoManager.genres.filter { genre in
                        !genre.isDefault && genre.name != "メモ"
                    }, id: \.name) { genre in
                        Text(genre.name.isEmpty ? "タグなし" : genre.name).tag(genre.name)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - 保存処理
    private func saveMemo() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let finalNotificationDate = hasNotification ? notificationDate : nil
        let finalInterval = hasNotification ? notificationInterval : .none
        let finalSnoozeInterval = hasNotification ? snoozeInterval : .none
        let finalGenre = selectedGenre.isEmpty ? "" : selectedGenre
        
        if let editingMemo = editingMemo {
            memoManager.updateMemo(editingMemo, 
                                 title: trimmedTitle, 
                                 notificationDate: finalNotificationDate, 
                                 interval: finalInterval,
                                 snoozeInterval: finalSnoozeInterval,
                                 genre: finalGenre)
        } else {
            memoManager.addMemo(title: trimmedTitle, 
                              notificationDate: finalNotificationDate, 
                              interval: finalInterval,
                              snoozeInterval: finalSnoozeInterval,
                              genre: finalGenre)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    AddEditMemoView(memoManager: MemoManager())
}

