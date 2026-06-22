---

## 例 1: 単一 PDF をインデックスに追加する

```mathematica
Needs["PDFIndex`"]

pdfIndex["C:/Users/user/Documents/syllabus_R06.pdf",
  Title -> "令和6年度シラバス",
  Collection -> "syllabus",
  Privacy -> 0.5
]
```

**期待される出力:** `"Indexed: syllabus_R06.pdf (42 chunks)"`

---

## 例 2: ディレクトリ内の全 PDF を一括インデックスする

```mathematica
pdfIndexDirectory["C:/Users/user/Documents/reports/",
  Collection -> "annual_reports",
  FilePattern -> "*.pdf"
]
```

**期待される出力:** `"Indexed 7 files, 381 chunks total"`

---

## 例 3: URL から PDF をダウンロードしてインデックスする

```mathematica
pdfIndexURL["https://example.ac.jp/curriculum_guide_2025.pdf",
  Collection -> "curriculum",
  Privacy -> 0.3
]
```

**期待される出力:** `"Downloaded and indexed: curriculum_guide_2025.pdf"`

---

## 例 4: キーワードで検索して上位件数を取得する

```mathematica
results = pdfSearch["情報工学科 必修科目", 5,
  Collection -> "syllabus"
]
results
```

**期待される出力:** `Dataset[...]` (スコア降順の上位 5 件のチャンク一覧)

検索スコアリングには複数タームの共起ボーナス・見出し一致ボーナス・目次一致ボーナス・目次ページペナルティ・学科名ペナルティが適用され、より関連性の高いページが上位に来ます。複数タームがチャンク本文や目次（TOC）エントリで揃って一致するほどスコアが乗算的に増幅されるため、具体的な複合クエリほど精度が向上します。

---

## 例 5: インタラクティブ検索 UI を表示する

```mathematica
pdfSearchUI["reversible computing ゲート構成", 8,
  Collection -> "syllabus"
]
```

**期待される出力:** ノートブックに検索結果と `[全文]` `[前後]` `[質問]` ボタンが表示されます。

---

## 例 6: PDF インデックスを参照して LLM に質問する

```mathematica
pdfAskLLM["情報工学科の必修単位数は?",
  Collection -> "syllabus",
  MaxItems -> 10
]
```

**期待される出力:** `"情報工学科では、必修科目の合計単位数は○○単位です。（出典: p.XX）"`

---

## 例 7: コレクション内のドキュメント一覧を確認する

```mathematica
pdfListCollections[]
pdfListDocs["syllabus"]
```

**期待される出力:** コレクション名リストと、ドキュメントメタデータ（タイトル・ページ数・追加日時）の `Dataset`

---

## 例 8: 指定ページを画像としてノートブックに表示する

```mathematica
pdfShowPage[124, "syllabus"]
```

**期待される出力:** ノートブックのセル出力に p.124 の画像がインラインで表示されます。

PDF によっては表紙・前付きページの存在により、印刷上の「p.1」が物理ページ番号 3 や 5 に相当することがあります。PDFIndex は論理ページラベル（印刷ページ番号）と物理ページ番号の対応を自動検出・変換するため、ユーザーは印刷上のページ番号をそのまま指定できます。ページラベルは目次（TOC）抽出と同時に取得され、TOC のページ番号もラベル基準に補正されます。

```mathematica
(* 印刷上のページ番号を指定 → 物理ページ番号への変換は自動 *)
pdfShowPage[1, "syllabus"]
```

---

## 例 9: 非同期インデックス（進捗表示付き）

```mathematica
pdfIndexAsync["C:/Users/user/Documents/large_handbook.pdf",
  Collection -> "handbook",
  ForceReindex -> True
]
```

**期待される出力:** ステータスバーに進捗が表示され、完了後に `"Done: 156 chunks indexed"` と出力されます。

---

## 例 10: 動作確認（プリフライトチェック）

```mathematica
pdfPreflightCheck[]
```

**期待される出力:** PDF 抽出・LM Studio Embedding・LLM 接続の各項目に `✓` または `✗` が表示されます。

---

## 例 11: 検索辞書を設定してエイリアス・ターム展開を利用する

パッケージディレクトリに `pdfindex_search_config.json` を配置すると、略称を正規名に自動変換したり、複合語をサブワードに展開して検索精度を向上させたりできます。

```json
{
  "aliases": {
    "_comment": "略称 → 正規名のマッピング",
    "機械工学科": "機械システム工学科",
    "情工": "情報工学科",
    "センター": "国際センター"
  },
  "term_expansions": {
    "_comment": "複合語 → サブワードリストのマッピング",
    "必修科目": ["必修", "科目"],
    "開設科目": ["開設", "科目"]
  }
}
```

設定ファイルを配置後、パッケージを再ロードするか `iLoadSearchConfig[]` を実行すると辞書が読み込まれます。エイリアス・ターム展開はマッチ用に正規化した版でも照合されるため、表記ゆれにも対応します。

```mathematica
(* 略称でも正規名と同等の検索結果が得られる *)
pdfSearch["機械工学科 必修", 5, Collection -> "syllabus"]
```

**期待される出力:** "機械工学科" が自動的に "機械システム工学科" に解決されたうえで検索されます。

---

## 例 12: デフォルト学科を設定してクエリを絞り込む

クエリに学科名が含まれない場合に補完するデフォルト学科を設定できます。特定の学科のシラバスを主に検索する運用に適しています。

```mathematica
(* デフォルト学科を設定 *)
PDFIndex`$PDFIndexDefaultDepartment = "情報工学科";

(* 学科名を省略しても情報工学科のページが優先される *)
pdfSearch["必修単位数", 5, Collection -> "syllabus"]
```

設定を解除するには `None` を代入します。

```mathematica
PDFIndex`$PDFIndexDefaultDepartment = None;
```

---

## 例 13: 並列カーネル数を設定して OCR を高速化する

文字化けページ（CID フォント等でテキスト抽出が破綻したページ）は自動検出され、多段 OCR パイプラインで再抽出されます。優先順位は **EasyOCR（並列実行）→ Claude Vision CLI（失敗ページのみ逐次フォールバック）→ TextRecognize（最終手段）** です。EasyOCR ステップは並列サブカーネルで処理され、デフォルトのカーネル数は `Min[$ProcessorCount - 1, 6]` ですが、明示的に指定できます。

```mathematica
(* 並列カーネル数を 4 に固定 *)
PDFIndex`$pdfParallelKernelCount = 4;

(* 文字化けページが多い PDF をインデックス *)
pdfIndex["C:/Users/user/Documents/old_catalog.pdf",
  Collection -> "archive",
  ForceReindex -> True
]
```

**期待される出力:** 文字化けページが検出され、4 つのサブカーネルで EasyOCR が並列実行されます。EasyOCR で読み取れなかったページのみ Claude Vision CLI（利用可能な場合）でフォールバック再抽出され、それでも失敗したページは TextRecognize で処理されます。`$pdfIndexDebug = True` を設定すると、各ページの採用 OCR 手法（EasyOCR / ClaudeVision / TextRecognize）と文字数が出力されます。

```mathematica
(* OCR の進捗・採用手法を確認したい場合 *)
PDFIndex`$pdfIndexDebug = True;
pdfIndex["C:/Users/user/Documents/old_catalog.pdf",
  Collection -> "archive", ForceReindex -> True]
```

---

## 例 14: エンティティインデックスを構築・再構築する

固有名詞（学科名・人名・施設名・センター名など）の検索精度を高めるエンティティインデックスを、既存コレクションに対して構築または再構築できます。インデックス追加時に自動生成されますが、手動で再構築することもできます。

```mathematica
(* 既存コレクションのエンティティインデックスを再構築 *)
pdfReindex["syllabus"]
```

エンティティインデックスはコレクションディレクトリにコレクションレベルのファイルとして保存され、次回検索時から自動的に利用されます。固有名詞の抽出源は以下の通りです。

- **チャンクテキスト**: 各ページの本文から学科名・人名・施設名などを抽出
- **ドキュメントタイトル**: ドキュメントのメタデータタイトルからも固有名詞を抽出（タイトルに学科名や年度情報が含まれる場合に有効）

抽出された固有名詞はクエリタームの正規化に使用され、「国際センター」「機械システム工学科」などの固有名詞検索の精度が向上します。既存ドキュメント互換のため、ドキュメント別エンティティファイルも引き続き読み込まれます。