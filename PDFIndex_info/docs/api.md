# PDFIndex API リファレンス

PDFIndex パッケージ — PDF ドキュメントのインデクシングとマルチレイヤー検索。
依存: localInit.wl, claudecode.wl (省略可), maildb.wl (embedding 関数)
リポジトリ: https://github.com/transreal/PDFIndex

## 定数・設定変数

### $pdfIndexBaseDir
型: String, 初期値: `FileNameJoin[{$packageDirectory, "pdfindex_private"}]`
Privacy > 0.5 のプライベート PDF インデックスの保存先ディレクトリ。

### $pdfIndexAttachDir
型: String, 初期値: `FileNameJoin[{$packageDirectory, "claude_attachments"}]`
クラウド LLM 処理可能な公開 PDF インデックスの保存先ディレクトリ。

### $pdfIndexDebug
型: Boolean, 初期値: False
True にすると内部処理の詳細ログを Print 出力する。

### $pdfPythonPath
型: String, 初期値: 自動検出 (失敗時 `"python"`)
PDF 抽出・OCR に使用する Python 実行ファイルのパス。パッケージロード時に ExternalEvaluate で自動検出される。

## PDFIndexObject

### PDFIndexObject[<|...|>]
ロード済み PDF インデックスを表すオブジェクト。
`idx["dataset"]`, `idx["nearest"]`, `idx["count"]`, `idx["docs"]` でフィールドにアクセスする。
表示形式: `PDFIndexObject[«collection, N docs, M chunks»]`

## インデクシング

### pdfIndex[pdfPath, opts]
単一 PDF ファイルをインデックスに追加する。Privacy 値に応じて保存先が変わる。
→ Association (インデクシング結果メタデータ)
Options: Privacy -> Automatic (0.0〜1.0。Automatic で LLM 自動推定), Keywords -> {} (追加キーワードリスト), Title -> "" (タイトル上書き), Collection -> "default" (コレクション名), ForceReindex -> False (既存エントリを強制上書き)
例:
```wolfram
pdfIndex["C:/docs/report.pdf",
  Collection -> "research",
  Privacy -> 0.3,
  Keywords -> {"reversible computing", "QCA"}]
```

### pdfIndexDirectory[dirPath, opts]
ディレクトリ内の全 PDF を一括インデックスする。
Options: pdfIndex と同じ + FilePattern -> "*.pdf" (対象ファイルのグロブパターン)
例:
```wolfram
pdfIndexDirectory["C:/docs/papers", Collection -> "research", FilePattern -> "R0*.pdf"]
```

### pdfIndexURL[url, opts]
URL から PDF をダウンロードしてインデックスに追加する。
Options: pdfIndex と同じ

### pdfIndexAsync[pdfPath, opts]
pdfIndex を非同期実行し、進捗をステータスバーに表示する。内部の Claude 呼び出しを NonBlocking (StartProcess + Pause) で実行し、フロントエンドの応答性を維持する。Print 出力がノートブックセル出力に混入しない。
Options: pdfIndex と同じ

### pdfReindex[collection] → Null
コレクション内の全ドキュメントの LLM 要約・embedding を再生成する。

## 検索

### pdfSearch[query, n, opts]
ハイブリッド検索 (embedding + キーワード) で上位 n 件のチャンクを返す。
→ List of Association
Options: Collection -> All (文字列またはAll), MaxItems -> 20, MinPrivacy -> 0.0, MaxPrivacy -> 1.0

### pdfSearchForLLM[query, opts]
検索結果を LLM プロンプト用テキストに変換する。
→ `<|"public" -> <|"prompt" -> String, "count" -> n|>, "private" -> <|"prompt" -> String, "count" -> m|>|>`
Options: MaxItems -> 20, Collection -> All, IncludeFullText -> False
例:
```wolfram
result = pdfSearchForLLM["reversible computing gate", MaxItems -> 5, Collection -> "research"];
result["public"]["prompt"]  (* クラウド LLM へ渡す文字列 *)
result["private"]["prompt"] (* ローカル LLM へ渡す文字列 *)
```

### pdfAskLLM[question, opts]
PDF インデックスを検索し、公開分はクラウド LLM、秘密分は `$ClaudePrivateModel` に問い合わせる。
→ String (LLM の回答)
Options: Collection -> All, MaxItems -> 20, IncludeFullText -> False
例:
```wolfram
pdfAskLLM["reversible computing のゲート構成は?", Collection -> "research"]
```

## ロード・管理

### pdfLoadIndex[collection] → PDFIndexObject
コレクションのインデックスをロードして PDFIndexObject を返す。引数なしの場合は全コレクションをロードする。

### pdfLoadIndex[] → List of PDFIndexObject
全コレクションをロードして PDFIndexObject のリストを返す。

### pdfListCollections[] → List of String
利用可能なコレクション名の一覧を返す。

### pdfListDocs[collection] → Dataset
コレクション内のドキュメント一覧を Dataset 形式で返す。

### pdfRemoveDoc[docId, collection] → Null
指定 docId のドキュメントをインデックスから削除する。docId は SHA256 先頭 16 桁の 16 進文字列。

### pdfStatus[] → Null
現在のインデクシング状態 (`$pdfIndexTaskStatus`) をノートブックに表示する。

### pdfPreflightCheck[] → Association
PDF 抽出 (PyMuPDF/pdfplumber)・LLM (ClaudeQueryBg)・Embedding (LM Studio) の動作確認を行い、各コンポーネントのステータスを返す。

## UI・表示

### pdfSearchUI[query, n, opts]
インタラクティブな検索結果をノートブックに表示する。各結果に [全文] [前後] [質問] ボタンを生成する。[全文]: チャンクの全テキストを出力。[前後]: 前後チャンクを含むコンテキストを表示。[質問]: そのチャンクを元に ClaudeQuery で質問。
Options: Collection -> "default"

### pdfGetChunk[chunkIndex, collection] → String
コレクション内の指定インデックス番号のチャンク全文を返す。
`pdfGetChunk[{from, to}, collection]` で範囲指定チャンクを連結して返す。

### pdfShowPage[pageNum, collection] → Null
PDF の指定ページを画像としてノートブックに表示する。
`pdfShowPage[pageNum, collection, "file"]` は画像ファイルパスを String で返す。
`pdfShowPage[pageNum]` のように collection 省略時は "default" を使用する。

### pdfFindPage[query, collection] → Integer
クエリにマッチする PDF ページ番号を推定して返す。チャンク位置と PDF メタデータからページ番号を計算する。

## データ構造メモ

チャンク Association の主要キー:
- `"pageNum"` — 開始ページ番号
- `"endPageNum"` — 終了ページ番号 (表チャンクのみ)
- `"chunkIdx"` — ページ内チャンク番号
- `"globalIdx"` — ドキュメント全体のチャンク番号
- `"text"` — チャンクテキスト本文
- `"charCount"` — テキスト文字数
- `"isTable"` — True の場合は表チャンク (Markdown 表形式)
- `"tableCaption"` — 表キャプション (isTable == True のとき)
- `"isFigure"` — True の場合は図チャンク

ドキュメント Association の主要キー:
- `"docId"` — SHA256 先頭 16 桁の文字列 ID
- `"title"` — タイトル
- `"pdfPath"` — 元 PDF のパス
- `"collection"` — コレクション名
- `"privacy"` — プライバシー値 (0.0〜1.0)
- `"keywords"` — キーワードリスト
- `"yearInfo"` — `<|"westernYear"->Integer, "japaneseYear"->String, ...|>` (年度情報、該当する場合)
- `"chunkCount"` — チャンク数

## 内部定数 (調整可能)

以下のプライベート変数は `PDFIndex`Private`` コンテキストに属するが、高度な調整で変更できる。
- `$chunkMaxChars = 2000` — 1 チャンクの最大文字数
- `$chunkOverlap = 200` — チャンク間のオーバーラップ文字数
- `$summaryMaxChars = 150` — LLM 要約の最大文字数
- `$embeddingEndpoint = "http://localhost:1234/v1/embeddings"` — LM Studio の embedding API エンドポイント
- `$embeddingModel = "text-embedding-multilingual-e5-large-instruct"` — embedding モデル名

## 依存関係・動作要件

- **Python**: PyMuPDF (`fitz`) または pdfplumber が必要。OCR には EasyOCR も利用可能。
- **LLM**: claudecode.wl の `ClaudeQueryBg` / `ClaudeQuery` 経由 (Claude Code CLI、課金なし)。秘密文書には `$ClaudePrivateModel` (ローカル LLM)。
- **Embedding**: LM Studio (localhost:1234) の OpenAI 互換 API。失敗時は maildb.wl 経由、それも失敗ならキーワード検索のみで代替。
- **OCR パイプライン優先順**: Claude Vision (ClaudeQueryBg) → EasyOCR → Mathematica TextRecognize