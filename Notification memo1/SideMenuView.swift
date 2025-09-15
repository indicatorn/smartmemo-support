//
//  SideMenuView.swift
//  Notification memo1
//
//  Created by 印出啓人 on 2025/09/06.
//

import SwiftUI

struct SideMenuView: View {
    @ObservedObject var memoManager: MemoManager
    @Binding var isShowing: Bool
    
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
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .edgesIgnoringSafeArea(.vertical)
    }
    
    // MARK: - ヘッダー
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("メニュー")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color.white)
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
                        .foregroundColor(.red)
                        .frame(width: 24, height: 24)
                    
                    Text("削除済み")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    if !memoManager.deletedMemos.isEmpty {
                        Text("\(memoManager.deletedMemos.count)")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(memoManager.showingDeletedItems ? Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.1) : Color.clear)
            }
            
            Divider()
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - ジャンル一覧セクション
    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // セクションタイトル
            HStack {
                Text("ジャンル")
                    .font(.system(size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                Spacer()
            }
            
            // ジャンルリスト
            ForEach(memoManager.genres) { genre in
                Button(action: {
                    memoManager.selectGenre(genre.name)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowing = false
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: genreIcon(for: genre.name))
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                            .frame(width: 24, height: 24)
                        
                        Text(genre.name)
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        let count = memoManager.memos.filter { genre.name == "すべてのメモ" || $0.genre == genre.name }.count
                        if count > 0 {
                            Text("\(count)")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(memoManager.selectedGenre == genre.name && !memoManager.showingDeletedItems ? Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.1) : Color.clear)
                }
            }
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
        default:
            return "folder"
        }
    }
}

#Preview {
    SideMenuView(memoManager: MemoManager(), isShowing: .constant(true))
}
