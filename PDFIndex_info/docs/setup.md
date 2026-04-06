# PDFIndex インストール手順書

macOS/Linux ではパス区切りやシェルコマンドを適宜読み替えてください。

---

## 動作要件

| 項目 | 要件 |
|------|------|
| Mathematica | 13.1 以上 (14.x 推奨) |
| Python | 3.9 以上 (`ExternalEvaluate["Python", ...]` 経由) |
| Python ライブラリ | PyMuPDF (`fitz`) または pdfplumber |
| OS | Windows 11 |

---

## 依存パッケージ

以下のパッケージをあらかじめ `$packageDirectory` に配置してください。

| パッケージ | 用途 | リポジトリ |
|------------|------|------------|
| localInit | 初期化・共通設定 | https://github.com/transreal/localInit |
| claudecode | LLM クエリ (必須) | https://github.com/transreal/claudecode |
| maildb | Embedding 生成 (推奨) | https://github.com/transreal/maildb |

---

## インストール手順

### 1. Python ライブラリのインストール

コマンドプロンプトまたは PowerShell で実行します。

```
pip install pymupdf
```

PyMuPDF が使用できない場合、pdfplumber が自動的に利用されます。

```
pip install pdfplumber
```

### 2. パッケージファイルの配置

`PDFIndex.wl` を `$packageDirectory` に直接配置します（サブフォルダは不要です）。

```
C:\Users\<ユーザー名>\Documents\WolframPackages\
  ├── PDFIndex.wl         ← ここに配置
  ├── localInit.wl
  ├── claudecode.wl
  └── maildb.wl           (推奨)
```

### 3. $Path の設定

`init.m` または `localInit.wl` で以下を設定してください。

```mathematica
$packageDirectory = "C:\\Users\\<ユーザー名>\\Documents\\WolframPackages";
AppendTo[$Path, $packageDirectory];
```

**注意:** `$Path` には `$packageDirectory` 自体を追加します。  
`AppendTo[$Path, "C:\\...\\PDFIndex"]` のようなサブディレクトリ指定は**誤り**です。

### 4. パッケージのロード

```mathematica
Block[{$CharacterEncoding = "UTF-8"},
  Needs["PDFIndex`", "PDFIndex.wl"]];
```

claudecode を利用している場合、`$Path` は自動的に設定されます。

---

## 主要な設定変数

```mathematica
(* プライベートPDF用インデックス保存先 (デフォルト値) *)
PDFIndex`$pdfIndexBaseDir =
  FileNameJoin[{$packageDirectory, "pdfindex_private"}];

(* クラウドLLM処理可能なPDF用保存先 (デフォルト値) *)
PDFIndex`$pdfIndexAttachDir =
  FileNameJoin[{$packageDirectory, "claude_attachments"}];

(* デバッグ出力 (必要時のみ) *)
PDFIndex`$pdfIndexDebug = False;
```

デフォルト値を変更する場合は `Needs` の**前**に設定してください。

---

## API キーの設定

LLM クエリには claudecode.wl 経由で Claude API を使用します。  
API キーは claudecode.wl の設定に従ってください。  
詳細は [claudecode](https://github.com/transreal/claudecode) のドキュメントを参照してください。

Embedding 生成には maildb.wl 経由の API または `LLMSynthesize` が使用されます。

---

## 動作確認

### Python 接続確認

```mathematica
ExternalEvaluate["Python", "import fitz; fitz.__version__"]
```

バージョン文字列が返れば正常です。

### パッケージ動作確認

```mathematica
pdfPreflightCheck[]
```

PDF 抽出・LLM・Embedding の各機能を一括検証します。

### インデクシングの最小動作例

```mathematica
(* 単一PDFをインデックスに追加 *)
pdfIndex["C:\\Users\\<ユーザー名>\\Documents\\sample.pdf",
  Collection -> "default"]

(* インデックスのロード *)
idx = pdfLoadIndex["default"]

(* 検索 *)
pdfSearch["検索キーワード", 5]
```

---

## インデックスのディレクトリ構成

インデクシング後、以下のファイルが自動生成されます。

```
pdfindex_private\default\        ← Privacy > 0.5 のPDF
  doc_<docId>.wl
  chunks_<docId>.wl
  toc_<docId>.wl
  catalog_<docId>.wl

claude_attachments\pdfindex\default\   ← Privacy <= 0.5 のPDF
  doc_<docId>.wl
  chunks_<docId>.wl
  ...