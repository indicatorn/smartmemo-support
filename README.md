# SmartMemo - シンプルリマインダー

GitHub Pagesでホストされるアプリのサポートページです。

## ファイル構成

- `index.html` - メインページ（アプリの紹介）
- `styles.css` - スタイルシート
- `privacy-policy.html` - プライバシーポリシー
- `terms-of-service.html` - 利用規約

## GitHub Pagesでの公開方法

### 1. GitHubリポジトリの作成

1. GitHubに新しいリポジトリを作成
2. リポジトリ名: `smartmemo-support` または任意の名前
3. リポジトリを公開（Public）に設定

### 2. ファイルのアップロード

1. 作成したファイルをリポジトリにアップロード
2. 以下のファイルを含める：
   - `index.html`
   - `styles.css`
   - `privacy-policy.html`
   - `terms-of-service.html`

### 3. GitHub Pagesの有効化

1. リポジトリの「Settings」タブを開く
2. 左サイドバーの「Pages」をクリック
3. 「Source」で「Deploy from a branch」を選択
4. 「Branch」で「main」を選択
5. 「Save」をクリック

### 4. 公開URLの確認

- 公開後、以下のURLでアクセス可能：
  - `https://[ユーザー名].github.io/[リポジトリ名]/`

## App Store Connectでの設定

### Support URL

GitHub PagesのURLをApp Store Connectの「Support URL」に設定：

```
https://[ユーザー名].github.io/[リポジトリ名]/
```

### Marketing URL（オプション）

同じURLを「Marketing URL」にも設定可能。

## カスタマイズ

### アプリアイコンの変更

`index.html`の以下の部分を変更：

```html
<div class="icon-placeholder">
    📝
</div>
```

実際のアプリアイコン画像に置き換える場合は：

```html
<img src="app-icon.png" alt="SmartMemo" class="app-icon-image">
```

### 色の変更

`styles.css`の以下の部分を変更：

```css
background: linear-gradient(135deg, #007AFF 0%, #0056CC 100%);
```

### 連絡先の変更

`index.html`の以下の部分を変更：

```html
<p>📧 メール: support@smartmemo.app</p>
```

## 注意事項

- プライバシーポリシーと利用規約は、実際のアプリの内容に合わせて調整してください
- 連絡先メールアドレスは実際に使用可能なものに変更してください
- スクリーンショットは実際のアプリの画像に置き換えてください
