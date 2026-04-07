# PDFIndex ユーザーマニュアル

**パッケージ:** PDFIndex  
**リポジトリ:** [https://github.com/transreal/PDFIndex](https://github.com/transreal/PDFIndex)  
**対象バージョン:** 2026-04-04

---

## 目次

1. [概要](#概要)
2. [設定変数](#設定変数)
3. [インデクシング](#インデクシング)
4. [検索](#検索)
5. [LLM 連携](#llm-連携)
6. [インデックス管理](#インデックス管理)
7. [表示・UI](#表示ui)
8. [デバッグ](#デバッグ)

---

## 概要

PDFIndex は PDF ファイルのテキストを抽出・チャンク化し、Embedding ベクトルと LLM 要約を組み合わせたハイブリッド検索を提供するパッケージです。プライバシー推定によって公開・非公開を自動判別し、クラウド LLM とローカル LLM を適切に使い分けます。

### 基本的な使い方

```mathematica
(* パッケージを読み込む *)
Get["PDFIndex.wl"]

(* PDF をインデックスに追加する *)
pdfIndex["C:/documents/report.pdf"]

(* キーワードで検索する *)
pdfSearch["可逆計算", 5]
```

---

## 設定変数

### `$pdfIndexBaseDir`

プライベート PDF インデックス（Privacy > 0.5）の保存先ディレクトリです。

```mathematica
(* 保存先を確認する *)
$pdfIndexBaseDir
(* → "C:/packages/pdfindex_private" *)

(* 保存先を変更する *)
$pdfIndexBaseDir = "D:/private_indexes"
```

---

### `$pdfIndexAttachDir`

クラウド LLM に渡せる公開 PDF のインデックス保存先ディレクトリです。

```mathematica
$pdfIndexAttachDir
(* → "C:/packages/claude_attachments" *)
```

---

### `$pdfIndexDebug`

`True` に設定すると詳細なデバッグ出力が有効になります。デフォルトは `False` です。

```mathematica
$pdfIndexDebug = True
pdfIndex["report.pdf"]  (* 抽出・チャンキング状況が出力される *)
```

---

## インデクシング

### `pdfIndex`

単一の PDF ファイルをインデックスに追加します。

**シグネチャ:**
```
pdfIndex[pdfPath, opts]
```

**主なオプション:**

| オプション | デフォルト | 説明 |
|---|---|---|
| `Privacy` | `Automatic` | 0.0〜1.0（LLM 自動推定） |
| `Keywords` | `{}` | 追加キーワード |
| `Title` | `""` | タイトル（省略時はファイル名） |
| `Collection` | `"default"` | コレクション名 |
| `ForceReindex` | `False` | 強制再インデックス |

```mathematica
pdfIndex["C:/docs/syllabus2025.pdf",
  Title -> "2025年度シラバス",
  Collection -> "academic",
  Keywords -> {"シラバス", "情報工学"}
]
```

---

### `pdfIndexDirectory`

ディレクトリ内のすべての PDF を一括インデックスします。

**シグネチャ:**
```
pdfIndexDirectory[dirPath, opts]
```

`pdfIndex` と同じオプションに加え `FilePattern -> "*.pdf"` が使えます。

```mathematica
pdfIndexDirectory["D:/research_papers",
  Collection -> "papers",
  FilePattern -> "*2024*.pdf"
]
```

---

### `pdfIndexURL`

URL から PDF をダウンロードしてインデックスに追加します。

**シグネチャ:**
```
pdfIndexURL[url, opts]
```

```mathematica
pdfIndexURL["https://example.ac.jp/bulletin2025.pdf",
  Collection -> "bulletins",
  Privacy -> 0.0
]
```

---

### `pdfIndexAsync`

`pdfIndex` を非同期で実行し、進捗をステータスバーに表示します。ノートブックの応答性を維持したまま大きな PDF をインデックスできます。

**シグネチャ:**
```
pdfIndexAsync[pdfPath, opts]
```

```mathematica
pdfIndexAsync["C:/docs/large_report.pdf",
  Collection -> "reports"
]
(* ステータスバーに進捗が表示される。セル出力には混入しない *)
```

---

### `pdfReindex`

コレクション内のすべてのドキュメントの LLM 要約と Embedding を再生成します。

**シグネチャ:**
```
pdfReindex[collection]
```

```mathematica
pdfReindex["academic"]
(* "academic" コレクション内の全文書を再処理する *)
```

---

## 検索

### `pdfSearch`

Embedding とキーワードを組み合わせたハイブリッド検索を行い、上位 `n` 件のチャンクを返します。

**シグネチャ:**
```
pdfSearch[query, n, opts]
```

**主なオプション:**

| オプション | 説明 |
|---|---|
| `Collection` | 検索対象コレクション（`All` で全て） |
| `MaxItems` | 最大取得件数（デフォルト 20） |
| `MinPrivacy` / `MaxPrivacy` | プライバシースコアの絞り込み |

```mathematica
results = pdfSearch["可逆計算 ゲート構成", 5,
  Collection -> "papers"
]
```

---

### `pdfSearchForLLM`

検索結果を LLM プロンプト用のテキストに変換します。公開分と非公開分を分けて返します。

**シグネチャ:**
```
pdfSearchForLLM[query, opts]
```

**戻り値:**
```mathematica
<|"public"  -> <|"prompt" -> "...", "count" -> n|>,
  "private" -> <|"prompt" -> "...", "count" -> m|>|>
```

```mathematica
ctx = pdfSearchForLLM["情報工学科のカリキュラム",
  Collection -> "academic",
  MaxItems -> 10,
  IncludeFullText -> True
]
ctx["public"]["prompt"]  (* 公開文書のプロンプトテキスト *)
```

---

## LLM 連携

### `pdfAskLLM`

PDF インデックスを検索し、公開文書はクラウド LLM、非公開文書はローカル LLM（`$ClaudePrivateModel`）に問い合わせて回答を返します。

**シグネチャ:**
```
pdfAskLLM[question, opts]
```

**主なオプション:**

| オプション | 説明 |
|---|---|
| `Collection` | 検索対象コレクション |
| `MaxItems` | 参照チャンク数 |
| `IncludeFullText` | チャンク全文をプロンプトに含めるか |

```mathematica
pdfAskLLM["reversible computing のゲート構成は?",
  Collection -> "papers",
  MaxItems -> 5
]
```

```mathematica
pdfAskLLM["情報工学科の必修科目の単位数は?",
  Collection -> "academic"
]
(* プライバシースコアに応じてクラウド/ローカル LLM が自動選択される *)
```

---

## インデックス管理

### `pdfLoadIndex`

コレクションのインデックスをロードし、`PDFIndexObject` を返します。引数なしで呼ぶと全コレクションをロードします。

**シグネチャ:**
```
pdfLoadIndex[collection]
pdfLoadIndex[]
```

```mathematica
idx = pdfLoadIndex["academic"]
(* → PDFIndexObject[«academic, 12 docs, 847 chunks»] *)

(* アクセサでデータを取得する *)
idx["count"]    (* チャンク数 *)
idx["dataset"]  (* Dataset形式の全チャンク *)
```

---

### `pdfListCollections`

利用可能なコレクションの一覧を返します。

**シグネチャ:**
```
pdfListCollections[]
```

```mathematica
pdfListCollections[]
(* → {"default", "academic", "papers"} *)
```

---

### `pdfListDocs`

コレクション内のドキュメント一覧を `Dataset` 形式で返します。

**シグネチャ:**
```
pdfListDocs[collection]
```

```mathematica
pdfListDocs["academic"]
(* タイトル・パス・チャンク数・プライバシースコアなどが Dataset で表示される *)
```

---

### `pdfRemoveDoc`

ドキュメントをインデックスから削除します。

**シグネチャ:**
```
pdfRemoveDoc[docId, collection]
```

```mathematica
(* ドキュメント ID は pdfListDocs で確認できる *)
pdfRemoveDoc["a3f2c1b0d4e5f678", "academic"]
```

---

### `pdfStatus`

現在のインデクシング状態を表示します。

**シグネチャ:**
```
pdfStatus[]
```

```mathematica
pdfStatus[]
(* コレクション数・文書数・チャンク数・バックグラウンドジョブ状況が表示される *)
```

---

### `pdfPreflightCheck`

PDF 抽出・LLM・Embedding の動作確認を行います。初回セットアップ後に実行することを推奨します。

**シグネチャ:**
```
pdfPreflightCheck[]
```

```mathematica
pdfPreflightCheck[]
(* PyMuPDF の利用可否、LM Studio への接続、Claude Code CLI の動作などを検査する *)
```

---

## 表示・UI

### `pdfSearchUI`

インタラクティブな検索 UI をノートブックに表示します。各結果に **[全文]** **[前後]** **[質問]** ボタンが付きます。

**シグネチャ:**
```
pdfSearchUI[query, n, opts]
```

| ボタン | 動作 |
|---|---|
| [全文] | チャンクの全テキストを出力 |
| [前後] | 前後チャンクを含むコンテキストを表示 |
| [質問] | そのチャンクを元に ClaudeQuery で質問 |

```mathematica
pdfSearchUI["カリキュラムマップ", 10,
  Collection -> "academic"
]
```

---

### `pdfGetChunk`

インデックス番号でチャンクの全文を取得します。範囲指定で複数チャンクを連結して返せます。

**シグネチャ:**
```
pdfGetChunk[chunkIndex, collection]
pdfGetChunk[{from, to}, collection]
```

```mathematica
pdfGetChunk[42, "academic"]       (* チャンク 42 の全文 *)
pdfGetChunk[{40, 45}, "academic"] (* チャンク 40〜45 を連結 *)
```

---

### `pdfShowPage`

PDF の指定ページを画像としてノートブックに表示します。第3引数に `"file"` を指定すると画像ファイルパスを返します。

**シグネチャ:**
```
pdfShowPage[pageNum, collection]
pdfShowPage[pageNum, collection, "file"]
```

```mathematica
pdfShowPage[124, "academic"]          (* p.124 をノートブックに表示 *)
pdfShowPage[124, "academic", "file"]  (* 画像ファイルパスを返す *)
```

---

### `pdfFindPage`

クエリにマッチする PDF のページ番号を推定して返します。チャンク位置と PDF メタデータから計算します。

**シグネチャ:**
```
pdfFindPage[query, collection]
```

```mathematica
pdfFindPage["情報工学科 教育目的", "academic"]
(* → 125  （目次情報とチャンク位置から推定） *)
```

---

## PDFIndexObject リファレンス

`pdfLoadIndex` が返すオブジェクトは以下のキーでアクセスできます。

```mathematica
idx = pdfLoadIndex["academic"]

idx["dataset"]    (* Dataset: 全チャンクのメタデータ＋テキスト *)
idx["nearest"]    (* NearestFunction: embedding 近傍検索に使用 *)
idx["count"]      (* Integer: 総チャンク数 *)
idx["docs"]       (* List: ドキュメントメタデータの一覧 *)
```

---

## 典型的なワークフロー

### 1. 初回セットアップ

```mathematica
Get["PDFIndex.wl"]
pdfPreflightCheck[]   (* 依存ツールの動作確認 *)
```

### 2. ディレクトリ一括インデックス

```mathematica
pdfIndexDirectory["D:/university/syllabi",
  Collection -> "syllabi2025",
  Keywords -> {"シラバス", "2025年度"}
]
```

### 3. 対話的に質問する

```mathematica
(* インタラクティブ UI で検索 *)
pdfSearchUI["必修科目 単位数", 8, Collection -> "syllabi2025"]

(* LLM に質問する *)
pdfAskLLM["情報工学科の卒業要件は何単位ですか?",
  Collection -> "syllabi2025"
]
```

### 4. プライバシーに応じた検索絞り込み

```mathematica
(* 公開文書のみを検索（Privacy ≤ 0.5） *)
pdfSearch["ゲート回路", 5,
  Collection -> All,
  MaxPrivacy -> 0.5
]

(* 非公開文書のみを検索 *)
pdfSearch["成績分布", 5,
  MinPrivacy -> 0.5
]