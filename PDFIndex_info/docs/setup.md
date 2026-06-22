---

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
| claudecode | 推奨（LLM 検索・Claude Vision OCR に使用） | [github.com/transreal/claudecode](https://github.com/transreal/claudecode) |
| maildb | 任意（Embedding フォールバック） | [github.com/transreal/maildb](https://github.com/transreal/maildb) |

各 `.wl` ファイルを `$packageDirectory` に配置してください。

> 文字化けページの修復に使う Claude Vision OCR は claudecode の `ClaudeQueryBg` を利用します。claudecode が未導入の場合、OCR は自動的に EasyOCR・TextRecognize にフォールバックします。

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

### 文字化けページ修復の OCR フォールバック

スキャン PDF や CID フォントなどで文字化けが検出されたページは、以下の優先順位で自動的に再 OCR されます。

| 順位 | 手段 | 必要なもの | 備考 |
|------|------|-----------|------|
| 1 | Claude Vision OCR | claudecode（`ClaudeQueryBg`） | 日本語の表・配当表で最も高精度。450 DPI でレンダリングしページを上下分割して認識 |
| 2 | EasyOCR | `pip install easyocr` | ローカル深層学習ベース。400 DPI でレンダリング。**文字化けページは並列カーネルで一括処理**されます |
| 3 | TextRecognize | Mathematica 内蔵 | 最終フォールバック |

> EasyOCR は `ExternalEvaluate["Python", ...]` ベースのためサブカーネルでも実行可能で、複数の文字化けページを並列に処理します（並列カーネル数は `$pdfParallelKernelCount` で調整、後述）。Claude Vision はメインカーネルで逐次フォールバック実行されます。

---

## 3. LM Studio のセットアップ（ローカル Embedding）

1. [LM Studio](https://lmstudio.ai/) をインストールして起動します。
2. モデル `text-embedding-baai-bge-m3-568m` をダウンロードします。
3. **Local Server** タブで **Start Server** を実行します（デフォルトポート: `1234`）。

> `bge-m3` モデルは最大 8192 トークンに対応しており、複数ページにわたる長い表や年度ヘッダを含むコンテンツも途切れずに Embedding できます。以前使用していた `e5-large-instruct`（512 トークン上限）よりも表・配当表の検索精度が向上しています。

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
| `$pdfIndexDebug` | `False` | `True` にするとデバッグ出力を有効化（OCR の各段の試行ログも表示） |
| `$pdfParallelKernelCount` | `Automatic` | 並列 OCR に使用するサブカーネル数。`Automatic` は `Min[$ProcessorCount - 1, 6]`。物理コア数より多めに設定することも可能 |
| `$PDFIndexDefaultDepartment` | `None` | クエリに学科名がない場合に補完するデフォルト学科名（例: `"情報工学科"`）。指定すると、その学科名を含まないページにペナルティスコアが付き、関連する学科のページが優先的に返されます |

カスタマイズする場合はパッケージ読み込み後に設定します。

```mathematica
PDFIndex`$pdfIndexBaseDir = "D:\\MyPDFIndex\\private"
PDFIndex`$pdfIndexAttachDir = "D:\\MyPDFIndex\\public"
PDFIndex`$pdfParallelKernelCount = 4
PDFIndex`$PDFIndexDefaultDepartment = "情報工学科"
```

> `$pdfParallelKernelCount` は文字化けページの EasyOCR 並列処理にも使われます。多数のスキャンページを含む PDF をインデックスする場合は、コア数に応じて値を上げると再 OCR が高速化します。

---

## 7. 検索辞書の設定（任意）

`$packageDirectory` 直下に `pdfindex_search_config.json` を置くと、クエリタームの正規化に使われる検索辞書をカスタマイズできます。パッケージロード時に自動で読み込まれます。

```json
{
  "aliases": {
    "_comment": "略称・表記ゆれを正規名に変換",
    "機械工学科": "機械システム工学科",
    "情工": "情報工学科"
  },
  "term_expansions": {
    "_comment": "複合語をサブワードに分解して部分マッチを改善",
    "必修科目": ["必修", "科目"],
    "配当表": ["配当", "科目表"]
  }
}
```

| キー | 説明 |
|------|------|
| `aliases` | 略称・表記ゆれを正規名に変換するエイリアスマップ |
| `term_expansions` | 複合語をサブワードに分解し、部分マッチ精度を向上させるマップ |

ファイルが存在しない場合は辞書なしで動作します。

### エンティティインデックス（自動生成）

検索辞書に加えて、`pdfIndex` の実行時にインデックス済みドキュメントの内容から**エンティティインデックス**が自動生成されます。学科名・学部名・施設名・ドキュメントタイトルなどの固有名詞が自動抽出・正規化され、クエリタームの正規化や検索スコアリングに利用されます。手動での設定は不要です。

---

## 8. 動作確認

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

## 9. 最小限の利用例

```mathematica
Block[{$CharacterEncoding = "UTF-8"},
  Needs["PDFIndex`", "PDFIndex.wl"]]

(* PDF をインデックス登録（プライバシー自動推定） *)
pdfIndex["C:\\research\\paper.pdf", Collection -> "research"]

(* ハイブリッド検索 *)
pdfSearch["量子ゲート 可逆計算", 5, Collection -> "research"]

(* LLM に質問 *)
pdfAskLLM["reversible computing のゲート構成は?", Collection -> "research"]