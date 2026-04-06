# PDFIndex API Reference

PDF文書のインデクシング・多層検索パッケージ。
`maildb.wl` と同じアーキテクチャ（embedding + keyword ハイブリッド検索、公開/秘密分離、LLM問い合わせ）をPDFに適用。

## ストレージ構造

- **公開PDF** (privacy ≤ 0.5): `$packageDirectory/claude_attachments/pdfindex/<collection>/`
  - クラウドLLM（Claude等）で処理可能
- **秘密PDF** (privacy > 0.5): `$dropbox/udb/pdfindex/<collection>/`
  - `$ClaudePrivateModel` (LM Studio等) でのみ処理

各ドキュメントは2つのファイルで構成:
- `doc_<docId>.wl` — メタデータ（タイトル、著者、privacy、ページ数等）
- `chunks_<docId>.wl` — チャンクリスト（テキスト、要約、embedding、タグ）

## 主要API

### インデクシング

```mathematica
(* 単一PDF *)
pdfIndex["path/to/file.pdf"]
pdfIndex["path.pdf", Privacy -> 0.8, Collection -> "papers"]

(* ディレクトリ一括 *)
pdfIndexDirectory["/path/to/pdfs", Collection -> "textbooks"]

(* URLから *)
pdfIndexURL["https://example.com/paper.pdf", Keywords -> {"reversible", "CA"}]
```

### 検索

```mathematica
(* ハイブリッド検索（embedding + keyword + RRF） *)
results = pdfSearch["reversible computing gates", 20]
results = pdfSearch["query", Collection -> "papers", MaxItems -> 10]

(* ボタン付きインタラクティブ検索 *)
pdfSearchUI["離散数学の配当期は？"]
(* → [全文] [前後] [質問] [ページ] ボタンで操作 *)

(* PDFページを画像として表示 *)
pdfShowPage[124]                        (* ページ番号指定 *)
pdfShowPage["離散数学"]                  (* 検索→推定ページを表示 *)
pdfFindPage["離散数学"]                  (* ページ番号のみ返す *)

(* チャンク直接取得 *)
pdfGetChunk[42]                         (* チャンク全文 *)
pdfGetChunk[{40, 44}]                   (* 前後含めて取得 *)

(* LLMプロンプト用: 公開/秘密分離済み *)
sr = pdfSearchForLLM["query", MaxItems -> 20]
(* sr["public"]["prompt"], sr["private"]["prompt"] *)

(* 検索 + LLM回答（mailAskLLM と同様） *)
pdfAskLLM["Fredkinゲートの構成方法は?"]
pdfAskLLM["question", Collection -> "papers", IncludeFullText -> True]
```

### 管理

```mathematica
pdfListCollections[]           (* コレクション一覧 *)
pdfListDocs["default"]         (* ドキュメント一覧 Dataset *)
pdfRemoveDoc["docId"]          (* ドキュメント削除 *)
pdfReindex["default"]          (* 全再インデックス *)
pdfLoadIndex["default"]        (* PDFIndexObject ロード *)
pdfPreflightCheck[]            (* 動作確認 *)
pdfStatus[]                    (* ステータス表示 *)
```

## Privacy モデル

`maildb.wl` と同じ公開/秘密モデル:
- `privacy ≤ 0.5`: クラウドLLM処理可能 → `pdfSearchForLLM` の `public` 側
- `privacy > 0.5`: ローカルLLMのみ → `pdfSearchForLLM` の `private` 側
- `Automatic` 指定時はドキュメント内容からLLMが自動推定

## WebServer 統合

パッケージロード時に WebServer が利用可能なら自動登録:
- `GET /pdfsearch?q=...&collection=default` — HTML検索フォーム＋結果
- `POST /pdfsearch/api` — JSON API (`{"query": "...", "collection": "default"}`)

## ClaudeEval 連携例

```mathematica
(* ClaudeEval から呼ぶ場合 *)
ClaudeEval["reversible computingの論文を検索して要約せよ",
  Model -> Automatic, PrivacySpec -> Automatic]
(* → pdfAskLLM が内部的に呼ばれる *)
```
