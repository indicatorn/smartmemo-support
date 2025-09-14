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
    @State private var showingSortOptions = false
    
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
        .actionSheet(isPresented: $showingSortOptions) {
            ActionSheet(
                title: Text("並び替え"),
                buttons: SortOption.allCases.map { option in
                    .default(Text(option.rawValue)) {
                        memoManager.sortOption = option
                    }
                } + [.cancel()]
            )
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
                showingSortOptions = true
            }) {
                Text("編集")
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
        ScrollView {
            LazyVStack(spacing: 0) {
                if memoManager.showingDeletedItems {
                    ForEach(memoManager.deletedMemos) { memo in
                        DeletedMemoRowView(memo: memo, memoManager: memoManager)
                    }
                } else {
                    ForEach(memoManager.sortedMemos) { memo in
                        MemoRowView(memo: memo, memoManager: memoManager) {
                            showingEditMemo = memo
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
}

// MARK: - メモ行ビュー
struct MemoRowView: View {
    let memo: Memo
    let memoManager: MemoManager
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // チェックボックス
            Button(action: {
                memoManager.toggleCompletion(for: memo)
            }) {
                Circle()
                    .stroke(Color.gray, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .fill(memo.isCompleted ? Color(red: 0.4, green: 0.8, blue: 0.6) : Color.clear)
                            .frame(width: 20, height: 20)
                    )
            }
            
            // メモ内容
            VStack(alignment: .leading, spacing: 4) {
                Text(memo.title)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .strikethrough(memo.isCompleted)
                
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
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white)
        .onTapGesture {
            onEdit()
        }
        .swipeActions(edge: .trailing) {
            Button("削除") {
                memoManager.deleteMemo(memo)
            }
            .tint(.red)
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
