//
//  SideMenuView.swift
//  ToDo通知
//
//  Created by 印出啓人 on 2025/09/06.
//

import SwiftUI

struct SideMenuView: View {
    @ObservedObject var memoManager: MemoManager
    @Binding var isShowing: Bool
    @State private var showingAddGenreAlert = false
    @State private var newGenreName = ""
    @State private var editingGenre: Genre?
    @State private var editingGenreName = ""
    @State private var showingEditGenreAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ヘッダー
            headerView
            
            // 削除済み項目
            deletedItemsSection
            
            // ジャンル一覧
            genresSection
            
            Spacer()
        }
        .frame(width: 280)
        .background(Color("BackgroundColor"))
        .edgesIgnoringSafeArea(.vertical)
    }
    
    // MARK: - ヘッダー
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 追加のスペース（2行分）
            Spacer()
                .frame(height: 40)
            
            HStack {
                Text("メニュー")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.black)
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color("BackgroundColor"))
    }
    
    // MARK: - 削除済み項目セクション
    private var deletedItemsSection: some View {
        VStack(spacing: 0) {
            Button(action: {
                memoManager.showDeletedItems()
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowing = false
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.0, green: 0.478, blue: 1.0))
                        .frame(width: 24, height: 24)
                    
                    Text("削除済み")
                        .font(.system(size: 16))
                        .foregroundColor(Color.black)
                    
                    Spacer()
                    
                    let deletedCount = memoManager.selectedGenre == "すべてのメモ" ? 
                        memoManager.deletedMemos.count : 
                        memoManager.deletedMemos.filter { $0.genre == memoManager.selectedGenre }.count
                    
                    if deletedCount > 0 {
                        Text("\(deletedCount)")
                            .font(.system(size: 14))
                            .foregroundColor(Color.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(memoManager.showingDeletedItems ? Color(red: 0.0, green: 0.478, blue: 1.0).opacity(0.1) : Color.clear)
            }
            
            Divider()
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - ジャンル一覧セクション
    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // セクションタイトルとプラスボタン
            HStack {
                Text("ジャンル")
                    .font(.system(size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    newGenreName = ""
                    showingAddGenreAlert = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.0, green: 0.478, blue: 1.0))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // すべてのメモ
            if let allMemosGenre = memoManager.genres.first(where: { $0.name == "すべてのメモ" }) {
                genreRowView(for: allMemosGenre)
            }
            
            // メモシート（すべてのメモの直下）
            memoSheetRowView
            
            // その他のジャンル（ユーザーが作成したもの）
            ForEach(memoManager.genres.filter { $0.name != "すべてのメモ" && $0.name != "メモ" }) { genre in
                genreRowView(for: genre)
            }
        }
        .alert("新しいジャンルを追加", isPresented: $showingAddGenreAlert) {
            TextField("ジャンル名", text: $newGenreName)
            Button("追加") {
                if !newGenreName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    memoManager.addGenre(newGenreName.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
            Button("キャンセル", role: .cancel) { }
        }
        .alert("ジャンルを編集", isPresented: $showingEditGenreAlert) {
            TextField("ジャンル名", text: $editingGenreName)
            Button("保存") {
                if let genre = editingGenre,
                   !editingGenreName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    memoManager.updateGenre(genre, newName: editingGenreName.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
            Button("キャンセル", role: .cancel) { }
        }
    }
    
    // MARK: - ジャンル行ビュー
    private func genreRowView(for genre: Genre) -> some View {
        HStack(spacing: 12) {
            // ジャンル選択ボタン
            Button(action: {
                memoManager.selectGenre(genre.name)
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowing = false
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: genreIcon(for: genre.name))
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.0, green: 0.478, blue: 1.0))
                        .frame(width: 24, height: 24)
                    
                    Text(genre.name)
                        .font(.system(size: 16))
                        .foregroundColor(Color.black)
                    
                    Spacer()
                    
                    let count = memoManager.memos.filter { !$0.isDeleted && (genre.name == "すべてのメモ" || $0.genre == genre.name) }.count
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 14))
                            .foregroundColor(Color.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(memoManager.selectedGenre == genre.name && !memoManager.showingDeletedItems ? Color(red: 0.0, green: 0.478, blue: 1.0).opacity(0.1) : Color.clear)
            }
            
            // 編集・削除ボタン（デフォルトジャンル以外）
            if !genre.isDefault {
                Menu {
                    Button("編集") {
                        editingGenre = genre
                        editingGenreName = genre.name
                        showingEditGenreAlert = true
                    }
                    
                    Button("削除", role: .destructive) {
                        memoManager.deleteGenre(genre)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(Color.gray)
                        .frame(width: 24, height: 24)
                }
                .padding(.trailing, 16)
            }
        }
    }
    
    // MARK: - メモシート行ビュー
    private var memoSheetRowView: some View {
        Button(action: {
            memoManager.selectGenre("メモ")
            withAnimation(.easeInOut(duration: 0.3)) {
                isShowing = false
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "note.text")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.0, green: 0.478, blue: 1.0))
                    .frame(width: 24, height: 24)
                
                Text("メモ")
                    .font(.system(size: 16))
                    .foregroundColor(Color.black)
                
                Spacer()
                
                let count = memoManager.memos.filter { !$0.isDeleted && $0.genre == "メモ" }.count
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 14))
                        .foregroundColor(Color.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(memoManager.selectedGenre == "メモ" && !memoManager.showingDeletedItems ? Color(red: 0.0, green: 0.478, blue: 1.0).opacity(0.1) : Color.clear)
        }
    }
    
    // MARK: - ジャンルアイコン
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
    SideMenuView(memoManager: MemoManager(), isShowing: .constant(true))
}
