# PDFIndex 使用例集

## 前提

```mathematica
Get["PDFIndex.wl"]
```

---

## 例 1: 単一 PDF のインデックス登録

```mathematica
pdfIndex["C:/Documents/report2025.pdf", Collection -> "research"]
```

```
[pdfIndex] ドキュメントID: 3a7f2c1b8e4d0591
  タイトル: Annual Report 2025
  ページ数: 48
  ✔ インデックス完了: Annual Report 2025
<| "docId" -> "3a7f2c1b8e4d0591", "title" -> "Annual Report 2025",
   "privacy" -> 0.3, "chunks" -> 127, "collection" -> "research" |>
```

---

## 例 2: ディレクトリ一括インデックス登録

```mathematica
pdfIndexDirectory["C:/Papers/", Collection -> "papers", Privacy -> 0.0]
```

```
[pdfIndexDirectory] 12 ファイルを処理します
--- 1/12: intro.pdf ---
  ...
✔ インデックス完了: 12 件
```

---

## 例 3: URL から PDF をインデックス登録

```mathematica
pdfIndexURL[
  "https://example.ac.jp/syllabus2025.pdf",
  Collection -> "syllabus",
  Title -> "2025年度シラバス"
]
```

```
  URL ダウンロード中: https://example.ac.jp/syllabus2025.pdf...
  タイトル: 2025年度シラバス
  ✔ インデックス完了: 2025年度シラバス
```

---

## 例 4: ハイブリッド検索

```mathematica
idx = pdfLoadIndex["research"];
pdfSearch["reversible computing ゲート構成", 5, Collection -> "research"]
```

```
Dataset[{<| "docId" -> "3a7f...", "title" -> "...", "pageNum" -> 12,
            "score" -> 0.91, "summary" -> "可逆論理ゲートの..." |>, ...}]
```

---

## 例 5: LLM への質問 (RAG)

```mathematica
pdfAskLLM[
  "情報工学科の必修科目と単位数は？",
  Collection -> "syllabus",
  MaxItems -> 8
]
```

```
"情報工学科の必修科目は以下の通りです。
プログラミング基礎（2単位）、データ構造（2単位）、..."
```

---

## 例 6: インタラクティブ検索 UI の起動

```mathematica
pdfSearchUI["カリキュラムマップ", 10, Collection -> "syllabus"]
```

```
（ノートブック内に検索結果カードが表示され、各結果に
  [全文] [前後] [質問] ボタンが付いたインタラクティブ UI が現れます）
```

---

## 例 7: コレクション・ドキュメント管理

```mathematica
(* 利用可能なコレクション一覧 *)
pdfListCollections[]

(* コレクション内ドキュメント一覧 *)
pdfListDocs["research"]

(* ドキュメントの削除 *)
pdfRemoveDoc["3a7f2c1b8e4d0591", "research"]
```

```
{"papers", "research", "syllabus"}

Dataset[{<| "title" -> "Annual Report 2025", "pageCount" -> 48,
            "chunkCount" -> 127, "privacy" -> 0.3, ... |>}]

削除完了: 3a7f2c1b8e4d0591
```

---

## 例 8: ページ表示とチャンク参照

```mathematica
(* PDF の特定ページを画像としてノートブックに表示 *)
pdfShowPage[124, "syllabus"]

(* クエリにマッチするページ番号を推定 *)
pdfFindPage["カリキュラムマップ", "syllabus"]

(* チャンク番号 10〜15 の全文を取得 *)
pdfGetChunk[{10, 15}, "syllabus"]
```

```
（ページ 124 の画像がノートブックに出力されます）

124

"カリキュラムマップ\n\n| 科目コード | 科目名 | 単位 | ..."
```

---

## 動作確認

```mathematica
pdfPreflightCheck[]
```

```
✔ PDF 抽出 (PyMuPDF): OK
✔ LLM 接続 (Claude Code CLI): OK
✔ Embedding: OK