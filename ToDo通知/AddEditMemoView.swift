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
    @Binding var isKeyboardVisible: Bool
    
    @State private var title: String = ""
    @State private var hasNotification: Bool = true
    @State private var notificationDate: Date = Date()
    @State private var notificationInterval: NotificationInterval = .none
    @State private var snoozeInterval: SnoozeInterval = .none
    @State private var selectedGenre: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    init(memoManager: MemoManager, editingMemo: Memo? = nil, isKeyboardVisible: Binding<Bool> = .constant(false)) {
        self.memoManager = memoManager
        self.editingMemo = editingMemo
        self._isKeyboardVisible = isKeyboardVisible
        
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
                
                // コンテンツ（ScrollViewで囲む）
                ScrollView {
                    contentView
                        .padding(.bottom, 20)
                }
                .background(Color("BackgroundColor"))
            }
                .background(Color("BackgroundColor"))
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - ヘッダービュー
    private var headerView: some View {
        HStack {
            Button("キャンセル") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(Color("TextColor"))
            
            Spacer()
            
            Text(editingMemo == nil ? "新規メモ" : "メモを編集")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("TextColor"))
            
            Spacer()
            
            Button("保存") {
                saveMemo()
            }
            .foregroundColor(Color("TextColor"))
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color("HeaderColor"))
    }
    
    // MARK: - コンテンツビュー
    private var contentView: some View {
        VStack(spacing: 20) {
            // タイトル入力
            VStack(alignment: .leading, spacing: 8) {
                Text("メモ内容")
                    .font(.headline)
                    .foregroundColor(Color("TextColor"))
                
                TextField("メモを入力してください", text: $title, axis: .vertical)
                    .frame(minHeight: 80, maxHeight: 120)
                    .font(.system(size: 16))
                    .foregroundColor(Color("TextColor"))
                    .padding(8)
                    .lineLimit(5...10)
                    .focused($isTextFieldFocused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("完了") {
                                isTextFieldFocused = false
                            }
                        }
                    }
                .background(Color("BackgroundColor"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            
            // 通知設定
            VStack(alignment: .leading, spacing: 12) {
                Toggle("通知を設定", isOn: $hasNotification)
                    .font(.headline)
                    .foregroundColor(Color("TextColor"))
                    .tint(Color("AccentBlue"))
                
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
                                .accentColor(Color("AccentBlue"))
                                .colorScheme(.light)
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
                            .accentColor(Color("AccentBlue"))
                            .colorScheme(.light)
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
                            .accentColor(Color("AccentBlue"))
                            .colorScheme(.light)
                        }
                    }
                    .padding()
                    .background(Color("BackgroundColor"))
                    .cornerRadius(8)
                }
            }
            
            // ジャンル選択
            VStack(alignment: .leading, spacing: 12) {
                Text("ジャンル")
                    .font(.headline)
                    .foregroundColor(Color("TextColor"))
                
                VStack(alignment: .leading, spacing: 8) {
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
                    .padding(.vertical, 12)
                    .background(Color("BackgroundColor"))
                    .cornerRadius(12)
                    .accentColor(Color("AccentBlue"))
                    .colorScheme(.light)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .onAppear {
            // 新規作成時のみ自動でフォーカス
            if editingMemo == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextFieldFocused = true
                }
            }
        }
        .onTapGesture {
            // キーボードを閉じるためのタップジェスチャー
            if isTextFieldFocused {
                isTextFieldFocused = false
            }
        }
        .onChange(of: isTextFieldFocused) { focused in
            isKeyboardVisible = focused
        }
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

