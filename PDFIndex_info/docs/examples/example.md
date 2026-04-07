# PDFIndex 使用例集

PDFIndex パッケージの主な使用例をまとめます。

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
pdfAskLLM["令和6年度の情報工学科の必修単位数は?",
  Collection -> "syllabus",
  MaxItems -> 10
]
```

**期待される出力:** `"令和6年度の情報工学科では、必修科目の合計単位数は○○単位です。（出典: p.XX）"`

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