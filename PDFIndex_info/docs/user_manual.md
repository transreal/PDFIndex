# PDFIndex ユーザーマニュアル

**パッケージ:** PDFIndex  
**リポジトリ:** [https://github.com/transreal/PDFIndex](https://github.com/transreal/PDFIndex)  
**対象バージョン:** 2026-06-21

---

## 目次

1. [概要](#概要)
2. [設定変数](#設定変数)
3. [インデクシング](#インデクシング)
4. [検索](#検索)
5. [LLM 連携](#llm-連携)
6. [インデックス管理](#インデックス管理)
7. [表示・UI](#表示ui)
8. [検索辞書のカスタマイズ](#検索辞書のカスタマイズ)
9. [デバッグ](#デバッグ)

---

## 概要

PDFIndex は PDF ファイルのテキストを抽出・チャンク化し、Embedding ベクトルと LLM 要約を組み合わせたハイブリッド検索を提供するパッケージです。プライバシー推定によって公開・非公開を自動判別し、クラウド LLM とローカル LLM を適切に使い分けます。

CID フォントなどによって文字化けしたページは、EasyOCR の並列処理 → Claude Vision CLI → Mathematica TextRecognize の 3 段階フォールバックで自動修復されます。

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

### `$PDFIndexDefaultDepartment`

クエリに学科名が含まれていない場合に補完するデフォルト学科名です。デフォルトは `None`（補完なし）です。

学科別 PDF コレクション（履修要件・シラバス等）を特定学科専用として使う場合に設定すると、無関係な学科のページがヒットしにくくなります。

```mathematica
(* 情報工学科専用コレクションとして使う場合 *)
$PDFIndexDefaultDepartment = "情報工学科"

(* 補完をオフに戻す *)
$PDFIndexDefaultDepartment = None
```

---

### `$pdfParallelKernelCount`

PDF 抽出・OCR 処理に使用するサブカーネル数です。デフォルトは `Automatic`（= `Min[$ProcessorCount - 1, 6]`）です。

大量ページの OCR やバッチインデックス時に処理を並列化します。メインカーネルの ScheduledTask（LLMGraph 等）とは独立して動作します。EasyOCR による文字化けページ修復も、このサブカーネルプールを利用して並列実行されます。

```mathematica
(* サブカーネル数を明示的に指定する *)
$pdfParallelKernelCount = 4

(* 並列処理を無効にする *)
$pdfParallelKernelCount = 1

(* Automatic に戻す *)
$pdfParallelKernelCount = Automatic
```

---

## インデクシング

### `pdfIndex`

単一の PDF ファイルをインデックスに追加します。インデクシング時にエンティティインデックス（学科名・人名・建物名などの固有名詞一覧）も自動生成され、検索時のクエリ正規化に利用されます。

CID フォントなどによって文字化けしたページが検出された場合は、後述の **OCR パイプライン** が自動的に起動して修復します。

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

### OCR パイプライン（文字化けページの自動修復）

`pdfIndex` の内部では、PyMuPDF でテキスト抽出した後に各ページの文字化けを自動検出します。文字化け判定の基準は「2 文字以上のひらがな連続の出現回数が、200 文字あたり 1 回未満」です（CID フォントではひらがなの助詞・接続が失われるため）。

文字化けページが検出されると、次の 3 段階でフォールバック修復を試みます。

| 優先順 | 手法 | 特徴 |
|---|---|---|
| 1 | **EasyOCR**（400 DPI レンダリング） | `ParallelMap` で全文字化けページを並列処理（CPU 集約型・無料） |
| 2 | **Claude Vision CLI** | 上下分割してそれぞれ送信（精度最高・Pro/Max プランが必要） |
| 3 | **TextRecognize**（Mathematica 内蔵） | 最終手段 |

EasyOCR は `$pdfParallelKernelCount` で制御されるサブカーネルプールを利用します。Claude Vision は上半分・下半分を別々に送信することで 1 枚あたりのサイズ制限を回避します。`$pdfIndexDebug = True` を設定すると各ステップの結果が出力されます。

```mathematica
(* デバッグ出力で OCR フォールバックの状況を確認する *)
$pdfIndexDebug = True
pdfIndex["C:/docs/garbled_report.pdf", Collection -> "reports"]
(* → ⚠️ 文字化け検出: p.3,7,12 → 並列OCRで再抽出 (3 pages)
        ✔ p.3: 1824 chars (EasyOCR)
        ⚠️ p.7 OCR失敗
        Claude Vision OCR p.7 上半分...
        Claude Vision OCR p.7 下半分...
        ✔ p.7: 943+812 chars (Claude Vision)
        ✔ p.12: 652 chars (TextRecognize) *)
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

コレクション内のすべてのドキュメントの LLM 要約と Embedding を再生成します。PDF の再抽出も含む完全な再処理です。

**シグネチャ:**
```
pdfReindex[collection]
```

```mathematica
pdfReindex["academic"]
(* "academic" コレクション内の全文書を再処理する *)
```

---

### `pdfReembed`

保存済みチャンクのテキストから **Embedding のみを再生成** して更新します。PDF 再抽出・LLM 再要約は行わないため、`pdfReindex` より大幅に高速です。

テキストのエンコーディング修正後に既存 Embedding を作り直す場合や、Embedding モデルを変更した後に既存チャンクを更新する用途に適しています。

**シグネチャ:**
```
pdfReembed[collection]
```

```mathematica
(* エンコーディング修正後に embedding だけ更新する *)
pdfReembed["academic"]

(* 全コレクションの embedding を作り直す場合 *)
Do[pdfReembed[col], {col, pdfListCollections[]}]
```

`pdfReindex` との比較:

| 処理 | `pdfReindex` | `pdfReembed` |
|---|---|---|
| PDF 再抽出 | ✓ | — |
| OCR フォールバック | ✓ | — |
| LLM 再要約 | ✓ | — |
| Embedding 再生成 | ✓ | ✓ |
| 処理速度 | 遅い | 速い |

---

## 検索

### `pdfSearch`

Embedding とキーワードを組み合わせたハイブリッド検索を行い、上位 `n` 件のチャンクを返します。

検索時には検索辞書（`pdfindex_search_config.json`）によるエイリアス解決とターム展開、およびエンティティインデックスによる固有名詞正規化が自動的に適用されます。

**スコアリング動作:**

- **1 ターム**: ベーススコアのみ（ボーナスなし）
- **2 ターム以上**: `(1.0 + (マッチ数 / ターム数)² × 3.0)` の二次式ボーナスが加算されます。全ターム一致で最大 ×4 のスコア補正が得られます。チャンクマッチと TOC マッチそれぞれに独立してボーナスが計算されます。

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

クエリにマッチする PDF のページ番号を推定して返します。チャンク位置・TOC・ページラベル情報を組み合わせて計算します。

**ページラベルマッピング:** 多くの PDF では表紙・目次等の前付きページにより、物理ページ番号と印刷ページ番号にオフセットが生じます。`pdfFindPage` は PyMuPDF のページラベル情報を取得してマッピングを構築し、印刷ページ番号を正確に返します。

**TOC 親エントリ遡上:** TOC の子エントリ（level ≥ 3）がクエリに最もマッチした場合、1 段だけ親エントリ（level ≥ 2）に遡上してページ範囲を取得します。これにより、「情報工学科 教育目的」にマッチしたとき p.125–127 の狭い範囲ではなく、「②情報工学科」セクション全体（p.125–131 等）が対象になります。level 1 まで遡上することはありません。

**シグネチャ:**
```
pdfFindPage[query, collection]
```

```mathematica
pdfFindPage["情報工学科 教育目的", "academic"]
(* → 125  （TOC・チャンク位置・ページラベルから推定。親セクション範囲を使用） *)

pdfFindPage["必修科目 単位数", "syllabi2025"]
(* → 43   （印刷ページ番号で返す。物理ページ番号とは異なる場合あり） *)
```

---

## 検索辞書のカスタマイズ

`$packageDirectory` に `pdfindex_search_config.json` を置くと、検索クエリのエイリアス解決とターム展開を設定できます。パッケージロード時に自動的に読み込まれます。

### ファイル構造

```json
{
  "aliases": {
    "機械工学科": "機械システム工学科",
    "情工": "情報工学科",
    "必修": "必修科目"
  },
  "term_expansions": {
    "必修科目": ["必修", "科目"],
    "カリキュラムマップ": ["カリキュラム", "マップ"],
    "GPA": ["GPA", "成績評価"]
  }
}
```

### `aliases`（エイリアス解決）

略称・異表記を正式名称に変換します。クエリへの適用は 2 段階で行われます。

1. **正規名に完全一致** → そのまま使用
2. **エイリアスに完全一致** → 正規名に置換してから検索

```mathematica
(* "機械工学科" → "機械システム工学科" として検索される *)
pdfSearch["機械工学科 必修", 5, Collection -> "academic"]
```

### `term_expansions`（ターム展開）

複合語を構成サブワードに分解します。登録された複合語がクエリに含まれると、サブワードへの部分一致も同時に試みます。

```mathematica
(* "必修科目" → {"必修", "科目"} に展開してスコアリング *)
pdfSearch["必修科目 単位数", 5, Collection -> "academic"]
```

### エンティティインデックス

インデクシング時に PDF 内の固有名詞（学科名・人名・建物名・専門用語等）が自動抽出されてエンティティインデックスとして保存されます。検索時にクエリタームがこのインデックスで正規化されるため、表記ゆれに強い検索が実現されます。エンティティインデックスは `pdfIndex` / `pdfReindex` 実行時に自動更新されます。

### デバッグ確認

```mathematica
$pdfIndexDebug = True
pdfSearch["機械工学科", 3, Collection -> "academic"]
(* 検索辞書ロード件数・エイリアス解決結果・ターム展開結果がログ出力される *)
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
```

### 5. 学科専用コレクションの設定

```mathematica
(* 情報工学科の資料のみを扱うコレクション *)
$PDFIndexDefaultDepartment = "情報工学科"
pdfSearch["教育目標", 5, Collection -> "cs_dept"]
(* 情報工学科のページが優先してヒットする *)
```

### 6. Embedding モデル変更後の軽量更新

```mathematica
(* PDF 再抽出・LLM 再要約は不要な場合は pdfReembed を使う *)
pdfReembed["academic"]   (* embedding だけ再生成（高速） *)

(* エンコーディング修正を含む完全再処理が必要な場合 *)
pdfReindex["academic"]   (* PDF 再抽出・LLM 要約・embedding を全て再生成 *)