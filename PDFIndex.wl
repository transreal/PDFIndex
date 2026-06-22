(* ::Package:: *)

(* PDFIndex.wl - PDF Document Indexing & Multi-layer Search Package *)
(* Date: 2026-04-04 *)
(* \:4f9d\:5b58: localInit.wl, claudecode.wl (optional), maildb.wl (embedding functions) *)
(* \:30a8\:30f3\:30b3\:30fc\:30c9: UTF-8 *)

BeginPackage["PDFIndex`"];

(* === Exported Symbols === *)
PDFIndexObject::usage =
  "PDFIndexObject[<|...|>] \:306f\:30ed\:30fc\:30c9\:6e08\:307fPDF\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:3092\:8868\:3059\:3002\n" <>
  "idx[\"dataset\"], idx[\"nearest\"], idx[\"count\"], idx[\"docs\"] \:3067\:30a2\:30af\:30bb\:30b9\:3002";

$pdfIndexBaseDir::usage =
  "$pdfIndexBaseDir \:306f\:30d7\:30e9\:30a4\:30d9\:30fc\:30c8PDF\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:306e\:4fdd\:5b58\:5148\:3002\n" <>
  "\:30c7\:30d5\:30a9\:30eb\:30c8: FileNameJoin[{$packageDirectory, \"pdfindex_private\"}]";

$pdfIndexAttachDir::usage =
  "$pdfIndexAttachDir \:306f\:30af\:30e9\:30a6\:30c9LLM\:51e6\:7406\:53ef\:80fd\:306aPDF\:306e\:4fdd\:5b58\:5148\:3002\n" <>
  "\:30c7\:30d5\:30a9\:30eb\:30c8: FileNameJoin[{$packageDirectory, \"claude_attachments\"}]";

(* ---- \:30a4\:30f3\:30c7\:30af\:30b7\:30f3\:30b0 ---- *)
pdfIndex::usage =
  "pdfIndex[pdfPath, opts] \:306f\:5358\:4e00PDF\:3092\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:306b\:8ffd\:52a0\:3059\:308b\:3002\n" <>
  "\:30aa\:30d7\:30b7\:30e7\:30f3: Privacy -> 0.0\:301c1.0 (\:30c7\:30d5\:30a9\:30eb\:30c8 Automatic \:3067 LLM \:63a8\:5b9a),\n" <>
  "  Keywords -> {\"key1\", ...}, Title -> \"\:30bf\:30a4\:30c8\:30eb\",\n" <>
  "  Collection -> \"default\" (\:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:540d),\n" <>
  "  ForceReindex -> False\n" <>
  "Privacy > 0.5 \:306e\:30d5\:30a1\:30a4\:30eb\:306f $pdfIndexBaseDir \:306b\:3001\n" <>
  "\:305d\:308c\:4ee5\:5916\:306f $pdfIndexAttachDir \:306b\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:3092\:4fdd\:5b58\:3002";

pdfIndexDirectory::usage =
  "pdfIndexDirectory[dirPath, opts] \:306f\:30c7\:30a3\:30ec\:30af\:30c8\:30ea\:5185\:306e\:5168PDF\:3092\:4e00\:62ec\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:3059\:308b\:3002\n" <>
  "\:30aa\:30d7\:30b7\:30e7\:30f3: pdfIndex \:3068\:540c\:3058 + FilePattern -> \"*.pdf\"";

pdfIndexURL::usage =
  "pdfIndexURL[url, opts] \:306fURL\:304b\:3089PDF\:3092\:30c0\:30a6\:30f3\:30ed\:30fc\:30c9\:3057\:3066\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:3059\:308b\:3002";

pdfIndexAsync::usage =
  "pdfIndexAsync[pdfPath, opts] \:306f pdfIndex \:3092\:5b9f\:884c\:3057\:3001\:9032\:6357\:3092\:30b9\:30c6\:30fc\:30bf\:30b9\:30d0\:30fc\:306b\:8868\:793a\:3059\:308b\:3002\n" <>
  "Print \:51fa\:529b\:304c\:30ce\:30fc\:30c8\:30d6\:30c3\:30af\:306e\:30bb\:30eb\:51fa\:529b\:306b\:6df7\:5165\:3057\:306a\:3044\:3002\n" <>
  "\:5185\:90e8\:306e Claude \:547c\:3073\:51fa\:3057\:306f NonBlocking (StartProcess + Pause) \:3067\n" <>
  "\:30d5\:30ed\:30f3\:30c8\:30a8\:30f3\:30c9\:306e\:5fdc\:7b54\:6027\:3092\:7dad\:6301\:3059\:308b\:3002";

pdfReindex::usage =
  "pdfReindex[collection] \:306f\:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:5185\:306e\:5168\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:306eLLM\:8981\:7d04\:30fbembedding \:3092\:518d\:751f\:6210\:3059\:308b\:3002";

pdfReembed::usage =
  "pdfReembed[collection] \:306f\:4fdd\:5b58\:6e08\:307f\:30c1\:30e3\:30f3\:30af\:306e\:30c6\:30ad\:30b9\:30c8\:304b\:3089 embedding \:3060\:3051\:3092\:518d\:751f\:6210\:3057\:3066\:66f4\:65b0\:3059\:308b\:3002\n" <>
  "PDF\:518d\:62bd\:51fa\:30fbLLM\:518d\:8981\:7d04\:306f\:884c\:308f\:306a\:3044 (\:8efd\:91cf)\:3002\:30a8\:30f3\:30b3\:30fc\:30c9\:4fee\:6b63\:5f8c\:306b\:65e2\:5b58 embedding \:3092\:4f5c\:308a\:76f4\:3059\:7528\:9014\:3002";

(* ---- \:691c\:7d22 ---- *)
pdfSearch::usage =
  "pdfSearch[query, n, opts] \:306f\:30cf\:30a4\:30d6\:30ea\:30c3\:30c9\:691c\:7d22 (embedding + keyword) \:3067\:4e0a\:4f4dn\:4ef6\:3092\:8fd4\:3059\:3002\n" <>
  "\:30aa\:30d7\:30b7\:30e7\:30f3: Collection -> All, MaxItems -> 20, MinPrivacy/MaxPrivacy";

pdfSearchForLLM::usage =
  "pdfSearchForLLM[query, opts] \:306f\:691c\:7d22\:7d50\:679c\:3092LLM\:30d7\:30ed\:30f3\:30d7\:30c8\:7528\:30c6\:30ad\:30b9\:30c8\:306b\:5909\:63db\:3059\:308b\:3002\n" <>
  "\:623b\:308a\:5024: <|\"public\" -> <|\"prompt\"->..., \"count\"->n|>,\n" <>
  "          \"private\" -> <|\"prompt\"->..., \"count\"->m|>|>\n" <>
  "\:30aa\:30d7\:30b7\:30e7\:30f3: MaxItems, Collection, IncludeFullText";

pdfAskLLM::usage =
  "pdfAskLLM[question, opts] \:306fPDF\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:3092\:691c\:7d22\:3057\:3001\n" <>
  "\:516c\:958b\:5206\:306f\:30af\:30e9\:30a6\:30c9LLM\:3001\:79d8\:5bc6\:5206\:306f $ClaudePrivateModel \:306b\:554f\:3044\:5408\:308f\:305b\:308b\:3002\n" <>
  "\:30aa\:30d7\:30b7\:30e7\:30f3: Collection, MaxItems, IncludeFullText\n" <>
  "\:4f8b: pdfAskLLM[\"reversible computing \:306e\:30b2\:30fc\:30c8\:69cb\:6210\:306f?\"]";

(* ---- \:30ed\:30fc\:30c9\:30fb\:7ba1\:7406 ---- *)
pdfLoadIndex::usage =
  "pdfLoadIndex[collection] \:306f\:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:306e\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:3092\:30ed\:30fc\:30c9\:3057 PDFIndexObject \:3092\:8fd4\:3059\:3002\n" <>
  "pdfLoadIndex[] \:306f\:5168\:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:3092\:30ed\:30fc\:30c9\:3059\:308b\:3002";

pdfListCollections::usage =
  "pdfListCollections[] \:306f\:5229\:7528\:53ef\:80fd\:306a\:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:4e00\:89a7\:3092\:8fd4\:3059\:3002";

pdfListDocs::usage =
  "pdfListDocs[collection] \:306f\:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:5185\:306e\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:4e00\:89a7\:3092 Dataset \:3067\:8fd4\:3059\:3002";

pdfRemoveDoc::usage =
  "pdfRemoveDoc[docId, collection] \:306f\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:3092\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:304b\:3089\:524a\:9664\:3059\:308b\:3002";

pdfStatus::usage =
  "pdfStatus[] \:306f\:73fe\:5728\:306e\:30a4\:30f3\:30c7\:30af\:30b7\:30f3\:30b0\:72b6\:614b\:3092\:8868\:793a\:3059\:308b\:3002";

pdfPreflightCheck::usage =
  "pdfPreflightCheck[] \:306f PDF \:62bd\:51fa\:30fbLLM\:30fbEmbedding \:306e\:52d5\:4f5c\:78ba\:8a8d\:3092\:884c\:3046\:3002";

pdfSearchUI::usage =
  "pdfSearchUI[query, n] \:306f\:30a4\:30f3\:30bf\:30e9\:30af\:30c6\:30a3\:30d6\:306a\:691c\:7d22\:7d50\:679c\:3092\:8868\:793a\:3059\:308b\:3002\n" <>
  "\:5404\:7d50\:679c\:306b [\:5168\:6587] [\:524d\:5f8c] [\:8cea\:554f] \:30dc\:30bf\:30f3\:3092\:8868\:793a\:3057\:3001\n" <>
  "  [\:5168\:6587] \:30c1\:30e3\:30f3\:30af\:306e\:5168\:30c6\:30ad\:30b9\:30c8\:3092\:30ce\:30fc\:30c8\:30d6\:30c3\:30af\:306b\:51fa\:529b\n" <>
  "  [\:524d\:5f8c] \:524d\:5f8c\:306e\:30c1\:30e3\:30f3\:30af\:3082\:542b\:3081\:305f\:30b3\:30f3\:30c6\:30ad\:30b9\:30c8\:3092\:8868\:793a\n" <>
  "  [\:8cea\:554f] \:305d\:306e\:30c1\:30e3\:30f3\:30af\:3092\:5143\:306b ClaudeQuery \:3067\:8cea\:554f\n" <>
  "\:30aa\:30d7\:30b7\:30e7\:30f3: Collection -> \"default\"";

pdfGetChunk::usage =
  "pdfGetChunk[chunkIndex, collection] \:306f\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:756a\:53f7\:306e\:30c1\:30e3\:30f3\:30af\:5168\:6587\:3092\:8fd4\:3059\:3002\n" <>
  "pdfGetChunk[{from, to}, collection] \:306f\:7bc4\:56f2\:306e\:30c1\:30e3\:30f3\:30af\:3092\:9023\:7d50\:3057\:3066\:8fd4\:3059\:3002";

pdfShowPage::usage =
  "pdfShowPage[pageNum, collection] \:306fPDF\:306e\:6307\:5b9a\:30da\:30fc\:30b8\:3092\:753b\:50cf\:3068\:3057\:3066\:30ce\:30fc\:30c8\:30d6\:30c3\:30af\:306b\:8868\:793a\:3059\:308b\:3002\n" <>
  "pdfShowPage[pageNum, collection, \"file\"] \:306f\:753b\:50cf\:30d5\:30a1\:30a4\:30eb\:30d1\:30b9\:3092\:8fd4\:3059\:3002\n" <>
  "\:4f8b: pdfShowPage[124]";

pdfFindPage::usage =
  "pdfFindPage[query, collection] \:306f\:30af\:30a8\:30ea\:306b\:30de\:30c3\:30c1\:3059\:308bPDF\:30da\:30fc\:30b8\:756a\:53f7\:3092\:63a8\:5b9a\:3057\:3066\:8fd4\:3059\:3002\n" <>
  "\:30c1\:30e3\:30f3\:30af\:4f4d\:7f6e\:3068PDF\:30e1\:30bf\:30c7\:30fc\:30bf\:304b\:3089\:30da\:30fc\:30b8\:756a\:53f7\:3092\:8a08\:7b97\:3059\:308b\:3002";

(* ---- \:30c7\:30d0\:30c3\:30b0 ---- *)
$pdfIndexDebug::usage = "$pdfIndexDebug = True \:3067\:30c7\:30d0\:30c3\:30b0\:51fa\:529b\:3092\:6709\:52b9\:306b\:3059\:308b\:3002";
$pdfIndexDebug = False;

(* Python \:5b9f\:884c\:30d1\:30b9: \:30d1\:30c3\:30b1\:30fc\:30b8\:30ed\:30fc\:30c9\:6642\:306b\:691c\:51fa *)
$pdfPythonPath = Quiet @ Check[
  Module[{pyExe},
    pyExe = ExternalEvaluate["Python", "import sys; sys.executable"];
    If[StringQ[pyExe] && FileExistsQ[pyExe], pyExe, "python"]],
  "python"];

EndPackage[];

(* === Dependencies === *)
Get["localInit.wl"];

(* === Implementation === *)
Begin["PDFIndex`Private`"];

(* ============================================================ *)
(* \:521d\:671f\:5316\:30fb\:5b9a\:6570                                                  *)
(* ============================================================ *)

(* \:30d9\:30fc\:30b9\:30c7\:30a3\:30ec\:30af\:30c8\:30ea: \:30d7\:30e9\:30a4\:30d9\:30fc\:30c8PDF\:7528 *)
If[!StringQ[PDFIndex`$pdfIndexBaseDir],
  PDFIndex`$pdfIndexBaseDir =
    FileNameJoin[{Global`$packageDirectory, "pdfindex_private"}]];

(* \:30a2\:30bf\:30c3\:30c1\:30e1\:30f3\:30c8\:30c7\:30a3\:30ec\:30af\:30c8\:30ea: \:30af\:30e9\:30a6\:30c9LLM\:51e6\:7406\:53ef\:80fd *)
If[!StringQ[PDFIndex`$pdfIndexAttachDir],
  PDFIndex`$pdfIndexAttachDir =
    FileNameJoin[{Global`$packageDirectory, "claude_attachments"}]];

(* \:30a4\:30f3\:30c7\:30af\:30b7\:30f3\:30b0\:72b6\:614b\:7ba1\:7406 *)
$pdfIndexTaskStatus = <|"state" -> "idle"|>;
If[!AssociationQ[$pdfIndexAsyncContext], $pdfIndexAsyncContext = <||>];
If[!AssociationQ[$pdfIndexAsyncJobs], $pdfIndexAsyncJobs = <||>];

(* \:30c7\:30d5\:30a9\:30eb\:30c8\:5b66\:79d1: \:30af\:30a8\:30ea\:306b\:5b66\:79d1\:540d\:304c\:306a\:3044\:5834\:5408\:306b\:88dc\:5b8c *)
$PDFIndexDefaultDepartment = None;  (* \:4f8b: "\:60c5\:5831\:5de5\:5b66\:79d1" *)

(* \:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:30ad\:30e3\:30c3\:30b7\:30e5 *)
If[!AssociationQ[$pdfIndexCache], $pdfIndexCache = <||>];

(* ============================================================ *)
(* \:691c\:7d22\:8f9e\:66f8 (\:30a8\:30a4\:30ea\:30a2\:30b9\:30fb\:30bf\:30fc\:30e0\:5c55\:958b)                              *)
(* $packageDirectory/pdfindex_search_config.json \:304b\:3089\:8d77\:52d5\:6642\:306b\:30ed\:30fc\:30c9 *)
(* ============================================================ *)
$pdfSearchAliases = <||>;       (* "\:6a5f\:68b0\:5de5\:5b66\:79d1" -> "\:6a5f\:68b0\:30b7\:30b9\:30c6\:30e0\:5de5\:5b66\:79d1" \:7b49 *)
$pdfSearchTermExpansions = <||>; (* "\:5fc5\:4fee\:79d1\:76ee" -> {"\:5fc5\:4fee", "\:79d1\:76ee"} \:7b49 *)

iLoadSearchConfig[] := Module[{path, json},
  path = FileNameJoin[{
    If[StringQ[Global`$packageDirectory], Global`$packageDirectory,
      Quiet @ Check[NotebookDirectory[], Directory[]]],
    "pdfindex_search_config.json"}];
  If[!FileExistsQ[path],
    If[TrueQ[$pdfIndexDebug],
      Print["  \:691c\:7d22\:8f9e\:66f8: \:30d5\:30a1\:30a4\:30eb\:306a\:3057 (" <> path <> ")"]];
    Return[]];
  json = Quiet @ Check[Developer`ReadRawJSONFile[path], $Failed];
  If[!AssociationQ[json],
    Print[Style["\[WarningSign] \:691c\:7d22\:8f9e\:66f8\:306e\:8aad\:307f\:8fbc\:307f\:306b\:5931\:6557: " <> path, Orange]];
    Return[]];
  $pdfSearchAliases = KeyDrop[Lookup[json, "aliases", <||>], "_comment"];
  $pdfSearchTermExpansions = Map[
    If[ListQ[#], #, {#}] &,
    KeyDrop[Lookup[json, "term_expansions", <||>], "_comment"]];
  If[TrueQ[$pdfIndexDebug],
    Print["  \:691c\:7d22\:8f9e\:66f8\:30ed\:30fc\:30c9: aliases=" <> ToString[Length[$pdfSearchAliases]] <>
      ", expansions=" <> ToString[Length[$pdfSearchTermExpansions]]]]];

(* \:30bf\:30fc\:30e0\:5c55\:958b: \:8f9e\:66f8\:306b\:767b\:9332\:3055\:308c\:305f\:8907\:5408\:8a9e\:3092\:30b5\:30d6\:30ef\:30fc\:30c9\:306b\:5206\:89e3\:3059\:308b\:3002
   \:767b\:9332\:3055\:308c\:3066\:3044\:306a\:3044\:30bf\:30fc\:30e0\:306f\:305d\:306e\:307e\:307e\:8fd4\:3059\:3002
   \:4f8b: iExpandTerm["\:5fc5\:4fee\:79d1\:76ee"] \[RightArrow] {"\:5fc5\:4fee", "\:79d1\:76ee"} *)
iExpandTerm[term_String] :=
  Lookup[$pdfSearchTermExpansions, term,
    (* \:8f9e\:66f8\:306b\:306a\:3044\:5834\:5408: iNormalizeForMatch \:3057\:305f\:7248\:3067\:3082\:691c\:7d22 *)
    Module[{nTerm = iNormalizeForMatch[term]},
      Lookup[$pdfSearchTermExpansions, nTerm, {term}]]];

(* \:30a8\:30a4\:30ea\:30a2\:30b9\:89e3\:6c7a: \:8f9e\:66f8\:306b\:767b\:9332\:3055\:308c\:305f\:7565\:79f0\:3092\:6b63\:898f\:540d\:306b\:5909\:63db\:3059\:308b\:3002
   \:4f8b: iResolveAlias["\:6a5f\:68b0\:5de5\:5b66\:79d1"] \[RightArrow] "\:6a5f\:68b0\:30b7\:30b9\:30c6\:30e0\:5de5\:5b66\:79d1" *)
iResolveAlias[term_String] :=
  Lookup[$pdfSearchAliases, term,
    Module[{nTerm = iNormalizeForMatch[term]},
      Lookup[$pdfSearchAliases, nTerm, term]]];

(* \:30d1\:30c3\:30b1\:30fc\:30b8\:30ed\:30fc\:30c9\:6642\:306b\:691c\:7d22\:8f9e\:66f8\:3092\:8aad\:307f\:8fbc\:3080 *)
iLoadSearchConfig[];

(* \:30c1\:30e3\:30f3\:30af\:30b5\:30a4\:30ba\:5b9a\:6570 *)
$chunkMaxChars = 2000;   (* 1\:30c1\:30e3\:30f3\:30af\:306e\:6700\:5927\:6587\:5b57\:6570 *)
$chunkOverlap = 200;     (* \:30c1\:30e3\:30f3\:30af\:9593\:306e\:30aa\:30fc\:30d0\:30fc\:30e9\:30c3\:30d7\:6587\:5b57\:6570 *)
$summaryMaxChars = 150;  (* LLM\:8981\:7d04\:306e\:6700\:5927\:6587\:5b57\:6570 *)

(* ============================================================ *)
(* \:4e26\:5217\:30ab\:30fc\:30cd\:30eb\:7ba1\:7406                                              *)
(* Phase 0 \:306e ExternalEvaluate (Python) \:3092\:8907\:6570\:30b3\:30a2\:3067\:5b9f\:884c\:3059\:308b\:305f\:3081  *)
(* LaunchKernels / ParallelMap \:3092\:4f7f\:7528\:3002                           *)
(* LLMGraph \:306e\:30b9\:30b1\:30b8\:30e5\:30fc\:30e9 (ScheduledTask \:30d9\:30fc\:30b9) \:3068\:306f\:72ec\:7acb\:3002       *)
(* Phase 0 \:306f\:540c\:671f\:51e6\:7406\:306a\:306e\:3067\:3001\:30e1\:30a4\:30f3\:30ab\:30fc\:30cd\:30eb\:306e ScheduledTask \:3068     *)
(* \:7af6\:5408\:3057\:306a\:3044\:3002                                                   *)
(* ============================================================ *)

(* \:4e26\:5217\:30ab\:30fc\:30cd\:30eb\:6570: \:7269\:7406\:30b3\:30a2\:6570 - 1 (\:30e1\:30a4\:30f3\:30ab\:30fc\:30cd\:30eb\:5206) \:3092\:4e0a\:9650\:3002
   OCR/\:30da\:30fc\:30b8\:5206\:6790\:306b\:306f Python \:304c\:5fc5\:8981\:306a\:306e\:3067\:3001\:5404\:30b5\:30d6\:30ab\:30fc\:30cd\:30eb\:3067
   ExternalEvaluate \:30bb\:30c3\:30b7\:30e7\:30f3\:3092\:521d\:671f\:5316\:3059\:308b\:3002 *)
$pdfParallelKernelCount = Automatic;  (* Automatic = Min[$ProcessorCount - 1, 6] *)

(* \:30b5\:30d6\:30ab\:30fc\:30cd\:30eb\:306e Python \:521d\:671f\:5316\:6e08\:307f\:30d5\:30e9\:30b0 *)
$pdfParallelInitialized = False;

(* iEnsureParallelKernels[]: \:5fc5\:8981\:6570\:306e\:30b5\:30d6\:30ab\:30fc\:30cd\:30eb\:3092\:8d77\:52d5\:3057\:3001
   $pythonPDFExtractCode \:3068\:5fc5\:8981\:306a\:30d1\:30c3\:30b1\:30fc\:30b8\:30d1\:30b9\:3092\:914d\:5e03\:3059\:308b\:3002
   \:65e2\:306b\:8d77\:52d5\:6e08\:307f\:306a\:3089\:4f55\:3082\:3057\:306a\:3044\:3002LLMGraph \:306e\:30dd\:30fc\:30ea\:30f3\:30b0\:30bf\:30b9\:30af\:306b\:306f\:5f71\:97ff\:306a\:3057\:3002 *)
iEnsureParallelKernels[] := Module[{targetCount, currentCount},
  targetCount = If[IntegerQ[$pdfParallelKernelCount],
    $pdfParallelKernelCount,
    Min[$ProcessorCount - 1, 6]];
  If[targetCount < 1, targetCount = 1];
  currentCount = Length[Kernels[]];
  If[currentCount < targetCount,
    If[TrueQ[PDFIndex`$pdfIndexDebug],
      Print["  [Parallel] Launching ", targetCount - currentCount,
        " subkernels (current: ", currentCount, ")"]];
    LaunchKernels[targetCount - currentCount]];
  (* \:30b5\:30d6\:30ab\:30fc\:30cd\:30eb\:306b Python \:30b3\:30fc\:30c9\:3068\:5fc5\:8981\:306a\:5b9a\:7fa9\:3092\:914d\:5e03 *)
  If[!TrueQ[$pdfParallelInitialized] || currentCount < targetCount,
    Quiet @ ParallelEvaluate[
      Needs["Developer`"];
      (* $TemporaryDirectory \:306f\:30b5\:30d6\:30ab\:30fc\:30cd\:30eb\:3067\:3082\:5229\:7528\:53ef\:80fd *)
    ];
    $pdfParallelInitialized = True];
];

(* iParallelMapSafe: \:30b5\:30d6\:30ab\:30fc\:30cd\:30eb\:3092\:4f7f\:3063\:305f ParallelMap\:3002
   \:5931\:6557\:6642\:306f\:901a\:5e38\:306e Map \:306b\:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af\:3002
   fn \:306f\:5404\:8981\:7d20\:306b\:5bfe\:3057\:3066\:9069\:7528\:3055\:308c\:308b\:7d14\:95a2\:6570\:3002 *)
iParallelMapSafe[fn_, list_List] := Module[{result},
  If[Length[list] <= 1, Return[Map[fn, list]]];
  iEnsureParallelKernels[];
  result = Quiet @ Check[
    ParallelMap[fn, list, Method -> "FinestGrained"],
    $Failed];
  If[result === $Failed || !ListQ[result],
    If[TrueQ[PDFIndex`$pdfIndexDebug],
      Print["  [Parallel] ParallelMap failed, falling back to Map"]];
    Map[fn, list],
    result]
];

(* iParallelMapBatched: \:30ea\:30b9\:30c8\:3092 n \:500b\:306e\:30d0\:30c3\:30c1\:306b\:5206\:5272\:3057 ParallelMap\:3002
   \:5404\:30d0\:30c3\:30c1\:306f1\:3064\:306e\:30b5\:30d6\:30ab\:30fc\:30cd\:30eb\:3067\:9010\:6b21\:51e6\:7406\:3055\:308c\:308b\:3002
   Python \:30bb\:30c3\:30b7\:30e7\:30f3\:521d\:671f\:5316\:30b3\:30b9\:30c8\:3092 amortize \:3059\:308b\:3002 *)
iParallelMapBatched[fn_, list_List, batchCount_Integer:Automatic] := Module[
  {nBatches, partitioned, batchResults},
  If[Length[list] <= 1, Return[Map[fn, list]]];
  iEnsureParallelKernels[];
  nBatches = If[IntegerQ[batchCount] && batchCount > 0,
    batchCount,
    Min[Length[Kernels[]], Length[list]]];
  If[nBatches < 1, nBatches = 1];
  partitioned = Partition[list, UpTo[Ceiling[Length[list] / nBatches]]];
  batchResults = Quiet @ Check[
    ParallelMap[
      Function[batch, Map[fn, batch]],
      partitioned],
    $Failed];
  If[batchResults === $Failed || !ListQ[batchResults],
    Map[fn, list],
    Flatten[batchResults, 1]]
];

(* ============================================================ *)
(* PDFIndexObject \:30a2\:30af\:30bb\:30b5                                       *)
(* ============================================================ *)

(idx_PDFIndex`PDFIndexObject)[key_String] := idx[[1]][key];

Format[PDFIndex`PDFIndexObject[data_Association]] :=
  Row[{"PDFIndexObject[\[LeftGuillemet]",
    data["collection"], ", ",
    data["docCount"], " docs, ",
    data["chunkCount"], " chunks\[RightGuillemet]]"}];

(* ============================================================ *)
(* \:30c7\:30a3\:30ec\:30af\:30c8\:30ea\:7ba1\:7406                                              *)
(* ============================================================ *)

(* \:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:5225\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:30c7\:30a3\:30ec\:30af\:30c8\:30ea *)
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

(* \:30c9\:30ad\:30e5\:30e1\:30f3\:30c8ID\:306e\:751f\:6210: SHA256 \:5148\:982d16\:6841 *)
iDocId[pdfPath_String] := Module[{hashVal},
  hashVal = If[iIsURL[pdfPath],
    Hash[pdfPath, "SHA256"],
    Quiet @ Check[FileHash[pdfPath, "SHA256"], Hash[pdfPath, "SHA256"]]];
  IntegerString[hashVal, 16, 16]
];

iIsURL[s_String] := StringMatchQ[s, ("http://" | "https://") ~~ __];
iIsURL[_] := False;

(* ============================================================ *)
(* \:30d1\:30b9\:76f8\:5bfe\:5316\:30fb\:89e3\:6c7a\:30d8\:30eb\:30d1\:30fc                                      *)
(* $packageDirectory \:5909\:66f4\:6642\:306b\:3082\:6b63\:3057\:304f\:52d5\:4f5c\:3059\:308b\:3088\:3046\:3001               *)
(* \:4fdd\:5b58\:6642\:306f\:76f8\:5bfe\:30d1\:30b9\:3001\:8aad\:307f\:51fa\:3057\:6642\:306b\:5c55\:958b\:3059\:308b\:3002                       *)
(* ============================================================ *)

(* iMakeRelativePath: $packageDirectory \:914d\:4e0b\:306a\:3089\:76f8\:5bfe\:30d1\:30b9\:306b\:5909\:63db *)
iMakeRelativePath[absPath_String] := Module[{baseDir, normalized, normalizedBase},
  If[iIsURL[absPath], Return[absPath]];
  baseDir = Global`$packageDirectory;
  If[!StringQ[baseDir], Return[absPath]];
  (* \:30d1\:30b9\:533a\:5207\:308a\:6587\:5b57\:3092\:7d71\:4e00\:3057\:3066\:6bd4\:8f03 *)
  normalized = StringReplace[absPath, "\\" -> "/"];
  normalizedBase = StringReplace[baseDir, "\\" -> "/"];
  If[!StringEndsQ[normalizedBase, "/"],
    normalizedBase = normalizedBase <> "/"];
  If[StringStartsQ[normalized, normalizedBase],
    StringDrop[normalized, StringLength[normalizedBase]],
    absPath]
];

(* iResolveSourcePath: \:4fdd\:5b58\:6e08\:307f\:30d1\:30b9\:3092\:7d76\:5bfe\:30d1\:30b9\:306b\:89e3\:6c7a *)
iResolveSourcePath[storedPath_String] := Module[{},
  If[iIsURL[storedPath], Return[storedPath]];
  (* \:65e2\:306b\:7d76\:5bfe\:30d1\:30b9\:306a\:3089 (\:30c9\:30e9\:30a4\:30d6\:30ec\:30bf\:30fc or / \:59cb\:307e\:308a) \:305d\:306e\:307e\:307e *)
  If[StringMatchQ[storedPath, LetterCharacter ~~ ":" ~~ __] ||
     StringStartsQ[storedPath, "/"],
    Return[storedPath]];
  (* \:76f8\:5bfe\:30d1\:30b9 \[RightArrow] $packageDirectory \:3067\:5c55\:958b *)
  FileNameJoin[{Global`$packageDirectory, storedPath}]
];

(* ============================================================ *)
(* PDF \:30c6\:30ad\:30b9\:30c8\:62bd\:51fa (Python/PyMuPDF)                             *)
(* ============================================================ *)

$pythonPDFExtractCode = "
import sys, json, os, warnings
warnings.filterwarnings('ignore')

def extract_pdf(pdf_path, max_pages=None):
    _old_stderr = sys.stderr
    sys.stderr = open(os.devnull, 'w')
    try:
        return _extract_pdf_impl(pdf_path, max_pages)
    finally:
        sys.stderr = _old_stderr

def _extract_pdf_impl(pdf_path, max_pages=None):
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

iPDFExtract[pdfPath_String, maxPages_:None, skipOCR_:False] := Module[
  {escapedPath, maxPagesStr, pyCode, outJsonFile, result, json},
  (* Windows \:30d1\:30b9\:306e\:30d0\:30c3\:30af\:30b9\:30e9\:30c3\:30b7\:30e5\:3092\:5b89\:5168\:306b\:30a8\:30b9\:30b1\:30fc\:30d7 *)
  escapedPath = StringReplace[pdfPath, "\\" -> "/"];
  maxPagesStr = If[IntegerQ[maxPages], ToString[maxPages], "None"];
  (* \:51fa\:529b\:5148\:306e\:4e00\:6642JSON\:30d5\:30a1\:30a4\:30eb *)
  outJsonFile = FileNameJoin[{$TemporaryDirectory,
    "pdfidx_out_" <> IntegerString[Round[AbsoluteTime[] * 1000]] <> ".json"}];
  (* Python \:30b3\:30fc\:30c9: \:95a2\:6570\:5b9a\:7fa9 + \:547c\:3073\:51fa\:3057 + JSON\:51fa\:529b *)
  pyCode = $pythonPDFExtractCode <> "\n" <>
    "import json\n" <>
    "_pdfidx_result = extract_pdf(r'" <> escapedPath <> "', " <> maxPagesStr <> ")\n" <>
    "with open(r'" <> StringReplace[outJsonFile, "\\" -> "/"] <>
      "', 'w', encoding='utf-8') as _f:\n" <>
    "    json.dump(_pdfidx_result, _f, ensure_ascii=False)\n" <>
    "'done'\n";
  (* ExternalEvaluate \:3067Python\:5b9f\:884c *)
  result = Quiet @ Check[ExternalEvaluate["Python", pyCode], $Failed];
  (* JSON \:30d5\:30a1\:30a4\:30eb\:304b\:3089\:7d50\:679c\:3092\:8aad\:307f\:8fbc\:307f *)
  If[FileExistsQ[outJsonFile],
    json = Quiet @ Check[
      Developer`ReadRawJSONFile[outJsonFile],
      Quiet @ Check[Import[outJsonFile, "RawJSON"], $Failed]];
    Quiet[DeleteFile[outJsonFile]];
    If[AssociationQ[json],
      If[KeyExistsQ[json, "error"],
        Print["  \[WarningSign] PDF\:62bd\:51fa\:30a8\:30e9\:30fc: " <> json["error"]];
        Return[iPDFExtractWL[pdfPath, maxPages]]];
      Return[If[TrueQ[skipOCR], json, iFixGarbledPages[json, pdfPath]]]]];
  (* Python \:5b9f\:884c\:5931\:6557 or JSON \:306a\:3057 \[RightArrow] WL \:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af *)
  If[TrueQ[PDFIndex`$pdfIndexDebug],
    Print["  [iPDFExtract] Python\:7d50\:679c: " <> ToString[Short[result]]]];
  iPDFExtractWL[pdfPath, maxPages]
];

(* === \:6587\:5b57\:5316\:3051\:691c\:51fa ===
   CID\:30d5\:30a9\:30f3\:30c8\:7b49\:3067\:6587\:5b57\:5316\:3051\:3059\:308b\:30da\:30fc\:30b8\:3092\:691c\:51fa\:3002
   \:6587\:5b57\:5316\:3051\:30c6\:30ad\:30b9\:30c8\:306e\:7279\:5fb4:
     - \:500b\:5225\:306e\:6f22\:5b57\:8a9e\:ff08\:79d1\:76ee\:540d\:7b49\:ff09\:306f\:5076\:7136\:8aad\:3081\:308b\:3053\:3068\:304c\:3042\:308b
     - \:3057\:304b\:3057\:52a9\:8a5e\:30fb\:63a5\:7d9a\:306e\:300c\:3072\:3089\:304c\:306a\:9023\:7d9a\:300d(\:306e\:3001\:3092\:3001\:306b\:3059\:308b\:3001\:306b\:3064\:3044\:3066\:7b49)\:304c\:306a\:3044
     - \:6b63\:5e38\:30c6\:30ad\:30b9\:30c8: \:300c...\:306b\:95a2\:3059\:308b\:5c02\:9580\:77e5\:8b58\:306e\:4fee\:5f97\:300d\[RightArrow] \:300c\:306b\:300d\:300c\:3059\:308b\:300d\:300c\:306e\:300d
     - \:6587\:5b57\:5316\:3051: \:300c\:78ba\:854a2\:7e4a\:8a0e...\:300d\[RightArrow] \:3072\:3089\:304c\:306a\:9023\:7d9a\:306a\:3057
   \:5224\:5b9a: 2\:6587\:5b57\:4ee5\:4e0a\:306e\:3072\:3089\:304c\:306a\:9023\:7d9a\:51fa\:73fe\:6570\:304c\:5c11\:306a\:3051\:308c\:3070\:6587\:5b57\:5316\:3051 *)
iIsGarbledText[text_String] := Module[
  {len, latinCount, hiraSeqs},
  len = StringLength[text];
  If[len < 200, Return[False]];
  latinCount = StringCount[text, RegularExpression["[a-zA-Z]"]];
  If[latinCount / N[len] > 0.5, Return[False]];
  (* 2\:6587\:5b57\:4ee5\:4e0a\:306e\:3072\:3089\:304c\:306a\:9023\:7d9a\:3092\:691c\:51fa *)
  hiraSeqs = StringCount[text,
    RegularExpression["[\\x{3041}-\\x{309F}]{2,}"]];
  (* \:6b63\:5e38\:306a\:65e5\:672c\:8a9e: 200\:6587\:5b57\:3042\:305f\:308a3\:56de\:4ee5\:4e0a\:306e\:3072\:3089\:304c\:306a\:9023\:7d9a\:304c\:3042\:308b\:3002
     \:8868\:30da\:30fc\:30b8(\:6f22\:5b57\:591a\:3081)\:3067\:3082\:300c\:306e\:300d\:300c\:3092\:300d\:300c\:306b\:300d\:7b49\:306e\:52a9\:8a5e\:30da\:30a2\:304c\:983b\:51fa\:3002
     \:4f8b: R04 p.3 (3957ch, \:8aad\:3081\:308b) \[RightArrow] ~30\:56de
         R05 p.1 (939ch, \:6587\:5b57\:5316\:3051) \[RightArrow] 0\:56de
         R03 p.4 (2546ch, \:6587\:5b57\:5316\:3051) \[RightArrow] 0\:56de *)
  hiraSeqs < Max[1, len / 500]
];

(* === \:6587\:5b57\:5316\:3051\:30da\:30fc\:30b8\:306e\:518d\:62bd\:51fa ===
   iPDFExtract \:306e\:7d50\:679c\:3092\:5f8c\:51e6\:7406\:3057\:3001\:6587\:5b57\:5316\:3051\:30da\:30fc\:30b8\:3092\:4fee\:5fa9\:3059\:308b\:3002
   \:4e26\:5217\:5316\:6226\:7565:
     1. EasyOCR \:3092 ParallelMap \:3067\:5168\:6587\:5b57\:5316\:3051\:30da\:30fc\:30b8\:306b\:4e26\:5217\:9069\:7528 (CPU\:96c6\:7d04)
     2. \:5931\:6557\:30da\:30fc\:30b8\:306e\:307f Claude Vision CLI \:3067\:9010\:6b21\:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af
     3. \:3055\:3089\:306b\:5931\:6557\:306a\:3089 TextRecognize
   EasyOCR \:306f ExternalEvaluate["Python", ...] \:30d9\:30fc\:30b9\:306a\:306e\:3067
   \:30b5\:30d6\:30ab\:30fc\:30cd\:30eb\:3067\:3082\:5b9f\:884c\:53ef\:80fd\:3002Claude Vision \:306f ClaudeQueryBg \:3092
   \:4f7f\:3046\:305f\:3081\:30e1\:30a4\:30f3\:30ab\:30fc\:30cd\:30eb\:3067\:306e\:307f\:52d5\:4f5c\:3002 *)
iFixGarbledPages[extractResult_Association, pdfPath_String] :=
  Module[{pages, garbledNums = {}, garbledPageMap, ocrResults},
    If[!KeyExistsQ[extractResult, "pages"], Return[extractResult]];
    pages = extractResult["pages"];
    (* \:6587\:5b57\:5316\:3051\:30da\:30fc\:30b8\:3092\:691c\:51fa *)
    Do[Module[{text = Lookup[p, "text", ""]},
      If[iIsGarbledText[text],
        AppendTo[garbledNums, Lookup[p, "pageNum", 0]]]],
      {p, pages}];
    If[Length[garbledNums] === 0, Return[extractResult]];
    If[TrueQ[PDFIndex`$pdfIndexDebug],
      Print["  \:26a0\:fe0f \:6587\:5b57\:5316\:3051\:691c\:51fa: p." <>
        StringRiffle[ToString /@ garbledNums, ","] <>
        " \[RightArrow] \:4e26\:5217OCR\:3067\:518d\:62bd\:51fa (" <> ToString[Length[garbledNums]] <> " pages)"]];
    (* OCR \:4fee\:6b63\:30c6\:30ad\:30b9\:30c8\:3092\:4fdd\:5b58: \:5f8c\:6bb5\:306e\:69cb\:9020\:5316\:30c1\:30e3\:30f3\:30ad\:30f3\:30b0\:3067\:4f7f\:7528 *)
    $pdfIndexAsyncContext["ocrFixedPages"] = <||>;

    (* \:30b9\:30c6\:30c3\:30d71: EasyOCR \:3092\:4e26\:5217\:5b9f\:884c (\:30b5\:30d6\:30ab\:30fc\:30cd\:30eb\:3067\:5b9f\:884c\:53ef\:80fd) *)
    ocrResults = iParallelMapSafe[
      Function[{pgNum},
        Module[{text},
          text = Quiet @ Check[
            iOCRPageWithEasyOCR[pdfPath, pgNum], $Failed];
          <|"pageNum" -> pgNum,
            "text" -> If[StringQ[text] && StringLength[text] > 20,
              text, None],
            "method" -> "EasyOCR"|>]],
      garbledNums];

    (* \:30b9\:30c6\:30c3\:30d72: EasyOCR \:5931\:6557\:30da\:30fc\:30b8\:3092 Claude Vision \:3067\:9010\:6b21\:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af *)
    ocrResults = Map[
      Function[{res},
        If[res["text"] === None,
          Module[{text},
            text = Quiet @ Check[
              iOCRPageWithClaudeVision[pdfPath, res["pageNum"]], None];
            If[StringQ[text] && StringLength[text] > 20,
              <|"pageNum" -> res["pageNum"], "text" -> text,
                "method" -> "ClaudeVision"|>,
              (* \:30b9\:30c6\:30c3\:30d73: TextRecognize \:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af *)
              Module[{wlText},
                wlText = Quiet @ Check[
                  iOCRPageFallback[pdfPath, res["pageNum"]], $Failed];
                <|"pageNum" -> res["pageNum"],
                  "text" -> If[StringQ[wlText], wlText, None],
                  "method" -> "TextRecognize"|>]]],
          res]],
      ocrResults];

    (* \:7d50\:679c\:3092 garbledPageMap \:306b\:683c\:7d0d *)
    garbledPageMap = <||>;
    Scan[If[StringQ[#["text"]],
      garbledPageMap[#["pageNum"]] = #["text"];
      If[TrueQ[PDFIndex`$pdfIndexDebug],
        Print["  \:2714 p." <> ToString[#["pageNum"]] <> ": " <>
          ToString[StringLength[#["text"]]] <> " chars (" <>
          #["method"] <> ")"]],
      If[TrueQ[PDFIndex`$pdfIndexDebug],
        Print["  \:26a0\:fe0f p." <> ToString[#["pageNum"]] <> " OCR\:5931\:6557"]]] &,
      ocrResults];

    (* \:30da\:30fc\:30b8\:30c6\:30ad\:30b9\:30c8\:3092\:66f4\:65b0 *)
    pages = Map[
      Module[{pg = Lookup[#, "pageNum", 0], ocrText},
        ocrText = Lookup[garbledPageMap, pg, None];
        If[StringQ[ocrText],
          $pdfIndexAsyncContext["ocrFixedPages"][pg] = ocrText;
          Append[KeyDrop[#, "text"], "text" -> ocrText],
          #]] &,
      pages];
    Join[KeyDrop[extractResult, "pages"], <|"pages" -> pages|>]
  ];

(* === OCR \:30d1\:30a4\:30d7\:30e9\:30a4\:30f3 ===
   \:512a\:5148\:9806: Claude Vision \[RightArrow] EasyOCR \[RightArrow] TextRecognize
   Claude Vision: \:65e5\:672c\:8a9e\:8868\:306e\:8a8d\:8b58\:7cbe\:5ea6\:304c\:6700\:3082\:9ad8\:3044\:ff08CLI\:7d4c\:7531\:3001Pro/Max\:542b\:3080\:ff09
   EasyOCR: \:30ed\:30fc\:30ab\:30eb\:6df1\:5c64\:5b66\:7fd2\:30d9\:30fc\:30b9\:ff08\:7121\:6599\:3001\:7cbe\:5ea6\:4e2d\:7a0b\:5ea6\:ff09
   TextRecognize: Mathematica \:5185\:8535\:ff08\:6700\:7d42\:624b\:6bb5\:ff09 *)

iOCRPageWithClaudeCode[pdfPath_String, pageNum_Integer] := Module[
  {text},
  (* 1. Claude Vision \:3092\:8a66\:884c *)
  text = iOCRPageWithClaudeVision[pdfPath, pageNum];
  If[StringQ[text] && StringLength[text] > 20, Return[text]];
  (* 2. EasyOCR \:3092\:8a66\:884c *)
  text = iOCRPageWithEasyOCR[pdfPath, pageNum];
  If[StringQ[text] && StringLength[text] > 20, Return[text]];
  (* 3. TextRecognize \:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af *)
  iOCRPageFallback[pdfPath, pageNum]
];

(* Claude Vision OCR: PDF\:30da\:30fc\:30b8\:3092\:753b\:50cf\:5316\:3057\:3001\:4e0a\:4e0b\:5206\:5272\:3057\:3066 Claude \:306b\:5168\:30c6\:30ad\:30b9\:30c8\:62bd\:51fa\:3092\:4f9d\:983c\:3002
   \:5927\:304d\:306a\:753b\:50cf\:30921\:679a\:3067\:9001\:308b\:3068 CLI \:304c\:30bf\:30a4\:30e0\:30a2\:30a6\:30c8\:3059\:308b\:305f\:3081\:3001
   \:30da\:30fc\:30b8\:3092\:4e0a\:4e0b\:306b\:5206\:5272\:3057\:3066\:5404\:534a\:5206\:3092\:5225\:3005\:306b OCR \:3057\:7d50\:679c\:3092\:30de\:30fc\:30b8\:3059\:308b\:3002 *)
iOCRPageWithClaudeVision[pdfPath_String, pageNum_Integer] := Module[
  {img, imgFile, escapedPath, pyCode, renderResult,
   dims, halfH, topImg, botImg, topText, botText, prompt},
  If[TrueQ[PDFIndex`$pdfIndexDebug],
    Print["  Claude Vision OCR p." <> ToString[pageNum] <> "..."]];
  (* ClaudeQueryBg \:304c\:5229\:7528\:53ef\:80fd\:304b\:78ba\:8a8d *)
  If[Length[Names["ClaudeCode`ClaudeQueryBg"]] === 0,
    If[TrueQ[PDFIndex`$pdfIndexDebug],
      Print["  ClaudeQueryBg unavailable, skipping Vision OCR"]];
    Return[None]];
  (* PyMuPDF \:3067 300 DPI \:30ec\:30f3\:30c0\:30ea\:30f3\:30b0 \[RightArrow] PNG \:4fdd\:5b58 \[RightArrow] Import *)
  imgFile = FileNameJoin[{$TemporaryDirectory,
    "pdfocr_vision_" <> IntegerString[Round[AbsoluteTime[] * 1000]] <> ".png"}];
  escapedPath = StringReplace[pdfPath, "\\" -> "/"];
  pyCode = "
import fitz
doc = fitz.open(r'" <> escapedPath <> "')
pix = doc[" <> ToString[pageNum - 1] <> "].get_pixmap(dpi=450)
pix.save(r'" <> StringReplace[imgFile, "\\" -> "/"] <> "')
doc.close()
'done'
";
  renderResult = Quiet @ Check[ExternalEvaluate["Python", pyCode], $Failed];
  If[!FileExistsQ[imgFile],
    If[TrueQ[PDFIndex`$pdfIndexDebug],
      Print["  \:30da\:30fc\:30b8\:30ec\:30f3\:30c0\:30ea\:30f3\:30b0\:5931\:6557"]];
    Return[None]];
  img = Quiet @ Check[Import[imgFile, "PNG"], $Failed];
  Quiet[DeleteFile[imgFile]];
  If[!ImageQ[img],
    If[TrueQ[PDFIndex`$pdfIndexDebug],
      Print["  \:753b\:50cf\:8aad\:307f\:8fbc\:307f\:5931\:6557"]];
    Return[None]];

  (* \:30da\:30fc\:30b8\:3092\:4e0a\:4e0b\:306b\:5206\:5272 *)
  dims = ImageDimensions[img]; (* {width, height} *)
  halfH = Round[dims[[2]] / 2];
  (* ImageTake[img, {y1, y2}] \[LongDash] \:4e0a\:304b\:3089 y1\:301cy2 \:884c\:3092\:5207\:308a\:51fa\:3057 *)
  topImg = ImageTake[img, {1, halfH + 30}];       (* 30px \:30aa\:30fc\:30d0\:30fc\:30e9\:30c3\:30d7 *)
  botImg = ImageTake[img, {halfH - 30, dims[[2]]}];

  prompt = "\:3053\:306e\:753b\:50cf\:306f\:5927\:5b66\:306e\:914d\:5f53\:8868\:ff08\:5c65\:4fee\:8868\:ff09\:306ePDF\:30da\:30fc\:30b8\:306e\:4e00\:90e8\:3067\:3059\:3002" <>
    "\:8868\:306e\:5168\:3066\:306e\:884c\:3092\:7701\:7565\:305b\:305a\:62bd\:51fa\:3057\:3066\:304f\:3060\:3055\:3044\:3002" <>
    "\:79d1\:76ee\:30b3\:30fc\:30c9\:3068\:79d1\:76ee\:540d\:3092\:6b63\:78ba\:306b\:3002" <>
    "\:51fa\:529b\:306f\:62bd\:51fa\:30c6\:30ad\:30b9\:30c8\:306e\:307f\:3002\:8aac\:660e\:4e0d\:8981\:3002";

  (* \:4e0a\:534a\:5206\:3092 OCR \[LongDash] \:5206\:5272\:753b\:50cf\:306f\:5c0f\:3055\:3044\:306e\:3067 $iMediaMaxImageSize \:3092\:4e00\:6642\:7684\:306b\:62e1\:5927 *)
  Print["  Claude Vision OCR p." <> ToString[pageNum] <> " \:4e0a\:534a\:5206..."];
  topText = Quiet @ Check[
    Block[{ClaudeCode`$iMediaMaxImageSize = 1568},
      ClaudeCode`ClaudeQueryBg[{prompt, topImg},
        "NonBlocking" -> True, "Timeout" -> 180]],
    $Failed];
  If[!StringQ[topText] || StringStartsQ[topText, "Error:"],
    Print["  Claude Vision \:4e0a\:534a\:5206\:5931\:6557: " <>
      If[StringQ[topText], StringTake[topText, UpTo[60]], "N/A"]];
    topText = ""];

  (* \:4e0b\:534a\:5206\:3092 OCR *)
  Print["  Claude Vision OCR p." <> ToString[pageNum] <> " \:4e0b\:534a\:5206..."];
  botText = Quiet @ Check[
    Block[{ClaudeCode`$iMediaMaxImageSize = 1568},
      ClaudeCode`ClaudeQueryBg[{prompt, botImg},
        "NonBlocking" -> True, "Timeout" -> 180]],
    $Failed];
  If[!StringQ[botText] || StringStartsQ[botText, "Error:"],
    Print["  Claude Vision \:4e0b\:534a\:5206\:5931\:6557: " <>
      If[StringQ[botText], StringTake[botText, UpTo[60]], "N/A"]];
    botText = ""];

  (* \:7d50\:679c\:3092\:30de\:30fc\:30b8 *)
  If[StringLength[topText] + StringLength[botText] > 20,
    Print["  \:2714 p." <> ToString[pageNum] <> ": " <>
      ToString[StringLength[topText]] <> "+" <>
      ToString[StringLength[botText]] <> " chars (Claude Vision)"];
    StringTrim[topText] <> "\n" <> StringTrim[botText],
    Print["  Claude Vision OCR \:5931\:6557 (\:4e21\:534a\:5206\:3068\:3082\:4e0d\:5341\:5206)"];
    None]
];

(* EasyOCR: PyMuPDF \:3067 400 DPI \:30ec\:30f3\:30c0\:30ea\:30f3\:30b0 + \:753b\:50cf\:524d\:51e6\:7406 + EasyOCR *)
iOCRPageWithEasyOCR[pdfPath_String, pageNum_Integer] := Module[
  {pathFile, ocrOutFile, pyCode, result, text},
  If[TrueQ[PDFIndex`$pdfIndexDebug],
    Print["  EasyOCR p." <> ToString[pageNum] <> "..."]];
  (* PDF \:30d1\:30b9\:3092\:4e00\:6642\:30d5\:30a1\:30a4\:30eb\:306b\:66f8\:304d\:51fa\:3057 (\:65e5\:672c\:8a9e\:30d1\:30b9\:554f\:984c\:56de\:907f) *)
  pathFile = FileNameJoin[{$TemporaryDirectory,
    "pdfpath_" <> IntegerString[Round[AbsoluteTime[] * 1000]] <> ".txt"}];
  ocrOutFile = FileNameJoin[{$TemporaryDirectory,
    "pdfocr_" <> IntegerString[Round[AbsoluteTime[] * 1000]] <> ".txt"}];
  Export[pathFile, pdfPath, "Text", CharacterEncoding -> "UTF-8"];
  (* 400 DPI \:30ec\:30f3\:30c0\:30ea\:30f3\:30b0 + EasyOCR \:30921\:56de\:306e Python \:547c\:3073\:51fa\:3057\:3067\:5b9f\:884c *)
  pyCode = "
import os, fitz

_result = 'INIT'
try:
    import easyocr
    _reader = easyocr.Reader(['ja', 'en'], gpu=False)
    # PDF \:30d1\:30b9\:3092\:4e00\:6642\:30d5\:30a1\:30a4\:30eb\:304b\:3089\:8aad\:307f\:53d6\:308a
    with open(r'" <> StringReplace[pathFile, "\\" -> "/"] <>
      "', 'r', encoding='utf-8') as f:
        pdf_path = f.read().strip()
    doc = fitz.open(pdf_path)
    pix = doc[" <> ToString[pageNum - 1] <> "].get_pixmap(dpi=400)
    img_path = r'" <> StringReplace[
      FileNameJoin[{$TemporaryDirectory, "pdfocr_render.png"}], "\\" -> "/"] <> "'
    pix.save(img_path)
    doc.close()
    results = _reader.readtext(img_path, detail=0, paragraph=True)
    text = '\\n'.join(results)
    os.remove(img_path)
    with open(r'" <> StringReplace[ocrOutFile, "\\" -> "/"] <>
      "', 'w', encoding='utf-8') as f:
        f.write(text)
    _result = 'OK:' + str(len(text))
except Exception as e:
    _result = 'ERR:' + str(e)
_result
";
  result = Quiet[ExternalEvaluate["Python", pyCode]];
  Quiet[DeleteFile[pathFile]];
  If[TrueQ[PDFIndex`$pdfIndexDebug],
    Print["  EasyOCR result: " <> ToString[result]]];
  If[StringQ[result] && StringStartsQ[result, "ERR:"],
    Print["  EasyOCR error: " <> result]];
  text = If[FileExistsQ[ocrOutFile],
    Module[{t = Import[ocrOutFile, "Text", CharacterEncoding -> "UTF-8"]},
      Quiet[DeleteFile[ocrOutFile]]; t],
    None];
  If[StringQ[text] && StringLength[text] > 20,
    If[TrueQ[PDFIndex`$pdfIndexDebug],
      Print["  \:2714 p." <> ToString[pageNum] <> ": " <>
        ToString[StringLength[text]] <> " chars (EasyOCR)"]];
    Return[text]];
  If[TrueQ[PDFIndex`$pdfIndexDebug],
    Print["  EasyOCR\:5931\:6557 \[RightArrow] TextRecognize"]];
  iOCRPageFallback[pdfPath, pageNum]
];

(* Mathematica TextRecognize \:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af *)
iOCRPageFallback[pdfPath_String, pageNum_Integer] := Module[
  {img, wlText},
  img = Quiet @ Check[iRenderPagePyMuPDF[pdfPath, pageNum], $Failed];
  If[img =!= $Failed,
    wlText = Quiet @ Check[
      TextRecognize[img, Language -> "Japanese"], $Failed];
    If[StringQ[wlText] && StringLength[wlText] > 20,
      If[TrueQ[PDFIndex`$pdfIndexDebug],
        Print["  \:2714 p." <> ToString[pageNum] <> ": " <>
          ToString[StringLength[wlText]] <> " chars (TextRecognize)"]];
      wlText,
      $Failed],
    $Failed]
];

(* Mathematica \:30cd\:30a4\:30c6\:30a3\:30d6 PDF Import \:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af *)
iPDFExtractWL[pdfPath_String, maxPages_:None] := Module[
  {pageCount, n, allText, pageTexts, pages, title, author},
  If[TrueQ[PDFIndex`$pdfIndexDebug], Print["  [fallback] WL Import: " <> pdfPath]];
  pageCount = Quiet @ Check[
    Import[pdfPath, {"PDF", "PageCount"}], 0];
  If[pageCount === 0 || !IntegerQ[pageCount],
    (* PageCount \:53d6\:5f97\:5931\:6557\:6642\:306f\:5168\:30c6\:30ad\:30b9\:30c8\:30921\:30c1\:30e3\:30f3\:30af\:3068\:3057\:3066\:8fd4\:3059 *)
    allText = Quiet @ Check[Import[pdfPath, "Plaintext"], $Failed];
    If[StringQ[allText],
      Return[<|"metadata" -> <|"title" -> FileBaseName[pdfPath],
        "author" -> "", "subject" -> "", "creator" -> "", "producer" -> "",
        "pageCount" -> 1, "creationDate" -> "", "modDate" -> ""|>,
        "pages" -> {<|"pageNum" -> 1, "text" -> allText,
          "charCount" -> StringLength[allText]|>}|>],
      Return[<|"error" -> "PDF Import \:306b\:5931\:6557"|>]]];
  n = If[IntegerQ[maxPages], Min[maxPages, pageCount], pageCount];
  (* \:30da\:30fc\:30b8\:3054\:3068\:306e\:30c6\:30ad\:30b9\:30c8\:62bd\:51fa: \:8907\:6570\:306e\:65b9\:6cd5\:3092\:8a66\:3059 *)
  pageTexts = Quiet @ Check[
    (* \:65b9\:6cd51: {"PDF", "Plaintext"} \:306f\:30da\:30fc\:30b8\:3054\:3068\:306e\:30ea\:30b9\:30c8\:3092\:8fd4\:3059 *)
    Module[{raw = Import[pdfPath, {"PDF", "Plaintext"}]},
      If[ListQ[raw], Take[raw, UpTo[n]],
        If[StringQ[raw], {raw}, {}]]],
    {}];
  If[Length[pageTexts] === 0,
    (* \:65b9\:6cd52: "Plaintext" \:3067\:5168\:30c6\:30ad\:30b9\:30c8\:3092\:53d6\:5f97\:30571\:30c1\:30e3\:30f3\:30af\:306b *)
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
(* \:76ee\:6b21 (TOC) \:62bd\:51fa                                               *)
(* ============================================================ *)

(* PyMuPDF \:3067\:76ee\:6b21\:3092\:62bd\:51fa: [{level, title, page}, ...] *)
(* iExtractTOC: TOC\:62bd\:51fa\:3068\:540c\:6642\:306b\:30da\:30fc\:30b8\:30e9\:30d9\:30eb\:3082\:53d6\:5f97\:3057\:3001
   TOC\:30da\:30fc\:30b8\:756a\:53f7\:3092\:8ad6\:7406\[RightArrow]\:7269\:7406\:5909\:63db\:3059\:308b\:3002
   \:591a\:304f\:306ePDF\:3067\:306f\:8868\:7d19\:30fb\:76ee\:6b21\:7b49\:306e\:524d\:4ed8\:304d\:30da\:30fc\:30b8\:306b\:3088\:308a
   \:7269\:7406\:30da\:30fc\:30b8\:756a\:53f7\:3068\:5370\:5237\:30da\:30fc\:30b8\:756a\:53f7\:306b\:30aa\:30d5\:30bb\:30c3\:30c8\:304c\:3042\:308b\:3002
   get_toc()\:306f\:7269\:7406\:30da\:30fc\:30b8\:3092\:8fd4\:3059\:304c\:3001PDF\:306e\:30d6\:30c3\:30af\:30de\:30fc\:30af\:304c
   \:8ad6\:7406\:30da\:30fc\:30b8\:3067\:4f5c\:3089\:308c\:3066\:3044\:308b\:5834\:5408\:304c\:3042\:308b\:305f\:3081\:3001
   \:30e9\:30d9\:30eb\:30de\:30c3\:30d4\:30f3\:30b0\:3067\:691c\:8a3c\:30fb\:88dc\:6b63\:3059\:308b\:3002
   \:526f\:7523\:7269: $pdfIndexAsyncContext["pageLabels"] \:3082\:8a2d\:5b9a\:3059\:308b\:3002 *)
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
    toc_raw = doc.get_toc()
    # === \:30da\:30fc\:30b8\:30e9\:30d9\:30eb\:53d6\:5f97 ===
    page_count = doc.page_count
    phys_to_label = {}   # physical(1-based) -> label
    label_to_phys = {}   # label -> physical(1-based)
    has_labels = False
    for i in range(page_count):
        try:
            lbl = doc[i].get_label()
            if lbl:
                p1 = i + 1  # 1-based
                phys_to_label[p1] = lbl
                if lbl != str(p1):
                    has_labels = True
                # label -> physical (last wins for duplicates)
                label_to_phys[lbl] = p1
        except:
            pass
    # === TOC\:30da\:30fc\:30b8\:756a\:53f7 ===
    # PyMuPDF get_toc() \:306f 1-based \:7269\:7406\:30da\:30fc\:30b8\:756a\:53f7\:3092\:8fd4\:3059\:3002\:5909\:63db\:4e0d\:8981\:3002
    result_toc = []
    for t in toc_raw:
        level, title, raw_page = t[0], t[1], t[2]
        result_toc.append({'level': level, 'title': title,
                          'page': raw_page, 'rawPage': raw_page})
    # === \:30e9\:30d9\:30eb\:30de\:30c3\:30d4\:30f3\:30b0\:3082\:51fa\:529b ===
    label_map = {}
    if has_labels:
        for p1, lbl in phys_to_label.items():
            if lbl != str(p1):
                label_map[str(p1)] = lbl
    output = {'toc': result_toc, 'labels': label_map,
              'hasLabels': has_labels, 'pageCount': page_count}
    doc.close()
    with open(r'" <> StringReplace[outJsonFile, "\\" -> "/"] <>
      "', 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False)
    'done'
except Exception as e:
    str(e)
";
  result = Quiet @ Check[ExternalEvaluate["Python", pyCode], $Failed];
  If[FileExistsQ[outJsonFile],
    json = Quiet @ Check[Developer`ReadRawJSONFile[outJsonFile], $Failed];
    Quiet[DeleteFile[outJsonFile]];
    If[AssociationQ[json],
      (* \:30e9\:30d9\:30eb\:30de\:30c3\:30d4\:30f3\:30b0\:3092 $pdfIndexAsyncContext \:306b\:30ad\:30e3\:30c3\:30b7\:30e5 *)
      Module[{labels = Lookup[json, "labels", <||>]},
        If[AssociationQ[labels] && Length[labels] > 0,
          $pdfIndexAsyncContext["pageLabels"] = labels;
          If[TrueQ[PDFIndex`$pdfIndexDebug],
            Print["  \:30da\:30fc\:30b8\:30e9\:30d9\:30eb: " <>
              ToString[Length[labels]] <> "\:30da\:30fc\:30b8\:5206\:30ed\:30fc\:30c9 (\:30aa\:30d5\:30bb\:30c3\:30c8\:3042\:308a)"]]]];
      Lookup[json, "toc", {}],
      If[ListQ[json], json, {}]],
    {}]
];

(* TOC\:304b\:3089\:30af\:30a8\:30ea\:30bf\:30fc\:30e0\:306b\:30de\:30c3\:30c1\:3059\:308b\:30bb\:30af\:30b7\:30e7\:30f3\:306e\:30da\:30fc\:30b8\:7bc4\:56f2\:3092\:7279\:5b9a *)
(* \:623b\:308a\:5024: <|"section"->\:30bf\:30a4\:30c8\:30eb, "startPage"->n, "endPage"->m|> or None *)
iTOCFindPageRange[toc_List, query_String] := Module[
  {terms, bestMatch = None, bestScore = 0, bestIdx = 0},
  If[Length[toc] === 0, Return[None]];
  terms = iSplitQueryTerms[query];
  If[Length[terms] === 0, Return[None]];
  (* \:5404TOC\:30a8\:30f3\:30c8\:30ea\:3092\:30b9\:30b3\:30a2\:30ea\:30f3\:30b0 *)
  Do[
    Module[{entry = toc[[i]], title, nTitle, level, page, sc = 0},
      title = Lookup[entry, "title", ""];
      level = Lookup[entry, "level", 1];
      page = Lookup[entry, "page", 0];
      If[!StringQ[title] || !IntegerQ[page] || page <= 0, Continue[]];
      nTitle = iNormalizeForMatch[title];
      Do[
        Module[{nt = iNormalizeForMatch[t], subTerms},
          If[StringContainsQ[nTitle, nt, IgnoreCase -> True],
            (* \:5b8c\:5168\:4e00\:81f4: \:30d5\:30eb\:30b9\:30b3\:30a2 *)
            sc += StringLength[t] * 5,
            (* \:30b5\:30d6\:30bf\:30fc\:30e0\:7167\:5408: \:6f22\:5b57\:5206\:5272\:3067\:90e8\:5206\:4e00\:81f4\:3092\:8a66\:307f\:308b
               \:4f8b: "\:79d1\:76ee\:8868" \[RightArrow] {"\:79d1\:76ee","\:8868"} \[RightArrow] "\:79d1\:76ee\:914d\:5f53\:8868" \:306b "\:79d1\:76ee" \:304c\:30de\:30c3\:30c1 *)
            subTerms = Select[iSplitAtCharBoundary[nt],
              StringLength[#] >= 2 && # =!= nt &];
            Do[
              If[StringContainsQ[nTitle, st, IgnoreCase -> True],
                sc += StringLength[st] * 2],  (* \:30b5\:30d6\:30bf\:30fc\:30e0\:306f\:4f4e\:3081\:306e\:30b9\:30b3\:30a2 *)
              {st, subTerms}]]],
        {t, terms}];
      If[sc > 0,
        sc += Max[0, (4 - level) * 5];
        If[StringLength[title] < 30, sc += 3];
        (* === \:5b66\:90e8/\:5927\:5b66\:9662\:306e\:533a\:5225 ===
           \:300c\:5b66\:79d1\:300d\:3092\:542b\:3080\:30af\:30a8\:30ea\:306b\:300c\:5c02\:653b\:300d\:300c\:7814\:7a76\:79d1\:300d\:306eTOC\:30a8\:30f3\:30c8\:30ea\:3092
           \:30de\:30c3\:30c1\:3055\:305b\:306a\:3044 (\:307e\:305f\:306f\:305d\:306e\:9006)\:3002 *)
        If[AnyTrue[terms, StringContainsQ[#, "\:5b66\:79d1"] &] &&
           (StringContainsQ[title, "\:5c02\:653b"] || StringContainsQ[title, "\:7814\:7a76\:79d1"]),
          sc = 0];
        If[AnyTrue[terms, StringContainsQ[#, "\:5c02\:653b"] &] &&
           StringContainsQ[title, "\:5b66\:79d1"] && !StringContainsQ[title, "\:5c02\:653b"],
          sc = 0]];
      If[sc > bestScore,
        bestScore = sc; bestIdx = i; bestMatch = entry]],
    {i, Length[toc]}];
  If[bestMatch === None, Return[None]];

  (* \:30de\:30c3\:30c1\:3057\:305f\:30a8\:30f3\:30c8\:30ea\:306e\:30da\:30fc\:30b8\:7bc4\:56f2\:3092\:8a08\:7b97\:3002
     \:5b50\:30a8\:30f3\:30c8\:30ea\:306b\:30de\:30c3\:30c1\:3057\:305f\:5834\:5408\:30011\:3064\:4e0a\:306e\:89aa\:30a8\:30f3\:30c8\:30ea\:306e\:7bc4\:56f2\:3092\:4f7f\:3046\:3002
     \:3053\:308c\:306b\:3088\:308a\:300c\:60c5\:5831\:5de5\:5b66\:79d1 \:6559\:80b2\:76ee\:7684\:300d(p.125-127) \:3067\:306f\:306a\:304f
     \:300c\:2462\:60c5\:5831\:5de5\:5b66\:79d1\:300d(p.125-131) \:306e\:5168\:7bc4\:56f2\:304c\:30ab\:30d0\:30fc\:3055\:308c\:308b\:3002
     \:305f\:3060\:3057\:6700\:4e0a\:4f4d(level 1)\:307e\:3067\:306f\:767b\:3089\:306a\:3044\:3002 *)
  Module[{useIdx, useLevel, startPage, endPage, matchLevel, j},
    matchLevel = Lookup[bestMatch, "level", 1];
    useIdx = bestIdx;
    useLevel = matchLevel;
    (* 1\:6bb5\:3060\:3051\:89aa\:3078\:9061\:4e0a (level >= 3 \:306e\:5b50\:30a8\:30f3\:30c8\:30ea\:306e\:307f\:3002level 1 \:306b\:306f\:767b\:3089\:306a\:3044) *)
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
    (* \:6b21\:306e\:540c\:30ec\:30d9\:30eb\:4ee5\:4e0a\:306e\:30a8\:30f3\:30c8\:30ea\:3092\:63a2\:3059 \[RightArrow] \:305d\:306e\:30da\:30fc\:30b8-1 \:304c\:7d42\:4e86\:30da\:30fc\:30b8 *)
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
(* \:30da\:30fc\:30b8\:5206\:985e\:30fb\:30d3\:30b8\:30e7\:30f3\:89e3\:6790\:30fb\:30ab\:30bf\:30ed\:30b0\:69cb\:7bc9                        *)
(* ============================================================ *)

(* \:30c6\:30ad\:30b9\:30c8\:62bd\:51fa\:7d50\:679c\:304b\:3089\:8868\:30fb\:56f3\:30da\:30fc\:30b8\:3092\:691c\:51fa\:3059\:308b\:30d2\:30e5\:30fc\:30ea\:30b9\:30c6\:30a3\:30af\:30b9 *)
iIsTableOrFigurePage[pageText_String] := Module[
  {lines, shortLines, totalLines, codePattern, frontBackCount},
  If[StringLength[pageText] < 50, Return[False]];
  lines = Select[StringSplit[pageText, "\n"], StringLength[StringTrim[#]] > 0 &];
  totalLines = Length[lines];
  If[totalLines < 3, Return[False]];
  (* \:77ed\:3044\:884c (15\:6587\:5b57\:672a\:6e80) \:304c60%\:4ee5\:4e0a \[RightArrow] \:8868\:306e\:30bb\:30eb\:304c\:30d0\:30e9\:30d0\:30e9 *)
  shortLines = Count[lines, l_ /; StringLength[StringTrim[l]] < 15];
  If[shortLines > totalLines * 0.6, Return[True]];
  (* "\:524d" "\:5f8c" \:30d1\:30bf\:30fc\:30f3 (\:914d\:5f53\:8868) *)
  frontBackCount = StringCount[pageText, "\:524d"] + StringCount[pageText, "\:5f8c"];
  If[frontBackCount > 6, Return[True]];
  (* \:79d1\:76ee\:30b3\:30fc\:30c9\:30d1\:30bf\:30fc\:30f3 (T06xxx, TI6xxx) *)
  If[Length[StringCases[pageText,
      RegularExpression["[A-Z]\\d{2}[A-Z]{2,3}\\d{3}"]]] > 3, Return[True]];
  (* \:6570\:5024\:304c\:591a\:3044\:884c\:304c\:9023\:7d9a \[RightArrow] \:7d71\:8a08\:8868 *)
  False
];

(* LLM\:30d3\:30b8\:30e7\:30f3\:89e3\:6790\:306e\:4ee3\:308f\:308a\:306b PyMuPDF \:306e\:69cb\:9020\:5316\:62bd\:51fa\:3092\:4f7f\:7528\:3002
   LLM/API\:547c\:3073\:51fa\:3057\:306a\:3057\:3002ExternalEvaluate \:3067 Python \:3092\:5b9f\:884c\:3002
   \:8868\:306e\:691c\:51fa\:306f get_text("blocks") \:306e\:4f4d\:7f6e\:60c5\:5831\:304b\:3089\:884c\:3046\:3002 *)

$pythonStructuredExtractCode = "
import fitz, json, re, sys, os, warnings
warnings.filterwarnings('ignore')

def analyze_page(pdf_path, page_num):
    '''Extract structured content from a PDF page using PyMuPDF.
    Returns: {paragraphs, tables, figures, key_entities, page_type}'''
    # \:8b66\:544a\:30e1\:30c3\:30bb\:30fc\:30b8\:3092\:6291\:5236
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

    # \:30c6\:30ad\:30b9\:30c8\:30d6\:30ed\:30c3\:30af\:53d6\:5f97 (\:4f4d\:7f6e\:60c5\:5831\:4ed8\:304d)
    blocks = page.get_text('blocks')
    text_blocks = [b for b in blocks if b[6] == 0]
    img_blocks = [b for b in blocks if b[6] == 1]

    # === \:8868\:691c\:51fa ===
    tables_data = []

    # \:65b9\:6cd51: find_tables() (PyMuPDF 1.23+)
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

    # \:65b9\:6cd52: \:30c6\:30ad\:30b9\:30c8\:30d6\:30ed\:30c3\:30af\:89e3\:6790\:306b\:3088\:308b\:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af\:8868\:691c\:51fa
    if len(tables_data) == 0:
        tables_data = _detect_tables_from_blocks(text_blocks, page_height, page_num)

    # === \:6bb5\:843d\:30c6\:30ad\:30b9\:30c8 ===
    # \:8868\:306b\:4f7f\:308f\:308c\:305f\:30d6\:30ed\:30c3\:30af\:306e Y \:7bc4\:56f2\:3092\:9664\:5916
    table_y_ranges = []
    for td in tables_data:
        # \:8868\:30c7\:30fc\:30bf\:304b\:3089Y\:7bc4\:56f2\:3092\:63a8\:5b9a (\:8fd1\:4f3c)
        pass  # find_tables() \:306e\:5834\:5408\:306f bbox \:304c\:3042\:308b\:304c\:3001\:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af\:306e\:5834\:5408\:306f\:306a\:3044

    paragraphs = []
    for tb in text_blocks:
        text = tb[4].strip()
        if len(text) > 20:
            lines = text.split('\\n')
            short_ratio = sum(1 for l in lines if 0 < len(l.strip()) < 10) / max(len(lines), 1)
            if short_ratio < 0.5:
                paragraphs.append(text)

    # === \:56f3\:306e\:691c\:51fa ===
    figures = []
    for ib in img_blocks:
        fig_caption = ''
        for tb in text_blocks:
            if abs(tb[1] - ib[3]) < 30 or abs(ib[1] - tb[3]) < 30:
                cap_text = tb[4].strip()
                if any(k in cap_text for k in ['\:56f3', '\:30de\:30c3\:30d7', 'Figure', 'Chart', '\:30ab\:30ea\:30ad\:30e5\:30e9\:30e0']):
                    fig_caption = cap_text
                    break
        if fig_caption or (ib[2]-ib[0]) > 200:
            figures.append({
                'caption': fig_caption or '(\:56f3)',
                'description': f'\:30da\:30fc\:30b8{page_num}\:306e\:56f3 ({int(ib[2]-ib[0])}x{int(ib[3]-ib[1])}px)'
            })

    # === \:30da\:30fc\:30b8\:30bf\:30a4\:30d7\:5224\:5b9a ===
    page_type = 'text'
    if len(tables_data) > 0:
        page_type = 'table' if len(paragraphs) < 3 else 'mixed'
    elif len(figures) > 0 and len(paragraphs) < 3:
        page_type = 'figure'

    # === \:4e3b\:8981\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:62bd\:51fa ===
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
    '''\:8868\:306e\:4e0a\:306b\:3042\:308b\:30c6\:30ad\:30b9\:30c8\:30d6\:30ed\:30c3\:30af\:304b\:3089\:30ad\:30e3\:30d7\:30b7\:30e7\:30f3\:3092\:63a2\:3059'''
    best = ''
    best_dist = 999
    for tb in text_blocks:
        dist = table_top_y - tb[3]  # \:8868\:4e0a\:7aef - \:30d6\:30ed\:30c3\:30af\:4e0b\:7aef
        if 0 < dist < 50 and dist < best_dist:
            best = tb[4].strip().split('\\n')[0]  # \:6700\:521d\:306e\:884c\:306e\:307f
            best_dist = dist
    return best

def _detect_tables_from_blocks(text_blocks, page_height, page_num):
    '''\:30c6\:30ad\:30b9\:30c8\:30d6\:30ed\:30c3\:30af\:306e\:30d1\:30bf\:30fc\:30f3\:304b\:3089\:8868\:69cb\:9020\:3092\:691c\:51fa\:3059\:308b\:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af\:3002
    \:79d1\:76ee\:30b3\:30fc\:30c9 (T06xxx, TI6xxx) \:3092\:542b\:3080\:30d6\:30ed\:30c3\:30af\:7fa4\:3092\:8868\:3068\:3057\:3066\:8a8d\:8b58\:3002'''
    tables = []
    table_lines = []
    code_pattern = re.compile(r'[A-Z]\\d{2}[A-Z]{2,3}\\d{3}')

    # \:5168\:30c6\:30ad\:30b9\:30c8\:3092\:884c\:306b\:5206\:5272\:3057\:3066\:79d1\:76ee\:30b3\:30fc\:30c9\:30d1\:30bf\:30fc\:30f3\:3092\:691c\:51fa
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
                # \:524d\:306e\:884c\:304b\:3089\:30ad\:30e3\:30d7\:30b7\:30e7\:30f3\:3092\:63a8\:6e2c
                for j in range(max(0, i-3), i):
                    prev = lines[j].strip()
                    if len(prev) > 5 and not code_pattern.search(prev):
                        caption = prev
            table_lines.append(stripped)
            table_end_y = i
        elif in_table and len(stripped) < 5:
            # \:77ed\:3044\:884c (\:533a\:5207\:308a) \:306f\:30b9\:30ad\:30c3\:30d7
            continue
        elif in_table:
            # \:8868\:7d42\:4e86
            if len(table_lines) >= 3:
                headers, rows = _parse_table_lines(table_lines)
                continues_from = (table_start_y < 3)
                continues_to = (table_end_y > len(lines) - 5)
                # \:5099\:8003\:3092\:63a2\:3059
                notes = ''
                for j in range(table_end_y + 1, min(table_end_y + 10, len(lines))):
                    note_line = lines[j].strip()
                    if note_line.startswith(('\:5099\:8003', '\:203b', '\:6ce8', '*', '\:ff11\:ff0e', '1.')):
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

    # \:6700\:5f8c\:306e\:8868
    if in_table and len(table_lines) >= 3:
        headers, rows = _parse_table_lines(table_lines)
        tables.append({
            'caption': caption,
            'headers': headers,
            'rows': rows,
            'notes': '',
            'continues_from_previous': (table_start_y < 3),
            'continues_to_next': True  # \:30da\:30fc\:30b8\:672b\:5c3e\:307e\:3067\:7d9a\:304f
        })

    return tables

def _parse_table_lines(lines):
    '''\:79d1\:76ee\:30b3\:30fc\:30c9\:3092\:542b\:3080\:884c\:7fa4\:304b\:3089\:30d8\:30c3\:30c0\:30fc\:3068\:884c\:3092\:63a8\:6e2c'''
    # \:5404\:884c\:3092\:30bf\:30d6/\:8907\:6570\:30b9\:30da\:30fc\:30b9\:3067\:5206\:5272
    rows = []
    for line in lines:
        cells = re.split(r'\\t|\\s{2,}', line.strip())
        cells = [c.strip() for c in cells if c.strip()]
        if cells:
            rows.append(cells)
    if len(rows) == 0:
        return [], []
    # \:6700\:5927\:5217\:6570\:306b\:5408\:308f\:305b\:3066\:30d1\:30c7\:30a3\:30f3\:30b0
    max_cols = max(len(r) for r in rows)
    rows = [r + [''] * (max_cols - len(r)) for r in rows]
    # \:30d8\:30c3\:30c0\:30fc\:306f\:63a8\:5b9a (\:79d1\:76ee\:30b3\:30fc\:30c9\:3092\:542b\:307e\:306a\:3044\:6700\:521d\:306e\:884c\:3001\:307e\:305f\:306f\:56fa\:5b9a)
    headers = ['\:79d1\:76ee\:30b3\:30fc\:30c9', '\:79d1\:76ee\:540d'] + [f'\:5217{i+3}' for i in range(max_cols - 2)]
    return headers, rows
";

iAnalyzePageWithVision[pdfPath_String, pageNum_Integer] := Module[
  {escapedPath, tempDir, outFile, pyCode, result, json},
  escapedPath = StringReplace[pdfPath, "\\" -> "/"];
  (* Claude Code \:304c\:30a2\:30af\:30bb\:30b9\:3067\:304d\:308b\:30ed\:30fc\:30ab\:30eb\:30c7\:30a3\:30ec\:30af\:30c8\:30ea\:306b\:51fa\:529b *)
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

(* \:9023\:7d9a\:30da\:30fc\:30b8\:306e\:8868\:3092\:30de\:30fc\:30b8\:3002continues_from_previous/continues_to_next \:3092\:4f7f\:7528 *)
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
          (* \:524d\:306e\:30da\:30fc\:30b8\:306e\:8868\:306b\:884c\:3092\:8ffd\:52a0 *)
          currentMerge = Join[currentMerge, <|
            "rows" -> Join[Lookup[currentMerge, "rows", {}],
              Lookup[t, "rows", {}]],
            "endPage" -> pg,
            "notes" -> If[StringQ[Lookup[t, "notes", ""]] && t["notes"] =!= "",
              Lookup[currentMerge, "notes", ""] <> "\n" <> t["notes"],
              Lookup[currentMerge, "notes", ""]]|>],
          (* \:65b0\:3057\:3044\:8868\:3092\:958b\:59cb (\:524d\:306e\:8868\:304c\:3042\:308c\:3070\:78ba\:5b9a) *)
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
        (* \:6b21\:30da\:30fc\:30b8\:306b\:7d9a\:304b\:306a\:3044\:5358\:72ec\:8868\:306f\:5373\:78ba\:5b9a *)
        If[!TrueQ[Lookup[t, "continues_to_next", False]] &&
           !TrueQ[Lookup[t, "continues_from_previous", False]],
          If[currentMerge =!= None, AppendTo[allTables, currentMerge]];
          currentMerge = None],
      {t, tables}]],
  {pageResult, pageResults}];
  If[currentMerge =!= None, AppendTo[allTables, currentMerge]];
  allTables
];

(* \:30ab\:30bf\:30ed\:30b0\:69cb\:7bc9: \:8868\:30fb\:56f3\:30fb\:30bb\:30af\:30b7\:30e7\:30f3\:306e\:8efd\:91cf\:7d22\:5f15\:3002\:691c\:7d22\:306e\:30a8\:30f3\:30c8\:30ea\:30dd\:30a4\:30f3\:30c8 *)
iBuildCatalog[pageResults_List, mergedTables_List, toc_List] := Module[
  {tableCatalog, figureCatalog, sectionCatalog},
  (* \:8868\:30ab\:30bf\:30ed\:30b0: \:30ad\:30e3\:30d7\:30b7\:30e7\:30f3 + \:5217\:30d8\:30c3\:30c0 + \:4e3b\:8981\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3 *)
  tableCatalog = MapIndexed[
    <|"id" -> "t" <> ToString[#2[[1]]],
      "caption" -> Lookup[#1, "caption", ""],
      "startPage" -> #1["startPage"],
      "endPage" -> #1["endPage"],
      "headers" -> Lookup[#1, "headers", {}],
      "rowCount" -> Length[Lookup[#1, "rows", {}]],
      "notes" -> Lookup[#1, "notes", ""],
      (* \:691c\:7d22\:7528\:30b5\:30de\:30ea\:30fc: \:30ad\:30e3\:30d7\:30b7\:30e7\:30f3 + \:30d8\:30c3\:30c0 + \:5099\:8003 *)
      "searchText" -> StringJoin[
        Lookup[#1, "caption", ""], " ",
        StringRiffle[Lookup[#1, "headers", {}], " "], " ",
        Lookup[#1, "notes", ""]]
    |> &,
    mergedTables];
  (* \:56f3\:30ab\:30bf\:30ed\:30b0 *)
  figureCatalog = Flatten[
    Function[{pr},
      If[ListQ[Lookup[pr, "figures", {}]] && Length[Lookup[pr, "figures", {}]] > 0,
        MapIndexed[
          <|"id" -> "f" <> ToString[pr["pageNum"]] <> "_" <> ToString[#2[[1]]],
            "caption" -> Lookup[#1, "caption", ""],
            "page" -> pr["pageNum"],
            "description" -> Lookup[#1, "description", ""],
            "searchText" -> Lookup[#1, "caption", ""] <> " " <>
              Lookup[#1, "description", ""]
          |> &,
          pr["figures"]],
        {}]
    ] /@ pageResults];
  (* \:30bb\:30af\:30b7\:30e7\:30f3\:30ab\:30bf\:30ed\:30b0 (TOC \:30d9\:30fc\:30b9) *)
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

(* \:69cb\:9020\:5316\:30c7\:30fc\:30bf\:304b\:3089\:30c1\:30e3\:30f3\:30af\:3092\:751f\:6210\:3002
   \:8868\:306f1\:3064\:306e\:8868 = 1\:30c1\:30e3\:30f3\:30af (Markdown\:8868\:5f62\:5f0f)\:3002
   \:6bb5\:843d\:306f\:5f93\:6765\:306e\:6587\:5b57\:6570\:30d9\:30fc\:30b9\:30c1\:30e3\:30f3\:30ad\:30f3\:30b0\:3002 *)
iChunkFromStructured[pageResults_List, mergedTables_List] := Module[
  {chunks = {}, tablePages, chunkIdx = 0},
  (* \:30de\:30fc\:30b8\:6e08\:307f\:8868\:306e\:30da\:30fc\:30b8\:7bc4\:56f2\:3092\:8a18\:9332 *)
  tablePages = Flatten[
    Range[#["startPage"], #["endPage"]] & /@ mergedTables];
  (* \:8868\:30c1\:30e3\:30f3\:30af: \:5404\:30de\:30fc\:30b8\:6e08\:307f\:8868\:30921\:30c1\:30e3\:30f3\:30af\:306b *)
  Do[
    Module[{tableText, headers, rows},
      headers = Lookup[tbl, "headers", {}];
      rows = Lookup[tbl, "rows", {}];
      tableText = Lookup[tbl, "caption", ""] <> "\n\n";
      (* Markdown \:8868\:5f62\:5f0f *)
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
  (* \:6bb5\:843d\:30c1\:30e3\:30f3\:30af: \:8868\:30da\:30fc\:30b8\:4ee5\:5916\:306e\:30c6\:30ad\:30b9\:30c8 *)
  Do[
    Module[{pg = pr["pageNum"], paras, paraText},
      If[MemberQ[tablePages, pg], Continue[]];
      paras = Lookup[pr, "paragraphs", {}];
      If[!ListQ[paras] || Length[paras] === 0,
        (* \:30d3\:30b8\:30e7\:30f3\:89e3\:6790\:306a\:3057\:306e\:30da\:30fc\:30b8: rawText \:3092\:4f7f\:7528 *)
        paras = {Lookup[pr, "rawText", ""]}];
      paraText = StringTrim[StringJoin[Riffle[
        Select[paras, StringQ[#] && StringLength[#] > 0 &], "\n\n"]]];
      If[StringLength[paraText] > 0,
        (* \:9577\:3044\:6bb5\:843d\:30c6\:30ad\:30b9\:30c8\:306f\:3055\:3089\:306b\:30c1\:30e3\:30f3\:30af\:5206\:5272 *)
        Module[{subChunks},
          subChunks = iChunkText[paraText, pg];
          Do[
            chunkIdx++;
            AppendTo[chunks,
              Append[sc, "chunkIdx" -> chunkIdx]],
            {sc, subChunks}]]]],
    {pr, pageResults}];
  (* \:56f3\:30c1\:30e3\:30f3\:30af: \:56f3\:306e\:8aac\:660e\:30c6\:30ad\:30b9\:30c8 *)
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
  (* globalIdx \:3092\:632f\:308a\:76f4\:3059 *)
  MapIndexed[Append[#1, "globalIdx" -> #2[[1]]] &, chunks]
];

(* ============================================================ *)
(* \:30c1\:30e3\:30f3\:30ad\:30f3\:30b0 (\:5f93\:6765\:65b9\:5f0f: \:30d3\:30b8\:30e7\:30f3\:4e0d\:4f7f\:7528\:30da\:30fc\:30b8\:7528)                *)
(* ============================================================ *)

(* \:30da\:30fc\:30b8\:5358\:4f4d\:306e\:30c6\:30ad\:30b9\:30c8\:3092\:30bb\:30af\:30b7\:30e7\:30f3/\:6bb5\:843d\:5358\:4f4d\:306b\:30c1\:30e3\:30f3\:30af\:5206\:5272\:3059\:308b *)
iChunkText[text_String, pageNum_Integer, maxChars_:Automatic, overlap_:Automatic] :=
  Module[{mc, ol, chunks, lines, buf, bufLen, chunk},
    mc = If[IntegerQ[maxChars], maxChars, $chunkMaxChars];
    ol = If[IntegerQ[overlap], overlap, $chunkOverlap];
    (* \:77ed\:3044\:30da\:30fc\:30b8\:306f\:305d\:306e\:307e\:307e1\:30c1\:30e3\:30f3\:30af *)
    If[StringLength[text] <= mc,
      Return[{<|"pageNum" -> pageNum, "chunkIdx" -> 1,
               "text" -> StringTrim[text],
               "charCount" -> StringLength[text]|>}]];
    (* \:6bb5\:843d/\:884c\:5358\:4f4d\:3067\:5206\:5272 *)
    lines = StringSplit[text, "\n"];
    chunks = {};
    buf = "";
    bufLen = 0;
    Do[
      If[bufLen + StringLength[line] + 1 > mc && bufLen > 0,
        (* \:30d0\:30c3\:30d5\:30a1\:3092\:30c1\:30e3\:30f3\:30af\:3068\:3057\:3066\:4fdd\:5b58 *)
        AppendTo[chunks,
          <|"pageNum" -> pageNum,
            "chunkIdx" -> Length[chunks] + 1,
            "text" -> StringTrim[buf],
            "charCount" -> StringLength[StringTrim[buf]]|>];
        (* \:30aa\:30fc\:30d0\:30fc\:30e9\:30c3\:30d7: \:672b\:5c3e\:306e\:4e00\:90e8\:3092\:6b21\:306e\:30d0\:30c3\:30d5\:30a1\:306b\:5f15\:304d\:7d99\:3050 *)
        buf = If[ol > 0 && StringLength[buf] > ol,
          StringTake[buf, -ol] <> "\n" <> line,
          line];
        bufLen = StringLength[buf],
        (* \:30d0\:30c3\:30d5\:30a1\:306b\:8ffd\:52a0 *)
        buf = If[buf === "", line, buf <> "\n" <> line];
        bufLen = StringLength[buf]],
      {line, lines}];
    (* \:6b8b\:308a\:306e\:30d0\:30c3\:30d5\:30a1 *)
    If[StringLength[StringTrim[buf]] > 0,
      AppendTo[chunks,
        <|"pageNum" -> pageNum,
          "chunkIdx" -> Length[chunks] + 1,
          "text" -> StringTrim[buf],
          "charCount" -> StringLength[StringTrim[buf]]|>]];
    chunks
  ];

(* \:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:5168\:4f53\:3092\:30c1\:30e3\:30f3\:30af\:5316 *)
iChunkDocument[extractResult_Association] := Module[{pages, allChunks},
  pages = Lookup[extractResult, "pages", {}];
  If[!ListQ[pages] || Length[pages] === 0, Return[{}]];
  allChunks = Flatten[
    iChunkText[#["text"], #["pageNum"]] & /@ pages, 1];
  (* \:30b0\:30ed\:30fc\:30d0\:30eb\:306a\:30c1\:30e3\:30f3\:30af\:756a\:53f7\:3092\:632f\:308a\:76f4\:3059 *)
  MapIndexed[Append[#1, "globalIdx" -> #2[[1]]] &, allChunks]
];

(* ============================================================ *)
(* LLM \:30d8\:30eb\:30d1\:30fc: claudecode.wl \:306e ClaudeQuery/ClaudeQueryBg \:7d4c\:7531 *)
(* claudecode.wl \:4fee\:6b63\:6e08\:307f: ClaudeQueryBg \:3082 Fallback->False \:3067    *)
(*   Claude Code CLI \:3092\:4f7f\:7528\:3059\:308b (\:8ab2\:91d1\:306a\:3057)\:3002                       *)
(* Fallback -> True \:3092\:6307\:5b9a\:3057\:306a\:3044\:9650\:308a\:8ab2\:91d1API\:306f\:4f7f\:308f\:308c\:306a\:3044\:3002          *)
(* LLMSynthesize \:7b49\:306e\:76f4\:63a5\:547c\:3073\:51fa\:3057\:306f\:7981\:6b62\:3002                         *)
(* ============================================================ *)

(* \:30af\:30e9\:30a6\:30c9 LLM: ClaudeQueryBg (\:540c\:671f) \[RightArrow] ClaudeQuery (\:975e\:540c\:671f) \:306e\:9806\:3067\:8a66\:884c\:3002
   \:3069\:3061\:3089\:3082 Fallback -> False (\:30c7\:30d5\:30a9\:30eb\:30c8) \:3067 Claude Code CLI \:7d4c\:7531\:3002\:8ab2\:91d1\:306a\:3057\:3002
   ClaudeQueryBg: ScheduledTask/SocketListen \:5185\:3067\:3082\:5b89\:5168 (RunProcess \:4f7f\:7528)\:3002
   ClaudeQuery: \:30c8\:30c3\:30d7\:30ec\:30d9\:30eb\:3067\:306e\:307f\:5b89\:5168 (StartProcess + ScheduledTask \:4f7f\:7528)\:3002 *)
(* model \:5f15\:6570\:306a\:3057: \:30c7\:30d5\:30a9\:30eb\:30c8\:30e2\:30c7\:30eb (Opus) *)
iQueryCloudLLM[prompt_String] := iQueryCloudLLM[prompt, ""];

(* model \:5f15\:6570\:3042\:308a: Block \:3067 $ClaudeModel \:3092\:4e00\:6642\:7684\:306b\:5207\:308a\:66ff\:3048 *)
iQueryCloudLLM[prompt_String, model_String] := Module[{result},
  Block[{ClaudeCode`$ClaudeModel =
      If[model =!= "", model, ClaudeCode`$ClaudeModel]},
    (* ClaudeQueryBg: \:540c\:671f\:30fb\:3069\:306e\:30b3\:30f3\:30c6\:30ad\:30b9\:30c8\:3067\:3082\:5b89\:5168 *)
    If[Length[Names["ClaudeCode`ClaudeQueryBg"]] > 0,
      result = Quiet @ Check[
        ClaudeCode`ClaudeQueryBg[prompt],
        $Failed];
      If[StringQ[result] && result =!= "" && !StringStartsQ[result, "Error"], 
        Return[result]]];
    (* ClaudeQuery: \:30c8\:30c3\:30d7\:30ec\:30d9\:30eb\:3067\:306e\:307f\:5b89\:5168 *)
    If[Quiet[Check[$CurrentTask, None]] === None &&
       Quiet[Check[$ScheduledTask, None]] === None &&
       Length[Names["ClaudeCode`ClaudeQuery"]] > 0,
      result = Quiet @ Check[
        ClaudeCode`ClaudeQuery[prompt],
        $Failed];
      If[StringQ[result] && result =!= "", Return[result]]];
    ""]
];

(* \:30ed\:30fc\:30ab\:30eb LLM ($ClaudePrivateModel): maildb.wl \:7d4c\:7531 \[RightArrow] ClaudeQuery \:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af *)
iQueryLocalLLM[prompt_String] := Module[{result},
  (* maildb.wl \:304c\:5229\:7528\:53ef\:80fd\:306a\:3089\:305d\:3061\:3089\:3092\:4f7f\:3046 (LM Studio \:7b49) *)
  If[Length[Names["Maildb`Private`iQueryLocalLLM"]] > 0,
    result = Quiet @ Check[Maildb`Private`iQueryLocalLLM[prompt], $Failed];
    If[StringQ[result] && result =!= "", Return[result]]];
  (* maildb \:306a\:3057: ClaudeQuery \:306b Model -> $ClaudePrivateModel \:3092\:6307\:5b9a *)
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
(* Embedding \:30d8\:30eb\:30d1\:30fc                                            *)
(* LM Studio (localhost:1234) \:306e OpenAI \:4e92\:63db API \:3092\:76f4\:63a5\:547c\:3073\:51fa\:3057\:3002 *)
(* \:30e2\:30c7\:30eb: text-embedding-multilingual-e5-large-instruct          *)
(* \:8ab2\:91d1API\:4e0d\:4f7f\:7528\:3002\:30ed\:30fc\:30ab\:30eb\:5b9f\:884c\:3002                                  *)
(* ============================================================ *)

$embeddingEndpoint = "http://localhost:1234/v1/embeddings";
(* \:65e2\:5b9a\:306e\:57cb\:3081\:8fbc\:307f\:30e2\:30c7\:30eb\:3002bge-m3 \:306f 8192 \:30c8\:30fc\:30af\:30f3\:5bfe\:5fdc\:30fb\:591a\:8a00\:8a9e\:30fb1024\:6b21\:5143\:3067\:3001
   \:8868\:672b\:5c3e\:306e\:5e74\:5ea6\:30d8\:30c3\:30c0\:3084\:9577\:3044\:8868\:3082\:5207\:3089\:305a\:306b embedding \:3067\:304d\:308b (e5-large-instruct \:306f 512 \:4e0a\:9650)\:3002
   \:30e2\:30c7\:30eb\:540d\:306f\:8a2d\:5b9a\:5024\:3067\:3042\:308a\:3001\:5c06\:6765\:306f IndexBuildProfile(\[Section]19.5.5) \:304b\:3089\:5dee\:3057\:66ff\:3048\:308b\:3002 *)
$embeddingModel = "text-embedding-baai-bge-m3-568m";
(* embedding \:751f\:6210\:306b\:4f7f\:3046\:672c\:6587\:306e\:6700\:5927\:6587\:5b57\:6570\:3002\:9577\:30b3\:30f3\:30c6\:30ad\:30b9\:30c8\:30e2\:30c7\:30eb\:3067\:306f\:5927\:304d\:304f\:3057\:3066\:3001
   \:8868\:306e\:9014\:4e2d\:30fb\:672b\:5c3e\:306b\:3042\:308b\:5217\:898b\:51fa\:3057\:30fb\:5e74\:5ea6\:30d8\:30c3\:30c0\:30fb\:51e1\:4f8b\:3092 embedding \:306b\:542b\:3081\:308b
   (IncludeHeaderCarryover \:76f8\:5f53\:306e\:6700\:5c0f\:5b9f\:88c5)\:3002512 \:4e0a\:9650\:30e2\:30c7\:30eb\:3067\:306f ~400 \:7a0b\:5ea6\:306b\:623b\:3059\:3053\:3068\:3002 *)
$embeddingTextWindow = 6000;

(* LM Studio \:306f token \:8a8d\:8a3c\:3092\:8981\:6c42\:3059\:308b\:5834\:5408\:304c\:3042\:308b\:3002localhost LLM token \:306f NBAccess \:7d4c\:7531\:3067
   \:53d6\:5f97\:3059\:308b (NBGetLocalLLMAPIKey + AccessLevel 1.0)\:3002\:30cf\:30fc\:30c9\:30b3\:30fc\:30c9\:305b\:305a\:3001\:672a\:53d6\:5f97\:6642\:306e\:307f
   \:65e2\:5b9a "lm-studio" \:306b\:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af\:3002endpoint/model \:306f private init \:304b\:3089\:4e0a\:66f8\:304d\:53ef\:3002 *)
iEmbedLMStudioAPIKey[] := Module[{base, k},
  base = StringReplace[$embeddingEndpoint,
    {RegularExpression["/v1/embeddings$"] -> "", RegularExpression["/v1$"] -> "",
     RegularExpression["/$"] -> ""}];
  If[base === "", base = "http://localhost:1234"];
  k = Quiet @ Check[
    NBAccess`NBGetLocalLLMAPIKey["lmstudio", base, PrivacySpec -> <|"AccessLevel" -> 1.0|>],
    Null];
  If[StringQ[k] && k =!= "", k, "lm-studio"]];

iCreateEmbeddings[texts_List] := Module[{result},
  If[Length[texts] === 0, Return[{}]];
  (* 1. LM Studio (localhost:1234) \:3092\:512a\:5148\:4f7f\:7528 *)
  result = Quiet @ Check[iEmbedViaLMStudio[texts], $Failed];
  If[ListQ[result] && Length[result] === Length[texts] &&
     ListQ[First[result]] && Length[First[result]] > 10,
    Return[result]];
  (* 2. maildb.wl \:306e\:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af *)
  If[Length[Names["Maildb`Private`createEmbeddings"]] > 0,
    result = Quiet @ Check[Maildb`Private`createEmbeddings[texts], $Failed];
    If[ListQ[result] && Length[result] === Length[texts],
      Return[result]]];
  (* 3. \:5168\:3066\:5931\:6557 \[RightArrow] \:7a7a\:30d9\:30af\:30c8\:30eb (\:30ad\:30fc\:30ef\:30fc\:30c9\:691c\:7d22\:3067\:4ee3\:66ff) *)
  Print["  \:26a0 Embedding\:672a\:4f7f\:7528: LM Studio (" <> $embeddingEndpoint <>
    ") \:306b\:63a5\:7d9a\:3067\:304d\:307e\:305b\:3093"];
  ConstantArray[{}, Length[texts]]
];

(* LM Studio \:306e OpenAI \:4e92\:63db embeddings API \:3092 URLRead \:3067\:547c\:3073\:51fa\:3057\:3002
   \:30d0\:30c3\:30c1\:51e6\:7406: \:6700\:592720\:30c6\:30ad\:30b9\:30c8\:305a\:3064\:9001\:4fe1 (\:5927\:91cf\:30c6\:30ad\:30b9\:30c8\:306e\:30e1\:30e2\:30ea\:5bfe\:7b56)\:3002 *)
iEmbedViaLMStudio[texts_List] := Module[
  {batchSize = 20, allEmbeddings = {}, batch,
   body, bodyBytes, req, resp, json, embeddings},
  If[Length[texts] === 0, Return[{}]];
  Do[
    batch = texts[[i ;; Min[i + batchSize - 1, Length[texts]]]];
    batch = StringTake[#, UpTo[2000]] & /@ batch;
    (* \:30ea\:30af\:30a8\:30b9\:30c8\:69cb\:7bc9\:3002ExportByteArray \:3067\:76f4\:63a5 UTF-8 \:30d0\:30a4\:30c8\:5316\:3059\:308b\:3002
       ExportString[...,"RawJSON"]+StringToByteArray["UTF-8"] \:306f $CharacterEncoding \:304c
       ShiftJIS \:7b49\:306e\:3068\:304d\:65e5\:672c\:8a9e\:3092\:4e8c\:91cd UTF-8 \:5316\:3057\:3001LM Studio \:304c\:6587\:5b57\:5316\:3051\:30c6\:30ad\:30b9\:30c8\:3092 embed \:3057\:3066
       \:3057\:307e\:3046 (\:30ad\:30fc\:30ef\:30fc\:30c9\:306f\:52b9\:304f\:304c\:610f\:5473\:691c\:7d22\:304c\:7121\:610f\:5473\:306a\:30d9\:30af\:30c8\:30eb\:306b\:306a\:308b)\:3002 *)
    bodyBytes = ExportByteArray[
      <|"model" -> $embeddingModel, "input" -> batch|>, "RawJSON"];
    req = HTTPRequest[$embeddingEndpoint, <|
      Method -> "POST",
      "Headers" -> {"Content-Type" -> "application/json",
        "Authorization" -> "Bearer " <> iEmbedLMStudioAPIKey[]},
      "Body" -> bodyBytes|>];
    (* API \:547c\:3073\:51fa\:3057 *)
    resp = Quiet @ Check[URLRead[req, "BodyByteArray"], $Failed];
    If[!MatchQ[resp, _ByteArray],
      Return[$Failed, Module]];
    (* \:30ec\:30b9\:30dd\:30f3\:30b9\:30d1\:30fc\:30b9 *)
    json = Quiet @ Check[
      Developer`ReadRawJSONString[ByteArrayToString[resp, "UTF-8"]],
      $Failed];
    If[!AssociationQ[json] || !KeyExistsQ[json, "data"],
      Return[$Failed, Module]];
    (* embedding \:30d9\:30af\:30c8\:30eb\:3092\:62bd\:51fa (index \:9806\:306b\:30bd\:30fc\:30c8) *)
    embeddings = SortBy[json["data"], Lookup[#, "index", 0] &];
    embeddings = Lookup[#, "embedding", {}] & /@ embeddings;
    allEmbeddings = Join[allEmbeddings, embeddings],
    {i, 1, Length[texts], batchSize}];
  If[Length[allEmbeddings] === Length[texts], allEmbeddings,
    PadRight[allEmbeddings, Length[texts], {{}}]]
];

iCreateEmbeddingSession[] :=
  If[Length[Names["Maildb`Private`createEmbeddingSession"]] > 0,
    Maildb`Private`createEmbeddingSession[],
    Null];

(* \:30c6\:30ad\:30b9\:30c8\:306e\:5b89\:5168\:306a\:30a8\:30b9\:30b1\:30fc\:30d7 *)
iDoubleEscape[s_String] :=
  StringReplace[s, {"\\" -> "\\\\", "\"" -> "\\\""}];
iDoubleEscape[_] := "";

(* ============================================================ *)
(* LLM \:306b\:3088\:308b\:30c1\:30e3\:30f3\:30af\:8981\:7d04\:30fb\:30bf\:30b0\:30fb\:30d7\:30e9\:30a4\:30d0\:30b7\:30fc\:63a8\:5b9a                  *)
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

(* \:30c1\:30e3\:30f3\:30af\:306e\:8981\:7d04\:30fb\:30bf\:30b0\:751f\:6210 *)
iSummarizeChunk[chunkText_String, docTitle_String:"", useLocal_:True] :=
  Module[{prompt, raw, lines, summary = "", entities = "", tags = ""},
    prompt = $pdfChunkSummarizePrompt <>
      If[docTitle =!= "", "Document: " <> docTitle <> "\n\n", ""] <>
      StringTake[chunkText, UpTo[3000]];
    raw = If[TrueQ[useLocal], iQueryLocalLLM[prompt], iQueryCloudLLM[prompt]];
    If[!StringQ[raw], Return[<|"summary" -> "", "entities" -> "", "tags" -> ""|>]];
    (* \:884c\:30d9\:30fc\:30b9\:3067 SUMMARY/ENTITIES/TAGS \:3092\:62bd\:51fa *)
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

(* \:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:5168\:4f53\:306e\:30d7\:30e9\:30a4\:30d0\:30b7\:30fc\:63a8\:5b9a *)
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
(* \:56fa\:6709\:540d\:8a5e\:30fb\:5c02\:9580\:7528\:8a9e\:30a4\:30f3\:30c7\:30c3\:30af\:30b9 (Entity Index)                  *)
(* ============================================================ *)
(* \:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:30ec\:30d9\:30eb\:306e\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:30ec\:30b8\:30b9\:30c8\:30ea\:3002                   *)
(* \:56fa\:6709\:540d\:8a5e (\:5b66\:79d1\:540d, \:4eba\:540d, \:5efa\:7269\:540d\:7b49) \:3068\:5c02\:9580\:7528\:8a9e\:3092\:6b63\:898f\:5316\:3057\:3001      *)
(* \:30a8\:30a4\:30ea\:30a2\:30b9 (\:8868\:8a18\:3086\:308c) \[RightArrow] \:6b63\:898f\:540d \:306e\:30de\:30c3\:30d4\:30f3\:30b0\:3092\:63d0\:4f9b\:3059\:308b\:3002       *)
(* \:691c\:7d22\:6642\:306b\:30af\:30a8\:30ea\:30bf\:30fc\:30e0\:3092\:6b63\:898f\:5316\:3059\:308b\:3053\:3068\:3067\:3001                       *)
(* \:300c\:6a5f\:68b0\:5de5\:5b66\:79d1\:300d\[RightArrow]\:300c\:6a5f\:68b0\:30b7\:30b9\:30c6\:30e0\:5de5\:5b66\:79d1\:300d\:7b49\:306e\:89e3\:6c7a\:3092\:884c\:3046\:3002         *)

$pdfEntityIndexPrompt =
  "\:3042\:306a\:305f\:306fPDF\:6587\:66f8\:306e\:56fa\:6709\:540d\:8a5e\:30fb\:5c02\:9580\:7528\:8a9e\:30ec\:30b8\:30b9\:30c8\:30ea\:3092\:4f5c\:6210\:3059\:308b\:30a8\:30ad\:30b9\:30d1\:30fc\:30c8\:3067\:3059\:3002\n\n" <>
  "\:3010\:30bf\:30b9\:30af\:3011\n" <>
  "\:4ee5\:4e0b\:306e\:30c1\:30e3\:30f3\:30af\:8981\:7d04\:30fb\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:4e00\:89a7\:304b\:3089\:3001\:3053\:306e\:6587\:66f8\:306b\:304a\:3051\:308b\:56fa\:6709\:540d\:8a5e\:30fb\:5c02\:9580\:7528\:8a9e\:3092\:62bd\:51fa\:3057\:3066\:304f\:3060\:3055\:3044\:3002\n\n" <>
  "\:3010\:56fa\:6709\:540d\:8a5e\:306e\:5b9a\:7fa9\:3011\n" <>
  "\:3053\:306e\:6587\:66f8\:306e\:4e2d\:3067\:7279\:5b9a\:306e\:5b9f\:5728\:3059\:308b\:5bfe\:8c61\:3092\:6307\:3059\:8a9e\:3002\n" <>
  "\:4f8b: \:5b66\:79d1\:540d(\:6a5f\:68b0\:30b7\:30b9\:30c6\:30e0\:5de5\:5b66\:79d1), \:4eba\:540d, \:5efa\:7269\:540d(1\:53f7\:9928), \:90e8\:7f72\:540d(\:6559\:52d9\:8ab2), \:79d1\:76ee\:540d(\:96e2\:6563\:6570\:5b66)\n" <>
  "\:300c\:5b66\:79d1\:300d\:300c\:5b66\:751f\:300d\:306e\:3088\:3046\:306a\:4e00\:822c\:540d\:8a5e\:306f\:9664\:5916\:3002\n\n" <>
  "\:3010\:5c02\:9580\:7528\:8a9e\:306e\:5b9a\:7fa9\:3011\n" <>
  "\:3053\:306e\:6587\:66f8\:306e\:4e2d\:3067\:5b9a\:7fa9\:3084\:5236\:5ea6\:306b\:57fa\:3065\:3044\:3066\:4f7f\:308f\:308c\:308b\:7528\:8a9e\:3002\n" <>
  "\:4f8b: \:914d\:5f53\:671f, GPA, CAP\:5236, \:5fc5\:4fee\:79d1\:76ee, \:9078\:629e\:5fc5\:4fee, \:5352\:696d\:8981\:4ef6\n\n" <>
  "\:3010\:51fa\:529b\:5f62\:5f0f\:3011 1\:884c1\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:3001\:30bf\:30d6\:533a\:5207\:308a:\n" <>
  "CANONICAL\tTYPE\tALIASES\n" <>
  "\:6b63\:5f0f\:540d\:79f0\ttype\t\:30a8\:30a4\:30ea\:30a2\:30b91,\:30a8\:30a4\:30ea\:30a2\:30b92,...\n\n" <>
  "TYPE\:306f: department, person, organization, building, subject, term \:306e\:3044\:305a\:308c\:304b\n" <>
  "ALIASES\:306f\:3001\:305d\:306e\:6b63\:5f0f\:540d\:79f0\:3092\:691c\:7d22\:3059\:308b\:3068\:304d\:306b\:4f7f\:308f\:308c\:3046\:308b\:8868\:8a18\:3086\:308c\:30fb\:7565\:79f0\:30fb\:90e8\:5206\:540d\:79f0\n" <>
  "\:4f8b: \:6a5f\:68b0\:30b7\:30b9\:30c6\:30e0\:5de5\:5b66\:79d1\tdepartment\t\:6a5f\:68b0\:5de5\:5b66\:79d1,\:30b7\:30b9\:30c6\:30e0\:5de5\:5b66\:79d1,\:6a5f\:30b7\:30b9\n\n" <>
  "\:3010\:6ce8\:610f\:3011\n" <>
  "- \:6587\:66f8\:5168\:4f53\:3067\:6700\:592750\:500b\:7a0b\:5ea6\:306b\:7d5e\:308b\n" <>
  "- \:30a8\:30a4\:30ea\:30a2\:30b9\:306b\:306f\:7701\:7565\:5f62\:3001\:90e8\:5206\:4e00\:81f4\:3067\:691c\:7d22\:3055\:308c\:3046\:308b\:8868\:73fe\:3092\:542b\:3081\:308b\n" <>
  "- \:30d8\:30c3\:30c0\:884c CANONICAL\tTYPE\tALIASES \:3092\:51fa\:529b\:3057\:306a\:3044\:3067\:304f\:3060\:3055\:3044\n\n" <>
  "\:3010\:6587\:66f8\:30bf\:30a4\:30c8\:30eb\:3011\n";

(* \:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:3092\:751f\:6210 *)
iGenerateEntityIndex[processedChunks_List, docTitle_String,
    useLocal_:True] :=
  Module[{entitiesList, summariesList, inputText, raw, lines, entities = {}},
    (* \:5168\:30c1\:30e3\:30f3\:30af\:304b\:3089\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:3068\:8981\:7d04\:3092\:53ce\:96c6 *)
    entitiesList = DeleteDuplicates[Flatten[
      StringSplit[Lookup[#, "entities", ""], ","] & /@ processedChunks]];
    entitiesList = StringTrim /@ Select[entitiesList, StringLength[#] >= 2 &];
    summariesList = Select[Lookup[#, "summary", ""] & /@ processedChunks,
      StringLength[#] > 5 &];
    If[Length[entitiesList] < 3 && Length[summariesList] < 3,
      Print["  \:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:304c\:5c11\:306a\:3059\:304e\:308b\:305f\:3081\:30b9\:30ad\:30c3\:30d7"];
      Return[{}]];
    inputText = $pdfEntityIndexPrompt <> docTitle <> "\n\n" <>
      "\:3010\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:4e00\:89a7\:3011\n" <>
      StringRiffle[Take[entitiesList, UpTo[200]], ", "] <> "\n\n" <>
      "\:3010\:30c1\:30e3\:30f3\:30af\:8981\:7d04\:62dc\:8981\:3011\n" <>
      StringRiffle[Take[summariesList, UpTo[50]], "\n"];
    raw = If[TrueQ[useLocal], iQueryLocalLLM[inputText], iQueryCloudLLM[inputText]];
    If[!StringQ[raw],
      Print["  \:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:751f\:6210\:5931\:6557"];
      Return[{}]];
    (* \:51fa\:529b\:3092\:30d1\:30fc\:30b9: \:30bf\:30d6\:533a\:5207\:308a *)
    lines = StringSplit[raw, "\n"];
    Do[
      Module[{parts = StringSplit[StringTrim[l], "\t"],
              canonical, type, aliases},
        If[Length[parts] >= 2,
          canonical = StringTrim[parts[[1]]];
          type = StringTrim[parts[[2]]];
          aliases = If[Length[parts] >= 3,
            StringTrim /@ StringSplit[parts[[3]], ","],
            {}];
          (* \:30d8\:30c3\:30c0\:884c\:3092\:30b9\:30ad\:30c3\:30d7 *)
          If[canonical =!= "CANONICAL" && StringLength[canonical] >= 2,
            AppendTo[entities,
              <|"canonical" -> canonical,
                "type" -> type,
                "aliases" -> Select[aliases, StringLength[#] >= 2 &]|>]]]],
      {l, lines}];
    (* \:30da\:30fc\:30b8\:60c5\:5831\:3092\:4ed8\:4e0e: \:5404\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:304c\:51fa\:73fe\:3059\:308b\:30c1\:30e3\:30f3\:30af\:306e\:30da\:30fc\:30b8\:3092\:53ce\:96c6 *)
    entities = Map[
      Module[{ent = #, canon = #["canonical"], pages},
        pages = DeleteDuplicates[Flatten[Table[
          If[StringContainsQ[
              Lookup[c, "text", ""] <> " " <> Lookup[c, "entities", ""],
              canon, IgnoreCase -> True],
            Lookup[c, "pageNum", 0],
            Nothing],
          {c, processedChunks}]]];
        Append[ent, "pages" -> Select[pages, IntegerQ[#] && # > 0 &]]] &,
      entities];
    Print["  \:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:30a4\:30f3\:30c7\:30c3\:30af\:30b9: " <>
      ToString[Length[entities]] <> "\:4ef6\:751f\:6210"];
    entities
  ];

(* \:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:3092\:30ed\:30fc\:30c9 *)
iLoadEntityIndex[collection_String] :=
  Module[{dirs, entityFiles, entities = {}, collFile},
    dirs = {iCollectionDir[collection, "private"],
            iCollectionDir[collection, "public"]};
    (* \:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:30ec\:30d9\:30eb\:306e\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:30d5\:30a1\:30a4\:30eb\:3092\:512a\:5148\:30ed\:30fc\:30c9 *)
    Do[collFile = FileNameJoin[{d, "entities_collection.wl"}];
      If[FileExistsQ[collFile],
        Module[{data = Quiet @ Check[Get[collFile], {}]},
          If[ListQ[data], entities = Join[entities, data]]]],
      {d, dirs}];
    (* \:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:5225\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:30d5\:30a1\:30a4\:30eb\:3082\:30ed\:30fc\:30c9 (\:65e2\:5b58\:4e92\:63db) *)
    entityFiles = Flatten[FileNames["entities_*.wl", #] & /@ dirs];
    entityFiles = Select[entityFiles,
      !StringContainsQ[#, "entities_collection"] &];
    Do[Module[{data = Quiet @ Check[Get[f], {}]},
      If[ListQ[data], entities = Join[entities, data]]],
      {f, entityFiles}];
    (* \:91cd\:8907\:9664\:53bb: canonical\:540d\:304c\:540c\:3058\:306a\:3089\:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:30ec\:30d9\:30eb\:3092\:512a\:5148 *)
    DeleteDuplicatesBy[entities, Lookup[#, "canonical", ""] &]
  ];

(* \:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:306e\:30ad\:30e3\:30c3\:30b7\:30e5 *)
$entityIndexCache = <||>;

iGetEntityIndex[collection_String] :=
  Module[{cached = Lookup[$entityIndexCache, collection, None]},
    If[cached =!= None, cached,
      Module[{idx = iLoadEntityIndex[collection]},
        $entityIndexCache[collection] = idx;
        idx]]];

(* \:30af\:30a8\:30ea\:30bf\:30fc\:30e0\:3092\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:3067\:6b63\:898f\:5316
   \:8fd4\:308a\:5024: {\:6b63\:898f\:5316\:6e08\:307f\:30bf\:30fc\:30e0, ...}
   \:5404\:30bf\:30fc\:30e0\:306b\:3064\:3044\:3066:
     1. \:6b63\:898f\:540d\:306b\:5b8c\:5168\:4e00\:81f4 \[RightArrow] \:305d\:306e\:307e\:307e
     2. \:30a8\:30a4\:30ea\:30a2\:30b9\:306b\:5b8c\:5168\:4e00\:81f4 \[RightArrow] \:6b63\:898f\:540d\:306b\:7f6e\:63db
     3. \:30a8\:30a4\:30ea\:30a2\:30b9\:306b\:90e8\:5206\:4e00\:81f4 (\:30bf\:30fc\:30e0\[RightArrow]\:30a8\:30a4\:30ea\:30a2\:30b9 or \:30a8\:30a4\:30ea\:30a2\:30b9\[RightArrow]\:30bf\:30fc\:30e0) \[RightArrow] \:6b63\:898f\:540d\:306b\:7f6e\:63db
     4. \:672a\:77e5\:8a9e \[RightArrow] \:305d\:306e\:307e\:307e *)
iNormalizeQueryWithEntities[terms_List, collection_String] :=
  Module[{entities = iGetEntityIndex[collection], normalized = {},
          resolvedEntities = <||>},
    If[Length[entities] === 0, Return[terms]];
    Do[
      Module[{matched = False, bestCanon = None, bestScore = 0},
        (* 1. \:6b63\:898f\:540d\:306b\:5b8c\:5168\:4e00\:81f4 *)
        Do[If[t === ent["canonical"], matched = True; bestCanon = t; Break[]],
          {ent, entities}];
        (* 2. \:30a8\:30a4\:30ea\:30a2\:30b9\:306b\:5b8c\:5168\:4e00\:81f4 *)
        If[!matched,
          Do[If[MemberQ[Lookup[ent, "aliases", {}], t],
              matched = True; bestCanon = ent["canonical"]; Break[]],
            {ent, entities}]];
        (* 3. \:90e8\:5206\:4e00\:81f4: t \:304c\:30a8\:30a4\:30ea\:30a2\:30b9\:3092\:542b\:3080 or \:30a8\:30a4\:30ea\:30a2\:30b9\:304c t \:3092\:542b\:3080 *)
        If[!matched,
          Do[
            Module[{aliases = Prepend[Lookup[ent, "aliases", {}], ent["canonical"]]},
              Do[
                Module[{score = 0},
                  Which[
                    StringContainsQ[a, t], score = StringLength[t],
                    StringContainsQ[t, a], score = StringLength[a],
                    True, score = 0];
                  (* \:6700\:4f4e3\:6587\:5b57\:4ee5\:4e0a\:306e\:4e00\:81f4\:3067\:3001\:304b\:3064\:73fe\:5728\:306e\:30d9\:30b9\:30c8\:3088\:308a\:826f\:3044\:5834\:5408 *)
                  If[score >= 3 && score > bestScore,
                    bestScore = score;
                    bestCanon = ent["canonical"]]],
                {a, aliases}]],
            {ent, entities}];
          If[bestCanon =!= None, matched = True]];
        If[matched && bestCanon =!= None,
          AppendTo[normalized, bestCanon];
          resolvedEntities[t] = bestCanon;
          If[t =!= bestCanon,
            Print["  \:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:89e3\:6c7a: \"" <> t <> "\" \[RightArrow] \"" <>
              bestCanon <> "\""]],
          AppendTo[normalized, t]]],
      {t, terms}];
    DeleteDuplicates[normalized]
  ];

(* \:65e2\:5b58\:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:306e\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:3092\:69cb\:7bc9/\:518d\:69cb\:7bc9 *)
PDFIndex`pdfBuildEntityIndex[collection_String:"default"] :=
  Module[{docs, chunks, allChunks},
    docs = iLoadCollectionDocs[collection];
    allChunks = iLoadCollectionChunks[collection];
    If[Length[docs] === 0, Print["\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:304c\:3042\:308a\:307e\:305b\:3093"]; Return[$Failed]];
    Do[
      Module[{did = Lookup[d, "docId", ""], title = Lookup[d, "title", ""],
              docChunks, entityIdx, indexDir, ef, privacy},
        docChunks = Select[allChunks, Lookup[#, "docId", ""] === did &];
        Print["--- " <> title <> " (" <> ToString[Length[docChunks]] <> " chunks) ---"];
        entityIdx = iGenerateEntityIndex[docChunks, title, True];
        If[ListQ[entityIdx] && Length[entityIdx] > 0,
          privacy = Lookup[d, "privacy", 0];
          indexDir = If[privacy > 0.5,
            iCollectionDir[collection, "private"],
            iCollectionDir[collection, "public"]];
          ef = FileNameJoin[{indexDir, "entities_" <> did <> ".wl"}];
          Put[entityIdx, ef];
          Print["  \:4fdd\:5b58: " <> ef]]],
      {d, docs}];
    $entityIndexCache = KeyDrop[$entityIndexCache, collection];
    Print[Style["\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:69cb\:7bc9\:5b8c\:4e86", Darker[Green]]];
  ];

(* ============================================================ *)
(* \:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:30ec\:30d9\:30eb \:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:30a4\:30f3\:30c7\:30c3\:30af\:30b9 (TOC\:81ea\:52d5\:751f\:6210)       *)
(* \:30ab\:30c6\:30b4\:30ea\:30fc: department, faculty, facility, course             *)
(* ============================================================ *)

PDFIndex`pdfBuildCollectionEntities[collection_String:"default"] :=
  Module[{allDocs, allTocEntries = {}, entities = {},
          deptNames = {}, facNames = {}, facilityNames = {},
          indexDir, outFile},
    allDocs = iLoadCollectionDocs[collection];
    If[Length[allDocs] === 0,
      Print["\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:304c\:3042\:308a\:307e\:305b\:3093"]; Return[$Failed]];

    (* === Phase 1: \:5168\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:306eTOC + \:30bf\:30a4\:30c8\:30eb\:304b\:3089\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:62bd\:51fa === *)
    Do[Module[{sp = Lookup[ad, "sourcePath", ""],
               dTitle = Lookup[ad, "title", ""],
               dPath, dToc},
      dPath = iResolveSourcePath[sp];
      If[StringQ[dPath] && FileExistsQ[dPath],
        dToc = iExtractTOC[dPath];
        If[ListQ[dToc],
          Do[Module[{title = Lookup[e, "title", ""],
                     page = Lookup[e, "page", 0]},
            If[StringQ[title] && IntegerQ[page] && page > 0,
              AppendTo[allTocEntries,
                <|"title" -> iNormalizeForMatch[title], "page" -> page|>]]],
            {e, dToc}]]];
      (* \:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:30bf\:30a4\:30c8\:30eb\:304b\:3089\:3082\:62bd\:51fa *)
      AppendTo[allTocEntries,
        <|"title" -> iNormalizeForMatch[dTitle], "page" -> 0|>]],
      {ad, allDocs}];

    Print["  TOC\:30a8\:30f3\:30c8\:30ea\:53ce\:96c6: " <> ToString[Length[allTocEntries]] <> "\:4ef6"];

    (* === Phase 2: \:30d1\:30bf\:30fc\:30f3\:30de\:30c3\:30c1\:30f3\:30b0\:3067\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:62bd\:51fa === *)
    (* \:500b\:5225\:306eTOC\:30bf\:30a4\:30c8\:30eb\:304b\:3089\:30d1\:30bf\:30fc\:30f3\:62bd\:51fa *)
    Do[Module[{t = Lookup[entry, "title", ""]},
      (* \:5b66\:79d1: \:62ec\:5f27\:5185 \:300c\:ff08XX\:5b66\:79d1\:ff09\:300d *)
      Do[AppendTo[deptNames, m],
        {m, StringCases[t, ("(" | "\:ff08") ~~ d : Shortest[Repeated[_, {4, 20}]] ~~
          "\:5b66\:79d1" ~~ (")" | "\:ff09") :> d <> "\:5b66\:79d1"]}];
      (* \:5b66\:79d1: \:30bf\:30a4\:30c8\:30eb\:5148\:982d\:4ed8\:8fd1 \:300cNNN XX\:5b66\:79d1 YY\:300d *)
      If[StringContainsQ[t, "\:5b66\:79d1"],
        Module[{parts = StringCases[t, x : (Repeated[
              Except[WhitespaceCharacter | "(" | ")" | "\:ff08" | "\:ff09" |
                     "," | "\:3001" | "\:ff0c"], {4, 20}] ~~ "\:5b66\:79d1") :> x]},
          Do[If[!StringContainsQ[p, DigitCharacter] &&
                StringLength[p] >= 4 && StringLength[p] <= 15,
            AppendTo[deptNames, p]],
            {p, parts}]]];
      (* \:5b66\:90e8 *)
      If[StringContainsQ[t, "\:5b66\:90e8"],
        Do[AppendTo[facNames, m],
          {m, StringCases[t, x : (Repeated[
            Except[WhitespaceCharacter | DigitCharacter], {2, 10}] ~~
            "\:5b66\:90e8") :> x]}]];
      (* \:30bb\:30f3\:30bf\:30fc *)
      If[StringContainsQ[t, "\:30bb\:30f3\:30bf\:30fc"],
        Do[AppendTo[facilityNames, m],
          {m, StringCases[t, x : (Repeated[
            Except[WhitespaceCharacter], {2, 15}] ~~
            "\:30bb\:30f3\:30bf\:30fc") :> x]}]]],
      {entry, allTocEntries}];
    deptNames = DeleteDuplicates[Select[deptNames, StringLength[#] >= 4 &]];
    facNames = DeleteDuplicates[Select[facNames,
      StringLength[#] >= 4 &&
      !StringContainsQ[#, "\:5927\:5b66\:5b66\:90e8"] &]];
    facilityNames = DeleteDuplicates[Select[facilityNames,
      StringLength[#] >= 5 &]];

    Print["  \:62bd\:51fa: \:5b66\:79d1=" <> ToString[Length[deptNames]] <>
      ", \:5b66\:90e8=" <> ToString[Length[facNames]] <>
      ", \:65bd\:8a2d=" <> ToString[Length[facilityNames]]];

    (* === Phase 3: \:30a8\:30a4\:30ea\:30a2\:30b9\:81ea\:52d5\:751f\:6210 === *)

    (* \:5b66\:79d1\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3 *)
    Do[Module[{aliases = {}, canon = name, pages = {}},
      (* \:30a8\:30a4\:30ea\:30a2\:30b91: "\:30b7\:30b9\:30c6\:30e0" \:3092\:9664\:53bb \[RightArrow] "\:6a5f\:68b0\:5de5\:5b66\:79d1" *)
      If[StringContainsQ[canon, "\:30b7\:30b9\:30c6\:30e0"],
        AppendTo[aliases, StringReplace[canon, "\:30b7\:30b9\:30c6\:30e0" -> ""]]];
      (* \:30a8\:30a4\:30ea\:30a2\:30b92: \:672b\:5c3e\:306e "\:5b66\:79d1" \:3092\:9664\:53bb \[RightArrow] "\:6a5f\:68b0\:30b7\:30b9\:30c6\:30e0\:5de5" *)
      If[StringLength[StringDelete[canon, "\:5b66\:79d1"]] >= 3,
        AppendTo[aliases, StringDelete[canon, "\:5b66\:79d1"]]];
      (* \:30a8\:30a4\:30ea\:30a2\:30b93: "\:30b7\:30b9\:30c6\:30e0" \:9664\:53bb + "\:5b66\:79d1" \:9664\:53bb *)
      If[StringContainsQ[canon, "\:30b7\:30b9\:30c6\:30e0"],
        Module[{short = StringReplace[StringDelete[canon, "\:5b66\:79d1"],
                  "\:30b7\:30b9\:30c6\:30e0" -> ""]},
          If[StringLength[short] >= 2, AppendTo[aliases, short]]]];
      (* \:30da\:30fc\:30b8\:53ce\:96c6: TOC\:30a8\:30f3\:30c8\:30ea\:3067canon\:540d\:3092\:542b\:3080\:3082\:306e *)
      pages = DeleteDuplicates[
        Select[Lookup[#, "page", 0] & /@
          Select[allTocEntries,
            StringContainsQ[Lookup[#, "title", ""], canon,
              IgnoreCase -> True] &],
          IntegerQ[#] && # > 0 &]];
      aliases = DeleteDuplicates[Select[aliases,
        StringLength[#] >= 2 && # =!= canon &]];
      AppendTo[entities,
        <|"type" -> "department", "canonical" -> canon,
          "aliases" -> aliases, "pages" -> pages|>]],
      {name, deptNames}];

    (* \:5b66\:90e8\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3 *)
    Do[Module[{aliases = {}, pages = {}},
      If[StringLength[StringDelete[name, "\:5b66\:90e8"]] >= 2,
        AppendTo[aliases, StringDelete[name, "\:5b66\:90e8"]]];
      pages = DeleteDuplicates[
        Select[Lookup[#, "page", 0] & /@
          Select[allTocEntries,
            StringContainsQ[Lookup[#, "title", ""], name,
              IgnoreCase -> True] &],
          IntegerQ[#] && # > 0 &]];
      AppendTo[entities,
        <|"type" -> "faculty", "canonical" -> name,
          "aliases" -> Select[aliases, # =!= name &],
          "pages" -> pages|>]],
      {name, facNames}];

    (* \:65bd\:8a2d\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3 *)
    Do[Module[{pages = {}},
      pages = DeleteDuplicates[
        Select[Lookup[#, "page", 0] & /@
          Select[allTocEntries,
            StringContainsQ[Lookup[#, "title", ""], name,
              IgnoreCase -> True] &],
          IntegerQ[#] && # > 0 &]];
      AppendTo[entities,
        <|"type" -> "facility", "canonical" -> name,
          "aliases" -> {}, "pages" -> pages|>]],
      {name, facilityNames}];

    (* === Phase 4: \:4fdd\:5b58 === *)
    indexDir = iCollectionDir[collection, "public"];
    If[!DirectoryQ[indexDir], CreateDirectory[indexDir]];
    outFile = FileNameJoin[{indexDir, "entities_collection.wl"}];
    Put[entities, outFile];
    (* \:30ad\:30e3\:30c3\:30b7\:30e5\:30af\:30ea\:30a2 *)
    $entityIndexCache = KeyDrop[$entityIndexCache, collection];
    Print["\n  === \:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:30a4\:30f3\:30c7\:30c3\:30af\:30b9 ==="];
    Do[Print["  " <> e["type"] <> ": " <> e["canonical"] <>
      If[Length[e["aliases"]] > 0,
        " (\:5225\:540d: " <> StringRiffle[e["aliases"], ", "] <> ")",
        ""] <>
      " [" <> ToString[Length[e["pages"]]] <> "p]"],
      {e, entities}];
    Print["\n  \:4fdd\:5b58: " <> outFile <>
      " (" <> ToString[Length[entities]] <> "\:4ef6)"];
    entities
  ];

(* ============================================================ *)
(* \:5e74\:5ea6\:30fb\:7248\:30e1\:30bf\:30c7\:30fc\:30bf\:62bd\:51fa                                        *)
(* ============================================================ *)

(* \:5168\:89d2\:6570\:5b57\[RightArrow]\:534a\:89d2\:6570\:5b57 *)
iNormalizeDigits[s_String] := StringReplace[s, {
  "\:ff10" -> "0", "\:ff11" -> "1", "\:ff12" -> "2", "\:ff13" -> "3", "\:ff14" -> "4",
  "\:ff15" -> "5", "\:ff16" -> "6", "\:ff17" -> "7", "\:ff18" -> "8", "\:ff19" -> "9"}];

(* \:548c\:66a6\[RightArrow]\:897f\:66a6\:5909\:63db *)
iJapaneseEraToWestern[era_String, num_Integer] := Which[
  StringMatchQ[era, ("\:4ee4\:548c" | "R") ~~ ___], 2018 + num,
  StringMatchQ[era, ("\:5e73\:6210" | "H") ~~ ___], 1988 + num,
  StringMatchQ[era, ("\:662d\:548c" | "S") ~~ ___], 1925 + num,
  True, 0];

(* \:897f\:66a6\[RightArrow]\:548c\:66a6\:6587\:5b57\:5217 *)
iWesternToJapaneseEra[wy_Integer] := Which[
  wy >= 2019, "\:4ee4\:548c" <> ToString[wy - 2018],
  wy >= 1989, "\:5e73\:6210" <> ToString[wy - 1988],
  wy >= 1926, "\:662d\:548c" <> ToString[wy - 1925],
  True, ToString[wy]];

(* \:30c6\:30ad\:30b9\:30c8\:304b\:3089\:5e74\:5ea6\:60c5\:5831\:3092\:62bd\:51fa\:3059\:308b\:3002
   \:5bfe\:8c61\:30d1\:30bf\:30fc\:30f3: \:4ee4\:548cX\:5e74\:5ea6, R5\:5e74\:5ea6, \:5e73\:6210X\:5e74\:5ea6, H30\:5e74\:5ea6, 20XX\:5e74\:5ea6
   \:30b3\:30f3\:30c6\:30ad\:30b9\:30c8: \:5165\:5b66\:8005, \:9069\:7528, \:7248, \:5e74\:9451, \:8981\:89a7, \:4fbf\:89a7
   \:8fd4\:308a\:5024: <|"rawText" -> "\:4ee4\:548c4\:5e74\:5ea6\:5165\:5b66\:8005\:306b\:9069\:7528",
            "westernYear" -> 2022,
            "japaneseYear" -> "\:4ee4\:548c4",
            "context" -> "\:5165\:5b66\:8005\:9069\:7528"|>  or None *)
iExtractYearInfo[texts__String] := Module[
  {allText, matches, best = None, bestYear = 0},
  allText = iNormalizeDigits[StringJoin[Riffle[{texts}, "\n"]]];
  (* \:4ee4\:548c/\:5e73\:6210/\:662d\:548c X\:5e74\:5ea6 (\:6b63\:5f0f\:8868\:8a18) *)
  matches = StringCases[allText,
    RegularExpression["(\:4ee4\:548c|\:5e73\:6210|\:662d\:548c)(\\d{1,2})\:5e74\:5ea6([\:5165\:5b66\:8005\:306b\:9069\:7528\:7248\:9451\:89a7\:4fbf]{0,10})"] :>
      {"$1", "$2", "$3"}];
  (* R/H/S \:7565\:79f0 X\:5e74\:5ea6 *)
  matches = Join[matches, StringCases[allText,
    RegularExpression["(?<![A-Za-z])(R|H|S)(\\d{1,2})\:5e74\:5ea6([\:5165\:5b66\:8005\:306b\:9069\:7528\:7248\:9451\:89a7\:4fbf]{0,10})"] :>
      {"$1", "$2", "$3"}]];
  Do[
    Module[{era = m[[1]], numStr = m[[2]], ctx = m[[3]], wy},
      wy = iJapaneseEraToWestern[era, ToExpression[numStr]];
      If[wy > bestYear,
        bestYear = wy;
        best = <|"rawText" -> era <> numStr <> "\:5e74\:5ea6" <> ctx,
                 "westernYear" -> wy,
                 "japaneseYear" -> iWesternToJapaneseEra[wy],
                 "context" -> ctx|>]],
    {m, matches}];
  (* \:897f\:66a6 + \:5e74\:5ea6 *)
  If[best === None,
    matches = StringCases[allText,
      RegularExpression["(20\\d{2})\:5e74\:5ea6"] :> "$1"];
    If[Length[matches] > 0,
      bestYear = ToExpression[First[matches]];
      best = <|"rawText" -> First[matches] <> "\:5e74\:5ea6",
               "westernYear" -> bestYear,
               "japaneseYear" -> iWesternToJapaneseEra[bestYear],
               "context" -> ""|>]];
  (* \:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af: \:30d5\:30a1\:30a4\:30eb\:540d\:7b49\:304b\:3089\:5e74\:5ea6\:306a\:3057\:3067\:62bd\:51fa
     "R05", "H30" (\:5358\:72ec) or "2023" (\:5358\:72ec) *)
  If[best === None,
    matches = StringCases[allText,
      RegularExpression["(?<![A-Za-z])(R|H|S)(0?\\d{1,2})(?![\\d\:5e74])"] :>
        {"$1", "$2"}];
    Do[Module[{era = m[[1]], numStr = m[[2]], wy},
      wy = iJapaneseEraToWestern[era, ToExpression[numStr]];
      If[wy > 2000 && wy > bestYear,
        bestYear = wy;
        best = <|"rawText" -> era <> numStr,
                 "westernYear" -> wy,
                 "japaneseYear" -> iWesternToJapaneseEra[wy],
                 "context" -> ""|>]],
      {m, matches}]];
  If[best === None,
    matches = StringCases[allText,
      RegularExpression["(?<![\\d])(20[12]\\d)(?![\\d\:5e74])"] :> "$1"];
    If[Length[matches] > 0,
      Module[{wy = ToExpression[First[matches]]},
        If[wy > bestYear,
          bestYear = wy;
          best = <|"rawText" -> ToString[wy],
                   "westernYear" -> wy,
                   "japaneseYear" -> iWesternToJapaneseEra[wy],
                   "context" -> ""|>]]]];
  best
];

(* \:30af\:30a8\:30ea\:304b\:3089\:5e74\:5ea6\:60c5\:5831\:3092\:62bd\:51fa *)
iExtractYearFromQuery[query_String] := Module[
  {q, matches, era, num, wy},
  q = iNormalizeDigits[query];
  (* \:4ee4\:548c/\:5e73\:6210/\:662d\:548c X\:5e74\:5ea6 (\:6b63\:5f0f\:8868\:8a18) *)
  matches = StringCases[q,
    RegularExpression["(\:4ee4\:548c|\:5e73\:6210|\:662d\:548c)(\\d{1,2})(?:\:5e74\:5ea6?)?"] :>
      {"$1", "$2"}];
  If[Length[matches] > 0,
    {era, num} = First[matches];
    wy = iJapaneseEraToWestern[era, ToExpression[num]];
    Return[wy]];
  (* R/H/S \:7565\:79f0 *)
  matches = StringCases[q,
    RegularExpression["(?<![A-Za-z])(R|H|S)(\\d{1,2})(?:\:5e74\:5ea6?)?"] :>
      {"$1", "$2"}];
  If[Length[matches] > 0,
    {era, num} = First[matches];
    wy = iJapaneseEraToWestern[era, ToExpression[num]];
    Return[wy]];
  (* \:897f\:66a6 4\:6841 *)
  matches = StringCases[q, RegularExpression["(20\\d{2})(?:\:5e74\:5ea6?)?"] :> "$1"];
  If[Length[matches] > 0, Return[ToExpression[First[matches]]]];
  None
];

(* \:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:5185\:306e\:5168\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:306e\:5e74\:5ea6\:60c5\:5831\:3092\:53d6\:5f97 *)
iGetCollectionYearInfo[collection_String] := Module[{docs},
  docs = iLoadCollectionDocs[collection];
  If[Length[docs] === 0, Return[None]];
  (* \:6700\:65b0\:306e\:5e74\:5ea6\:60c5\:5831\:3092\:8fd4\:3059 (\:5f8c\:65b9\:4e92\:63db) *)
  Module[{best = None, bestYear = 0},
    Do[Module[{yi = Lookup[d, "yearInfo", None]},
      If[AssociationQ[yi] && Lookup[yi, "westernYear", 0] > bestYear,
        bestYear = yi["westernYear"]; best = yi]],
      {d, docs}];
    best]
];

(* \:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:5185\:306e\:5168\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:304b\:3089\:5e74\:5ea6\:3067\:30d9\:30b9\:30c8\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:3092\:9078\:629e
   queryYear: \:897f\:66a6\:5e74(Integer) or None (None\:306a\:3089\:6700\:65b0)
   \:8fd4\:308a\:5024: <|"doc" -> docAssoc, "yearNote" -> String|None|> or None *)
iFindBestDocByYear[collection_String, queryYear_] := Module[
  {docs, bestDoc = None, bestYear = 0, exactMatch = False, yearNote = None},
  docs = iLoadCollectionDocs[collection];
  If[Length[docs] === 0, Return[None]];
  (* \:5168\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:3092\:30b9\:30ad\:30e3\:30f3 *)
  Do[
    Module[{yi = Lookup[d, "yearInfo", None], wy},
      If[AssociationQ[yi],
        wy = Lookup[yi, "westernYear", 0];
        If[IntegerQ[queryYear],
          (* \:5b8c\:5168\:4e00\:81f4 *)
          If[wy === queryYear,
            bestDoc = d; bestYear = wy; exactMatch = True],
          (* \:6700\:65b0 *)
          If[wy > bestYear, bestDoc = d; bestYear = wy]],
        (* yearInfo \:306a\:3057 \[RightArrow] queryYear \:3082 None \:306e\:3068\:304d\:5019\:88dc\:306b *)
        If[!IntegerQ[queryYear] && bestDoc === None,
          bestDoc = d]]],
    {d, docs}];
  (* \:5b8c\:5168\:4e00\:81f4\:304c\:306a\:3051\:308c\:3070\:6700\:3082\:8fd1\:3044\:3082\:306e\:3092\:63a2\:3059 *)
  If[IntegerQ[queryYear] && !exactMatch,
    bestDoc = None; bestYear = 0;
    Do[Module[{yi = Lookup[d, "yearInfo", None], wy},
      If[AssociationQ[yi],
        wy = Lookup[yi, "westernYear", 0];
        If[wy <= queryYear && wy > bestYear,
          bestDoc = d; bestYear = wy]]],
      {d, docs}];
    (* \:305d\:308c\:3067\:3082\:306a\:3051\:308c\:3070\:6700\:65b0 *)
    If[bestDoc === None,
      Do[Module[{yi = Lookup[d, "yearInfo", None], wy},
        If[AssociationQ[yi],
          wy = Lookup[yi, "westernYear", 0];
          If[wy > bestYear, bestDoc = d; bestYear = wy]]],
        {d, docs}]];
    If[bestDoc =!= None,
      yearNote = "\:26a0\:fe0f " <> iWesternToJapaneseEra[queryYear] <>
        "\:5e74\:5ea6(" <> ToString[queryYear] <>
        ")\:306e\:8cc7\:6599\:306f\:3042\:308a\:307e\:305b\:3093\:3002" <>
        iWesternToJapaneseEra[bestYear] <> "\:5e74\:5ea6(" <>
        ToString[bestYear] <> ")\:7248\:3092\:8868\:793a\:3057\:3066\:3044\:307e\:3059\:3002"]];
  If[bestDoc === None, bestDoc = First[docs]];
  <|"doc" -> bestDoc, "yearNote" -> yearNote,
    "yearMatch" -> If[exactMatch, "exact",
      If[IntegerQ[queryYear], "approximate", "latest"]]|>
];

(* \:5f8c\:65b9\:4e92\:63db: \:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:304b\:3089\:6700\:521d\:306e\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:30d1\:30b9\:3092\:53d6\:5f97 *)
iFindBestCollectionByYear[queryYear_] := Module[
  {collections, bestC = None, bestYear = 0},
  collections = PDFIndex`pdfListCollections[];
  Do[Module[{yi = iGetCollectionYearInfo[c], wy},
    If[AssociationQ[yi],
      wy = Lookup[yi, "westernYear", 0];
      If[IntegerQ[queryYear],
        If[wy === queryYear, Return[c, Module]];
        If[wy <= queryYear && wy > bestYear,
          bestYear = wy; bestC = c],
        If[wy > bestYear, bestYear = wy; bestC = c]]]],
    {c, collections}];
  bestC
];

(* ============================================================ *)
(* \:30a4\:30f3\:30c7\:30af\:30b7\:30f3\:30b0\:5b9f\:884c                                            *)
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
    (* \:30aa\:30d7\:30b7\:30e7\:30f3\:89e3\:6c7a *)
    privacy = OptionValue[PDFIndex`pdfIndex, {opts}, Privacy];
    keywords = OptionValue[PDFIndex`pdfIndex, {opts}, Keywords];
    title = OptionValue[PDFIndex`pdfIndex, {opts}, Title];
    collection = OptionValue[PDFIndex`pdfIndex, {opts}, Collection];
    forceReindex = OptionValue[PDFIndex`pdfIndex, {opts}, ForceReindex];

    (* \:30d1\:30b9\:89e3\:6c7a *)
    absPath = If[iIsURL[pdfPath],
      (* URL: \:30c0\:30a6\:30f3\:30ed\:30fc\:30c9\:3057\:3066\:30ad\:30e3\:30c3\:30b7\:30e5 *)
      iDownloadAndCache[pdfPath],
      (* \:30ed\:30fc\:30ab\:30eb\:30d5\:30a1\:30a4\:30eb *)
      If[FileExistsQ[pdfPath], pdfPath,
        Module[{nbDir},
          nbDir = Quiet @ Check[NotebookDirectory[], Global`$packageDirectory];
          FileNameJoin[{nbDir, pdfPath}]]]];

    If[!StringQ[absPath] || (!FileExistsQ[absPath] && !iIsURL[pdfPath]),
      Message[PDFIndex`pdfIndex::notfound, pdfPath];
      Return[$Failed]];

    docId = iDocId[If[iIsURL[pdfPath], pdfPath, absPath]];
    Print["[pdfIndex] \:30c9\:30ad\:30e5\:30e1\:30f3\:30c8ID: " <> docId];

    (* \:65e2\:5b58\:30c1\:30a7\:30c3\:30af *)
    If[!TrueQ[forceReindex],
      Module[{existing},
        existing = iFindExistingDoc[docId, collection];
        If[AssociationQ[existing],
          Print["  \:2714 \:65e2\:306b\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:6e08\:307f\:3002ForceReindex -> True \:3067\:518d\:751f\:6210\:3002"];
          Return[existing]]]];

    (* PDF \:30c6\:30ad\:30b9\:30c8\:62bd\:51fa *)
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

    (* \:76ee\:6b21 (TOC) \:62bd\:51fa *)
    Module[{tocData = iExtractTOC[absPath]},
      Print["  TOC\:30a8\:30f3\:30c8\:30ea: " <> ToString[Length[tocData]] <> "\:4ef6"];
      $pdfIndexAsyncContext["pendingTOC"] = tocData];

    (* === \:65b0\:30d1\:30a4\:30d7\:30e9\:30a4\:30f3: \:30d3\:30b8\:30e7\:30f3\:89e3\:6790 + \:69cb\:9020\:5316\:30c1\:30e3\:30f3\:30ad\:30f3\:30b0 === *)
    Print["  \:30da\:30fc\:30b8\:5206\:6790\:4e2d..."];
    Module[{pages, pageResults = {}, visionPages = {}, textPages = {},
            mergedTables, catalog, pg, rawText, isVision, visionResult,
            tocData = Lookup[$pdfIndexAsyncContext, "pendingTOC", {}]},

      pages = Lookup[extractResult, "pages", {}];

      (* \:30b9\:30c6\:30c3\:30d71: \:5404\:30da\:30fc\:30b8\:3092\:5206\:985e *)
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

      (* \:30b9\:30c6\:30c3\:30d72: \:30d3\:30b8\:30e7\:30f3\:89e3\:6790 (\:8868\:30fb\:56f3\:30da\:30fc\:30b8) \[LongDash] \:4e26\:5217\:51e6\:7406 *)
      If[Length[visionPages] > 0,
        Module[{vpDataList, parallelResults2},
          Print["  \:30d3\:30b8\:30e7\:30f3\:89e3\:6790: " <> ToString[Length[visionPages]] <>
            " pages (parallel)..."];
          vpDataList = Map[
            Function[{vpg},
              <|"pageNum" -> vpg,
                "rawText" -> Lookup[
                  SelectFirst[pages, #["pageNum"] === vpg &, <||>],
                  "text", ""]|>],
            visionPages];
          parallelResults2 = iParallelMapSafe[
            Function[{vpd},
              Module[{vpg = vpd["pageNum"], vr},
                vr = Quiet @ Check[
                  iAnalyzePageWithVision[absPath, vpg], $Failed];
                If[AssociationQ[vr],
                  Join[vr, <|"pageNum" -> vpg, "isVision" -> True|>],
                  <|"pageNum" -> vpg, "isVision" -> False,
                    "rawText" -> vpd["rawText"],
                    "paragraphs" -> {},
                    "tables" -> {}, "figures" -> {}|>]]],
            vpDataList];
          pageResults = Join[pageResults, parallelResults2];
          Print["  \:30d3\:30b8\:30e7\:30f3\:89e3\:6790\:5b8c\:4e86: " <>
            ToString[Length[parallelResults2]] <> " pages"]]];

      (* \:30b9\:30c6\:30c3\:30d73: \:30c6\:30ad\:30b9\:30c8\:30da\:30fc\:30b8 (\:5f93\:6765\:65b9\:5f0f) *)
      Do[
        AppendTo[pageResults,
          <|"pageNum" -> pg, "isVision" -> False,
            "rawText" -> Lookup[
              SelectFirst[pages, #["pageNum"] === pg &, <||>],
              "text", ""],
            "paragraphs" -> {},
            "tables" -> {}, "figures" -> {}|>],
        {pg, textPages}];

      (* \:30da\:30fc\:30b8\:756a\:53f7\:9806\:306b\:30bd\:30fc\:30c8 *)
      pageResults = SortBy[pageResults, Lookup[#, "pageNum", 9999] &];

      (* \:30b9\:30c6\:30c3\:30d74: \:9023\:7d9a\:30da\:30fc\:30b8\:306e\:8868\:30de\:30fc\:30b8 *)
      mergedTables = iMergeSpanningTables[pageResults];
      If[Length[mergedTables] > 0,
        Print["  \:8868\:691c\:51fa: " <> ToString[Length[mergedTables]] <> "\:4ef6" <>
          " (\:30de\:30fc\:30b8\:6e08\:307f)"]];

      (* \:30b9\:30c6\:30c3\:30d75: \:30ab\:30bf\:30ed\:30b0\:69cb\:7bc9 *)
      catalog = iBuildCatalog[pageResults, mergedTables, tocData];
      Print["  \:30ab\:30bf\:30ed\:30b0: \:8868" <>
        ToString[Length[catalog["tables"]]] <>
        " \:56f3" <> ToString[Length[catalog["figures"]]] <>
        " \:30bb\:30af\:30b7\:30e7\:30f3" <> ToString[Length[catalog["sections"]]]];

      (* \:30b9\:30c6\:30c3\:30d76: \:69cb\:9020\:5316\:30c1\:30e3\:30f3\:30ad\:30f3\:30b0 *)
      chunks = iChunkFromStructured[pageResults, mergedTables];
      Print["  \:69cb\:9020\:5316\:30c1\:30e3\:30f3\:30af: " <> ToString[Length[chunks]] <> "\:4ef6"];

      (* \:30b9\:30c6\:30c3\:30d76b: OCR \:4fee\:6b63\:30c6\:30ad\:30b9\:30c8\:3067\:30c1\:30e3\:30f3\:30af\:3092\:7f6e\:63db
         iFixGarbledPages \:3067 Tesseract/TextRecognize \:304c\:6210\:529f\:3057\:305f\:30da\:30fc\:30b8\:306e
         \:30c6\:30ad\:30b9\:30c8\:3067\:3001\:69cb\:9020\:5316\:89e3\:6790\:304c\:518d\:62bd\:51fa\:3057\:305f\:6587\:5b57\:5316\:3051\:30c6\:30ad\:30b9\:30c8\:3092\:4e0a\:66f8\:304d\:3059\:308b *)
      Module[{ocrFixed = Lookup[$pdfIndexAsyncContext, "ocrFixedPages", <||>]},
        If[AssociationQ[ocrFixed] && Length[ocrFixed] > 0,
          Print["  OCR\:30c6\:30ad\:30b9\:30c8\:3067\:30c1\:30e3\:30f3\:30af\:7f6e\:63db: p." <>
            StringRiffle[ToString /@ Keys[ocrFixed], ","]];
          chunks = Map[
            Module[{pg = Lookup[#, "pageNum", 0], fixedText},
              fixedText = Lookup[ocrFixed, pg, None];
              If[StringQ[fixedText],
                Append[KeyDrop[#, "text"], "text" -> fixedText],
                #]] &,
            chunks];
          $pdfIndexAsyncContext = KeyDrop[$pdfIndexAsyncContext, "ocrFixedPages"]]];

      (* \:30ab\:30bf\:30ed\:30b0\:3092\:4fdd\:5b58\:7528\:306b\:8a18\:9332 *)
      $pdfIndexAsyncContext["pendingCatalog"] = catalog];

    (* \:30d7\:30e9\:30a4\:30d0\:30b7\:30fc\:63a8\:5b9a *)
    If[privacy === Automatic,
      Print["  \:30d7\:30e9\:30a4\:30d0\:30b7\:30fc\:63a8\:5b9a\:4e2d..."];
      docPrivacy = iEstimatePrivacy[title,
        If[Length[chunks] > 0, chunks[[1]]["text"], ""]];
      Print["  Privacy: " <> ToString[docPrivacy]],
      docPrivacy = N[privacy]];

    (* LLM \:51e6\:7406: \:30ed\:30fc\:30ab\:30eb or \:30af\:30e9\:30a6\:30c9 *)
    useLocal = docPrivacy > 0.5;

    (* \:30c1\:30e3\:30f3\:30af\:8981\:7d04\:30fb\:30bf\:30b0\:751f\:6210 *)
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

    (* Embedding \:751f\:6210 *)
    Print["  Embedding\:751f\:6210\:4e2d..."];
    iCreateEmbeddingSession[];
    embTexts = (iDoubleEscape[
      #["summary"] <> " " <> #["entities"] <> " " <> #["tags"] <>
      " " <> StringTake[#["text"], UpTo[$embeddingTextWindow]]] &) /@ processedChunks;
    embeddings = Quiet @ Check[iCreateEmbeddings[embTexts], {}];
    If[ListQ[embeddings] && Length[embeddings] === Length[processedChunks],
      processedChunks = MapThread[
        Append[#1, "embedding" -> If[ListQ[#2] && Length[#2] > 100, #2, {}]] &,
        {processedChunks, embeddings}],
      processedChunks = Append[#, "embedding" -> {}] & /@ processedChunks];

    (* \:4fdd\:5b58\:5148\:6c7a\:5b9a *)
    indexDir = If[docPrivacy > 0.5,
      iCollectionDir[collection, "private"],
      iCollectionDir[collection, "public"]];

    (* \:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:30e1\:30bf\:30c7\:30fc\:30bf\:4fdd\:5b58 *)
    Module[{docMeta, yearInfo, firstPageText = ""},
      (* \:5e74\:5ea6\:60c5\:5831\:62bd\:51fa: \:30bf\:30a4\:30c8\:30eb\:3001\:6700\:521d\:306e\:6570\:30da\:30fc\:30b8\:306e\:30c6\:30ad\:30b9\:30c8\:304b\:3089 *)
      If[ListQ[Lookup[extractResult, "pages", {}]] &&
         Length[extractResult["pages"]] > 0,
        firstPageText = StringJoin[
          Riffle[
            Lookup[#, "text", ""] & /@
              Take[extractResult["pages"], UpTo[5]], "\n"]]];
      yearInfo = iExtractYearInfo[title, firstPageText];
      If[AssociationQ[yearInfo],
        Print["  \:5e74\:5ea6\:60c5\:5831: " <> yearInfo["japaneseYear"] <>
          "\:5e74\:5ea6 (\:897f\:66a6" <> ToString[yearInfo["westernYear"]] <> ")" <>
          If[StringLength[Lookup[yearInfo, "context", ""]] > 0,
            " [" <> yearInfo["context"] <> "]", ""]]];
      docMeta = <|
        "docId" -> docId,
        "title" -> title,
        "author" -> Lookup[metadata, "author", ""],
        "sourcePath" -> If[iIsURL[pdfPath], pdfPath, iMakeRelativePath[absPath]],
        "sourceType" -> If[iIsURL[pdfPath], "url", "file"],
        "privacy" -> docPrivacy,
        "collection" -> collection,
        "pageCount" -> Lookup[metadata, "pageCount", 0],
        "chunkCount" -> Length[processedChunks],
        "keywords" -> keywords,
        "yearInfo" -> yearInfo,
        "indexedAt" -> DateString[Now, "ISODateTime"],
        "storageType" -> If[docPrivacy > 0.5, "private", "public"]
      |>;
      docFile = FileNameJoin[{indexDir, "doc_" <> docId <> ".wl"}];
      Put[docMeta, docFile];
      Print["  \:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:30e1\:30bf\:4fdd\:5b58: " <> docFile]];

    (* \:30c1\:30e3\:30f3\:30af\:30c7\:30fc\:30bf\:4fdd\:5b58: \:5404\:30c1\:30e3\:30f3\:30af\:306b docId \:3092\:4ed8\:52a0 *)
    processedChunks = Append[#, "docId" -> docId] & /@ processedChunks;
    chunkFile = FileNameJoin[{indexDir, "chunks_" <> docId <> ".wl"}];
    Put[processedChunks, chunkFile];
    Print["  \:30c1\:30e3\:30f3\:30af\:30c7\:30fc\:30bf\:4fdd\:5b58: " <> chunkFile];

    (* \:5168\:30da\:30fc\:30b8\:30c6\:30ad\:30b9\:30c8\:4fdd\:5b58: \:691c\:7d22\:6642\:306bPDF\:3092\:53c2\:7167\:4e0d\:8981\:306b\:3059\:308b *)
    Module[{pages = Lookup[extractResult, "pages", {}], pageTexts, pagesFile},
      pageTexts = Map[
        <|"page" -> Lookup[#, "pageNum", 0],
          "text" -> StringTake[Lookup[#, "text", ""], UpTo[5000]],
          "docId" -> docId|> &,
        pages];
      pageTexts = Select[pageTexts, Lookup[#, "page", 0] > 0 &];
      If[Length[pageTexts] > 0,
        pagesFile = FileNameJoin[{indexDir, "pages_" <> docId <> ".wl"}];
        Put[pageTexts, pagesFile];
        Print["  \:30da\:30fc\:30b8\:30c6\:30ad\:30b9\:30c8\:4fdd\:5b58: " <> ToString[Length[pageTexts]] <>
          "\:30da\:30fc\:30b8"];
        (* \:30ad\:30e3\:30c3\:30b7\:30e5\:3092\:30af\:30ea\:30a2 *)
        $pdfPageTextCache = KeyDrop[$pdfPageTextCache, collection]]];

    (* TOC \:4fdd\:5b58 *)
    Module[{tocData = Lookup[$pdfIndexAsyncContext, "pendingTOC", {}], tocFile},
      If[ListQ[tocData] && Length[tocData] > 0,
        tocFile = FileNameJoin[{indexDir, "toc_" <> docId <> ".wl"}];
        Put[tocData, tocFile];
        Print["  TOC\:4fdd\:5b58: " <> ToString[Length[tocData]] <> "\:30a8\:30f3\:30c8\:30ea"]];
      $pdfIndexAsyncContext = KeyDrop[$pdfIndexAsyncContext, "pendingTOC"]];

    (* \:30ab\:30bf\:30ed\:30b0\:4fdd\:5b58 *)
    Module[{catalog = Lookup[$pdfIndexAsyncContext, "pendingCatalog", <||>],
            catalogFile},
      If[AssociationQ[catalog] && Length[catalog] > 0,
        catalogFile = FileNameJoin[{indexDir, "catalog_" <> docId <> ".wl"}];
        Put[catalog, catalogFile];
        Print["  \:30ab\:30bf\:30ed\:30b0\:4fdd\:5b58: " <> catalogFile]];
      $pdfIndexAsyncContext = KeyDrop[$pdfIndexAsyncContext, "pendingCatalog"]];

    (* \:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:751f\:6210\:30fb\:4fdd\:5b58 *)
    Module[{entityIdx, ef},
      entityIdx = iGenerateEntityIndex[processedChunks, title, useLocal];
      If[ListQ[entityIdx] && Length[entityIdx] > 0,
        ef = FileNameJoin[{indexDir, "entities_" <> docId <> ".wl"}];
        Put[entityIdx, ef];
        Print["  \:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:4fdd\:5b58: " <> ef];
        $entityIndexCache = KeyDrop[$entityIndexCache, collection]]];

    (* \:30ad\:30e3\:30c3\:30b7\:30e5\:3092\:7121\:52b9\:5316 *)
    $pdfIndexCache = KeyDrop[$pdfIndexCache, collection];

    Print[Style["  \:2714 \:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:5b8c\:4e86: " <> title, Darker[Green]]];
    <|"docId" -> docId, "title" -> title, "privacy" -> docPrivacy,
      "chunks" -> Length[processedChunks], "collection" -> collection|>
  ];

PDFIndex`pdfIndex::notfound = "\:30d5\:30a1\:30a4\:30eb\:304c\:898b\:3064\:304b\:308a\:307e\:305b\:3093: `1`";

(* ============================================================ *)
(* \:975e\:540c\:671f pdfIndex v2 \[LongDash] LLMGraph \:30d9\:30fc\:30b9                           *)
(*                                                              *)
(* \:8a2d\:8a08:                                                         *)
(*   Phase 0 (\:540c\:671f, ~10-20s): Extract + \:30da\:30fc\:30b8\:5206\:985e + \:30d3\:30b8\:30e7\:30f3\:89e3\:6790 *)
(*     + \:30c1\:30e3\:30f3\:30ad\:30f3\:30b0 \[RightArrow] LLMGraph \:69cb\:7bc9                             *)
(*   Phase 1 (\:975e\:540c\:671f, LLMGraph \:30b9\:30b1\:30b8\:30e5\:30fc\:30e9):                     *)
(*     \:6587\:5b57\:5316\:3051OCR (render \[RightArrow] CLI\[Times]2) \[RightArrow] rechunk \[RightArrow] \:8981\:7d04 (CLI\[Times]N)    *)
(*     \[RightArrow] finalize (Embedding + \:4fdd\:5b58)                             *)
(*                                                              *)
(* \:30b9\:30b1\:30b8\:30e5\:30fc\:30e9\:306f\:30ab\:30c6\:30b4\:30ea\:5225\:4e26\:5217\:5ea6\:5236\:5fa1\:3002\:30d5\:30ed\:30f3\:30c8\:30a8\:30f3\:30c9\:306f\:30d6\:30ed\:30c3\:30af\:3057\:306a\:3044\:3002 *)
(* \:5c06\:6765: \:30ab\:30c6\:30b4\:30ea\:5225\:4e26\:5217\:5ea6\:5236\:5fa1\:3092\:5c0e\:5165\:4e88\:5b9a\:3002                         *)
(* ============================================================ *)

(* \[HorizontalLine]\[HorizontalLine] PDFIndex \:30bf\:30b9\:30af\:30c7\:30a3\:30b9\:30af\:30ea\:30d7\:30bf \[HorizontalLine]\[HorizontalLine]
   \:30ce\:30fc\:30c9\:30ab\:30c6\:30b4\:30ea\:304b\:3089 LLMGraph \:62bd\:8c61\:30ab\:30c6\:30b4\:30ea\:3078\:306e\:30de\:30c3\:30d4\:30f3\:30b0\:3002
   maxConcurrency: LLMGraph \:306e\:30b0\:30ed\:30fc\:30d0\:30eb\:30c7\:30d5\:30a9\:30eb\:30c8 ($LLMGraphMaxConcurrency) \:3092
   PDFIndex \:7528\:306b\:30aa\:30fc\:30d0\:30fc\:30e9\:30a4\:30c9\:3002\:8907\:6570\:30da\:30fc\:30b8\:306e OCR \:3092\:4e26\:5217\:5b9f\:884c\:3059\:308b\:305f\:3081
   "process" (\:30ec\:30f3\:30c0\:30ea\:30f3\:30b0) \:3068 "cli-vision" (Claude Vision OCR) \:306e\:4e26\:5217\:5ea6\:3092\:5f15\:304d\:4e0a\:3052\:3002
   $ProcessorCount \:306b\:57fa\:3065\:3044\:3066\:52d5\:7684\:306b\:8a2d\:5b9a\:3002
   \:6ce8: \:30e1\:30a4\:30f3\:30ab\:30fc\:30cd\:30eb\:306e\:30b9\:30b1\:30b8\:30e5\:30fc\:30e9 (iLLMGraphDAGTick) \:306f
   ScheduledTask \:3067 1.5s \:9593\:9694\:3067\:5b9f\:884c\:3055\:308c\:308b\:305f\:3081\:3001\:3053\:3053\:3067\:306e\:4e26\:5217\:5ea6\:306f
   \:540c\:6642\:306b\:8d77\:52d5\:3055\:308c\:308b\:5916\:90e8\:30d7\:30ed\:30bb\:30b9 (StartProcess) \:306e\:4e0a\:9650\:3092\:610f\:5473\:3059\:308b\:3002 *)
$iPdfTaskDescriptor = <|
  "name" -> "pdfIndex LLMGraph",
  "categoryMap" -> <|
    "render"    -> "process",
    "ocr"       -> "cli-vision",
    "summarize" -> "cli",
    "chunk"     -> "sync",
    "save"      -> "sync",
    (* Phase 30: finalize-embed \:3092 Python \:30b5\:30d6\:30d7\:30ed\:30bb\:30b9\:3067\:975e\:540c\:671f\:5b9f\:884c *)
    "embed"     -> "process"
  |>,
  "maxConcurrency" -> <|
    (* render: PyMuPDF \:3067\:30da\:30fc\:30b8\:753b\:50cf\:5316\:3002CPU \:30d0\:30a6\:30f3\:30c9\:3002\:30b3\:30a2\:6570\:306b\:5fdc\:3058\:3066\:4e26\:5217\:5316 *)
    "process"    -> Min[$ProcessorCount, 8],
    (* ocr: Claude Vision CLI \:547c\:3073\:51fa\:3057\:3002IO \:30d0\:30a6\:30f3\:30c9 (\:30cd\:30c3\:30c8\:30ef\:30fc\:30af\:5f85\:3061) \:306a\:306e\:3067
       \:30b3\:30a2\:6570\:3088\:308a\:591a\:3081\:306b\:8a2d\:5b9a\:53ef\:80fd *)
    "cli-vision" -> Min[Max[Floor[$ProcessorCount / 2], 2], 6],
    (* summarize: Claude CLI \:30c6\:30ad\:30b9\:30c8\:51e6\:7406\:3002IO \:30d0\:30a6\:30f3\:30c9 *)
    "cli"        -> Min[Max[$ProcessorCount, 4], 8],
    "sync"       -> 99
  |>
|>;

(* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
   PDFIndex Async \:30e9\:30a4\:30d5\:30b5\:30a4\:30af\:30eb \[LongDash] ClaudeRuntime \:7d71\:5408\:7248
   
   \:5168\:95a2\:6570\:306f runtimeId (\:65b0) \:3068 jobId (\:30ec\:30ac\:30b7\:30fc) \:306e\:4e21\:65b9\:3092\:53d7\:3051\:4ed8\:3051\:308b\:3002
   runtimeId \:306e\:5834\:5408\:306f ClaudeRuntime API \:306b\:59d4\:8b72\:3057\:3001
   jobId \:306e\:5834\:5408\:306f\:5f93\:6765\:306e LLMGraphDAG API \:306b\:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af\:3059\:308b\:3002
   \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)

(* \[HorizontalLine]\[HorizontalLine] \:30b9\:30c6\:30fc\:30bf\:30b9\:7167\:4f1a \[HorizontalLine]\[HorizontalLine] *)
PDFIndex`pdfIndexAsyncStatus[id_String] :=
  Module[{rt = Quiet @ ClaudeRuntime`Private`$iClaudeRuntimes[id]},
    If[AssociationQ[rt],
      <|"runtimeId" -> id,
        "status"    -> rt["Status"],
        "jobId"     -> Lookup[rt, "CurrentJobId", None],
        "profile"   -> Lookup[rt, "Profile", "?"]|>,
      (* fallback: legacy jobId *)
      ClaudeCode`LLMGraphDAGStatus[id]]];

(* \[HorizontalLine]\[HorizontalLine] \:30ad\:30e3\:30f3\:30bb\:30eb \[HorizontalLine]\[HorizontalLine] *)
PDFIndex`pdfIndexAsyncCancel[id_String] :=
  Module[{rt = Quiet @ ClaudeRuntime`Private`$iClaudeRuntimes[id], jobId},
    If[AssociationQ[rt],
      jobId = Lookup[rt, "CurrentJobId", None];
      If[StringQ[jobId], ClaudeCode`LLMGraphDAGCancel[jobId]];
      rt["Status"] = "Cancelled";
      ClaudeRuntime`Private`$iClaudeRuntimes[id] = rt,
      (* fallback *)
      ClaudeCode`LLMGraphDAGCancel[id]]];

(* \[HorizontalLine]\[HorizontalLine] \:505c\:6b62 (DAG \:505c\:6b62\:306e\:307f\:3001\:4fdd\:5b58\:306f\:3057\:306a\:3044) \[HorizontalLine]\[HorizontalLine] *)
PDFIndex`pdfIndexAsyncStop[id_String] :=
  Module[{rt = Quiet @ ClaudeRuntime`Private`$iClaudeRuntimes[id], jobId},
    If[AssociationQ[rt],
      jobId = Lookup[rt, "CurrentJobId", None];
      If[StringQ[jobId], ClaudeCode`LLMGraphDAGStop[jobId]],
      (* fallback *)
      ClaudeCode`LLMGraphDAGStop[id]]];

(* \[HorizontalLine]\[HorizontalLine] \:30b9\:30ca\:30c3\:30d7\:30b7\:30e7\:30c3\:30c8\:4fdd\:5b58 (ClaudeRuntime \:7d71\:5408) \[HorizontalLine]\[HorizontalLine] *)
PDFIndex`pdfIndexAsyncSnapshot[id_String] :=
  Module[{rt = Quiet @ ClaudeRuntime`Private`$iClaudeRuntimes[id]},
    If[AssociationQ[rt],
      (* AuxiliaryState \:306b\:6700\:65b0\:306e $pdfIndexAsyncContext \:3092\:53cd\:6620 *)
      rt["AuxiliaryState"] = <|
        "pdfIndexAsyncContext" -> $pdfIndexAsyncContext|>;
      ClaudeRuntime`Private`$iClaudeRuntimes[id] = rt;
      ClaudeCode`ClaudeRuntimeSnapshot[id],
      (* fallback: legacy *)
      ClaudeCode`LLMGraphDAGSnapshot[id,
        "AuxiliaryState" -> <|
          "pdfIndexAsyncContext" -> $pdfIndexAsyncContext|>]]];

(* \[HorizontalLine]\[HorizontalLine] \:30b9\:30ca\:30c3\:30d7\:30b7\:30e7\:30c3\:30c8\:5fa9\:5143 \[HorizontalLine]\[HorizontalLine] *)
PDFIndex`pdfIndexAsyncRestore[snapDir_String] :=
  Module[{result, auxState},
    If[FileExistsQ[FileNameJoin[{snapDir, "runtime_state.wl"}]],
      (* ClaudeRuntime \:5f62\:5f0f *)
      result = ClaudeCode`ClaudeRuntimeRestore[snapDir];
      If[AssociationQ[result],
        Module[{rt = Quiet @
            ClaudeRuntime`Private`$iClaudeRuntimes[result["runtimeId"]]},
          If[AssociationQ[rt],
            auxState = Lookup[rt, "AuxiliaryState", <||>];
            If[KeyExistsQ[auxState, "pdfIndexAsyncContext"],
              $pdfIndexAsyncContext = auxState["pdfIndexAsyncContext"];
              Print["  $pdfIndexAsyncContext \:5fa9\:5143\:6e08"]]]]];
      result,
      (* fallback: legacy LLMGraphDAG \:5f62\:5f0f *)
      result = ClaudeCode`LLMGraphDAGRestore[snapDir];
      If[AssociationQ[result],
        auxState = Lookup[result, "auxiliaryState", <||>];
        If[AssociationQ[auxState] && KeyExistsQ[auxState, "pdfIndexAsyncContext"],
          $pdfIndexAsyncContext = auxState["pdfIndexAsyncContext"];
          Print["  $pdfIndexAsyncContext \:5fa9\:5143\:6e08"]]];
      result]];

PDFIndex`pdfIndexAsyncRestore[snapDir_String, "Resume"] :=
  Module[{result},
    If[FileExistsQ[FileNameJoin[{snapDir, "runtime_state.wl"}]],
      (* ClaudeRuntime \:5f62\:5f0f: Restore + \:81ea\:52d5 Retry *)
      ClaudeCode`ClaudeRuntimeRestore[snapDir, "Resume"],
      (* fallback: legacy *)
      result = PDFIndex`pdfIndexAsyncRestore[snapDir];
      If[AssociationQ[result] && StringQ[result["jobId"]],
        Print["  \[Rule] \:81ea\:52d5\:518d\:958b\:4e2d..."];
        ClaudeCode`LLMGraphDAGRetry[result["jobId"]]];
      result]];

(* \[HorizontalLine]\[HorizontalLine] \:518d\:958b (failed \:30ce\:30fc\:30c9\:306e\:307f\:518d\:5b9f\:884c) \[HorizontalLine]\[HorizontalLine] *)
PDFIndex`pdfIndexAsyncResume[id_String] :=
  Module[{rt = Quiet @ ClaudeRuntime`Private`$iClaudeRuntimes[id], jobId},
    If[AssociationQ[rt],
      (* runtimeId \[RightArrow] jobId \:7d4c\:7531\:3067 LLMGraphDAGRetry *)
      jobId = Lookup[rt, "CurrentJobId", None];
      If[StringQ[jobId],
        ClaudeCode`LLMGraphDAGRetry[jobId],
        Print[Style["\[WarningSign] CurrentJobId not found", Red]]; $Failed],
      (* fallback: id \:3092\:76f4\:63a5 jobId \:3068\:3057\:3066\:4f7f\:3046 *)
      ClaudeCode`LLMGraphDAGRetry[id]]];

(* \[HorizontalLine]\[HorizontalLine] \:30ab\:30bf\:30ed\:30b0\:518d\:69cb\:7bc9 (LLM \:4e0d\:8981\:30fb\:540c\:671f\:51e6\:7406\:306e\:307f) \[HorizontalLine]\[HorizontalLine]
   \:65e2\:5b58\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:306e catalog \:30d5\:30a1\:30a4\:30eb\:306e\:307f\:3092\:518d\:751f\:6210\:3059\:308b\:3002
   \:7528\:9014: iBuildCatalog \:306e\:30d0\:30b0\:4fee\:6b63\:5f8c\:306b\:65e2\:5b58\:30ab\:30bf\:30ed\:30b0\:3092\:66f4\:65b0\:3059\:308b\:5834\:5408 \:7b49\:3002
   \:4f8b: pdfRebuildCatalog["898b8340f18e8389"]
       pdfRebuildCatalog["898b8340f18e8389", "default"] *)
PDFIndex`pdfRebuildCatalog::usage =
  "pdfRebuildCatalog[docId, collection] \:306f\:65e2\:5b58\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:306e catalog \:30d5\:30a1\:30a4\:30eb\:306e\:307f\:3092\:518d\:751f\:6210\:3059\:308b\:3002\n" <>
  "LLM \:547c\:3073\:51fa\:3057\:4e0d\:8981\:3002\:4f8b: pdfRebuildCatalog[\"898b8340f18e8389\"]";

PDFIndex`pdfRebuildCatalog[docId_String, collection_String:"default"] :=
  Module[{docs, docMeta, sp, pdfPath, extractResult,
          pageResults = {}, mergedTables, tocData, catalog,
          indexDir, catalogFile, privacy},
    docs = iLoadCollectionDocs[collection];
    docMeta = SelectFirst[docs, Lookup[#, "docId", ""] === docId &, None];
    If[!AssociationQ[docMeta],
      Print[Style["\[WarningSign] docId \:304c\:898b\:3064\:304b\:308a\:307e\:305b\:3093: " <> docId, Red]];
      Return[$Failed]];

    sp = Lookup[docMeta, "sourcePath", ""];
    pdfPath = iResolveSourcePath[sp];
    If[!StringQ[pdfPath] || !FileExistsQ[pdfPath],
      Print[Style["\[WarningSign] PDF \:304c\:898b\:3064\:304b\:308a\:307e\:305b\:3093: " <> ToString[sp], Red]];
      Return[$Failed]];
    privacy = Lookup[docMeta, "privacy", 0.0];

    Print[Style["\[RightArrow] \:30ab\:30bf\:30ed\:30b0\:518d\:69cb\:7bc9: " <>
      Lookup[docMeta, "title", docId], Bold]];

    (* \:30c6\:30ad\:30b9\:30c8\:62bd\:51fa (skipOCR=True: \:9ad8\:901f) *)
    Print["  \:30c6\:30ad\:30b9\:30c8\:62bd\:51fa\:4e2d..."];
    extractResult = iPDFExtract[pdfPath, None, True];
    If[!AssociationQ[extractResult], Return[$Failed]];

    (* \:30da\:30fc\:30b8\:5206\:985e (LLM \:4e0d\:8981) *)
    Print["  \:30da\:30fc\:30b8\:5206\:985e\:4e2d..."];
    Module[{pages = Lookup[extractResult, "pages", {}]},
      Do[Module[{pg = page["pageNum"], rawText = Lookup[page, "text", ""]},
        AppendTo[pageResults,
          <|"pageNum" -> pg, "isVision" -> False,
            "rawText" -> rawText,
            "paragraphs" -> {}, "tables" -> {}, "figures" -> {}|>]],
        {page, pages}]];

    (* TOC *)
    tocData = iExtractTOC[pdfPath];

    (* \:30ab\:30bf\:30ed\:30b0\:69cb\:7bc9 *)
    Print["  \:30ab\:30bf\:30ed\:30b0\:69cb\:7bc9\:4e2d..."];
    mergedTables = iMergeSpanningTables[pageResults];
    catalog = iBuildCatalog[pageResults, mergedTables, tocData];

    (* \:4fdd\:5b58 *)
    indexDir = If[privacy > 0.5,
      iCollectionDir[collection, "private"],
      iCollectionDir[collection, "public"]];
    catalogFile = FileNameJoin[{indexDir, "catalog_" <> docId <> ".wl"}];
    Put[catalog, catalogFile];
    Print[Style["  \[Checkmark] \:30ab\:30bf\:30ed\:30b0\:4fdd\:5b58: " <> catalogFile, Darker[Green]]];
    Print["  tables: ", Length[catalog["tables"]],
      ", figures: ", Length[catalog["figures"]],
      ", sections: ", Length[catalog["sections"]]];
    catalog];

(* \[HorizontalLine]\[HorizontalLine] \:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:524a\:9664 \[HorizontalLine]\[HorizontalLine]
   \:6307\:5b9a\:30d5\:30a1\:30a4\:30eb\:30d1\:30b9\:307e\:305f\:306f docId \:306e\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:3092\:5168\:524a\:9664\:3059\:308b\:3002
   ClaudeDetach \:304b\:3089\:547c\:3070\:308c\:308b\:3053\:3068\:3092\:60f3\:5b9a\:3002
   \:4f8b: pdfDeleteIndex["C:/.../claude_attachments/file.abc123.pdf"]
       pdfDeleteIndex["abc12345abcdef01", "default"]  (* docId \:76f4\:63a5\:6307\:5b9a *) *)
PDFIndex`pdfDeleteIndex::usage =
  "pdfDeleteIndex[pathOrDocId, collection] \:306f\:6307\:5b9a\:30d5\:30a1\:30a4\:30eb\:306e\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:3092\:524a\:9664\:3059\:308b\:3002\n" <>
  "\:30d5\:30a1\:30a4\:30eb\:30d1\:30b9\:307e\:305f\:306f docId \:3092\:6307\:5b9a\:53ef\:80fd\:3002\n" <>
  "\:4f8b: pdfDeleteIndex[\"C:/.../file.pdf\"]\n" <>
  "\:4f8b: pdfDeleteIndex[\"abc12345abcdef01\"]";

PDFIndex`pdfDeleteIndex[pathOrDocId_String, collection_String:"default"] :=
  Module[{docId, dirs, deleted = 0, suffixes, docs},
    (* docId \:3092\:7279\:5b9a: \:30d1\:30b9\:306a\:3089 hash\:300116\:6841hex \:306a\:3089\:305d\:306e\:307e\:307e *)
    If[FileExistsQ[pathOrDocId],
      docId = iDocId[pathOrDocId],
      If[StringMatchQ[pathOrDocId, RegularExpression["[0-9a-f]{16}"]],
        docId = pathOrDocId,
        (* \:30ed\:30fc\:30c9\:6e08\:307f\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:304b\:3089 sourcePath \:3067\:691c\:7d22 *)
        docs = iLoadCollectionDocs[collection];
        docId = Module[{found = None},
          Scan[Module[{sp = Lookup[#, "sourcePath", ""]},
            If[StringContainsQ[sp, pathOrDocId, IgnoreCase -> True] ||
               StringContainsQ[pathOrDocId, FileNameTake[sp], IgnoreCase -> True],
              found = Lookup[#, "docId", ""]; Return[]]] &, docs];
          found];
        If[!StringQ[docId] || docId === "",
          Print["  \[WarningSign] \:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:304c\:898b\:3064\:304b\:308a\:307e\:305b\:3093: " <>
            FileNameTake[pathOrDocId]];
          Return[0]]]];

    dirs = {iCollectionDir[collection, "public"],
            iCollectionDir[collection, "private"]};
    suffixes = {"doc_", "chunks_", "toc_", "catalog_", "entities_"};
    Do[
      Do[Module[{f = FileNameJoin[{d, sfx <> docId <> ".wl"}]},
        If[FileExistsQ[f],
          Quiet[DeleteFile[f]];
          deleted++;
          If[deleted <= 3, Print["  \:524a\:9664: " <> FileNameTake[f]]]]], {sfx, suffixes}],
      {d, dirs}];
    (* \:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:30ad\:30e3\:30c3\:30b7\:30e5\:3092\:30af\:30ea\:30a2 *)
    $pdfIndexCache = KeyDrop[$pdfIndexCache, collection];
    If[deleted > 0,
      Print[Style["  \[Checkmark] \:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:524a\:9664: " <> docId <>
        " (" <> ToString[deleted] <> " \:30d5\:30a1\:30a4\:30eb)", Darker[Green]]],
      Print["  \:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:30d5\:30a1\:30a4\:30eb\:306a\:3057: " <> docId]];
    deleted];

Options[PDFIndex`pdfIndexAsync] = Options[PDFIndex`pdfIndex];

PDFIndex`pdfIndexAsync[pdfPath_String, opts:OptionsPattern[]] :=
  Module[{nb, jobId, privacy, title, collection, forceReindex,
          absPath, docId, extractResult, metadata,
          garbledPages = {}, visionPages = {}, textPages = {},
          pageResults = {}, chunks, docPrivacy, tocData,
          mergedTables, catalog, pythonExe,
          nodes = <||>,
          allOcrIds = {}, allSumIds = {}},

    nb = Quiet @ Check[EvaluationNotebook[], $Failed];
    jobId = "pdfidx-" <> ToString[UnixTime[]] <>
      "-" <> ToString[RandomInteger[99999]];

    (* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
       Phase 0: \:540c\:671f\:51e6\:7406 (\:9ad8\:901f\:3001~10-20s)
       \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)

    (* Claude CLI \:52d5\:4f5c\:78ba\:8a8d: where \:30b3\:30de\:30f3\:30c9\:3067\:76f4\:63a5\:691c\:7d22 *)
    Module[{whereOut},
      whereOut = Quiet @ Check[
        StringTrim @ RunProcess[{"cmd", "/c", "where claude"}, "StandardOutput"], ""];
      If[!StringQ[whereOut] || whereOut === "" ||
         StringContainsQ[whereOut, "Could not find"],
        Print[Style["\[WarningSign] Claude CLI \:304c PATH \:306b\:898b\:3064\:304b\:308a\:307e\:305b\:3093\:3002", Orange, Bold]];
        Print["  OCR/\:8981\:7d04\:306e LLM \:30ce\:30fc\:30c9\:304c\:5931\:6557\:3059\:308b\:53ef\:80fd\:6027\:304c\:3042\:308a\:307e\:3059\:3002"];
        Print["  \:30a4\:30f3\:30b9\:30c8\:30fc\:30eb: npm install -g @anthropic-ai/claude-code"]]];

    privacy    = OptionValue[PDFIndex`pdfIndexAsync, {opts}, Privacy];
    title      = OptionValue[PDFIndex`pdfIndexAsync, {opts}, Title];
    collection = OptionValue[PDFIndex`pdfIndexAsync, {opts}, Collection];
    forceReindex = OptionValue[PDFIndex`pdfIndexAsync, {opts}, ForceReindex];

    (* \:30d1\:30b9\:89e3\:6c7a *)
    absPath = If[iIsURL[pdfPath], iDownloadAndCache[pdfPath],
      If[FileExistsQ[pdfPath], pdfPath,
        FileNameJoin[{Quiet @ Check[NotebookDirectory[],
          Global`$packageDirectory], pdfPath}]]];
    If[!StringQ[absPath] || !FileExistsQ[absPath], Return[$Failed]];

    docId = iDocId[absPath];
    If[nb =!= $Failed,
      Quiet[CurrentValue[nb, WindowStatusArea] = "pdfIndex: \:521d\:671f\:5316..."]];

    (* \:65e2\:5b58\:30c1\:30a7\:30c3\:30af *)
    If[!TrueQ[forceReindex],
      Module[{existing = iFindExistingDoc[docId, collection]},
        If[AssociationQ[existing],
          If[nb =!= $Failed, Quiet[CurrentValue[nb, WindowStatusArea] = ""]];
          Return[existing]]]];

    (* \[HorizontalLine]\[HorizontalLine] \:65e2\:5b58\:5931\:6557\:30b8\:30e7\:30d6\:306e\:691c\:51fa\:30fb\:30ea\:30c8\:30e9\:30a4 \[HorizontalLine]\[HorizontalLine]
       \:540c\:3058 docId \:306e DAG \:30b8\:30e7\:30d6\:304c\:6b8b\:3063\:3066\:3044\:3066 Failed \:30ce\:30fc\:30c9\:304c\:3042\:308c\:3070\:3001
       \:65b0\:898f DAG \:4f5c\:6210\:305b\:305a\:30ea\:30c8\:30e9\:30a4\:3067\:518d\:958b\:3059\:308b\:3002
       ForceReindex \:6642\:306f\:65b0\:898f\:4f5c\:6210\:ff08\:65e7\:30b8\:30e7\:30d6\:306f\:7834\:68c4\:ff09\:3002 *)
    If[!TrueQ[forceReindex],
      Module[{found = ClaudeCode`LLMGraphDAGFindByContext["docId", docId],
              retryTarget},
        retryTarget = SelectFirst[found, #["failed"] > 0 &, None];
        If[AssociationQ[retryTarget],
          Print[Style["\[RightArrow] \:65e2\:5b58\:306e\:5931\:6557\:30b8\:30e7\:30d6\:3092\:691c\:51fa\:3002\:30ea\:30c8\:30e9\:30a4\:3057\:307e\:3059\:3002", Bold]];
          Print["  JobID: ", retryTarget["jobId"]];
          Print["  Done: ", retryTarget["done"], " / Failed: ", retryTarget["failed"],
            " / Total: ", retryTarget["total"]];
          ClaudeCode`LLMGraphDAGRetry[retryTarget["jobId"]];
          (* runtimeId \:304c\:3042\:308c\:3070\:305d\:308c\:3092\:8fd4\:3059\:3001\:306a\:3051\:308c\:3070 jobId *)
          Module[{rtId = Lookup[
              Lookup[retryTarget, "context", <||>], "runtimeId", None]},
            Return[If[StringQ[rtId], rtId, retryTarget["jobId"]]]]]],
      (* ForceReindex \:6642: \:540c\:4e00 docId \:306e\:65e7\:30b8\:30e7\:30d6\:3092\:30ad\:30e3\:30f3\:30bb\:30eb *)
      ClaudeCode`LLMGraphDAGFindByContext["docId", docId, "Cancel"]];

    (* PDF \:30c6\:30ad\:30b9\:30c8\:62bd\:51fa (ExternalEvaluate, ~3s)
       skipOCR=True: \:6587\:5b57\:5316\:3051\:4fee\:5fa9\:306f LLMGraph \:3067\:975e\:540c\:671f\:5b9f\:884c\:3059\:308b\:305f\:3081
       Phase 0 \:3067\:306f\:540c\:671f OCR \:3092\:30b9\:30ad\:30c3\:30d7 \[RightArrow] \:30d5\:30ed\:30f3\:30c8\:30a8\:30f3\:30c9\:975e\:30d6\:30ed\:30c3\:30af *)
    If[nb =!= $Failed,
      Quiet[CurrentValue[nb, WindowStatusArea] = "pdfIndex: \:30c6\:30ad\:30b9\:30c8\:62bd\:51fa\:4e2d..."]];
    extractResult = iPDFExtract[absPath, None, True];
    If[!AssociationQ[extractResult], Return[$Failed]];

    metadata = extractResult["metadata"];
    If[title === None, title = metadata["title"]];
    If[!StringQ[title] || title === "", title = FileBaseName[absPath]];

    (* TOC \:62bd\:51fa *)
    tocData = iExtractTOC[absPath];
    $pdfIndexAsyncContext["pendingTOC"] = tocData;

    (* \:6587\:5b57\:5316\:3051\:30da\:30fc\:30b8\:691c\:51fa: LLMGraph \:3067\:975e\:540c\:671f OCR \:3059\:308b\:5bfe\:8c61\:3092\:6c7a\:5b9a *)
    If[nb =!= $Failed,
      Quiet[CurrentValue[nb, WindowStatusArea] = "pdfIndex: \:30da\:30fc\:30b8\:5206\:6790\:4e2d..."]];
    Module[{pages = Lookup[extractResult, "pages", {}]},
      Do[If[iIsGarbledText[Lookup[p, "text", ""]],
        AppendTo[garbledPages, Lookup[p, "pageNum", 0]]],
        {p, pages}]];

    (* \:30da\:30fc\:30b8\:5206\:985e + \:30d3\:30b8\:30e7\:30f3\:89e3\:6790 (pure Python\:3001\:5404\:30da\:30fc\:30b8 ~1s)
       \:30d3\:30b8\:30e7\:30f3\:89e3\:6790\:5bfe\:8c61\:30da\:30fc\:30b8\:3092 ParallelMap \:3067\:4e26\:5217\:51e6\:7406\:3002
       iAnalyzePageWithVision \:306f ExternalEvaluate["Python", ...] \:3092\:4f7f\:3046\:305f\:3081
       \:30b5\:30d6\:30ab\:30fc\:30cd\:30eb\:3054\:3068\:306b\:72ec\:7acb\:3057\:305f Python \:30bb\:30c3\:30b7\:30e7\:30f3\:3067\:5b9f\:884c\:3055\:308c\:308b\:3002
       \:30e1\:30a4\:30f3\:30ab\:30fc\:30cd\:30eb\:306e ScheduledTask (LLMGraph \:30dd\:30fc\:30ea\:30f3\:30b0) \:306f
       ParallelMap \:4e2d\:3082\:52d5\:4f5c\:3092\:7d99\:7d9a\:3059\:308b (ParallelMap \:306f\:30e1\:30a4\:30f3\:30eb\:30fc\:30d7\:3092
       \:30d6\:30ed\:30c3\:30af\:3057\:306a\:3044; Mathematica \:306e\:4e26\:5217\:30a4\:30f3\:30d5\:30e9\:304c\:7ba1\:7406)\:3002 *)
    Module[{pages = Lookup[extractResult, "pages", {}],
            visionPageData = {}, textPageData = {}, parallelResults},
      (* \:30b9\:30c6\:30c3\:30d71: \:5168\:30da\:30fc\:30b8\:3092\:5206\:985e (\:8efd\:91cf\:30fb\:9010\:6b21) *)
      Do[Module[{pg = page["pageNum"], rawText = Lookup[page, "text", ""]},
        If[iIsTableOrFigurePage[rawText],
          AppendTo[visionPages, pg];
          AppendTo[visionPageData,
            <|"pageNum" -> pg, "rawText" -> rawText|>],
          AppendTo[textPages, pg];
          AppendTo[textPageData,
            <|"pageNum" -> pg, "rawText" -> rawText|>]]],
        {page, pages}];

      (* \:30b9\:30c6\:30c3\:30d72: \:30c6\:30ad\:30b9\:30c8\:30da\:30fc\:30b8\:306f\:5373\:5ea7\:306b pageResults \:306b\:8ffd\:52a0 *)
      Do[AppendTo[pageResults,
        <|"pageNum" -> tp["pageNum"], "isVision" -> False,
          "rawText" -> tp["rawText"],
          "paragraphs" -> {}, "tables" -> {}, "figures" -> {}|>],
        {tp, textPageData}];

      (* \:30b9\:30c6\:30c3\:30d73: \:30d3\:30b8\:30e7\:30f3\:30da\:30fc\:30b8\:3092 ParallelMap \:3067\:4e26\:5217\:89e3\:6790 *)
      If[Length[visionPageData] > 0,
        If[nb =!= $Failed,
          Quiet[CurrentValue[nb, WindowStatusArea] =
            "pdfIndex: \:30d3\:30b8\:30e7\:30f3\:89e3\:6790 " <>
            ToString[Length[visionPageData]] <> " pages (parallel)..."]];
        parallelResults = iParallelMapSafe[
          Function[{vpd},
            Module[{pg = vpd["pageNum"], rawText = vpd["rawText"], vr},
              vr = Quiet @ Check[
                iAnalyzePageWithVision[absPath, pg], $Failed];
              If[AssociationQ[vr],
                Join[vr, <|"pageNum" -> pg, "isVision" -> True|>],
                <|"pageNum" -> pg, "isVision" -> False,
                  "rawText" -> rawText,
                  "paragraphs" -> {}, "tables" -> {}, "figures" -> {}|>]]],
          visionPageData];
        pageResults = Join[pageResults, parallelResults]];

      pageResults = SortBy[pageResults, Lookup[#, "pageNum", 9999] &]];

    (* \:8868\:30de\:30fc\:30b8 + \:30ab\:30bf\:30ed\:30b0 + \:30c1\:30e3\:30f3\:30ad\:30f3\:30b0 *)
    mergedTables = iMergeSpanningTables[pageResults];
    catalog = iBuildCatalog[pageResults, mergedTables, tocData];
    $pdfIndexAsyncContext["pendingCatalog"] = catalog;
    chunks = iChunkFromStructured[pageResults, mergedTables];

    (* \:30d7\:30e9\:30a4\:30d0\:30b7\:30fc\:63a8\:5b9a *)
    If[privacy === Automatic,
      docPrivacy = iEstimatePrivacy[title,
        If[Length[chunks] > 0, Lookup[chunks[[1]], "text", ""], ""]],
      docPrivacy = N[privacy]];

    (* Python \:5b9f\:884c\:30d1\:30b9\:3092\:53d6\:5f97 (Phase 0 \:306e\:540c\:671f\:30b3\:30f3\:30c6\:30ad\:30b9\:30c8\:3067\:5b89\:5168) *)
    pythonExe = Quiet @ Check[
      ExternalEvaluate["Python", "import sys; sys.executable"], "python"];

    (* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
       LLMGraph \:69cb\:7bc9
       \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)

    (* \[HorizontalLine]\[HorizontalLine] OCR \:30ce\:30fc\:30c9\:7fa4: \:6587\:5b57\:5316\:3051\:30da\:30fc\:30b8\:3054\:3068\:306b render \[RightArrow] (ocr-top, ocr-bot) \:4e26\:5217 \[HorizontalLine]\[HorizontalLine]
       \:65e7: render-1 \[RightArrow] ocr-1-top \[RightArrow] ocr-1-bot \[RightArrow] render-2 \[RightArrow] ... (\:76f4\:5217\:30c1\:30a7\:30fc\:30f3)
       \:65b0: render-N \:306f\:4ed6\:30da\:30fc\:30b8\:306b\:4f9d\:5b58\:3057\:306a\:3044\:3002ocr-top/bot \:306f\:81ea\:30da\:30fc\:30b8\:306e render \:306e\:307f\:306b\:4f9d\:5b58\:3002
           \:3053\:308c\:306b\:3088\:308a\:5168\:30da\:30fc\:30b8\:306e OCR \:304c $iPdfTaskDescriptor \:306e maxConcurrency \:307e\:3067
           \:4e26\:5217\:5b9f\:884c\:3055\:308c\:308b\:3002LLMGraph \:30b9\:30b1\:30b8\:30e5\:30fc\:30e9\:304c\:81ea\:52d5\:7684\:306b\:30ab\:30c6\:30b4\:30ea\:5225\:4e26\:5217\:5ea6\:3092\:5236\:5fa1\:3002 *)
    Do[
      With[{pg = garbledPages[[gi]],
            ap = absPath, pyExe = pythonExe, jid = jobId},
        Module[{renderId, ocrTopId, ocrBotId,
                imgDir, topPath, botPath, outMarker},
          renderId = "render-" <> ToString[pg];
          ocrTopId = "ocr-" <> ToString[pg] <> "-top";
          ocrBotId = "ocr-" <> ToString[pg] <> "-bot";
          imgDir  = FileNameJoin[{$TemporaryDirectory,
            "pdfocr_" <> jid <> "_p" <> ToString[pg]}];
          topPath   = FileNameJoin[{imgDir, "top.png"}];
          botPath   = FileNameJoin[{imgDir, "bot.png"}];
          outMarker = FileNameJoin[{imgDir, "render_done.txt"}];

          (* render \:30ce\:30fc\:30c9: \:4f9d\:5b58\:306a\:3057 \[RightArrow] \:5168\:30da\:30fc\:30b8\:306e\:30ec\:30f3\:30c0\:30ea\:30f3\:30b0\:304c\:4e26\:5217\:8d77\:52d5\:53ef\:80fd *)
          nodes[renderId] = ClaudeCode`iLLMGraphNode[renderId, "python", "render",
            {},
            With[{ep = StringReplace[ap, "\\" -> "/"],
                  tp = StringReplace[topPath, "\\" -> "/"],
                  bp = StringReplace[botPath, "\\" -> "/"],
                  om = StringReplace[outMarker, "\\" -> "/"],
                  id = imgDir, px = pyExe, pn = pg},
              Function[{jobCtx},
                Module[{pyScript, pyFile, batFile, proc},
                  If[!DirectoryQ[id],
                    CreateDirectory[id, CreateIntermediateDirectories -> True]];
                  pyScript = StringJoin[
                    "import fitz, io\n",
                    "from PIL import Image\n",
                    "doc = fitz.open(r'", ep, "')\n",
                    "pix = doc[", ToString[pn - 1], "].get_pixmap(dpi=450)\n",
                    "doc.close()\n",
                    "img = Image.open(io.BytesIO(pix.tobytes('png')))\n",
                    "w, h = img.size\n",
                    "half = h // 2\n",
                    "img.crop((0, 0, w, half + 30)).save(r'", tp, "')\n",
                    "img.crop((0, half - 30, w, h)).save(r'", bp, "')\n",
                    "with open(r'", om, "', 'w') as f:\n",
                    "    f.write('OK')\n"];
                  pyFile = FileNameJoin[{id, "render.py"}];
                  Export[pyFile, pyScript, "Text", CharacterEncoding -> "UTF-8"];
                  batFile = FileNameJoin[{id, "render.bat"}];
                  Export[batFile,
                    "@echo off\r\nchcp 65001 > nul\r\n\"" <> px <>
                    "\" \"" <> pyFile <> "\" > \"" <> om <> "\" 2>&1\r\n",
                    "Text", CharacterEncoding -> "ASCII"];
                  proc = Quiet @ StartProcess[{"cmd", "/c", batFile}];
                  If[Head[proc] === ProcessObject,
                    <|"proc" -> proc, "outFile" -> om,
                      "batFile" -> batFile, "promptFile" -> pyFile,
                      "startTime" -> AbsoluteTime[]|>,
                    $Failed]]]]];

          (* OCR \:4e0a\:534a\:5206\:30ce\:30fc\:30c9 *)
          nodes[ocrTopId] = ClaudeCode`iLLMGraphNode[ocrTopId, "claude-cli", "ocr", {renderId},
            With[{tp = topPath, id = imgDir, pn = pg},
              Function[{jobCtx},
                Module[{prompt, ts, outFile, promptFile, batFile, proc},
                  prompt = StringJoin[
                    "The following files are attached. ",
                    "Images are included as multimodal content.\n",
                    "1. ", tp, "\n\n",
                    "\:3053\:306e\:753b\:50cf\:306f\:5927\:5b66\:306e\:914d\:5f53\:8868\:ff08\:5c65\:4fee\:8868\:ff09\:306ePDF\:30da\:30fc\:30b8\:306e\:4e0a\:534a\:5206\:3067\:3059\:3002",
                    "\:8868\:306e\:5168\:3066\:306e\:884c\:3092\:7701\:7565\:305b\:305a\:62bd\:51fa\:3057\:3066\:304f\:3060\:3055\:3044\:3002",
                    "\:79d1\:76ee\:30b3\:30fc\:30c9\:3068\:79d1\:76ee\:540d\:3092\:6b63\:78ba\:306b\:3002",
                    "\:51fa\:529b\:306f\:62bd\:51fa\:30c6\:30ad\:30b9\:30c8\:306e\:307f\:3002\:8aac\:660e\:4e0d\:8981\:3002"];
                  ts = ToString[UnixTime[]] <> "ot" <> ToString[pn];
                  outFile = FileNameJoin[{$TemporaryDirectory,
                    "pis_ocr_" <> ts <> ".txt"}];
                  promptFile = FileNameJoin[{$TemporaryDirectory,
                    "pis_pmt_" <> ts <> ".txt"}];
                  Block[{strm},
                    strm = OpenWrite[promptFile, BinaryFormat -> True];
                    BinaryWrite[strm, ToCharacterCode[prompt, "UTF-8"], "Byte"];
                    Close[strm]];
                  batFile = ClaudeCode`iMakeBat[promptFile, outFile, {id}];
                  proc = Quiet @ StartProcess[{"cmd", "/c", batFile}];
                  If[Head[proc] === ProcessObject,
                    <|"proc" -> proc, "outFile" -> outFile,
                      "promptFile" -> promptFile, "batFile" -> batFile,
                      "startTime" -> AbsoluteTime[]|>,
                    $Failed]]]]];

          (* OCR \:4e0b\:534a\:5206\:30ce\:30fc\:30c9: renderId \:306b\:4f9d\:5b58 (ocrTopId \:3067\:306f\:306a\:3044)
             \[RightArrow] \:4e0a\:4e0b\:534a\:5206\:304c\:540c\:6642\:306b Claude CLI \:3078\:9001\:4fe1\:53ef\:80fd *)
          nodes[ocrBotId] = ClaudeCode`iLLMGraphNode[ocrBotId, "claude-cli", "ocr", {renderId},
            With[{bp = botPath, id = imgDir, pn = pg},
              Function[{jobCtx},
                Module[{prompt, ts, outFile, promptFile, batFile, proc},
                  prompt = StringJoin[
                    "The following files are attached. ",
                    "Images are included as multimodal content.\n",
                    "1. ", bp, "\n\n",
                    "\:3053\:306e\:753b\:50cf\:306f\:5927\:5b66\:306e\:914d\:5f53\:8868\:ff08\:5c65\:4fee\:8868\:ff09\:306ePDF\:30da\:30fc\:30b8\:306e\:4e0b\:534a\:5206\:3067\:3059\:3002",
                    "\:8868\:306e\:5168\:3066\:306e\:884c\:3092\:7701\:7565\:305b\:305a\:62bd\:51fa\:3057\:3066\:304f\:3060\:3055\:3044\:3002",
                    "\:79d1\:76ee\:30b3\:30fc\:30c9\:3068\:79d1\:76ee\:540d\:3092\:6b63\:78ba\:306b\:3002",
                    "\:51fa\:529b\:306f\:62bd\:51fa\:30c6\:30ad\:30b9\:30c8\:306e\:307f\:3002\:8aac\:660e\:4e0d\:8981\:3002"];
                  ts = ToString[UnixTime[]] <> "ob" <> ToString[pn];
                  outFile = FileNameJoin[{$TemporaryDirectory,
                    "pis_ocr_" <> ts <> ".txt"}];
                  promptFile = FileNameJoin[{$TemporaryDirectory,
                    "pis_pmt_" <> ts <> ".txt"}];
                  Block[{strm},
                    strm = OpenWrite[promptFile, BinaryFormat -> True];
                    BinaryWrite[strm, ToCharacterCode[prompt, "UTF-8"], "Byte"];
                    Close[strm]];
                  batFile = ClaudeCode`iMakeBat[promptFile, outFile, {id}];
                  proc = Quiet @ StartProcess[{"cmd", "/c", batFile}];
                  If[Head[proc] === ProcessObject,
                    <|"proc" -> proc, "outFile" -> outFile,
                      "promptFile" -> promptFile, "batFile" -> batFile,
                      "startTime" -> AbsoluteTime[]|>,
                    $Failed]]]]];

          (* rechunk \:306f top/bot \:4e21\:65b9\:306e\:5b8c\:4e86\:3092\:5f85\:3064\:5fc5\:8981\:304c\:3042\:308b *)
          AppendTo[allOcrIds, ocrTopId];
          AppendTo[allOcrIds, ocrBotId]]],
    {gi, Length[garbledPages]}];

    (* \[HorizontalLine]\[HorizontalLine] rechunk \:30ce\:30fc\:30c9: OCR \:7d50\:679c\:3067\:30c1\:30e3\:30f3\:30af\:30c6\:30ad\:30b9\:30c8\:3092\:66f4\:65b0 \[HorizontalLine]\[HorizontalLine] *)
    nodes["rechunk"] = ClaudeCode`iLLMGraphNode["rechunk", "sync", "chunk", allOcrIds,
      With[{gPages = garbledPages},
        Function[{jobCtx},
          Module[{ns = jobCtx["nodes"], updChunks = Lookup[Lookup[jobCtx, "context", <||>], "chunks", {}]},
            Do[Module[{pg = gPages[[gi]],
                       topId, botId, topText, botText, merged},
              topId = "ocr-" <> ToString[pg] <> "-top";
              botId = "ocr-" <> ToString[pg] <> "-bot";
              topText = Lookup[Lookup[ns, topId, <||>], "result", ""];
              botText = Lookup[Lookup[ns, botId, <||>], "result", ""];
              If[StringQ[topText],
                topText = ClaudeCode`cleanOutput[ClaudeCode`stripANSI[topText]]];
              If[StringQ[botText],
                botText = ClaudeCode`cleanOutput[ClaudeCode`stripANSI[botText]]];
              merged = StringTrim[If[StringQ[topText], topText, ""]] <> "\n" <>
                       StringTrim[If[StringQ[botText], botText, ""]];
              If[StringLength[merged] > 20,
                updChunks = Map[
                  If[Lookup[#, "pageNum", 0] === pg,
                    Append[KeyDrop[#, "text"], "text" -> merged], #] &,
                  updChunks]]],
            {gi, Length[gPages]}];
            updChunks]]]];

    (* \[HorizontalLine]\[HorizontalLine] summarize \:30ce\:30fc\:30c9\:7fa4: \:5404\:30c1\:30e3\:30f3\:30af\:306e LLM \:8981\:7d04 \[HorizontalLine]\[HorizontalLine] *)
    Do[
      With[{ci2 = ci, docTitle = title},
        Module[{sumId = "sum-" <> ToString[ci2]},
          nodes[sumId] = ClaudeCode`iLLMGraphNode[sumId, "claude-cli", "summarize", {"rechunk"},
            Function[{jobCtx},
              Module[{updChunks, chk, prompt, ts, outFile, promptFile, batFile, proc},
                updChunks = Lookup[
                  Lookup[jobCtx["nodes"], "rechunk", <||>],
                  "result", Lookup[Lookup[jobCtx, "context", <||>], "chunks", {}]];
                chk = If[ci2 <= Length[updChunks], updChunks[[ci2]], <||>];
                prompt = $pdfChunkSummarizePrompt <>
                  If[docTitle =!= "", "Document: " <> docTitle <> "\n\n", ""] <>
                  StringTake[Lookup[chk, "text", ""], UpTo[3000]];
                ts = ToString[UnixTime[]] <> "s" <> ToString[ci2];
                outFile = FileNameJoin[{$TemporaryDirectory,
                  "pis_sum_" <> ts <> ".txt"}];
                promptFile = FileNameJoin[{$TemporaryDirectory,
                  "pis_pmt_" <> ts <> ".txt"}];
                Block[{strm},
                  strm = OpenWrite[promptFile, BinaryFormat -> True];
                  BinaryWrite[strm, ToCharacterCode[prompt, "UTF-8"], "Byte"];
                  Close[strm]];
                batFile = ClaudeCode`iMakeBat[promptFile, outFile, {}];
                proc = Quiet @ StartProcess[{"cmd", "/c", batFile}];
                If[Head[proc] === ProcessObject,
                  <|"proc" -> proc, "outFile" -> outFile,
                    "promptFile" -> promptFile, "batFile" -> batFile,
                    "startTime" -> AbsoluteTime[]|>,
                  $Failed]]]];
          AppendTo[allSumIds, sumId]]],
    {ci, Length[chunks]}];

    (* \[HorizontalLine]\[HorizontalLine] finalize-embed \:30ce\:30fc\:30c9: Embedding \:751f\:6210 (Python \:975e\:540c\:671f) \[HorizontalLine]\[HorizontalLine]
       Phase 30: \:65e7\:6765\:306f finalize (sync) \:5185\:3067 iEmbedViaLMStudio \:3092\:547c\:3073\:51fa\:3057\:3001
       368 \:30c1\:30e3\:30f3\:30af \[Times] 19 \:30d0\:30c3\:30c1\:306e URLRead \:3067 tick \:3092 20-40 \:79d2\:30d6\:30ed\:30c3\:30af\:3057\:3066\:3044\:305f\:3002
       \:65b0\:8a2d\:8a08: Python \:30b5\:30d6\:30d7\:30ed\:30bb\:30b9\:3067 LM Studio API \:3092\:547c\:3073\:51fa\:3057\:3001
       \:7d50\:679c\:3092 JSON \:3067\:66f8\:304d\:51fa\:3059\:3002\:30e1\:30a4\:30f3\:30ab\:30fc\:30cd\:30eb\:306e tick \:306f\:30d6\:30ed\:30c3\:30af\:3055\:308c\:306a\:3044\:3002
       \:30cf\:30f3\:30c9\:30e9\:306f\:30c7\:30fc\:30bf\:6e96\:5099 (\:30c1\:30e3\:30f3\:30af\:7d50\:679c\:306e\:53ce\:96c6) \:306e\:307f\:3092\:540c\:671f\:5b9f\:884c\:3057\:3001
       Python \:8d77\:52d5\:5f8c\:306f\:30d7\:30ed\:30bb\:30b9 runState \:3092\:8fd4\:3057\:3066 tick \:306b\:623b\:308b\:3002
       iICollectChunkResult \:304c\:5b8c\:4e86\:3092\:30dd\:30fc\:30ea\:30f3\:30b0\:3059\:308b\:3002 *)
    nodes["finalize-embed"] = ClaudeCode`iLLMGraphNode["finalize-embed",
      "python", "embed", allSumIds,
      With[{fDocId = docId, fCollection = collection, pyExe = pythonExe,
            embEndpoint = $embeddingEndpoint, embModel = $embeddingModel},
        Function[{jobCtx},
          Module[{ns = jobCtx["nodes"], finalChunks, processedChunks,
                  embTexts, tempDir, inputFile, outputFile, markerFile,
                  pyScript, pyFile, batFile, proc},
            (* rechunk \:7d50\:679c\:3092\:53d6\:5f97 *)
            finalChunks = Lookup[
              Lookup[ns, "rechunk", <||>], "result",
              Lookup[Lookup[jobCtx, "context", <||>], "chunks", {}]];
            If[!ListQ[finalChunks],
              finalChunks = Lookup[Lookup[jobCtx, "context", <||>], "chunks", {}]];
            (* \:5404\:30c1\:30e3\:30f3\:30af\:306b LLM \:8981\:7d04\:7d50\:679c\:3092\:30de\:30fc\:30b8 *)
            processedChunks = Table[
              Module[{sumId = "sum-" <> ToString[k], raw, lines,
                      summary = "", entities = "", tags = ""},
                raw = Lookup[Lookup[ns, sumId, <||>], "result", ""];
                If[StringQ[raw],
                  lines = StringSplit[raw, "\n"];
                  Scan[Module[{tr = StringTrim[#]},
                    Which[
                      StringStartsQ[tr, "SUMMARY:", IgnoreCase -> True],
                        summary = StringTrim[StringDrop[tr, 8]],
                      StringStartsQ[tr, "ENTITIES:", IgnoreCase -> True],
                        entities = StringTrim[StringDrop[tr, 9]],
                      StringStartsQ[tr, "TAGS:", IgnoreCase -> True],
                        tags = StringTrim[StringDrop[tr, 5]]]] &, lines]];
                Join[If[k <= Length[finalChunks], finalChunks[[k]], <||>],
                  <|"summary" -> summary, "entities" -> entities,
                    "tags" -> tags|>]],
              {k, Length[finalChunks]}];
            (* Embedding \:7528\:30c6\:30ad\:30b9\:30c8\:69cb\:7bc9 (iDoubleEscape \:306f JSON \:7d4c\:7531\:306a\:306e\:3067\:4e0d\:8981) *)
            embTexts = (Lookup[#, "summary", ""] <> " " <>
              Lookup[#, "entities", ""] <> " " <>
              Lookup[#, "tags", ""] <> " " <>
              StringTake[Lookup[#, "text", ""], UpTo[$embeddingTextWindow]]) & /@
              processedChunks;
            (* \:4f5c\:696d\:30c7\:30a3\:30ec\:30af\:30c8\:30ea *)
            tempDir = FileNameJoin[{$TemporaryDirectory,
              "pdfidx_embed_" <> fDocId}];
            If[!DirectoryQ[tempDir],
              CreateDirectory[tempDir, CreateIntermediateDirectories -> True]];
            inputFile  = FileNameJoin[{tempDir, "input.json"}];
            outputFile = FileNameJoin[{tempDir, "embeddings.json"}];
            markerFile = FileNameJoin[{tempDir, "marker.txt"}];
            (* \:51e6\:7406\:6e08\:307f\:30c1\:30e3\:30f3\:30af\:3092\:4e00\:6642\:4fdd\:5b58: finalize (save) \:5074\:3067\:518d\:5229\:7528 \[HorizontalLine]\[HorizontalLine]
               finalize-embed \:3068 finalize \:306e\:4e21\:65b9\:3067 sum \:30ce\:30fc\:30c9\:7d50\:679c\:3092\:518d\:96c6\:8a08\:3059\:308b\:3068
               O(N) \:8a08\:7b97\:304c 2 \:56de\:767a\:751f\:3059\:308b\:305f\:3081\:3001\:4e00\:5ea6\:3060\:3051\:96c6\:8a08\:3057\:3066 WL \:30d5\:30a1\:30a4\:30eb\:306b\:4fdd\:5b58\:3002
               Put \:306f WL \:5f0f\:3068\:3057\:3066\:4fdd\:5b58\:3059\:308b\:306e\:3067 Import["WL"] \:3067\:8aad\:307f\:51fa\:305b\:308b\:3002 *)
            Quiet @ Put[processedChunks,
              FileNameJoin[{tempDir, "processed_chunks.wl"}]];
            (* \:5165\:529b\:30c6\:30ad\:30b9\:30c8\:3092 JSON \:3067\:51fa\:529b *)
            Export[inputFile, embTexts, "JSON"];
            (* Python \:30b9\:30af\:30ea\:30d7\:30c8: LM Studio OpenAI \:4e92\:63db embeddings API \:3092\:547c\:3073\:51fa\:3059\:3002
               - \:6a19\:6e96\:30e9\:30a4\:30d6\:30e9\:30ea\:306e\:307f (urllib.request, json) \:3092\:4f7f\:7528\:3002requests \:4e0d\:8981\:3002
               - \:30a8\:30e9\:30fc\:6642\:306f\:7a7a\:30ea\:30b9\:30c8 [] \:3092\:5404\:30c6\:30ad\:30b9\:30c8\:306b\:5bfe\:5fdc\:3055\:305b\:3066\:51fa\:529b\:3002
               - \:30d0\:30c3\:30c1\:30b5\:30a4\:30ba 20 (\:5927\:91cf\:30c6\:30ad\:30b9\:30c8\:306e\:30e1\:30e2\:30ea\:5bfe\:7b56)\:3002 *)
            pyScript = StringJoin[
              "import json, sys, urllib.request, urllib.error\n",
              "INPUT  = r'", StringReplace[inputFile, "\\" -> "/"], "'\n",
              "OUTPUT = r'", StringReplace[outputFile, "\\" -> "/"], "'\n",
              "MARKER = r'", StringReplace[markerFile, "\\" -> "/"], "'\n",
              "ENDPOINT = '", embEndpoint, "'\n",
              "MODEL = '", embModel, "'\n",
              "BATCH = 20\n",
              "MAX_CHARS = 2000\n",
              "with open(INPUT, 'r', encoding='utf-8') as f:\n",
              "    texts = json.load(f)\n",
              "all_embeddings = []\n",
              "for i in range(0, len(texts), BATCH):\n",
              "    batch = [t[:MAX_CHARS] for t in texts[i:i+BATCH]]\n",
              "    body = json.dumps({'model': MODEL, 'input': batch}).encode('utf-8')\n",
              "    req = urllib.request.Request(ENDPOINT, data=body,\n",
              "        headers={'Content-Type': 'application/json'})\n",
              "    try:\n",
              "        with urllib.request.urlopen(req, timeout=120) as resp:\n",
              "            data = json.loads(resp.read())\n",
              "        items = sorted(data.get('data', []), key=lambda x: x.get('index', 0))\n",
              "        embs = [item.get('embedding', []) for item in items]\n",
              "        if len(embs) < len(batch):\n",
              "            embs += [[] for _ in range(len(batch) - len(embs))]\n",
              "        all_embeddings.extend(embs)\n",
              "    except Exception as e:\n",
              "        sys.stderr.write('batch %d failed: %s\\n' % (i, e))\n",
              "        all_embeddings.extend([[] for _ in batch])\n",
              "with open(OUTPUT, 'w', encoding='utf-8') as f:\n",
              "    json.dump(all_embeddings, f)\n",
              "ok = sum(1 for e in all_embeddings if isinstance(e, list) and len(e) > 100)\n",
              "with open(MARKER, 'w', encoding='utf-8') as f:\n",
              "    f.write('OK %d/%d' % (ok, len(all_embeddings)))\n",
              "print('OK %d/%d' % (ok, len(all_embeddings)))\n"];
            pyFile  = FileNameJoin[{tempDir, "embed.py"}];
            batFile = FileNameJoin[{tempDir, "embed.bat"}];
            Export[pyFile, pyScript, "Text", CharacterEncoding -> "UTF-8"];
            Export[batFile,
              "@echo off\r\nchcp 65001 > nul\r\n\"" <> pyExe <>
              "\" \"" <> pyFile <> "\" > \"" <> markerFile <> "\" 2>&1\r\n",
              "Text", CharacterEncoding -> "ASCII"];
            (* \:30c1\:30e3\:30f3\:30af\:304c 0 \:500b\:306a\:3089 Python \:3092\:8d77\:52d5\:305b\:305a\:7a7a\:30d5\:30a1\:30a4\:30eb\:3092\:66f8\:3044\:3066\:5b8c\:4e86\:6271\:3044 *)
            If[Length[embTexts] === 0,
              Export[outputFile, {}, "JSON"];
              Export[markerFile, "OK 0/0", "Text"];
              (* \:30c0\:30df\:30fc proc \:3092\:4f7f\:308f\:305a finalize (save) \:306b\:59d4\:306d\:308b\:3002
                 iICollectChunkResult \:306f proc=None \:3092\:6271\:3048\:306a\:3044\:305f\:3081\:3001
                 \:7c21\:6613\:30d7\:30ed\:30bb\:30b9\:3092\:8d77\:52d5\:3057\:3066\:3059\:3050\:7d42\:4e86\:3055\:305b\:308b\:3002 *)
              proc = Quiet @ StartProcess[{"cmd", "/c", "exit", "0"}],
              (* \:901a\:5e38\:30b1\:30fc\:30b9: Python \:8d77\:52d5 *)
              proc = Quiet @ StartProcess[{"cmd", "/c", batFile}]];
            If[Head[proc] === ProcessObject,
              <|"proc" -> proc, "outFile" -> markerFile,
                "batFile" -> batFile, "promptFile" -> pyFile,
                "startTime" -> AbsoluteTime[]|>,
              $Failed]]]]];

    (* \[HorizontalLine]\[HorizontalLine] finalize \:30ce\:30fc\:30c9: \:4fdd\:5b58\:306e\:307f (sync\:30fb\:8efd\:91cf) \[HorizontalLine]\[HorizontalLine]
       Phase 30: Embedding \:751f\:6210\:3092 finalize-embed (python \:975e\:540c\:671f) \:306b\:5206\:96e2\:3002
       \:3053\:306e sync \:30ce\:30fc\:30c9\:306f tick \:5185\:3067\:9ad8\:901f\:306b\:5b9f\:884c\:3055\:308c\:308b\:4fdd\:5b58\:51e6\:7406\:306e\:307f\:3092\:62c5\:5f53:
       - finalize-embed \:304c\:66f8\:3044\:305f processed_chunks.wl \:3068 embeddings.json \:3092\:8aad\:307f\:8fbc\:3080
       - Embedding \:3068\:30c1\:30e3\:30f3\:30af\:3092\:30de\:30fc\:30b8
       - doc/chunks/toc/catalog/entities \:30d5\:30a1\:30a4\:30eb\:3092 Put \:3067\:4fdd\:5b58
       LM Studio \:5931\:6557\:6642 (embeddings JSON \:304c\:7a7a/\:4e0d\:8db3) \:306f\:65e7\:6765\:306e iCreateEmbeddings
       \:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af\:3092\:547c\:3073\:3001maildb \:7d4c\:7531\:307e\:305f\:306f\:7a7a\:30d9\:30af\:30c8\:30eb\:3067\:88dc\:5b8c\:3059\:308b\:3002 *)
    nodes["finalize"] = ClaudeCode`iLLMGraphNode["finalize", "sync", "save",
      {"finalize-embed"},
      With[{fDocId = docId, fTitle = title, fDocPrivacy = docPrivacy,
            fCollection = collection, fAbsPath = absPath,
            fMetadata = metadata, fExtractResult = extractResult,
            fPdfPath = pdfPath},
        Function[{jobCtx},
          Module[{processedChunks, embeddings, indexDir, docMeta, yearInfo,
                  firstPageText = "", docFile, chunkFile,
                  tempDir, chunksSavedFile, embeddingsFile,
                  validEmbeddings, needsFallback, embTexts},
            tempDir = FileNameJoin[{$TemporaryDirectory,
              "pdfidx_embed_" <> fDocId}];
            chunksSavedFile = FileNameJoin[{tempDir, "processed_chunks.wl"}];
            embeddingsFile  = FileNameJoin[{tempDir, "embeddings.json"}];
            (* processedChunks \:3092\:8aad\:307f\:8fbc\:307f (finalize-embed \:304c\:4fdd\:5b58) *)
            processedChunks = If[FileExistsQ[chunksSavedFile],
              Quiet @ Check[Get[chunksSavedFile], {}], {}];
            If[!ListQ[processedChunks] || Length[processedChunks] === 0,
              (* \:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af: finalize-embed \:304c\:4fdd\:5b58\:3067\:304d\:306a\:304b\:3063\:305f\:5834\:5408\:3001
                 sum \:30ce\:30fc\:30c9\:304b\:3089\:518d\:96c6\:8a08 (\:65e7\:6765\:306e finalize \:3068\:540c\:3058\:30ed\:30b8\:30c3\:30af) *)
              Module[{ns = jobCtx["nodes"], finalChunks},
                finalChunks = Lookup[
                  Lookup[ns, "rechunk", <||>], "result",
                  Lookup[Lookup[jobCtx, "context", <||>], "chunks", {}]];
                If[!ListQ[finalChunks],
                  finalChunks = Lookup[Lookup[jobCtx, "context", <||>], "chunks", {}]];
                processedChunks = Table[
                  Module[{sumId = "sum-" <> ToString[k], raw, lines,
                          summary = "", entities = "", tags = ""},
                    raw = Lookup[Lookup[ns, sumId, <||>], "result", ""];
                    If[StringQ[raw],
                      lines = StringSplit[raw, "\n"];
                      Scan[Module[{tr = StringTrim[#]},
                        Which[
                          StringStartsQ[tr, "SUMMARY:", IgnoreCase -> True],
                            summary = StringTrim[StringDrop[tr, 8]],
                          StringStartsQ[tr, "ENTITIES:", IgnoreCase -> True],
                            entities = StringTrim[StringDrop[tr, 9]],
                          StringStartsQ[tr, "TAGS:", IgnoreCase -> True],
                            tags = StringTrim[StringDrop[tr, 5]]]] &, lines]];
                    Join[If[k <= Length[finalChunks], finalChunks[[k]], <||>],
                      <|"summary" -> summary, "entities" -> entities,
                        "tags" -> tags|>]],
                  {k, Length[finalChunks]}]]];
            (* Embedding \:8aad\:307f\:8fbc\:307f *)
            embeddings = If[FileExistsQ[embeddingsFile],
              Quiet @ Check[Import[embeddingsFile, "JSON"], {}], {}];
            If[!ListQ[embeddings], embeddings = {}];
            (* \:6709\:52b9\:30d9\:30af\:30c8\:30eb (\:9577\:3055 > 100) \:306e\:6bd4\:7387\:3092\:78ba\:8a8d *)
            validEmbeddings = Count[embeddings,
              _?(ListQ[#] && Length[#] > 100 &)];
            needsFallback = Length[embeddings] =!= Length[processedChunks] ||
              validEmbeddings < Length[processedChunks] / 2;
            If[needsFallback && Length[processedChunks] > 0,
              (* LM Studio / Python \:304c\:5931\:6557\:3057\:305f \[RightArrow] Wolfram \:5074\:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af *)
              Print["  \:26a0 finalize-embed \:306e Embedding \:7d50\:679c\:304c\:4e0d\:5b8c\:5168 (", 
                ToString[validEmbeddings], "/", ToString[Length[processedChunks]],
                ") \[Rule] Wolfram \:5074\:3067\:88dc\:5b8c\:8a66\:884c"];
              iCreateEmbeddingSession[];
              embTexts = (iDoubleEscape[
                Lookup[#, "summary", ""] <> " " <> Lookup[#, "entities", ""] <>
                " " <> Lookup[#, "tags", ""] <>
                " " <> StringTake[Lookup[#, "text", ""], UpTo[$embeddingTextWindow]]] &) /@
                processedChunks;
              embeddings = Quiet @ Check[iCreateEmbeddings[embTexts], {}]];
            (* \:30c1\:30e3\:30f3\:30af\:306b embedding \:3092\:30de\:30fc\:30b8 *)
            If[ListQ[embeddings] && Length[embeddings] === Length[processedChunks],
              processedChunks = MapThread[
                Append[#1, "embedding" ->
                  If[ListQ[#2] && Length[#2] > 100, #2, {}]] &,
                {processedChunks, embeddings}],
              processedChunks = Append[#, "embedding" -> {}] & /@
                processedChunks];
            (* \:4fdd\:5b58 *)
            indexDir = If[fDocPrivacy > 0.5,
              iCollectionDir[fCollection, "private"],
              iCollectionDir[fCollection, "public"]];
            If[ListQ[Lookup[fExtractResult, "pages", {}]] &&
               Length[fExtractResult["pages"]] > 0,
              firstPageText = StringJoin[Riffle[
                Lookup[#, "text", ""] & /@
                  Take[fExtractResult["pages"], UpTo[5]], "\n"]]];
            yearInfo = iExtractYearInfo[fTitle, firstPageText];
            docMeta = <|
              "docId" -> fDocId, "title" -> fTitle,
              "author" -> Lookup[fMetadata, "author", ""],
              "sourcePath" -> If[iIsURL[fPdfPath], fPdfPath, iMakeRelativePath[fAbsPath]],
              "sourceType" -> If[iIsURL[fPdfPath], "url", "file"],
              "privacy" -> fDocPrivacy, "collection" -> fCollection,
              "pageCount" -> Lookup[fMetadata, "pageCount", 0],
              "chunkCount" -> Length[processedChunks],
              "yearInfo" -> yearInfo,
              "indexedAt" -> DateString[Now, "ISODateTime"],
              "storageType" -> If[fDocPrivacy > 0.5, "private", "public"]|>;
            docFile = FileNameJoin[{indexDir, "doc_" <> fDocId <> ".wl"}];
            Put[docMeta, docFile];
            processedChunks = Append[#, "docId" -> fDocId] & /@ processedChunks;
            chunkFile = FileNameJoin[{indexDir, "chunks_" <> fDocId <> ".wl"}];
            Put[processedChunks, chunkFile];
            (* TOC/\:30ab\:30bf\:30ed\:30b0\:4fdd\:5b58 *)
            Module[{toc = Lookup[$pdfIndexAsyncContext, "pendingTOC", {}], tf},
              If[ListQ[toc] && Length[toc] > 0,
                tf = FileNameJoin[{indexDir, "toc_" <> fDocId <> ".wl"}];
                Put[toc, tf]];
              $pdfIndexAsyncContext = KeyDrop[$pdfIndexAsyncContext, "pendingTOC"]];
            Module[{cat = Lookup[$pdfIndexAsyncContext, "pendingCatalog", <||>], cf},
              If[AssociationQ[cat] && Length[cat] > 0,
                cf = FileNameJoin[{indexDir, "catalog_" <> fDocId <> ".wl"}];
                Put[cat, cf]];
              $pdfIndexAsyncContext = KeyDrop[$pdfIndexAsyncContext, "pendingCatalog"]];
            (* \:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:751f\:6210\:30fb\:4fdd\:5b58 *)
            Module[{entityIdx, ef},
              entityIdx = iGenerateEntityIndex[processedChunks, fTitle,
                Lookup[Lookup[jobCtx, "context", <||>], "useLocal", True]];
              If[ListQ[entityIdx] && Length[entityIdx] > 0,
                ef = FileNameJoin[{indexDir, "entities_" <> fDocId <> ".wl"}];
                Put[entityIdx, ef];
                $entityIndexCache = KeyDrop[$entityIndexCache, fCollection]]];
            $pdfIndexCache = KeyDrop[$pdfIndexCache, fCollection];
            (* \:4e00\:6642\:30c7\:30a3\:30ec\:30af\:30c8\:30ea\:306e\:30af\:30ea\:30fc\:30f3\:30a2\:30c3\:30d7 *)
            Quiet @ Check[DeleteDirectory[tempDir, DeleteContents -> True], Null];
            <|"docId" -> fDocId, "title" -> fTitle,
              "privacy" -> fDocPrivacy,
              "chunks" -> Length[processedChunks],
              "collection" -> fCollection|>]]]];

    (* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
       LLMGraphDAGCreate \:3067\:30b8\:30e7\:30d6\:767b\:9332\:30fb\:30b9\:30b1\:30b8\:30e5\:30fc\:30e9\:8d77\:52d5
       \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)
    With[{fGarbledPages = garbledPages},
      jobId = ClaudeCode`LLMGraphDAGCreate[<|
        "nodes" -> nodes,
        "taskDescriptor" -> $iPdfTaskDescriptor,
        "nb" -> nb,
        "context" -> <|
          "chunks" -> chunks,
          "docId" -> docId,
          "title" -> title,
          "garbledPages" -> garbledPages
        |>,
        "onComplete" -> Function[{completedJob},
          Module[{ns = completedJob["nodes"],
                  finalResult = Lookup[
                    Lookup[completedJob["nodes"], "finalize", <||>],
                    "result", None],
                  failCount, jnb = Lookup[completedJob, "nb", $Failed]},
            failCount = Count[Values[ns],
              _?(Lookup[#, "status", ""] === "failed" &)];
            If[jnb =!= $Failed && AssociationQ[finalResult],
              NotebookWrite[jnb, Cell[BoxData[ToBoxes[
                If[failCount > 0,
                  Append[finalResult, "failedNodes" -> failCount],
                  finalResult]]], "Output"]]];
            Scan[Module[{imgDir = FileNameJoin[{$TemporaryDirectory,
                  "pdfocr_" <> jobId <> "_p" <> ToString[#]}]},
              If[DirectoryQ[imgDir],
                Quiet[DeleteDirectory[imgDir, DeleteContents -> True]]]] &,
              fGarbledPages];
            (* \[HorizontalLine]\[HorizontalLine] ClaudeRuntime \:30b9\:30c6\:30fc\:30bf\:30b9\:66f4\:65b0 \[HorizontalLine]\[HorizontalLine] *)
            Module[{ctxRtId = Lookup[
                      Lookup[completedJob, "context", <||>],
                      "runtimeId", None]},
              If[StringQ[ctxRtId],
                Module[{rtState = Quiet @
                    ClaudeRuntime`Private`$iClaudeRuntimes[ctxRtId]},
                  If[AssociationQ[rtState],
                    rtState["Status"] = If[failCount > 0, "Failed", "Done"];
                    rtState["CompletedDAGNodes"] = Association @ Map[
                      KeyDrop[#, {"handler", "runState"}] &, ns];
                    ClaudeRuntime`Private`$iClaudeRuntimes[ctxRtId] =
                      rtState]]]]]]
      |>]];

    (* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
       ClaudeRuntime \:767b\:9332 \[LongDash] \:7d71\:5408 Snapshot/Restore/Retry
       \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)
    Module[{rtId},
      rtId = ClaudeCode`ClaudeRegisterDAGRuntime[jobId, <|
        "Metadata" -> <|
          "docId"      -> docId,
          "title"      -> title,
          "collection" -> collection,
          "absPath"    -> absPath,
          "pdfPath"    -> pdfPath
        |>,
        "AuxiliaryState" -> <|
          "pdfIndexAsyncContext" -> $pdfIndexAsyncContext
        |>
      |>];
      (* DAG \:306e context \:306b runtimeId \:3092\:8ffd\:52a0 *)
      Module[{job = ClaudeCode`Private`$iLLMGraphDAGJobs[jobId]},
        If[AssociationQ[job],
          job["context", "runtimeId"] = rtId;
          ClaudeCode`Private`$iLLMGraphDAGJobs[jobId] = job]];
      rtId]
  ];




(* === \:30da\:30fc\:30b8\:5206\:6790 + \:30c1\:30e3\:30f3\:30ad\:30f3\:30b0 \:30d8\:30eb\:30d1\:30fc (\:540c\:671f\:7248 pdfIndex \:7528\:3001\:4e92\:63db\:7dad\:6301) === *)
iRunPageAnalysisAndChunking[extractResult_Association, absPath_String,
    metadata_Association] := Module[
  {pages, pageResults = {}, visionPages = {}, textPages = {},
   visionPageData = {}, parallelVisionResults,
   tocData, mergedTables, catalog, chunks, pg, rawText, isVision, visionResult},
  tocData = Lookup[extractResult, "toc", {}];
  Module[{toc = iExtractTOC[absPath]},
    Print["  TOC\:30a8\:30f3\:30c8\:30ea: " <> ToString[Length[toc]] <> "\:4ef6"];
    If[ListQ[toc] && Length[toc] > 0,
      $pdfIndexAsyncContext["pendingTOC"] = toc;
      tocData = toc]];
  Print["  \:30da\:30fc\:30b8\:5206\:6790\:4e2d..."];
  pages = Lookup[extractResult, "pages", {}];
  (* \:30b9\:30c6\:30c3\:30d71: \:30da\:30fc\:30b8\:5206\:985e (\:8efd\:91cf\:30fb\:9010\:6b21) *)
  Do[
    pg = page["pageNum"]; rawText = Lookup[page, "text", ""];
    isVision = iIsTableOrFigurePage[rawText];
    If[isVision,
      AppendTo[visionPages, pg];
      AppendTo[visionPageData,
        <|"pageNum" -> pg, "rawText" -> rawText|>],
      AppendTo[textPages, pg]],
    {page, pages}];
  Print["  \:30d3\:30b8\:30e7\:30f3\:89e3\:6790\:5bfe\:8c61: " <>
    ToString[Length[visionPages]] <> "\:30da\:30fc\:30b8 / " <>
    ToString[Length[pages]] <> "\:30da\:30fc\:30b8\:4e2d"];

  (* \:30b9\:30c6\:30c3\:30d72: \:30d3\:30b8\:30e7\:30f3\:30da\:30fc\:30b8\:3092 ParallelMap \:3067\:4e26\:5217\:89e3\:6790 *)
  If[Length[visionPageData] > 0,
    Print["  \:30d3\:30b8\:30e7\:30f3\:89e3\:6790: " <> ToString[Length[visionPageData]] <>
      " pages (parallel)..."];
    parallelVisionResults = iParallelMapSafe[
      Function[{vpd},
        Module[{vpg = vpd["pageNum"], vr},
          vr = Quiet @ Check[iAnalyzePageWithVision[absPath, vpg], $Failed];
          If[AssociationQ[vr],
            Join[vr, <|"pageNum" -> vpg, "isVision" -> True|>],
            <|"pageNum" -> vpg, "isVision" -> False,
              "rawText" -> vpd["rawText"],
              "paragraphs" -> {}, "tables" -> {}, "figures" -> {}|>]]],
      visionPageData];
    pageResults = Join[pageResults, parallelVisionResults];
    Print["  \:30d3\:30b8\:30e7\:30f3\:89e3\:6790\:5b8c\:4e86: " <>
      ToString[Length[parallelVisionResults]] <> " pages"]];

  (* \:30b9\:30c6\:30c3\:30d73: \:30c6\:30ad\:30b9\:30c8\:30da\:30fc\:30b8\:3092\:8ffd\:52a0 *)
  Do[AppendTo[pageResults,
    <|"pageNum" -> pg, "isVision" -> False,
      "rawText" -> Lookup[
        SelectFirst[pages, #["pageNum"] === pg &, <||>], "text", ""],
      "paragraphs" -> {}, "tables" -> {}, "figures" -> {}|>],
    {pg, textPages}];
  pageResults = SortBy[pageResults, Lookup[#, "pageNum", 9999] &];
  mergedTables = iMergeSpanningTables[pageResults];
  catalog = iBuildCatalog[pageResults, mergedTables, tocData];
  Print["  \:30ab\:30bf\:30ed\:30b0: \:8868" <> ToString[Length[catalog["tables"]]] <>
    " \:56f3" <> ToString[Length[catalog["figures"]]] <>
    " \:30bb\:30af\:30b7\:30e7\:30f3" <> ToString[Length[catalog["sections"]]]];
  $pdfIndexAsyncContext["pendingCatalog"] = catalog;
  chunks = iChunkFromStructured[pageResults, mergedTables];
  Print["  \:69cb\:9020\:5316\:30c1\:30e3\:30f3\:30af: " <> ToString[Length[chunks]] <> "\:4ef6"];
  Module[{ocrFixed = Lookup[$pdfIndexAsyncContext, "ocrFixedPages", <||>]},
    If[AssociationQ[ocrFixed] && Length[ocrFixed] > 0,
      Print["  OCR\:30c6\:30ad\:30b9\:30c8\:3067\:30c1\:30e3\:30f3\:30af\:7f6e\:63db: p." <>
        StringRiffle[ToString /@ Keys[ocrFixed], ","]];
      chunks = Map[Module[{cpg = Lookup[#, "pageNum", 0], fixedText},
        fixedText = Lookup[ocrFixed, cpg, None];
        If[StringQ[fixedText],
          Append[KeyDrop[#, "text"], "text" -> fixedText], #]] &, chunks];
      $pdfIndexAsyncContext = KeyDrop[$pdfIndexAsyncContext, "ocrFixedPages"]]];
  chunks
];

(* ============================================================ *)
(* URL \:30c0\:30a6\:30f3\:30ed\:30fc\:30c9\:30fb\:30ad\:30e3\:30c3\:30b7\:30e5                                   *)
(* ============================================================ *)

iDownloadAndCache[url_String] := Module[{dir, hashStr, existing, outPath, data},
  dir = FileNameJoin[{PDFIndex`$pdfIndexAttachDir}];
  If[!DirectoryQ[dir], Quiet[CreateDirectory[dir, CreateIntermediateDirectories -> True]]];
  hashStr = IntegerString[Hash[url, "SHA256"], 16, 8];
  (* \:65e2\:5b58\:30ad\:30e3\:30c3\:30b7\:30e5\:3092\:691c\:7d22 *)
  existing = FileNames["*." <> hashStr <> ".pdf", dir];
  If[Length[existing] > 0, Return[First[existing]]];
  (* \:30c0\:30a6\:30f3\:30ed\:30fc\:30c9 *)
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
(* \:30c7\:30a3\:30ec\:30af\:30c8\:30ea\:4e00\:62ec\:30a4\:30f3\:30c7\:30af\:30b7\:30f3\:30b0                                 *)
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
(* URL \:30a4\:30f3\:30c7\:30af\:30b7\:30f3\:30b0                                            *)
(* ============================================================ *)

Options[PDFIndex`pdfIndexURL] = Options[PDFIndex`pdfIndex];

PDFIndex`pdfIndexURL[url_String, opts:OptionsPattern[]] :=
  PDFIndex`pdfIndex[url, opts];

(* ============================================================ *)
(* \:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:306e\:30ed\:30fc\:30c9                                          *)
(* ============================================================ *)

(* \:65e2\:5b58\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:306e\:691c\:7d22 *)
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

(* \:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:306e\:5168\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:30e1\:30bf\:30c7\:30fc\:30bf\:3092\:30ed\:30fc\:30c9 *)
iLoadCollectionDocs[collection_String] := Module[{dirs, docFiles, docs},
  dirs = {iCollectionDir[collection, "private"],
          iCollectionDir[collection, "public"]};
  docFiles = Flatten[FileNames["doc_*.wl", #] & /@ dirs];
  docs = Select[Quiet[Check[Get[#], Nothing] & /@ docFiles], AssociationQ];
  docs
];

(* \:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:306e\:5168\:30c1\:30e3\:30f3\:30af\:3092\:30ed\:30fc\:30c9 *)
iLoadCollectionChunks[collection_String] := Module[{dirs, chunkFiles, allChunks},
  dirs = {iCollectionDir[collection, "private"],
          iCollectionDir[collection, "public"]};
  chunkFiles = Flatten[FileNames["chunks_*.wl", #] & /@ dirs];
  allChunks = Flatten[
    Select[Quiet[Check[Get[#], {}] & /@ chunkFiles], ListQ], 1];
  Select[allChunks, AssociationQ]
];

(* \:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:306e\:5168\:30da\:30fc\:30b8\:30c6\:30ad\:30b9\:30c8\:3092\:30ed\:30fc\:30c9 (\:30e1\:30e2\:30ea\:30ad\:30e3\:30c3\:30b7\:30e5\:4ed8\:304d) *)
$pdfPageTextCache = <||>;

iLoadCollectionPageTexts[collection_String] :=
  Module[{cached = Lookup[$pdfPageTextCache, collection, None]},
    If[cached =!= None, Return[cached]];
    Module[{dirs, pageFiles, allPages},
      dirs = {iCollectionDir[collection, "private"],
              iCollectionDir[collection, "public"]};
      pageFiles = Flatten[FileNames["pages_*.wl", #] & /@ dirs];
      allPages = Flatten[
        Select[Quiet[Check[Get[#], {}] & /@ pageFiles], ListQ], 1];
      allPages = Select[allPages, AssociationQ];
      If[Length[allPages] > 0,
        Print["  \:30da\:30fc\:30b8\:30c6\:30ad\:30b9\:30c8\:30ad\:30e3\:30c3\:30b7\:30e5: " <> ToString[Length[allPages]] <>
          "\:30da\:30fc\:30b8 (" <> collection <> ")"]];
      $pdfPageTextCache[collection] = allPages;
      allPages]];

(* docId \:3067\:30d5\:30a3\:30eb\:30bf\:3057\:305f\:30da\:30fc\:30b8\:30c6\:30ad\:30b9\:30c8\:3092\:53d6\:5f97
   pages_*.wl \:304c\:306a\:3044\:5834\:5408\:306f\:30c1\:30e3\:30f3\:30af\:304b\:3089\:30da\:30fc\:30b8\:30c6\:30ad\:30b9\:30c8\:3092\:81ea\:52d5\:518d\:69cb\:6210 *)
iGetDocPageTexts[collection_String, docId_String] :=
  Module[{allPages = iLoadCollectionPageTexts[collection], filtered},
    filtered = If[docId === "",
      allPages,
      Select[allPages, Lookup[#, "docId", ""] === docId &]];
    If[Length[filtered] > 0, Return[filtered]];
    (* pages_*.wl \:306a\:3057: \:30c1\:30e3\:30f3\:30af\:304b\:3089\:30da\:30fc\:30b8\:30c6\:30ad\:30b9\:30c8\:3092\:518d\:69cb\:6210\:3057\:3066\:30ad\:30e3\:30c3\:30b7\:30e5 *)
    Module[{chunks, result = {}},
      chunks = iLoadCollectionChunks[collection];
      If[docId =!= "",
        chunks = Select[chunks, Lookup[#, "docId", ""] === docId &]];
      If[Length[chunks] === 0, Return[{}]];
      (* \:30c1\:30e3\:30f3\:30af\:3092\:30da\:30fc\:30b8\:756a\:53f7\:3067\:30b0\:30eb\:30fc\:30d7\:5316\:3057\:3066\:9023\:7d50 *)
      Module[{pageTextMap = <||>, pageDocMap = <||>},
      Do[Module[{pg = Lookup[c, "pageNum", 0],
                 txt = Lookup[c, "text", ""],
                 did = Lookup[c, "docId", ""]},
        If[IntegerQ[pg] && pg > 0 && StringQ[txt],
          pageTextMap[pg] = Lookup[pageTextMap, pg, ""] <> "\n" <> txt;
          If[!KeyExistsQ[pageDocMap, pg], pageDocMap[pg] = did]]],
        {c, chunks}];
      result = SortBy[
        KeyValueMap[<|"page" -> #1, "text" -> StringTrim[#2],
                      "docId" -> Lookup[pageDocMap, #1, ""]|> &,
          pageTextMap],
        Lookup[#, "page", 0] &]];
      If[Length[result] > 0,
        Print["  \:30c1\:30e3\:30f3\:30af\:304b\:3089\:30da\:30fc\:30b8\:30c6\:30ad\:30b9\:30c8\:518d\:69cb\:6210: " <> ToString[Length[result]] <> "\:30da\:30fc\:30b8"];
        (* \:30ad\:30e3\:30c3\:30b7\:30e5\:306b\:8ffd\:52a0 *)
        $pdfPageTextCache[collection] =
          Join[Lookup[$pdfPageTextCache, collection, {}], result]];
      result]];

(* \:30ab\:30bf\:30ed\:30b0\:30d5\:30a1\:30a4\:30eb\:306e\:30ed\:30fc\:30c9 *)
iLoadCollectionCatalogs[collection_String] := Module[{dirs, catalogFiles, catalogs},
  dirs = {iCollectionDir[collection, "private"],
          iCollectionDir[collection, "public"]};
  catalogFiles = Flatten[FileNames["catalog_*.wl", #] & /@ dirs];
  catalogs = Select[
    Quiet[Check[Get[#], Nothing] & /@ catalogFiles], AssociationQ];
  (* \:5168\:30ab\:30bf\:30ed\:30b0\:3092\:7d71\:5408 *)
  If[Length[catalogs] === 0, Return[<|"tables" -> {}, "figures" -> {}, "sections" -> {}|>]];
  <|"tables" -> Flatten[Lookup[#, "tables", {}] & /@ catalogs],
    "figures" -> Flatten[Lookup[#, "figures", {}] & /@ catalogs],
    "sections" -> Flatten[Lookup[#, "sections", {}] & /@ catalogs]|>
];

(* PDFIndexObject \:306e\:69cb\:7bc9 *)
PDFIndex`pdfLoadIndex[collection_String:"default"] := Module[
  {docs, chunks, catalogs, embRules, embRulesST, nearest, nearestST},
  (* \:30ad\:30e3\:30c3\:30b7\:30e5\:30c1\:30a7\:30c3\:30af *)
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
  (* NearestFunction \:69cb\:7bc9 *)
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
(* \:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:7ba1\:7406                                              *)
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
(* \:691c\:7d22\:30a8\:30f3\:30b8\:30f3                                                  *)
(* ============================================================ *)

(* \:30af\:30a8\:30ea\:62e1\:5f35: LLM \:3092\:4f7f\:308f\:305a\:30ad\:30fc\:30ef\:30fc\:30c9\:5206\:5272\:306e\:307f\:3067\:5bfe\:5fdc\:3002
   \:8ab2\:91d1API\:547c\:3073\:51fa\:3057\:3092\:9632\:6b62\:3059\:308b\:305f\:3081\:3001LLM\:62e1\:5f35\:306f\:7121\:52b9\:5316\:3002 *)
iExpandSearchQuery[query_String] := query;

(* \:30ad\:30fc\:30ef\:30fc\:30c9\:30de\:30c3\:30c1\:30b9\:30b3\:30a2 *)
(* ============================================================ *)
(* \:65e5\:672c\:8a9e\:5bfe\:5fdc\:30af\:30a8\:30ea\:5206\:5272 (maildb.wl \:306e splitQueryTerms \:79fb\:690d)      *)
(* ============================================================ *)

(* \:52a9\:8a5e\:30fb\:63a5\:7d9a\:8a5e\:3067\:30af\:30a8\:30ea\:3092\:5206\:5272\:3057\:3001\:610f\:5473\:306e\:3042\:308b\:8a9e\:3092\:62bd\:51fa *)
iSplitQueryTerms[query_String] := Module[{raw, terms},
  raw = StringSplit[query, Whitespace];
  terms = Flatten[StringSplit[#,
    RegularExpression["\:306e|\:306f|\:304c|\:3092|\:306b|\:3067|\:3068|\:3082|\:3078|\:304b\:3089|\:307e\:3067|\:306b\:3064\:3044\:3066|\:306b\:304a\:3051\:308b|\:306b\:3088\:308b|\:306b\:95a2\:3059\:308b|\:3068\:306f|\:3063\:3066|\:305f|\:3067\:3059|\:307e\:3059|\:3057\:305f"]] & /@ raw];
  (* \:7591\:554f\:7b26\:7b49\:3092\:9664\:53bb *)
  terms = StringReplace[#, RegularExpression["[?\:ff1f!,.\:3001\:3002\:30fb]"] -> ""] & /@ terms;
  Select[terms, StringLength[#] >= 2 &]
];

(* \:6587\:5b57\:7a2e\:5883\:754c\:3067\:8907\:5408\:8a9e\:3092\:3055\:3089\:306b\:5206\:5272 (\:6f22\:5b57/\:30ab\:30bf\:30ab\:30ca/\:82f1\:6570\:5b57\:306e\:5207\:308c\:76ee)
   \:4f8b: "\:60c5\:5831\:5de5\:5b66\:79d1" \[RightArrow] {"\:60c5\:5831\:5de5\:5b66\:79d1", "\:60c5\:5831", "\:5de5\:5b66", "\:5de5\:5b66\:79d1"}
   \:4f8b: "CANDAR\:8ad6\:6587" \[RightArrow] {"CANDAR\:8ad6\:6587", "CANDAR", "\:8ad6\:6587"} *)
iSplitAtCharBoundary[term_String] := Module[{parts, result, kanjiNgrams},
  parts = StringCases[term,
    RegularExpression[
      "[\:30a0-\:30ff\:31f0-\:31ff\:ff65-\:ff9f]+" <>   (* katakana *)
      "|[\:4e00-\:9fff\:3400-\:4dbf\:f900-\:faff]+" <>  (* kanji *)
      "|[\:3040-\:309f]+" <>                        (* hiragana *)
      "|[A-Za-z0-9\:ff10-\:ff19\:ff21-\:ff3a\:ff41-\:ff5a]+"]];  (* alphanum *)
  parts = Select[parts, StringLength[#] >= 2 &];
  result = If[Length[parts] > 1, Prepend[parts, term], {term}];
  (* \:6f22\:5b573\:6587\:5b57\:4ee5\:4e0a\:306e\:9023\:7d9a\:304b\:30892-gram, 3-gram \:3092\:751f\:6210 *)
  kanjiNgrams = Flatten[Function[p,
    If[StringMatchQ[p, RegularExpression["[\:4e00-\:9fff\:3400-\:4dbf\:f900-\:faff]{3,}"]],
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

(* \:30ad\:30fc\:30ef\:30fc\:30c9\:30de\:30c3\:30c1\:30b9\:30b3\:30a2: \:65e5\:672c\:8a9e\:5bfe\:5fdc\:7248 *)
iKeywordMatchScore[chunk_Association, query_String] :=
  Module[{terms, subTerms, score = 0.0, text, summ, tags, entities, hasMeta},
    terms = iSplitQueryTerms[query];
    If[Length[terms] == 0, terms = {query}];
    (* \:6587\:5b57\:7a2e\:5883\:754c\:3067\:8ffd\:52a0\:5206\:5272 *)
    subTerms = DeleteDuplicates[Flatten[iSplitAtCharBoundary /@ terms]];
    text = If[StringQ[chunk["text"]], StringTake[chunk["text"], UpTo[3000]], ""];
    summ = If[StringQ[chunk["summary"]], chunk["summary"], ""];
    tags = If[StringQ[chunk["tags"]], chunk["tags"], ""];
    entities = If[StringQ[chunk["entities"]], chunk["entities"], ""];
    (* \:30e1\:30bf\:30c7\:30fc\:30bf (summary/tags) \:304c\:5b58\:5728\:3059\:308b\:304b *)
    hasMeta = StringLength[summ] > 0 || StringLength[tags] > 0;
    (* \:5143\:306e\:30bf\:30fc\:30e0\:3067\:30d5\:30eb\:30a6\:30a7\:30a4\:30c8\:30b9\:30b3\:30a2\:30ea\:30f3\:30b0 *)
    Do[
      If[StringContainsQ[summ, term, IgnoreCase -> True], score += 3.0];
      If[StringContainsQ[entities, term, IgnoreCase -> True], score += 3.0];
      If[StringContainsQ[tags, term, IgnoreCase -> True], score += 2.0];
      (* \:30c6\:30ad\:30b9\:30c8\:306e\:30aa\:30ea\:30b8\:30ca\:30eb\:30bf\:30fc\:30e0: \:30e1\:30bf\:306a\:3057\:6642\:306f\:9ad8\:30a6\:30a7\:30a4\:30c8 *)
      If[StringContainsQ[text, term, IgnoreCase -> True],
        score += If[hasMeta, 1.0, 5.0]],
      {term, terms}];
    (* \:5168\:30bf\:30fc\:30e0\:304c\:540c\:4e00\:30c1\:30e3\:30f3\:30af\:306b\:5171\:8d77 \[RightArrow] \:30dc\:30fc\:30ca\:30b9 *)
    If[Length[terms] >= 2 &&
       AllTrue[terms, StringContainsQ[text, #, IgnoreCase -> True] &],
      score += 3.0 * Length[terms]];
    (* \:30b5\:30d6\:30bf\:30fc\:30e0\:3067\:6e1b\:8870\:30a6\:30a7\:30a4\:30c8\:30b9\:30b3\:30a2\:30ea\:30f3\:30b0 *)
    With[{extraTerms = Complement[subTerms, terms]},
      Do[
        If[StringContainsQ[summ, st, IgnoreCase -> True], score += 1.5];
        If[StringContainsQ[entities, st, IgnoreCase -> True], score += 1.5];
        If[StringContainsQ[tags, st, IgnoreCase -> True], score += 1.0];
        If[StringContainsQ[text, st, IgnoreCase -> True], score += 0.3],
        {st, extraTerms}]];
    score / Max[Length[terms], 1]
  ];

(* \:30cf\:30a4\:30d6\:30ea\:30c3\:30c9\:691c\:7d22 *)
Options[PDFIndex`pdfSearch] = {
  Collection -> "default",
  MaxItems -> 20,
  MinPrivacy -> None,
  MaxPrivacy -> None
};

(* \:5185\:90e8: \:751f\:30c7\:30fc\:30bf\:3092\:8fd4\:3059\:691c\:7d22\:30b3\:30a2 *)
iPdfSearchRaw[query_String, maxItems_Integer, collection_String,
              minPriv_, maxPriv_] :=
  Module[{idx, expandedQuery, qEmbedding,
          embIndices, kwScores, allIndices,
          embRanks, finalScores, ranked, filtered},
    (* \:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:30ed\:30fc\:30c9 *)
    idx = PDFIndex`pdfLoadIndex[collection];
    If[idx["count"] === 0,
      Print["  \:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:304c\:7a7a\:3067\:3059\:3002\:5148\:306b pdfIndex[] \:3067\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:3092\:8ffd\:52a0\:3057\:3066\:304f\:3060\:3055\:3044\:3002"];
      Return[{}]];

    (* \:30af\:30a8\:30ea\:62e1\:5f35 *)
    expandedQuery = iExpandSearchQuery[query];

    (* \:691c\:7d22\:8a9e\:306e\:8868\:793a *)
    Module[{terms = iSplitQueryTerms[query],
            subTerms},
      subTerms = DeleteDuplicates[Flatten[iSplitAtCharBoundary /@ terms]];
      Print["  \:691c\:7d22\:8a9e: " <> StringRiffle[terms, ", "] <>
        If[Length[subTerms] > Length[terms],
          "  (+\:5206\:5272: " <> StringRiffle[Complement[subTerms, terms], ", "] <> ")",
          ""]]];

    If[TrueQ[PDFIndex`$pdfIndexDebug],
      Print["  \:62e1\:5f35\:30af\:30a8\:30ea: " <> StringTake[expandedQuery, UpTo[80]] <> "..."]];

    (* Embedding \:691c\:7d22 *)
    qEmbedding = Quiet @ Check[
      First[iCreateEmbeddings[{expandedQuery}]], {}];
    embIndices = If[idx["nearest"] =!= None && Length[qEmbedding] > 100,
      idx["nearest"][qEmbedding, Min[maxItems * 3, idx["count"]]],
      (* Embedding \:672a\:4f7f\:7528: \:30ad\:30fc\:30ef\:30fc\:30c9\:691c\:7d22\:306b\:4f9d\:5b58 *)
      (Print["  \:26a0 Embedding\:672a\:4f7f\:7528 (\:30ad\:30fc\:30ef\:30fc\:30c9\:691c\:7d22\:306e\:307f)"]; {})];

    (* \:30ad\:30fc\:30ef\:30fc\:30c9\:691c\:7d22: \:5168\:30c1\:30e3\:30f3\:30af\:3092\:30b9\:30ad\:30e3\:30f3 *)
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

    (* === \:30ab\:30bf\:30ed\:30b0\:30b9\:30b3\:30a2\:30d6\:30fc\:30b9\:30c8 ===
       \:8868\:30ad\:30e3\:30d7\:30b7\:30e7\:30f3\:30fb\:56f3\:30ad\:30e3\:30d7\:30b7\:30e7\:30f3\:30fb\:30bb\:30af\:30b7\:30e7\:30f3\:898b\:51fa\:3057\:306b\:30af\:30a8\:30ea\:304c\:30de\:30c3\:30c1\:3057\:305f\:3089
       \:8a72\:5f53\:30da\:30fc\:30b8\:306e\:30c1\:30e3\:30f3\:30af\:30b9\:30b3\:30a2\:3092\:5927\:5e45\:306b\:5f15\:304d\:4e0a\:3052\:308b *)
    Module[{catalogs, catalogPages = {}, qTerms = iSplitQueryTerms[query],
            subTerms, cScore},
      catalogs = Quiet @ Check[Lookup[idx, "catalogs", <||>], <||>];
      If[AssociationQ[catalogs],
        subTerms = DeleteDuplicates[Flatten[iSplitAtCharBoundary /@ qTerms]];
        (* \:8868\:30ab\:30bf\:30ed\:30b0\:691c\:7d22 *)
        Do[
          cScore = 0;
          Do[If[StringContainsQ[Lookup[te, "searchText", ""],
                t, IgnoreCase -> True], cScore++], {t, subTerms}];
          If[cScore > 0,
            Do[AppendTo[catalogPages,
              p -> cScore * 2.0],  (* \:8868\:30d2\:30c3\:30c8\:306f\:9ad8\:30d6\:30fc\:30b9\:30c8 *)
              {p, Range[te["startPage"], te["endPage"]]}]],
          {te, Lookup[catalogs, "tables", {}]}];
        (* \:56f3\:30ab\:30bf\:30ed\:30b0\:691c\:7d22 *)
        Do[
          cScore = 0;
          Do[If[StringContainsQ[Lookup[fe, "searchText", ""],
                t, IgnoreCase -> True], cScore++], {t, subTerms}];
          If[cScore > 0,
            AppendTo[catalogPages, fe["page"] -> cScore * 1.5]],
          {fe, Lookup[catalogs, "figures", {}]}];
        (* \:30ab\:30bf\:30ed\:30b0\:30de\:30c3\:30c1\:30da\:30fc\:30b8\:306e\:30c1\:30e3\:30f3\:30af\:3092\:30d6\:30fc\:30b9\:30c8 *)
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

    (* \:30ad\:30fc\:30ef\:30fc\:30c9\:30de\:30c3\:30c1\:60c5\:5831\:306e\:8868\:793a *)
    Module[{kwMatches, kwMatchCount, topKw, qTerms = iSplitQueryTerms[query]},
      kwMatches = Select[kwScores, #[[1]] > 0 &];
      kwMatchCount = Length[kwMatches];
      Print["  \:30ad\:30fc\:30ef\:30fc\:30c9\:30de\:30c3\:30c1: " <> ToString[kwMatchCount] <> "\:4ef6" <>
        If[Length[embIndices] > 0,
          ", Embedding\:7d50\:679c: " <> ToString[Length[embIndices]] <> "\:4ef6", ""]];
      (* \:4e0a\:4f4d5\:4ef6\:306e\:30ad\:30fc\:30ef\:30fc\:30c9\:30de\:30c3\:30c1\:3092KWIC\:3067\:8868\:793a *)
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

    (* \:30d7\:30e9\:30a4\:30d0\:30b7\:30fc\:30d5\:30a3\:30eb\:30bf + \:30b9\:30b3\:30a2\:30fb\:30e1\:30bf\:30c7\:30fc\:30bf\:4ed8\:52a0 *)
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

(* \:516c\:958bAPI: \:898b\:3084\:3059\:3044 Dataset \:3067\:8fd4\:3059 *)
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
        "docTitle" -> StringTake[If[StringQ[#1["docTitle"]], #1["docTitle"], ""], UpTo[80]],
        "docId" -> Lookup[#1, "docId", ""],
        "summary" -> If[StringQ[#1["summary"]], #1["summary"], ""],
        "tags" -> If[StringQ[#1["tags"]], #1["tags"], ""],
        "context" -> iKWIC[If[StringQ[#1["text"]], #1["text"], ""], queryTerms, 120],
        (* pdfGetChunk \:306f\:914d\:5217\:4f4d\:7f6e\:3067\:7d22\:5f15\:3059\:308b\:305f\:3081\:3001\:7d50\:679c ChunkId \:306b\:306f globalIdx(\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:5185\:756a\:53f7\:3067
           doc\:3092\:307e\:305f\:3044\:3067\:885d\:7a81\:3059\:308b)\:3067\:306f\:306a\:304f chunkIndex(\:5168\:4f53\:306e\:914d\:5217\:4f4d\:7f6e)\:3092\:4f7f\:3046\:3002\:3053\:308c\:3092\:8aa4\:308b\:3068
           pdfGetChunk \:304c\:5225\:30c1\:30e3\:30f3\:30af\:306e\:672c\:6587\:3092\:8fd4\:3057\:3001LLM \:306b\:9593\:9055\:3063\:305f\:6839\:62e0\:304c\:6e21\:308b\:3002 *)
        "chunkIdx" -> Lookup[#1, "chunkIndex", #2[[1]]]|> &,
      raw]
  ];

(* KWIC: Keyword In Context \[LongDash] \:30de\:30c3\:30c1\:3057\:305f\:30ad\:30fc\:30ef\:30fc\:30c9\:5468\:8fba\:306e\:30c6\:30ad\:30b9\:30c8\:3092\:62bd\:51fa *)
iKWIC[text_String, queryTerms_List, maxLen_Integer:120] :=
  Module[{pos, bestPos = 0, bestTerm = "", term, p, start, end, result},
    If[StringLength[text] == 0, Return[""]];
    (* \:6700\:521d\:306b\:30de\:30c3\:30c1\:3059\:308b\:30aa\:30ea\:30b8\:30ca\:30eb\:30bf\:30fc\:30e0\:3092\:63a2\:3059 (\:9577\:3044\:8a9e\:3092\:512a\:5148) *)
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
      (* \:30aa\:30ea\:30b8\:30ca\:30eb\:30bf\:30fc\:30e0\:306a\:3057 \[RightArrow] \:30b5\:30d6\:30bf\:30fc\:30e0\:3067\:691c\:7d22 *)
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
      (* \:30de\:30c3\:30c1\:306a\:3057 \[RightArrow] \:5148\:982d\:3092\:8868\:793a *)
      Return[StringTake[text, UpTo[maxLen]]]];
    (* \:30de\:30c3\:30c1\:4f4d\:7f6e\:306e\:524d\:5f8c\:3092\:8868\:793a *)
    start = Max[1, bestPos - 40];
    end = Min[StringLength[text], bestPos + maxLen - 40];
    result = "";
    If[start > 1, result = "..."];
    result = result <> StringTake[text, {start, end}];
    If[end < StringLength[text], result = result <> "..."];
    (* \:30de\:30c3\:30c1\:7b87\:6240\:3092\:3010\:3011\:3067\:56f2\:3080 *)
    StringReplace[result, bestTerm -> "\:300c" <> bestTerm <> "\:300d", 1]
  ];

(* \:30c1\:30e3\:30f3\:30af\:304b\:3089\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:30e1\:30bf\:30c7\:30fc\:30bf\:3092\:53d6\:5f97\:3059\:308b\:30d8\:30eb\:30d1\:30fc *)
iGetDocMetaForChunk[chunk_Association, docs_List] :=
  Module[{cDocId, match},
    cDocId = Lookup[chunk, "docId", ""];
    If[cDocId === "" || !StringQ[cDocId],
      Return[First[docs, None]]];
    match = Select[docs, Lookup[#, "docId", ""] === cDocId &, 1];
    If[Length[match] > 0, First[match], First[docs, None]]
  ];

(* ============================================================ *)
(* \:30c1\:30e3\:30f3\:30af\:76f4\:63a5\:53d6\:5f97                                              *)
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
(* PDF \:30da\:30fc\:30b8\:753b\:50cf\:8868\:793a                                            *)
(* ============================================================ *)

(* \:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:306e\:30bd\:30fc\:30b9\:30d1\:30b9\:3092\:53d6\:5f97 *)
iGetDocSourcePath[collection_String] := Module[{docs},
  docs = iLoadCollectionDocs[collection];
  If[Length[docs] > 0,
    iResolveSourcePath[First[docs]["sourcePath"]],
    None]
];

(* \:30c1\:30e3\:30f3\:30af\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:304b\:3089\:306e\:7c97\:63a8\:5b9a\:ff08\:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af\:7528\:ff09 *)
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
(* PDF \:30da\:30fc\:30b8\:30c6\:30ad\:30b9\:30c8\:76f4\:63a5\:691c\:7d22 (TOC\:512a\:5148 + \:8fd1\:63a5\:6027\:30b9\:30b3\:30a2\:30ea\:30f3\:30b0)       *)
(* ============================================================ *)

(* \:30b3\:30ec\:30af\:30b7\:30e7\:30f3\:306eTOC\:3092\:30ed\:30fc\:30c9 *)
iLoadTOC[collection_String] := Module[{dirs, tocFiles, toc},
  dirs = {iCollectionDir[collection, "private"],
          iCollectionDir[collection, "public"]};
  tocFiles = Flatten[FileNames["toc_*.wl", #] & /@ dirs];
  If[Length[tocFiles] === 0, Return[{}]];
  toc = Quiet @ Check[Get[First[tocFiles]], {}];
  If[ListQ[toc], toc, {}]
];

(* PDF\:306e\:5404\:30da\:30fc\:30b8\:30c6\:30ad\:30b9\:30c8\:3092\:53d6\:5f97\:3057\:3066\:30b9\:30b3\:30a2\:30ea\:30f3\:30b0
   \:6226\:7565: TOC\:304c\:3042\:308c\:3070\:30bb\:30af\:30b7\:30e7\:30f3\:7bc4\:56f2\:3092\:7d5e\:308a\:8fbc\:307f\:3001\:305d\:306e\:7bc4\:56f2\:5185\:3092\:512a\:5148\:7684\:306b\:691c\:7d22 *)
iSearchPDFPages[pdfPath_String, query_String] :=
  iSearchPDFPagesWithCollection[pdfPath, query, "default"];

iSearchPDFPagesWithCollection[pdfPath_String, query_String,
    collection_String, docId_String:""] :=
  Module[{terms, json,
          toc, tocRange, scores, rangeScores, bestPage, allPages, pairScores,
          chunkScores = <||>},
    terms = iSplitQueryTerms[query];
    If[Length[terms] === 0, terms = {query}];

    (* TOC \:3092\:30ed\:30fc\:30c9\:3057\:3066\:30da\:30fc\:30b8\:7bc4\:56f2\:3092\:7279\:5b9a *)
    toc = iLoadTOC[collection];
    tocRange = iTOCFindPageRange[toc, query];
    If[tocRange =!= None,
      Print["  TOC: \"" <> tocRange["section"] <> "\" \[RightArrow] p." <>
        ToString[tocRange["startPage"]] <> "-" <>
        ToString[tocRange["endPage"]]]];

    (* === \:30da\:30fc\:30b8\:30c6\:30ad\:30b9\:30c8\:3092\:30ad\:30e3\:30c3\:30b7\:30e5\:304b\:3089\:30ed\:30fc\:30c9 ===
       \:30a4\:30f3\:30c7\:30af\:30b7\:30f3\:30b0\:6642\:306b\:4fdd\:5b58\:6e08\:307f\:306e pages_<docId>.wl \:3092\:4f7f\:7528\:3002
       ExternalEvaluate/Python \:4e0d\:4f7f\:7528\:3002\:30e1\:30e2\:30ea\:30ad\:30e3\:30c3\:30b7\:30e5\:304b\:3089\:5373\:5ea7\:306b\:53c2\:7167\:3002
       \:6587\:5b57\:5316\:3051\:88dc\:5b8c\:306f\:4e0d\:8981 (\:30a4\:30f3\:30c7\:30af\:30b7\:30f3\:30b0\:6642\:306b iFixGarbledPages \:3067\:4fee\:6b63\:6e08\:307f)\:3002 *)
    json = iGetDocPageTexts[collection, docId];
    If[Length[json] === 0,
      Print["  \:30da\:30fc\:30b8\:30c6\:30ad\:30b9\:30c8\:30ad\:30e3\:30c3\:30b7\:30e5\:306a\:3057: WL Import \:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af"];
      Return[iSearchPDFPagesWL[pdfPath, terms]]];

    (* === \:30c1\:30e3\:30f3\:30af\:30d9\:30fc\:30b9\:30da\:30fc\:30b8\:30b9\:30b3\:30a2\:30ea\:30f3\:30b0 (\:30d7\:30e9\:30a4\:30de\:30ea) ===
       \:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:6e08\:307f\:30c1\:30e3\:30f3\:30af\:306fOCR\:88dc\:6b63\:30fb\:8868\:69cb\:9020\:89e3\:6790\:6e08\:307f\:3067\:4fe1\:983c\:6027\:304c\:9ad8\:3044\:3002
       \:30c1\:30e3\:30f3\:30af\:3067\:30d2\:30c3\:30c8\:3057\:305f\:30da\:30fc\:30b8\:3092\:5f37\:304f\:30d6\:30fc\:30b9\:30c8\:3059\:308b\:3002 *)
    Module[{chunks, filteredChunks},
      chunks = iLoadCollectionChunks[collection];
      If[docId =!= "",
        chunks = Select[chunks, Lookup[#, "docId", ""] === docId &]];
      If[Length[chunks] > 0,
        Do[
          Module[{pg = Lookup[c, "pageNum", 0],
                  txt = iNormalizeForMatch[Lookup[c, "text", ""]],
                  cap = Lookup[c, "tableCaption", ""],
                  isTab = TrueQ[Lookup[c, "isTable", False]],
                  matched = {}, sc = 0},
            If[!IntegerQ[pg] || pg <= 0 || !StringQ[txt], Continue[]];
            (* \:30bf\:30fc\:30e0\:7167\:5408: \:30c1\:30e3\:30f3\:30af\:30c6\:30ad\:30b9\:30c8 + \:30c6\:30fc\:30d6\:30eb\:30ad\:30e3\:30d7\:30b7\:30e7\:30f3 *)
            Do[
              Module[{nt = iNormalizeForMatch[t]},
              If[StringContainsQ[txt, nt, IgnoreCase -> True] ||
                 (StringQ[cap] && StringContainsQ[iNormalizeForMatch[cap], nt, IgnoreCase -> True]),
                AppendTo[matched, t];
                sc += StringLength[t] * 3]],
              {t, terms}];
            (* \:8907\:6570\:30bf\:30fc\:30e0\:5171\:8d77\:30dc\:30fc\:30ca\:30b9 *)
            If[Length[matched] >= 2,
              sc *= (1 + Length[matched])];
            (* \:30c6\:30fc\:30d6\:30eb\:30c1\:30e3\:30f3\:30af + \:30c7\:30fc\:30bf\:30af\:30a8\:30ea\:8a9e\:5f59 \[RightArrow] \:8ffd\:52a0\:30d6\:30fc\:30b9\:30c8 *)
            If[isTab && sc > 0 &&
               AnyTrue[{"\:5fc5\:4fee", "\:9078\:629e", "\:5358\:4f4d", "\:914d\:5f53", "\:958b\:8b1b", "\:79d1\:76ee"},
                 StringContainsQ[query, #] &],
              sc *= 2];
            If[sc > 0,
              chunkScores[pg] = Lookup[chunkScores, pg, 0] + sc]],
          {c, chunks}];
        If[Length[chunkScores] > 0,
          Print["  \:30c1\:30e3\:30f3\:30af\:30b9\:30b3\:30a2: " <>
            StringRiffle[
              ("p." <> ToString[#[[1]]] <> "=" <>
                ToString[#[[2]]]) & /@
                Take[SortBy[Normal[chunkScores], -#[[2]] &], UpTo[5]], ", "]]]]];

    (* \:30b9\:30b3\:30a2\:30ea\:30f3\:30b0: \:500b\:5225\:30da\:30fc\:30b8 *)
    allPages = iScorePagesByProximity[json, terms];

    (* \:30c1\:30e3\:30f3\:30af\:30b9\:30b3\:30a2\:3092\:30da\:30fc\:30b8\:30b9\:30b3\:30a2\:306b\:7d71\:5408: \:30c1\:30e3\:30f3\:30af\:306f\:4fe1\:983c\:6027\:304c\:9ad8\:3044\:306e\:3067\:5927\:304d\:304f\:52a0\:7b97 *)
    If[AssociationQ[chunkScores] && Length[chunkScores] > 0,
      allPages = Map[
        Module[{pg = #[[1]], sc = #[[2]], csc},
          csc = Lookup[chunkScores, pg, 0];
          {pg, sc + csc}] &,
        allPages];
      (* \:30c1\:30e3\:30f3\:30af\:306b\:306e\:307f\:5b58\:5728\:3059\:308b\:30da\:30fc\:30b8\:3082\:8ffd\:52a0 *)
      Do[
        If[!MemberQ[allPages[[All, 1]], pg],
          AppendTo[allPages, {pg, chunkScores[pg]}]],
        {pg, Keys[chunkScores]}]];

    (* === \:9023\:7d9a\:30da\:30fc\:30b8\:30da\:30a2\:30b9\:30b3\:30a2\:30ea\:30f3\:30b0 ===
       \:8868\:304c\:30da\:30fc\:30b8\:3092\:307e\:305f\:3050\:5834\:5408: p.N \:306b\:8868\:30d8\:30c3\:30c0(\:60c5\:5831\:5de5\:5b66\:79d1)\:3001p.N+1 \:306b\:8868\:672c\:4f53(\:96e2\:6563\:6570\:5b66)
       \[RightArrow] 2\:30da\:30fc\:30b8\:9023\:7d50\:3057\:3066\:30b9\:30b3\:30a2\:30ea\:30f3\:30b0\:3057\:3001\:30da\:30a2\:3068\:3057\:3066\:8a55\:4fa1 *)
    pairScores = {};
    Do[
      Module[{p1 = json[[i]], p2 = json[[i + 1]],
              pg1, pg2, combinedText, pairScore},
        pg1 = Lookup[p1, "page", 0];
        pg2 = Lookup[p2, "page", 0];
        combinedText = Lookup[p1, "text", ""] <> "\n" <> Lookup[p2, "text", ""];
        pairScore = First[iScorePagesByProximity[
          {<|"page" -> pg2, "text" -> combinedText|>}, terms]];
        (* \:30da\:30a2\:30b9\:30b3\:30a2\:306b1.5\:500d\:30dc\:30fc\:30ca\:30b9: \:8868\:304c\:307e\:305f\:3050\:30da\:30fc\:30b8\:3092\:512a\:9047 *)
        If[pairScore[[2]] > 0,
          AppendTo[pairScores, {pg2, pairScore[[2]] * 1.5, pg1}]]],
      {i, Length[json] - 1}];
    (* \:30da\:30a2\:30b9\:30b3\:30a2\:3092\:500b\:5225\:30b9\:30b3\:30a2\:306b\:7d71\:5408 *)
    Do[
      Module[{pg = ps[[1]], psc = ps[[2]]},
        allPages = Map[
          If[#[[1]] === pg && psc > #[[2]],
            {#[[1]], psc}, #] &,
          allPages]],
      {ps, pairScores}];

    allPages = Select[allPages, #[[2]] > 0 &];
    If[Length[allPages] === 0, Return[$Failed]];

    (* TOC\:3067\:30da\:30fc\:30b8\:7bc4\:56f2\:304c\:7279\:5b9a\:3067\:304d\:305f\:5834\:5408:
       TOC\:30de\:30c3\:30c1\:306f\:6587\:66f8\:69cb\:9020\:306b\:57fa\:3065\:304f\:5f37\:3044\:4fe1\:53f7\:3002
       \:7bc4\:56f2\:5185\:30da\:30fc\:30b8\:306b\:306f\:5927\:304d\:306a\:30dc\:30fc\:30ca\:30b9\:3001\:7bc4\:56f2\:5916\:30da\:30fc\:30b8\:306b\:306f\:30da\:30ca\:30eb\:30c6\:30a3\:3002
       \:30c1\:30e3\:30f3\:30af\:30b9\:30b3\:30a2\:3082\:7bc4\:56f2\:5185\:3067\:9ad8\:3051\:308c\:3070\:78ba\:4fe1\:5ea6UP\:3002 *)
    If[tocRange =!= None,
      Module[{sp = tocRange["startPage"], ep = tocRange["endPage"],
              maxInRange, tocConfidence},
        (* \:7bc4\:56f2\:5185\:30da\:30fc\:30b8\:306e\:6700\:5927\:30b9\:30b3\:30a2\:3092\:53d6\:5f97 *)
        maxInRange = Max[0, Sequence @@ (
          Cases[allPages, {pg_, sc_} /; sp <= pg <= ep :> sc])];
        (* TOC\:78ba\:4fe1\:5ea6: \:7bc4\:56f2\:5185\:306b\:30c1\:30e3\:30f3\:30af\:30d2\:30c3\:30c8\:3082\:3042\:308c\:3070\:9ad8\:78ba\:4fe1 *)
        tocConfidence = If[AssociationQ[chunkScores] &&
            AnyTrue[Keys[chunkScores], sp <= # <= ep &],
          "high", "normal"];
        If[tocConfidence === "high",
          Print["  TOC+\:30c1\:30e3\:30f3\:30af\:78ba\:4fe1: high (\:7bc4\:56f2 p." <>
            ToString[sp] <> "-" <> ToString[ep] <> ")"]];
        allPages = Map[
          Module[{pg = #[[1]], sc = #[[2]]},
            Which[
              (* \:7bc4\:56f2\:5185: \:5927\:304d\:306a\:30dc\:30fc\:30ca\:30b9 *)
              sp <= pg <= ep,
                {pg, sc * 2.0 + 200.0},
              (* \:8fd1\:508d *)
              pg > ep && pg <= ep + 5,
                {pg, sc + 50.0},
              pg < sp && pg >= sp - 3,
                {pg, sc + 50.0},
              (* \:7bc4\:56f2\:5916: \:9ad8\:78ba\:4fe1\:306a\:3089\:6e1b\:8870\:30da\:30ca\:30eb\:30c6\:30a3 *)
              tocConfidence === "high",
                {pg, sc * 0.3},
              True,
                {pg, sc * 0.7}]] &,
          allPages]]];

    (* === \:30c7\:30fc\:30bf\:30c6\:30fc\:30d6\:30eb\:30da\:30fc\:30b8\:30d6\:30fc\:30b9\:30c8 ===
       \:300c\:914d\:5f53\:671f\:306f\:ff1f\:300d\:300c\:5358\:4f4d\:6570\:306f\:ff1f\:300d\:306a\:3069\:5177\:4f53\:7684\:30c7\:30fc\:30bf\:3092\:554f\:3046\:30af\:30a8\:30ea\:3067\:306f\:3001
       \:30ab\:30ea\:30ad\:30e5\:30e9\:30e0\:30de\:30c3\:30d7(\:6982\:5ff5\:56f3)\:3088\:308a\:5b9f\:969b\:306e\:30c7\:30fc\:30bf\:8868\:3092\:512a\:5148\:3059\:308b\:3002
       \:30c7\:30fc\:30bf\:8868\:306e\:7279\:5b9a\:6307\:6a19:
         - \:79d1\:76ee\:30b3\:30fc\:30c9 (T06xxx, T16xxx\:7b49) \:304c\:591a\:6570 \[RightArrow] \:914d\:5f53\:8868/\:79d1\:76ee\:4e00\:89a7
         - "\:8b1b\:7fa9"/"\:6f14\:7fd2" \:304c\:8907\:6570\:56de \[RightArrow] \:6388\:696d\:5f62\:614b\:8a18\:8f09\:306e\:8868
       \:6982\:5ff5\:56f3(\:30ab\:30ea\:30ad\:30e5\:30e9\:30e0\:30de\:30c3\:30d7)\:306f\:77ed\:3044\:884c\:304c\:591a\:3044\:304c\:79d1\:76ee\:30b3\:30fc\:30c9\:306f\:542b\:307e\:306a\:3044 *)
    Module[{dataTerms = {"\:914d\:5f53", "\:5358\:4f4d", "\:958b\:8b1b", "\:5fc5\:4fee", "\:9078\:629e", "\:524d\:671f", "\:5f8c\:671f",
              "\:79d1\:76ee", "\:30ca\:30f3\:30d0\:30fc", "\:6642\:9593\:5272"}, isDataQuery},
      isDataQuery = AnyTrue[dataTerms,
        StringContainsQ[query, #] &];
      If[isDataQuery,
        allPages = Map[
          Module[{pg = #[[1]], sc = #[[2]], pageText, codeCount, formatCount,
                  tableScore = 0},
            pageText = Lookup[
              SelectFirst[json, Lookup[#, "page", 0] === pg &, <||>],
              "text", ""];
            If[StringLength[pageText] > 0,
              (* \:79d1\:76ee\:30b3\:30fc\:30c9\:6570: \:30c7\:30fc\:30bf\:8868\:306e\:6307\:6a19 (\:63a7\:3048\:3081\:306a\:30d6\:30fc\:30b9\:30c8:
                 \:30bf\:30fc\:30e0\:306e\:95a2\:9023\:6027\:3092\:4e0a\:66f8\:304d\:3057\:306a\:3044\:3088\:3046\:6291\:5236) *)
              codeCount = Length[StringCases[pageText,
                RegularExpression["[A-Z]\\d{2}[A-Z]{2,3}\\d{3}"]]];
              (* \:6388\:696d\:5f62\:614b: "\:8b1b\:7fa9" "\:6f14\:7fd2" "\:5b9f\:9a13" \:306e\:51fa\:73fe\:6570 *)
              formatCount = StringCount[pageText, "\:8b1b\:7fa9"] +
                StringCount[pageText, "\:6f14\:7fd2"] +
                StringCount[pageText, "\:5b9f\:9a13"];
              tableScore = Min[sc * 0.2, codeCount * 3 + formatCount * 2];
              If[tableScore > 0,
                Print["  p." <> ToString[pg] <> " \:30c6\:30fc\:30d6\:30eb\:30b9\:30b3\:30a2: +" <>
                  ToString[tableScore] <>
                  " (\:79d1\:76ee\:30b3\:30fc\:30c9" <> ToString[codeCount] <>
                  ", \:6388\:696d\:5f62\:614b" <> ToString[formatCount] <> ")"]];
              {pg, sc + tableScore},
            #]] &,
          allPages];
        Print["  \:30c7\:30fc\:30bf\:30af\:30a8\:30ea\:691c\:51fa: \:30c6\:30fc\:30d6\:30eb\:30d6\:30fc\:30b9\:30c8\:9069\:7528"]]];

    (* === \:76ee\:6b21\:30fb\:7d22\:5f15\:30da\:30fc\:30b8\:30da\:30ca\:30eb\:30c6\:30a3 ===
       \:76ee\:6b21\:30da\:30fc\:30b8\:306f\:591a\:304f\:306e\:30bf\:30fc\:30e0\:3092\:542b\:3080\:304c\:3001\:5b9f\:969b\:306e\:30b3\:30f3\:30c6\:30f3\:30c4\:3067\:306f\:306a\:3044\:3002
       \:300c\:30fb\:30fb\:30fb\:300d\:30d1\:30bf\:30fc\:30f3\:3084\:300c\:76ee\:6b21\:300d\:300c\:76ee\:3000\:6b21\:300d\:306e\:5b58\:5728\:3067\:691c\:51fa\:3057\:3001\:5927\:5e45\:6e1b\:8870\:3002
       \:305f\:3060\:3057\:30af\:30a8\:30ea\:81ea\:4f53\:304c\:300c\:76ee\:6b21\:300d\:3092\:542b\:3080\:5834\:5408\:306f\:30da\:30ca\:30eb\:30c6\:30a3\:306a\:3057\:3002 *)
    If[!StringContainsQ[query, "\:76ee\:6b21"],
      allPages = Map[
        Module[{pg = #[[1]], sc = #[[2]], pageText, dotCount, isTOCPage},
          pageText = Lookup[
            SelectFirst[json, Lookup[#, "page", 0] === pg &, <||>],
            "text", ""];
          isTOCPage = False;
          If[StringLength[pageText] > 0,
            (* \:300c\:76ee\:3000\:6b21\:300d\:300c\:76ee\:6b21\:300d\:304c\:30da\:30fc\:30b8\:5185\:306b\:3042\:308b *)
            If[StringContainsQ[pageText,
                 RegularExpression["\:76ee\\s*\:6b21"]] &&
               (* \:300c\:30fb\:30fb\:30fb\:300d\:30ea\:30fc\:30c0\:30fc\:7dda\:304c\:591a\:6570 *)
               StringCount[pageText, "\:30fb\:30fb\:30fb"] >= 3,
              isTOCPage = True];
            (* \:30ea\:30fc\:30c0\:30fc\:7dda + \:30da\:30fc\:30b8\:756a\:53f7\:30d1\:30bf\:30fc\:30f3\:304c\:5927\:91cf\:306b\:3042\:308b *)
            If[!isTOCPage,
              dotCount = StringCount[pageText, "\:30fb\:30fb\:30fb"] +
                StringCount[pageText,
                  RegularExpression["[\\.\[Ellipsis]]{3,}\\s*\\d+"]];
              If[dotCount >= 8, isTOCPage = True]]];
          If[isTOCPage,
            Print["  p." <> ToString[pg] <>
              " \:76ee\:6b21\:30da\:30fc\:30b8\:691c\:51fa: \:9664\:5916"];
            {pg, 0},
            #]] &,
        allPages]];

    (* === \:5b66\:79d1\:540d\:30da\:30ca\:30eb\:30c6\:30a3 ===
       \:30af\:30a8\:30ea\:306b\:5b66\:79d1\:540d(department \:30a8\:30f3\:30c6\:30a3\:30c6\:30a3)\:304c\:542b\:307e\:308c\:308b\:5834\:5408\:3001
       \:305d\:306e\:5b66\:79d1\:540d\:304c\:30c6\:30ad\:30b9\:30c8\:306b\:306a\:3044\:30da\:30fc\:30b8\:3092\:5927\:5e45\:6e1b\:8870\:3002
       \:5b66\:79d1\:540d\:306f\:300c\:3069\:306e\:30bb\:30af\:30b7\:30e7\:30f3\:306e\:60c5\:5831\:304b\:300d\:3092\:7279\:5b9a\:3059\:308b\:91cd\:8981\:306a\:5236\:7d04\:3002 *)
    Module[{entities = iGetEntityIndex[collection],
            deptTerms = {}, queryDepts},
      queryDepts = Select[entities,
        Lookup[#, "type", ""] === "department" &&
        (StringContainsQ[query, Lookup[#, "canonical", ""],
           IgnoreCase -> True] ||
         AnyTrue[Lookup[#, "aliases", {}],
           StringContainsQ[query, #, IgnoreCase -> True] &]) &];
      If[Length[queryDepts] > 0,
        deptTerms = Lookup[#, "canonical", ""] & /@ queryDepts;
        allPages = Map[
          Module[{pg = #[[1]], sc = #[[2]], pageText, hasDept},
            pageText = Lookup[
              SelectFirst[json, Lookup[#, "page", 0] === pg &, <||>],
              "text", ""];
            hasDept = AnyTrue[deptTerms,
              StringContainsQ[pageText, #, IgnoreCase -> True] &];
            If[!hasDept && sc > 0,
              {pg, sc * 0.15},
              #]] &,
          allPages]]];

    bestPage = First[SortBy[allPages, -#[[2]] &]];

    (* === TOC\:7bc4\:56f2\:5916\:30d9\:30b9\:30c8\:30da\:30fc\:30b8\:691c\:51fa ===
       TOC\:304c\:7279\:5b9a\:306e\:30bb\:30af\:30b7\:30e7\:30f3\:3092\:6307\:3057\:305f\:306e\:306b\:30d9\:30b9\:30c8\:30da\:30fc\:30b8\:304c\:305d\:306e\:7bc4\:56f2\:5916\:306e\:5834\:5408:
       (a) \:7bc4\:56f2\:5185\:306b\:6709\:610f\:306a\:30b9\:30b3\:30a2\:306e\:30da\:30fc\:30b8\:304c\:3042\:308b \[RightArrow] \:7bc4\:56f2\:5185\:30d9\:30b9\:30c8\:306b\:5207\:66ff
           (\:4f8b: TOC=\:60c5\:5831\:5de5\:5b66\:79d1 p.132-133 \:3060\:304c\:6a5f\:68b0\:30b7\:30b9\:30c6\:30e0\:5de5\:5b66\:79d1 p.135 \:304c\:6700\:9ad8\:30b9\:30b3\:30a2
            \[RightArrow] p.132 \:306e\:65b9\:304c\:6b63\:3057\:3044)
       (b) \:7bc4\:56f2\:5185\:306b\:30b9\:30b3\:30a2\:306e\:3042\:308b\:30da\:30fc\:30b8\:304c\:306a\:3044 \[RightArrow] $Failed \:3067\:4ed6\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:691c\:7d22 *)
    If[tocRange =!= None,
      Module[{sp = tocRange["startPage"], ep = tocRange["endPage"],
              bestPg = bestPage[[1]], bestSc = bestPage[[2]],
              inRangeScores, bestInRange},
        inRangeScores = Select[allPages,
          sp <= #[[1]] <= ep && #[[2]] > 0 &];
        If[!(sp <= bestPg <= ep),
          Module[{nearRange = sp - 3 <= bestPg <= ep + 3,
                  inRangeMax = If[Length[inRangeScores] > 0,
                    Max[inRangeScores[[All, 2]]], 0]},
            Which[
              (* (a) \:30d9\:30b9\:30c8\:304cTOC\:7bc4\:56f2\:306e\:8fd1\:508d(\[PlusMinus]3\:30da\:30fc\:30b8) \[RightArrow] \:30b3\:30f3\:30c6\:30f3\:30c4\:30b9\:30b3\:30a2\:3092\:4fe1\:983c
                 TOC\:306e\:30da\:30fc\:30b8\:756a\:53f7\:304c1-2\:30da\:30fc\:30b8\:305a\:308c\:3066\:3044\:308b\:3053\:3068\:306f\:3088\:304f\:3042\:308b\:3002
                 \:4f8b: TOC=p.132-133(\:60c5\:5831\:5de5\:5b66\:79d1) \:3060\:304cp.131\:304c\:5b9f\:969b\:306e\:914d\:5f53\:8868 *)
              nearRange,
                Print["  TOC\:8fd1\:508d\:30da\:30fc\:30b8: p." <> ToString[bestPg] <>
                  "(score=" <> ToString[NumberForm[bestSc, {5,1}]] <>
                  ", TOC\:7bc4\:56f2p." <> ToString[sp] <> "-" <> ToString[ep] <>
                  "\:306e\[PlusMinus]" <> ToString[Abs[bestPg - sp]] <>
                  ") \[RightArrow] \:30b3\:30f3\:30c6\:30f3\:30c4\:30b9\:30b3\:30a2\:3092\:4fe1\:983c"];
                (* bestPage \:306f\:305d\:306e\:307e\:307e\:4fdd\:6301 *) Null,
              (* (b) \:7bc4\:56f2\:5185\:306b\:6709\:610f\:306a\:30b9\:30b3\:30a2\:304c\:3042\:308a\:3001\:304b\:3064\:30d9\:30b9\:30c8\:306e60%\:4ee5\:4e0a \[RightArrow] \:7bc4\:56f2\:5185\:512a\:5148
                 \:9060\:304f\:306e\:30da\:30fc\:30b8\:304c\:9ad8\:30b9\:30b3\:30a2\:3067\:3082\:3001\:7bc4\:56f2\:5185\:304c\:5341\:5206\:9ad8\:3051\:308c\:3070TOC\:3092\:4fe1\:983c *)
              inRangeMax >= 50 && inRangeMax >= bestSc * 0.6,
                bestInRange = First[SortBy[inRangeScores, -#[[2]] &]];
                Print["  TOC\:7bc4\:56f2\:5185\:512a\:5148: p." <> ToString[bestPg] <>
                  "(score=" <> ToString[NumberForm[bestSc, {5,1}]] <>
                  ") \[RightArrow] p." <> ToString[bestInRange[[1]]] <>
                  "(score=" <> ToString[NumberForm[bestInRange[[2]], {5,1}]] <>
                  ", TOC\:7bc4\:56f2\:5185)"];
                bestPage = bestInRange,
              (* (c) \:7bc4\:56f2\:5916\:304b\:3064\:9060\:304f\:3001\:7bc4\:56f2\:5185\:306b\:30b9\:30b3\:30a2\:306a\:3057 \[RightArrow] \:4ed6\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:691c\:7d22 *)
              bestSc < 200,
                Print["  TOC\:7bc4\:56f2(p." <> ToString[sp] <> "-" <> ToString[ep] <>
                  ")\:5916\:306b\:30d9\:30b9\:30c8: p." <> ToString[bestPg] <>
                  " \[RightArrow] \:6587\:66f8\:5185\:30de\:30c3\:30c1\:4e0d\:5341\:5206\:3068\:5224\:5b9a"];
                Return[$Failed],
              (* (d) \:7bc4\:56f2\:5916\:3060\:304c\:9ad8\:30b9\:30b3\:30a2 \[RightArrow] \:30b3\:30f3\:30c6\:30f3\:30c4\:30b9\:30b3\:30a2\:3092\:4fe1\:983c *)
              True, Null]]]]];

    allPages = Select[allPages, #[[2]] > 0 &];

    Print["  \:30da\:30fc\:30b8\:30b9\:30b3\:30a2: " <>
      StringRiffle[
        ("p." <> ToString[#[[1]]] <> "=" <>
          ToString[NumberForm[#[[2]], {5, 1}]]) & /@
          Take[SortBy[allPages, -#[[2]] &], UpTo[5]], ", "]];

    (* \:30d9\:30b9\:30c8\:30da\:30fc\:30b8\:3092\:8fd4\:3059\:3002
       \:30da\:30a2\:30b9\:30b3\:30a2\:30ea\:30f3\:30b0\:3067\:30d9\:30b9\:30c8\:30da\:30fc\:30b8\:304c\:6c7a\:307e\:3063\:305f\:5834\:5408\:3001
       \:8868\:306e\:30d8\:30c3\:30c0\:306f\:5e38\:306b\:524d\:30da\:30fc\:30b8\:306b\:3042\:308b\:305f\:3081 {bestPg-1, bestPg} \:3092\:30da\:30a2\:3068\:3059\:308b *)
    Module[{bestPg = bestPage[[1]], hasPairContext},
      (* bestPg \:304c\:4f55\:3089\:304b\:306e\:30da\:30a2\:306b\:95a2\:4e0e\:3057\:3066\:3044\:308b\:304b\:78ba\:8a8d *)
      hasPairContext = Length[Select[pairScores,
        #[[1]] === bestPg || #[[3]] === bestPg &]] > 0;
      If[hasPairContext && bestPg > 1,
        $pdfIndexAsyncContext["lastPairPages"] = {bestPg - 1, bestPg},
        $pdfIndexAsyncContext["lastPairPages"] = None];
      bestPg]
  ];

(* \:30da\:30fc\:30b8\:30b9\:30b3\:30a2\:30ea\:30f3\:30b0: \:7a00\:5c11\:5ea6 \[Times] \:5171\:8d77\:91cd\:8996\:3002\:898b\:51fa\:3057\:4f4d\:7f6e\:306f\:8003\:616e\:3057\:306a\:3044\:ff08TOC\:304c\:62c5\:5f53\:ff09 *)
(* \:30c6\:30ad\:30b9\:30c8\:6b63\:898f\:5316: \:4e2d\:9ed2\:30fb\:5168\:89d2\:30b9\:30da\:30fc\:30b9\:7b49\:3092\:9664\:53bb\:3057\:3066\:30de\:30c3\:30c1\:7cbe\:5ea6\:3092\:5411\:4e0a *)
iNormalizeForMatch[s_String] :=
  StringReplace[s, {
    (* \:8a18\:53f7\:9664\:53bb *)
    "\:30fb" -> "", "\:ff5e" -> "", "\:3000" -> " ",
    "\:ff0d" -> "", "\[Hyphen]" -> "", "\:2011" -> "", "\:2012" -> "",
    "\[Dash]" -> "", "\[LongDash]" -> "",
    (* \:534a\:89d2\:30ab\:30bf\:30ab\:30ca \[RightArrow] \:5168\:89d2\:30ab\:30bf\:30ab\:30ca *)
    "\:ff71" -> "\:30a2", "\:ff72" -> "\:30a4", "\:ff73" -> "\:30a6",
    "\:ff74" -> "\:30a8", "\:ff75" -> "\:30aa",
    "\:ff76" -> "\:30ab", "\:ff77" -> "\:30ad", "\:ff78" -> "\:30af",
    "\:ff79" -> "\:30b1", "\:ff7a" -> "\:30b3",
    "\:ff7b" -> "\:30b5", "\:ff7c" -> "\:30b7", "\:ff7d" -> "\:30b9",
    "\:ff7e" -> "\:30bb", "\:ff7f" -> "\:30bd",
    "\:ff80" -> "\:30bf", "\:ff81" -> "\:30c1", "\:ff82" -> "\:30c4",
    "\:ff83" -> "\:30c6", "\:ff84" -> "\:30c8",
    "\:ff85" -> "\:30ca", "\:ff86" -> "\:30cb", "\:ff87" -> "\:30cc",
    "\:ff88" -> "\:30cd", "\:ff89" -> "\:30ce",
    "\:ff8a" -> "\:30cf", "\:ff8b" -> "\:30d2", "\:ff8c" -> "\:30d5",
    "\:ff8d" -> "\:30d8", "\:ff8e" -> "\:30db",
    "\:ff8f" -> "\:30de", "\:ff90" -> "\:30df", "\:ff91" -> "\:30e0",
    "\:ff92" -> "\:30e1", "\:ff93" -> "\:30e2",
    "\:ff94" -> "\:30e4", "\:ff95" -> "\:30e6", "\:ff96" -> "\:30e8",
    "\:ff97" -> "\:30e9", "\:ff98" -> "\:30ea", "\:ff99" -> "\:30eb",
    "\:ff9a" -> "\:30ec", "\:ff9b" -> "\:30ed",
    "\:ff9c" -> "\:30ef", "\:ff9d" -> "\:30f3",
    "\:ff6f" -> "\:30c3", "\:ff6c" -> "\:30e3", "\:ff6d" -> "\:30e5",
    "\:ff6e" -> "\:30e7", "\:ff70" -> "\:30fc"}];

iScorePagesByProximity[pages_List, terms_List] :=
  Module[{termPageCounts, nTerms},
    nTerms = iNormalizeForMatch /@ terms;
    (* \:30bf\:30fc\:30e0\:51fa\:73fe\:30da\:30fc\:30b8\:6570\:3092\:4e8b\:524d\:96c6\:8a08: \:7a00\:5c11\:306a\:30bf\:30fc\:30e0\:307b\:3069\:9ad8\:30a6\:30a7\:30a4\:30c8 *)
    termPageCounts = Association@Table[
      nTerms[[i]] -> Length[Select[pages,
        StringContainsQ[iNormalizeForMatch[Lookup[#, "text", ""]],
          nTerms[[i]], IgnoreCase -> True] &]],
      {i, Length[nTerms]}];
    Map[
      Module[{text = iNormalizeForMatch[Lookup[#, "text", ""]],
              pg = Lookup[#, "page", 0],
              positions, matchedTerms, sc = 0, proxBonus = 0},
        positions = Association[
          # -> Quiet @ Check[
            StringPosition[text, #, 1],
            {}] & /@ nTerms];
        matchedTerms = Select[nTerms, Length[positions[#]] > 0 &];
        (* \:57fa\:672c\:30b9\:30b3\:30a2: \:30bf\:30fc\:30e0\:9577 \[Times] \:7a00\:5c11\:5ea6 *)
        Do[
          Module[{rarity = 1.0 + 10.0 / Max[Lookup[termPageCounts, t, 1], 1]},
            sc += StringLength[t] * rarity],
          {t, matchedTerms}];

        (* === \:5171\:8d77\:30dc\:30fc\:30ca\:30b9 (\:6700\:91cd\:8981) ===
           \:8907\:6570\:306e\:30af\:30a8\:30ea\:30bf\:30fc\:30e0\:304c\:540c\:4e00\:30da\:30fc\:30b8\:306b\:5171\:8d77 \[RightArrow] \:5927\:304d\:306a\:30dc\:30fc\:30ca\:30b9
           1\:30bf\:30fc\:30e0: \:30dc\:30fc\:30ca\:30b9\:306a\:3057 (\:30d9\:30fc\:30b9\:30b9\:30b3\:30a2\:306e\:307f)
           2\:30bf\:30fc\:30e0: \[Times]3 + \:8fd1\:63a5\:6027
           \:5168\:30bf\:30fc\:30e0: \[Times]5 + \:8fd1\:63a5\:6027 *)
        If[Length[matchedTerms] >= 2,
          Module[{firstPositions, minSpan, coocBonus},
            firstPositions = positions[#][[1, 1]] & /@ matchedTerms;
            minSpan = Max[firstPositions] - Min[firstPositions];
            (* \:8fd1\:63a5\:6027: \:8fd1\:3044\:307b\:3069\:9ad8\:3044 *)
            proxBonus = 100.0 / (1.0 + minSpan / 100.0) * Length[matchedTerms];
            (* \:5171\:8d77\:500d\:7387: \:5168\:30bf\:30fc\:30e0\:4e00\:81f4\:306a\:3089\:3055\:3089\:306b\:30dc\:30fc\:30ca\:30b9 *)
            coocBonus = If[Length[matchedTerms] === Length[nTerms],
              sc * 3.0,  (* \:5168\:30bf\:30fc\:30e0: \:30d9\:30fc\:30b9\:30b9\:30b3\:30a2\:306e3\:500d\:3092\:8ffd\:52a0 *)
              sc * 1.0]; (* \:90e8\:5206\:4e00\:81f4: \:30d9\:30fc\:30b9\:30b9\:30b3\:30a2\:306e1\:500d\:3092\:8ffd\:52a0 *)
            sc += coocBonus]];

        (* === \:898b\:51fa\:3057\:4e00\:81f4\:30dc\:30fc\:30ca\:30b9 ===
           \:30da\:30fc\:30b8\:5185\:306e\:898b\:51fa\:3057\:884c\:ff08\[FilledSquare], \[FilledDiamond], \:3010\:3011\:7b49\:3067\:59cb\:307e\:308b\:884c\:ff09\:306b
           \:30af\:30a8\:30ea\:30bf\:30fc\:30e0\:304c\:542b\:307e\:308c\:308b\:5834\:5408\:3001\:305d\:306e\:30da\:30fc\:30b8\:306f\:305d\:306e\:30c8\:30d4\:30c3\:30af\:306e
           \:30e1\:30a4\:30f3\:30da\:30fc\:30b8\:3067\:3042\:308b\:53ef\:80fd\:6027\:304c\:9ad8\:3044\:3002 *)
        Module[{headingLines, headBonus = 0},
          headingLines = Select[
            StringSplit[text, "\n"],
            StringMatchQ[StringTrim[#],
              RegularExpression["^[\[FilledSquare]\[FilledDiamond]\[FilledCircle]\[FilledRightTriangle]\[FilledDownTriangle]\[FivePointedStar]\:2606\:3010].+"]] &];
          Do[
            Module[{nLine = iNormalizeForMatch[hl]},
              Do[
                If[StringContainsQ[nLine, nt, IgnoreCase -> True],
                  headBonus += StringLength[nt] * 10],
                {nt, matchedTerms}]],
            {hl, headingLines}];
          sc += headBonus];

        {pg, sc + proxBonus}] &,
      pages]];

(* WL Import \:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af\:3067\:30da\:30fc\:30b8\:691c\:7d22 *)
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

(* \:30af\:30a8\:30ea\:304b\:3089\:5e74\:5ea6\:8868\:73fe\:3092\:9664\:53bb (\:30da\:30fc\:30b8\:30b9\:30b3\:30a2\:30ea\:30f3\:30b0\:7528)
   \:5e74\:5ea6\:306f\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:9078\:629e\:306b\:4f7f\:7528\:6e08\:307f\:306e\:305f\:3081\:3001\:30da\:30fc\:30b8\:691c\:7d22\:3067\:306f\:4e0d\:8981\:3002
   \:6b8b\:3059\:3068PDF\:5185\:30c6\:30ad\:30b9\:30c8\:3068\:30de\:30c3\:30c1\:305b\:305a\:30ce\:30a4\:30ba\:306b\:306a\:308b\:3002 *)
iStripYearFromQuery[query_String] := Module[{q},
  q = iNormalizeDigits[query];
  q = StringReplace[q, {
    RegularExpression["(\:4ee4\:548c|\:5e73\:6210|\:662d\:548c)\\d{1,2}(?:\:5e74\:5ea6?)?\:5165\:5b66\:751f?[\:306e\:306b]?"] -> "",
    RegularExpression["(?<![A-Za-z])(R|H|S)\\d{1,2}(?:\:5e74\:5ea6?)?[\:306e\:306b]?"] -> "",
    RegularExpression["20\\d{2}(?:\:5e74\:5ea6?)?[\:306e\:306b]?"] -> ""}];
  StringTrim[q]
];

(* \:30af\:30a8\:30ea\:306b\:30de\:30c3\:30c1\:3059\:308b\:30da\:30fc\:30b8\:756a\:53f7\:3092\:691c\:7d22 *)
(* ============================================================ *)
(* pdfFindPage: \:30b0\:30ed\:30fc\:30d0\:30eb\:6a2a\:65ad\:691c\:7d22\:30a8\:30f3\:30b8\:30f3 (\:5168\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:30fb\:5168TOC\:30fb\:5168\:30c1\:30e3\:30f3\:30af)     *)
(*                                                                *)
(* \:512a\:5148\:5ea6\:30b9\:30b3\:30a2:                                                   *)
(*   1. doc/yearInfo \[LongDash] \:5e74\:5ea6\:4e00\:81f4 (\:6307\:5b9a\:306a\:3057=\:4eca\:5e74\:5ea6)                   *)
(*   2. doc/title \[LongDash] \:30bf\:30a4\:30c8\:30eb\:306b\:30af\:30a8\:30ea\:30bf\:30fc\:30e0\:542b\:6709                      *)
(*   3. TOC \:30a8\:30f3\:30c8\:30ea \[LongDash] level\:9806 (\:6d45\:3044\:307b\:3069\:91cd\:8981)                       *)
(*   4. chunks \[LongDash] \:30c6\:30ad\:30b9\:30c8\:5185\:5bb9\:30de\:30c3\:30c1                                 *)
(* \:5358\:4e00\:30ef\:30fc\:30c9: TOC/doc\:30e1\:30bf\:30c7\:30fc\:30bf\:3067\:78ba\:5b9a                              *)
(* \:8907\:6570\:30ef\:30fc\:30c9: \:5404\:30ef\:30fc\:30c9\:72ec\:7acb\:30b9\:30b3\:30a2 \[RightArrow] \:30de\:30fc\:30b8                          *)
(* ============================================================ *)

PDFIndex`pdfFindPage[query_String, collection_String:"default"] :=
  Module[{queryYear, searchQuery, terms, allDocs, allChunks,
          candidates = {}, currentYear, nTerms},

    queryYear = iExtractYearFromQuery[query];
    currentYear = DateValue[Now, "Year"];
    If[!IntegerQ[queryYear], queryYear = currentYear];

    searchQuery = iStripYearFromQuery[query];
    If[StringLength[searchQuery] < 2, searchQuery = query];

    (* === \:30c7\:30d5\:30a9\:30eb\:30c8\:5b66\:79d1\:88dc\:5b8c === *)
    If[StringQ[$PDFIndexDefaultDepartment] &&
       StringLength[$PDFIndexDefaultDepartment] > 0,
      Module[{entities = iGetEntityIndex[collection], hasDept = False},
        Do[If[Lookup[e, "type", ""] === "department",
          If[StringContainsQ[searchQuery, Lookup[e, "canonical", ""],
               IgnoreCase -> True] ||
             AnyTrue[Lookup[e, "aliases", {}],
               StringContainsQ[searchQuery, #, IgnoreCase -> True] &],
            hasDept = True; Break[]]],
          {e, entities}];
        If[!hasDept,
          searchQuery = $PDFIndexDefaultDepartment <> " " <> searchQuery]]];

    (* === \:30a8\:30f3\:30c6\:30a3\:30c6\:30a3\:6b63\:898f\:5316 === *)
    Module[{rawTerms = iSplitQueryTerms[searchQuery], normalizedTerms},
      normalizedTerms = iNormalizeQueryWithEntities[rawTerms, collection];
      If[normalizedTerms =!= rawTerms,
        searchQuery = StringRiffle[normalizedTerms, " "]]];

    terms = iSplitQueryTerms[searchQuery];
    (* === \:691c\:7d22\:8f9e\:66f8\:30a8\:30a4\:30ea\:30a2\:30b9\:89e3\:6c7a === *)
    terms = iResolveAlias /@ terms;
    nTerms = iNormalizeForMatch /@ terms;
    If[Length[terms] === 0, terms = {searchQuery}; nTerms = {iNormalizeForMatch[searchQuery]}];

    allDocs = iLoadCollectionDocs[collection];
    allChunks = iLoadCollectionChunks[collection];

    Print["  \:691c\:7d22: \"" <> searchQuery <> "\" (\:5e74\:5ea6=" <> ToString[queryYear] <>
      ", " <> ToString[Length[terms]] <> "\:30bf\:30fc\:30e0, " <>
      ToString[Length[allDocs]] <> "\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8)"];

    (* === \:5358\:72ec\:30a8\:30f3\:30c6\:30a3\:30c6\:30a3 \[RightArrow] TOC\:76f4\:63a5\:8fd4\:5374 ===
       \:5358\:4e00\:30bf\:30fc\:30e0\:3067\:8cea\:554f\:5f62\:5f0f\:3067\:306a\:3044\:5834\:5408\:3001TOC\:306e\:5148\:982d\:30da\:30fc\:30b8\:3092\:76f4\:63a5\:8fd4\:3059\:3002
       \:300c\:6a5f\:68b0\:30b7\:30b9\:30c6\:30e0\:5de5\:5b66\:79d1\:300d\:300c\:56fd\:969b\:30bb\:30f3\:30bf\:30fc\:300d\:306a\:3069\:306e\:56fa\:6709\:540d\:8a5e\:691c\:7d22\:306b\:6709\:52b9\:3002 *)
    If[Length[terms] <= 2 &&
       !StringContainsQ[searchQuery, "\:ff1f" | "?" | "\:914d\:5f53" | "\:5358\:4f4d" | "\:5fc5\:4fee" | "\:79d1\:76ee"],
      Module[{allTocHits = {}, bestTocHit},
        Do[Module[{did2 = Lookup[ad2, "docId", ""],
                   sp2 = Lookup[ad2, "sourcePath", ""],
                   yi2 = Lookup[ad2, "yearInfo", <||>],
                   dTitle2 = Lookup[ad2, "title", ""],
                   dPath2, dToc2, dYear2, docHasTocHit = False,
                   dYearScore},
          dPath2 = iResolveSourcePath[sp2];
          dYear2 = Lookup[yi2, "westernYear", 0];
          dYearScore = Which[
            dYear2 === queryYear, 10000,
            Abs[dYear2 - queryYear] === 1, 5000,
            Abs[dYear2 - queryYear] === 2, 2000,
            True, Max[0, 1000 - Abs[dYear2 - queryYear] * 200]];
          If[StringQ[dPath2] && FileExistsQ[dPath2],
            dToc2 = iExtractTOC[dPath2];
            If[ListQ[dToc2] && Length[dToc2] > 0,
              Do[Module[{title = Lookup[e, "title", ""],
                         page = Lookup[e, "page", 0],
                         level = Lookup[e, "level", 99]},
                If[IntegerQ[page] && page > 0 && StringQ[title] &&
                   StringContainsQ[iNormalizeForMatch[title],
                     nTerms[[1]], IgnoreCase -> True],
                  docHasTocHit = True;
                  AppendTo[allTocHits,
                    <|"page" -> page, "title" -> title,
                      "docPath" -> dPath2,
                      "docTitle" -> dTitle2,
                      "year" -> dYear2, "level" -> level,
                      "yearScore" -> dYearScore|>]]],
                {e, dToc2}]];
            (* \:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:30bf\:30a4\:30c8\:30eb\:81ea\:4f53\:306b\:30de\:30c3\:30c1 + TOC\:30d2\:30c3\:30c8\:306a\:3057 \[RightArrow] page 1 \:3092\:5019\:88dc\:8ffd\:52a0
               (\:5c0f\:3055\:3044PDF \:3067\:30d6\:30c3\:30af\:30de\:30fc\:30af\:304c\:7121\:3044\:5834\:5408\:306e\:6551\:6e08) *)
            If[!docHasTocHit &&
               StringContainsQ[iNormalizeForMatch[dTitle2],
                 nTerms[[1]], IgnoreCase -> True],
              AppendTo[allTocHits,
                <|"page" -> 1, "title" -> dTitle2,
                  "docPath" -> dPath2,
                  "docTitle" -> dTitle2,
                  "year" -> dYear2, "level" -> 0,
                  "yearScore" -> dYearScore|>]]]],
          {ad2, allDocs}];
        If[Length[allTocHits] > 0,
          allTocHits = SortBy[allTocHits,
            {-#["yearScore"], #["level"], #["page"]} &];
          bestTocHit = First[allTocHits];
          $pdfIndexAsyncContext["resolvedDocPath"] = bestTocHit["docPath"];
          $pdfIndexAsyncContext["resolvedCollection"] = collection;
          $pdfIndexAsyncContext["yearNote"] = ToString[bestTocHit["year"]] <> "\:5e74\:5ea6";
          iEnsurePageLabels[bestTocHit["docPath"]];
          Print["  TOC\:76f4\:63a5\:53c2\:7167: \"" <> searchQuery <>
            "\" \[RightArrow] " <> bestTocHit["docTitle"] <>
            " p." <> ToString[bestTocHit["page"]] <>
            " (" <> ToString[Length[allTocHits]] <> "\:4ef6\:30de\:30c3\:30c1)"];
          Return[bestTocHit["page"]]]]];

    (* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
       Phase 1: \:5168\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:306e\:30e1\:30bf\:30c7\:30fc\:30bf + TOC \:3092\:6a2a\:65ad\:30b9\:30b3\:30a2\:30ea\:30f3\:30b0
       \:5404 (docId, page) \:30da\:30a2\:306b\:5bfe\:3057\:3066\:512a\:5148\:5ea6\:30b9\:30b3\:30a2\:3092\:8a08\:7b97\:3002
       \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)
    Do[Module[{did = Lookup[ad, "docId", ""],
               sp  = Lookup[ad, "sourcePath", ""],
               yi  = Lookup[ad, "yearInfo", <||>],
               dTitle = Lookup[ad, "title", ""],
               dYear, dPath, dToc,
               docYearScore = 0, docTitleScore = 0,
               tocContextPages = {}},
      dYear = Lookup[yi, "westernYear", 0];
      dPath = iResolveSourcePath[sp];

      (* --- Priority 1: \:5e74\:5ea6\:30b9\:30b3\:30a2 --- *)
      docYearScore = Which[
        dYear === queryYear, 100000,
        Abs[dYear - queryYear] === 1, 50000,
        Abs[dYear - queryYear] === 2, 20000,
        dYear >= currentYear, 30000,
        True, Max[0, 10000 - Abs[dYear - queryYear] * 2000]];

      (* --- Priority 2: \:30bf\:30a4\:30c8\:30eb\:30b9\:30b3\:30a2 --- *)
      Do[If[StringContainsQ[iNormalizeForMatch[dTitle],
             nTerms[[ti]], IgnoreCase -> True],
        docTitleScore += 5000],
        {ti, Length[nTerms]}];

      (* --- Priority 3: TOC \:30a8\:30f3\:30c8\:30ea\:30b9\:30b3\:30a2 --- *)
      If[StringQ[dPath] && FileExistsQ[dPath],
        dToc = iExtractTOC[dPath];
        If[ListQ[dToc] && Length[dToc] > 0,
          Do[Module[{title = Lookup[e, "title", ""],
                     page = Lookup[e, "page", 0],
                     level = Lookup[e, "level", 99],
                     tocTermScore = 0, levelBonus},
            If[IntegerQ[page] && page > 0 && StringQ[title],
              levelBonus = Max[1, 10 - level] * 2000;
              Module[{tocMatchCount = 0, nTitle = iNormalizeForMatch[title]},
              Do[If[StringContainsQ[nTitle, nTerms[[ti]], IgnoreCase -> True],
                tocTermScore += levelBonus; tocMatchCount++],
                {ti, Length[nTerms]}];
              (* \:30b5\:30d6\:30ef\:30fc\:30c9\:5c55\:958b\:30dc\:30fc\:30ca\:30b9: \:672a\:30de\:30c3\:30c1\:30bf\:30fc\:30e0\:3092\:8f9e\:66f8\:3067\:5c55\:958b\:3057\:90e8\:5206\:30de\:30c3\:30c1 *)
              Do[If[!StringContainsQ[nTitle, nTerms[[ti]], IgnoreCase -> True],
                Module[{expanded = iExpandTerm[terms[[ti]]], subMatches = 0},
                  If[Length[expanded] > 1,
                    Do[If[StringContainsQ[nTitle,
                          iNormalizeForMatch[sub], IgnoreCase -> True],
                      subMatches++], {sub, expanded}];
                    If[subMatches > 0,
                      tocTermScore += levelBonus * 0.3 *
                        (subMatches / N[Length[expanded]]);
                      tocMatchCount += 0.5]]]],
                {ti, Length[nTerms]}];
              (* \:8907\:6570\:30bf\:30fc\:30e0\:5171\:8d77\:30dc\:30fc\:30ca\:30b9: \:5168\:30bf\:30fc\:30e0\:4e00\:81f4\:3067\:5927\:5e45\:30d6\:30fc\:30b9\:30c8 *)
              If[Length[nTerms] > 1 && tocMatchCount >= 2,
                tocTermScore = tocTermScore *
                  (1.0 + (tocMatchCount / N[Length[nTerms]])^2 * 3.0)]];
              If[tocTermScore > 0,
                AppendTo[candidates,
                  <|"docId" -> did, "docPath" -> dPath,
                    "page" -> page, "docYear" -> dYear,
                    "docTitle" -> dTitle,
                    "score" -> tocTermScore + docYearScore + docTitleScore,
                    "source" -> "toc",
                    "matchInfo" -> StringTake[title, UpTo[50]]|>];
                (* TOC\:30b3\:30f3\:30c6\:30ad\:30b9\:30c8\:7bc4\:56f2\:3092\:8a18\:9332: \:6b21\:306eTOC\:30a8\:30f3\:30c8\:30ea\:307e\:3067\:306e\:30da\:30fc\:30b8\:3092\:30d6\:30fc\:30b9\:30c8\:5bfe\:8c61 *)
                Do[AppendTo[tocContextPages, page + dp],
                  {dp, 0, 10}]]]],
            {e, dToc}]]];

      (* --- Priority 4: \:30c1\:30e3\:30f3\:30af\:30b9\:30b3\:30a2 --- *)
      Module[{docChunks = Select[allChunks,
                Lookup[#, "docId", ""] === did &]},
        Do[Module[{txt = iNormalizeForMatch[
                     Lookup[ch, "text", ""] <> " " <>
                     Lookup[ch, "summary", ""] <> " " <>
                     Lookup[ch, "tags", ""]],
                   pg = Lookup[ch, "pageNum", 0],
                   chunkTermScore = 0},
          Module[{chunkMatchCount = 0},
          Do[If[StringContainsQ[txt, nTerms[[ti]], IgnoreCase -> True],
            chunkTermScore += 500; chunkMatchCount++],
            {ti, Length[nTerms]}];
          (* \:8907\:6570\:30bf\:30fc\:30e0\:5171\:8d77\:30dc\:30fc\:30ca\:30b9 *)
          If[Length[nTerms] > 1 && chunkMatchCount >= 2,
            chunkTermScore = chunkTermScore *
              (1.0 + (chunkMatchCount / N[Length[nTerms]])^2 * 3.0)]];
          (* TOC\:30b3\:30f3\:30c6\:30ad\:30b9\:30c8\:30d6\:30fc\:30b9\:30c8: \:30c1\:30e3\:30f3\:30af\:304cTOC\:30de\:30c3\:30c1\:30bb\:30af\:30b7\:30e7\:30f3\:5185\:306a\:3089\[Times]3
             \:4f8b: TOC\:300c\:60c5\:5831\:5de5\:5b66\:79d1 p.128\:300d\:306e\:8fd1\:508d\:306b\:3042\:308b\:300c\:96e2\:6563\:6570\:5b66\:300d\:30c1\:30e3\:30f3\:30af\:3092\:30d6\:30fc\:30b9\:30c8 *)
          If[MemberQ[tocContextPages, pg],
            chunkTermScore = chunkTermScore * 3.0];
          If[chunkTermScore > 0 && IntegerQ[pg] && pg > 0,
            AppendTo[candidates,
              <|"docId" -> did, "docPath" -> dPath,
                "page" -> pg, "docYear" -> dYear,
                "docTitle" -> dTitle,
                "score" -> chunkTermScore + docYearScore + docTitleScore,
                "source" -> If[MemberQ[tocContextPages, pg], "toc+chunk", "chunk"],
                "matchInfo" -> If[MemberQ[tocContextPages, pg],
                  "toc\:7bc4\:56f2\:5185 p." <> ToString[pg],
                  "chunk p." <> ToString[pg]]|>]]],
          {ch, docChunks}]]],
      {ad, allDocs}];

    If[Length[candidates] === 0,
      Print["  \[RightArrow] \:5168\:30c9\:30ad\:30e5\:30e1\:30f3\:30c8\:3067\:30de\:30c3\:30c1\:306a\:3057"];
      Return[$Failed]];

    (* \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550
       Phase 2: \:540c\:4e00\:30da\:30fc\:30b8\:306e\:5019\:88dc\:3092\:30de\:30fc\:30b8\:3057\:3001\:6700\:7d42\:30e9\:30f3\:30ad\:30f3\:30b0
       \:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550\:2550 *)
    Module[{grouped, ranked, best, bestDoc2, bestPath},
      (* (docId, page) \:30da\:30a2\:3067\:30b0\:30eb\:30fc\:30d7\:5316\:3057\:3001\:6700\:5927\:30b9\:30b3\:30a2\:3092\:63a1\:7528 *)
      grouped = GroupBy[candidates,
        {Lookup[#, "docId", ""], Lookup[#, "page", 0]} &];
      ranked = KeyValueMap[
        Function[{key, hits},
          Module[{maxScore = Max[Lookup[#, "score", 0] & /@ hits],
                  bestHit = First[SortBy[hits, -Lookup[#, "score", 0] &]]},
            <|"docId" -> key[[1]], "page" -> key[[2]],
              "score" -> maxScore,
              "docPath" -> bestHit["docPath"],
              "docYear" -> bestHit["docYear"],
              "docTitle" -> bestHit["docTitle"],
              "source" -> bestHit["source"],
              "matchInfo" -> bestHit["matchInfo"]|>]],
        grouped];
      (* \:30bd\:30fc\:30c8: \:30b9\:30b3\:30a2\:964d\:9806 \[RightArrow] TOC\:512a\:5148 \[RightArrow] \:30da\:30fc\:30b8\:756a\:53f7\:6607\:9806 (\:30bf\:30a4\:30d6\:30ec\:30fc\:30af) *)
      ranked = SortBy[ranked,
        {-Lookup[#, "score", 0],
         If[StringContainsQ[Lookup[#, "source", ""], "toc"], 0, 1],
         Lookup[#, "page", 999]} &];

      (* \:30ed\:30b0\:51fa\:529b *)
      Print["  \:5019\:88dc: " <> ToString[Length[ranked]] <> "\:4ef6"];
      Do[Module[{r = ranked[[ri]]},
        Print["    #" <> ToString[ri] <> " " <>
          r["docTitle"] <> " p." <> ToString[r["page"]] <>
          " (score=" <> ToString[r["score"]] <>
          ", " <> r["source"] <> ": " <> r["matchInfo"] <> ")"]],
        {ri, Min[5, Length[ranked]]}];

      best = First[ranked];
      bestPath = best["docPath"];

      (* \:89e3\:6c7a\:7d50\:679c\:3092\:975e\:540c\:671f\:30b3\:30f3\:30c6\:30ad\:30b9\:30c8\:306b\:8a18\:9332 *)
      $pdfIndexAsyncContext["resolvedDocPath"] = bestPath;
      $pdfIndexAsyncContext["resolvedCollection"] = collection;
      $pdfIndexAsyncContext["yearNote"] =
        If[best["docYear"] === queryYear,
          ToString[queryYear] <> "\:5e74\:5ea6",
          ToString[best["docYear"]] <> "\:5e74\:5ea6 (\:8981\:6c42: " <>
            ToString[queryYear] <> ")"];

      (* \:30da\:30fc\:30b8\:30e9\:30d9\:30eb\:3092\:30ed\:30fc\:30c9 *)
      iEnsurePageLabels[bestPath];

      Print["  \[RightArrow] " <> best["docTitle"] <>
        " p." <> ToString[best["page"]] <>
        " (score=" <> ToString[best["score"]] <> ")"];
      best["page"]]
  ];

(* PDF\:30da\:30fc\:30b8\:3092\:753b\:50cf\:3068\:3057\:3066\:8868\:793a *)
PDFIndex`pdfShowPage[pageNum_Integer, collection_String:"default",
    mode_String:"display"] :=
  Module[{pdfPath, img, imgFile},
    pdfPath = iGetDocSourcePath[collection];
    If[pdfPath === None || !FileExistsQ[pdfPath],
      Print["\[WarningSign] PDF\:30d5\:30a1\:30a4\:30eb\:304c\:898b\:3064\:304b\:308a\:307e\:305b\:3093: " <> ToString[pdfPath]];
      Return[$Failed]];
    (* \:65b9\:6cd51: Python/PyMuPDF \:3067\:30ec\:30f3\:30c0\:30ea\:30f3\:30b0 *)
    img = iRenderPagePyMuPDF[pdfPath, pageNum];
    (* \:65b9\:6cd52: Mathematica Import \:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af *)
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
      (* \:30ce\:30fc\:30c8\:30d6\:30c3\:30af\:306b\:8868\:793a *)
      CellPrint[Cell[BoxData[ToBoxes[
        Column[{
          Style["PDF \:30da\:30fc\:30b8 " <> ToString[pageNum], Bold, 12],
          Show[img, ImageSize -> 600]
        }]]],
        "Output"]];
      img]
  ];

(* Python/PyMuPDF \:3067PDF\:30da\:30fc\:30b8\:3092\:30ec\:30f3\:30c0\:30ea\:30f3\:30b0 *)
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

(* Mathematica Import \:3067PDF\:30da\:30fc\:30b8\:3092\:30ec\:30f3\:30c0\:30ea\:30f3\:30b0 *)
iRenderPageWL[pdfPath_String, pageNum_Integer] :=
  Module[{img},
    (* \:65b9\:6cd51: PageGraphics *)
    img = Quiet @ Check[
      Import[pdfPath, {"PageGraphics", pageNum}],
      $Failed];
    If[img =!= $Failed && Head[img] === Graphics,
      Return[Rasterize[img, ImageResolution -> 150]]];
    (* \:65b9\:6cd52: ImageList *)
    img = Quiet @ Check[
      Import[pdfPath, {"ImageList", pageNum}],
      $Failed];
    If[img =!= $Failed && Head[img] === Image, Return[img]];
    $Failed
  ];

(* \:691c\:7d22 + \:30da\:30fc\:30b8\:8868\:793a\:306e\:30ef\:30f3\:30b7\:30e7\:30c3\:30c8\:95a2\:6570
   \:8868\:304c\:30da\:30fc\:30b8\:3092\:307e\:305f\:3050\:5834\:5408\:3001\:524d\:30da\:30fc\:30b8(\:8868\:30d8\:30c3\:30c0)\:3082\:81ea\:52d5\:8868\:793a *)
PDFIndex`pdfShowPage[query_String, collection_String:"default"] :=
  Module[{pageNum, pairPages},
    pageNum = PDFIndex`pdfFindPage[query, collection];
    If[!IntegerQ[pageNum], Return[$Failed]];
    (* \:30da\:30a2\:30da\:30fc\:30b8\:60c5\:5831\:304c\:3042\:308c\:3070\:524d\:30da\:30fc\:30b8\:3082\:8868\:793a *)
    pairPages = Lookup[$pdfIndexAsyncContext, "lastPairPages", None];
    If[ListQ[pairPages] && Length[pairPages] === 2 && pairPages[[2]] === pageNum,
      Print["  \:8868\:304c\:30da\:30fc\:30b8\:3092\:307e\:305f\:3050\:305f\:3081 p." <>
        ToString[pairPages[[1]]] <> "-" <> ToString[pairPages[[2]]] <> " \:3092\:8868\:793a"];
      PDFIndex`pdfShowPage[pairPages[[1]], collection];
      PDFIndex`pdfShowPage[pairPages[[2]], collection],
      PDFIndex`pdfShowPage[pageNum, collection]]
  ] /; StringQ[query];

(* ============================================================ *)
(* \:30a4\:30f3\:30bf\:30e9\:30af\:30c6\:30a3\:30d6\:691c\:7d22UI                                        *)
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
        (* KWIC \:30d7\:30ec\:30d3\:30e5\:30fc: \:30ad\:30fc\:30ef\:30fc\:30c9\:5468\:8fba\:3092\:8868\:793a *)
        preview = If[StringQ[c["summary"]] && c["summary"] =!= "",
          c["summary"],
          iKWIC[fullText, queryTerms, 80]];
        {
          (* \:756a\:53f7 *)
          Style[ToString[rank], Gray, 11],
          (* \:30c1\:30e3\:30f3\:30af\:756a\:53f7 *)
          Style["#" <> ToString[gIdx] <>
            If[pg =!= "?" && pg =!= 1, " p." <> ToString[pg], ""], 10],
          (* \:30b9\:30b3\:30a2 *)
          Style[ToString[NumberForm[sc, {4, 3}]], 10],
          (* KWIC \:30d7\:30ec\:30d3\:30e5\:30fc: \:30c4\:30fc\:30eb\:30c1\:30c3\:30d7\:3067\:5168\:6587\:8868\:793a *)
          Tooltip[
            Style[preview, 11],
            StringTake[fullText, UpTo[500]]],
          (* \:30dc\:30bf\:30f3\:7fa4 *)
          Row[{
            (* \:5168\:6587\:30dc\:30bf\:30f3: \:30c1\:30e3\:30f3\:30af\:5168\:6587\:3092\:30ce\:30fc\:30c8\:30d6\:30c3\:30af\:306b\:51fa\:529b *)
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
            (* \:524d\:5f8c\:30dc\:30bf\:30f3: \:524d\:5f8c\:30c1\:30e3\:30f3\:30af\:3082\:542b\:3081\:305f\:30b3\:30f3\:30c6\:30ad\:30b9\:30c8\:8868\:793a *)
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
            (* \:8cea\:554f\:30dc\:30bf\:30f3: \:3053\:306e\:30c1\:30e3\:30f3\:30af\:3092\:5143\:306b ClaudeQuery \:3067\:8cea\:554f
               Fallback -> False (\:30c7\:30d5\:30a9\:30eb\:30c8) \:3067\:8ab2\:91d1API\:4e0d\:4f7f\:7528 *)
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
            (* \:30da\:30fc\:30b8\:30dc\:30bf\:30f3: PDF\:306e\:5168\:30da\:30fc\:30b8\:3092\:76f4\:63a5\:691c\:7d22\:3057\:3066\:8a72\:5f53\:30da\:30fc\:30b8\:3092\:753b\:50cf\:8868\:793a *)
            Button[Style["\:30da\:30fc\:30b8", 10],
              Module[{foundPage, pdfPath, pairPages},
                pdfPath = iGetDocSourcePath[collection];
                Print[Style["  PDF\:30da\:30fc\:30b8\:3092\:691c\:7d22\:4e2d...", Italic, Gray]];
                foundPage = iSearchPDFPagesWithCollection[pdfPath, query, collection];
                If[IntegerQ[foundPage],
                  Print["  \[RightArrow] \:30da\:30fc\:30b8 " <> ToString[foundPage]];
                  (* \:30da\:30a2\:30da\:30fc\:30b8(\:8868\:30d8\:30c3\:30c0+\:672c\:4f53)\:304c\:3042\:308c\:3070\:4e21\:65b9\:8868\:793a *)
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

    (* Grid \:3067\:6574\:5f62\:8868\:793a *)
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

    (* \:691c\:7d22\:5b9f\:884c: \:751f\:30c7\:30fc\:30bf\:7248\:3092\:4f7f\:7528 *)
    data = iPdfSearchRaw[query, maxItems * 2, collection, None, None];
    If[!ListQ[data] || Length[data] === 0,
      Return[<|
        "public" -> <|"prompt" -> "", "count" -> 0|>,
        "private" -> <|"prompt" -> "", "count" -> 0|>|>]];

    data = Take[data, UpTo[maxItems]];

    (* === \:96a3\:63a5\:30c1\:30e3\:30f3\:30af\:81ea\:52d5\:5c55\:958b ===
       \:8868\:3084\:4e00\:89a7\:304c\:8907\:6570\:30da\:30fc\:30b8\:306b\:307e\:305f\:304c\:308b\:5834\:5408\:3001\:30d2\:30c3\:30c8\:3057\:305f\:30c1\:30e3\:30f3\:30af\:306e
       \:524d\:5f8c\:30c1\:30e3\:30f3\:30af\:306b\:3082\:91cd\:8981\:306a\:60c5\:5831\:304c\:542b\:307e\:308c\:3066\:3044\:308b\:53ef\:80fd\:6027\:304c\:3042\:308b\:3002
       \:30d2\:30c3\:30c8\:30c1\:30e3\:30f3\:30af\:306e \[PlusMinus]1 \:3092\:81ea\:52d5\:7684\:306b\:30b3\:30f3\:30c6\:30ad\:30b9\:30c8\:3068\:3057\:3066\:8ffd\:52a0\:3059\:308b\:3002 *)
    expanded = iExpandWithAdjacentChunks[data, collection];

    (* \:516c\:958b/\:79d8\:5bc6\:306b\:5206\:5272 *)
    pubChunks = Select[expanded, Lookup[#, "docPrivacy", 0] <= privacyThreshold &];
    privChunks = Select[expanded, Lookup[#, "docPrivacy", 0] > privacyThreshold &];

    (* \:30d7\:30ed\:30f3\:30d7\:30c8\:69cb\:7bc9 *)
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

(* \:96a3\:63a5\:30c1\:30e3\:30f3\:30af\:81ea\:52d5\:5c55\:958b: \:30d2\:30c3\:30c8\:30c1\:30e3\:30f3\:30af\:306e\:524d\:5f8c \[PlusMinus]1 \:30c1\:30e3\:30f3\:30af\:3092\:30b3\:30f3\:30c6\:30ad\:30b9\:30c8\:3068\:3057\:3066\:8ffd\:52a0\:3002
   \:8868\:3084\:4e00\:89a7\:304c\:8907\:6570\:30da\:30fc\:30b8\:306b\:307e\:305f\:304c\:308b\:30b1\:30fc\:30b9\:3067\:3001\:691c\:7d22\:306b\:30d2\:30c3\:30c8\:3057\:306a\:304b\:3063\:305f
   \:7d9a\:304d\:30da\:30fc\:30b8\:306e\:60c5\:5831\:3082 LLM \:306b\:63d0\:4f9b\:3059\:308b\:3002
   \:91cd\:8907\:6392\:9664\:6e08\:307f\:30fb\:30c1\:30e3\:30f3\:30af\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:9806\:306b\:30bd\:30fc\:30c8\:3057\:3066\:8fd4\:3059\:3002 *)
iExpandWithAdjacentChunks[hitChunks_List, collection_String] := Module[
  {idx, hitIndices, adjacentIndices, totalChunks, result},

  (* \:30a8\:30e9\:30fc\:6642\:306f\:30d2\:30c3\:30c8\:30c1\:30e3\:30f3\:30af\:3092\:305d\:306e\:307e\:307e\:8fd4\:3059 *)
  idx = Quiet @ Check[PDFIndex`pdfLoadIndex[collection], None];
  If[!AssociationQ[idx] || idx["count"] === 0, Return[hitChunks]];
  totalChunks = Length[idx["chunks"]];
  If[totalChunks === 0, Return[hitChunks]];

  (* \:30d2\:30c3\:30c8\:30c1\:30e3\:30f3\:30af\:306e\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:3092\:53ce\:96c6 *)
  hitIndices = DeleteDuplicates[
    Select[
      Lookup[#, "chunkIndex", None] & /@ hitChunks,
      IntegerQ]];
  If[Length[hitIndices] === 0, Return[hitChunks]];

  (* \:524d\:5f8c \[PlusMinus]1 \:306e\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:3092\:8a08\:7b97 *)
  adjacentIndices = DeleteDuplicates[
    Flatten[{# - 1, # + 1} & /@ hitIndices]];
  adjacentIndices = Select[adjacentIndices,
    IntegerQ[#] && 1 <= # <= totalChunks && !MemberQ[hitIndices, #] &];

  If[Length[adjacentIndices] === 0, Return[hitChunks]];

  Print["  \:96a3\:63a5\:30c1\:30e3\:30f3\:30af\:5c55\:958b: +" <> ToString[Length[adjacentIndices]] <> "\:4ef6"];

  (* \:96a3\:63a5\:30c1\:30e3\:30f3\:30af\:3092\:30ed\:30fc\:30c9\:3057\:3066\:30e1\:30bf\:30c7\:30fc\:30bf\:4ed8\:52a0 *)
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

  (* \:30c1\:30e3\:30f3\:30af\:30a4\:30f3\:30c7\:30c3\:30af\:30b9\:9806\:306b\:30bd\:30fc\:30c8 *)
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
    (* \:8868\:30c1\:30e3\:30f3\:30af: \:30ad\:30e3\:30d7\:30b7\:30e7\:30f3 + \:5168\:8868\:30c7\:30fc\:30bf\:3092\:5e38\:306b\:542b\:3081\:308b *)
    If[isTable,
      line = line <>
        "  TableCaption: " <>
        If[StringQ[Lookup[chunk, "tableCaption", ""]], chunk["tableCaption"], ""] <>
        "\n";
      If[StringQ[chunk["text"]],
        line = line <> "  TableData:\n" <>
          StringTake[chunk["text"], UpTo[4000]] <> "\n"];
      Return[line <> "\n"]];
    (* \:56f3\:30c1\:30e3\:30f3\:30af: \:30ad\:30e3\:30d7\:30b7\:30e7\:30f3 + \:8aac\:660e\:3092\:5e38\:306b\:542b\:3081\:308b *)
    If[isFigure,
      line = line <>
        "  FigureCaption: " <>
        If[StringQ[Lookup[chunk, "figureCaption", ""]], chunk["figureCaption"], ""] <>
        "\n";
      If[StringQ[chunk["text"]],
        line = line <> "  Description: " <> chunk["text"] <> "\n"];
      Return[line <> "\n"]];
    (* \:901a\:5e38\:30c1\:30e3\:30f3\:30af *)
    line = line <>
      "  Summary: " <> If[StringQ[chunk["summary"]], chunk["summary"], ""] <> "\n" <>
      "  Entities: " <> If[StringQ[chunk["entities"]], chunk["entities"], ""] <> "\n";
    (* \:96a3\:63a5\:30b3\:30f3\:30c6\:30ad\:30b9\:30c8\:30c1\:30e3\:30f3\:30af\:306f\:5e38\:306b\:30c6\:30ad\:30b9\:30c8\:3092\:542b\:3081\:308b *)
    If[(TrueQ[includeFullText] || isContext) && StringQ[chunk["text"]],
      line = line <> "  Text: " <> StringTake[chunk["text"], UpTo[1500]] <> "\n"];
    line <> "\n"
  ];

(* ============================================================ *)
(* \:9ad8\:30ec\:30d9\:30eb\:554f\:3044\:5408\:308f\:305b: pdfAskLLM                                  *)
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

    (* \:691c\:7d22 *)
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

    (* \:516c\:958b\:5206: $ClaudeDocModel (Sonnet) \:3067\:9ad8\:901f\:56de\:7b54 *)
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

    (* \:79d8\:5bc6\:5206: \:30ed\:30fc\:30ab\:30eb LLM *)
    If[privCount > 0,
      Print["  \:30ed\:30fc\:30ab\:30eb LLM ($ClaudePrivateModel) \:306b\:554f\:3044\:5408\:308f\:305b\:4e2d..."];
      privResult = Quiet @ Check[
        iQueryLocalLLM[
          "\:4ee5\:4e0b\:306ePDF\:6587\:66f8\:306e\:62bd\:51fa\:5185\:5bb9\:304b\:3089\:3001\:300c" <> question <>
          "\:300d\:306b\:95a2\:9023\:3059\:308b\:60c5\:5831\:3092\:65e5\:672c\:8a9e\:3067\:307e\:3068\:3081\:3066\:304f\:3060\:3055\:3044\:3002\n\n" <> privPrompt],
        ""]];

    (* \:7d50\:679c\:7d71\:5408 *)
    finalResult = "";
    If[StringQ[pubResult] && pubResult =!= "",
      finalResult = finalResult <> pubResult];
    If[StringQ[privResult] && privResult =!= "",
      finalResult = finalResult <>
        If[finalResult =!= "", "\n\n---\n\n", ""] <>
        "\:3010\:79d8\:5bc6\:60c5\:5831\:3011\n" <> privResult];

    (* \:30ce\:30fc\:30c8\:30d6\:30c3\:30af\:3078\:306e\:51fa\:529b: NBAccess \:7d4c\:7531 *)
    If[StringLength[finalResult] > 0,
      If[Length[Names["NBAccess`NBWriteCell"]] > 0,
        (* NBAccess \:5229\:7528\:53ef\:80fd: claudecode.wl \:306e\:30eb\:30fc\:30eb\:306b\:6e96\:62e0 *)
        nb = Quiet @ Check[EvaluationNotebook[], InputNotebook[]];
        If[MatchQ[nb, _NotebookObject],
          NBAccess`NBWriteCell[nb, finalResult, "Text"]],
        (* NBAccess \:306a\:3057: \:76f4\:63a5\:66f8\:304d\:8fbc\:307f *)
        nb = Quiet @ Check[EvaluationNotebook[], InputNotebook[]];
        If[MatchQ[nb, _NotebookObject],
          Quiet[SelectionMove[nb, After, Cell]];
          NotebookWrite[nb, Cell[finalResult, "Text"], After]]]];

    finalResult
  ];

(* ============================================================ *)
(* \:518d\:30a4\:30f3\:30c7\:30af\:30b7\:30f3\:30b0                                              *)
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
        path = iResolveSourcePath[doc["sourcePath"]];
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

(* \:4fdd\:5b58\:6e08\:307f\:30c1\:30e3\:30f3\:30af\:306e\:30c6\:30ad\:30b9\:30c8\:304b\:3089 embedding \:3060\:3051\:518d\:751f\:6210 (\:8efd\:91cf)\:3002
   \:7d22\:5f15\:6642\:3068\:540c\:3058\:5408\:6210\:30c6\:30ad\:30b9\:30c8 (summary+entities+tags+text\:5148\:982d500\:5b57, iDoubleEscape) \:3092
   embed \:3057\:76f4\:3057\:3001"embedding" \:30d5\:30a3\:30fc\:30eb\:30c9\:306e\:307f\:66f4\:65b0\:3057\:3066 Put \:3057\:76f4\:3059\:3002 *)
PDFIndex`pdfReembed[collection_String:"default"] :=
  Module[{dirs, files, totalUpdated = 0, totalChunks = 0, fileCount = 0},
    dirs = {iCollectionDir[collection, "public"], iCollectionDir[collection, "private"]};
    files = Flatten[FileNames["chunks_*.wl", #] & /@ Select[dirs, DirectoryQ]];
    If[files === {},
      Print["chunks \:30d5\:30a1\:30a4\:30eb\:304c\:898b\:3064\:304b\:308a\:307e\:305b\:3093: " <> collection]; Return[<|"Status" -> "NoChunks"|>]];
    Print["[pdfReembed] " <> ToString[Length[files]] <> " \:500b\:306e chunks \:30d5\:30a1\:30a4\:30eb\:3092\:518d embedding \:3057\:307e\:3059"];
    Do[
      Module[{chunks, embTexts, embeddings, updated},
        chunks = Quiet @ Check[Get[file], $Failed];
        If[! ListQ[chunks] || chunks === {}, Continue[]];
        totalChunks += Length[chunks];
        embTexts = (iDoubleEscape[
          Lookup[#, "summary", ""] <> " " <> Lookup[#, "entities", ""] <> " " <>
          Lookup[#, "tags", ""] <> " " <> StringTake[Lookup[#, "text", ""], UpTo[$embeddingTextWindow]]] &) /@ chunks;
        embeddings = Quiet @ Check[iCreateEmbeddings[embTexts], {}];
        If[! (ListQ[embeddings] && Length[embeddings] === Length[chunks]),
          Print["  ! \:5931\:6557 (embedding \:6570\:4e0d\:4e00\:81f4): " <> FileNameTake[file]]; Continue[]];
        updated = MapThread[
          Function[{c, e},
            If[ListQ[e] && Length[e] > 100, Append[c, "embedding" -> e], c]],
          {chunks, embeddings}];
        Put[updated, file];
        fileCount++;
        totalUpdated += Count[embeddings, _?(ListQ[#] && Length[#] > 100 &)];
        Print["  \[Checkmark] " <> FileNameTake[file] <> " (" <> ToString[Length[chunks]] <> " chunks)"]],
      {file, files}];
    $pdfIndexCache = KeyDrop[$pdfIndexCache, collection];
    Print["[pdfReembed] \:5b8c\:4e86: " <> ToString[totalUpdated] <> "/" <> ToString[totalChunks] <> " chunks \:66f4\:65b0"];
    <|"Status" -> "OK", "Files" -> fileCount, "ChunksTotal" -> totalChunks, "Updated" -> totalUpdated|>
  ];

(* ============================================================ *)
(* \:30d7\:30ea\:30d5\:30e9\:30a4\:30c8\:30c1\:30a7\:30c3\:30af                                          *)
(* ============================================================ *)

PDFIndex`pdfPreflightCheck[] := Module[{pdfOK = False, llmOK = False, embOK = False},
  Print["\:30d7\:30ea\:30d5\:30e9\:30a4\:30c8\:30c1\:30a7\:30c3\:30af..."];
  (* PDF \:62bd\:51fa\:30c6\:30b9\:30c8 *)
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

  (* LLM \:30c6\:30b9\:30c8 *)
  Module[{llmResult},
    llmResult = Quiet @ Check[iQueryLocalLLM["\:300c\:30c6\:30b9\:30c8\:300d\:3068\:3060\:3051\:51fa\:529b\:305b\:3088\:3002"], $Failed];
    If[StringQ[llmResult] && StringLength[llmResult] > 0,
      Print["  \:2714 LLM (iQueryLocalLLM): OK"];
      llmOK = True,
      Print["  \:2718 LLM (iQueryLocalLLM): \:5fdc\:7b54\:306a\:3057\:307e\:305f\:306f\:30a8\:30e9\:30fc"]]];

  (* Embedding \:30c6\:30b9\:30c8 *)
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
(* \:30b9\:30c6\:30fc\:30bf\:30b9\:8868\:793a                                                *)
(* ============================================================ *)

PDFIndex`pdfStatus[] := Module[{collections, total = 0},
  collections = PDFIndex`pdfListCollections[];
  Print[Style["\[FilledRightTriangle] PDFIndex \:30b9\:30c6\:30fc\:30bf\:30b9", Blue, Bold, 14]];
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
(* Web\:7528\:753b\:50cf\:30d8\:30eb\:30d1\:30fc                                             *)
(* ============================================================ *)

(* Web\:7528: 1\:56de\:306e ExternalEvaluate \:3067\:8907\:6570\:30da\:30fc\:30b8\:3092 PNG \:30ec\:30f3\:30c0\:30ea\:30f3\:30b0 \[RightArrow] base64 Association\:3002
   ScheduledTask \:306e\:30b9\:30c6\:30fc\:30b82\:3067\:547c\:3070\:308c\:308b\:3002\:3053\:306e\:30c6\:30a3\:30c3\:30af\:3067\:306f\:552f\:4e00\:306e
   ExternalEvaluate \:547c\:3073\:51fa\:3057\:3068\:306a\:308b\:305f\:3081\:30bb\:30c3\:30b7\:30e7\:30f3\:885d\:7a81\:3057\:306a\:3044\:3002
   \:623b\:308a\:5024: <|pageNum1 -> "base64...", pageNum2 -> "base64...", ...|> *)
(* === \:30da\:30fc\:30b8\:30e9\:30d9\:30eb\:5909\:63db\:30d8\:30eb\:30d1\:30fc ===
   PDF\:306e\:8ad6\:7406\:30da\:30fc\:30b8\:30e9\:30d9\:30eb (Acrobat\:8a2d\:5b9a) \:3068\:7269\:7406\:30da\:30fc\:30b8\:756a\:53f7\:306e\:5909\:63db *)
iGetPageLabel[physicalPage_Integer] :=
  Module[{labels = Lookup[$pdfIndexAsyncContext, "pageLabels", <||>]},
    Lookup[labels, ToString[physicalPage], None]];

iPageDisplayStr[physicalPage_Integer] :=
  Module[{label = iGetPageLabel[physicalPage]},
    If[StringQ[label],
      "p." <> label,
      "p." <> ToString[physicalPage]]];

(* \:8ad6\:7406\:30da\:30fc\:30b8\:30e9\:30d9\:30eb\:304b\:3089\:7269\:7406\:30da\:30fc\:30b8\:756a\:53f7\:3078\:306e\:9006\:5909\:63db *)
iLabelToPhysical[label_String] :=
  Module[{labels = Lookup[$pdfIndexAsyncContext, "pageLabels", <||>],
          found},
    found = SelectFirst[Normal[labels], #[[2]] === label &, None];
    If[found =!= None,
      ToExpression[found[[1]]],
      (* \:30e9\:30d9\:30eb\:304c\:898b\:3064\:304b\:3089\:306a\:3044\:5834\:5408\:306f\:6570\:5024\:3068\:3057\:3066\:7269\:7406\:30da\:30fc\:30b8\:3068\:89e3\:91c8 *)
      Quiet @ Check[ToExpression[label], None]]];

(* PDF\:304b\:3089\:30da\:30fc\:30b8\:30e9\:30d9\:30eb\:3092\:62bd\:51fa\:3057\:3066\:30ad\:30e3\:30c3\:30b7\:30e5 *)
iEnsurePageLabels[pdfPath_String] :=
  Module[{existing = Lookup[$pdfIndexAsyncContext, "pageLabels", <||>]},
    If[Length[existing] > 0, Return[existing]];
    Module[{escapedPath = StringReplace[pdfPath, "\\" -> "/"],
            outFile, pyCode, result, labels = <||>},
      outFile = FileNameJoin[{$TemporaryDirectory,
        "pdflabels_" <> IntegerString[Round[AbsoluteTime[] * 1000]] <> ".json"}];
      pyCode = "
import json
try:
    import fitz
    doc = fitz.open(r'" <> escapedPath <> "')
    labels = {}
    for i in range(doc.page_count):
        try:
            lbl = doc[i].get_label()
            if lbl and lbl != str(i+1):
                labels[str(i+1)] = lbl
        except:
            pass
    doc.close()
    with open(r'" <> StringReplace[outFile, "\\" -> "/"] <>
      "', 'w', encoding='utf-8') as f:
        json.dump(labels, f, ensure_ascii=False)
    'done'
except Exception as e:
    str(e)
";
      Quiet[ExternalEvaluate["Python", pyCode]];
      If[FileExistsQ[outFile],
        labels = Quiet @ Check[Developer`ReadRawJSONFile[outFile], <||>];
        Quiet[DeleteFile[outFile]];
        If[AssociationQ[labels] && Length[labels] > 0,
          $pdfIndexAsyncContext["pageLabels"] = labels;
          Print["  \:30da\:30fc\:30b8\:30e9\:30d9\:30eb: " <> ToString[Length[labels]] <> "\:30da\:30fc\:30b8\:5206\:30ed\:30fc\:30c9"]]];
      labels]];

(* Web\:7528: ExternalEvaluate 1\:56de\:3067\:5168\:30da\:30fc\:30b8\:3092 base64 \:3068\:3057\:3066\:76f4\:63a5\:8fd4\:3059\:3002
   \:30d5\:30a1\:30a4\:30eb I/O \:306a\:3057 \[LongDash] Python \:5185\:3067 base64 \:30a8\:30f3\:30b3\:30fc\:30c9\:3057\:3066\:623b\:308a\:5024\:3067\:53d7\:3051\:53d6\:308b\:3002
   \:623b\:308a\:5024: <|pageNum1 -> "base64...", ...|> *)
iRenderPagesBase64[pdfPath_String, pageNums_List] := Module[
  {escapedPath, pyCode, result, results = <||>},
  escapedPath = StringReplace[pdfPath, "\\" -> "/"];
  (* Python \:3067 base64 \:3092\:76f4\:63a5\:751f\:6210\:3057\:3066\:8f9e\:66f8\:3067\:8fd4\:3059 *)
  (* 72 DPI \[RightArrow] PIL \:3067 JPEG \:5909\:63db\:3002PIL \:306a\:3051\:308c\:3070 48 DPI PNG \:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af *)
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
  (* \:7d50\:679c\:89e3\:6790: Python dict \[RightArrow] WL Association *)
  If[AssociationQ[result],
    Do[
      Module[{key = ToString[pg], b64},
        b64 = Lookup[result, key, Lookup[result, pg, None]];
        If[StringQ[b64] && StringLength[b64] > 100,
          results[pg] = b64]],
      {pg, pageNums}]];
  (* \:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af: Mathematica Import *)
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
(* WebServer \:7d71\:5408\:30eb\:30fc\:30c8\:767b\:9332                                       *)
(* ============================================================ *)

(* === PDF \:975e\:540c\:671f\:30b8\:30e7\:30d6\:30ad\:30e5\:30fc ===
   WebServer \:306e $WebServerPendingJobs \:3068\:306f\:72ec\:7acb\:3057\:305f\:30ad\:30e5\:30fc\:3002
   /query \:3068 /pdfask, /pdfpage \:3092\:4e26\:5217\:5b9f\:884c\:53ef\:80fd\:306b\:3059\:308b\:3002

   [rule 95-B \:4f8b\:5916] ScheduledTask \:306e\:4f7f\:7528\:7406\:7531:
   ClaudeQueryBg (URLRead) \:304a\:3088\:3073 pdfShowPage (ExternalEvaluate) \:306f
   FrontEnd \:3068\:306e\:901a\:4fe1\:3092\:884c\:308f\:306a\:3044\:7d14\:7c8b\:306a HTTP / \:30d7\:30ed\:30bb\:30b9\:547c\:3073\:51fa\:3057\:30bf\:30b9\:30af\:3002
   SocketListen \:30cf\:30f3\:30c9\:30e9\:5185\:3067\:306e\:540c\:671f\:5b9f\:884c\:306f FrontEnd \:30d6\:30ed\:30c3\:30af
   \:ff08\:300c\:52d5\:7684\:8a55\:4fa1\:306e\:653e\:68c4\:300d\:30c0\:30a4\:30a2\:30ed\:30b0\:ff09\:3092\:5f15\:304d\:8d77\:3053\:3059\:305f\:3081\:975e\:540c\:671f\:5316\:304c\:5fc5\:8981\:3002 *)

$PDFJobPending    = <||>;  (* jobId -> <|"type"->..., "query"->..., "collection"->..., "t0"->...|> *)
$PDFJobResults    = <||>;  (* jobId -> <|"result"->..., "elapsed"->..., "type"->...|> *)
$PDFJobProcessing = False;
$PDFJobTask       = None;
$PDFImageCache    = <||>;  (* imgId -> base64String (\:4e00\:6642\:30ad\:30e3\:30c3\:30b7\:30e5) *)

(* PDF \:30b8\:30e7\:30d6\:30d7\:30ed\:30bb\:30c3\:30b5: 0.5\:79d2\:3054\:3068\:306b\:30ad\:30e5\:30fc\:3092\:78ba\:8a8d
   pdfask: iClaudeQueryAsyncWithProgress (StartProcess, \:5b8c\:5168\:975e\:30d6\:30ed\:30c3\:30ad\:30f3\:30b0)
   pdfpage/pdfrender: SessionSubmit (pdfask \:3068\:7af6\:5408\:3057\:306a\:3044)
   ScheduledTask \:306f\:30b8\:30e7\:30d6\:30c7\:30a3\:30b9\:30d1\:30c3\:30c1\:306e\:307f \[LongDash] FrontEnd \:3092\:30d6\:30ed\:30c3\:30af\:3057\:306a\:3044\:3002 *)
iStartPDFJobProcessor[] := Module[{},
  $PDFJobProcessing = False;
  $PDFRenderBusy = False;
  If[MatchQ[$PDFJobTask, _ScheduledTaskObject],
    Quiet[RemoveScheduledTask[$PDFJobTask]]];
  $PDFJobTask = RunScheduledTask[
    Module[{pendingIds},
      pendingIds = Keys[$PDFJobPending];
      Do[
        Module[{ji = $PDFJobPending[jid], jt},
          jt = Lookup[ji, "type", ""];
          Which[
            (* pdfpage/pdfrender: SessionSubmit \:3067\:30c7\:30a3\:30b9\:30d1\:30c3\:30c1 *)
            (jt === "pdfpage" || jt === "pdfrender") && !TrueQ[$PDFRenderBusy],
              $PDFJobPending = KeyDrop[$PDFJobPending, jid];
              $PDFRenderBusy = True;
              With[{id = jid, info = ji, typ = jt},
                SessionSubmit[
                  Module[{},
                    Quiet @ Check[
                      If[typ === "pdfpage",
                        iExecPdfPageJob[id, info],
                        iExecPdfRenderJob[id, info]],
                      $PDFJobResults[id] =
                        <|"result" -> <|"error" -> "Error"|>,
                          "elapsed" -> 0, "type" -> "pdfpage",
                          "query" -> Lookup[info, "query", ""]|>];
                    $PDFRenderBusy = False]]],

            (* pdfask: /query \:3068\:540c\:3058\:975e\:30d6\:30ed\:30c3\:30ad\:30f3\:30b0\:30d1\:30bf\:30fc\:30f3
               \:691c\:7d22\:306f\:540c\:671f(\:9ad8\:901f\:30ad\:30e3\:30c3\:30b7\:30e5)\:3001LLM\:306fStartProcess+\:30dd\:30fc\:30ea\:30f3\:30b0 *)
            jt === "pdfask" && !TrueQ[$PDFJobProcessing],
              $PDFJobPending = KeyDrop[$PDFJobPending, jid];
              $PDFJobProcessing = True;
              Module[{query = Lookup[ji, "query", ""],
                      collection = Lookup[ji, "collection", "default"],
                      searchResult, pubPrompt, fullPrompt, nb0, t0 = ji["t0"]},
                (* \:691c\:7d22: \:540c\:671f\:5b9f\:884c (\:30c1\:30e3\:30f3\:30af\:30ad\:30e3\:30c3\:30b7\:30e5\:3001\:9ad8\:901f) *)
                searchResult = Quiet @ Check[
                  PDFIndex`pdfSearchForLLM[query, Collection -> collection],
                  <|"public" -> <|"prompt" -> "", "count" -> 0|>,
                    "private" -> <|"prompt" -> "", "count" -> 0|>|>];
                pubPrompt = searchResult["public"]["prompt"];
                If[!StringQ[pubPrompt] || pubPrompt === "",
                  $PDFJobResults[jid] =
                    <|"result" -> "\:691c\:7d22\:7d50\:679c\:304c\:898b\:3064\:304b\:308a\:307e\:305b\:3093\:3067\:3057\:305f\:3002",
                      "elapsed" -> Round[AbsoluteTime[] - t0, 0.01],
                      "type" -> "pdfask", "query" -> query|>;
                  $PDFJobProcessing = False,
                  (* LLM \:30d7\:30ed\:30f3\:30d7\:30c8\:69cb\:7bc9 *)
                  fullPrompt =
                    "\:4ee5\:4e0b\:306ePDF\:6587\:66f8\:306e\:62bd\:51fa\:5185\:5bb9\:304b\:3089\:3001\:300c" <> query <>
                    "\:300d\:306b\:95a2\:9023\:3059\:308b\:60c5\:5831\:3092\:65e5\:672c\:8a9e\:3067\:307e\:3068\:3081\:3066\:304f\:3060\:3055\:3044\:3002\n" <>
                    "\:5404\:30c1\:30e3\:30f3\:30af\:304b\:3089\:91cd\:8981\:306a\:60c5\:5831\:3092\:62bd\:51fa\:3057\:3001\:51fa\:5178\:30da\:30fc\:30b8\:756a\:53f7\:3082\:660e\:8a18\:3057\:3066\:304f\:3060\:3055\:3044\:3002\n" <>
                    "\:51fa\:529b\:306f Markdown \:5f62\:5f0f\:3067\:3002\n\n" <> pubPrompt;
                  (* \:975e\:30d6\:30ed\:30c3\:30ad\:30f3\:30b0 LLM \:547c\:3073\:51fa\:3057 *)
                  nb0 = Quiet @ Check[
                    If[MatchQ[$MWSNotebook, _NotebookObject], $MWSNotebook,
                       First[Notebooks[]]], $Failed];
                  If[MatchQ[nb0, _NotebookObject],
                    (* ClaudeQueryAsync: \:516c\:958bAPI\:3001\:5b8c\:5168\:975e\:30d6\:30ed\:30c3\:30ad\:30f3\:30b0 *)
                    With[{id = jid, q = query, tt0 = t0},
                      ClaudeCode`ClaudeQueryAsync[
                        fullPrompt,
                        Function[response,
                          $PDFJobResults[id] =
                            <|"result" -> response,
                              "elapsed" -> Round[AbsoluteTime[] - tt0, 0.01],
                              "type" -> "pdfask", "query" -> q|>;
                          $PDFJobProcessing = False],
                        nb0]],
                    (* \:30d5\:30a9\:30fc\:30eb\:30d0\:30c3\:30af: ClaudeQueryBg (\:30d6\:30ed\:30c3\:30ad\:30f3\:30b0) *)
                    With[{id = jid, q = query, tt0 = t0, fp = fullPrompt},
                      SessionSubmit[
                        Module[{result},
                          result = Quiet @ Check[
                            ClaudeCode`ClaudeQueryBg[fp], "Error"];
                          $PDFJobResults[id] =
                            <|"result" -> result,
                              "elapsed" -> Round[AbsoluteTime[] - tt0, 0.01],
                              "type" -> "pdfask", "query" -> q|>;
                          $PDFJobProcessing = False]]]]]],

            True, Null]],
        {jid, pendingIds}]],
    0.5];
];

(* pdfpage \:30b9\:30c6\:30fc\:30b81: \:691c\:7d22 \[RightArrow] \:30da\:30fc\:30b8\:756a\:53f7\:78ba\:5b9a \[RightArrow] \:30b9\:30c6\:30fc\:30b82\:3092\:30ad\:30e5\:30fc\:306b\:518d\:6295\:5165 *)
iExecPdfPageJob[jobId_String, jobInfo_Association] :=
  Module[{query, collection, pageNum, pairPages},
    query = jobInfo["query"];
    collection = Lookup[jobInfo, "collection", "default"];
    pageNum = Lookup[jobInfo, "directPage", None];
    (* \:76f4\:63a5\:30da\:30fc\:30b8\:6307\:5b9a\:6642: \:30e9\:30d9\:30eb\:30de\:30c3\:30d4\:30f3\:30b0\:304c\:672a\:30ed\:30fc\:30c9\:306e\:5834\:5408\:304c\:3042\:308b\:305f\:3081\:3001
       \:30da\:30fc\:30b8\:30e9\:30d9\:30eb\:3092\:78ba\:5b9f\:306b\:30ed\:30fc\:30c9\:3059\:308b\:3002
       pdfFindPage \:7d4c\:7531\:306e\:5834\:5408\:306f iExtractTOC \:304c\:526f\:7523\:7269\:3068\:3057\:3066\:8a2d\:5b9a\:6e08\:307f\:3002 *)
    If[IntegerQ[pageNum],
      Module[{dpPath = iGetDocSourcePath[collection]},
        If[StringQ[dpPath] && FileExistsQ[dpPath],
          iEnsurePageLabels[dpPath]]]];
    If[!IntegerQ[pageNum],
      pageNum = Quiet @ Check[
        PDFIndex`pdfFindPage[query, collection], None]];
    Module[{resolvedC = Lookup[$pdfIndexAsyncContext,
        "resolvedCollection", collection],
      yearNote = Lookup[$pdfIndexAsyncContext, "yearNote", None],
      docPath = Lookup[$pdfIndexAsyncContext, "resolvedDocPath", None]},
    If[IntegerQ[pageNum],
      pairPages = Lookup[$pdfIndexAsyncContext, "lastPairPages", None];
      $PDFJobPending[jobId] =
        <|"type" -> "pdfrender",
          "pageNum" -> pageNum,
          "pairPages" -> pairPages,
          "query" -> query,
          "collection" -> resolvedC,
          "docPath" -> docPath,
          "yearNote" -> yearNote,
          "t0" -> jobInfo["t0"]|>,
      $PDFJobResults[jobId] =
        <|"result" -> <|"error" -> "\:30da\:30fc\:30b8\:304c\:898b\:3064\:304b\:308a\:307e\:305b\:3093\:3067\:3057\:305f"|>,
          "elapsed" -> Round[AbsoluteTime[] - jobInfo["t0"], 0.01],
          "type" -> "pdfpage", "query" -> query|>]]];

(* pdfrender \:30b9\:30c6\:30fc\:30b82: WL Import \:3067\:30ec\:30f3\:30c0\:30ea\:30f3\:30b0 (ExternalEvaluate \:4e0d\:4f7f\:7528) *)
iExecPdfRenderJob[jobId_String, jobInfo_Association] :=
  Module[{result, elapsed, query, collection, pageNum, pdfPath, b64},
    query = Lookup[jobInfo, "query", ""];
    collection = Lookup[jobInfo, "collection", "default"];
    pageNum = jobInfo["pageNum"];
    pdfPath = Lookup[jobInfo, "docPath", None];
    If[!StringQ[pdfPath] || !FileExistsQ[pdfPath],
      pdfPath = iGetDocSourcePath[collection]];
    (* \:30da\:30fc\:30b8\:30e9\:30d9\:30eb: ExternalEvaluate \:3092\:4f7f\:3046\:305f\:3081\:7701\:7565\:53ef *)
    b64 = Quiet @ Check[iRenderPageBase64WL[pdfPath, pageNum], None];
    result = If[StringQ[b64] && StringLength[b64] > 100,
      <|"pageNum" -> pageNum, "b64Main" -> b64,
        "b64Prev" -> None, "pairPages" -> None|>,
      <|"error" -> "Error: \:30ec\:30f3\:30c0\:30ea\:30f3\:30b0\:5931\:6557"|>];
    elapsed = Round[AbsoluteTime[] - jobInfo["t0"], 0.01];
    $PDFJobResults[jobId] =
      <|"result" -> result, "elapsed" -> elapsed,
        "type" -> "pdfpage", "query" -> query,
        "yearNote" -> Lookup[jobInfo, "yearNote", None]|>];

(* WL Import \:306b\:3088\:308b\:30da\:30fc\:30b8\:30ec\:30f3\:30c0\:30ea\:30f3\:30b0 \[RightArrow] base64 (ExternalEvaluate \:4e0d\:4f7f\:7528) *)
iRenderPageBase64WL[pdfPath_String, pageNum_Integer] :=
  Module[{img, tmpFile, bytes},
    img = Quiet @ Check[
      Import[pdfPath, {"PageGraphics", pageNum}], $Failed];
    If[img === $Failed || Head[img] =!= Graphics,
      img = Quiet @ Check[
        Import[pdfPath, {"ImageList", pageNum}], $Failed]];
    If[img === $Failed, Return[None]];
    tmpFile = FileNameJoin[{$TemporaryDirectory,
      "pdfwl_" <> ToString[pageNum] <> "_" <>
      IntegerString[Round[AbsoluteTime[] * 1000]] <> ".jpg"}];
    Quiet @ Check[
      Export[tmpFile,
        If[Head[img] === Graphics,
          Rasterize[img, ImageResolution -> 100],
          img],
        "JPEG", ImageResolution -> 100,
        CompressionLevel -> 0.5], $Failed];
    If[!FileExistsQ[tmpFile], Return[None]];
    bytes = ReadByteArray[tmpFile];
    Quiet[DeleteFile[tmpFile]];
    If[Length[bytes] > 0,
      BaseEncode[bytes],
      None]];

(* WebServer \:304c\:30ed\:30fc\:30c9\:6e08\:307f\:306a\:3089\:691c\:7d22\:30eb\:30fc\:30c8\:3092\:81ea\:52d5\:767b\:9332\:3059\:308b *)
iRegisterWebServerRoutes[] := Module[{},
  If[Length[Names["WebServer`RegisterRoute"]] === 0, Return[]];

  (* \:30b8\:30e7\:30d6\:30d7\:30ed\:30bb\:30c3\:30b5\:8d77\:52d5 *)
  iStartPDFJobProcessor[];

  (* ============ GET /pdfsearch?q=... (\:65e2\:5b58) ============ *)
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

  (* ============ POST /pdfsearch/api (\:65e2\:5b58) ============ *)
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
  (* /pdfask : PDF\:691c\:7d22 + LLM\:8cea\:554f\:5fdc\:7b54 (\:975e\:540c\:671f\:30b8\:30e7\:30d6\:30ad\:30e5\:30fc)          *)
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
        (* \:30dd\:30fc\:30ea\:30f3\:30b0: \:30b8\:30e7\:30d6\:7d50\:679c\:78ba\:8a8d *)
        method === "GET" && StringLength[pollId] > 0,
          iPDFJobPoll[pollId, "/pdfask"],

        (* POST: \:30b8\:30e7\:30d6\:3092\:30ad\:30e5\:30fc\:306b\:8ffd\:52a0 *)
        (method === "POST" || method === "GET") && StringLength[StringTrim[query]] > 0,
          jobId = "pa" <> ToString[Floor[AbsoluteTime[] * 1000]];
          $PDFJobPending[jobId] =
            <|"type" -> "pdfask", "query" -> query,
              "collection" -> collection, "t0" -> AbsoluteTime[]|>;
          iHTTP200[iPDFHTMLPage["PDF \:8cea\:554f\:5fdc\:7b54 - \:51e6\:7406\:4e2d",
            iPDFRenderPolling[jobId, query, "/pdfask"]]],

        (* GET: \:30d5\:30a9\:30fc\:30e0\:8868\:793a *)
        True,
          iHTTP200[iPDFHTMLPage["PDF \:8cea\:554f\:5fdc\:7b54",
            iPDFRenderAskForm[""]]]
      ]
    ]]];

  (* ============================================================ *)
  (* /pdfpage : PDF\:30da\:30fc\:30b8\:753b\:50cf\:8868\:793a (\:975e\:540c\:671f\:30b8\:30e7\:30d6\:30ad\:30e5\:30fc)             *)
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
        (* \:30dd\:30fc\:30ea\:30f3\:30b0: \:30b8\:30e7\:30d6\:7d50\:679c\:78ba\:8a8d *)
        method === "GET" && StringLength[pollId] > 0,
          iPDFJobPoll[pollId, "/pdfpage"],

        (* \:30da\:30fc\:30b8\:756a\:53f7\:76f4\:63a5\:6307\:5b9a: /pdfpage?p=129
           \:8ad6\:7406\:30da\:30fc\:30b8\:30e9\:30d9\:30eb\:304c\:30ed\:30fc\:30c9\:6e08\:307f\:306e\:5834\:5408\:3001\:5165\:529b\:3092\:8ad6\:7406\[RightArrow]\:7269\:7406\:5909\:63db *)
        (* \:7269\:7406\:30da\:30fc\:30b8\:76f4\:63a5\:6307\:5b9a: /pdfpage?phys=133 (\:30ca\:30d3\:30b2\:30fc\:30b7\:30e7\:30f3\:7528\:3001\:5909\:63db\:306a\:3057) *)
        method === "GET" && StringLength[Lookup[req["Query"], "phys", ""]] > 0,
          pageNum = Quiet @ Check[
            ToExpression[Lookup[req["Query"], "phys", "1"]], 1];
          jobId = "pp" <> ToString[Floor[AbsoluteTime[] * 1000]];
          $PDFJobPending[jobId] =
            <|"type" -> "pdfpage",
              "query" -> ("p." <> ToString[pageNum]),
              "directPage" -> pageNum,
              "collection" -> collection, "t0" -> AbsoluteTime[]|>;
          iHTTP200[iPDFHTMLPage["PDF \:30da\:30fc\:30b8 - \:51e6\:7406\:4e2d",
            iPDFRenderPolling[jobId, "p." <> ToString[pageNum], "/pdfpage"]]],

        (* \:8ad6\:7406\:30da\:30fc\:30b8\:6307\:5b9a: /pdfpage?p=128 (\:30e9\:30d9\:30eb\[RightArrow]\:7269\:7406\:5909\:63db\:3042\:308a) *)
        method === "GET" && StringLength[Lookup[req["Query"], "p", ""]] > 0,
          pageNum = Quiet @ Check[
            ToExpression[Lookup[req["Query"], "p", "1"]], 1];
          (* \:8ad6\:7406\:30da\:30fc\:30b8\:30e9\:30d9\:30eb\:304b\:3089\:306e\:5909\:63db\:3092\:8a66\:307f\:308b *)
          pageNum = With[{pp = iLabelToPhysical[ToString[pageNum]]},
            If[IntegerQ[pp] && pp =!= pageNum,
              Print["  \:30da\:30fc\:30b8\:30e9\:30d9\:30eb\:5909\:63db: p." <> ToString[pageNum] <>
                " \[RightArrow] \:7269\:7406p." <> ToString[pp]]; pp,
              pageNum]];
          jobId = "pp" <> ToString[Floor[AbsoluteTime[] * 1000]];
          $PDFJobPending[jobId] =
            <|"type" -> "pdfpage",
              "query" -> ("p." <> ToString[pageNum]),
              "directPage" -> pageNum,
              "collection" -> collection, "t0" -> AbsoluteTime[]|>;
          iHTTP200[iPDFHTMLPage["PDF \:30da\:30fc\:30b8 - \:51e6\:7406\:4e2d",
            iPDFRenderPolling[jobId, "p." <> ToString[pageNum], "/pdfpage"]]],

        (* \:30af\:30a8\:30ea\:304b\:3089\:30da\:30fc\:30b8\:691c\:7d22 *)
        (method === "POST" || method === "GET") && StringLength[StringTrim[query]] > 0,
          jobId = "pp" <> ToString[Floor[AbsoluteTime[] * 1000]];
          $PDFJobPending[jobId] =
            <|"type" -> "pdfpage", "query" -> query,
              "collection" -> collection, "t0" -> AbsoluteTime[]|>;
          iHTTP200[iPDFHTMLPage["PDF \:30da\:30fc\:30b8 - \:51e6\:7406\:4e2d",
            iPDFRenderPolling[jobId, query, "/pdfpage"]]],

        (* GET: \:30d5\:30a9\:30fc\:30e0\:8868\:793a *)
        True,
          iHTTP200[iPDFHTMLPage["PDF \:30da\:30fc\:30b8\:8868\:793a",
            iPDFRenderPageForm[""]]]
      ]
    ]]];

  (* ============================================================ *)
  (* /pdfimgdata : \:753b\:50cfbase64\:30c7\:30fc\:30bf\:914d\:4fe1 (JS\:9045\:5ef6\:30ed\:30fc\:30c9\:7528)           *)
  (* ============================================================ *)
  WebServer`RegisterRoute["/pdfimgdata",
    Function[req, Module[{imgId, b64},
      imgId = Lookup[req["Query"], "id", ""];
      If[StringLength[imgId] === 0,
        Return[iHTTP400["id \:304c\:5fc5\:8981\:3067\:3059"]]];
      b64 = Lookup[$PDFImageCache, imgId, None];
      If[StringQ[b64],
        (* \:30ad\:30e3\:30c3\:30b7\:30e5\:304b\:3089\:524a\:9664 (1\:56de\:9650\:308a) *)
        $PDFImageCache = KeyDrop[$PDFImageCache, imgId];
        (* base64 \:6587\:5b57\:5217\:3092\:305d\:306e\:307e\:307e\:8fd4\:3059 (Content-Type: text/plain) *)
        Module[{bodyBytes},
          bodyBytes = StringToByteArray[b64, "ISO8859-1"];
          "HTTP/1.1 200 OK\r\n" <>
          "Content-Type: text/plain; charset=ascii\r\n" <>
          "Content-Length: " <> ToString[Length[bodyBytes]] <>
          "\r\n\r\n" <> b64],
        iHTTP400["Image not found: " <> imgId]]
    ]]];

(*  Print["  PDFIndex WebServer \:30eb\:30fc\:30c8\:767b\:9332:"];
  Print["    GET  /pdfsearch?q=...       \:691c\:7d22\:30d5\:30a9\:30fc\:30e0 + \:7d50\:679c\:8868\:793a"];
  Print["    POST /pdfsearch/api         JSON API"];
  Print["    GET  /pdfask                \:8cea\:554f\:5fdc\:7b54\:30d5\:30a9\:30fc\:30e0 (pdfAskLLM)"];
  Print["    GET  /pdfpage?q=...         \:30da\:30fc\:30b8\:691c\:7d22\:30fb\:8868\:793a (pdfShowPage)"];
  Print["    GET  /pdfpage?p=129         \:30da\:30fc\:30b8\:756a\:53f7\:76f4\:63a5\:6307\:5b9a"];
  Print["    GET  /pdfimgdata?id=...     \:753b\:50cf\:30c7\:30fc\:30bf\:914d\:4fe1 (JS\:904e\:5ef6\:30ed\:30fc\:30c9)"];
*)
];

(* ============================================================ *)
(* PDF Web HTML \:30c6\:30f3\:30d7\:30ec\:30fc\:30c8                                      *)
(* ============================================================ *)

iPDFHTMLPage[title_String, body_String] :=
  "<!DOCTYPE html><html><head><meta charset='utf-8'><title>" <> title <>
  "</title><link rel='stylesheet' href='/style.css'></head><body>" <>
  body <> "</body></html>";

(* pdfAskLLM \:30d5\:30a9\:30fc\:30e0 *)
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

(* pdfShowPage \:30d5\:30a9\:30fc\:30e0 *)
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

(* \:30dd\:30fc\:30ea\:30f3\:30b0\:30da\:30fc\:30b8 *)
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

(* \:30b8\:30e7\:30d6\:7d50\:679c\:30dd\:30fc\:30ea\:30f3\:30b0 *)
iPDFJobPoll[jobId_String, returnPath_String] :=
  If[KeyExistsQ[$PDFJobResults, jobId],
    (* \:7d50\:679c\:3042\:308a *)
    Module[{jr = $PDFJobResults[jobId], jobType, result, elapsed, query, html},
      $PDFJobResults = KeyDrop[$PDFJobResults, jobId];
      jobType = Lookup[jr, "type", ""];
      result = jr["result"];
      elapsed = jr["elapsed"];
      query = Lookup[jr, "query", ""];
      html = Switch[jobType,
        "pdfask",  iPDFRenderAskResult[query, result, elapsed, returnPath],
        "pdfpage", iPDFRenderPageResult[query, result, elapsed, returnPath,
                     Lookup[jr, "yearNote", None]],
        _, "<h1>Error</h1><p>Unknown job type</p>"];
      (* pdfpage \:306f\:5b8c\:5168\:306aHTML\:3092\:8fd4\:3059\:3002Content-Length \:5fc5\:9808:
         base64\:753b\:50cf\:3067\:6570\:5341KB\:306b\:306a\:308b\:305f\:3081\:3001Content-Length \:304c\:306a\:3044\:3068
         Pause[0.05]+Close \:3067\:30d6\:30e9\:30a6\:30b6\:304c\:5168\:30c7\:30fc\:30bf\:53d7\:4fe1\:524d\:306b\:5207\:65ad\:3055\:308c\:308b *)
      If[jobType === "pdfpage",
        Module[{bodyBytes = StringToByteArray[html, "UTF-8"]},
          "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\n" <>
          "Content-Length: " <> ToString[Length[bodyBytes]] <> "\r\n" <>
          "Connection: close\r\n\r\n" <> html],
        iHTTP200[iPDFHTMLPage["PDF - \:7d50\:679c", html]]]],
    (* \:307e\:3060\:51e6\:7406\:4e2d \[RightArrow] \:518d\:30dd\:30fc\:30ea\:30f3\:30b0 *)
    If[KeyExistsQ[$PDFJobPending, jobId] || TrueQ[$PDFJobProcessing] || TrueQ[$PDFRenderBusy],
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

(* pdfAskLLM \:7d50\:679c\:30ec\:30f3\:30c0\:30ea\:30f3\:30b0 *)
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

(* pdfShowPage \:7d50\:679c\:30ec\:30f3\:30c0\:30ea\:30f3\:30b0:
   \:8d85\:8efd\:91cfHTML: CSS\:5916\:90e8\:30d5\:30a1\:30a4\:30eb\:306a\:3057\:3001\:76f4\:63a5\:30a4\:30f3\:30e9\:30a4\:30f3base64\:3002
   36 DPI \:3067 ~30KB base64\:3001HTML\:5168\:4f53 ~35KB\:3002
   WebServer 512B\[Times]0.05s = ~3.4\:79d2\:3067\:9001\:4fe1\:5b8c\:4e86\:3002 *)
iPDFRenderPageResult[query_String, result_, elapsed_, returnPath_String,
    yearNote_:None] :=
  Module[{pageNum, b64Main, navHtml = "", imgHtml = "", yearHtml = ""},
    If[!AssociationQ[result],
      Return["<html><body><h1>Error</h1><p>" <> ToString[result] <>
        "</p><a href='/pdfpage'>Back</a></body></html>"]];
    If[KeyExistsQ[result, "error"],
      Return["<html><body><h1>Error</h1><p>" <> result["error"] <>
        "</p><a href='/pdfpage'>Back</a></body></html>"]];
    (* \:5e74\:5ea6\:30df\:30b9\:30de\:30c3\:30c1\:8b66\:544a *)
    If[StringQ[yearNote],
      yearHtml = "<div style='background:#442200;border:1px solid #886600;" <>
        "padding:8px 12px;border-radius:6px;margin:8px 0;" <>
        "color:#ffcc44;font-size:13px'>" <>
        WebServer`Private`iHTMLEscape[yearNote] <> "</div>\n"];

    pageNum = Lookup[result, "pageNum", 0];
    b64Main = Lookup[result, "b64Main", None];

    (* \:30ca\:30d3\:30b2\:30fc\:30b7\:30e7\:30f3 \[LongDash] URL\:306f\:7269\:7406\:30da\:30fc\:30b8\:3001\:8868\:793a\:306f\:8ad6\:7406\:30e9\:30d9\:30eb *)
    navHtml = "<div style='margin:8px 0'>";
    If[IntegerQ[pageNum] && pageNum > 1,
      navHtml = navHtml <>
        "<a href='/pdfpage?phys=" <> ToString[pageNum - 1] <>
        "' style='color:#fff;background:#234;padding:6px 12px;" <>
        "border-radius:4px;text-decoration:none;margin-right:6px'>" <>
        "&lt; " <> iPageDisplayStr[pageNum - 1] <> "</a>"];
    If[IntegerQ[pageNum],
      navHtml = navHtml <>
        "<a href='/pdfpage?phys=" <> ToString[pageNum + 1] <>
        "' style='color:#fff;background:#234;padding:6px 12px;" <>
        "border-radius:4px;text-decoration:none;margin-right:6px'>" <>
        iPageDisplayStr[pageNum + 1] <> " &gt;</a>" <>
        "<a href='/pdfpage' style='color:#8af;margin-left:12px'>\:65b0\:898f\:691c\:7d22</a>" <>
        " <a href='/pdfask' style='color:#8af;margin-left:8px'>\:8cea\:554f</a>"];
    navHtml = navHtml <> "</div>\n";

    (* \:753b\:50cf *)
    If[StringQ[b64Main],
      Module[{mimeType = If[StringStartsQ[b64Main, "/9j/"],
          "image/jpeg", "image/png"]},
        imgHtml = "<img src='data:" <> mimeType <> ";base64," <> b64Main <>
          "' style='max-width:100%'>\n"],
      imgHtml = "<p style='color:red'>\:753b\:50cf\:306e\:751f\:6210\:306b\:5931\:6557</p>"];

    (* \:8d85\:8efd\:91cfHTML: style.css\:3092\:53c2\:7167\:3057\:306a\:3044 *)
    Module[{dispPage = iPageDisplayStr[pageNum]},
    "<!DOCTYPE html><html><head><meta charset='utf-8'>" <>
    "<title>PDF " <> dispPage <> "</title></head>" <>
    "<body style='background:#0d1b2a;color:#eee;font-family:sans-serif;" <>
    "margin:12px'>\n" <>
    "<p style='color:#88aaff'>" <>
    WebServer`Private`iHTMLEscape[query] <>
    " \[RightArrow] " <> dispPage <>
    " (" <> ToString[elapsed] <> "s)</p>\n" <>
    yearHtml <>
    navHtml <>
    "<h3 style='color:#4488cc'>PDF " <> dispPage <> "</h3>\n" <>
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
    "background:#0a1525;color:#eee;border:1px solid #334;border-radius:4px' title='\:8ad6\:7406\:30da\:30fc\:30b8\:756a\:53f7\:5bfe\:5fdc'>" <>
    "<button type='submit' style='padding:6px 12px;background:#234;color:#8af;" <>
    "border:1px solid #456;border-radius:4px;cursor:pointer'>\:8868\:793a</button></form></div>" <>
    "</body></html>"]
  ];

(* pdfpage \:5171\:901a\:30d5\:30a9\:30fc\:30e0: \:691c\:7d22 + \:30da\:30fc\:30b8\:756a\:53f7\:76f4\:63a5\:6307\:5b9a *)
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

(* HTTP \:30ec\:30b9\:30dd\:30f3\:30b9\:30d8\:30eb\:30d1\:30fc: Content-Length \:306f\:30d0\:30a4\:30c8\:6570\:3067\:8a08\:7b97 *)
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

(* \:691c\:7d22\:30d5\:30a9\:30fc\:30e0 HTML *)
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

(* \:691c\:7d22\:7d50\:679c\:30ec\:30f3\:30c0\:30ea\:30f3\:30b0 *)
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

(* === WebServer \:30eb\:30fc\:30c8\:81ea\:52d5\:767b\:9332 === *)
PDFIndex`Private`iRegisterWebServerRoutes[];

(* ---- ClaudeCode \:30ad\:30fc\:30ef\:30fc\:30c9\:81ea\:52d5\:6ce8\:5165\:767b\:9332 ---- *)
If[AssociationQ[ClaudeCode`$ClaudePackageKeywordMap],
  ClaudeCode`$ClaudePackageKeywordMap["pdfindex"] =
    {"PDF", "pdf", "pdfIndex", "pdfSearch", "pdfSearchUI", "pdfAskLLM",
     "pdfGetChunk", "pdfShowPage", "pdfFindPage",
     "\:8ad6\:6587", "paper", "\:6587\:66f8", "document", "\:691c\:7d22", "search", "\:30da\:30fc\:30b8",
     "pdfSearchForLLM", "pdfLoadIndex", "pdfReindex",
     "pdfRebuildCatalog", "pdfDeleteIndex",
     "pdfIndexAsyncSnapshot", "pdfIndexAsyncRestore",
     "pdfListDocs", "pdfListCollections", "pdfStatus",
     "\:30a4\:30f3\:30c7\:30c3\:30af\:30b9", "index", "chunk"}
];
