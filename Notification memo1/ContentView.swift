//
//  ContentView.swift
//  Notification memo1
//
//  Created by 印出啓人 on 2025/09/06.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var memoManager = MemoManager()
    @State private var showingAddMemo = false
    @State private var showingEditMemo: Memo?
    @State private var isEditMode = false
    @State private var selectedMemos: Set<UUID> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                headerView
                
                // 新しいメモを作成ボタン
                addMemoButton
                
                // メモリスト
                memoListView
            }
            .background(Color(red: 0.95, green: 0.95, blue: 0.95))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddMemo) {
            AddEditMemoView(memoManager: memoManager)
        }
        .sheet(item: $showingEditMemo) { memo in
            AddEditMemoView(memoManager: memoManager, editingMemo: memo)
        }
    }
    
    // MARK: - ヘッダービュー
    private var headerView: some View {
        HStack {
            Button(action: {
                // ハンバーガーメニュー（将来的に実装）
            }) {
                Image(systemName: "line.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("TODO")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                if isEditMode {
                    if selectedMemos.isEmpty {
                        // 編集モード終了
                        isEditMode = false
                    } else {
                        // 選択されたメモを削除
                        deleteSelectedMemos()
                    }
                } else {
                    // 編集モード開始 - 即座に手動並び替えモードに切り替え
                    memoManager.sortOption = .manual
                    isEditMode = true
                    selectedMemos.removeAll()
                }
            }) {
                Text(buttonTitle)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color(red: 0.4, green: 0.8, blue: 0.6))
    }
    
    // MARK: - 新しいメモを作成ボタン
    private var addMemoButton: some View {
        Button(action: {
            showingAddMemo = true
        }) {
            HStack {
                Spacer()
                Text("新しいメモを作成")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                Spacer()
            }
            .padding(.vertical, 20)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 0.4, green: 0.8, blue: 0.6), lineWidth: 2)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - メモリストビュー
    private var memoListView: some View {
        Group {
            if memoManager.showingDeletedItems {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(memoManager.deletedMemos) { memo in
                            DeletedMemoRowView(memo: memo, memoManager: memoManager)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            } else {
                List {
                    ForEach(memoManager.sortedMemos, id: \.id) { memo in
                        MemoRowView(
                            memo: memo, 
                            memoManager: memoManager,
                            isEditMode: isEditMode,
                            isSelected: selectedMemos.contains(memo.id),
                            onToggleSelection: {
                                if selectedMemos.contains(memo.id) {
                                    selectedMemos.remove(memo.id)
                                } else {
                                    selectedMemos.insert(memo.id)
                                }
                            }
                        ) {
                            if !isEditMode {
                                showingEditMemo = memo
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowSeparator(.hidden)
                        .background(Color.clear)
                    }
                    .onMove(perform: isEditMode ? moveMemos : nil)
                }
                .listStyle(PlainListStyle())
                .background(Color(red: 0.95, green: 0.95, blue: 0.95))
            }
        }
    }
    
    // MARK: - 並び替え機能
    private func moveMemos(from source: IndexSet, to destination: Int) {
        memoManager.moveMemos(from: source, to: destination)
    }
    
    // MARK: - ボタンタイトル
    private var buttonTitle: String {
        if !isEditMode {
            return "編集"
        } else if selectedMemos.isEmpty {
            return "完了"
        } else {
            return "削除"
        }
    }
    
    // MARK: - 選択されたメモを削除
    private func deleteSelectedMemos() {
        for memoId in selectedMemos {
            if let memo = memoManager.memos.first(where: { $0.id == memoId }) {
                memoManager.deleteMemo(memo)
            }
        }
        selectedMemos.removeAll()
        isEditMode = false
    }
}

// MARK: - メモ行ビュー
struct MemoRowView: View {
    let memo: Memo
    let memoManager: MemoManager
    let isEditMode: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 左端の丸いマーク
            Button(action: {
                if isEditMode {
                    // 編集モード時は選択切り替え
                    onToggleSelection()
                } else {
                    // 通常モード時は完了切り替え
                    memoManager.toggleCompletion(for: memo)
                }
            }) {
                Circle()
                    .stroke(Color.gray, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Group {
                            if isEditMode && isSelected {
                                // 編集モード時の選択状態
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            } else if !isEditMode && memo.isCompleted {
                                // 通常モード時の完了状態
                                Circle()
                                    .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                                    .frame(width: 20, height: 20)
                            }
                        }
                    )
                    .background(
                        Circle()
                            .fill(isEditMode && isSelected ? Color(red: 0.4, green: 0.8, blue: 0.6) : Color.clear)
                            .frame(width: 24, height: 24)
                    )
            }
            
            // 編集モード時のハンバーガーメニュー
            if isEditMode {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
            }
            
            // メモ内容
            VStack(alignment: .leading, spacing: 4) {
                Text(memo.title)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .strikethrough(memo.isCompleted && !isEditMode)
                
                HStack {
                    Text(memo.formattedDate)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                    
                    Spacer()
                    
                    if memo.notificationInterval != .none {
                        HStack(spacing: 4) {
                            Image(systemName: "bell")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                            Text(memo.notificationInterval.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                        }
                    }
                }
            }
            
            Spacer()
            
            // 編集モード時の削除ボタン
            if isEditMode {
                Button(action: {
                    memoManager.deleteMemo(memo)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(8)
        .onTapGesture {
            onEdit()
        }
        .swipeActions(edge: .trailing) {
            if !isEditMode {
                Button("削除") {
                    memoManager.deleteMemo(memo)
                }
                .tint(.red)
            }
        }
    }
}

// MARK: - 削除済みメモ行ビュー
struct DeletedMemoRowView: View {
    let memo: Memo
    let memoManager: MemoManager
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .stroke(Color.gray, lineWidth: 2)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(memo.title)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .strikethrough()
                
                Text(memo.formattedDate)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.8))
        .swipeActions(edge: .trailing) {
            Button("復元") {
                memoManager.restoreMemo(memo)
            }
            .tint(.green)
            
            Button("完全削除") {
                memoManager.permanentlyDelete(memo)
            }
            .tint(.red)
        }
    }
}

#Preview {
    ContentView()
}
