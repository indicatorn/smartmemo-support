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
    @State private var showingSideMenu = false
    
    var body: some View {
        ZStack {
            // メインコンテンツ
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
            .offset(x: showingSideMenu ? 280 : 0)
            .scaleEffect(showingSideMenu ? 0.9 : 1.0)
            .overlay(
                // サイドメニュー表示時のオーバーレイ
                showingSideMenu ? 
                Color.black.opacity(0.3)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingSideMenu = false
                        }
                    }
                : nil
            )
            
            // サイドメニュー
            if showingSideMenu {
                HStack {
                    SideMenuView(memoManager: memoManager, isShowing: $showingSideMenu)
                    Spacer()
                }
                .transition(.move(edge: .leading))
            }
        }
        .sheet(isPresented: $showingAddMemo) {
            AddEditMemoView(memoManager: memoManager)
        }
        .sheet(item: $showingEditMemo) { memo in
            AddEditMemoView(memoManager: memoManager, editingMemo: memo)
        }
        .onChange(of: showingAddMemo) { newValue in
            if newValue {
                // メモ作成画面を開く時はサイドメニューを閉じる
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingSideMenu = false
                }
            }
        }
    }
    
    // MARK: - ヘッダービュー
    private var headerView: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingSideMenu.toggle()
                }
            }) {
                Image(systemName: "line.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text(memoManager.showingDeletedItems ? "削除済み (\(memoManager.selectedGenre))" : memoManager.selectedGenre)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            // 削除済み表示時は一括操作ボタン、通常時は編集ボタン
            if memoManager.showingDeletedItems {
                HStack(spacing: 12) {
                    if !memoManager.selectedDeletedMemos.isEmpty {
                        Button(action: {
                            memoManager.bulkRestoreSelectedDeletedMemos()
                        }) {
                            Text("復元")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            memoManager.bulkPermanentlyDeleteSelectedDeletedMemos()
                        }) {
                            Text("完全削除")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                    } else {
                        Text("削除済み")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
            } else {
                Button(action: {
                    if isEditMode {
                        // 編集モード終了
                        isEditMode = false
                    } else {
                        // 編集モード開始 - 即座に手動並び替えモードに切り替え
                        memoManager.sortOption = .manual
                        isEditMode = true
                    }
                }) {
                    Text(isEditMode ? "完了" : "編集")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
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
                        ForEach(memoManager.filteredDeletedMemos) { memo in
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
                            isEditMode: isEditMode
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
}

// MARK: - メモ行ビュー
struct MemoRowView: View {
    let memo: Memo
    let memoManager: MemoManager
    let isEditMode: Bool
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 通常モードでのみチェックボタンを表示
            if !isEditMode {
                Button(action: {
                    print("完了切り替え実行")
                    memoManager.toggleCompletion(for: memo)
                }) {
                    ZStack {
                        // 枠線の円
                        Circle()
                            .stroke(Color.gray, lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        // 完了状態の表示
                        if memo.isCompleted {
                            Circle()
                                .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                                .frame(width: 16, height: 16)
                        }
                    }
                }
                .frame(width: 44, height: 44) // タップ領域を広げる
                .contentShape(Rectangle()) // タップ可能領域を明確にする
                .buttonStyle(PlainButtonStyle()) // ボタンスタイルを明確にする
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
                // メモタイトル（ジャンル名は右端に配置）
                HStack {
                    Text(memo.title)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                    
                    // ジャンル名表示（すべてのメモ表示時または削除済み表示時、メモ本文の1番右に配置）
                    if (memoManager.selectedGenre == "すべてのメモ" || memoManager.showingDeletedItems) && memo.genre != "すべてのメモ" {
                        Text(memo.genre)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                HStack {
                    Text(memo.formattedDate)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                    
                    Spacer()
                    
                    // 通知頻度タグ
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
            if !isEditMode {
                onEdit()
            }
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
    @ObservedObject var memoManager: MemoManager
    
    var body: some View {
        HStack(spacing: 12) {
            // 選択ボタン
            ZStack {
                // 枠線の円
                Circle()
                    .stroke(Color.gray, lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                // 選択状態の表示（通常モードと同じ仕様）
                if memoManager.isDeletedMemoSelected(memo) {
                    Circle()
                        .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                        .frame(width: 16, height: 16)
                        .onAppear {
                            print("選択状態の円を表示: \(memo.title)")
                        }
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .onTapGesture {
                print("削除済みメモボタンタップ: \(memo.title)")
                memoManager.toggleDeletedMemoSelection(memo)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // メモタイトルとジャンル名を横並びに
                HStack {
                    Text(memo.title)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                    
                    // ジャンル名表示（削除済み表示時、メモ本文の1番右に配置）
                    if (memoManager.selectedGenre == "すべてのメモ" || memoManager.showingDeletedItems) && memo.genre != "すべてのメモ" {
                        Text(memo.genre)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Text(memo.formattedDate)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            Group {
                let isSelected = memoManager.isDeletedMemoSelected(memo)
                print("背景色設定: \(memo.title) - 選択状態: \(isSelected)")
                return isSelected ? 
                    Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.1) : 
                    Color.white.opacity(0.8)
            }
        )
        .cornerRadius(8)
        .onTapGesture {
            print("削除済みメモ行タップ: \(memo.title)")
            memoManager.toggleDeletedMemoSelection(memo)
        }
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
