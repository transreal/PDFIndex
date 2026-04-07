# PDFIndex セットアップ手順

macOS/Linux ではパス区切りやシェルコマンドを適宜読み替えてください。

---

## 動作要件

| 項目 | 要件 |
|------|------|
| Mathematica | 13.1 以上 |
| Python | 3.9 以上（ExternalEvaluate 経由） |
| LM Studio | 0.3 以上（ローカル Embedding 用） |
| OS | Windows 11 |

---

## 1. 依存パッケージの確認

PDFIndex は以下のパッケージに依存しています。

| パッケージ | 必須 | URL |
|-----------|------|-----|
| localInit | **必須** | [github.com/transreal/localInit](https://github.com/transreal/localInit) |
| claudecode | 推奨（LLM 検索に使用） | [github.com/transreal/claudecode](https://github.com/transreal/claudecode) |
| maildb | 任意（Embedding フォールバック） | [github.com/transreal/maildb](https://github.com/transreal/maildb) |

各 `.wl` ファイルを `$packageDirectory` に配置してください。

---

## 2. Python ライブラリのインストール

コマンドプロンプトで以下を実行します。

```
pip install pymupdf
```

OCR 機能（文字化けページの修復）を使う場合は追加でインストールします。

```
pip install easyocr
pip install pdfplumber
```

> PyMuPDF（`import fitz`）が最優先で使われます。インストール失敗時は pdfplumber にフォールバックします。

---

## 3. LM Studio のセットアップ（ローカル Embedding）

1. [LM Studio](https://lmstudio.ai/) をインストールして起動します。
2. モデル `text-embedding-multilingual-e5-large-instruct` をダウンロードします。
3. **Local Server** タブで **Start Server** を実行します（デフォルトポート: `1234`）。

> LM Studio が起動していない場合、Embedding は使用されず **キーワード検索のみ** で動作します。

---

## 4. PDFIndex のインストール

1. [PDFIndex リポジトリ](https://github.com/transreal/PDFIndex) から `PDFIndex.wl` をダウンロードします。
2. `localInit.wl` と同じ `$packageDirectory` に配置します。

```
C:\Users\<ユーザー名>\Documents\WolframPackages\
  ├── localInit.wl
  ├── claudecode.wl        ← 推奨
  ├── maildb.wl            ← 任意
  └── PDFIndex.wl
```

---

## 5. $Path の設定とパッケージの読み込み

`$packageDirectory` が `$Path` に含まれていない場合は追加します。

```mathematica
AppendTo[$Path, $packageDirectory]
```

claudecode を使用する場合、`$Path` は自動で設定されます。

パッケージを読み込みます。

```mathematica
Block[{$CharacterEncoding = "UTF-8"},
  Needs["PDFIndex`", "PDFIndex.wl"]]
```

---

## 6. 主要な設定変数

| 変数 | デフォルト値 | 説明 |
|------|-------------|------|
| `$pdfIndexBaseDir` | `$packageDirectory\pdfindex_private` | 秘密 PDF インデックスの保存先 |
| `$pdfIndexAttachDir` | `$packageDirectory\claude_attachments` | 公開 PDF インデックスの保存先 |
| `$pdfIndexDebug` | `False` | `True` にするとデバッグ出力を有効化 |

カスタマイズする場合はパッケージ読み込み後に設定します。

```mathematica
PDFIndex`$pdfIndexBaseDir = "D:\\MyPDFIndex\\private"
PDFIndex`$pdfIndexAttachDir = "D:\\MyPDFIndex\\public"
```

---

## 7. 動作確認

```mathematica
(* 環境チェック *)
pdfPreflightCheck[]

(* PDF を1件インデックス登録 *)
pdfIndex["C:\\Users\\<ユーザー名>\\Documents\\sample.pdf"]

(* 検索テスト *)
pdfSearch["reversible computing", 5]

(* コレクション一覧 *)
pdfListCollections[]
```

`pdfPreflightCheck[]` で Python・LLM・Embedding の接続状態を確認できます。

---

## 8. 最小限の利用例

```mathematica
Block[{$CharacterEncoding = "UTF-8"},
  Needs["PDFIndex`", "PDFIndex.wl"]]

(* PDF をインデックス登録（プライバシー自動推定） *)
pdfIndex["C:\\research\\paper.pdf", Collection -> "research"]

(* ハイブリッド検索 *)
pdfSearch["量子ゲート 可逆計算", 5, Collection -> "research"]

(* LLM に質問 *)
pdfAskLLM["reversible computing のゲート構成は?", Collection -> "research"]