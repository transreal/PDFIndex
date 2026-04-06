(* ::Package:: *)

(* PDFIndex.wl - PDF Document Indexing & Multi-layer Search Package *)
(* Date: 2026-04-04 *)
(* 依存: localInit.wl, claudecode.wl (optional), maildb.wl (embedding functions) *)
(* エンコード: UTF-8 *)

BeginPackage["PDFIndex`"];

(* === Exported Symbols === *)
PDFIndexObject::usage =
  "PDFIndexObject[<|...|>] はロード済みPDFインデックスを表す。\n" <>
  "idx[\"dataset\"], idx[\"nearest\"], idx[\"count\"], idx[\"docs\"] でアクセス。";

$pdfIndexBaseDir::usage =
  "$pdfIndexBaseDir はプライベートPDFインデックスの保存先。\n" <>
  "デフォルト: FileNameJoin[{$packageDirectory, \"pdfindex_private\"}]";

$pdfIndexAttachDir::usage =
  "$pdfIndexAttachDir はクラウドLLM処理可能なPDFの保存先。\n" <>
  "デフォルト: FileNameJoin[{$packageDirectory, \"claude_attachments\"}]";

(* ---- インデクシング ---- *)
pdfIndex::usage =
  "pdfIndex[pdfPath, opts] は単一PDFをインデックスに追加する。\n" <>
  "オプション: Privacy -> 0.0〜1.0 (デフォルト Automatic で LLM 推定),\n" <>
  "  Keywords -> {\"key1\", ...}, Title -> \"タイトル\",\n" <>
  "  Collection -> \"default\" (コレクション名),\n" <>
  "  ForceReindex -> False\n" <>
  "Privacy > 0.5 のファイルは $pdfIndexBaseDir に、\n" <>
  "それ以外は $pdfIndexAttachDir にインデックスを保存。";

pdfIndexDirectory::usage =
  "pdfIndexDirectory[dirPath, opts] はディレクトリ内の全PDFを一括インデックスする。\n" <>
  "オプション: pdfIndex と同じ + FilePattern -> \"*.pdf\"";

pdfIndexURL::usage =
  "pdfIndexURL[url, opts] はURLからPDFをダウンロードしてインデックスする。";

pdfReindex::usage =
  "pdfReindex[collection] はコレクション内の全ドキュメントのLLM要約・embedding を再生成する。";

(* ---- 検索 ---- *)
pdfSearch::usage =
  "pdfSearch[query, n, opts] はハイブリッド検索 (embedding + keyword) で上位n件を返す。\n" <>
  "オプション: Collection -> All, MaxItems -> 20, MinPrivacy/MaxPrivacy";

pdfSearchForLLM::usage =
  "pdfSearchForLLM[query, opts] は検索結果をLLMプロンプト用テキストに変換する。\n" <>
  "戻り値: <|\"public\" -> <|\"prompt\"->..., \"count\"->n|>,\n" <>
  "          \"private\" -> <|\"prompt\"->..., \"count\"->m|>|>\n" <>
  "オプション: MaxItems, Collection, IncludeFullText";

pdfAskLLM::usage =
  "pdfAskLLM[question, opts] はPDFインデックスを検索し、\n" <>
  "公開分はクラウドLLM、秘密分は $ClaudePrivateModel に問い合わせる。\n" <>
  "オプション: Collection, MaxItems, IncludeFullText\n" <>
  "例: pdfAskLLM[\"reversible computing のゲート構成は?\"]";

(* ---- ロード・管理 ---- *)
pdfLoadIndex::usage =
  "pdfLoadIndex[collection] はコレクションのインデックスをロードし PDFIndexObject を返す。\n" <>
  "pdfLoadIndex[] は全コレクションをロードする。";

pdfListCollections::usage =
  "pdfListCollections[] は利用可能なコレクション一覧を返す。";

pdfListDocs::usage =
  "pdfListDocs[collection] はコレクション内のドキュメント一覧を Dataset で返す。";

pdfRemoveDoc::usage =
  "pdfRemoveDoc[docId, collection] はドキュメントをインデックスから削除する。";

pdfStatus::usage =
  "pdfStatus[] は現在のインデクシング状態を表示する。";

pdfPreflightCheck::usage =
  "pdfPreflightCheck[] は PDF 抽出・LLM・Embedding の動作確認を行う。";

pdfSearchUI::usage =
  "pdfSearchUI[query, n] はインタラクティブな検索結果を表示する。\n" <>
  "各結果に [全文] [前後] [質問] ボタンを表示し、\n" <>
  "  [全文] チャンクの全テキストをノートブックに出力\n" <>
  "  [前後] 前後のチャンクも含めたコンテキストを表示\n" <>
  "  [質問] そのチャンクを元に ClaudeQuery で質問\n" <>
  "オプション: Collection -> \"default\"";

pdfGetChunk::usage =
  "pdfGetChunk[chunkIndex, collection] はインデックス番号のチャンク全文を返す。\n" <>
  "pdfGetChunk[{from, to}, collection] は範囲のチャンクを連結して返す。";

pdfShowPage::usage =
  "pdfShowPage[pageNum, collection] はPDFの指定ページを画像としてノートブックに表示する。\n" <>
  "pdfShowPage[pageNum, collection, \"file\"] は画像ファイルパスを返す。\n" <>
  "例: pdfShowPage[124]";

pdfFindPage::usage =
  "pdfFindPage[query, collection] はクエリにマッチするPDFページ番号を推定して返す。\n" <>
  "チャンク位置とPDFメタデータからページ番号を計算する。";

(* ---- デバッグ ---- *)
$pdfIndexDebug::usage = "$pdfIndexDebug = True でデバッグ出力を有効にする。";
$pdfIndexDebug = False;

(* Python 実行パス: パッケージロード時に検出 *)
$pdfPythonPath = Quiet @ Check[
  Module[{path},
    path = ExternalEvaluate["Python", "import sys; sys.executable"];
    If[StringQ[path] && FileExistsQ[path], path, "python"]],
  "python"];

EndPackage[];

(* === Dependencies === *)
Get["localInit.wl"];

(* === Implementation === *)
Begin["PDFIndex`Private`"];

(* ============================================================ *)
(* 初期化・定数                                                  *)
(* ============================================================ *)

(* ベースディレクトリ: プライベートPDF用 *)
If[!StringQ[PDFIndex`$pdfIndexBaseDir],
  PDFIndex`$pdfIndexBaseDir =
    FileNameJoin[{Global`$packageDirectory, "pdfindex_private"}]];

(* アタッチメントディレクトリ: クラウドLLM処理可能 *)
If[!StringQ[PDFIndex`$pdfIndexAttachDir],
  PDFIndex`$pdfIndexAttachDir =
    FileNameJoin[{Global`$packageDirectory, "claude_attachments"}]];

(* インデクシング状態管理 *)
$pdfIndexTaskStatus = <|"state" -> "idle"|>;
$pdfIndexAsyncContext = <||>;

(* インデックスキャッシュ *)
$pdfIndexCache = <||>;

(* チャンクサイズ定数 *)
$chunkMaxChars = 2000;   (* 1チャンクの最大文字数 *)
$chunkOverlap = 200;     (* チャンク間のオーバーラップ文字数 *)
$summaryMaxChars = 150;  (* LLM要約の最大文字数 *)

(* ============================================================ *)
(* PDFIndexObject アクセサ                                       *)
(* ============================================================ *)

(idx_PDFIndex`PDFIndexObject)[key_String] := idx[[1]][key];

Format[PDFIndex`PDFIndexObject[data_Association]] :=
  Row[{"PDFIndexObject[\[LeftGuillemet]",
    data["collection"], ", ",
    data["docCount"], " docs, ",
    data["chunkCount"], " chunks\[RightGuillemet]]"}];

(* ============================================================ *)
(* ディレクトリ管理                                              *)
(* ============================================================ *)

(* コレクション別インデックスディレクトリ *)
iCollectionDir[collection_String, "private"] :=
  Module[{dir},
    dir = FileNameJoin[{PDFIndex`$pdfIndexBaseDir, collection}];
    If[!DirectoryQ[dir], Quiet[CreateDirectory[dir, CreateIntermediateDirectories -> True]]];
    dir];

iCollectionDir[collection_String, "public"] :=
  Module[{dir},
    dir = FileNameJoin[{PDFIndex`$pdfIndexAttachDir, "pdfindex", collection}];
    If[!DirectoryQ[dir], Quiet[CreateDirectory[dir, CreateIntermediateDirectories -> True]]];
    dir];

(* ドキュメントIDの生成: SHA256 先頭16桁 *)
iDocId[pdfPath_String] := Module[{hashVal},
  hashVal = If[iIsURL[pdfPath],
    Hash[pdfPath, "SHA256"],
    Quiet @ Check[FileHash[pdfPath, "SHA256"], Hash[pdfPath, "SHA256"]]];
  IntegerString[hashVal, 16, 16]
];

iIsURL[s_String] := StringMatchQ[s, ("http://" | "https://") ~~ __];
iIsURL[_] := False;

(* ============================================================ *)
(* PDF テキスト抽出 (Python/PyMuPDF)                             *)
(* ============================================================ *)

$pythonPDFExtractCode = "
import sys, json, os

def extract_pdf(pdf_path, max_pages=None):
    \"\"\"Extract text and metadata from PDF using PyMuPDF (fitz).\"\"\"
    try:
        import fitz  # PyMuPDF
    except ImportError:
        # Fallback: try pdfplumber
        try:
            import pdfplumber
            return extract_pdf_pdfplumber(pdf_path, max_pages)
        except ImportError:
            return {'error': 'Neither PyMuPDF nor pdfplumber is installed'}

    try:
        doc = fitz.open(pdf_path)
        metadata = {
            'title': doc.metadata.get('title', '') or '',
            'author': doc.metadata.get('author', '') or '',
            'subject': doc.metadata.get('subject', '') or '',
            'creator': doc.metadata.get('creator', '') or '',
            'producer': doc.metadata.get('producer', '') or '',
            'pageCount': doc.page_count,
            'creationDate': doc.metadata.get('creationDate', '') or '',
            'modDate': doc.metadata.get('modDate', '') or '',
        }
        pages = []
        n = doc.page_count if max_pages is None else min(doc.page_count, max_pages)
        for i in range(n):
            page = doc[i]
            text = page.get_text('text')
            pages.append({
                'pageNum': i + 1,
                'text': text,
                'charCount': len(text)
            })
        doc.close()
        return {'metadata': metadata, 'pages': pages}
    except Exception as e:
        return {'error': str(e)}

def extract_pdf_pdfplumber(pdf_path, max_pages=None):
    import pdfplumber
    try:
        pdf = pdfplumber.open(pdf_path)
        metadata = {
            'title': pdf.metadata.get('Title', '') or '',
            'author': pdf.metadata.get('Author', '') or '',
            'subject': '',
            'creator': pdf.metadata.get('Creator', '') or '',
            'producer': pdf.metadata.get('Producer', '') or '',
            'pageCount': len(pdf.pages),
            'creationDate': '',
            'modDate': '',
        }
        pages = []
        n = len(pdf.pages) if max_pages is None else min(len(pdf.pages), max_pages)
        for i in range(n):
            text = pdf.pages[i].extract_text() or ''
            pages.append({
                'pageNum': i + 1,
                'text': text,
                'charCount': len(text)
            })
        pdf.close()
        return {'metadata': metadata, 'pages': pages}
    except Exception as e:
        return {'error': str(e)}
";

iPDFExtract[pdfPath_String, maxPages_:None] := Module[
  {escapedPath, maxPagesStr, pyCode, outJsonFile, result, json},
  (* Windows パスのバックスラッシュを安全にエスケープ *)
  escapedPath = StringReplace[pdfPath, "\\" -> "/"];
  maxPagesStr = If[IntegerQ[maxPages], ToString[maxPages], "None"];
  (* 出力先の一時JSONファイル *)
  outJsonFile = FileNameJoin[{$TemporaryDirectory,
    "pdfidx_out_" <> IntegerString[Round[AbsoluteTime[] * 1000]] <> ".json"}];
  (* Python コード: 関数定義 + 呼び出し + JSON出力 *)
  pyCode = $pythonPDFExtractCode <> "\n" <>
    "import json\n" <>
    "_pdfidx_result = extract_pdf(r'" <> escapedPath <> "', " <> maxPagesStr <> ")\n" <>
    "with open(r'" <> StringReplace[outJsonFile, "\\" -> "/"] <>
      "', 'w', encoding='utf-8') as _f:\n" <>
    "    json.dump(_pdfidx_result, _f, ensure_ascii=False)\n" <>
    "'done'\n";
  (* ExternalEvaluate でPython実行 *)
  result = Quiet @ Check[ExternalEvaluate["Python", pyCode], $Failed];
  (* JSON ファイルから結果を読み込み *)
  If[FileExistsQ[outJsonFile],
    json = Quiet @ Check[
      Developer`ReadRawJSONFile[outJsonFile],
      Quiet @ Check[Import[outJsonFile, "RawJSON"], $Failed]];
    Quiet[DeleteFile[outJsonFile]];
    If[AssociationQ[json],
      If[KeyExistsQ[json, "error"],
        Print["  \[WarningSign] PDF\:62bd\:51fa\:30a8\:30e9\:30fc: " <> json["error"]];
        Return[iPDFExtractWL[pdfPath, maxPages]]];
      Return[json]]];
  (* Python 実行失敗 or JSON なし → WL フォールバック *)
  If[TrueQ[PDFIndex`$pdfIndexDebug],
    Print["  [iPDFExtract] Python\:7d50\:679c: " <> ToString[Short[result]]]];
  iPDFExtractWL[pdfPath, maxPages]
];

(* Mathematica ネイティブ PDF Import フォールバック *)
iPDFExtractWL[pdfPath_String, maxPages_:None] := Module[
  {pageCount, n, allText, pageTexts, pages, title, author},
  If[TrueQ[PDFIndex`$pdfIndexDebug], Print["  [fallback] WL Import: " <> pdfPath]];
  pageCount = Quiet @ Check[
    Import[pdfPath, {"PDF", "PageCount"}], 0];
  If[pageCount === 0 || !IntegerQ[pageCount],
    (* PageCount 取得失敗時は全テキストを1チャンクとして返す *)
    allText = Quiet @ Check[Import[pdfPath, "Plaintext"], $Failed];
    If[StringQ[allText],
      Return[<|"metadata" -> <|"title" -> FileBaseName[pdfPath],
        "author" -> "", "subject" -> "", "creator" -> "", "producer" -> "",
        "pageCount" -> 1, "creationDate" -> "", "modDate" -> ""|>,
        "pages" -> {<|"pageNum" -> 1, "text" -> allText,
          "charCount" -> StringLength[allText]|>}|>],
      Return[<|"error" -> "PDF Import \:306b\:5931\:6557"|>]]];
  n = If[IntegerQ[maxPages], Min[maxPages, pageCount], pageCount];
  (* ページごとのテキスト抽出: 複数の方法を試す *)
  pageTexts = Quiet @ Check[
    (* 方法1: {"PDF", "Plaintext"} はページごとのリストを返す *)
    Module[{raw = Import[pdfPath, {"PDF", "Plaintext"}]},
      If[ListQ[raw], Take[raw, UpTo[n]],
        If[StringQ[raw], {raw}, {}]]],
    {}];
  If[Length[pageTexts] === 0,
    (* 方法2: "Plaintext" で全テキストを取得し1チャンクに *)
    allText = Quiet @ Check[Import[pdfPath, "Plaintext"], ""];
    pageTexts = If[StringQ[allText], {allText}, {}]];
  pages = MapIndexed[
    <|"pageNum" -> #2[[1]],
      "text" -> If[StringQ[#1], #1, ""],
      "charCount" -> If[StringQ[#1], StringLength[#1], 0]|> &,
    pageTexts];
  title = Quiet @ Check[
    Module[{t = Import[pdfPath, {"PDF", "Title"}]},
      If[StringQ[t], t, ""]],
    ""];
  author = Quiet @ Check[
    Module[{a = Import[pdfPath, {"PDF", "Author"}]},
      If[StringQ[a], a, ""]],
    ""];
  <|"metadata" -> <|
      "title" -> title,
      "author" -> author,
      "subject" -> "",
      "creator" -> "",
      "producer" -> "",
      "pageCount" -> pageCount,
      "creationDate" -> "",
      "modDate" -> ""|>,
    "pages" -> pages|>
];

(* ============================================================ *)
(* 目次 (TOC) 抽出                                               *)
(* ============================================================ *)

(* PyMuPDF で目次を抽出: [{level, title, page}, ...] *)
iExtractTOC[pdfPath_String] := Module[
  {escapedPath, outJsonFile, pyCode, result, json},
  escapedPath = StringReplace[pdfPath, "\\" -> "/"];
  outJsonFile = FileNameJoin[{$TemporaryDirectory,
    "pdftoc_" <> IntegerString[Round[AbsoluteTime[] * 1000]] <> ".json"}];
  pyCode = "
import json
try:
    import fitz
    doc = fitz.open(r'" <> escapedPath <> "')
    toc = doc.get_toc()
    result = [{'level': t[0], 'title': t[1], 'page': t[2]} for t in toc]
    doc.close()
    with open(r'" <> StringReplace[outJsonFile, "\\" -> "/"] <>
      "', 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False)
    'done'
except Exception as e:
    str(e)
";
  result = Quiet @ Check[ExternalEvaluate["Python", pyCode], $Failed];
  If[FileExistsQ[outJsonFile],
    json = Quiet @ Check[Developer`ReadRawJSONFile[outJsonFile], $Failed];
    Quiet[DeleteFile[outJsonFile]];
    If[ListQ[json], json, {}],
    {}]
];

(* TOCからクエリタームにマッチするセクションのページ範囲を特定 *)
(* 戻り値: <|"section"->タイトル, "startPage"->n, "endPage"->m|> or None *)
iTOCFindPageRange[toc_List, query_String] := Module[
  {terms, bestMatch = None, bestScore = 0, bestIdx = 0},
  If[Length[toc] === 0, Return[None]];
  terms = iSplitQueryTerms[query];
  If[Length[terms] === 0, Return[None]];
  (* 各TOCエントリをスコアリング *)
  Do[
    Module[{entry = toc[[i]], title, level, page, sc = 0},
      title = Lookup[entry, "title", ""];
      level = Lookup[entry, "level", 1];
      page = Lookup[entry, "page", 0];
      If[!StringQ[title] || !IntegerQ[page] || page <= 0, Continue[]];
      Do[
        If[StringContainsQ[title, t, IgnoreCase -> True],
          sc += StringLength[t] * 5],
        {t, terms}];
      If[sc > 0,
        sc += Max[0, (4 - level) * 5];
        If[StringLength[title] < 30, sc += 3]];
      If[sc > bestScore,
        bestScore = sc; bestIdx = i; bestMatch = entry]],
    {i, Length[toc]}];
  If[bestMatch === None, Return[None]];

  (* マッチしたエントリのページ範囲を計算。
     子エントリにマッチした場合、1つ上の親エントリの範囲を使う。
     これにより「情報工学科 教育目的」(p.125-127) ではなく
     「③情報工学科」(p.125-131) の全範囲がカバーされる。
     ただし最上位(level 1)までは登らない。 *)
  Module[{useIdx, useLevel, startPage, endPage, matchLevel, j},
    matchLevel = Lookup[bestMatch, "level", 1];
    useIdx = bestIdx;
    useLevel = matchLevel;
    (* 1段だけ親へ遡上 (level >= 3 の子エントリのみ。level 1 には登らない) *)
    If[matchLevel >= 3,
      j = bestIdx - 1;
      While[j >= 1,
        Module[{prevLevel = Lookup[toc[[j]], "level", 99]},
          If[prevLevel < matchLevel && prevLevel >= 2,
            useIdx = j;
            useLevel = prevLevel;
            Break[]]];
        j--]];
    startPage = Lookup[toc[[useIdx]], "page", 1];
    (* 次の同レベル以上のエントリを探す → そのページ-1 が終了ページ *)
    endPage = startPage + 30;
    j = useIdx + 1;
    While[j <= Length[toc],
      If[Lookup[toc[[j]], "level", 99] <= useLevel,
        endPage = Lookup[toc[[j]], "page", endPage] - 1;
        Break[]];
      j++];
    <|"section" -> Lookup[toc[[useIdx]], "title", ""],
      "startPage" -> startPage,
      "endPage" -> endPage|>]
];

(* ============================================================ *)
(* ページ分類・ビジョン解析・カタログ構築                        *)
(* ============================================================ *)

(* テキスト抽出結果から表・図ページを検出するヒューリスティクス *)
iIsTableOrFigurePage[pageText_String] := Module[
  {lines, shortLines, totalLines, codePattern, frontBackCount},
  If[StringLength[pageText] < 50, Return[False]];
  lines = Select[StringSplit[pageText, "\n"], StringLength[StringTrim[#]] > 0 &];
  totalLines = Length[lines];
  If[totalLines < 3, Return[False]];
  (* 短い行 (15文字未満) が60%以上 → 表のセルがバラバラ *)
  shortLines = Count[lines, l_ /; StringLength[StringTrim[l]] < 15];
  If[shortLines > totalLines * 0.6, Return[True]];
  (* "前" "後" パターン (配当表) *)
  frontBackCount = StringCount[pageText, "\:524d"] + StringCount[pageText, "\:5f8c"];
  If[frontBackCount > 6, Return[True]];
  (* 科目コードパターン (T06xxx, TI6xxx) *)
  If[Length[StringCases[pageText,
      RegularExpression["[A-Z]\\d{2}[A-Z]{2,3}\\d{3}"]]] > 3, Return[True]];
  (* 数値が多い行が連続 → 統計表 *)
  False
];

(* LLMビジョン解析の代わりに PyMuPDF の構造化抽出を使用。
   LLM/API呼び出しなし。ExternalEvaluate で Python を実行。
   表の検出は get_text("blocks") の位置情報から行う。 *)

$pythonStructuredExtractCode = "
import fitz, json, re, sys, os, warnings
warnings.filterwarnings('ignore')

def analyze_page(pdf_path, page_num):
    '''Extract structured content from a PDF page using PyMuPDF.
    Returns: {paragraphs, tables, figures, key_entities, page_type}'''
    # 警告メッセージを抑制
    old_stderr = sys.stderr
    sys.stderr = open(os.devnull, 'w')
    try:
        return _analyze_page_impl(pdf_path, page_num)
    finally:
        sys.stderr.close()
        sys.stderr = old_stderr

def _analyze_page_impl(pdf_path, page_num):
    doc = fitz.open(pdf_path)
    page = doc[page_num - 1]
    page_height = page.rect.height

    # テキストブロック取得 (位置情報付き)
    blocks = page.get_text('blocks')
    text_blocks = [b for b in blocks if b[6] == 0]
    img_blocks = [b for b in blocks if b[6] == 1]

    # === 表検出 ===
    tables_data = []

    # 方法1: find_tables() (PyMuPDF 1.23+)
    try:
        tab_finder = page.find_tables()
        for tab in tab_finder.tables:
            rows = tab.extract()
            if len(rows) < 2:
                continue
            headers = [str(c) if c else '' for c in rows[0]]
            data_rows = [[str(c) if c else '' for c in r] for r in rows[1:]]
            tab_rect = tab.bbox
            caption = _find_caption_above(text_blocks, tab_rect[1])
            continues_from = (tab_rect[1] < 80)
            continues_to = (tab_rect[3] > page_height - 60)
            tables_data.append({
                'caption': caption,
                'headers': headers,
                'rows': data_rows,
                'notes': '',
                'continues_from_previous': continues_from,
                'continues_to_next': continues_to
            })
    except:
        pass

    # 方法2: テキストブロック解析によるフォールバック表検出
    if len(tables_data) == 0:
        tables_data = _detect_tables_from_blocks(text_blocks, page_height, page_num)

    # === 段落テキスト ===
    # 表に使われたブロックの Y 範囲を除外
    table_y_ranges = []
    for td in tables_data:
        # 表データからY範囲を推定 (近似)
        pass  # find_tables() の場合は bbox があるが、フォールバックの場合はない

    paragraphs = []
    for tb in text_blocks:
        text = tb[4].strip()
        if len(text) > 20:
            lines = text.split('\\n')
            short_ratio = sum(1 for l in lines if 0 < len(l.strip()) < 10) / max(len(lines), 1)
            if short_ratio < 0.5:
                paragraphs.append(text)

    # === 図の検出 ===
    figures = []
    for ib in img_blocks:
        fig_caption = ''
        for tb in text_blocks:
            if abs(tb[1] - ib[3]) < 30 or abs(ib[1] - tb[3]) < 30:
                cap_text = tb[4].strip()
                if any(k in cap_text for k in ['図', 'マップ', 'Figure', 'Chart', 'カリキュラム']):
                    fig_caption = cap_text
                    break
        if fig_caption or (ib[2]-ib[0]) > 200:
            figures.append({
                'caption': fig_caption or '(図)',
                'description': f'ページ{page_num}の図 ({int(ib[2]-ib[0])}x{int(ib[3]-ib[1])}px)'
            })

    # === ページタイプ判定 ===
    page_type = 'text'
    if len(tables_data) > 0:
        page_type = 'table' if len(paragraphs) < 3 else 'mixed'
    elif len(figures) > 0 and len(paragraphs) < 3:
        page_type = 'figure'

    # === 主要エンティティ抽出 ===
    full_text = page.get_text('text')
    entities = list(set(re.findall(r'[A-Z]\\d{2}[A-Z]{2,3}\\d{3}', full_text)))
    entities += list(set(re.findall(r'[\\u4e00-\\u9fff]{2,8}[\\u5b66\\u79d1\\u5de5\\u5b66]', full_text)))

    doc.close()
    return {
        'page_type': page_type,
        'paragraphs': paragraphs,
        'tables': tables_data,
        'figures': figures,
        'key_entities': entities[:20]
    }

def _find_caption_above(text_blocks, table_top_y):
    '''表の上にあるテキストブロックからキャプションを探す'''
    best = ''
    best_dist = 999
    for tb in text_blocks:
        dist = table_top_y - tb[3]  # 表上端 - ブロック下端
        if 0 < dist < 50 and dist < best_dist:
            best = tb[4].strip().split('\\n')[0]  # 最初の行のみ
            best_dist = dist
    return best

def _detect_tables_from_blocks(text_blocks, page_height, page_num):
    '''テキストブロックのパターンから表構造を検出するフォールバック。
    科目コード (T06xxx, TI6xxx) を含むブロック群を表として認識。'''
    tables = []
    table_lines = []
    code_pattern = re.compile(r'[A-Z]\\d{2}[A-Z]{2,3}\\d{3}')

    # 全テキストを行に分割して科目コードパターンを検出
    all_text = '\\n'.join(tb[4] for tb in text_blocks)
    lines = all_text.split('\\n')

    in_table = False
    table_start_y = 0
    table_end_y = 0
    caption = ''

    for i, line in enumerate(lines):
        stripped = line.strip()
        if code_pattern.search(stripped):
            if not in_table:
                in_table = True
                table_start_y = i
                # 前の行からキャプションを推測
                for j in range(max(0, i-3), i):
                    prev = lines[j].strip()
                    if len(prev) > 5 and not code_pattern.search(prev):
                        caption = prev
            table_lines.append(stripped)
            table_end_y = i
        elif in_table and len(stripped) < 5:
            # 短い行 (区切り) はスキップ
            continue
        elif in_table:
            # 表終了
            if len(table_lines) >= 3:
                headers, rows = _parse_table_lines(table_lines)
                continues_from = (table_start_y < 3)
                continues_to = (table_end_y > len(lines) - 5)
                # 備考を探す
                notes = ''
                for j in range(table_end_y + 1, min(table_end_y + 10, len(lines))):
                    note_line = lines[j].strip()
                    if note_line.startswith(('備考', '※', '注', '*', '１．', '1.')):
                        notes = '\\n'.join(l.strip() for l in lines[j:min(j+15, len(lines))] if l.strip())
                        break
                tables.append({
                    'caption': caption,
                    'headers': headers,
                    'rows': rows,
                    'notes': notes,
                    'continues_from_previous': continues_from,
                    'continues_to_next': continues_to
                })
            table_lines = []
            in_table = False
            caption = ''

    # 最後の表
    if in_table and len(table_lines) >= 3:
        headers, rows = _parse_table_lines(table_lines)
        tables.append({
            'caption': caption,
            'headers': headers,
            'rows': rows,
            'notes': '',
            'continues_from_previous': (table_start_y < 3),
            'continues_to_next': True  # ページ末尾まで続く
        })

    return tables

def _parse_table_lines(lines):
    '''科目コードを含む行群からヘッダーと行を推測'''
    # 各行をタブ/複数スペースで分割
    rows = []
    for line in lines:
        cells = re.split(r'\\t|\\s{2,}', line.strip())
        cells = [c.strip() for c in cells if c.strip()]
        if cells:
            rows.append(cells)
    if len(rows) == 0:
        return [], []
    # 最大列数に合わせてパディング
    max_cols = max(len(r) for r in rows)
    rows = [r + [''] * (max_cols - len(r)) for r in rows]
    # ヘッダーは推定 (科目コードを含まない最初の行、または固定)
    headers = ['科目コード', '科目名'] + [f'列{i+3}' for i in range(max_cols - 2)]
    return headers, rows
";

iAnalyzePageWithVision[pdfPath_String, pageNum_Integer] := Module[
  {escapedPath, tempDir, outFile, pyCode, result, json},
  escapedPath = StringReplace[pdfPath, "\\" -> "/"];
  (* Claude Code がアクセスできるローカルディレクトリに出力 *)
  tempDir = If[StringQ[ClaudeCode`$ClaudeWorkingDirectory] &&
               ClaudeCode`$ClaudeWorkingDirectory =!= "",
    ClaudeCode`$ClaudeWorkingDirectory,
    FileNameJoin[{$HomeDirectory, "Claude Working"}]];
  If[!DirectoryQ[tempDir],
    Quiet[CreateDirectory[tempDir, CreateIntermediateDirectories -> True]]];
  outFile = FileNameJoin[{tempDir,
    "pdfstruct_" <> IntegerString[Round[AbsoluteTime[] * 1000]] <> ".json"}];
  pyCode = $pythonStructuredExtractCode <> "\n" <>
    "import json\n" <>
    "_result = analyze_page(r'" <> escapedPath <> "', " <> ToString[pageNum] <> ")\n" <>
    "with open(r'" <> StringReplace[outFile, "\\" -> "/"] <>
    "', 'w', encoding='utf-8') as _f:\n" <>
    "    json.dump(_result, _f, ensure_ascii=False)\n" <>
    "'done'\n";
  result = Quiet @ Check[ExternalEvaluate["Python", pyCode], $Failed];
  If[FileExistsQ[outFile],
    json = Quiet @ Check[
      Developer`ReadRawJSONFile[outFile],
      Quiet @ Check[Import[outFile, "RawJSON"], $Failed]];
    Quiet[DeleteFile[outFile]];
    If[AssociationQ[json], json, $Failed],
    $Failed]
];

(* 連続ページの表をマージ。continues_from_previous/continues_to_next を使用 *)
iMergeSpanningTables[pageResults_List] := Module[
  {allTables = {}, currentMerge = None},
  Do[
    Module[{pg, tables},
      pg = Lookup[pageResult, "pageNum", 0];
      tables = Lookup[pageResult, "tables", {}];
      If[!ListQ[tables], Continue[]];
      Do[
        If[TrueQ[Lookup[t, "continues_from_previous", False]] &&
           currentMerge =!= None,
          (* 前のページの表に行を追加 *)
          currentMerge = Join[currentMerge, <|
            "rows" -> Join[Lookup[currentMerge, "rows", {}],
              Lookup[t, "rows", {}]],
            "endPage" -> pg,
            "notes" -> If[StringQ[Lookup[t, "notes", ""]] && t["notes"] =!= "",
              Lookup[currentMerge, "notes", ""] <> "\n" <> t["notes"],
              Lookup[currentMerge, "notes", ""]]|>],
          (* 新しい表を開始 (前の表があれば確定) *)
          If[currentMerge =!= None,
            AppendTo[allTables, currentMerge]];
          currentMerge = <|
            "caption" -> Lookup[t, "caption", ""],
            "startPage" -> pg, "endPage" -> pg,
            "headers" -> Lookup[t, "headers", {}],
            "rows" -> Lookup[t, "rows", {}],
            "notes" -> Lookup[t, "notes", ""],
            "continues_to_next" -> TrueQ[Lookup[t, "continues_to_next", False]]
          |>];
        (* 次ページに続かない単独表は即確定 *)
        If[!TrueQ[Lookup[t, "continues_to_next", False]] &&
           !TrueQ[Lookup[t, "continues_from_previous", False]],
          If[currentMerge =!= None, AppendTo[allTables, currentMerge]];
          currentMerge = None],
      {t, tables}]],
  {pageResult, pageResults}];
  If[currentMerge =!= None, AppendTo[allTables, currentMerge]];
  allTables
];

(* カタログ構築: 表・図・セクションの軽量索引。検索のエントリポイント *)
iBuildCatalog[pageResults_List, mergedTables_List, toc_List] := Module[
  {tableCatalog, figureCatalog, sectionCatalog},
  (* 表カタログ: キャプション + 列ヘッダ + 主要エンティティ *)
  tableCatalog = MapIndexed[
    <|"id" -> "t" <> ToString[#2[[1]]],
      "caption" -> Lookup[#1, "caption", ""],
      "startPage" -> #1["startPage"],
      "endPage" -> #1["endPage"],
      "headers" -> Lookup[#1, "headers", {}],
      "rowCount" -> Length[Lookup[#1, "rows", {}]],
      "notes" -> Lookup[#1, "notes", ""],
      (* 検索用サマリー: キャプション + ヘッダ + 備考 *)
      "searchText" -> StringJoin[
        Lookup[#1, "caption", ""], " ",
        StringRiffle[Lookup[#1, "headers", {}], " "], " ",
        Lookup[#1, "notes", ""]]
    |> &,
    mergedTables];
  (* 図カタログ *)
  figureCatalog = Flatten[
    Function[{pr},
      MapIndexed[
        <|"id" -> "f" <> ToString[pr["pageNum"]] <> "_" <> ToString[#2[[1]]],
          "caption" -> Lookup[#1, "caption", ""],
          "page" -> pr["pageNum"],
          "description" -> Lookup[#1, "description", ""],
          "searchText" -> Lookup[#1, "caption", ""] <> " " <>
            Lookup[#1, "description", ""]
        |> &,
        Lookup[pr, "figures", {}]] /;
      ListQ[Lookup[pr, "figures", {}]] && Length[pr["figures"]] > 0
    ] /@ pageResults];
  (* セクションカタログ (TOC ベース) *)
  sectionCatalog = If[ListQ[toc],
    Select[
      (<|"title" -> Lookup[#, "title", ""],
         "page" -> Lookup[#, "page", 0],
         "level" -> Lookup[#, "level", 1]|> &) /@ toc,
      #["page"] > 0 &],
    {}];
  <|"tables" -> tableCatalog,
    "figures" -> figureCatalog,
    "sections" -> sectionCatalog|>
];

(* 構造化データからチャンクを生成。
   表は1つの表 = 1チャンク (Markdown表形式)。
   段落は従来の文字数ベースチャンキング。 *)
iChunkFromStructured[pageResults_List, mergedTables_List] := Module[
  {chunks = {}, tablePages, chunkIdx = 0},
  (* マージ済み表のページ範囲を記録 *)
  tablePages = Flatten[
    Range[#["startPage"], #["endPage"]] & /@ mergedTables];
  (* 表チャンク: 各マージ済み表を1チャンクに *)
  Do[
    Module[{tableText, headers, rows},
      headers = Lookup[tbl, "headers", {}];
      rows = Lookup[tbl, "rows", {}];
      tableText = Lookup[tbl, "caption", ""] <> "\n\n";
      (* Markdown 表形式 *)
      If[Length[headers] > 0,
        tableText = tableText <>
          "| " <> StringRiffle[headers, " | "] <> " |\n" <>
          "| " <> StringRiffle[ConstantArray["---", Length[headers]], " | "] <> " |\n"];
      Do[
        If[ListQ[row],
          tableText = tableText <>
            "| " <> StringRiffle[ToString /@ row, " | "] <> " |\n"],
        {row, rows}];
      If[StringQ[Lookup[tbl, "notes", ""]] && tbl["notes"] =!= "",
        tableText = tableText <> "\n" <> tbl["notes"]];
      chunkIdx++;
      AppendTo[chunks,
        <|"pageNum" -> tbl["startPage"],
          "endPageNum" -> tbl["endPage"],
          "chunkIdx" -> chunkIdx,
          "isTable" -> True,
          "tableCaption" -> Lookup[tbl, "caption", ""],
          "text" -> tableText,
          "charCount" -> StringLength[tableText]|>]],
    {tbl, mergedTables}];
  (* 段落チャンク: 表ページ以外のテキスト *)
  Do[
    Module[{pg = pr["pageNum"], paras, paraText},
      If[MemberQ[tablePages, pg], Continue[]];
      paras = Lookup[pr, "paragraphs", {}];
      If[!ListQ[paras] || Length[paras] === 0,
        (* ビジョン解析なしのページ: rawText を使用 *)
        paras = {Lookup[pr, "rawText", ""]}];
      paraText = StringTrim[StringJoin[Riffle[
        Select[paras, StringQ[#] && StringLength[#] > 0 &], "\n\n"]]];
      If[StringLength[paraText] > 0,
        (* 長い段落テキストはさらにチャンク分割 *)
        Module[{subChunks},
          subChunks = iChunkText[paraText, pg];
          Do[
            chunkIdx++;
            AppendTo[chunks,
              Append[sc, "chunkIdx" -> chunkIdx]],
            {sc, subChunks}]]]],
    {pr, pageResults}];
  (* 図チャンク: 図の説明テキスト *)
  Do[
    Module[{pg = pr["pageNum"], figs},
      figs = Lookup[pr, "figures", {}];
      If[!ListQ[figs], Continue[]];
      Do[
        If[AssociationQ[fig] &&
           StringLength[Lookup[fig, "description", ""]] > 10,
          chunkIdx++;
          AppendTo[chunks,
            <|"pageNum" -> pg,
              "chunkIdx" -> chunkIdx,
              "isFigure" -> True,
              "figureCaption" -> Lookup[fig, "caption", ""],
              "text" -> "[" <> Lookup[fig, "caption", "\:56f3"] <> "] " <>
                Lookup[fig, "description", ""],
              "charCount" -> StringLength[Lookup[fig, "description", ""]]|>]],
        {fig, figs}]],
    {pr, pageResults}];
  (* globalIdx を振り直す *)
  MapIndexed[Append[#1, "globalIdx" -> #2[[1]]] &, chunks]
];

(* ============================================================ *)
(* チャンキング (従来方式: ビジョン不使用ページ用)                *)
(* ============================================================ *)

(* ページ単位のテキストをセクション/段落単位にチャンク分割する *)
iChunkText[text_String, pageNum_Integer, maxChars_:Automatic, overlap_:Automatic] :=
  Module[{mc, ol, chunks, lines, buf, bufLen, chunk},
    mc = If[IntegerQ[maxChars], maxChars, $chunkMaxChars];
    ol = If[IntegerQ[overlap], overlap, $chunkOverlap];
    (* 短いページはそのまま1チャンク *)
    If[StringLength[text] <= mc,
      Return[{<|"pageNum" -> pageNum, "chunkIdx" -> 1,
               "text" -> StringTrim[text],
               "charCount" -> StringLength[text]|>}]];
    (* 段落/行単位で分割 *)
    lines = StringSplit[text, "\n"];
    chunks = {};
    buf = "";
    bufLen = 0;
    Do[
      If[bufLen + StringLength[line] + 1 > mc && bufLen > 0,
        (* バッファをチャンクとして保存 *)
        AppendTo[chunks,
          <|"pageNum" -> pageNum,
            "chunkIdx" -> Length[chunks] + 1,
            "text" -> StringTrim[buf],
            "charCount" -> StringLength[StringTrim[buf]]|>];
        (* オーバーラップ: 末尾の一部を次のバッファに引き継ぐ *)
        buf = If[ol > 0 && StringLength[buf] > ol,
          StringTake[buf, -ol] <> "\n" <> line,
          line];
        bufLen = StringLength[buf],
        (* バッファに追加 *)
        buf = If[buf === "", line, buf <> "\n" <> line];
        bufLen = StringLength[buf]],
      {line, lines}];
    (* 残りのバッファ *)
    If[StringLength[StringTrim[buf]] > 0,
      AppendTo[chunks,
        <|"pageNum" -> pageNum,
          "chunkIdx" -> Length[chunks] + 1,
          "text" -> StringTrim[buf],
          "charCount" -> StringLength[StringTrim[buf]]|>]];
    chunks
  ];

(* ドキュメント全体をチャンク化 *)
iChunkDocument[extractResult_Association] := Module[{pages, allChunks},
  pages = Lookup[extractResult, "pages", {}];
  If[!ListQ[pages] || Length[pages] === 0, Return[{}]];
  allChunks = Flatten[
    iChunkText[#["text"], #["pageNum"]] & /@ pages, 1];
  (* グローバルなチャンク番号を振り直す *)
  MapIndexed[Append[#1, "globalIdx" -> #2[[1]]] &, allChunks]
];

(* ============================================================ *)
(* LLM ヘルパー: claudecode.wl の ClaudeQuery/ClaudeQueryBg 経由 *)
(* claudecode.wl 修正済み: ClaudeQueryBg も Fallback->False で    *)
(*   Claude Code CLI を使用する (課金なし)。                       *)
(* Fallback -> True を指定しない限り課金APIは使われない。          *)
(* LLMSynthesize 等の直接呼び出しは禁止。                         *)
(* ============================================================ *)

(* クラウド LLM: ClaudeQueryBg (同期) → ClaudeQuery (非同期) の順で試行。
   どちらも Fallback -> False (デフォルト) で Claude Code CLI 経由。課金なし。
   ClaudeQueryBg: ScheduledTask/SocketListen 内でも安全 (RunProcess 使用)。
   ClaudeQuery: トップレベルでのみ安全 (StartProcess + ScheduledTask 使用)。 *)
(* model 引数なし: デフォルトモデル (Opus) *)
iQueryCloudLLM[prompt_String] := iQueryCloudLLM[prompt, ""];

(* model 引数あり: Block で $ClaudeModel を一時的に切り替え *)
iQueryCloudLLM[prompt_String, model_String] := Module[{result},
  Block[{ClaudeCode`$ClaudeModel =
      If[model =!= "", model, ClaudeCode`$ClaudeModel]},
    (* ClaudeQueryBg: 同期・どのコンテキストでも安全 *)
    If[Length[Names["ClaudeCode`ClaudeQueryBg"]] > 0,
      result = Quiet @ Check[
        ClaudeCode`ClaudeQueryBg[prompt],
        $Failed];
      If[StringQ[result] && result =!= "" && !StringStartsQ[result, "Error"], 
        Return[result]]];
    (* ClaudeQuery: トップレベルでのみ安全 *)
    If[Quiet[Check[$CurrentTask, None]] === None &&
       Quiet[Check[$ScheduledTask, None]] === None &&
       Length[Names["ClaudeCode`ClaudeQuery"]] > 0,
      result = Quiet @ Check[
        ClaudeCode`ClaudeQuery[prompt],
        $Failed];
      If[StringQ[result] && result =!= "", Return[result]]];
    ""]
];

(* ローカル LLM ($ClaudePrivateModel): maildb.wl 経由 → ClaudeQuery フォールバック *)
iQueryLocalLLM[prompt_String] := Module[{result},
  (* maildb.wl が利用可能ならそちらを使う (LM Studio 等) *)
  If[Length[Names["Maildb`Private`iQueryLocalLLM"]] > 0,
    result = Quiet @ Check[Maildb`Private`iQueryLocalLLM[prompt], $Failed];
    If[StringQ[result] && result =!= "", Return[result]]];
  (* maildb なし: ClaudeQuery に Model -> $ClaudePrivateModel を指定 *)
  If[Quiet[Check[$CurrentTask, None]] === None &&
     Quiet[Check[$ScheduledTask, None]] === None &&
     ListQ[ClaudeCode`$ClaudePrivateModel] &&
     Length[ClaudeCode`$ClaudePrivateModel] >= 2 &&
     Length[Names["ClaudeCode`ClaudeQuery"]] > 0,
    result = Quiet @ Check[
      ClaudeCode`ClaudeQuery[prompt,
        Model -> ClaudeCode`$ClaudePrivateModel],
      $Failed];
    If[StringQ[result] && result =!= "", Return[result]]];
  ""
];

(* ============================================================ *)
(* Embedding ヘルパー                                            *)
(* Embedding は低コストなため課金API使用を許可。                   *)
(* 優先順: maildb → LLMSynthesize → 空ベクトル                   *)
(* ============================================================ *)

iCreateEmbeddings[texts_List] := Module[{result},
  (* 1. maildb.wl の createEmbeddings を優先使用 *)
  If[Length[Names["Maildb`Private`createEmbeddings"]] > 0,
    result = Quiet @ Check[Maildb`Private`createEmbeddings[texts], $Failed];
    If[ListQ[result] && Length[result] === Length[texts],
      Return[result]]];
  (* 2. LLMSynthesize (課金API) — Embedding は低コストのため許可 *)
  result = Quiet @ Check[
    Map[
      Module[{emb},
        emb = LLMSynthesize[#, LLMEvaluator -> <|"Task" -> "Embedding"|>];
        If[ListQ[emb], emb, {}]] &,
      texts],
    $Failed];
  If[ListQ[result] && Length[result] === Length[texts], result,
    (* 3. 全て失敗 → 空ベクトル *)
    ConstantArray[{}, Length[texts]]]
];

iCreateEmbeddingSession[] :=
  If[Length[Names["Maildb`Private`createEmbeddingSession"]] > 0,
    Maildb`Private`createEmbeddingSession[],
    Null];

(* テキストの安全なエスケープ *)
iDoubleEscape[s_String] :=
  StringReplace[s, {"\\" -> "\\\\", "\"" -> "\\\""}];
iDoubleEscape[_] := "";

(* ============================================================ *)
(* LLM によるチャンク要約・タグ・プライバシー推定                  *)
(* ============================================================ *)

$pdfChunkSummarizePrompt =
  "\:3042\:306a\:305f\:306f\:300cPDF\:6587\:66f8\:30c1\:30e3\:30f3\:30af\:306e\:57cb\:3081\:8fbc\:307f\:7528\:8981\:7d04\:5668\:300d\:3067\:3059\:3002\:691c\:7d22/RAG\:3067\:306e\:518d\:5229\:7528\:3092\:76ee\:7684\:3068\:3057\:3001\n" <>
  "\:30c1\:30e3\:30f3\:30af\:306e\:5185\:5bb9\:3092\:77ed\:304f\:6b63\:78ba\:306b\:307e\:3068\:3081\:3066\:304f\:3060\:3055\:3044\:3002\n\n" <>
  "\:3010\:3084\:308b\:3053\:3068\:3011\n" <>
  "1) 1\:301c3\:6587\:ff08\:5408\:8a08120\:5b57\:4ee5\:5185\:ff09\:3067\:8981\:65e8\:3092\:8ff0\:3079\:308b\:3002\n" <>
  "2) \:56fa\:6709\:540d\:8a5e\:306f\:6b63\:5f0f\:540d\:ff0b\:5225\:540d/\:82f1\:8a9e\:540d/\:7565\:79f0\:3092\:4f75\:8a18\:3002\n" <>
  "3) \:6570\:5b57\:30fb\:5b9a\:7406\:540d\:30fb\:56fa\:6709\:8868\:73fe\:306f\:305d\:306e\:307e\:307e\:6b8b\:3059\:3002\n" <>
  "4) \:82f1\:6587\:306e\:5834\:5408\:306f\:65e5\:672c\:8a9e\:8a33\:3082\:8ffd\:52a0\:3002\n\n" <>
  "\:3010\:51fa\:529b\:5f62\:5f0f\:3011\n" <>
  "SUMMARY: <\:8981\:65e8\:30921\:301c3\:6587>\n" <>
  "ENTITIES: <\:56fa\:6709\:540d\:8a5e\:3092\:30ab\:30f3\:30de\:533a\:5207\:308a>\n" <>
  "TAGS: <\:691c\:7d22\:5f37\:5316\:7528\:306e\:540c\:7fa9\:8a9e\:30fb\:7565\:79f0\:30923\:301c10\:8a9e>\n\n" <>
  "\:3010\:30c1\:30e3\:30f3\:30af\:3011\n";

$pdfDocPrivacyPrompt =
  "\:4ee5\:4e0b\:306e PDF \:6587\:66f8\:306e\:30bf\:30a4\:30c8\:30eb\:3068\:5148\:982d\:30c6\:30ad\:30b9\:30c8\:304b\:3089\:3001\:79d8\:533f\:5ea6(PRIVACY)\:30920.0\:304b\:30891.0\:3067\:63a8\:5b9a\:305b\:3088\:3002\n\n" <>
  "0.0: \:516c\:958b\:8ad6\:6587\:30fb\:30de\:30cb\:30e5\:30a2\:30eb\:30fb\:4e00\:822c\:516c\:958b\:8cc7\:6599\n" <>
  "0.3: \:5b66\:4f1a\:8cc7\:6599\:30fb\:6559\:7a0b\:30fb\:6280\:8853\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\n" <>
  "0.5: \:5b66\:5185\:7528\:8cc7\:6599\:30fb\:8b70\:4e8b\:9332\n" <>
  "0.7: \:500b\:4eba\:60c5\:5831\:3092\:542b\:3080\:6587\:66f8\n" <>
  "0.8: \:4eba\:4e8b\:30fb\:6210\:7e3e\:30fb\:7d66\:4e0e\:60c5\:5831\n" <>
  "1.0: \:6975\:3081\:3066\:6a5f\:5bc6\:306a\:6587\:66f8\n\n" <>
  "\:51fa\:529b\:306f 1\:884c\:306e\:307f: PRIVACY: <\:6570\:5024>\n\n" <>
  "\:3010\:30bf\:30a4\:30c8\:30eb\:3011\n";

(* チャンクの要約・タグ生成 *)
iSummarizeChunk[chunkText_String, docTitle_String:"", useLocal_:True] :=
  Module[{prompt, raw, lines, summary = "", entities = "", tags = ""},
    prompt = $pdfChunkSummarizePrompt <>
      If[docTitle =!= "", "Document: " <> docTitle <> "\n\n", ""] <>
      StringTake[chunkText, UpTo[3000]];
    raw = If[TrueQ[useLocal], iQueryLocalLLM[prompt], iQueryCloudLLM[prompt]];
    If[!StringQ[raw], Return[<|"summary" -> "", "entities" -> "", "tags" -> ""|>]];
    (* 行ベースで SUMMARY/ENTITIES/TAGS を抽出 *)
    lines = StringSplit[raw, "\n"];
    Do[
      Module[{trimmed = StringTrim[l]},
        Which[
          StringStartsQ[trimmed, "SUMMARY:", IgnoreCase -> True],
            summary = StringTrim[StringDrop[trimmed, StringLength["SUMMARY:"]]],
          StringStartsQ[trimmed, "ENTITIES:", IgnoreCase -> True],
            entities = StringTrim[StringDrop[trimmed, StringLength["ENTITIES:"]]],
          StringStartsQ[trimmed, "TAGS:", IgnoreCase -> True],
            tags = StringTrim[StringDrop[trimmed, StringLength["TAGS:"]]]
        ]],
      {l, lines}];
    <|"summary" -> summary, "entities" -> entities, "tags" -> tags|>
  ];

(* ドキュメント全体のプライバシー推定 *)
iEstimatePrivacy[title_String, sampleText_String] := Module[{prompt, raw, val},
  prompt = $pdfDocPrivacyPrompt <> title <>
    "\n\n\:3010\:5148\:982d\:30c6\:30ad\:30b9\:30c8\:3011\n" <> StringTake[sampleText, UpTo[1000]];
  raw = iQueryLocalLLM[prompt];
  If[!StringQ[raw], Return[0.3]];
  val = First[StringCases[raw, "PRIVACY:" ~~ Whitespace ~~ v:NumberString :> v], ""];
  If[StringQ[val] && StringLength[val] > 0 && StringLength[val] <= 4,
    Clip[ToExpression[val], {0.0, 1.0}],
    0.3]
];

(* ============================================================ *)
(* インデクシング実行                                            *)
(* ============================================================ *)

Options[PDFIndex`pdfIndex] = {
  Privacy -> Automatic,
  Keywords -> {},
  Title -> None,
  Collection -> "default",
  ForceReindex -> False
};

PDFIndex`pdfIndex[pdfPath_String, opts:OptionsPattern[]] :=
  Module[{privacy, keywords, title, collection, forceReindex,
          absPath, docId, extractResult, metadata, chunks,
          docPrivacy, useLocal, indexDir, docFile, chunkFile,
          existingDoc, existingChunks,
          processedChunks, i, total, chunkData, embTexts, embeddings},
    (* オプション解決 *)
    privacy = OptionValue[PDFIndex`pdfIndex, {opts}, Privacy];
    keywords = OptionValue[PDFIndex`pdfIndex, {opts}, Keywords];
    title = OptionValue[PDFIndex`pdfIndex, {opts}, Title];
    collection = OptionValue[PDFIndex`pdfIndex, {opts}, Collection];
    forceReindex = OptionValue[PDFIndex`pdfIndex, {opts}, ForceReindex];

    (* パス解決 *)
    absPath = If[iIsURL[pdfPath],
      (* URL: ダウンロードしてキャッシュ *)
      iDownloadAndCache[pdfPath],
      (* ローカルファイル *)
      If[FileExistsQ[pdfPath], pdfPath,
        Module[{nbDir},
          nbDir = Quiet @ Check[NotebookDirectory[], Global`$packageDirectory];
          FileNameJoin[{nbDir, pdfPath}]]]];

    If[!StringQ[absPath] || (!FileExistsQ[absPath] && !iIsURL[pdfPath]),
      Message[PDFIndex`pdfIndex::notfound, pdfPath];
      Return[$Failed]];

    docId = iDocId[If[iIsURL[pdfPath], pdfPath, absPath]];
    Print["[pdfIndex] \:30c9\:30ad\:30e5\:30e1\:30f3\:30c8ID: " <> docId];

    (* 既存チェック *)
    If[!TrueQ[forceReindex],
      Module[{existing},
        existing = iFindExistingDoc[docId, collection];
        If[AssociationQ[existing],
          Print["  \:2714 \:65e2\:306b\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:6e08\:307f\:3002ForceReindex -> True \:3067\:518d\:751f\:6210\:3002"];
          Return[existing]]]];

    (* PDF テキスト抽出 *)
    Print["  \:30c6\:30ad\:30b9\:30c8\:62bd\:51fa\:4e2d..."];
    extractResult = iPDFExtract[absPath];
    If[!AssociationQ[extractResult] || KeyExistsQ[extractResult, "error"],
      Print["  \[WarningSign] PDF\:62bd\:51fa\:5931\:6557: " <>
        If[AssociationQ[extractResult], extractResult["error"], ToString[extractResult]]];
      Return[$Failed]];

    metadata = extractResult["metadata"];
    If[title === None, title = metadata["title"]];
    If[!StringQ[title] || title === "", title = FileBaseName[absPath]];
    Print["  \:30bf\:30a4\:30c8\:30eb: " <> title];
    Print["  \:30da\:30fc\:30b8\:6570: " <> ToString[metadata["pageCount"]]];

    (* 目次 (TOC) 抽出 *)
    Module[{tocData = iExtractTOC[absPath]},
      Print["  TOC\:30a8\:30f3\:30c8\:30ea: " <> ToString[Length[tocData]] <> "\:4ef6"];
      $pdfIndexAsyncContext["pendingTOC"] = tocData];

    (* === 新パイプライン: ビジョン解析 + 構造化チャンキング === *)
    Print["  \:30da\:30fc\:30b8\:5206\:6790\:4e2d..."];
    Module[{pages, pageResults = {}, visionPages = {}, textPages = {},
            mergedTables, catalog, pg, rawText, isVision, visionResult,
            tocData = Lookup[$pdfIndexAsyncContext, "pendingTOC", {}]},

      pages = Lookup[extractResult, "pages", {}];

      (* ステップ1: 各ページを分類 *)
      Do[
        pg = page["pageNum"];
        rawText = Lookup[page, "text", ""];
        isVision = iIsTableOrFigurePage[rawText];
        If[isVision,
          AppendTo[visionPages, pg],
          AppendTo[textPages, pg]],
        {page, pages}];
      Print["  \:30d3\:30b8\:30e7\:30f3\:89e3\:6790\:5bfe\:8c61: " <>
        ToString[Length[visionPages]] <> "\:30da\:30fc\:30b8 / " <>
        ToString[Length[pages]] <> "\:30da\:30fc\:30b8\:4e2d"];

      (* ステップ2: ビジョン解析 (表・図ページ) *)
      Do[
        Module[{pg = visionPages[[i]]},
          PrintTemporary["  \:30d3\:30b8\:30e7\:30f3\:89e3\:6790: p." <> ToString[pg] <>
            " (" <> ToString[i] <> "/" <> ToString[Length[visionPages]] <> ")"];
          visionResult = Quiet @ Check[
            iAnalyzePageWithVision[absPath, pg], $Failed];
          If[AssociationQ[visionResult],
            AppendTo[pageResults,
              Join[visionResult, <|"pageNum" -> pg, "isVision" -> True|>]],
            (* ビジョン解析失敗 → テキストフォールバック *)
            AppendTo[pageResults,
              <|"pageNum" -> pg, "isVision" -> False,
                "rawText" -> Lookup[
                  SelectFirst[pages, #["pageNum"] === pg &, <||>],
                  "text", ""],
                "paragraphs" -> {},
                "tables" -> {}, "figures" -> {}|>]]],
        {i, Length[visionPages]}];

      (* ステップ3: テキストページ (従来方式) *)
      Do[
        AppendTo[pageResults,
          <|"pageNum" -> pg, "isVision" -> False,
            "rawText" -> Lookup[
              SelectFirst[pages, #["pageNum"] === pg &, <||>],
              "text", ""],
            "paragraphs" -> {},
            "tables" -> {}, "figures" -> {}|>],
        {pg, textPages}];

      (* ページ番号順にソート *)
      pageResults = SortBy[pageResults, Lookup[#, "pageNum", 9999] &];

      (* ステップ4: 連続ページの表マージ *)
      mergedTables = iMergeSpanningTables[pageResults];
      If[Length[mergedTables] > 0,
        Print["  \:8868\:691c\:51fa: " <> ToString[Length[mergedTables]] <> "\:4ef6" <>
          " (\:30de\:30fc\:30b8\:6e08\:307f)"]];

      (* ステップ5: カタログ構築 *)
      catalog = iBuildCatalog[pageResults, mergedTables, tocData];
      Print["  \:30ab\:30bf\:30ed\:30b0: \:8868" <>
        ToString[Length[catalog["tables"]]] <>
        " \:56f3" <> ToString[Length[catalog["figures"]]] <>
        " \:30bb\:30af\:30b7\:30e7\:30f3" <> ToString[Length[catalog["sections"]]]];

      (* ステップ6: 構造化チャンキング *)
      chunks = iChunkFromStructured[pageResults, mergedTables];
      Print["  \:69cb\:9020\:5316\:30c1\:30e3\:30f3\:30af: " <> ToString[Length[chunks]] <> "\:4ef6"];

      (* カタログを保存用に記録 *)
      $pdfIndexAsyncContext["pendingCatalog"] = catalog];

    (* プライバシー推定 *)
    If[privacy === Automatic,
      Print["  \:30d7\:30e9\:30a4\:30d0\:30b7\:30fc\:63a8\:5b9a\:4e2d..."];
      docPrivacy = iEstimatePrivacy[title,
        If[Length[chunks] > 0, chunks[[1]]["text"], ""]];
      Print["  Privacy: " <> ToString[docPrivacy]],
      docPrivacy = N[privacy]];

    (* LLM 処理: ローカル or クラウド *)
    useLocal = docPrivacy > 0.5;

    (* チャンク要約・タグ生成 *)
    Print["  LLM\:8981\:7d04\:751f\:6210\:4e2d (" <>
      If[TrueQ[useLocal], "local", "cloud"] <> ")..."];
    total = Length[chunks];
    processedChunks = Table[
      PrintTemporary["  " <> ToString[i] <> "/" <> ToString[total]];
      Module[{c = chunks[[i]], sumResult},
        sumResult = Quiet @ Check[
          iSummarizeChunk[c["text"], title, useLocal],
          <|"summary" -> "", "entities" -> "", "tags" -> ""|>];
        Join[c, sumResult]],
      {i, total}];

    (* Embedding 生成 *)
    Print["  Embedding\:751f\:6210\:4e2d..."];
    iCreateEmbeddingSession[];
    embTexts = (iDoubleEscape[
      #["summary"] <> " " <> #["entities"] <> " " <> #["tags"] <>
      " " <> StringTake[#["text"], UpTo[500]]] &) /@ processedChunks;
    embeddings = Quiet @ Check[iCreateEmbeddings[embTexts], {}];
    If[ListQ[embeddings] && Length[embeddings] === Length[processedChunks],
      processedChunks = MapThread[
        Append[#1, "embedding" -> If[ListQ[#2] && Length[#2] > 100, #2, {}]] &,
        {processedChunks, embeddings}],
      processedChunks = Append[#, "embedding" -> {}] & /@ processedChunks];

    (* 保存先決定 *)
    indexDir = If[docPrivacy > 0.5,
      iCollectionDir[collection, "private"],
      iCollectionDir[collection, "public"]];

    (* ドキュメントメタデータ保存 *)
    Module[{docMeta},
      docMeta = <|
        "docId" -> docId,
        "title" -> title,
        "author" -> Lookup[metadata, "author", ""],
        "sourcePath" -> If[iIsURL[pdfPath], pdfPath, absPath],
        "sourceType" -> If[iIsURL[pdfPath], "url", "file"],
        "privacy" -> docPrivacy,
        "collection" -> collection,
        "pageCount" -> Lookup[metadata, "pageCount", 0],
        "chunkCount" -> Length[processedChunks],
        "keywords" -> keywords,
        "indexedAt" -> DateString[Now, "ISODateTime"],
        "storageType" -> If[docPrivacy > 0.5, "private", "public"]
      |>;
      docFile = FileNameJoin[{indexDir, "doc_" <> docId <> ".wl"}];
      Put[docMeta, docFile];
      Print["  \:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:30e1\:30bf\:4fdd\:5b58: " <> docFile]];

    (* チャンクデータ保存: 各チャンクに docId を付加 *)
    processedChunks = Append[#, "docId" -> docId] & /@ processedChunks;
    chunkFile = FileNameJoin[{indexDir, "chunks_" <> docId <> ".wl"}];
    Put[processedChunks, chunkFile];
    Print["  \:30c1\:30e3\:30f3\:30af\:30c7\:30fc\:30bf\:4fdd\:5b58: " <> chunkFile];

    (* TOC 保存 *)
    Module[{tocData = Lookup[$pdfIndexAsyncContext, "pendingTOC", {}], tocFile},
      If[ListQ[tocData] && Length[tocData] > 0,
        tocFile = FileNameJoin[{indexDir, "toc_" <> docId <> ".wl"}];
        Put[tocData, tocFile];
        Print["  TOC\:4fdd\:5b58: " <> ToString[Length[tocData]] <> "\:30a8\:30f3\:30c8\:30ea"]];
      $pdfIndexAsyncContext = KeyDrop[$pdfIndexAsyncContext, "pendingTOC"]];

    (* カタログ保存 *)
    Module[{catalog = Lookup[$pdfIndexAsyncContext, "pendingCatalog", <||>],
            catalogFile},
      If[AssociationQ[catalog] && Length[catalog] > 0,
        catalogFile = FileNameJoin[{indexDir, "catalog_" <> docId <> ".wl"}];
        Put[catalog, catalogFile];
        Print["  \:30ab\:30bf\:30ed\:30b0\:4fdd\:5b58: " <> catalogFile]];
      $pdfIndexAsyncContext = KeyDrop[$pdfIndexAsyncContext, "pendingCatalog"]];

    (* キャッシュを無効化 *)
    $pdfIndexCache = KeyDrop[$pdfIndexCache, collection];

    Print[Style["  \:2714 \:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:5b8c\:4e86: " <> title, Darker[Green]]];
    <|"docId" -> docId, "title" -> title, "privacy" -> docPrivacy,
      "chunks" -> Length[processedChunks], "collection" -> collection|>
  ];

PDFIndex`pdfIndex::notfound = "\:30d5\:30a1\:30a4\:30eb\:304c\:898b\:3064\:304b\:308a\:307e\:305b\:3093: `1`";

(* ============================================================ *)
(* URL ダウンロード・キャッシュ                                   *)
(* ============================================================ *)

iDownloadAndCache[url_String] := Module[{dir, hashStr, existing, outPath, data},
  dir = FileNameJoin[{PDFIndex`$pdfIndexAttachDir}];
  If[!DirectoryQ[dir], Quiet[CreateDirectory[dir, CreateIntermediateDirectories -> True]]];
  hashStr = IntegerString[Hash[url, "SHA256"], 16, 8];
  (* 既存キャッシュを検索 *)
  existing = FileNames["*." <> hashStr <> ".pdf", dir];
  If[Length[existing] > 0, Return[First[existing]]];
  (* ダウンロード *)
  Print["  URL\:30c0\:30a6\:30f3\:30ed\:30fc\:30c9\:4e2d: " <> StringTake[url, UpTo[60]] <> "..."];
  data = Quiet @ Check[URLRead[url, "BodyByteArray"], $Failed];
  If[!MatchQ[data, _ByteArray],
    Print["  \[WarningSign] \:30c0\:30a6\:30f3\:30ed\:30fc\:30c9\:5931\:6557"];
    Return[$Failed]];
  outPath = FileNameJoin[{dir, "url_" <> hashStr <> ".pdf"}];
  Module[{strm},
    strm = OpenWrite[outPath, BinaryFormat -> True];
    BinaryWrite[strm, Normal[data]];
    Close[strm]];
  Print["  \:4fdd\:5b58: " <> outPath];
  outPath
];

(* ============================================================ *)
(* ディレクトリ一括インデクシング                                 *)
(* ============================================================ *)

Options[PDFIndex`pdfIndexDirectory] = Join[
  Options[PDFIndex`pdfIndex],
  {FilePattern -> "*.pdf"}];

PDFIndex`pdfIndexDirectory[dirPath_String, opts:OptionsPattern[]] :=
  Module[{pattern, files, results},
    pattern = OptionValue[PDFIndex`pdfIndexDirectory, {opts}, FilePattern];
    files = FileNames[pattern, dirPath];
    If[Length[files] === 0,
      Print["\:5bfe\:8c61PDF\:306a\:3057: " <> dirPath];
      Return[{}]];
    Print["[pdfIndexDirectory] " <> ToString[Length[files]] <> " \:30d5\:30a1\:30a4\:30eb\:3092\:51e6\:7406\:3057\:307e\:3059"];
    results = Table[
      Print["\n--- " <> ToString[i] <> "/" <> ToString[Length[files]] <>
        ": " <> FileNameTake[files[[i]]] <> " ---"];
      Quiet @ Check[
        PDFIndex`pdfIndex[files[[i]],
          FilterRules[{opts}, Options[PDFIndex`pdfIndex]]],
        $Failed],
      {i, Length[files]}];
    Select[results, AssociationQ]
  ];

(* ============================================================ *)
(* URL インデクシング                                            *)
(* ============================================================ *)

Options[PDFIndex`pdfIndexURL] = Options[PDFIndex`pdfIndex];

PDFIndex`pdfIndexURL[url_String, opts:OptionsPattern[]] :=
  PDFIndex`pdfIndex[url, opts];

(* ============================================================ *)
(* インデックスのロード                                          *)
(* ============================================================ *)

(* 既存ドキュメントの検索 *)
iFindExistingDoc[docId_String, collection_String] := Module[{dirs, docFile},
  dirs = {iCollectionDir[collection, "private"],
          iCollectionDir[collection, "public"]};
  Do[
    docFile = FileNameJoin[{d, "doc_" <> docId <> ".wl"}];
    If[FileExistsQ[docFile],
      Return[Quiet @ Check[Get[docFile], $Failed], Module]],
    {d, dirs}];
  None
];

(* コレクションの全ドキュメントメタデータをロード *)
iLoadCollectionDocs[collection_String] := Module[{dirs, docFiles, docs},
  dirs = {iCollectionDir[collection, "private"],
          iCollectionDir[collection, "public"]};
  docFiles = Flatten[FileNames["doc_*.wl", #] & /@ dirs];
  docs = Select[Quiet[Check[Get[#], Nothing] & /@ docFiles], AssociationQ];
  docs
];

(* コレクションの全チャンクをロード *)
iLoadCollectionChunks[collection_String] := Module[{dirs, chunkFiles, allChunks},
  dirs = {iCollectionDir[collection, "private"],
          iCollectionDir[collection, "public"]};
  chunkFiles = Flatten[FileNames["chunks_*.wl", #] & /@ dirs];
  allChunks = Flatten[
    Select[Quiet[Check[Get[#], {}] & /@ chunkFiles], ListQ], 1];
  Select[allChunks, AssociationQ]
];

(* カタログファイルのロード *)
iLoadCollectionCatalogs[collection_String] := Module[{dirs, catalogFiles, catalogs},
  dirs = {iCollectionDir[collection, "private"],
          iCollectionDir[collection, "public"]};
  catalogFiles = Flatten[FileNames["catalog_*.wl", #] & /@ dirs];
  catalogs = Select[
    Quiet[Check[Get[#], Nothing] & /@ catalogFiles], AssociationQ];
  (* 全カタログを統合 *)
  If[Length[catalogs] === 0, Return[<|"tables" -> {}, "figures" -> {}, "sections" -> {}|>]];
  <|"tables" -> Flatten[Lookup[#, "tables", {}] & /@ catalogs],
    "figures" -> Flatten[Lookup[#, "figures", {}] & /@ catalogs],
    "sections" -> Flatten[Lookup[#, "sections", {}] & /@ catalogs]|>
];

(* PDFIndexObject の構築 *)
PDFIndex`pdfLoadIndex[collection_String:"default"] := Module[
  {docs, chunks, catalogs, embRules, embRulesST, nearest, nearestST},
  (* キャッシュチェック *)
  If[KeyExistsQ[$pdfIndexCache, collection],
    Return[$pdfIndexCache[collection]["idx"]]];
  Print["[pdfLoadIndex] " <> collection <> " \:3092\:30ed\:30fc\:30c9\:4e2d..."];
  docs = iLoadCollectionDocs[collection];
  chunks = iLoadCollectionChunks[collection];
  catalogs = iLoadCollectionCatalogs[collection];
  Print["  \:30c9\:30ad\:30e5\:30e1\:30f3\:30c8: " <> ToString[Length[docs]] <>
    ", \:30c1\:30e3\:30f3\:30af: " <> ToString[Length[chunks]] <>
    If[Length[catalogs] > 0,
      ", \:30ab\:30bf\:30ed\:30b0: " <> ToString[Length[catalogs]], ""]];
  (* NearestFunction 構築 *)
  embRules = Select[
    MapIndexed[
      If[ListQ[#1["embedding"]] && Length[#1["embedding"]] > 100,
        #1["embedding"] -> #2[[1]], Nothing] &,
      chunks],
    MatchQ[#, _Rule] &];
  nearest = If[Length[embRules] > 0,
    Quiet @ Check[Nearest[embRules, DistanceFunction -> CosineDistance], None],
    None];
  Module[{idx},
    idx = PDFIndex`PDFIndexObject[<|
      "collection" -> collection,
      "docs" -> docs,
      "chunks" -> chunks,
      "catalogs" -> catalogs,
      "docCount" -> Length[docs],
      "chunkCount" -> Length[chunks],
      "nearest" -> nearest,
      "count" -> Length[chunks]
    |>];
    $pdfIndexCache[collection] = <|
      "idx" -> idx,
      "loadedAt" -> AbsoluteTime[]|>;
    idx]
];

PDFIndex`pdfLoadIndex[] := Module[{collections},
  collections = PDFIndex`pdfListCollections[];
  Association[# -> PDFIndex`pdfLoadIndex[#] & /@ collections]
];

(* ============================================================ *)
(* コレクション管理                                              *)
(* ============================================================ *)

PDFIndex`pdfListCollections[] := Module[{dirs, collections},
  dirs = {};
  If[DirectoryQ[PDFIndex`$pdfIndexBaseDir],
    dirs = Join[dirs, Select[FileNames["*", PDFIndex`$pdfIndexBaseDir], DirectoryQ]]];
  Module[{pubDir = FileNameJoin[{PDFIndex`$pdfIndexAttachDir, "pdfindex"}]},
    If[DirectoryQ[pubDir],
      dirs = Join[dirs, Select[FileNames["*", pubDir], DirectoryQ]]]];
  collections = DeleteDuplicates[FileNameTake[#] & /@ dirs];
  If[Length[collections] === 0, {"default"}, Sort[collections]]
];

PDFIndex`pdfListDocs[collection_String:"default"] := Module[{docs},
  docs = iLoadCollectionDocs[collection];
  Dataset[docs[All, {"docId", "title", "author", "privacy", "pageCount",
    "chunkCount", "indexedAt", "storageType"}]]
];

PDFIndex`pdfRemoveDoc[docId_String, collection_String:"default"] :=
  Module[{dirs, removed = False},
    dirs = {iCollectionDir[collection, "private"],
            iCollectionDir[collection, "public"]};
    Do[
      Module[{docFile, chunkFile, catalogFile, tocFile},
        docFile = FileNameJoin[{d, "doc_" <> docId <> ".wl"}];
        chunkFile = FileNameJoin[{d, "chunks_" <> docId <> ".wl"}];
        catalogFile = FileNameJoin[{d, "catalog_" <> docId <> ".wl"}];
        tocFile = FileNameJoin[{d, "toc_" <> docId <> ".wl"}];
        If[FileExistsQ[docFile],
          Quiet[DeleteFile[docFile]]; removed = True];
        If[FileExistsQ[chunkFile], Quiet[DeleteFile[chunkFile]]];
        If[FileExistsQ[catalogFile], Quiet[DeleteFile[catalogFile]]];
        If[FileExistsQ[tocFile], Quiet[DeleteFile[tocFile]]]],
      {d, dirs}];
    $pdfIndexCache = KeyDrop[$pdfIndexCache, collection];
    If[removed, Print["\:524a\:9664\:5b8c\:4e86: " <> docId], Print["\:898b\:3064\:304b\:308a\:307e\:305b\:3093: " <> docId]];
    removed
  ];

(* ============================================================ *)
(* 検索エンジン                                                  *)
(* ============================================================ *)

(* クエリ拡張: LLM を使わずキーワード分割のみで対応。
   課金API呼び出しを防止するため、LLM拡張は無効化。 *)
iExpandSearchQuery[query_String] := query;

(* キーワードマッチスコア *)
(* ============================================================ *)
(* 日本語対応クエリ分割 (maildb.wl の splitQueryTerms 移植)      *)
(* ============================================================ *)

(* 助詞・接続詞でクエリを分割し、意味のある語を抽出 *)
iSplitQueryTerms[query_String] := Module[{raw, terms},
  raw = StringSplit[query, Whitespace];
  terms = Flatten[StringSplit[#,
    RegularExpression["\:306e|\:306f|\:304c|\:3092|\:306b|\:3067|\:3068|\:3082|\:3078|\:304b\:3089|\:307e\:3067|\:306b\:3064\:3044\:3066|\:306b\:304a\:3051\:308b|\:306b\:3088\:308b|\:306b\:95a2\:3059\:308b|\:3068\:306f|\:3063\:3066|\:305f|\:3067\:3059|\:307e\:3059|\:3057\:305f"]] & /@ raw];
  (* 疑問符等を除去 *)
  terms = StringReplace[#, RegularExpression["[?\:ff1f!,.\:3001\:3002\:30fb]"] -> ""] & /@ terms;
  Select[terms, StringLength[#] >= 2 &]
];

(* 文字種境界で複合語をさらに分割 (漢字/カタカナ/英数字の切れ目)
   例: "情報工学科" → {"情報工学科", "情報", "工学", "工学科"}
   例: "CANDAR論文" → {"CANDAR論文", "CANDAR", "論文"} *)
iSplitAtCharBoundary[term_String] := Module[{parts, result, kanjiNgrams},
  parts = StringCases[term,
    RegularExpression[
      "[\:30A0-\:30FF\:31F0-\:31FF\:FF65-\:FF9F]+" <>   (* katakana *)
      "|[\:4E00-\:9FFF\:3400-\:4DBF\:F900-\:FAFF]+" <>  (* kanji *)
      "|[\:3040-\:309F]+" <>                        (* hiragana *)
      "|[A-Za-z0-9\:FF10-\:FF19\:FF21-\:FF3A\:FF41-\:FF5A]+"]];  (* alphanum *)
  parts = Select[parts, StringLength[#] >= 2 &];
  result = If[Length[parts] > 1, Prepend[parts, term], {term}];
  (* 漢字3文字以上の連続から2-gram, 3-gram を生成 *)
  kanjiNgrams = Flatten[Function[p,
    If[StringMatchQ[p, RegularExpression["[\:4E00-\:9FFF\:3400-\:4DBF\:F900-\:FAFF]{3,}"]],
      With[{chars = Characters[p], len = StringLength[p]},
        Join[
          Table[StringJoin[chars[[i ;; i + 1]]], {i, len - 1}],
          If[len >= 4,
            Table[StringJoin[chars[[i ;; i + 2]]], {i, len - 2}],
            {}]]],
      {}]
  ] /@ parts];
  DeleteDuplicates[Join[result, kanjiNgrams]]
];

(* キーワードマッチスコア: 日本語対応版 *)
iKeywordMatchScore[chunk_Association, query_String] :=
  Module[{terms, subTerms, score = 0.0, text, summ, tags, entities, hasMeta},
    terms = iSplitQueryTerms[query];
    If[Length[terms] == 0, terms = {query}];
    (* 文字種境界で追加分割 *)
    subTerms = DeleteDuplicates[Flatten[iSplitAtCharBoundary /@ terms]];
    text = If[StringQ[chunk["text"]], StringTake[chunk["text"], UpTo[3000]], ""];
    summ = If[StringQ[chunk["summary"]], chunk["summary"], ""];
    tags = If[StringQ[chunk["tags"]], chunk["tags"], ""];
    entities = If[StringQ[chunk["entities"]], chunk["entities"], ""];
    (* メタデータ (summary/tags) が存在するか *)
    hasMeta = StringLength[summ] > 0 || StringLength[tags] > 0;
    (* 元のタームでフルウェイトスコアリング *)
    Do[
      If[StringContainsQ[summ, term, IgnoreCase -> True], score += 3.0];
      If[StringContainsQ[entities, term, IgnoreCase -> True], score += 3.0];
      If[StringContainsQ[tags, term, IgnoreCase -> True], score += 2.0];
      (* テキストのオリジナルターム: メタなし時は高ウェイト *)
      If[StringContainsQ[text, term, IgnoreCase -> True],
        score += If[hasMeta, 1.0, 5.0]],
      {term, terms}];
    (* 全タームが同一チャンクに共起 → ボーナス *)
    If[Length[terms] >= 2 &&
       AllTrue[terms, StringContainsQ[text, #, IgnoreCase -> True] &],
      score += 3.0 * Length[terms]];
    (* サブタームで減衰ウェイトスコアリング *)
    With[{extraTerms = Complement[subTerms, terms]},
      Do[
        If[StringContainsQ[summ, st, IgnoreCase -> True], score += 1.5];
        If[StringContainsQ[entities, st, IgnoreCase -> True], score += 1.5];
        If[StringContainsQ[tags, st, IgnoreCase -> True], score += 1.0];
        If[StringContainsQ[text, st, IgnoreCase -> True], score += 0.3],
        {st, extraTerms}]];
    score / Max[Length[terms], 1]
  ];

(* ハイブリッド検索 *)
Options[PDFIndex`pdfSearch] = {
  Collection -> "default",
  MaxItems -> 20,
  MinPrivacy -> None,
  MaxPrivacy -> None
};

(* 内部: 生データを返す検索コア *)
iPdfSearchRaw[query_String, maxItems_Integer, collection_String,
              minPriv_, maxPriv_] :=
  Module[{idx, expandedQuery, qEmbedding,
          embIndices, kwScores, allIndices,
          embRanks, finalScores, ranked, filtered},
    (* インデックスロード *)
    idx = PDFIndex`pdfLoadIndex[collection];
    If[idx["count"] === 0,
      Print["  \:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:304c\:7a7a\:3067\:3059\:3002\:5148\:306b pdfIndex[] \:3067\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:3092\:8ffd\:52a0\:3057\:3066\:304f\:3060\:3055\:3044\:3002"];
      Return[{}]];

    (* クエリ拡張 *)
    expandedQuery = iExpandSearchQuery[query];

    (* 検索語の表示 *)
    Module[{terms = iSplitQueryTerms[query],
            subTerms},
      subTerms = DeleteDuplicates[Flatten[iSplitAtCharBoundary /@ terms]];
      Print["  \:691c\:7d22\:8a9e: " <> StringRiffle[terms, ", "] <>
        If[Length[subTerms] > Length[terms],
          "  (+\:5206\:5272: " <> StringRiffle[Complement[subTerms, terms], ", "] <> ")",
          ""]]];

    If[TrueQ[PDFIndex`$pdfIndexDebug],
      Print["  \:62e1\:5f35\:30af\:30a8\:30ea: " <> StringTake[expandedQuery, UpTo[80]] <> "..."]];

    (* Embedding 検索 *)
    qEmbedding = Quiet @ Check[
      First[iCreateEmbeddings[{expandedQuery}]], {}];
    embIndices = If[idx["nearest"] =!= None && Length[qEmbedding] > 100,
      idx["nearest"][qEmbedding, Min[maxItems * 3, idx["count"]]],
      (* Embedding 未使用: キーワード検索に依存 *)
      (Print["  \:26a0 Embedding\:672a\:4f7f\:7528 (\:30ad\:30fc\:30ef\:30fc\:30c9\:691c\:7d22\:306e\:307f)"]; {})];

    (* キーワード検索: 全チャンクをスキャン *)
    kwScores = MapIndexed[
      {iKeywordMatchScore[#1, query], #2[[1]]} &,
      idx["chunks"]];

    (* Reciprocal Rank Fusion *)
    embRanks = Association@MapIndexed[#1 -> #2[[1]] &, embIndices];
    allIndices = Union[embIndices,
      (#[[2]] &) /@ Select[kwScores, #[[1]] > 0 &]];

    finalScores = Association@Map[
      Module[{embScore, kwScore},
        embScore = 0.6 / (60.0 + Lookup[embRanks, #, 9999]);
        kwScore = Lookup[
          Association[#[[2]] -> #[[1]] & /@ kwScores], #, 0.0];
        # -> (embScore +
          0.4 * kwScore / Max[Max[(#[[1]] &) /@ kwScores], 0.001])] &,
      allIndices];

    (* === カタログスコアブースト ===
       表キャプション・図キャプション・セクション見出しにクエリがマッチしたら
       該当ページのチャンクスコアを大幅に引き上げる *)
    Module[{catalogs, catalogPages = {}, qTerms = iSplitQueryTerms[query],
            subTerms, cScore},
      catalogs = Quiet @ Check[Lookup[idx, "catalogs", <||>], <||>];
      If[AssociationQ[catalogs],
        subTerms = DeleteDuplicates[Flatten[iSplitAtCharBoundary /@ qTerms]];
        (* 表カタログ検索 *)
        Do[
          cScore = 0;
          Do[If[StringContainsQ[Lookup[te, "searchText", ""],
                t, IgnoreCase -> True], cScore++], {t, subTerms}];
          If[cScore > 0,
            Do[AppendTo[catalogPages,
              p -> cScore * 2.0],  (* 表ヒットは高ブースト *)
              {p, Range[te["startPage"], te["endPage"]]}]],
          {te, Lookup[catalogs, "tables", {}]}];
        (* 図カタログ検索 *)
        Do[
          cScore = 0;
          Do[If[StringContainsQ[Lookup[fe, "searchText", ""],
                t, IgnoreCase -> True], cScore++], {t, subTerms}];
          If[cScore > 0,
            AppendTo[catalogPages, fe["page"] -> cScore * 1.5]],
          {fe, Lookup[catalogs, "figures", {}]}];
        (* カタログマッチページのチャンクをブースト *)
        If[Length[catalogPages] > 0,
          Module[{pageBoost = Association[catalogPages]},
            finalScores = Association@KeyValueMap[
              Module[{chunkPage, boost},
                chunkPage = Lookup[idx["chunks"][[#1]], "pageNum", 0];
                boost = Lookup[pageBoost, chunkPage, 0];
                #1 -> (#2 + boost)] &,
              finalScores];
            Print["  \:30ab\:30bf\:30ed\:30b0\:30d6\:30fc\:30b9\:30c8: " <>
              ToString[Length[pageBoost]] <> "\:30da\:30fc\:30b8"]]]]];

    ranked = Take[SortBy[Normal[finalScores], -#[[2]] &], UpTo[maxItems]];

    (* キーワードマッチ情報の表示 *)
    Module[{kwMatches, kwMatchCount, topKw, qTerms = iSplitQueryTerms[query]},
      kwMatches = Select[kwScores, #[[1]] > 0 &];
      kwMatchCount = Length[kwMatches];
      Print["  \:30ad\:30fc\:30ef\:30fc\:30c9\:30de\:30c3\:30c1: " <> ToString[kwMatchCount] <> "\:4ef6" <>
        If[Length[embIndices] > 0,
          ", Embedding\:7d50\:679c: " <> ToString[Length[embIndices]] <> "\:4ef6", ""]];
      (* 上位5件のキーワードマッチをKWICで表示 *)
      If[kwMatchCount > 0,
        topKw = Take[SortBy[kwMatches, -#[[1]] &], UpTo[5]];
        Do[
          Module[{ci = kw[[2]], sc = kw[[1]], kwic},
            kwic = iKWIC[
              If[StringQ[idx["chunks"][[ci]]["text"]],
                idx["chunks"][[ci]]["text"], ""],
              qTerms, 60];
            Print["    #" <> ToString[ci] <>
              " (score=" <> ToString[NumberForm[sc, {4, 2}]] <>
              "): " <> kwic]],
          {kw, topKw}]]];

    (* プライバシーフィルタ + スコア・メタデータ付加 *)
    filtered = Map[
      Module[{c = idx["chunks"][[#[[1]]]], docMeta, sc = #[[2]]},
        docMeta = iGetDocMetaForChunk[c, idx["docs"]];
        Join[c, <|
          "chunkIndex" -> #[[1]],
          "docTitle" -> If[AssociationQ[docMeta], docMeta["title"], ""],
          "docPrivacy" -> If[AssociationQ[docMeta], docMeta["privacy"], 0.0],
          "score" -> Round[sc, 0.001]|>]] &,
      ranked];
    If[NumericQ[minPriv],
      filtered = Select[filtered, Lookup[#, "docPrivacy", 0] >= minPriv &]];
    If[NumericQ[maxPriv],
      filtered = Select[filtered, Lookup[#, "docPrivacy", 1] <= maxPriv &]];
    filtered
  ];

(* 公開API: 見やすい Dataset で返す *)
PDFIndex`pdfSearch[query_String, n_Integer:20, opts:OptionsPattern[]] :=
  Module[{collection, maxItems, minPriv, maxPriv, raw, queryTerms},
    collection = OptionValue[PDFIndex`pdfSearch, {opts}, Collection];
    maxItems = OptionValue[PDFIndex`pdfSearch, {opts}, MaxItems];
    minPriv = OptionValue[PDFIndex`pdfSearch, {opts}, MinPrivacy];
    maxPriv = OptionValue[PDFIndex`pdfSearch, {opts}, MaxPrivacy];
    If[!IntegerQ[maxItems], maxItems = n];
    raw = iPdfSearchRaw[query, maxItems, collection, minPriv, maxPriv];
    If[!ListQ[raw] || Length[raw] === 0, Return[Dataset[{}]]];
    queryTerms = iSplitQueryTerms[query];
    Dataset@MapIndexed[
      <|"rank" -> #2[[1]],
        "score" -> Lookup[#1, "score", 0],
        "page" -> Lookup[#1, "pageNum", "?"],
        "docTitle" -> StringTake[If[StringQ[#1["docTitle"]], #1["docTitle"], ""], UpTo[25]],
        "summary" -> If[StringQ[#1["summary"]], #1["summary"], ""],
        "tags" -> If[StringQ[#1["tags"]], #1["tags"], ""],
        "context" -> iKWIC[If[StringQ[#1["text"]], #1["text"], ""], queryTerms, 120],
        "chunkIdx" -> Lookup[#1, "globalIdx", #2[[1]]]|> &,
      raw]
  ];

(* KWIC: Keyword In Context — マッチしたキーワード周辺のテキストを抽出 *)
iKWIC[text_String, queryTerms_List, maxLen_Integer:120] :=
  Module[{pos, bestPos = 0, bestTerm = "", term, p, start, end, result},
    If[StringLength[text] == 0, Return[""]];
    (* 最初にマッチするオリジナルタームを探す (長い語を優先) *)
    Do[
      p = Quiet @ Check[
        First[StringPosition[text, term, 1], None],
        None];
      If[p =!= None,
        bestPos = p[[1]];
        bestTerm = term;
        Break[]],
      {term, SortBy[queryTerms, -StringLength[#] &]}];
    If[bestPos === 0,
      (* オリジナルタームなし → サブタームで検索 *)
      Module[{subTerms},
        subTerms = DeleteDuplicates[Flatten[iSplitAtCharBoundary /@ queryTerms]];
        Do[
          p = Quiet @ Check[
            First[StringPosition[text, st, 1], None],
            None];
          If[p =!= None,
            bestPos = p[[1]]; bestTerm = st; Break[]],
          {st, SortBy[subTerms, -StringLength[#] &]}]]];
    If[bestPos === 0,
      (* マッチなし → 先頭を表示 *)
      Return[StringTake[text, UpTo[maxLen]]]];
    (* マッチ位置の前後を表示 *)
    start = Max[1, bestPos - 40];
    end = Min[StringLength[text], bestPos + maxLen - 40];
    result = "";
    If[start > 1, result = "..."];
    result = result <> StringTake[text, {start, end}];
    If[end < StringLength[text], result = result <> "..."];
    (* マッチ箇所を【】で囲む *)
    StringReplace[result, bestTerm -> "\:300c" <> bestTerm <> "\:300d", 1]
  ];

(* チャンクからドキュメントメタデータを取得するヘルパー *)
iGetDocMetaForChunk[chunk_Association, docs_List] :=
  Module[{cDocId, match},
    cDocId = Lookup[chunk, "docId", ""];
    If[cDocId === "" || !StringQ[cDocId],
      Return[First[docs, None]]];
    match = Select[docs, Lookup[#, "docId", ""] === cDocId &, 1];
    If[Length[match] > 0, First[match], First[docs, None]]
  ];

(* ============================================================ *)
(* チャンク直接取得                                              *)
(* ============================================================ *)

PDFIndex`pdfGetChunk[chunkIndex_Integer, collection_String:"default"] :=
  Module[{idx, chunk},
    idx = PDFIndex`pdfLoadIndex[collection];
    If[chunkIndex < 1 || chunkIndex > idx["count"],
      Print["\[WarningSign] \:7bc4\:56f2\:5916: 1\:301c" <> ToString[idx["count"]]];
      Return[$Failed]];
    chunk = idx["chunks"][[chunkIndex]];
    chunk["text"]
  ];

PDFIndex`pdfGetChunk[{from_Integer, to_Integer}, collection_String:"default"] :=
  Module[{idx, n, chunks},
    idx = PDFIndex`pdfLoadIndex[collection];
    n = idx["count"];
    chunks = idx["chunks"][[Max[1, from] ;; Min[n, to]]];
    StringJoin[Riffle[
      If[StringQ[#["text"]], #["text"], ""] & /@ chunks,
      "\n\n--- \:30c1\:30e3\:30f3\:30af\:5883\:754c ---\n\n"]]
  ];

(* ============================================================ *)
(* PDF ページ画像表示                                            *)
(* ============================================================ *)

(* ドキュメントのソースパスを取得 *)
iGetDocSourcePath[collection_String] := Module[{docs},
  docs = iLoadCollectionDocs[collection];
  If[Length[docs] > 0,
    First[docs]["sourcePath"],
    None]
];

(* チャンクインデックスからの粗推定（フォールバック用） *)
iEstimatePageNum[chunkIndex_Integer, collection_String:"default"] :=
  Module[{docs, totalPages, totalChunks},
    docs = iLoadCollectionDocs[collection];
    If[Length[docs] === 0, Return[1]];
    totalPages = First[docs]["pageCount"];
    totalChunks = First[docs]["chunkCount"];
    If[!IntegerQ[totalPages] || totalPages <= 0, totalPages = 1];
    If[!IntegerQ[totalChunks] || totalChunks <= 0, Return[1]];
    Clip[Ceiling[chunkIndex * totalPages / totalChunks], {1, totalPages}]
  ];

(* ============================================================ *)
(* PDF ページテキスト直接検索 (TOC優先 + 近接性スコアリング)       *)
(* ============================================================ *)

(* コレクションのTOCをロード *)
iLoadTOC[collection_String] := Module[{dirs, tocFiles, toc},
  dirs = {iCollectionDir[collection, "private"],
          iCollectionDir[collection, "public"]};
  tocFiles = Flatten[FileNames["toc_*.wl", #] & /@ dirs];
  If[Length[tocFiles] === 0, Return[{}]];
  toc = Quiet @ Check[Get[First[tocFiles]], {}];
  If[ListQ[toc], toc, {}]
];

(* PDFの各ページテキストを取得してスコアリング
   戦略: TOCがあればセクション範囲を絞り込み、その範囲内を優先的に検索 *)
iSearchPDFPages[pdfPath_String, query_String] :=
  iSearchPDFPagesWithCollection[pdfPath, query, "default"];

iSearchPDFPagesWithCollection[pdfPath_String, query_String,
    collection_String] :=
  Module[{terms, escapedPath, outJsonFile, pyCode, result, json,
          toc, tocRange, scores, rangeScores, bestPage, allPages, pairScores},
    terms = iSplitQueryTerms[query];
    If[Length[terms] === 0, terms = {query}];

    (* TOC をロードしてページ範囲を特定 *)
    toc = iLoadTOC[collection];
    tocRange = iTOCFindPageRange[toc, query];
    If[tocRange =!= None,
      Print["  TOC: \"" <> tocRange["section"] <> "\" \:2192 p." <>
        ToString[tocRange["startPage"]] <> "-" <>
        ToString[tocRange["endPage"]]]];

    escapedPath = StringReplace[pdfPath, "\\" -> "/"];
    outJsonFile = FileNameJoin[{$TemporaryDirectory,
      "pdfpages_" <> IntegerString[Round[AbsoluteTime[] * 1000]] <> ".json"}];
    (* PyMuPDF で全ページテキストを一括抽出 *)
    pyCode = "
import json
try:
    import fitz
    doc = fitz.open(r'" <> escapedPath <> "')
    pages = []
    for i in range(doc.page_count):
        text = doc[i].get_text('text')
        pages.append({'page': i+1, 'text': text[:5000]})
    doc.close()
    with open(r'" <> StringReplace[outJsonFile, "\\" -> "/"] <>
      "', 'w', encoding='utf-8') as f:
        json.dump(pages, f, ensure_ascii=False)
    'done'
except Exception as e:
    str(e)
";
    result = Quiet @ Check[ExternalEvaluate["Python", pyCode], $Failed];
    If[!FileExistsQ[outJsonFile],
      Return[iSearchPDFPagesWL[pdfPath, terms]]];
    json = Quiet @ Check[Developer`ReadRawJSONFile[outJsonFile], $Failed];
    Quiet[DeleteFile[outJsonFile]];
    If[!ListQ[json], Return[iSearchPDFPagesWL[pdfPath, terms]]];

    (* スコアリング: 個別ページ *)
    allPages = iScorePagesByProximity[json, terms];

    (* === 連続ページペアスコアリング ===
       表がページをまたぐ場合: p.N に表ヘッダ(情報工学科)、p.N+1 に表本体(離散数学)
       → 2ページ連結してスコアリングし、ペアとして評価 *)
    pairScores = {};
    Do[
      Module[{p1 = json[[i]], p2 = json[[i + 1]],
              pg1, pg2, combinedText, pairScore},
        pg1 = Lookup[p1, "page", 0];
        pg2 = Lookup[p2, "page", 0];
        combinedText = Lookup[p1, "text", ""] <> "\n" <> Lookup[p2, "text", ""];
        pairScore = First[iScorePagesByProximity[
          {<|"page" -> pg2, "text" -> combinedText|>}, terms]];
        (* ペアスコアに1.5倍ボーナス: 表がまたぐページを優遇 *)
        If[pairScore[[2]] > 0,
          AppendTo[pairScores, {pg2, pairScore[[2]] * 1.5, pg1}]]],
      {i, Length[json] - 1}];
    (* ペアスコアを個別スコアに統合 *)
    Do[
      Module[{pg = ps[[1]], psc = ps[[2]]},
        allPages = Map[
          If[#[[1]] === pg && psc > #[[2]],
            {#[[1]], psc}, #] &,
          allPages]],
      {ps, pairScores}];

    allPages = Select[allPages, #[[2]] > 0 &];
    If[Length[allPages] === 0, Return[$Failed]];

    (* TOCでページ範囲が特定できた場合:
       加算ボーナスのみ（乗算なし）。
       ページ内容の質（全タームの共起）がランキングを決め、
       TOCボーナスは「正しいセクション内にいる」追加点のみ。 *)
    If[tocRange =!= None,
      Module[{sp = tocRange["startPage"], ep = tocRange["endPage"], dist},
        allPages = Map[
          Module[{pg = #[[1]], sc = #[[2]]},
            Which[
              sp <= pg <= ep,
                {pg, sc + 100.0},
              pg > ep && pg <= ep + 5,
                {pg, sc + 100.0 - (pg - ep) * 10.0},
              pg > ep && pg <= ep + 10,
                {pg, sc + 30.0},
              pg < sp && pg >= sp - 3,
                {pg, sc + 30.0},
              True, #]] &,
          allPages]]];

    bestPage = First[SortBy[allPages, -#[[2]] &]];
    Print["  \:30da\:30fc\:30b8\:30b9\:30b3\:30a2: " <>
      StringRiffle[
        ("p." <> ToString[#[[1]]] <> "=" <>
          ToString[NumberForm[#[[2]], {5, 1}]]) & /@
          Take[SortBy[allPages, -#[[2]] &], UpTo[5]], ", "]];

    (* ベストページを返す。
       ペアスコアリングでベストページが決まった場合、
       表のヘッダは常に前ページにあるため {bestPg-1, bestPg} をペアとする *)
    Module[{bestPg = bestPage[[1]], hasPairContext},
      (* bestPg が何らかのペアに関与しているか確認 *)
      hasPairContext = Length[Select[pairScores,
        #[[1]] === bestPg || #[[3]] === bestPg &]] > 0;
      If[hasPairContext && bestPg > 1,
        $pdfIndexAsyncContext["lastPairPages"] = {bestPg - 1, bestPg},
        $pdfIndexAsyncContext["lastPairPages"] = None];
      bestPg]
  ];

(* ページスコアリング: 稀少度 × 共起重視。見出し位置は考慮しない（TOCが担当） *)
iScorePagesByProximity[pages_List, terms_List] :=
  Module[{termPageCounts},
    (* ターム出現ページ数を事前集計: 稀少なタームほど高ウェイト *)
    termPageCounts = Association@Table[
      t -> Length[Select[pages,
        StringContainsQ[Lookup[#, "text", ""], t, IgnoreCase -> True] &]],
      {t, terms}];
    Map[
      Module[{text = Lookup[#, "text", ""], pg = Lookup[#, "page", 0],
              positions, matchedTerms, sc = 0, proxBonus = 0},
        positions = Association[
          # -> Quiet @ Check[
            StringPosition[text, #, 1],
            {}] & /@ terms];
        matchedTerms = Select[terms, Length[positions[#]] > 0 &];
        (* 基本スコア: ターム長 × 稀少度 *)
        Do[
          Module[{rarity = 1.0 + 10.0 / Max[Lookup[termPageCounts, t, 1], 1]},
            sc += StringLength[t] * rarity],
          {t, matchedTerms}];

        (* === 共起ボーナス (最重要) ===
           複数のクエリタームが同一ページに共起 → 大きなボーナス
           1ターム: ボーナスなし (ベーススコアのみ)
           2ターム: ×3 + 近接性
           全ターム: ×5 + 近接性 *)
        If[Length[matchedTerms] >= 2,
          Module[{firstPositions, minSpan, coocBonus},
            firstPositions = positions[#][[1, 1]] & /@ matchedTerms;
            minSpan = Max[firstPositions] - Min[firstPositions];
            (* 近接性: 近いほど高い *)
            proxBonus = 100.0 / (1.0 + minSpan / 100.0) * Length[matchedTerms];
            (* 共起倍率: 全ターム一致ならさらにボーナス *)
            coocBonus = If[Length[matchedTerms] === Length[terms],
              sc * 3.0,  (* 全ターム: ベーススコアの3倍を追加 *)
              sc * 1.0]; (* 部分一致: ベーススコアの1倍を追加 *)
            sc += coocBonus]];

        {pg, sc + proxBonus}] &,
      pages]];

(* WL Import フォールバックでページ検索 *)
iSearchPDFPagesWL[pdfPath_String, terms_List] :=
  Module[{pageCount, pages = {}, text},
    pageCount = Quiet @ Check[Import[pdfPath, {"PDF", "PageCount"}], 0];
    If[!IntegerQ[pageCount] || pageCount === 0, Return[$Failed]];
    Do[
      text = Quiet @ Check[Import[pdfPath, {"Plaintext", i}], ""];
      If[!StringQ[text], text = ""];
      AppendTo[pages, <|"page" -> i, "text" -> StringTake[text, UpTo[5000]]|>],
      {i, pageCount}];
    Module[{scores, bestPage},
      scores = iScorePagesByProximity[pages, terms];
      scores = Select[scores, #[[2]] > 0 &];
      If[Length[scores] > 0,
        bestPage = First[SortBy[scores, -#[[2]] &]];
        bestPage[[1]],
        $Failed]]
  ];

(* クエリにマッチするページ番号を検索 *)
PDFIndex`pdfFindPage[query_String, collection_String:"default"] :=
  Module[{pdfPath, pageNum},
    pdfPath = iGetDocSourcePath[collection];
    If[pdfPath === None || !FileExistsQ[pdfPath],
      Print["\[WarningSign] PDF\:30d5\:30a1\:30a4\:30eb\:304c\:898b\:3064\:304b\:308a\:307e\:305b\:3093"];
      Return[$Failed]];
    Print["  PDF\:30da\:30fc\:30b8\:3092\:691c\:7d22\:4e2d..."];
    pageNum = iSearchPDFPagesWithCollection[pdfPath, query, collection];
    If[IntegerQ[pageNum],
      Print["  \:2192 \:30da\:30fc\:30b8 " <> ToString[pageNum] <> " \:306b\:30de\:30c3\:30c1"];
      pageNum,
      (* フォールバック: チャンク位置から粗推定 *)
      Module[{raw, chunkIdx, est},
        raw = iPdfSearchRaw[query, 1, collection, None, None];
        chunkIdx = If[ListQ[raw] && Length[raw] > 0,
          Lookup[First[raw], "globalIdx", 1], 1];
        est = iEstimatePageNum[chunkIdx, collection];
        Print["  \:2192 \:63a8\:5b9a\:30da\:30fc\:30b8 " <> ToString[est] <>
          " (\:30c1\:30e3\:30f3\:30af#" <> ToString[chunkIdx] <> " \:304b\:3089\:306e\:7c97\:63a8\:5b9a)"];
        est]]
  ];

(* PDFページを画像として表示 *)
PDFIndex`pdfShowPage[pageNum_Integer, collection_String:"default",
    mode_String:"display"] :=
  Module[{pdfPath, img, imgFile},
    pdfPath = iGetDocSourcePath[collection];
    If[pdfPath === None || !FileExistsQ[pdfPath],
      Print["\[WarningSign] PDF\:30d5\:30a1\:30a4\:30eb\:304c\:898b\:3064\:304b\:308a\:307e\:305b\:3093: " <> ToString[pdfPath]];
      Return[$Failed]];
    (* 方法1: Python/PyMuPDF でレンダリング *)
    img = iRenderPagePyMuPDF[pdfPath, pageNum];
    (* 方法2: Mathematica Import フォールバック *)
    If[img === $Failed,
      img = iRenderPageWL[pdfPath, pageNum]];
    If[img === $Failed,
      Print["\[WarningSign] \:30da\:30fc\:30b8 " <> ToString[pageNum] <> " \:306e\:30ec\:30f3\:30c0\:30ea\:30f3\:30b0\:306b\:5931\:6557"];
      Return[$Failed]];
    If[mode === "file",
      imgFile = FileNameJoin[{$TemporaryDirectory,
        "pdfpage_" <> ToString[pageNum] <> "_" <>
        IntegerString[Round[AbsoluteTime[] * 1000]] <> ".png"}];
      Export[imgFile, img, "PNG"];
      imgFile,
      (* ノートブックに表示 *)
      CellPrint[Cell[BoxData[ToBoxes[
        Column[{
          Style["PDF \:30da\:30fc\:30b8 " <> ToString[pageNum], Bold, 12],
          Show[img, ImageSize -> 600]
        }]]],
        "Output"]];
      img]
  ];

(* Python/PyMuPDF でPDFページをレンダリング *)
iRenderPagePyMuPDF[pdfPath_String, pageNum_Integer] :=
  Module[{escapedPath, imgFile, pyCode, result},
    escapedPath = StringReplace[pdfPath, "\\" -> "/"];
    imgFile = FileNameJoin[{$TemporaryDirectory,
      "pdfrender_" <> IntegerString[Round[AbsoluteTime[] * 1000]] <> ".png"}];
    pyCode = "
import fitz
doc = fitz.open(r'" <> escapedPath <> "')
page = doc[" <> ToString[pageNum - 1] <> "]
pix = page.get_pixmap(dpi=150)
pix.save(r'" <> StringReplace[imgFile, "\\" -> "/"] <> "')
doc.close()
'done'
";
    result = Quiet @ Check[ExternalEvaluate["Python", pyCode], $Failed];
    If[FileExistsQ[imgFile],
      Quiet @ Check[Import[imgFile, "PNG"], $Failed],
      $Failed]
  ];

(* Mathematica Import でPDFページをレンダリング *)
iRenderPageWL[pdfPath_String, pageNum_Integer] :=
  Module[{img},
    (* 方法1: PageGraphics *)
    img = Quiet @ Check[
      Import[pdfPath, {"PageGraphics", pageNum}],
      $Failed];
    If[img =!= $Failed && Head[img] === Graphics,
      Return[Rasterize[img, ImageResolution -> 150]]];
    (* 方法2: ImageList *)
    img = Quiet @ Check[
      Import[pdfPath, {"ImageList", pageNum}],
      $Failed];
    If[img =!= $Failed && Head[img] === Image, Return[img]];
    $Failed
  ];

(* 検索 + ページ表示のワンショット関数
   表がページをまたぐ場合、前ページ(表ヘッダ)も自動表示 *)
PDFIndex`pdfShowPage[query_String, collection_String:"default"] :=
  Module[{pageNum, pairPages},
    pageNum = PDFIndex`pdfFindPage[query, collection];
    If[!IntegerQ[pageNum], Return[$Failed]];
    (* ペアページ情報があれば前ページも表示 *)
    pairPages = Lookup[$pdfIndexAsyncContext, "lastPairPages", None];
    If[ListQ[pairPages] && Length[pairPages] === 2 && pairPages[[2]] === pageNum,
      Print["  \:8868\:304c\:30da\:30fc\:30b8\:3092\:307e\:305f\:3050\:305f\:3081 p." <>
        ToString[pairPages[[1]]] <> "-" <> ToString[pairPages[[2]]] <> " \:3092\:8868\:793a"];
      PDFIndex`pdfShowPage[pairPages[[1]], collection];
      PDFIndex`pdfShowPage[pairPages[[2]], collection],
      PDFIndex`pdfShowPage[pageNum, collection]]
  ] /; StringQ[query];

(* ============================================================ *)
(* インタラクティブ検索UI                                        *)
(* ============================================================ *)

Options[PDFIndex`pdfSearchUI] = {
  Collection -> "default"
};

PDFIndex`pdfSearchUI[query_String, n_Integer:10, opts:OptionsPattern[]] :=
  Module[{collection, raw, nb, grid, headerRow, dataRows, queryTerms},
    collection = OptionValue[PDFIndex`pdfSearchUI, {opts}, Collection];
    raw = iPdfSearchRaw[query, n, collection, None, None];
    If[!ListQ[raw] || Length[raw] === 0,
      Print["\:691c\:7d22\:7d50\:679c\:306a\:3057"];
      Return[]];

    nb = Quiet @ Check[EvaluationNotebook[], InputNotebook[]];
    queryTerms = iSplitQueryTerms[query];

    headerRow = {
      Style["#", Bold, 11],
      Style["chunk", Bold, 11],
      Style["score", Bold, 11],
      Style["\:30b3\:30f3\:30c6\:30ad\:30b9\:30c8", Bold, 11],
      Style["\:64cd\:4f5c", Bold, 11]
    };

    dataRows = MapIndexed[
      Module[{c = #1, rank = #2[[1]], pg, sc, preview, gIdx, fullText},
        pg = Lookup[c, "pageNum", "?"];
        sc = Lookup[c, "score", 0];
        gIdx = Lookup[c, "globalIdx", rank];
        fullText = If[StringQ[c["text"]], c["text"], ""];
        (* KWIC プレビュー: キーワード周辺を表示 *)
        preview = If[StringQ[c["summary"]] && c["summary"] =!= "",
          c["summary"],
          iKWIC[fullText, queryTerms, 80]];
        {
          (* 番号 *)
          Style[ToString[rank], Gray, 11],
          (* チャンク番号 *)
          Style["#" <> ToString[gIdx] <>
            If[pg =!= "?" && pg =!= 1, " p." <> ToString[pg], ""], 10],
          (* スコア *)
          Style[ToString[NumberForm[sc, {4, 3}]], 10],
          (* KWIC プレビュー: ツールチップで全文表示 *)
          Tooltip[
            Style[preview, 11],
            StringTake[fullText, UpTo[500]]],
          (* ボタン群 *)
          Row[{
            (* 全文ボタン: チャンク全文をノートブックに出力 *)
            Button[Style["\:5168\:6587", 10],
              Module[{},
                CellPrint[Cell[
                  "[\:30c1\:30e3\:30f3\:30af " <> ToString[gIdx] <>
                  " | p." <> ToString[pg] <> "]\n\n" <> fullText,
                  "Text",
                  Background -> RGBColor[0.95, 0.97, 1.0]]]],
              Appearance -> "Frameless",
              BaseStyle -> {FontColor -> RGBColor[0.1, 0.4, 0.8]}],
            Spacer[4],
            (* 前後ボタン: 前後チャンクも含めたコンテキスト表示 *)
            Button[Style["\:524d\:5f8c", 10],
              Module[{ctx, fromIdx, toIdx, idx2},
                idx2 = PDFIndex`pdfLoadIndex[collection];
                fromIdx = Max[1, gIdx - 1];
                toIdx = Min[idx2["count"], gIdx + 1];
                ctx = PDFIndex`pdfGetChunk[{fromIdx, toIdx}, collection];
                CellPrint[Cell[
                  "[\:30b3\:30f3\:30c6\:30ad\:30b9\:30c8: \:30c1\:30e3\:30f3\:30af " <>
                  ToString[fromIdx] <> "\:301c" <> ToString[toIdx] <>
                  " | p." <> ToString[pg] <> "]\n\n" <> ctx,
                  "Text",
                  Background -> RGBColor[0.95, 1.0, 0.95]]]],
              Appearance -> "Frameless",
              BaseStyle -> {FontColor -> RGBColor[0.1, 0.6, 0.2]}],
            Spacer[4],
            (* 質問ボタン: このチャンクを元に ClaudeQuery で質問
               Fallback -> False (デフォルト) で課金API不使用 *)
            Button[Style["\:8cea\:554f", 10],
              Module[{qPrompt},
                qPrompt = "\:4ee5\:4e0b\:306e\:6587\:66f8\:306e\:62bd\:51fa\:30c6\:30ad\:30b9\:30c8\:304b\:3089\:3001\:300c" <> query <>
                  "\:300d\:306b\:56de\:7b54\:3057\:3066\:304f\:3060\:3055\:3044\:3002\n\n" <>
                  "[\:30da\:30fc\:30b8 " <> ToString[pg] <> "]\n" <> fullText;
                If[Length[Names["ClaudeCode`ClaudeQuery"]] > 0,
                  ClaudeCode`ClaudeQuery[qPrompt],
                  CellPrint[Cell[qPrompt, "Text"]]]],
              Appearance -> "Frameless",
              BaseStyle -> {FontColor -> RGBColor[0.7, 0.3, 0.0]}],
            Spacer[4],
            (* ページボタン: PDFの全ページを直接検索して該当ページを画像表示 *)
            Button[Style["\:30da\:30fc\:30b8", 10],
              Module[{foundPage, pdfPath, pairPages},
                pdfPath = iGetDocSourcePath[collection];
                Print[Style["  PDF\:30da\:30fc\:30b8\:3092\:691c\:7d22\:4e2d...", Italic, Gray]];
                foundPage = iSearchPDFPagesWithCollection[pdfPath, query, collection];
                If[IntegerQ[foundPage],
                  Print["  \:2192 \:30da\:30fc\:30b8 " <> ToString[foundPage]];
                  (* ペアページ(表ヘッダ+本体)があれば両方表示 *)
                  pairPages = Lookup[$pdfIndexAsyncContext, "lastPairPages", None];
                  If[ListQ[pairPages] && pairPages[[2]] === foundPage,
                    PDFIndex`pdfShowPage[pairPages[[1]], collection];
                    PDFIndex`pdfShowPage[pairPages[[2]], collection],
                    PDFIndex`pdfShowPage[foundPage, collection]],
                  Print["  \[WarningSign] \:30da\:30fc\:30b8\:304c\:898b\:3064\:304b\:308a\:307e\:305b\:3093\:3067\:3057\:305f"]]],
              Appearance -> "Frameless",
              BaseStyle -> {FontColor -> RGBColor[0.5, 0.0, 0.5]}]
          }, Spacer[2]]
        }] &,
      raw];

    (* Grid で整形表示 *)
    Print[Style["PDF\:691c\:7d22: \"" <> query <> "\" (" <>
      ToString[Length[raw]] <> "\:4ef6)", Bold, 13]];
    Grid[
      Prepend[dataRows, headerRow],
      Alignment -> {{Left, Left, Right, Left, Left}},
      Dividers -> {None, {2 -> GrayLevel[0.7]}},
      Spacings -> {1, 0.8},
      ItemSize -> {{2, 5, 4, {50, Automatic}, Automatic}},
      Background -> {None, {1 -> GrayLevel[0.95]}}]
  ];

Options[PDFIndex`pdfSearchForLLM] = {
  MaxItems -> 20,
  Collection -> "default",
  IncludeFullText -> False
};

PDFIndex`pdfSearchForLLM[query_String, opts:OptionsPattern[]] :=
  Module[{maxItems, collection, includeFullText,
          data, expanded, pubChunks, privChunks,
          privacyThreshold, pubPrompt, privPrompt, i = 0},
    maxItems = OptionValue[PDFIndex`pdfSearchForLLM, {opts}, MaxItems];
    collection = OptionValue[PDFIndex`pdfSearchForLLM, {opts}, Collection];
    includeFullText = OptionValue[PDFIndex`pdfSearchForLLM, {opts}, IncludeFullText];

    privacyThreshold = Quiet @ Check[
      NBAccess`NBGetProviderMaxAccessLevel["claudecode"], 0.5];

    (* 検索実行: 生データ版を使用 *)
    data = iPdfSearchRaw[query, maxItems * 2, collection, None, None];
    If[!ListQ[data] || Length[data] === 0,
      Return[<|
        "public" -> <|"prompt" -> "", "count" -> 0|>,
        "private" -> <|"prompt" -> "", "count" -> 0|>|>]];

    data = Take[data, UpTo[maxItems]];

    (* === 隣接チャンク自動展開 ===
       表や一覧が複数ページにまたがる場合、ヒットしたチャンクの
       前後チャンクにも重要な情報が含まれている可能性がある。
       ヒットチャンクの ±1 を自動的にコンテキストとして追加する。 *)
    expanded = iExpandWithAdjacentChunks[data, collection];

    (* 公開/秘密に分割 *)
    pubChunks = Select[expanded, Lookup[#, "docPrivacy", 0] <= privacyThreshold &];
    privChunks = Select[expanded, Lookup[#, "docPrivacy", 0] > privacyThreshold &];

    (* プロンプト構築 *)
    pubPrompt = StringJoin[
      (i++;
       iChunkToPromptLine[#, i, includeFullText]) & /@ pubChunks];
    i = 0;
    privPrompt = StringJoin[
      (i++;
       iChunkToPromptLine[#, i, False]) & /@ privChunks];

    <|
      "public" -> <|"prompt" -> pubPrompt, "count" -> Length[pubChunks]|>,
      "private" -> <|"prompt" -> privPrompt, "count" -> Length[privChunks]|>
    |>
  ];

(* 隣接チャンク自動展開: ヒットチャンクの前後 ±1 チャンクをコンテキストとして追加。
   表や一覧が複数ページにまたがるケースで、検索にヒットしなかった
   続きページの情報も LLM に提供する。
   重複排除済み・チャンクインデックス順にソートして返す。 *)
iExpandWithAdjacentChunks[hitChunks_List, collection_String] := Module[
  {idx, hitIndices, adjacentIndices, totalChunks, result},

  (* エラー時はヒットチャンクをそのまま返す *)
  idx = Quiet @ Check[PDFIndex`pdfLoadIndex[collection], None];
  If[!AssociationQ[idx] || idx["count"] === 0, Return[hitChunks]];
  totalChunks = Length[idx["chunks"]];
  If[totalChunks === 0, Return[hitChunks]];

  (* ヒットチャンクのインデックスを収集 *)
  hitIndices = DeleteDuplicates[
    Select[
      Lookup[#, "chunkIndex", None] & /@ hitChunks,
      IntegerQ]];
  If[Length[hitIndices] === 0, Return[hitChunks]];

  (* 前後 ±1 のインデックスを計算 *)
  adjacentIndices = DeleteDuplicates[
    Flatten[{# - 1, # + 1} & /@ hitIndices]];
  adjacentIndices = Select[adjacentIndices,
    IntegerQ[#] && 1 <= # <= totalChunks && !MemberQ[hitIndices, #] &];

  If[Length[adjacentIndices] === 0, Return[hitChunks]];

  Print["  \:96a3\:63a5\:30c1\:30e3\:30f3\:30af\:5c55\:958b: +" <> ToString[Length[adjacentIndices]] <> "\:4ef6"];

  (* 隣接チャンクをロードしてメタデータ付加 *)
  result = Quiet @ Check[
    Join[hitChunks,
      Map[
        Module[{c, docMeta},
          c = idx["chunks"][[#]];
          docMeta = Quiet @ Check[iGetDocMetaForChunk[c, idx["docs"]], <||>];
          Join[c, <|
            "chunkIndex" -> #,
            "isAdjacentContext" -> True,
            "docTitle" -> If[AssociationQ[docMeta], Lookup[docMeta, "title", ""], ""],
            "docPrivacy" -> If[AssociationQ[docMeta], Lookup[docMeta, "privacy", 0.0], 0.0],
            "score" -> 0.0|>]] &,
        adjacentIndices]],
    hitChunks];

  (* チャンクインデックス順にソート *)
  SortBy[result, Lookup[#, "chunkIndex", 9999] &]
];

iChunkToPromptLine[chunk_Association, idx_Integer, includeFullText_:False] :=
  Module[{line, isContext = TrueQ[Lookup[chunk, "isAdjacentContext", False]],
          isTable = TrueQ[Lookup[chunk, "isTable", False]],
          isFigure = TrueQ[Lookup[chunk, "isFigure", False]]},
    line = "#" <> ToString[idx] <>
      If[isContext, " [context]", ""] <>
      If[isTable, " [TABLE]", ""] <>
      If[isFigure, " [FIGURE]", ""] <>
      " [page:" <> ToString[Lookup[chunk, "pageNum", "?"]] <>
      If[IntegerQ[Lookup[chunk, "endPageNum", None]],
        "-" <> ToString[chunk["endPageNum"]], ""] <>
      "] [doc:" <> If[StringQ[chunk["docTitle"]],
        StringTake[chunk["docTitle"], UpTo[30]], "?"] <>
      "]\n";
    (* 表チャンク: キャプション + 全表データを常に含める *)
    If[isTable,
      line = line <>
        "  TableCaption: " <>
        If[StringQ[Lookup[chunk, "tableCaption", ""]], chunk["tableCaption"], ""] <>
        "\n";
      If[StringQ[chunk["text"]],
        line = line <> "  TableData:\n" <>
          StringTake[chunk["text"], UpTo[4000]] <> "\n"];
      Return[line <> "\n"]];
    (* 図チャンク: キャプション + 説明を常に含める *)
    If[isFigure,
      line = line <>
        "  FigureCaption: " <>
        If[StringQ[Lookup[chunk, "figureCaption", ""]], chunk["figureCaption"], ""] <>
        "\n";
      If[StringQ[chunk["text"]],
        line = line <> "  Description: " <> chunk["text"] <> "\n"];
      Return[line <> "\n"]];
    (* 通常チャンク *)
    line = line <>
      "  Summary: " <> If[StringQ[chunk["summary"]], chunk["summary"], ""] <> "\n" <>
      "  Entities: " <> If[StringQ[chunk["entities"]], chunk["entities"], ""] <> "\n";
    (* 隣接コンテキストチャンクは常にテキストを含める *)
    If[(TrueQ[includeFullText] || isContext) && StringQ[chunk["text"]],
      line = line <> "  Text: " <> StringTake[chunk["text"], UpTo[1500]] <> "\n"];
    line <> "\n"
  ];

(* ============================================================ *)
(* 高レベル問い合わせ: pdfAskLLM                                  *)
(* ============================================================ *)

Options[PDFIndex`pdfAskLLM] = {
  Collection -> "default",
  MaxItems -> 20,
  IncludeFullText -> Automatic
};

PDFIndex`pdfAskLLM[question_String, opts:OptionsPattern[]] :=
  Module[{collection, maxItems, includeFullText,
          searchResult, pubCount, privCount,
          pubPrompt, privPrompt,
          pubResult = "", privResult = "", finalResult,
          nb},
    collection = OptionValue[PDFIndex`pdfAskLLM, {opts}, Collection];
    maxItems = OptionValue[PDFIndex`pdfAskLLM, {opts}, MaxItems];
    includeFullText = OptionValue[PDFIndex`pdfAskLLM, {opts}, IncludeFullText];
    If[includeFullText === Automatic, includeFullText = True];

    (* 検索 *)
    searchResult = PDFIndex`pdfSearchForLLM[question,
      MaxItems -> maxItems,
      Collection -> collection,
      IncludeFullText -> includeFullText];

    pubCount = searchResult["public"]["count"];
    privCount = searchResult["private"]["count"];
    pubPrompt = searchResult["public"]["prompt"];
    privPrompt = searchResult["private"]["prompt"];

    Print["[pdfAskLLM] \:691c\:7d22\:7d50\:679c: \:516c\:958b " <> ToString[pubCount] <>
      "\:4ef6, \:79d8\:5bc6 " <> ToString[privCount] <> "\:4ef6"];

    (* 公開分: $ClaudeDocModel (Sonnet) で高速回答 *)
    If[pubCount > 0,
      Module[{docModel = If[StringQ[ClaudeCode`$ClaudeDocModel] &&
                             ClaudeCode`$ClaudeDocModel =!= "",
                ClaudeCode`$ClaudeDocModel, ""]},
        Print["  LLM\:306b\:554f\:3044\:5408\:308f\:305b\:4e2d..." <>
          If[docModel =!= "", " (Model: " <> docModel <> ")", ""]];
        pubResult = Quiet @ Check[
          iQueryCloudLLM[
            "\:4ee5\:4e0b\:306ePDF\:6587\:66f8\:306e\:62bd\:51fa\:5185\:5bb9\:304b\:3089\:3001\:300c" <> question <>
            "\:300d\:306b\:95a2\:9023\:3059\:308b\:60c5\:5831\:3092\:65e5\:672c\:8a9e\:3067\:307e\:3068\:3081\:3066\:304f\:3060\:3055\:3044\:3002\n" <>
            "\:5404\:30c1\:30e3\:30f3\:30af\:304b\:3089\:91cd\:8981\:306a\:60c5\:5831\:3092\:62bd\:51fa\:3057\:3001\:51fa\:5178\:30da\:30fc\:30b8\:756a\:53f7\:3082\:660e\:8a18\:3057\:3066\:304f\:3060\:3055\:3044\:3002\n" <>
            "\:91cd\:8981: [context] \:4ed8\:304d\:30c1\:30e3\:30f3\:30af\:306f\:30d2\:30c3\:30c8\:30c1\:30e3\:30f3\:30af\:306e\:524d\:5f8c\:30da\:30fc\:30b8\:3067\:3059\:3002" <>
            "\:8868\:3084\:4e00\:89a7\:304c\:8907\:6570\:30da\:30fc\:30b8\:306b\:307e\:305f\:304c\:308b\:5834\:5408\:304c\:3042\:308b\:306e\:3067\:3001" <>
            "[context] \:30c1\:30e3\:30f3\:30af\:306e\:60c5\:5831\:3082\:5fc5\:305a\:78ba\:8a8d\:3057\:3066\:304f\:3060\:3055\:3044\:3002\n" <>
            "\:51fa\:529b\:306f Markdown \:5f62\:5f0f\:3067\:3002\n\n" <> pubPrompt,
            docModel],
          ""]]];

    (* 秘密分: ローカル LLM *)
    If[privCount > 0,
      Print["  \:30ed\:30fc\:30ab\:30eb LLM ($ClaudePrivateModel) \:306b\:554f\:3044\:5408\:308f\:305b\:4e2d..."];
      privResult = Quiet @ Check[
        iQueryLocalLLM[
          "\:4ee5\:4e0b\:306ePDF\:6587\:66f8\:306e\:62bd\:51fa\:5185\:5bb9\:304b\:3089\:3001\:300c" <> question <>
          "\:300d\:306b\:95a2\:9023\:3059\:308b\:60c5\:5831\:3092\:65e5\:672c\:8a9e\:3067\:307e\:3068\:3081\:3066\:304f\:3060\:3055\:3044\:3002\n\n" <> privPrompt],
        ""]];

    (* 結果統合 *)
    finalResult = "";
    If[StringQ[pubResult] && pubResult =!= "",
      finalResult = finalResult <> pubResult];
    If[StringQ[privResult] && privResult =!= "",
      finalResult = finalResult <>
        If[finalResult =!= "", "\n\n---\n\n", ""] <>
        "\:3010\:79d8\:5bc6\:60c5\:5831\:3011\n" <> privResult];

    (* ノートブックへの出力: NBAccess 経由 *)
    If[StringLength[finalResult] > 0,
      If[Length[Names["NBAccess`NBWriteCell"]] > 0,
        (* NBAccess 利用可能: claudecode.wl のルールに準拠 *)
        nb = Quiet @ Check[EvaluationNotebook[], InputNotebook[]];
        If[MatchQ[nb, _NotebookObject],
          NBAccess`NBWriteCell[nb, finalResult, "Text"]],
        (* NBAccess なし: 直接書き込み *)
        nb = Quiet @ Check[EvaluationNotebook[], InputNotebook[]];
        If[MatchQ[nb, _NotebookObject],
          Quiet[SelectionMove[nb, After, Cell]];
          NotebookWrite[nb, Cell[finalResult, "Text"], After]]]];

    finalResult
  ];

(* ============================================================ *)
(* 再インデクシング                                              *)
(* ============================================================ *)

PDFIndex`pdfReindex[collection_String:"default"] :=
  Module[{docs, docIds},
    docs = iLoadCollectionDocs[collection];
    If[Length[docs] === 0,
      Print["\:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:306b\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:304c\:3042\:308a\:307e\:305b\:3093: " <> collection];
      Return[{}]];
    Print["[pdfReindex] " <> ToString[Length[docs]] <> " \:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:3092\:518d\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:3057\:307e\:3059"];
    docIds = Table[
      Module[{doc = docs[[i]], path},
        path = doc["sourcePath"];
        Print["\n--- " <> ToString[i] <> "/" <> ToString[Length[docs]] <>
          ": " <> doc["title"] <> " ---"];
        Quiet @ Check[
          PDFIndex`pdfIndex[path,
            Privacy -> doc["privacy"],
            Keywords -> Lookup[doc, "keywords", {}],
            Title -> doc["title"],
            Collection -> collection,
            ForceReindex -> True],
          $Failed]],
      {i, Length[docs]}];
    $pdfIndexCache = KeyDrop[$pdfIndexCache, collection];
    Select[docIds, AssociationQ]
  ];

(* ============================================================ *)
(* プリフライトチェック                                          *)
(* ============================================================ *)

PDFIndex`pdfPreflightCheck[] := Module[{pdfOK = False, llmOK = False, embOK = False},
  Print["\:30d7\:30ea\:30d5\:30e9\:30a4\:30c8\:30c1\:30a7\:30c3\:30af..."];
  (* PDF 抽出テスト *)
  Module[{testResult},
    testResult = Quiet @ Check[
      ExternalEvaluate["Python", "import fitz; print('PyMuPDF OK')"],
      $Failed];
    If[testResult =!= $Failed,
      Print["  \:2714 PDF\:62bd\:51fa (PyMuPDF): OK"];
      pdfOK = True,
      testResult = Quiet @ Check[
        ExternalEvaluate["Python", "import pdfplumber; print('pdfplumber OK')"],
        $Failed];
      If[testResult =!= $Failed,
        Print["  \:2714 PDF\:62bd\:51fa (pdfplumber): OK"];
        pdfOK = True,
        Print["  \:26a0 PDF\:62bd\:51fa: Python\:30e9\:30a4\:30d6\:30e9\:30ea\:306a\:3057\:3002Mathematica Import \:3092\:4f7f\:7528\:3057\:307e\:3059\:3002"];
        pdfOK = True (* WL fallback is always available *)]]];

  (* LLM テスト *)
  Module[{llmResult},
    llmResult = Quiet @ Check[iQueryLocalLLM["\:300c\:30c6\:30b9\:30c8\:300d\:3068\:3060\:3051\:51fa\:529b\:305b\:3088\:3002"], $Failed];
    If[StringQ[llmResult] && StringLength[llmResult] > 0,
      Print["  \:2714 LLM (iQueryLocalLLM): OK"];
      llmOK = True,
      Print["  \:2718 LLM (iQueryLocalLLM): \:5fdc\:7b54\:306a\:3057\:307e\:305f\:306f\:30a8\:30e9\:30fc"]]];

  (* Embedding テスト *)
  Module[{embResult},
    iCreateEmbeddingSession[];
    embResult = Quiet @ Check[iCreateEmbeddings[{"\:30c6\:30b9\:30c8"}], $Failed];
    If[ListQ[embResult] && Length[embResult] > 0 && ListQ[embResult[[1]]] && Length[embResult[[1]]] > 100,
      Print["  \:2714 Embedding: OK"];
      embOK = True,
      Print["  \:2718 Embedding: \:5fdc\:7b54\:306a\:3057\:307e\:305f\:306f\:30a8\:30e9\:30fc"]]];

  If[pdfOK && llmOK && embOK,
    Print[Style["\:30d7\:30ea\:30d5\:30e9\:30a4\:30c8\:30c1\:30a7\:30c3\:30af OK", Bold]];
    True,
    Print[Style["\:30d7\:30ea\:30d5\:30e9\:30a4\:30c8\:30c1\:30a7\:30c3\:30af\:5931\:6557\:3002\:4e0a\:8a18\:3092\:78ba\:8a8d\:3057\:3066\:304f\:3060\:3055\:3044\:3002", Red, Bold]];
    False]
];

(* ============================================================ *)
(* ステータス表示                                                *)
(* ============================================================ *)

PDFIndex`pdfStatus[] := Module[{collections, total = 0},
  collections = PDFIndex`pdfListCollections[];
  Print[Style["\:25b6 PDFIndex \:30b9\:30c6\:30fc\:30bf\:30b9", Blue, Bold, 14]];
  Print["  \:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:6570: " <> ToString[Length[collections]]];
  Do[
    Module[{docs = iLoadCollectionDocs[c], chunks = iLoadCollectionChunks[c]},
      Print["  " <> c <> ": " <> ToString[Length[docs]] <>
        " docs, " <> ToString[Length[chunks]] <> " chunks"];
      total += Length[chunks]],
    {c, collections}];
  Print["  \:7dcf\:30c1\:30e3\:30f3\:30af\:6570: " <> ToString[total]];
  Print["  \:30d9\:30fc\:30b9\:30c7\:30a3\:30ec\:30af\:30c8\:30ea: " <> PDFIndex`$pdfIndexBaseDir];
  Print["  \:30a2\:30bf\:30c3\:30c1\:30c7\:30a3\:30ec\:30af\:30c8\:30ea: " <> PDFIndex`$pdfIndexAttachDir];
];

(* ============================================================ *)
(* Web用画像ヘルパー                                             *)
(* ============================================================ *)

(* Web用: 1回の ExternalEvaluate で複数ページを PNG レンダリング → base64 Association。
   ScheduledTask のステージ2で呼ばれる。このティックでは唯一の
   ExternalEvaluate 呼び出しとなるためセッション衝突しない。
   戻り値: <|pageNum1 -> "base64...", pageNum2 -> "base64...", ...|> *)
(* Web用: ExternalEvaluate 1回で全ページを base64 として直接返す。
   ファイル I/O なし — Python 内で base64 エンコードして戻り値で受け取る。
   戻り値: <|pageNum1 -> "base64...", ...|> *)
iRenderPagesBase64[pdfPath_String, pageNums_List] := Module[
  {escapedPath, pyCode, result, results = <||>},
  escapedPath = StringReplace[pdfPath, "\\" -> "/"];
  (* Python で base64 を直接生成して辞書で返す *)
  (* 72 DPI → PIL で JPEG 変換。PIL なければ 48 DPI PNG フォールバック *)
  pyCode = StringJoin[
    "import fitz, base64\n",
    "doc = fitz.open(r'", escapedPath, "')\n",
    "result = {}\n",
    "for pg in [", StringRiffle[ToString /@ pageNums, ","], "]:\n",
    "    pix = doc[pg-1].get_pixmap(dpi=72)\n",
    "    try:\n",
    "        from PIL import Image\n",
    "        import io\n",
    "        img = Image.frombytes('RGB', [pix.width, pix.height], pix.samples)\n",
    "        buf = io.BytesIO()\n",
    "        img.save(buf, format='JPEG', quality=50)\n",
    "        result[pg] = base64.b64encode(buf.getvalue()).decode('ascii')\n",
    "    except:\n",
    "        pix2 = doc[pg-1].get_pixmap(dpi=48)\n",
    "        result[pg] = base64.b64encode(pix2.tobytes('png')).decode('ascii')\n",
    "doc.close()\n",
    "result"];
  result = Quiet @ Check[ExternalEvaluate["Python", pyCode], $Failed];
  Print["  [pdfrender] ExternalEvaluate type: " <> ToString[Head[result]]];
  (* 結果解析: Python dict → WL Association *)
  If[AssociationQ[result],
    Do[
      Module[{key = ToString[pg], b64},
        b64 = Lookup[result, key, Lookup[result, pg, None]];
        If[StringQ[b64] && StringLength[b64] > 100,
          results[pg] = b64]],
      {pg, pageNums}]];
  (* フォールバック: Mathematica Import *)
  If[Length[results] === 0,
    Print["  [pdfrender] Fallback: Mathematica Import"];
    Do[
      Module[{img, tmpFile, bytes},
        img = Quiet @ Check[Import[pdfPath, {"PageGraphics", pg}], $Failed];
        If[img =!= $Failed,
          tmpFile = FileNameJoin[{$TemporaryDirectory,
            "pdfwl_" <> ToString[pg] <> ".png"}];
          Quiet @ Check[Export[tmpFile,
            Rasterize[img, ImageResolution -> 72], "PNG"], $Failed];
          If[FileExistsQ[tmpFile],
            bytes = ByteArray[BinaryReadList[tmpFile]];
            Quiet[DeleteFile[tmpFile]];
            If[Length[bytes] > 0,
              results[pg] = BaseEncode[bytes]]]]],
      {pg, pageNums}]];
  Print["  [pdfrender] Results: " <>
    StringRiffle[
      (ToString[#] <> "=" <>
        If[KeyExistsQ[results, #],
          ToString[StringLength[results[#]]] <> "chars", "MISS"]) & /@
      pageNums, ", "]];
  results
];

(* ============================================================ *)
(* WebServer 統合ルート登録                                       *)
(* ============================================================ *)

(* === PDF 非同期ジョブキュー ===
   WebServer の $WebServerPendingJobs とは独立したキュー。
   /query と /pdfask, /pdfpage を並列実行可能にする。

   [rule 95-B 例外] ScheduledTask の使用理由:
   ClaudeQueryBg (URLRead) および pdfShowPage (ExternalEvaluate) は
   FrontEnd との通信を行わない純粋な HTTP / プロセス呼び出しタスク。
   SocketListen ハンドラ内での同期実行は FrontEnd ブロック
   （「動的評価の放棄」ダイアログ）を引き起こすため非同期化が必要。 *)

$PDFJobPending    = <||>;  (* jobId -> <|"type"->..., "query"->..., "collection"->..., "t0"->...|> *)
$PDFJobResults    = <||>;  (* jobId -> <|"result"->..., "elapsed"->..., "type"->...|> *)
$PDFJobProcessing = False;
$PDFJobTask       = None;
$PDFImageCache    = <||>;  (* imgId -> base64String (一時キャッシュ) *)

(* PDF ジョブプロセッサ: 0.5秒ごとにキューを確認
   pdfpage は2段階:
     ステージ1 (type="pdfpage"): 検索 → ページ番号確定 → ステージ2をキューに追加
     ステージ2 (type="pdfrender"): ExternalEvaluate でレンダリングのみ (唯一の呼び出し)
   directPage がある場合はステージ1スキップ → 直接ステージ2
   pdfask: SessionSubmit で実行 *)
iStartPDFJobProcessor[] := Module[{},
  $PDFJobProcessing = False;
  If[MatchQ[$PDFJobTask, _ScheduledTaskObject],
    Quiet[RemoveScheduledTask[$PDFJobTask]]];
  $PDFJobTask = RunScheduledTask[
    If[!TrueQ[$PDFJobProcessing] && Length[$PDFJobPending] > 0,
      Module[{jobId, jobInfo, jobType},
        jobId = First[Keys[$PDFJobPending]];
        jobInfo = $PDFJobPending[jobId];
        $PDFJobPending = KeyDrop[$PDFJobPending, jobId];
        jobType = jobInfo["type"];

        Which[
          (* === ステージ1: 検索のみ (ExternalEvaluate 1回) ===
             ページ番号を確定し、ステージ2をキューに再投入 *)
          jobType === "pdfpage",
            Module[{query, collection, pageNum, pairPages},
              query = jobInfo["query"];
              collection = Lookup[jobInfo, "collection", "default"];
              pageNum = Lookup[jobInfo, "directPage", None];
              If[!IntegerQ[pageNum],
                pageNum = Quiet @ Check[
                  PDFIndex`pdfFindPage[query, collection], None]];
              If[IntegerQ[pageNum],
                pairPages = Lookup[$pdfIndexAsyncContext, "lastPairPages", None];
                (* ステージ2をキューに追加: 次のティックで実行 *)
                $PDFJobPending[jobId] =
                  <|"type" -> "pdfrender",
                    "pageNum" -> pageNum,
                    "pairPages" -> pairPages,
                    "query" -> query,
                    "collection" -> collection,
                    "t0" -> jobInfo["t0"]|>,
                (* 検索失敗 *)
                $PDFJobResults[jobId] =
                  <|"result" -> <|"error" -> "\:30da\:30fc\:30b8\:304c\:898b\:3064\:304b\:308a\:307e\:305b\:3093\:3067\:3057\:305f"|>,
                    "elapsed" -> Round[AbsoluteTime[] - jobInfo["t0"], 0.01],
                    "type" -> "pdfpage", "query" -> query|>]],

          (* === ステージ2: レンダリングのみ (ExternalEvaluate 1回) ===
             Web版は1ページのみレンダリング (HTMLサイズ制限のため)。
             ペアページはナビゲーションボタンで個別に表示。 *)
          jobType === "pdfrender",
            Module[{result, elapsed, query, collection, pageNum, pdfPath, b64Map},
              query = Lookup[jobInfo, "query", ""];
              collection = Lookup[jobInfo, "collection", "default"];
              pageNum = jobInfo["pageNum"];
              pdfPath = iGetDocSourcePath[collection];
              result = Quiet @ Check[
                If[StringQ[pdfPath] && FileExistsQ[pdfPath],
                  b64Map = iRenderPagesBase64[pdfPath, {pageNum}];
                  <|"pageNum" -> pageNum,
                    "b64Main" -> Lookup[b64Map, pageNum, None],
                    "b64Prev" -> None,
                    "pairPages" -> None|>,
                  <|"error" -> "PDF\:30d5\:30a1\:30a4\:30eb\:304c\:898b\:3064\:304b\:308a\:307e\:305b\:3093"|>],
                <|"error" -> "Error: \:30ec\:30f3\:30c0\:30ea\:30f3\:30b0\:5931\:6557"|>];
              elapsed = Round[AbsoluteTime[] - jobInfo["t0"], 0.01];
              $PDFJobResults[jobId] =
                <|"result" -> result, "elapsed" -> elapsed,
                  "type" -> "pdfpage", "query" -> query|>],

          (* === pdfask: SessionSubmit で実行 === *)
          jobType === "pdfask",
            $PDFJobProcessing = True;
            With[{jid = jobId, ji = jobInfo},
              SessionSubmit[
                Module[{result, elapsed, query, collection, errorMsg = ""},
                  query = ji["query"];
                  collection = Lookup[ji, "collection", "default"];
                  result = Check[
                    PDFIndex`pdfAskLLM[query, Collection -> collection],
                    (* エラー捕捉: メッセージを記録 *)
                    errorMsg = "Error: pdfAskLLM \:5931\:6557";
                    $Failed];
                  If[result === $Failed || !StringQ[result],
                    Print["  [pdfask] \:30a8\:30e9\:30fc: " <> errorMsg];
                    result = If[StringLength[errorMsg] > 0, errorMsg,
                      "Error: \:30b8\:30e7\:30d6\:5b9f\:884c\:5931\:6557"]];
                  elapsed = Round[AbsoluteTime[] - ji["t0"], 0.01];
                  $PDFJobResults[jid] =
                    <|"result" -> result, "elapsed" -> elapsed,
                      "type" -> "pdfask", "query" -> query|>;
                  $PDFJobProcessing = False]]],

          True, None]]],
    0.5];
];

(* WebServer がロード済みなら検索ルートを自動登録する *)
iRegisterWebServerRoutes[] := Module[{},
  If[Length[Names["WebServer`RegisterRoute"]] === 0, Return[]];

  (* ジョブプロセッサ起動 *)
  iStartPDFJobProcessor[];

  (* ============ GET /pdfsearch?q=... (既存) ============ *)
  WebServer`RegisterRoute["/pdfsearch",
    Function[req, Module[{query, collection, results, html},
      query = Lookup[req["Query"], "q", ""];
      collection = Lookup[req["Query"], "collection", "default"];
      If[query === "",
        Return[iHTTP200PDFSearchForm[]]];
      results = Quiet @ Check[
        PDFIndex`pdfSearch[query, 20, Collection -> collection],
        Dataset[{}]];
      html = iRenderSearchResults[query, results];
      iHTTP200[html]
    ]]];

  (* ============ POST /pdfsearch/api (既存) ============ *)
  WebServer`RegisterRoute["/pdfsearch/api",
    Function[req, Module[{body, query, collection, result, json},
      body = Quiet @ Check[
        ImportByteArray[StringToByteArray[req["Body"], "UTF-8"], "RawJSON"],
        <||>];
      query = Lookup[body, "query", ""];
      collection = Lookup[body, "collection", "default"];
      If[query === "",
        Return[iHTTP400["query \:304c\:5fc5\:8981\:3067\:3059"]]];
      result = Quiet @ Check[
        PDFIndex`pdfSearchForLLM[query,
          Collection -> collection, MaxItems -> 20],
        <||>];
      json = ExportString[result, "RawJSON"];
      iHTTP200JSON[json]
    ]]];

  (* ============================================================ *)
  (* /pdfask : PDF検索 + LLM質問応答 (非同期ジョブキュー)          *)
  (* ============================================================ *)
  WebServer`RegisterRoute["/pdfask",
    Function[req, Module[{method, query, collection, pollId, jobId},
      method = req["Method"];
      query = If[method === "POST",
        Lookup[req["FormData"], "query", ""],
        Lookup[req["Query"], "q", ""]];
      collection = If[method === "POST",
        Lookup[req["FormData"], "collection", "default"],
        Lookup[req["Query"], "collection", "default"]];
      pollId = Lookup[req["Query"], "poll", ""];

      Which[
        (* ポーリング: ジョブ結果確認 *)
        method === "GET" && StringLength[pollId] > 0,
          iPDFJobPoll[pollId, "/pdfask"],

        (* POST: ジョブをキューに追加 *)
        (method === "POST" || method === "GET") && StringLength[StringTrim[query]] > 0,
          jobId = "pa" <> ToString[Floor[AbsoluteTime[] * 1000]];
          $PDFJobPending[jobId] =
            <|"type" -> "pdfask", "query" -> query,
              "collection" -> collection, "t0" -> AbsoluteTime[]|>;
          iHTTP200[iPDFHTMLPage["PDF \:8cea\:554f\:5fdc\:7b54 - \:51e6\:7406\:4e2d",
            iPDFRenderPolling[jobId, query, "/pdfask"]]],

        (* GET: フォーム表示 *)
        True,
          iHTTP200[iPDFHTMLPage["PDF \:8cea\:554f\:5fdc\:7b54",
            iPDFRenderAskForm[""]]]
      ]
    ]]];

  (* ============================================================ *)
  (* /pdfpage : PDFページ画像表示 (非同期ジョブキュー)             *)
  (* ============================================================ *)
  WebServer`RegisterRoute["/pdfpage",
    Function[req, Module[{method, query, collection, pollId, jobId, pageNum},
      method = req["Method"];
      query = If[method === "POST",
        Lookup[req["FormData"], "query", ""],
        Lookup[req["Query"], "q", ""]];
      collection = If[method === "POST",
        Lookup[req["FormData"], "collection", "default"],
        Lookup[req["Query"], "collection", "default"]];
      pollId = Lookup[req["Query"], "poll", ""];

      Which[
        (* ポーリング: ジョブ結果確認 *)
        method === "GET" && StringLength[pollId] > 0,
          iPDFJobPoll[pollId, "/pdfpage"],

        (* ページ番号直接指定: /pdfpage?p=129 *)
        method === "GET" && StringLength[Lookup[req["Query"], "p", ""]] > 0,
          pageNum = Quiet @ Check[
            ToExpression[Lookup[req["Query"], "p", "1"]], 1];
          jobId = "pp" <> ToString[Floor[AbsoluteTime[] * 1000]];
          $PDFJobPending[jobId] =
            <|"type" -> "pdfpage",
              "query" -> ("p." <> ToString[pageNum]),
              "directPage" -> pageNum,
              "collection" -> collection, "t0" -> AbsoluteTime[]|>;
          iHTTP200[iPDFHTMLPage["PDF \:30da\:30fc\:30b8 - \:51e6\:7406\:4e2d",
            iPDFRenderPolling[jobId, "p." <> ToString[pageNum], "/pdfpage"]]],

        (* クエリからページ検索 *)
        (method === "POST" || method === "GET") && StringLength[StringTrim[query]] > 0,
          jobId = "pp" <> ToString[Floor[AbsoluteTime[] * 1000]];
          $PDFJobPending[jobId] =
            <|"type" -> "pdfpage", "query" -> query,
              "collection" -> collection, "t0" -> AbsoluteTime[]|>;
          iHTTP200[iPDFHTMLPage["PDF \:30da\:30fc\:30b8 - \:51e6\:7406\:4e2d",
            iPDFRenderPolling[jobId, query, "/pdfpage"]]],

        (* GET: フォーム表示 *)
        True,
          iHTTP200[iPDFHTMLPage["PDF \:30da\:30fc\:30b8\:8868\:793a",
            iPDFRenderPageForm[""]]]
      ]
    ]]];

  (* ============================================================ *)
  (* /pdfimgdata : 画像base64データ配信 (JS遅延ロード用)           *)
  (* ============================================================ *)
  WebServer`RegisterRoute["/pdfimgdata",
    Function[req, Module[{imgId, b64},
      imgId = Lookup[req["Query"], "id", ""];
      If[StringLength[imgId] === 0,
        Return[iHTTP400["id \:304c\:5fc5\:8981\:3067\:3059"]]];
      b64 = Lookup[$PDFImageCache, imgId, None];
      If[StringQ[b64],
        (* キャッシュから削除 (1回限り) *)
        $PDFImageCache = KeyDrop[$PDFImageCache, imgId];
        (* base64 文字列をそのまま返す (Content-Type: text/plain) *)
        Module[{bodyBytes},
          bodyBytes = StringToByteArray[b64, "ISO8859-1"];
          "HTTP/1.1 200 OK\r\n" <>
          "Content-Type: text/plain; charset=ascii\r\n" <>
          "Content-Length: " <> ToString[Length[bodyBytes]] <>
          "\r\n\r\n" <> b64],
        iHTTP400["Image not found: " <> imgId]]
    ]]];

  Print["  PDFIndex WebServer \:30eb\:30fc\:30c8\:767b\:9332:"];
  Print["    GET  /pdfsearch?q=...       \:691c\:7d22\:30d5\:30a9\:30fc\:30e0 + \:7d50\:679c\:8868\:793a"];
  Print["    POST /pdfsearch/api         JSON API"];
  Print["    GET  /pdfask                \:8cea\:554f\:5fdc\:7b54\:30d5\:30a9\:30fc\:30e0 (pdfAskLLM)"];
  Print["    GET  /pdfpage?q=...         \:30da\:30fc\:30b8\:691c\:7d22\:30fb\:8868\:793a (pdfShowPage)"];
  Print["    GET  /pdfpage?p=129         \:30da\:30fc\:30b8\:756a\:53f7\:76f4\:63a5\:6307\:5b9a"];
  Print["    GET  /pdfimgdata?id=...     \:753b\:50cf\:30c7\:30fc\:30bf\:914d\:4fe1 (JS\:904e\:5ef6\:30ed\:30fc\:30c9)"];
];

(* ============================================================ *)
(* PDF Web HTML テンプレート                                      *)
(* ============================================================ *)

iPDFHTMLPage[title_String, body_String] :=
  "<!DOCTYPE html><html><head><meta charset='utf-8'><title>" <> title <>
  "</title><link rel='stylesheet' href='/style.css'></head><body>" <>
  body <> "</body></html>";

(* pdfAskLLM フォーム *)
iPDFRenderAskForm[prevQuery_String] :=
  "<h1>PDF \:8cea\:554f\:5fdc\:7b54</h1>\n" <>
  "<p style='color:#8888aa'>PDF\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:3092\:691c\:7d22\:3057\:3001LLM\:304c\:56de\:7b54\:3057\:307e\:3059\:3002</p>\n" <>
  "<form class='query-form' method='POST' action='/pdfask'\n" <>
  "  onsubmit='var b=this.querySelector(\".btn-run\");" <>
  "b.disabled=true;b.innerHTML=\"&#x23F3; \:5b9f\:884c\:4e2d...\";'>\n" <>
  "  <label class='form-label'>\:8cea\:554f</label>\n" <>
  "  <textarea name='query' class='form-textarea' rows='3'\n" <>
  "    placeholder='\:4f8b: \:60c5\:5831\:5de5\:5b66\:79d1\:306e\:5fc5\:4fee\:79d1\:76ee\:306f\:ff1f'\n" <>
  "    autofocus>" <> WebServer`Private`iHTMLEscape[prevQuery] <> "</textarea>\n" <>
  "  <div class='form-footer'>\n" <>
  "    <select name='collection' style='padding:6px;background:#1a2a40;" <>
  "color:#eee;border:1px solid #334'>\n" <>
  StringJoin[("<option value='" <> # <> "'>" <> # <> "</option>\n") & /@
    PDFIndex`pdfListCollections[]] <>
  "    </select>\n" <>
  "    <button type='submit' class='btn btn-run'>&#x1F50D; \:8cea\:554f\:3059\:308b</button>\n" <>
  "  </div>\n</form>\n" <>
  "<p style='color:#666;font-size:12px'>" <>
  "<a href='/pdfpage' style='color:#88aaff'>\:30da\:30fc\:30b8\:8868\:793a</a> | " <>
  "<a href='/pdfsearch' style='color:#88aaff'>\:691c\:7d22</a> | " <>
  "<a href='/query' style='color:#88aaff'>Claude Query</a></p>\n";

(* pdfShowPage フォーム *)
iPDFRenderPageForm[prevQuery_String] :=
  "<h1>PDF \:30da\:30fc\:30b8\:8868\:793a</h1>\n" <>
  "<p style='color:#8888aa'>PDF\:306e\:30da\:30fc\:30b8\:3092\:691c\:7d22\:3057\:3066\:753b\:50cf\:3067\:8868\:793a\:3057\:307e\:3059\:3002</p>\n" <>
  "<form class='query-form' method='POST' action='/pdfpage'\n" <>
  "  onsubmit='var b=this.querySelector(\".btn-run\");" <>
  "b.disabled=true;b.innerHTML=\"&#x23F3; \:691c\:7d22\:4e2d...\";'>\n" <>
  "  <label class='form-label'>\:691c\:7d22\:30af\:30a8\:30ea\:307e\:305f\:306f\:30da\:30fc\:30b8\:756a\:53f7</label>\n" <>
  "  <input name='query' class='form-textarea' style='min-height:auto;height:40px'\n" <>
  "    placeholder='\:4f8b: \:60c5\:5831\:5de5\:5b66\:79d1\:306e\:96e2\:6563\:6570\:5b66\:306e\:958b\:8b1b\:671f\:306f\:ff1f'\n" <>
  "    value='" <> WebServer`Private`iHTMLEscape[prevQuery] <> "' autofocus>\n" <>
  "  <div class='form-footer'>\n" <>
  "    <select name='collection' style='padding:6px;background:#1a2a40;" <>
  "color:#eee;border:1px solid #334'>\n" <>
  StringJoin[("<option value='" <> # <> "'>" <> # <> "</option>\n") & /@
    PDFIndex`pdfListCollections[]] <>
  "    </select>\n" <>
  "    <button type='submit' class='btn btn-run'>&#x1F4C4; \:30da\:30fc\:30b8\:8868\:793a</button>\n" <>
  "  </div>\n</form>\n" <>
  "<p style='color:#666;font-size:12px'>" <>
  "<a href='/pdfask' style='color:#88aaff'>\:8cea\:554f\:5fdc\:7b54</a> | " <>
  "<a href='/pdfsearch' style='color:#88aaff'>\:691c\:7d22</a> | " <>
  "<a href='/query' style='color:#88aaff'>Claude Query</a></p>\n";

(* ポーリングページ *)
iPDFRenderPolling[jobId_String, query_String, returnPath_String] :=
  "<h1>&#x23F3; \:51e6\:7406\:4e2d...</h1>\n" <>
  "<div class='query-form' style='text-align:center;padding:24px'>\n" <>
  "  <div style='font-size:18px;margin-bottom:12px'>\:691c\:7d22\:30fb\:51e6\:7406\:3057\:3066\:3044\:307e\:3059</div>\n" <>
  "  <div style='color:#8888aa;font-size:13px'>" <>
  WebServer`Private`iHTMLEscape[StringTake[query, UpTo[100]]] <> "</div>\n" <>
  "  <div style='color:#666;font-size:11px;margin-top:8px'>Job: " <> jobId <> "</div>\n" <>
  "</div>\n" <>
  "<script>setTimeout(function(){window.location.href='" <>
  returnPath <> "?poll=" <> jobId <> "';},2000);</script>\n";

(* ジョブ結果ポーリング *)
iPDFJobPoll[jobId_String, returnPath_String] :=
  If[KeyExistsQ[$PDFJobResults, jobId],
    (* 結果あり *)
    Module[{jr = $PDFJobResults[jobId], jobType, result, elapsed, query, html},
      $PDFJobResults = KeyDrop[$PDFJobResults, jobId];
      jobType = Lookup[jr, "type", ""];
      result = jr["result"];
      elapsed = jr["elapsed"];
      query = Lookup[jr, "query", ""];
      html = Switch[jobType,
        "pdfask",  iPDFRenderAskResult[query, result, elapsed, returnPath],
        "pdfpage", iPDFRenderPageResult[query, result, elapsed, returnPath],
        _, "<h1>Error</h1><p>Unknown job type</p>"];
      (* pdfpage は完全なHTMLを返す。Content-Length なし + Connection: close で
         大きな画像データでもブラウザが全データを受信するまで待つ *)
      If[jobType === "pdfpage",
        "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\n" <>
        "Connection: close\r\n\r\n" <> html,
        iHTTP200[iPDFHTMLPage["PDF - \:7d50\:679c", html]]]],
    (* まだ処理中 → 再ポーリング *)
    If[KeyExistsQ[$PDFJobPending, jobId] || TrueQ[$PDFJobProcessing],
      iHTTP200[iPDFHTMLPage["\:51e6\:7406\:4e2d...",
        "<h1>&#x23F3; \:51e6\:7406\:4e2d...</h1>" <>
        "<p style='color:#8888aa'>\:7d50\:679c\:3092\:5f85\:3063\:3066\:3044\:307e\:3059...</p>" <>
        "<script>setTimeout(function(){window.location.href='" <>
        returnPath <> "?poll=" <> jobId <> "';},2000);</script>"]],
      iHTTP200[iPDFHTMLPage["Not Found",
        "<h1>\:30b8\:30e7\:30d6\:304c\:898b\:3064\:304b\:308a\:307e\:305b\:3093</h1>" <>
        "<p>\:30b8\:30e7\:30d6 " <> jobId <> " \:306f\:671f\:9650\:5207\:308c\:307e\:305f\:306f\:5b58\:5728\:3057\:307e\:305b\:3093\:3002</p>" <>
        "<a href='" <> returnPath <> "' style='color:#88aaff'>\:623b\:308b</a>"]]]
  ];

(* pdfAskLLM 結果レンダリング *)
iPDFRenderAskResult[query_String, result_, elapsed_, returnPath_String] :=
  Module[{answer},
    answer = If[StringQ[result], result,
      If[AssociationQ[result], Lookup[result, "answer", ToString[result]],
        ToString[result]]];
    "<h1>PDF \:8cea\:554f\:5fdc\:7b54</h1>\n" <>
    "<div class='query-form'>\n" <>
    "  <div style='color:#88aaff;font-size:12px;margin-bottom:8px'>\:8cea\:554f:</div>\n" <>
    "  <div style='font-size:15px;margin-bottom:16px;color:#eef'>" <>
    WebServer`Private`iHTMLEscape[query] <> "</div>\n" <>
    "  <div style='color:#88ddaa;font-size:12px;margin-bottom:8px'>\:56de\:7b54:</div>\n" <>
    "  <div style='font-size:14px;line-height:1.6;color:#eee'>" <>
    Quiet @ Check[WebServer`Private`iMarkdownToHTML[answer],
      "<pre>" <> WebServer`Private`iHTMLEscape[answer] <> "</pre>"] <>
    "</div>\n" <>
    "  <div style='color:#666;font-size:11px;margin-top:12px'>" <>
    ToString[elapsed] <> " \:79d2</div>\n" <>
    "</div>\n" <>
    "<form class='query-form' method='POST' action='" <> returnPath <> "'>\n" <>
    "  <textarea name='query' class='form-textarea' rows='2' autofocus></textarea>\n" <>
    "  <div class='form-footer'>\n" <>
    "    <select name='collection' style='padding:6px;background:#1a2a40;" <>
    "color:#eee;border:1px solid #334'>\n" <>
    StringJoin[("<option value='" <> # <> "'>" <> # <> "</option>\n") & /@
      PDFIndex`pdfListCollections[]] <>
    "    </select>\n" <>
    "    <button type='submit' class='btn btn-run'>&#x1F50D; \:6b21\:306e\:8cea\:554f</button>\n" <>
    "  </div>\n</form>\n"
  ];

(* pdfShowPage 結果レンダリング:
   超軽量HTML: CSS外部ファイルなし、直接インラインbase64。
   36 DPI で ~30KB base64、HTML全体 ~35KB。
   WebServer 512B×0.05s = ~3.4秒で送信完了。 *)
iPDFRenderPageResult[query_String, result_, elapsed_, returnPath_String] :=
  Module[{pageNum, b64Main, navHtml = "", imgHtml = ""},
    If[!AssociationQ[result],
      Return["<html><body><h1>Error</h1><p>" <> ToString[result] <>
        "</p><a href='/pdfpage'>Back</a></body></html>"]];
    If[KeyExistsQ[result, "error"],
      Return["<html><body><h1>Error</h1><p>" <> result["error"] <>
        "</p><a href='/pdfpage'>Back</a></body></html>"]];

    pageNum = Lookup[result, "pageNum", 0];
    b64Main = Lookup[result, "b64Main", None];

    (* ナビゲーション *)
    navHtml = "<div style='margin:8px 0'>";
    If[IntegerQ[pageNum] && pageNum > 1,
      navHtml = navHtml <>
        "<a href='/pdfpage?p=" <> ToString[pageNum - 1] <>
        "' style='color:#fff;background:#234;padding:6px 12px;" <>
        "border-radius:4px;text-decoration:none;margin-right:6px'>" <>
        "&lt; p." <> ToString[pageNum - 1] <> "</a>"];
    If[IntegerQ[pageNum],
      navHtml = navHtml <>
        "<a href='/pdfpage?p=" <> ToString[pageNum + 1] <>
        "' style='color:#fff;background:#234;padding:6px 12px;" <>
        "border-radius:4px;text-decoration:none;margin-right:6px'>" <>
        "p." <> ToString[pageNum + 1] <> " &gt;</a>" <>
        "<a href='/pdfpage' style='color:#8af;margin-left:12px'>\:65b0\:898f\:691c\:7d22</a>" <>
        " <a href='/pdfask' style='color:#8af;margin-left:8px'>\:8cea\:554f</a>"];
    navHtml = navHtml <> "</div>\n";

    (* 画像 *)
    If[StringQ[b64Main],
      Module[{mimeType = If[StringStartsQ[b64Main, "/9j/"],
          "image/jpeg", "image/png"]},
        imgHtml = "<img src='data:" <> mimeType <> ";base64," <> b64Main <>
          "' style='max-width:100%'>\n"],
      imgHtml = "<p style='color:red'>\:753b\:50cf\:306e\:751f\:6210\:306b\:5931\:6557</p>"];

    (* 超軽量HTML: style.cssを参照しない *)
    "<!DOCTYPE html><html><head><meta charset='utf-8'>" <>
    "<title>PDF p." <> ToString[pageNum] <> "</title></head>" <>
    "<body style='background:#0d1b2a;color:#eee;font-family:sans-serif;" <>
    "margin:12px'>\n" <>
    "<p style='color:#88aaff'>" <>
    WebServer`Private`iHTMLEscape[query] <>
    " \:2192 p." <> ToString[pageNum] <>
    " (" <> ToString[elapsed] <> "s)</p>\n" <>
    navHtml <>
    "<h3 style='color:#4488cc'>PDF p." <> ToString[pageNum] <> "</h3>\n" <>
    imgHtml <>
    navHtml <>
    "<div style='margin:12px 0;padding:12px;border:1px solid #334;border-radius:6px'>" <>
    "<form method='POST' action='/pdfpage' style='display:flex;gap:6px'>" <>
    "<input name='query' placeholder='\:691c\:7d22...' style='flex:1;padding:6px;" <>
    "background:#0a1525;color:#eee;border:1px solid #334;border-radius:4px'>" <>
    "<button type='submit' style='padding:6px 12px;background:#234;color:#8af;" <>
    "border:1px solid #456;border-radius:4px;cursor:pointer'>\:691c\:7d22</button></form>" <>
    "<form method='GET' action='/pdfpage' style='display:flex;gap:6px;margin-top:6px'>" <>
    "<input name='p' type='number' placeholder='p#' style='width:60px;padding:6px;" <>
    "background:#0a1525;color:#eee;border:1px solid #334;border-radius:4px'>" <>
    "<button type='submit' style='padding:6px 12px;background:#234;color:#8af;" <>
    "border:1px solid #456;border-radius:4px;cursor:pointer'>\:8868\:793a</button></form></div>" <>
    "</body></html>"
  ];

(* pdfpage 共通フォーム: 検索 + ページ番号直接指定 *)
iPDFPageFormHtml[prevQuery_String, returnPath_String] :=
  "\n<div class='query-form'>\n" <>
  "  <div style='display:flex;gap:12px;flex-wrap:wrap'>\n" <>
  "    <form method='POST' action='" <> returnPath <> "' style='flex:1;min-width:250px'>\n" <>
  "      <label class='form-label'>\:30af\:30a8\:30ea\:3067\:30da\:30fc\:30b8\:691c\:7d22</label>\n" <>
  "      <div style='display:flex;gap:6px'>\n" <>
  "        <input name='query' style='flex:1;padding:8px;background:#0d1b2a;" <>
  "color:#eee;border:1px solid #334;border-radius:4px'\n" <>
  "          placeholder='\:4f8b: \:60c5\:5831\:5de5\:5b66\:79d1\:306e\:96e2\:6563\:6570\:5b66\:306e\:958b\:8b1b\:671f\:306f\:ff1f'" <>
  If[StringLength[prevQuery] > 0, " value='" <>
    WebServer`Private`iHTMLEscape[prevQuery] <> "'", ""] <> ">\n" <>
  "        <select name='collection' style='padding:6px;background:#0d1b2a;" <>
  "color:#eee;border:1px solid #334'>\n" <>
  StringJoin[("<option value='" <> # <> "'>" <> # <> "</option>\n") & /@
    PDFIndex`pdfListCollections[]] <>
  "        </select>\n" <>
  "        <button type='submit' class='btn btn-run'>&#x1F50D; \:691c\:7d22</button>\n" <>
  "      </div>\n    </form>\n" <>
  "    <form method='GET' action='" <> returnPath <> "' style='min-width:150px'>\n" <>
  "      <label class='form-label'>\:30da\:30fc\:30b8\:756a\:53f7\:76f4\:63a5\:6307\:5b9a</label>\n" <>
  "      <div style='display:flex;gap:6px'>\n" <>
  "        <input name='p' type='number' min='1' style='width:80px;padding:8px;" <>
  "background:#0d1b2a;color:#eee;border:1px solid #334;border-radius:4px'\n" <>
  "          placeholder='129'>\n" <>
  "        <button type='submit' class='btn btn-run'>&#x1F4C4; \:8868\:793a</button>\n" <>
  "      </div>\n    </form>\n" <>
  "  </div>\n" <>
  "  <p style='color:#666;font-size:12px;margin-top:10px'>" <>
  "    <a href='/pdfask' style='color:#88aaff'>\:8cea\:554f\:5fdc\:7b54</a> | " <>
  "    <a href='/pdfsearch' style='color:#88aaff'>\:691c\:7d22</a> | " <>
  "    <a href='/query' style='color:#88aaff'>Claude Query</a>" <>
  "  </p>\n</div>\n";

(* HTTP レスポンスヘルパー: Content-Length はバイト数で計算 *)
iHTTP200[body_String] := Module[{bodyBytes},
  bodyBytes = StringToByteArray[body, "UTF-8"];
  "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\n" <>
  "Content-Length: " <> ToString[Length[bodyBytes]] <>
  "\r\n\r\n" <> body];

iHTTP200JSON[json_String] := Module[{bodyBytes},
  bodyBytes = StringToByteArray[json, "UTF-8"];
  "HTTP/1.1 200 OK\r\nContent-Type: application/json; charset=utf-8\r\n" <>
  "Content-Length: " <> ToString[Length[bodyBytes]] <>
  "\r\n\r\n" <> json];

iHTTP400[msg_String] :=
  "HTTP/1.1 400 Bad Request\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n" <> msg;

(* 検索フォーム HTML *)
iHTTP200PDFSearchForm[] := iHTTP200["<!DOCTYPE html>
<html><head><meta charset='utf-8'><title>PDF Search</title>
<link rel='stylesheet' href='/style.css'>
</head><body>
<h1>PDF \:691c\:7d22</h1>
<form method='get' action='/pdfsearch'>
<input name='q' placeholder='\:691c\:7d22\:30af\:30a8\:30ea...' style='width:60%;padding:8px'>
<select name='collection'>
" <> StringJoin[("<option value='" <> # <> "'>" <> # <> "</option>\n") & /@
  PDFIndex`pdfListCollections[]] <>
"</select>
<button type='submit'>\:691c\:7d22</button>
</form></body></html>"];

(* 検索結果レンダリング *)
iRenderSearchResults[query_String, results_] := Module[{data, html},
  data = If[Head[results] === Dataset, Normal[results], results];
  If[!ListQ[data], data = {}];
  html = "<!DOCTYPE html><html><head><meta charset='utf-8'><title>PDF Search: " <>
    query <> "</title><link rel='stylesheet' href='/style.css'></head><body>" <>
    "<h1>PDF \:691c\:7d22\:7d50\:679c: " <> query <> "</h1>" <>
    "<p>" <> ToString[Length[data]] <> " \:4ef6\:306e\:30c1\:30e3\:30f3\:30af\:304c\:898b\:3064\:304b\:308a\:307e\:3057\:305f</p>";
  Do[
    Module[{c = data[[i]]},
      html = html <> "<div style='border:1px solid #ccc;margin:8px 0;padding:12px;border-radius:8px'>" <>
        "<h3>#" <> ToString[i] <>
        If[StringQ[c["docTitle"]], " - " <> c["docTitle"], ""] <>
        " (p." <> ToString[Lookup[c, "pageNum", "?"]] <> ")</h3>" <>
        "<p><b>Summary:</b> " <> If[StringQ[c["summary"]], c["summary"], ""] <> "</p>" <>
        "<p><b>Tags:</b> " <> If[StringQ[c["tags"]], c["tags"], ""] <> "</p>" <>
        "<p style='color:gray;font-size:0.85em'>" <>
        StringTake[If[StringQ[c["text"]], c["text"], ""], UpTo[200]] <>
        "...</p></div>"],
    {i, Min[Length[data], 20]}];
  html <> "</body></html>"
];

End[];

(* === WebServer ルート自動登録 === *)
PDFIndex`Private`iRegisterWebServerRoutes[];

(* === Package loaded message === *)
Print[Style["PDFIndex \:30d1\:30c3\:30b1\:30fc\:30b8\:304c\:30ed\:30fc\:30c9\:3055\:308c\:307e\:3057\:305f\:3002", Bold]];
Print["
  pdfIndex[\"path/to/file.pdf\"]                    PDF\:3092\:30a4\:30f3\:30c7\:30c3\:30af\:30b9
  pdfIndex[\"path.pdf\", Privacy -> 0.8]             \:79d8\:533f\:5ea6\:6307\:5b9a\:3067\:30a4\:30f3\:30c7\:30c3\:30af\:30b9
  pdfIndexDirectory[\"/pdf/dir\"]                    \:30c7\:30a3\:30ec\:30af\:30c8\:30ea\:4e00\:62ec
  pdfIndexURL[\"https://...pdf\"]                    URL\:304b\:3089\:30a4\:30f3\:30c7\:30c3\:30af\:30b9
  pdfSearch[\"\:30af\:30a8\:30ea\", 20]                         \:30cf\:30a4\:30d6\:30ea\:30c3\:30c9\:691c\:7d22 (Dataset)
  pdfSearchUI[\"\:30af\:30a8\:30ea\", 10]                       \:30dc\:30bf\:30f3\:4ed8\:304d UI (\:5168\:6587/\:524d\:5f8c/\:8cea\:554f/\:30da\:30fc\:30b8)
  pdfShowPage[124]                                   PDF\:30da\:30fc\:30b8\:3092\:753b\:50cf\:8868\:793a
  pdfShowPage[\"\:96e2\:6563\:6570\:5b66\"]                             \:691c\:7d22\:2192\:63a8\:5b9a\:30da\:30fc\:30b8\:3092\:8868\:793a
  pdfFindPage[\"\:96e2\:6563\:6570\:5b66\"]                             \:30da\:30fc\:30b8\:756a\:53f7\:63a8\:5b9a
  pdfGetChunk[42]                                    \:30c1\:30e3\:30f3\:30af\:5168\:6587\:53d6\:5f97
  pdfGetChunk[{40,44}]                               \:7bc4\:56f2\:6307\:5b9a\:3067\:524d\:5f8c\:53d6\:5f97
  pdfSearchForLLM[\"\:30af\:30a8\:30ea\"]                       LLM\:30d7\:30ed\:30f3\:30d7\:30c8\:7528\:691c\:7d22
  pdfAskLLM[\"\:8cea\:554f\"]                                   \:691c\:7d22+LLM\:56de\:7b54\:ff08\:516c\:958b/\:79d8\:5bc6\:5206\:96e2\:ff09
  pdfLoadIndex[\"default\"]                          \:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:30ed\:30fc\:30c9
  pdfListCollections[]                             \:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:4e00\:89a7
  pdfListDocs[]                                    \:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:4e00\:89a7
  pdfRemoveDoc[\"docId\"]                            \:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:524a\:9664
  pdfReindex[\"default\"]                            \:5168\:518d\:30a4\:30f3\:30c7\:30c3\:30af\:30b9
  pdfPreflightCheck[]                              \:52d5\:4f5c\:78ba\:8a8d
  pdfStatus[]                                      \:30b9\:30c6\:30fc\:30bf\:30b9\:8868\:793a
"];

(* ---- ClaudeCode キーワード自動注入登録 ---- *)
If[AssociationQ[ClaudeCode`$ClaudePackageKeywordMap],
  ClaudeCode`$ClaudePackageKeywordMap["pdfindex"] =
    {"PDF", "pdf", "pdfIndex", "pdfSearch", "pdfSearchUI", "pdfAskLLM",
     "pdfGetChunk", "pdfShowPage", "pdfFindPage",
     "\:8ad6\:6587", "paper", "\:6587\:66f8", "document", "\:691c\:7d22", "search", "\:30da\:30fc\:30b8",
     "pdfSearchForLLM", "pdfLoadIndex", "pdfReindex",
     "pdfListDocs", "pdfListCollections", "pdfStatus",
     "\:30a4\:30f3\:30c7\:30c3\:30af\:30b9", "index", "chunk"}
];
