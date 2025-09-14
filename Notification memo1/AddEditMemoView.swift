//
//  AddEditMemoView.swift
//  Notification memo1
//
//  Created by 印出啓人 on 2025/09/06.
//

import SwiftUI

struct AddEditMemoView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var memoManager: MemoManager
    
    let editingMemo: Memo?
    
    @State private var title: String = ""
    @State private var hasNotification: Bool = false
    @State private var notificationDate: Date = Date()
    @State private var notificationInterval: NotificationInterval = .none
    
    init(memoManager: MemoManager, editingMemo: Memo? = nil) {
        self.memoManager = memoManager
        self.editingMemo = editingMemo
        
        if let memo = editingMemo {
            _title = State(initialValue: memo.title)
            _hasNotification = State(initialValue: memo.notificationDate != nil)
            _notificationDate = State(initialValue: memo.notificationDate ?? Date())
            _notificationInterval = State(initialValue: memo.notificationInterval)
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
            .foregroundColor(.white)
            
            Spacer()
            
            Text(editingMemo == nil ? "新しいメモ" : "メモを編集")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("保存") {
                saveMemo()
            }
            .foregroundColor(.white)
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color(red: 0.4, green: 0.8, blue: 0.6))
    }
    
    // MARK: - コンテンツビュー
    private var contentView: some View {
        VStack(spacing: 20) {
            // タイトル入力
            VStack(alignment: .leading, spacing: 8) {
                Text("メモ内容")
                    .font(.headline)
                    .foregroundColor(.black)
                
                TextField("メモを入力してください", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 16))
            }
            
            // 通知設定
            VStack(alignment: .leading, spacing: 12) {
                Toggle("通知を設定", isOn: $hasNotification)
                    .font(.headline)
                    .foregroundColor(.black)
                
                if hasNotification {
                    VStack(spacing: 12) {
                        // 通知日時
                        VStack(alignment: .leading, spacing: 8) {
                            Text("通知日時")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            DatePicker("", selection: $notificationDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                        }
                        
                        // 通知間隔
                        VStack(alignment: .leading, spacing: 8) {
                            Text("繰り返し")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Picker("通知間隔", selection: $notificationInterval) {
                                ForEach(NotificationInterval.allCases, id: \.self) { interval in
                                    Text(interval.rawValue).tag(interval)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                }
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
        
        if let editingMemo = editingMemo {
            memoManager.updateMemo(editingMemo, 
                                 title: trimmedTitle, 
                                 notificationDate: finalNotificationDate, 
                                 interval: finalInterval)
        } else {
            memoManager.addMemo(title: trimmedTitle, 
                              notificationDate: finalNotificationDate, 
                              interval: finalInterval)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    AddEditMemoView(memoManager: MemoManager())
}

