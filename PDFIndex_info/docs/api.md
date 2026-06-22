# PDFIndex API リファレンス

PDF文書のインデックス化と多層検索（embedding + キーワード）を行うパッケージ。LLM要約・embedding 生成・OCR フォールバック（Claude Vision / EasyOCR / TextRecognize）を備える。依存: localInit.wl, claudecode.wl（任意）, maildb.wl（embedding 関数）。Python（PyMuPDF/fitz、フォールバックで pdfplumber）が PDF 抽出に必要。

## インデックス操作

### pdfIndex[pdfPath, opts]
単一PDFをインデックスに追加する。
→ docId（追加されたドキュメントの識別子）
Options: Privacy -> Automatic (0.0〜1.0。Automatic で LLM が推定。>0.5 は $pdfIndexBaseDir、それ以外は $pdfIndexAttachDir に保存), Keywords -> {} ({"key1",...}), Title -> Automatic ("タイトル"), Collection -> "default" (コレクション名), ForceReindex -> False (既存でも再インデックス)
例: pdfIndex["paper.pdf", Collection -> "research", Keywords -> {"reversible"}]

### pdfIndexDirectory[dirPath, opts]
ディレクトリ内の全PDFを一括インデックスする。
→ docId のリスト
Options: pdfIndex と同じ + FilePattern -> "*.pdf" (対象ファイルパターン)

### pdfIndexURL[url, opts] → docId
URLからPDFをダウンロードしてインデックスする。Options は pdfIndex と同じ。

### pdfIndexAsync[pdfPath, opts]
pdfIndex を実行し、進捗をステータスバーに表示する。Print 出力がノートブックのセル出力に混入しない。内部の Claude 呼び出しは NonBlocking（StartProcess + Pause）でフロントエンドの応答性を維持。Options は pdfIndex と同じ。

### pdfReindex[collection] → 結果
コレクション内の全ドキュメントのLLM要約・embedding を再生成する。

### pdfReembed[collection] → 結果
保存済みチャンクのテキストから embedding だけを再生成して更新する。PDF再抽出・LLM再要約は行わない（軽量）。エンコード修正後に既存 embedding を作り直す用途。

## 検索

### pdfSearch[query, n, opts]
ハイブリッド検索（embedding + キーワード）で上位n件を返す。
→ 検索結果リスト
Options: Collection -> All (対象コレクション), MaxItems -> 20 (最大取得数), MinPrivacy -> 0.0 (下限プライバシー), MaxPrivacy -> 1.0 (上限プライバシー)

### pdfSearchForLLM[query, opts]
検索結果をLLMプロンプト用テキストに変換する。
→ <|"public" -> <|"prompt"->..., "count"->n|>, "private" -> <|"prompt"->..., "count"->m|>|>
Options: MaxItems (最大取得数), Collection (対象コレクション), IncludeFullText (チャンク全文を含めるか)

### pdfAskLLM[question, opts]
PDFインデックスを検索し、公開分はクラウドLLM、秘密分は $ClaudePrivateModel に問い合わせる。
→ 回答テキスト
Options: Collection, MaxItems, IncludeFullText
例: pdfAskLLM["reversible computing のゲート構成は?"]

## ロード・管理

### pdfLoadIndex[collection] → PDFIndexObject
コレクションのインデックスをロードする。pdfLoadIndex[] で全コレクションをロード。

### pdfListCollections[] → リスト
利用可能なコレクション一覧を返す。

### pdfListDocs[collection] → Dataset
コレクション内のドキュメント一覧を Dataset で返す。

### pdfRemoveDoc[docId, collection]
ドキュメントをインデックスから削除する。

### pdfStatus[] → 表示
現在のインデックシング状態を表示する。

### pdfPreflightCheck[] → 結果
PDF抽出・LLM・Embedding の動作確認を行う。

## チャンク・ページアクセス

### pdfGetChunk[chunkIndex, collection] → String
インデックス番号のチャンク全文を返す。pdfGetChunk[{from, to}, collection] で範囲のチャンクを連結して返す。

### pdfShowPage[pageNum, collection]
PDFの指定ページを画像としてノートブックに表示する。pdfShowPage[pageNum, collection, "file"] は画像ファイルパスを返す。
例: pdfShowPage[124]

### pdfFindPage[query, collection] → ページ番号
クエリにマッチするPDFページ番号を推定して返す。チャンク位置とPDFメタデータから計算する。

### pdfSearchUI[query, n, opts]
インタラクティブな検索結果を表示する。各結果に [全文]（チャンク全文をノートブックに出力）, [前後]（前後チャンクを含むコンテキスト表示）, [質問]（そのチャンクを元に ClaudeQuery で質問）ボタンを表示。
Options: Collection -> "default"

## PDFIndexObject

### PDFIndexObject[<|...|>]
ロード済みPDFインデックスを表すラッパー。文字列キーでアクセスする: idx["dataset"], idx["nearest"], idx["count"], idx["docs"], idx["collection"], idx["docCount"], idx["chunkCount"]。

## 変数

### $pdfIndexBaseDir
型: String, 初期値: FileNameJoin[{$packageDirectory, "pdfindex_private"}]
プライベートPDFインデックス（Privacy > 0.5）の保存先。

### $pdfIndexAttachDir
型: String, 初期値: FileNameJoin[{$packageDirectory, "claude_attachments"}]
クラウドLLM処理可能なPDFの保存先。

### $pdfIndexDebug
型: Boolean, 初期値: False
True でデバッグ出力を有効にする。

### $pdfPythonPath
型: String, 初期値: パッケージロード時に ExternalEvaluate で検出（取得失敗時 "python"）
Python 実行ファイルのパス。