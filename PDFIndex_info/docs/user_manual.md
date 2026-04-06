# PDFIndex ユーザーマニュアル

**パッケージ**: [PDFIndex](https://github.com/transreal/PDFIndex)
**対象バージョン**: 2026-04-04

---

## 目次

1. [概要](#概要)
2. [グローバル設定](#グローバル設定)
3. [インデクシング](#インデクシング)
4. [検索](#検索)
5. [インデックス管理](#インデックス管理)
6. [UI・ビューア](#uiビューア)
7. [デバッグ](#デバッグ)

---

## 概要

PDFIndex は PDF ファイルをチャンク分割・要約・埋め込みベクトル化し、ハイブリッド検索（埋め込み類似度 + キーワード）を提供する Wolfram Language パッケージです。プライバシーレベルに応じてクラウド LLM とローカル LLM を自動切り替えします。

依存パッケージ: localInit.wl（必須）、claudecode.wl（オプション）、maildb.wl（埋め込み生成に使用）

---

## グローバル設定

### `$pdfIndexBaseDir`

プライベート PDF インデックス（`Privacy > 0.5`）の保存先ディレクトリです。

```mathematica
(* デフォルト値を確認する *)
$pdfIndexBaseDir
(* => "C:\Users\...\pdfindex_private" *)

(* 変更する場合 *)
$pdfIndexBaseDir = "D:\\MyPrivateDocs\\index";
```

### `$pdfIndexAttachDir`

クラウド LLM で処理可能な公開 PDF のインデックス保存先です。

```mathematica
$pdfIndexAttachDir
(* => "C:\Users\...\claude_attachments" *)
```

---

## インデクシング

### `pdfIndex`

単一の PDF ファイルをインデクシングします。テキスト抽出・チャンキング・LLM 要約・埋め込み生成を自動実行します。

**シグネチャ**
```
pdfIndex[pdfPath, opts]
```

**主なオプション**

| オプション | デフォルト | 説明 |
|-----------|-----------|------|
| `Privacy` | `Automatic` | 0.0〜1.0（LLM 自動推定） |
| `Keywords` | `{}` | 追加キーワード |
| `Title` | `None` | タイトル上書き |
| `Collection` | `"default"` | コレクション名 |
| `ForceReindex` | `False` | 強制再インデクシング |

**例**
```mathematica
(* 基本的な使い方 *)
pdfIndex["C:\\Papers\\quantum_computing.pdf"]

(* プライバシーと所属コレクションを指定 *)
pdfIndex["report_2026.pdf",
  Privacy -> 0.7,
  Collection -> "internal",
  Title -> "2026年度報告書"]
```

---

### `pdfIndexDirectory`

ディレクトリ内の全 PDF を一括インデクシングします。

**シグネチャ**
```
pdfIndexDirectory[dirPath, opts]
```

`pdfIndex` と同じオプションに加え `FilePattern -> "*.pdf"` が使えます。

**例**
```mathematica
(* フォルダ内の全 PDF をインデクシング *)
pdfIndexDirectory["D:\\Papers\\2026\\",
  Collection -> "papers2026"]

(* 特定パターンのみ *)
pdfIndexDirectory["D:\\Reports\\",
  FilePattern -> "*annual*.pdf",
  Privacy -> 0.5]
```

---

### `pdfIndexURL`

URL から PDF をダウンロードしてインデクシングします。ダウンロード済みファイルはキャッシュされます。

**シグネチャ**
```
pdfIndexURL[url, opts]
```

**例**
```mathematica
pdfIndexURL["https://example.com/paper.pdf",
  Collection -> "web_papers",
  Privacy -> 0.0]
```

---

### `pdfReindex`

コレクション内の全ドキュメントの LLM 要約・埋め込みベクトルを再生成します。

**シグネチャ**
```
pdfReindex[collection]
```

**例**
```mathematica
(* LLM モデルを変更した後に再生成 *)
pdfReindex["papers2026"]
```

---

## 検索

### `pdfSearch`

埋め込み類似度とキーワードを組み合わせたハイブリッド検索で上位 n 件を返します。

**シグネチャ**
```
pdfSearch[query, n, opts]
```

**主なオプション**

| オプション | 説明 |
|-----------|------|
| `Collection` | 対象コレクション（`All` で全コレクション） |
| `MaxItems` | 最大件数（デフォルト 20） |
| `MinPrivacy` / `MaxPrivacy` | プライバシーレベルでフィルタ |

**例**
```mathematica
(* 上位 5 件を検索 *)
results = pdfSearch["reversible computing のゲート構成", 5]

(* 公開ドキュメントのみを対象にする *)
pdfSearch["量子ゲート", 10,
  Collection -> "papers2026",
  MaxPrivacy -> 0.5]
```

---

### `pdfSearchForLLM`

検索結果を LLM プロンプト用のテキストに変換します。公開分・秘密分を分けて返します。

**シグネチャ**
```
pdfSearchForLLM[query, opts]
```

**戻り値**
```
<|"public"  -> <|"prompt" -> "...", "count" -> n|>,
  "private" -> <|"prompt" -> "...", "count" -> m|>|>
```

**例**
```mathematica
context = pdfSearchForLLM["カリキュラムポリシー",
  MaxItems -> 10,
  IncludeFullText -> True]

(* 公開分のプロンプトを取得 *)
context["public"]["prompt"]
```

---

### `pdfAskLLM`

PDF インデックスを検索し、関連チャンクをコンテキストとして LLM に質問します。公開分はクラウド LLM、秘密分はプライベートモデルに問い合わせます。

**シグネチャ**
```
pdfAskLLM[question, opts]
```

**例**
```mathematica
(* シンプルな質問 *)
pdfAskLLM["reversible computing のゲート構成は?"]

(* コレクションを限定して質問 *)
pdfAskLLM["2026年度の必修科目一覧を教えてください",
  Collection -> "syllabus",
  MaxItems -> 15]
```

---

## インデックス管理

### `pdfLoadIndex`

コレクションのインデックスをロードし、`PDFIndexObject` を返します。一度ロードするとキャッシュされます。

**シグネチャ**
```
pdfLoadIndex[collection]   (* 単一コレクション *)
pdfLoadIndex[]             (* 全コレクションをロード *)
```

**例**
```mathematica
idx = pdfLoadIndex["papers2026"]
(* => PDFIndexObject[«papers2026, 12 docs, 340 chunks»] *)

(* アクセサで内部データを取得 *)
idx["docCount"]    (* => 12 *)
idx["chunkCount"]  (* => 340 *)
idx["docs"]        (* ドキュメントメタデータのリスト *)
```

---

### `pdfListCollections`

利用可能なコレクション名の一覧を返します。

**シグネチャ**
```
pdfListCollections[]
```

**例**
```mathematica
pdfListCollections[]
(* => {"default", "internal", "papers2026"} *)
```

---

### `pdfListDocs`

コレクション内のドキュメント一覧を `Dataset` 形式で返します。

**シグネチャ**
```
pdfListDocs[collection]
```

**例**
```mathematica
pdfListDocs["papers2026"]
(* docId, title, author, privacy, pageCount, chunkCount, indexedAt, storageType を含む Dataset *)
```

---

### `pdfRemoveDoc`

ドキュメントをインデックスから削除します。

**シグネチャ**
```
pdfRemoveDoc[docId, collection]
```

**例**
```mathematica
(* docId は pdfListDocs[] で確認できます *)
pdfRemoveDoc["a3f1b2c4d5e6f7a8", "papers2026"]
```

---

### `pdfStatus`

現在のインデクシング状態（進行中タスク・コレクション数など）を表示します。

**シグネチャ**
```
pdfStatus[]
```

**例**
```mathematica
pdfStatus[]
```

---

### `pdfPreflightCheck`

PDF テキスト抽出・LLM 接続・埋め込み生成の動作確認を行います。初回セットアップ後に実行することを推奨します。

**シグネチャ**
```
pdfPreflightCheck[]
```

**例**
```mathematica
pdfPreflightCheck[]
(* 各コンポーネントの OK / NG を表示します *)
```

---

## UI・ビューア

### `pdfSearchUI`

インタラクティブな検索結果を表示します。各結果に **[全文]** **[前後]** **[質問]** ボタンが表示されます。

**シグネチャ**
```
pdfSearchUI[query, n, opts]
```

**例**
```mathematica
pdfSearchUI["量子コンピュータ 誤り訂正", 5,
  Collection -> "papers2026"]
```

ボタンの動作:
- **[全文]** — チャンクの全テキストをノートブックに出力
- **[前後]** — 前後のチャンクも含めたコンテキストを表示
- **[質問]** — そのチャンクを元に ClaudeQuery で質問

---

### `pdfGetChunk`

インデックス番号でチャンクの全文を取得します。

**シグネチャ**
```
pdfGetChunk[chunkIndex, collection]
pdfGetChunk[{from, to}, collection]   (* 範囲指定で連結 *)
```

**例**
```mathematica
(* 単一チャンク *)
pdfGetChunk[42, "papers2026"]

(* 連続チャンクを結合して取得 *)
pdfGetChunk[{40, 45}, "papers2026"]
```

---

### `pdfShowPage`

PDF の指定ページを画像としてノートブックに表示します。

**シグネチャ**
```
pdfShowPage[pageNum, collection]
pdfShowPage[pageNum, collection, "file"]   (* 画像ファイルパスを返す *)
```

**例**
```mathematica
(* ページをノートブックに表示 *)
pdfShowPage[124, "papers2026"]

(* 画像ファイルとして保存してパスを取得 *)
path = pdfShowPage[124, "papers2026", "file"]
```

---

### `pdfFindPage`

クエリにマッチする PDF のページ番号を推定して返します。チャンク位置と PDF メタデータからページ番号を計算します。

**シグネチャ**
```
pdfFindPage[query, collection]
```

**例**
```mathematica
pdfFindPage["誤り訂正符号の定義", "papers2026"]
(* => 87 *)
```

---

## デバッグ

### `$pdfIndexDebug`

`True` に設定すると内部処理の詳細ログを出力します。問題発生時のトラブルシューティングに使用します。

**例**
```mathematica
$pdfIndexDebug = True;
pdfIndex["test.pdf"];
$pdfIndexDebug = False;
```

---

## よくある使い方パターン

### PDF を追加して質問する

```mathematica
(* 1. PDF をインデクシング *)
pdfIndex["my_document.pdf", Collection -> "mylib"]

(* 2. 質問する *)
pdfAskLLM["この文書の主要な結論は?", Collection -> "mylib"]
```

### インタラクティブに内容を確認する

```mathematica
(* 検索 UI を起動 *)
pdfSearchUI["キーワード", 10, Collection -> "mylib"]
```

### 複数 PDF をまとめてインデクシング

```mathematica
pdfIndexDirectory["D:\\Papers\\",
  Collection -> "papers",
  Privacy -> 0.3]

(* インデクシング後にドキュメント一覧を確認 *)
pdfListDocs["papers"]