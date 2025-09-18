//
//  ContentView.swift
//  ToDo通知
//
//  Created by 印出啓人 on 2025/09/06.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var memoManager = MemoManager()
    @State private var showingAddMemo = false
    @State private var showingEditMemo: Memo?
    @State private var isEditMode = false
    @State private var isDeletedEditMode = false
    @State private var showingSideMenu = false
    @State private var showingGenreSelection = false
    
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
                    
                    // 削除済み編集モード用のボタン
                    if memoManager.showingDeletedItems && isDeletedEditMode {
                        deletedEditButtonsView
                    }
                    
                    // 削除済みメモ選択時のアクションバー
                    if memoManager.showingDeletedItems && !memoManager.selectedDeletedMemos.isEmpty {
                        selectedDeletedMemosActionView
                    }
                    
                    // 通常モードでメモ選択時のアクションバー
                    if !memoManager.showingDeletedItems && !memoManager.selectedMemos.isEmpty {
                        selectedMemosActionView
                    }
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
            .sheet(isPresented: $showingGenreSelection) {
                GenreSelectionView(memoManager: memoManager, showingGenreSelection: $showingGenreSelection)
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
                // 選択を解除
                if memoManager.showingDeletedItems {
                    memoManager.selectedDeletedMemos.removeAll()
                } else {
                    memoManager.selectedMemos.removeAll()
                }
            }) {
                Image(systemName: "line.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            Text(memoManager.showingDeletedItems ? "削除済み" : memoManager.selectedGenre)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Spacer()
            
            // 削除済み表示時は編集ボタン（選択なし時のみ）、通常時は編集ボタン
            if memoManager.showingDeletedItems {
                if memoManager.selectedDeletedMemos.isEmpty {
                    Button(action: {
                        isDeletedEditMode.toggle()
                    }) {
                        Text(isDeletedEditMode ? "完了" : "編集")
                            .font(.system(size: 16))
                            .foregroundColor(Color.black)
                    }
                } else {
                    // 選択ありの時は透明なボタンでスペースを確保
                    Button(action: {}) {
                        Text("編集")
                            .font(.system(size: 16))
                            .foregroundColor(.clear)
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
                        // 選択を解除
                        memoManager.clearMemoSelection()
                    }
                }) {
                    Text(isEditMode ? "完了" : "編集")
                        .font(.system(size: 16))
                        .foregroundColor(Color.black)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color(red: 0.302, green: 0.8, blue: 0.416))
    }
    
    // MARK: - 新しいメモを作成ボタン
    private var addMemoButton: some View {
        Button(action: {
            showingAddMemo = true
            // 選択を解除
            if memoManager.showingDeletedItems {
                memoManager.selectedDeletedMemos.removeAll()
            } else {
                memoManager.selectedMemos.removeAll()
            }
        }) {
            HStack {
                Spacer()
                Text("新規メモ作成")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.302, green: 0.8, blue: 0.416))
                Spacer()
            }
            .padding(.vertical, 20)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 0.302, green: 0.8, blue: 0.416), lineWidth: 2)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - メモリストビュー
    private var memoListView: some View {
        Group {
            if memoManager.showingDeletedItems {
                List {
                    ForEach(memoManager.filteredDeletedMemos, id: \.id) { memo in
                        DeletedMemoRowView(memo: memo, memoManager: memoManager, isDeletedEditMode: $isDeletedEditMode)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .listRowSeparator(.visible)
                            .background(Color.clear)
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                .padding(.top, 8)
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
                        .listRowSeparator(.visible)
                        .background(Color.clear)
                    }
                    .onMove(perform: isEditMode ? moveMemos : nil)
                }
                .listStyle(PlainListStyle())
                .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - 削除済み編集モード用のボタン
    private var deletedEditButtonsView: some View {
        HStack {
            Button(action: {
                // 全て復元
                memoManager.restoreAllDeletedMemos()
                isDeletedEditMode = false
            }) {
                Text("全て復元")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: {
                // 全て削除
                memoManager.permanentlyDeleteAllDeletedMemos()
                isDeletedEditMode = false
            }) {
                Text("全て削除")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.1))
        .padding(.bottom, 20)
    }
    
    // MARK: - 選択された削除済みメモ用のアクションバー
    private var selectedDeletedMemosActionView: some View {
        HStack {
            Button(action: {
                memoManager.bulkRestoreSelectedDeletedMemos()
            }) {
                Text("復元")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.302, green: 0.8, blue: 0.416))
            }
            
            Spacer()
            
            Button(action: {
                // 全ての削除済みメモを選択
                let allDeletedMemoIds = Set(memoManager.filteredDeletedMemos.map { $0.id })
                
                // すでに全て選択されている場合は選択解除、そうでなければ全て選択
                if memoManager.selectedDeletedMemos == allDeletedMemoIds {
                    memoManager.selectedDeletedMemos.removeAll()
                } else {
                    memoManager.selectedDeletedMemos = allDeletedMemoIds
                }
            }) {
                Text("全て選択")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.302, green: 0.8, blue: 0.416))
            }
            
            Spacer()
            
            Button(action: {
                memoManager.bulkPermanentlyDeleteSelectedDeletedMemos()
            }) {
                Text("削除")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.302, green: 0.8, blue: 0.416))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.1))
        .padding(.bottom, 20)
    }
    
    // MARK: - 選択されたメモ用のアクションバー
    private var selectedMemosActionView: some View {
        HStack {
            Button(action: {
                showingGenreSelection = true
            }) {
                Text("移動")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.302, green: 0.8, blue: 0.416))
            }
            
            Spacer()
            
            Button(action: {
                // 全てのメモを選択
                let allMemoIds = Set(memoManager.sortedMemos.map { $0.id })
                
                // すでに全て選択されている場合は選択解除、そうでなければ全て選択
                if memoManager.selectedMemos == allMemoIds {
                    memoManager.selectedMemos.removeAll()
                } else {
                    memoManager.selectedMemos = allMemoIds
                }
            }) {
                Text("全て選択")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.302, green: 0.8, blue: 0.416))
            }
            
            Spacer()
            
            Button(action: {
                // 選択されたメモを削除済みに移動
                memoManager.bulkDeleteSelectedMemos()
            }) {
                Text("削除")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.302, green: 0.8, blue: 0.416))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.1))
        .padding(.bottom, 20)
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
                    print("メモ選択切り替え実行")
                    memoManager.toggleMemoSelection(memo)
                }) {
                    ZStack {
                        // 枠線の円
                        Circle()
                            .stroke(Color.gray, lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        // 選択状態の表示
                        if memoManager.isMemoSelected(memo) {
                            Circle()
                                .fill(Color(red: 0.302, green: 0.8, blue: 0.416))
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
                    .foregroundColor(Color.gray)
                    .frame(width: 24, height: 24)
            }
            
            // メモ内容
            VStack(alignment: .leading, spacing: 4) {
                // メモタイトル（ジャンル名は右端に配置）
                HStack {
                    Text(memo.title)
                        .font(.system(size: 16))
                        .foregroundColor(Color.black)
                    
                    // ジャンル名表示（すべてのメモ表示時または削除済み表示時、メモ本文の1番右に配置）
                    // 「メモ」タグは非表示にする
                    if (memoManager.selectedGenre == "すべてのメモ" || memoManager.showingDeletedItems) && memo.genre != "すべてのメモ" && memo.genre != "メモ" {
                        Text(memo.genre.isEmpty ? "タグなし" : memo.genre)
                            .font(.system(size: 12))
                            .foregroundColor(Color.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                HStack {
                    Text(memo.formattedDate)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.302, green: 0.8, blue: 0.416))
                    
                    Spacer()
                    
                    // 通知頻度タグ
                    HStack(spacing: 8) {
                        // 繰り返し設定
                        if memo.notificationInterval != .none {
                            HStack(spacing: 4) {
                                Image(systemName: "bell")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.302, green: 0.8, blue: 0.416))
                                Text(memo.notificationInterval.rawValue)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.302, green: 0.8, blue: 0.416))
                            }
                        }
                        
                        // スヌーズ設定
                        if memo.snoozeInterval != .none {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.302, green: 0.8, blue: 0.416))
                                Text(memo.snoozeInterval.rawValue)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.302, green: 0.8, blue: 0.416))
                            }
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
                        .foregroundColor(Color.black)
                }
                .buttonStyle(PlainButtonStyle())
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
                .tint(.black)
            }
        }
    }
}

// MARK: - 削除済みメモ行ビュー
struct DeletedMemoRowView: View {
    let memo: Memo
    @ObservedObject var memoManager: MemoManager
    @Binding var isDeletedEditMode: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // 選択ボタン（編集モードの場合は非表示）
            if !isDeletedEditMode {
                ZStack {
                    // 枠線の円
                    Circle()
                        .stroke(Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    // 選択状態の表示（通常モードと同じ仕様）
                    if memoManager.isDeletedMemoSelected(memo) {
                        Circle()
                            .fill(Color(red: 0.302, green: 0.8, blue: 0.416))
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
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // メモタイトルとジャンル名を横並びに
                HStack {
                    Text(memo.title)
                        .font(.system(size: 16))
                        .foregroundColor(Color.black)
                    
                    // ジャンル名表示（削除済み表示時、メモ本文の1番右に配置）
                    // 「メモ」タグは非表示にする
                    if (memoManager.selectedGenre == "すべてのメモ" || memoManager.showingDeletedItems) && memo.genre != "すべてのメモ" && memo.genre != "メモ" {
                        Text(memo.genre.isEmpty ? "タグなし" : memo.genre)
                            .font(.system(size: 12))
                            .foregroundColor(Color.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Text(memo.formattedDate)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.302, green: 0.8, blue: 0.416))
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
                    Color(red: 0.302, green: 0.8, blue: 0.416).opacity(0.1) : 
                    Color.white.opacity(0.8)
            }
        )
        .cornerRadius(8)
        .onTapGesture {
            print("削除済みメモ行タップ: \(memo.title)")
            memoManager.toggleDeletedMemoSelection(memo)
            // 編集モードの場合は解除
            if isDeletedEditMode {
                isDeletedEditMode = false
            }
        }
        .swipeActions(edge: .trailing) {
            Button("復元") {
                memoManager.restoreMemo(memo)
            }
            .tint(Color(red: 0.302, green: 0.8, blue: 0.416))
            
            Button("削除") {
                memoManager.permanentlyDelete(memo)
            }
            .tint(Color(red: 0.302, green: 0.8, blue: 0.416))
        }
    }
}

// MARK: - ジャンル選択ビュー
struct GenreSelectionView: View {
    @ObservedObject var memoManager: MemoManager
    @Binding var showingGenreSelection: Bool
    
    var body: some View {
        NavigationView {
            List {
                // メモ（最初に表示）
                if let memoGenre = memoManager.genres.first(where: { $0.name == "メモ" }) {
                    genreSelectionRow(for: memoGenre)
                }
                
                // ユーザーが作成したジャンル（メモ以外のデフォルトでないジャンル）
                ForEach(memoManager.genres.filter { genre in
                    !genre.isDefault && genre.name != "メモ"
                }) { genre in
                    genreSelectionRow(for: genre)
                }
            }
            .navigationTitle("ジャンルを選択")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("キャンセル") {
                    showingGenreSelection = false
                }
            )
        }
    }
    
    // MARK: - ジャンル選択行ビュー
    private func genreSelectionRow(for genre: Genre) -> some View {
        Button(action: {
            // 選択されたメモを指定されたジャンルに移動
            memoManager.moveSelectedMemosToGenre(genre.name)
            showingGenreSelection = false
        }) {
            HStack {
                Image(systemName: genreIcon(for: genre.name))
                    .foregroundColor(Color.black)
                    .frame(width: 24)
                
                Text(genre.name)
                    .foregroundColor(Color.black)
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func genreIcon(for genreName: String) -> String {
        switch genreName {
        case "すべてのメモ":
            return "doc.text"
        case "買い物":
            return "cart"
        case "仕事":
            return "briefcase"
        case "プライベート":
            return "person"
        case "勉強", "学習":
            return "book"
        case "健康", "フィットネス":
            return "heart"
        case "旅行":
            return "airplane"
        case "家事":
            return "house"
        case "趣味":
            return "star"
        case "家族":
            return "person.2"
        case "友達":
            return "person.3"
        case "医療", "病院":
            return "cross.case"
        case "会議":
            return "person.2.square.stack"
        case "プロジェクト":
            return "folder.badge.gearshape"
        case "アイデア":
            return "lightbulb"
        case "目標":
            return "target"
        case "メモ", "メモリー":
            return "note.text"
        case "リスト":
            return "list.bullet"
        case "スケジュール":
            return "calendar"
        case "タスク":
            return "checkmark.circle"
        default:
            return "folder"
        }
    }
}

#Preview {
    ContentView()
}
