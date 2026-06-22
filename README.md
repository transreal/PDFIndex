# PDFIndex

PDF ドキュメントのインデクシングとマルチレイヤーハイブリッド検索パッケージ

## 設計思想と実装の概要

PDFIndex は、PDF ファイルのテキストを抽出・チャンク化し、Embedding ベクトルとキーワードを組み合わせたハイブリッド検索と LLM 連携を提供する Wolfram Language パッケージです。

### 設計の中心にある「プライバシー分離」

このパッケージの最も重要な設計原則は、**プライバシースコアによる公開・非公開の自動分離**です。0.0〜1.0 の数値で表されるプライバシースコアは、LLM が文書タイトルと冒頭テキストから自動推定します。スコアが 0.5 を超える文書は `$pdfIndexBaseDir`（ローカル専用）に、それ以下の文書は `$pdfIndexAttachDir`（クラウド LLM 処理可能）に格納されます。この分離は `pdfSearchForLLM` や `pdfAskLLM` にも引き継がれ、クラウド LLM には公開文書のチャンクのみが渡され、非公開文書はローカル LLM (`$ClaudePrivateModel`) に問い合わせます。人事情報・成績・給与情報が機密外部サービスに漏れるリスクを構造的に排除した設計です。

### 多層的な PDF テキスト抽出

テキスト抽出は信頼性を最優先した多段フォールバック構成です。**PyMuPDF (fitz)** が最優先で使用され、インストールされていない場合は **pdfplumber** にフォールバックし、最終的には Mathematica ネイティブの `Import` が使われます。

文字化け検出も実装されており、CIDフォント等に起因するページは「ひらがな連続のパターン頻度」をヒューリスティクスとして検出されます。文字化けが検出されたページは OCR パイプライン（**EasyOCR（並列）→ Claude Vision CLI（失敗ページのみ逐次フォールバック）→ TextRecognize** の順）で自動修復されます。EasyOCR ステップは `$pdfParallelKernelCount` のサブカーネルで並列実行され、大量のスキャンページでも効率的に処理されます。

### 構造化チャンキングと表の保全

単純な文字数ベースのチャンキングに加え、PyMuPDF の `find_tables()` を使った**構造化チャンキング**に対応しています。表は複数ページにまたがる場合もマージされ、1つの表が1チャンクとして Markdown 表形式で格納されます。これにより、単位数表・配当表などの表形式データをそのまま検索・LLM 参照できます。

目次（TOC）抽出も実装されており、クエリにマッチするセクションのページ範囲を特定することで、関連チャンクの絞り込み精度を高めます。論理ページラベル（印刷ページ番号）と物理ページ番号の対応も自動検出・変換されるため、表紙・前付きのある PDF でも印刷上のページ番号をそのまま指定できます。

### エンティティインデックスによるクエリ正規化

インデクシング時に、学科名・人名・建物名などの固有名詞一覧を**エンティティインデックス**として自動生成します。固有名詞はページ本文だけでなくドキュメントタイトルからも抽出されます。検索時はこのエンティティインデックスと検索辞書（エイリアス・ターム展開）を組み合わせてクエリタームを自動正規化するため、略称や表記ゆれがあっても高精度な検索が可能です。

### スコアリングアルゴリズム

`pdfSearch` はチャンク単位の Embedding 近傍検索を起点としたページスコアリングを行い、複数ターム共起ボーナス・見出し一致ボーナス・目次一致ボーナス・目次ページペナルティ・学科名ペナルティを組み合わせて関連性の高いページを上位に返します。複数のタームが同一チャンクや目次エントリで揃って一致するほどスコアが乗算的に増幅されるため、具体的な複合クエリほど精度が向上します。

### LLM・Embedding の非課金設計

LLM 呼び出しはすべて [claudecode](https://github.com/transreal/claudecode) の `ClaudeQueryBg` / `ClaudeQuery` 経由で行われ、**Claude Code CLI を使用するため課金 API は呼ばれません**。Embedding は **LM Studio のローカルサーバー**（`text-embedding-baai-bge-m3-568m`）を OpenAI 互換 API で直接呼び出します。bge-m3 は最大 8192 トークンに対応した多言語モデルで、複数ページにわたる表や長文チャンクも途切れずに Embedding できます。LM Studio が起動していない場合はキーワード検索のみで動作します。

### 非同期インデクシングとノートブック統合

`pdfIndexAsync` は `StartProcess + Pause` による NonBlocking 実行で Claude 呼び出しを行い、フロントエンドの応答性を維持したまま大きな PDF を処理できます。進捗はステータスバーに表示され、Print 出力がセル出力に混入することもありません。

---

## 詳細説明

### 動作環境

| 項目 | 要件 |
|------|------|
| Mathematica | 13.1 以上 |
| Python | 3.9 以上（ExternalEvaluate 経由） |
| LM Studio | 0.3 以上（ローカル Embedding 用） |
| OS | Windows 11（macOS/Linux は動作未検証） |

### インストール

#### 依存パッケージ

| パッケージ | 必須 | リンク |
|-----------|------|--------|
| localInit | **必須** | [github.com/transreal/localInit](https://github.com/transreal/localInit) |
| claudecode | 推奨（LLM 検索・Claude Vision OCR に使用） | [github.com/transreal/claudecode](https://github.com/transreal/claudecode) |
| maildb | 任意（Embedding フォールバック） | [github.com/transreal/maildb](https://github.com/transreal/maildb) |

各 `.wl` ファイルを `$packageDirectory` に配置してください。

```
C:\Users\<ユーザー名>\Documents\WolframPackages\
  ├── localInit.wl
  ├── claudecode.wl        ← 推奨
  ├── maildb.wl            ← 任意
  └── PDFIndex.wl
```

#### Python ライブラリのインストール

```
pip install pymupdf
```

OCR 機能（文字化けページの修復）を使う場合は追加でインストールします。

```
pip install easyocr
pip install pdfplumber
```

#### LM Studio のセットアップ（ローカル Embedding）

1. [LM Studio](https://lmstudio.ai/) をインストールして起動します。
2. モデル `text-embedding-baai-bge-m3-568m` をダウンロードします。
3. **Local Server** タブで **Start Server** を実行します（デフォルトポート: `1234`）。

> bge-m3 は最大 8192 トークンに対応しており、以前使用していた `e5-large-instruct`（512 トークン上限）と比べて表・配当表を含む長文チャンクの検索精度が向上しています。

> LM Studio が起動していない場合、Embedding は使用されず**キーワード検索のみ**で動作します。

詳細なセットアップ手順（OCR フォールバックの優先順位・検索辞書の設定など）は [setup.md](setup.md) を参照してください。

#### $Path の設定とパッケージの読み込み

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

### クイックスタート

```mathematica
(* 1. パッケージを読み込む *)
Block[{$CharacterEncoding = "UTF-8"},
  Needs["PDFIndex`", "PDFIndex.wl"]]

(* 2. 主要な設定変数（デフォルト値） *)
(* $pdfIndexBaseDir        ... 秘密 PDF インデックスの保存先
                               デフォルト: $packageDirectory\pdfindex_private *)
(* $pdfIndexAttachDir      ... 公開 PDF インデックスの保存先
                               デフォルト: $packageDirectory\claude_attachments *)
(* $pdfIndexDebug          ... デバッグ出力の有効化（デフォルト: False） *)
(* $pdfParallelKernelCount ... OCR 並列サブカーネル数（デフォルト: Automatic） *)
(* $PDFIndexDefaultDepartment ... クエリ補完用デフォルト学科名（デフォルト: None） *)

(* 3. 動作確認 *)
pdfPreflightCheck[]

(* 4. PDF をインデックスに追加する（プライバシー自動推定・エンティティインデックス自動生成） *)
pdfIndex["C:\\research\\paper.pdf",
  Collection -> "research",
  Keywords -> {"reversible computing", "QCA"}]

(* 5. ハイブリッド検索（Embedding + キーワード）で上位 5 件を取得 *)
pdfSearch["可逆計算 ゲート構成", 5, Collection -> "research"]

(* 6. PDF インデックスを参照して LLM に質問する *)
pdfAskLLM["reversible computing のゲート構成は?", Collection -> "research"]
```

保存先やその他の変数をカスタマイズする場合はパッケージ読み込み後に設定します。

```mathematica
PDFIndex`$pdfIndexBaseDir             = "D:\\MyPDFIndex\\private"
PDFIndex`$pdfIndexAttachDir           = "D:\\MyPDFIndex\\public"
PDFIndex`$pdfParallelKernelCount      = 4
PDFIndex`$PDFIndexDefaultDepartment   = "情報工学科"
```

### 主な機能

#### インデクシング

| 関数 | 説明 |
|------|------|
| `pdfIndex[pdfPath, opts]` | 単一 PDF をインデックスに追加する。Privacy 値に応じて保存先が自動選択される。エンティティインデックス（固有名詞一覧）も自動生成される。 |
| `pdfIndexDirectory[dirPath, opts]` | ディレクトリ内の全 PDF を一括インデックスする。`FilePattern` で対象ファイルを絞り込み可能。 |
| `pdfIndexURL[url, opts]` | URL から PDF をダウンロードしてインデックスに追加する。 |
| `pdfIndexAsync[pdfPath, opts]` | `pdfIndex` を非同期実行し、進捗をステータスバーに表示する。ノートブックの応答性を維持する。 |
| `pdfReindex[collection]` | コレクション内の全ドキュメントの LLM 要約・Embedding・エンティティインデックスを再生成する（フル再処理）。 |
| `pdfReembed[collection]` | 保存済みチャンクテキストから Embedding のみを再生成・更新する。PDF 再抽出・LLM 再要約を行わない軽量版。エンコード修正後の既存 Embedding 再作成に使う。 |

主なオプション:

| オプション | デフォルト | 説明 |
|-----------|-----------|------|
| `Privacy` | `Automatic` | 0.0〜1.0。`Automatic` で LLM が自動推定する。 |
| `Keywords` | `{}` | 追加キーワードのリスト。 |
| `Title` | `Automatic` | タイトルの上書き（省略時は PDF メタデータから取得）。 |
| `Collection` | `"default"` | コレクション名。 |
| `ForceReindex` | `False` | 既存エントリを強制的に上書きする。 |

#### 検索

| 関数 | 説明 |
|------|------|
| `pdfSearch[query, n, opts]` | Embedding + キーワードのハイブリッド検索で上位 n 件のチャンクを返す。検索辞書とエンティティインデックスによるクエリ正規化が自動適用される。 |
| `pdfSearchForLLM[query, opts]` | 検索結果を LLM プロンプト用テキストに変換する。公開・非公開を分離して返す。 |
| `pdfAskLLM[question, opts]` | PDF インデックスを検索し、公開分はクラウド LLM、非公開分はローカル LLM に問い合わせる。 |
| `pdfSearchUI[query, n, opts]` | インタラクティブな検索 UI をノートブックに表示する。`[全文]` `[前後]` `[質問]` ボタン付き。 |

#### インデックス管理・表示

| 関数 | 説明 |
|------|------|
| `pdfLoadIndex[collection]` | コレクションのインデックスをロードして `PDFIndexObject` を返す。引数なしで全コレクションをロード。 |
| `pdfListCollections[]` | 利用可能なコレクションの一覧を返す。 |
| `pdfListDocs[collection]` | コレクション内のドキュメント一覧を `Dataset` で返す。 |
| `pdfRemoveDoc[docId, collection]` | ドキュメントをインデックスから削除する。 |
| `pdfShowPage[pageNum, collection]` | PDF の指定ページを画像としてノートブックに表示する。論理ページ番号は物理ページへ自動変換される。 |
| `pdfGetChunk[chunkIndex, collection]` | 指定インデックスのチャンク全文を返す。範囲指定も可能。 |
| `pdfFindPage[query, collection]` | クエリにマッチする PDF のページ番号を推定して返す。 |
| `pdfStatus[]` | 現在のインデクシング状態を表示する。 |
| `pdfPreflightCheck[]` | PDF 抽出・LLM・Embedding の動作確認を行い、各項目の状態を表示する。 |

各関数のシグネチャ・オプション・戻り値の詳細は [user_manual.md](user_manual.md) と [api.md](api.md) を参照してください。

### ドキュメント一覧

| ファイル | 内容 |
|---------|------|
| [api.md](api.md) | API リファレンス（関数シグネチャ・オプション・戻り値の詳細） |
| [examples/example.md](examples/example.md) | 使用例集（単一 PDF・ディレクトリ・URL・検索・UI・LLM 質問・検索辞書・デフォルト学科・並列カーネル・エンティティインデックスなど 14 例） |
| [setup.md](setup.md) | セットアップ手順（Python ライブラリ・LM Studio・インストール・OCR フォールバック・検索辞書・動作確認） |
| [user_manual.md](user_manual.md) | ユーザーマニュアル（設定変数・各関数の詳細説明・スコアリングアルゴリズム） |

---

## 使用例・デモ

リポジトリ: [https://github.com/transreal/PDFIndex](https://github.com/transreal/PDFIndex)

### 例 1: 単一 PDF のインデックス登録

```mathematica
pdfIndex["C:/Users/user/Documents/syllabus_R06.pdf",
  Title -> "令和6年度シラバス",
  Collection -> "syllabus",
  Privacy -> 0.5
]
(* → "Indexed: syllabus_R06.pdf (42 chunks)" *)
```

### 例 2: ディレクトリ一括インデックス

```mathematica
pdfIndexDirectory["C:/Users/user/Documents/reports/",
  Collection -> "annual_reports",
  FilePattern -> "*.pdf"
]
(* → "Indexed 7 files, 381 chunks total" *)
```

### 例 3: インタラクティブ検索 UI

```mathematica
pdfSearchUI["reversible computing ゲート構成", 8,
  Collection -> "syllabus"
]
(* → ノートブックに [全文] [前後] [質問] ボタン付き検索結果が表示される *)
```

### 例 4: LLM に質問する

```mathematica
pdfAskLLM["令和6年度の情報工学科の必修単位数は?",
  Collection -> "syllabus",
  MaxItems -> 10
]
(* → "令和6年度の情報工学科では、必修科目の合計単位数は○○単位です。（出典: p.XX）" *)
```

### 例 5: 非同期インデックス（進捗表示付き）

```mathematica
pdfIndexAsync["C:/Users/user/Documents/large_handbook.pdf",
  Collection -> "handbook",
  ForceReindex -> True
]
(* → ステータスバーに進捗が表示され、完了後に "Done: 156 chunks indexed" と出力 *)
```

### 例 6: LLM プロンプト用テキストの取得

```mathematica
result = pdfSearchForLLM["reversible computing gate",
  MaxItems -> 5,
  Collection -> "research"];
result["public"]["prompt"]   (* クラウド LLM へ渡す文字列 *)
result["private"]["prompt"]  (* ローカル LLM へ渡す文字列 *)
```

### 例 7: 指定ページを画像として表示する

```mathematica
(* 印刷上のページ番号を指定 → 物理ページ番号への変換は自動 *)
pdfShowPage[124, "syllabus"]
(* → ノートブックのセル出力に該当ページの画像がインラインで表示される *)
```

### 例 8: 検索辞書を設定してエイリアス・ターム展開を利用する

`$packageDirectory` に `pdfindex_search_config.json` を配置すると、略称を正規名に変換したり複合語をサブワードに展開して検索精度を向上させたりできます。

```json
{
  "aliases": {
    "機械工学科": "機械システム工学科",
    "情工": "情報工学科"
  },
  "term_expansions": {
    "必修科目": ["必修", "科目"],
    "配当表": ["配当", "科目表"]
  }
}
```

```mathematica
(* 略称でも正規名と同等の検索結果が得られる *)
pdfSearch["機械工学科 必修", 5, Collection -> "syllabus"]
(* → "機械工学科" が自動的に "機械システム工学科" に解決されたうえで検索される *)
```

### 例 9: デフォルト学科を設定してクエリを絞り込む

```mathematica
(* 情報工学科専用コレクションとして使う場合 *)
PDFIndex`$PDFIndexDefaultDepartment = "情報工学科";

(* 学科名を省略しても情報工学科のページが優先される *)
pdfSearch["必修単位数", 5, Collection -> "syllabus"]

(* 補完をオフに戻す *)
PDFIndex`$PDFIndexDefaultDepartment = None;
```

### 例 10: 並列カーネル数を設定して OCR を高速化する

```mathematica
(* 並列カーネル数を 4 に固定 *)
PDFIndex`$pdfParallelKernelCount = 4;

(* 文字化けページが多い PDF をインデックス *)
pdfIndex["C:/Users/user/Documents/old_catalog.pdf",
  Collection -> "archive",
  ForceReindex -> True
]
(* → 4 つのサブカーネルで EasyOCR が並列実行され、処理速度が向上する。
     EasyOCR で失敗したページのみ Claude Vision CLI → TextRecognize の順でフォールバックされる *)
```

### 例 11: エンティティインデックスを再構築する

```mathematica
(* 既存コレクションのエンティティインデックスを再構築 *)
pdfReindex["syllabus"]
(* → LLM 要約・Embedding・固有名詞インデックスがすべて再生成される *)
```

### 例 12: Embedding のみを軽量再生成する

```mathematica
(* PDF 再抽出・LLM 再要約を行わずに Embedding だけを更新する *)
pdfReembed["research"]
(* → エンコード修正後や Embedding モデル変更後に使用する *)
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