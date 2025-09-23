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
    @State private var showingEditDeletedMemo: Memo?
    @State private var isEditMode = false
    @State private var isDeletedEditMode = false
    @State private var showingSideMenu = false
    @State private var showingGenreSelection = false
    @State private var isKeyboardVisible = false
    
    var body: some View {
        ZStack {
            // メインコンテンツ
            NavigationView {
                VStack(spacing: 0) {
                    // ヘッダー
                    headerView
                    
                    // メモリスト
                    memoListView
                    
                    
                }
                .background(Color("BackgroundColor"))
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
            
            // フローティングアクションボタンとアクションバー（横並び）
            VStack {
                Spacer()
                HStack {
                    // アクションバー（左側）
                    if !memoManager.showingDeletedItems && !memoManager.selectedMemos.isEmpty {
                        selectedMemosActionView
                    } else if memoManager.showingDeletedItems && !memoManager.selectedDeletedMemos.isEmpty {
                        selectedDeletedMemosActionView
                    } else if memoManager.showingDeletedItems && isDeletedEditMode {
                        deletedEditButtonsView
                    } else {
                        Spacer()
                    }
                    
                    // フローティングアクションボタン（右側）
                    floatingActionButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 70) // 広告バナーの上に配置
            }
            
            // 広告バナー（最下部）
            VStack {
                Spacer()
                bannerAdView
            }
        }
            .sheet(isPresented: $showingAddMemo) {
                AddEditMemoView(memoManager: memoManager, isKeyboardVisible: $isKeyboardVisible)
                    .interactiveDismissDisabled(isKeyboardVisible)
            }
            .sheet(item: $showingEditMemo) { memo in
                AddEditMemoView(memoManager: memoManager, editingMemo: memo, isKeyboardVisible: $isKeyboardVisible)
                    .interactiveDismissDisabled(isKeyboardVisible)
            }
            .sheet(item: $showingEditDeletedMemo) { memo in
                AddEditMemoView(memoManager: memoManager, editingMemo: memo, isKeyboardVisible: $isKeyboardVisible)
                    .interactiveDismissDisabled(isKeyboardVisible)
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
                // 編集モードを解除
                isEditMode = false
                isDeletedEditMode = false
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
                        if isDeletedEditMode {
                            // 編集モード終了時に選択状態をクリア
                            memoManager.clearDeletedMemoSelection()
                        }
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
                        memoManager.clearDeletedMemoSelection()
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
        .background(Color("HeaderColor"))
    }
    
    // MARK: - フローティングアクションボタン（新規メモ作成）
    private var floatingActionButton: some View {
        Button(action: {
            showingAddMemo = true
            // 選択を解除
            if memoManager.showingDeletedItems {
                memoManager.selectedDeletedMemos.removeAll()
            } else {
                memoManager.selectedMemos.removeAll()
            }
            // 編集モードを解除
            isEditMode = false
            isDeletedEditMode = false
        }) {
            Image(systemName: "plus")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Color("AccentBlue"))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - 広告バナー
    private var bannerAdView: some View {
        HStack {
            // 左側のアイコン
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.gray)
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 中央のテキスト
            Text("広告スペース")
                .font(.system(size: 14))
                .foregroundColor(.black)
            
            Spacer()
            
            // 右側のボタン
            Button(action: {
                // 広告タップ時の処理
            }) {
                Text("開く >")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("WhiteColor"))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .top
        )
        .frame(height: 50)
    }
    
    // MARK: - メモリストビュー
    private var memoListView: some View {
        Group {
            if memoManager.showingDeletedItems {
                ZStack {
                    Color("BackgroundColor")
                        .ignoresSafeArea()
                    
                    List {
                        ForEach(memoManager.filteredDeletedMemos, id: \.id) { memo in
                            DeletedMemoRowView(
                                memo: memo, 
                                memoManager: memoManager, 
                                isDeletedEditMode: $isDeletedEditMode
                            ) {
                                if !isDeletedEditMode {
                                    showingEditDeletedMemo = memo
                                }
                            }
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .listRowSeparator(.visible, edges: [.top, .bottom])
                                .listRowBackground(Color.clear)
                        }
                        .onMove(perform: isDeletedEditMode ? moveDeletedMemos : nil)
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .environment(\.defaultMinListRowHeight, 0)
                }
                .padding(.top, 8)
                .padding(.bottom, 80) // フローティングボタンとの重なりを避ける
            } else {
                ZStack {
                    Color("BackgroundColor")
                        .ignoresSafeArea()
                    
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
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowSeparator(.visible, edges: [.top, .bottom])
                            .listRowBackground(Color.clear)
                        }
                        .onMove(perform: isEditMode ? moveMemos : nil)
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .environment(\.defaultMinListRowHeight, 0)
                }
                .padding(.top, 8)
                .padding(.bottom, 80) // フローティングボタンとの重なりを避ける
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
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            Button(action: {
                // 全て削除
                memoManager.permanentlyDeleteAllDeletedMemos()
                isDeletedEditMode = false
            }) {
                Text("全て削除")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("WhiteColor"))
        .cornerRadius(8)
    }
    
    // MARK: - 選択された削除済みメモ用のアクションバー
    private var selectedDeletedMemosActionView: some View {
        HStack {
            Button(action: {
                memoManager.bulkRestoreSelectedDeletedMemos()
            }) {
                Text("復元")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
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
                    .foregroundColor(Color(red: 0.0, green: 0.478, blue: 1.0))
            }
            
            Spacer()
            
            Button(action: {
                memoManager.bulkPermanentlyDeleteSelectedDeletedMemos()
            }) {
                Text("削除")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("WhiteColor"))
        .cornerRadius(8)
    }
    
    // MARK: - 選択されたメモ用のアクションバー
    private var selectedMemosActionView: some View {
        HStack {
            Button(action: {
                showingGenreSelection = true
            }) {
                Text("移動")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.purple)
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
                    .foregroundColor(Color(red: 0.0, green: 0.478, blue: 1.0))
            }
            
            Spacer()
            
            Button(action: {
                print("📱 アクションバー削除実行: \(memoManager.selectedMemos.count)個のメモ")
                // 選択されたメモを削除済みに移動
                memoManager.bulkDeleteSelectedMemos()
            }) {
                Text("削除")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("WhiteColor"))
        .cornerRadius(8)
    }
    
    // MARK: - 並び替え機能
    private func moveMemos(from source: IndexSet, to destination: Int) {
        memoManager.moveMemos(from: source, to: destination)
    }
    
    private func moveDeletedMemos(from source: IndexSet, to destination: Int) {
        memoManager.moveDeletedMemos(from: source, to: destination)
    }
}

// MARK: - メモ行ビュー
struct MemoRowView: View {
    let memo: Memo
    let memoManager: MemoManager
    let isEditMode: Bool
    let onEdit: () -> Void
    
    @State private var isShaking = false
    @State private var shakeOffset: CGFloat = 0
    @State private var shakeTimer: Timer?
    
    var body: some View {
        HStack(spacing: 12) {
            // 編集モード時の左側余白
            if isEditMode {
                Spacer()
                    .frame(width: 8)
            }
            
            // 通常モードでのみチェックボタンを表示
            if !isEditMode {
                ZStack {
                    // 枠線の円
                    Circle()
                        .stroke(Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    // 選択状態の表示
                    if memoManager.isMemoSelected(memo) {
                        Circle()
                            .fill(Color("AccentBlue"))
                            .frame(width: 16, height: 16)
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .onTapGesture {
                    memoManager.toggleMemoSelection(memo)
                }
                .padding(.leading, 12)
            }
            
            // 編集モード時のハンバーガーメニュー
            if isEditMode {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 22))
                    .foregroundColor(Color.gray)
                    .frame(width: 44, height: 44)
                    .padding(.leading, -6)
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
                            .background(Color("TagBackgroundColor"))
                            .cornerRadius(4)
                    }
                }
                
                HStack {
                    // 通知日時がある場合のみ表示
                    if memo.notificationDate != nil {
                        Text(memo.formattedNotificationDate)
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.0, green: 0.478, blue: 1.0))
                    }
                    
                    Spacer()
                    
                    // 通知頻度タグ
                    HStack(spacing: 8) {
                        // 繰り返し設定
                        if memo.notificationInterval != .none {
                            HStack(spacing: 4) {
                                Image(systemName: "bell")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.0, green: 0.478, blue: 1.0))
                                Text(memo.notificationInterval.rawValue)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.0, green: 0.478, blue: 1.0))
                            }
                        }
                        
                        // スヌーズ設定
                        if memo.snoozeInterval != .none {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.0, green: 0.478, blue: 1.0))
                                Text(memo.snoozeInterval.rawValue)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.0, green: 0.478, blue: 1.0))
                            }
                        }
                    }
                }
            }
            .offset(x: shakeOffset)
            .onAppear {
                if isEditMode {
                    startShaking()
                }
            }
            .onChange(of: isEditMode) { editMode in
                if editMode {
                    startShaking()
                } else {
                    stopShaking()
                }
            }
            
            Spacer()
            
            // 編集モード時の削除ボタン
            if isEditMode {
                Button(action: {
                    print("📱 編集モード削除ボタン実行: \(memo.title)")
                    memoManager.deleteMemo(memo)
                }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 16)
            }
        }
        .padding(.vertical, 12)
        .background(
            Group {
                let isSelected = memoManager.isMemoSelected(memo)
                return isSelected ? 
                    Color("AccentBlue").opacity(0.1) : 
                    Color("WhiteColor")
            }
        )
        .cornerRadius(8)
        .onTapGesture {
            if !isEditMode {
                onEdit()
            }
        }
        .swipeActions(edge: .trailing) {
            if !isEditMode {
                Button("削除") {
                    print("📱 スワイプ削除実行: \(memo.title)")
                    memoManager.deleteMemo(memo)
                }
                .tint(.red)
            }
        }
    }
    
    private func startShaking() {
        isShaking = true
        
        // Timerを使用した振動実装
        shakeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                shakeOffset = shakeOffset == 2 ? -2 : 2
            }
        }
    }
    
    private func stopShaking() {
        isShaking = false
        shakeTimer?.invalidate()
        shakeTimer = nil
        withAnimation(.easeOut(duration: 0.2)) {
            shakeOffset = 0
        }
    }
}

// MARK: - 削除済みメモ行ビュー
struct DeletedMemoRowView: View {
    let memo: Memo
    @ObservedObject var memoManager: MemoManager
    @Binding var isDeletedEditMode: Bool
    let onEdit: () -> Void
    
    @State private var isShaking = false
    @State private var shakeOffset: CGFloat = 0
    @State private var shakeTimer: Timer?
    
    var body: some View {
        HStack(spacing: 12) {
            // 編集モード時の左側余白
            if isDeletedEditMode {
                Spacer()
                    .frame(width: 8)
            }
            
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
                            .fill(Color("AccentBlue"))
                            .frame(width: 16, height: 16)
                            .onAppear {
                            }
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .onTapGesture {
                    memoManager.toggleDeletedMemoSelection(memo)
                }
                .padding(.leading, 12)
            }
            
            // 編集モード時のハンバーガーメニュー
            if isDeletedEditMode {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 22))
                    .foregroundColor(Color.gray)
                    .frame(width: 44, height: 44)
                    .padding(.leading, -6)
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
                            .background(Color("TagBackgroundColor"))
                            .cornerRadius(4)
                    }
                }
                
                // 通知日時がある場合のみ表示
                if memo.notificationDate != nil {
                    Text(memo.formattedNotificationDate)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.0, green: 0.478, blue: 1.0))
                }
            }
            .offset(x: shakeOffset)
            .onAppear {
                if isDeletedEditMode {
                    startShaking()
                }
            }
            .onChange(of: isDeletedEditMode) { editMode in
                if editMode {
                    startShaking()
                } else {
                    stopShaking()
                }
            }
            .onTapGesture {
                // 編集モードでない場合のみ編集可能
                if !isDeletedEditMode {
                    onEdit()
                }
            }
            
            Spacer()
            
            // 編集モード時の完全削除ボタン
            if isDeletedEditMode {
                Button(action: {
                    memoManager.permanentlyDelete(memo)
                }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 16)
            }
        }
        .padding(.vertical, 12)
        .background(
            memoManager.isDeletedMemoSelected(memo) ? 
                Color("AccentBlue").opacity(0.1) : 
                Color("WhiteColor")
        )
        .cornerRadius(8)
        .onTapGesture {
            // 編集モード時は何もしない（個別のタップジェスチャーで処理）
            if !isDeletedEditMode {
                memoManager.toggleDeletedMemoSelection(memo)
            }
        }
        .swipeActions(edge: .trailing) {
            Button("復元") {
                memoManager.restoreMemo(memo)
            }
            .tint(.green)
            
            Button("削除") {
                memoManager.permanentlyDelete(memo)
            }
            .tint(.red)
        }
    }
    
    private func startShaking() {
        isShaking = true
        
        // Timerを使用した振動実装
        shakeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                shakeOffset = shakeOffset == 2 ? -2 : 2
            }
        }
    }
    
    private func stopShaking() {
        isShaking = false
        shakeTimer?.invalidate()
        shakeTimer = nil
        withAnimation(.easeOut(duration: 0.2)) {
            shakeOffset = 0
        }
    }
}

// MARK: - ジャンル選択ビュー
struct GenreSelectionView: View {
    @ObservedObject var memoManager: MemoManager
    @Binding var showingGenreSelection: Bool
    
    init(memoManager: MemoManager, showingGenreSelection: Binding<Bool>) {
        self.memoManager = memoManager
        self._showingGenreSelection = showingGenreSelection
        
        // ナビゲーションバーの色を設定
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                List {
                    // メモ（最初に表示）
                    if let memoGenre = memoManager.genres.first(where: { $0.name == "メモ" }) {
                        genreSelectionRow(for: memoGenre)
                            .listRowBackground(Color.white)
                    }
                    
                    // ユーザーが作成したジャンル（メモ以外のデフォルトでないジャンル）
                    ForEach(memoManager.genres.filter { genre in
                        !genre.isDefault && genre.name != "メモ"
                    }) { genre in
                        genreSelectionRow(for: genre)
                            .listRowBackground(Color.white)
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("ジャンルを選択")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("キャンセル") {
                    showingGenreSelection = false
                }
                .foregroundColor(.black)
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
                    .foregroundColor(Color("AccentBlue"))
                    .frame(width: 24)
                
                Text(genre.name)
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(Color.white)
            .contentShape(Rectangle())
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
