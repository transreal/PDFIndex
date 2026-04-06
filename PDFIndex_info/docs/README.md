# PDFIndex

PDF文書のインデクシング・多層検索パッケージ（Wolfram Language）

## 設計思想と実装の概要

### パッケージの位置づけ

PDFIndex は、PDF文書を対象としたハイブリッド検索・RAG（Retrieval-Augmented Generation）基盤を Wolfram Language で実現するパッケージです。メールデータベースパッケージ [maildb](https://github.com/transreal/maildb) と同一のアーキテクチャ——埋め込みベクトル検索・キーワード検索の組み合わせ（RRF）、公開／秘密分離、LLM問い合わせ——をPDFドキュメントに適用することで、研究論文・シラバス・社内文書などあらゆるPDFを統一的に扱えるよう設計されています。

### プライバシーモデル: クラウドとローカルの自動切り替え

PDFIndex の中心的な設計思想は「文書のプライバシーレベルに応じたLLMの自動選択」です。各ドキュメントには `Privacy` スコア（0.0〜1.0）が付与されます。このスコアをもとに、保存先・処理LLMが自動的に決定されます。

| Privacy | 分類 | 保存先 | 使用LLM |
|---------|------|--------|---------|
| ≤ 0.5 | 公開 | `claude_attachments/pdfindex/<collection>/` | クラウドLLM（Claude等） |
| > 0.5 | 秘密 | `pdfindex_private/<collection>/` | `$ClaudePrivateModel`（LM Studio等） |

`Privacy -> Automatic` を指定すると、ドキュメントのタイトルと先頭テキストからLLMが自動推定します。これにより、利用者が逐一プライバシーレベルを意識することなく、クラウドへの情報漏洩リスクを制御できます。

### 構造化パイプライン: テキスト抽出から検索まで

インデクシングは以下のパイプラインで構成されます。

1. **PDF テキスト抽出**: Python の PyMuPDF（fitz）を `ExternalEvaluate` 経由で呼び出します。PyMuPDF が利用できない場合は pdfplumber、さらに Mathematica ネイティブの `Import` にフォールバックします。

2. **ページ分類・ビジョン解析**: ヒューリスティクスにより各ページを「テキストページ」と「表・図ページ」に分類します。表・図ページに対しては PyMuPDF の `find_tables()` や構造解析を用いた詳細解析を実行します。

3. **連続ページの表マージ**: 複数ページにまたがる表（`continues_from_previous` / `continues_to_next` フラグ）を自動的に結合し、1チャンクとして扱います。

4. **目次（TOC）抽出・カタログ構築**: PyMuPDF の `get_toc()` でドキュメント構造を取得し、表・図・セクションの軽量索引（カタログ）を別ファイルで保持します。これにより、ページ番号推定や構造検索が高速になります。

5. **チャンキング**: 表はMarkdown形式で1チャンク化、テキストは文字数ベース（デフォルト2000文字、200文字オーバーラップ）でチャンク化します。

6. **LLM要約・タグ生成**: 各チャンクに対し、要旨（SUMMARY）・固有名詞（ENTITIES）・検索用タグ（TAGS）をLLMで生成します。プライバシーレベルに応じてクラウドLLMまたはローカルLLMが使用されます。LLMクエリは [claudecode](https://github.com/transreal/claudecode) の `ClaudeQueryBg`（同期・バックグラウンド安全）を優先し、`ClaudeQuery`（非同期）にフォールバックします。

7. **埋め込みベクトル生成**: [maildb](https://github.com/transreal/maildb) の埋め込み関数を優先使用し、利用できない場合は `LLMSynthesize` を使用します。

8. **保存**: ドキュメントメタデータ（`doc_<docId>.wl`）、チャンクデータ（`chunks_<docId>.wl`）、TOC（`toc_<docId>.wl`）、カタログ（`catalog_<docId>.wl`）をコレクション別ディレクトリに保存します。

### 検索アーキテクチャ

検索は埋め込みベクトル類似度とキーワードマッチングを組み合わせたハイブリッド方式（RRF: Reciprocal Rank Fusion）を採用します。`pdfLoadIndex` でインデックスを `PDFIndexObject` としてメモリに展開し、`NearestFunction`（CosineDistance）によるベクトル検索を高速に実行します。

RAG問い合わせ（`pdfAskLLM`）では、検索結果を公開分と秘密分に分離した上で、それぞれ適切なLLMへプロンプトを送信します。WebServer が利用可能な場合はパッケージロード時に `/pdfsearch` エンドポイントが自動登録され、ブラウザやJSON APIからも検索できます。

---

## 詳細説明

### 動作環境

| 項目 | 要件 |
|------|------|
| Mathematica | 13.1 以上（14.x 推奨） |
| Python | 3.9 以上（`ExternalEvaluate["Python", ...]` 経由） |
| Python ライブラリ | PyMuPDF（`fitz`）または pdfplumber |
| OS | Windows 11（macOS / Linux は未検証） |

### インストール

#### 1. Python ライブラリのインストール

```
pip install pymupdf
```

PyMuPDF が使用できない場合は pdfplumber が自動的に利用されます。

```
pip install pdfplumber
```

#### 2. 依存パッケージの配置

以下のパッケージをあらかじめ `$packageDirectory` に配置してください。

| パッケージ | 用途 |
|------------|------|
| [localInit](https://github.com/transreal/localInit) | 初期化・共通設定（必須） |
| [claudecode](https://github.com/transreal/claudecode) | LLMクエリ（必須） |
| [maildb](https://github.com/transreal/maildb) | 埋め込み生成（推奨） |

#### 3. パッケージファイルの配置

`PDFIndex.wl` を `$packageDirectory` に直接配置します（サブフォルダは不要です）。

```
C:\Users\<ユーザー名>\Documents\WolframPackages\
  ├── PDFIndex.wl         ← ここに配置
  ├── localInit.wl
  ├── claudecode.wl
  └── maildb.wl           （推奨）
```

#### 4. `$Path` の設定

`init.m` または `localInit.wl` で以下を設定してください。

```mathematica
$packageDirectory = "C:\\Users\\<ユーザー名>\\Documents\\WolframPackages";
AppendTo[$Path, $packageDirectory];
```

**注意:** `$Path` には `$packageDirectory` 自体を追加します。`AppendTo[$Path, "C:\\...\\PDFIndex"]` のようなサブディレクトリ指定は**誤り**です。[claudecode](https://github.com/transreal/claudecode) を使用している場合、`$Path` は自動的に設定されます。

#### 5. パッケージのロード

```mathematica
Block[{$CharacterEncoding = "UTF-8"},
  Needs["PDFIndex`", "PDFIndex.wl"]];
```

#### 6. 主要な設定変数

デフォルト値を変更する場合は `Needs` の**前**に設定してください。

```mathematica
(* プライベートPDF用インデックス保存先 *)
PDFIndex`$pdfIndexBaseDir =
  FileNameJoin[{$packageDirectory, "pdfindex_private"}];

(* クラウドLLM処理可能なPDF用保存先 *)
PDFIndex`$pdfIndexAttachDir =
  FileNameJoin[{$packageDirectory, "claude_attachments"}];

(* デバッグ出力（必要時のみ） *)
PDFIndex`$pdfIndexDebug = False;
```

### クイックスタート

```mathematica
(* 1. パッケージのロード *)
Block[{$CharacterEncoding = "UTF-8"},
  Needs["PDFIndex`", "PDFIndex.wl"]];

(* 2. 動作確認 *)
pdfPreflightCheck[]
(* => ✔ PDF 抽出 (PyMuPDF): OK
      ✔ LLM 接続 (Claude Code CLI): OK
      ✔ Embedding: OK *)

(* 3. PDFをインデックスに登録 *)
pdfIndex["C:\\Users\\<ユーザー名>\\Documents\\sample.pdf",
  Collection -> "default"]

(* 4. 検索 *)
pdfSearch["検索したいキーワード", 5]

(* 5. LLMに質問（RAG） *)
pdfAskLLM["このドキュメントの主な内容は何ですか？"]

(* 6. インタラクティブUI *)
pdfSearchUI["検索キーワード", 10]
```

URLからインデックスを作成する場合:

```mathematica
pdfIndexURL["https://example.com/paper.pdf",
  Collection -> "papers",
  Privacy -> 0.0]
```

ディレクトリ内の全PDFを一括インデックス:

```mathematica
pdfIndexDirectory["C:\\Papers\\",
  Collection -> "papers",
  Privacy -> 0.3]
```

### 主な機能

#### インデクシング

- **`pdfIndex[pdfPath, opts]`** — 単一PDFをインデックスに追加します。テキスト抽出・チャンキング・LLM要約・埋め込み生成を自動実行します。主なオプション: `Privacy`（0.0〜1.0、デフォルト `Automatic` でLLM自動推定）、`Collection`（コレクション名、デフォルト `"default"`）、`Title`、`Keywords`、`ForceReindex`。

- **`pdfIndexDirectory[dirPath, opts]`** — ディレクトリ内の全PDFを一括インデクシングします。`FilePattern -> "*.pdf"` で対象ファイルを絞り込めます。

- **`pdfIndexURL[url, opts]`** — URLからPDFをダウンロードしてインデクシングします。ダウンロード済みファイルはキャッシュされます。

- **`pdfReindex[collection]`** — コレクション内の全ドキュメントのLLM要約・埋め込みベクトルを再生成します。LLMモデル変更後などに使用します。

#### 検索

- **`pdfSearch[query, n, opts]`** — 埋め込み類似度とキーワードを組み合わせたハイブリッド検索で上位n件を `Dataset` として返します。`Collection -> All` で全コレクションを横断検索できます。

- **`pdfSearchUI[query, n, opts]`** — インタラクティブな検索UIをノートブックに表示します。各結果に `[全文]` `[前後]` `[質問]` ボタンが付き、チャンク参照や追加質問を対話的に行えます。

- **`pdfSearchForLLM[query, opts]`** — 検索結果をLLMプロンプト用テキストに変換します。公開分（`"public"`）と秘密分（`"private"`）を分けたアソシエーションを返します。

- **`pdfAskLLM[question, opts]`** — PDFインデックスを検索し、公開分はクラウドLLM、秘密分はローカルLLM（`$ClaudePrivateModel`）に問い合わせます。`IncludeFullText -> True` でチャンク全文をプロンプトに含めます。

#### ページ・チャンク参照

- **`pdfShowPage[pageNum, collection]`** — PDFの指定ページを画像としてノートブックに表示します。クエリ文字列でページ番号を自動推定して表示することも可能です。

- **`pdfFindPage[query, collection]`** — クエリにマッチするページ番号を推定して返します。チャンク位置とTOCからページ番号を計算します。

- **`pdfGetChunk[chunkIndex, collection]`** — インデックス番号のチャンク全文を返します。`{from, to}` の範囲指定で前後チャンクを連結取得できます。

#### 管理

- **`pdfLoadIndex[collection]`** — コレクションのインデックスを `PDFIndexObject` としてメモリにロードします。引数なしで全コレクションをロードします。

- **`pdfListCollections[]`** — 利用可能なコレクション一覧を返します。

- **`pdfListDocs[collection]`** — コレクション内のドキュメント一覧を `Dataset` で返します。

- **`pdfRemoveDoc[docId, collection]`** — ドキュメントをインデックスから削除します。

- **`pdfStatus[]`** — 現在のインデクシング状態を表示します。

- **`pdfPreflightCheck[]`** — PDF抽出・LLM・Embeddingの各機能を一括検証します。

### ドキュメント一覧

| ファイル | 内容 |
|----------|------|
| `api.md` | APIリファレンス（全関数・オプション・戻り値の仕様） |
| `example.md` | 使用例集（インデクシング・検索・管理・ページ表示など） |
| `setup.md` | インストール手順書（依存関係・ディレクトリ構成・動作確認） |
| `user_manual.md` | ユーザーマニュアル（各関数の詳細説明とオプション一覧） |

---

## 使用例・デモ

### 研究論文の管理と質問応答

```mathematica
(* 論文フォルダを一括インデックス登録（公開論文として） *)
pdfIndexDirectory["C:\\Research\\Papers\\",
  Collection -> "papers",
  Privacy -> 0.0]

(* 論文に対して質問 *)
pdfAskLLM["Fredkinゲートの構成方法と可逆性の証明を説明せよ",
  Collection -> "papers",
  MaxItems -> 8]
```

### シラバス・教育資料の検索

```mathematica
(* シラバスPDFをURLからインデックス登録 *)
pdfIndexURL["https://example.ac.jp/syllabus2025.pdf",
  Collection -> "syllabus",
  Title -> "2025年度シラバス",
  Privacy -> 0.5]

(* インタラクティブ検索UIで閲覧 *)
pdfSearchUI["情報工学科 必修科目 単位数", 10, Collection -> "syllabus"]

(* 目的ページを画像で確認 *)
pdfShowPage["カリキュラムマップ", "syllabus"]
```

### LLMプロンプト用テキストの取得

```mathematica
(* 公開分・秘密分を分けて取得 *)
sr = pdfSearchForLLM["量子コンピュータの誤り訂正",
  Collection -> "papers",
  MaxItems -> 10]

(* 公開分のプロンプト文字列 *)
sr["public"]["prompt"]

(* 秘密分のチャンク数 *)
sr["private"]["count"]
```

---

## 免責事項

本ソフトウェアは "as is"（現状有姿）で提供されており、明示・黙示を問わずいかなる保証もありません。
本ソフトウェアの使用または使用不能から生じるいかなる損害についても責任を負いません。
今後の動作保証のための更新が行われるとは限りません。
本ソフトウェアとドキュメントはほぼすべてが生成AIによって生成されたものです。
Windows 11上での実行を想定しており、MacOS, LinuxのMathematicaでの動作検証は一切していません(生成AIの処理で対応可能と想定されます)。

---

## ライセンス

```
MIT License

Copyright (c) 2026 Katsunobu Imai

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.