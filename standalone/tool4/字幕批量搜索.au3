#include <GUIConstantsEx.au3>
#include <ButtonConstants.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <EditConstants.au3>
#include <ListViewConstants.au3>
#include <ComboConstants.au3>
#include <GuiListView.au3>
#include <MsgBoxConstants.au3>

; ============================================================================
; SubtitleSearch AutoIt 独立版 v1.9
; 数据源：SubtitleCat.com + 迅雷字幕接口
; 不依赖 PotPlayer，不需要第三方 AutoIt UDF；使用 Windows 自带 WinHTTP / ADODB COM。
; ============================================================================

Global Const $SITE_URL = "https://www.subtitlecat.com"
Global Const $XUNLEI_API_URL = "https://api-shoulei-ssl.xunlei.com/oracle/subtitle"
Global Const $APP_TITLE = "在线中文字幕搜索 - SubtitleCat + 迅雷"
Global Const $APP_VERSION = "1.9"

Global $g_hGUI = 0
Global $g_idTitle = 0
Global $g_idBrowseVideo = 0
Global $g_idSearch = 0
Global $g_idBatchFolder = 0
Global $g_idBrowseBatchFolder = 0
Global $g_idBatchSearch = 0
Global $g_idBatchDownload = 0
Global $g_idBatchStop = 0
Global $g_idClear = 0
Global $g_idUseCat = 0
Global $g_idUseXunlei = 0
Global $g_idCatSearchCount = 0
Global $g_idXunleiSearchCount = 0
Global $g_idProgress = 0
Global $g_idList = 0
Global $g_hList = 0
Global $g_idSaveDir = 0
Global $g_idBrowseDir = 0
Global $g_idDownload = 0
Global $g_idOpenDir = 0
Global $g_idOpenPage = 0
Global $g_idStatus = 0
Global $g_sCurrentVideoPath = ""
Global $g_iCurrentVideoFirstResult = 0 ; 当前视频在结果数组中的起始位置，用于局部去重
Global $g_aResults[0][10] ; title, source, lang, format, URL/detail ID, filename, related video path, direct file URL, file size bytes, downloaded flag
Global $g_iResultCount = 0
Global $g_iResultCapacity = 0
Global $g_iListViewRows = 0
Global $g_aListRowResultIndex[0] ; visible ListView row index -> $g_aResults index
Global $g_iListRowMapCount = 0
Global $g_iListRowMapCapacity = 0
Global $g_iBatchHiddenResultCount = 0
Global $g_aBatchVideos[0][3] ; path, first result index, result count
Global $g_iBatchVideoCount = 0
Global $g_bBatchSearchComplete = False
Global Const $BATCH_LISTVIEW_LIMIT = 1200
Global $g_bBatchRunning = False
Global $g_bCancelBatch = False
Global $g_bCloseRequested = False
Global $g_iScanFileCount = 0
Global $g_iScanFileCapacity = 0
Global $g_sLastError = ""
Global $g_oComErrorHandler = 0

_Main()

Func _Main()
    $g_oComErrorHandler = ObjEvent("AutoIt.Error", "_ComErrorHandler")

    $g_hGUI = GUICreate($APP_TITLE & " v" & $APP_VERSION, 1000, 700, -1, -1, BitOR($GUI_SS_DEFAULT_GUI, $WS_MINIMIZEBOX))
    GUISetFont(9, 400, 0, "Microsoft YaHei UI", $g_hGUI)

    GUICtrlCreateLabel("单个视频 / 手动搜索标题", 18, 10, 220, 20)
    $g_idTitle = GUICtrlCreateInput("", 18, 34, 760, 28)
    $g_idBrowseVideo = GUICtrlCreateButton("选择视频...", 790, 34, 95, 28)
    $g_idSearch = GUICtrlCreateButton("搜索字幕", 895, 34, 88, 28, $BS_DEFPUSHBUTTON)

    GUICtrlCreateLabel("批量视频目录（自动包含所有子文件夹）", 18, 70, 300, 20)
    $g_idBatchFolder = GUICtrlCreateInput("", 18, 94, 580, 28)
    $g_idBrowseBatchFolder = GUICtrlCreateButton("选择目录...", 607, 94, 85, 28)
    $g_idBatchSearch = GUICtrlCreateButton("批量搜索", 700, 94, 90, 28)
    $g_idBatchDownload = GUICtrlCreateButton("批量下载", 798, 94, 90, 28)
    $g_idBatchStop = GUICtrlCreateButton("停止批量", 896, 94, 87, 28)
    GUICtrlSetState($g_idBatchDownload, $GUI_DISABLE)
    GUICtrlSetState($g_idBatchStop, $GUI_HIDE)

    $g_idUseCat = GUICtrlCreateCheckbox("SubtitleCat", 20, 136, 110, 22)
    $g_idUseXunlei = GUICtrlCreateCheckbox("迅雷字幕", 145, 136, 110, 22)
    GUICtrlSetState($g_idUseCat, $GUI_CHECKED)
    GUICtrlSetState($g_idUseXunlei, $GUI_CHECKED)

    GUICtrlCreateLabel("SubtitleCat 搜索数量", 278, 138, 145, 20)
    $g_idCatSearchCount = GUICtrlCreateCombo("", 425, 132, 58, 25, $CBS_DROPDOWNLIST)
    GUICtrlSetData($g_idCatSearchCount, "1|2|3|4|5|6|7|8|9|10", "5")
    GUICtrlCreateLabel("迅雷搜索数量", 500, 138, 115, 20)
    $g_idXunleiSearchCount = GUICtrlCreateCombo("", 615, 132, 58, 25, $CBS_DROPDOWNLIST)
    GUICtrlSetData($g_idXunleiSearchCount, "1|2|3|4|5|6|7|8|9|10", "5")
    GUICtrlCreateLabel("单个与批量搜索共用数量设置", 690, 138, 285, 20, $SS_LEFT)

    GUICtrlCreateLabel("JAV 番号自动识别：ABCD-123 / ABC-123；支持 MP4、MOV、MKV 等格式。", 18, 163, 965, 18, $SS_LEFT)
    GUICtrlCreateLabel("搜索结果（批量搜索后可执行批量下载；也可按 Ctrl / Shift 多选手动下载）", 18, 185, 620, 20)
    $g_idList = GUICtrlCreateListView("关联视频|字幕名称|来源|语言|格式|文件大小", 18, 207, 965, 331, BitOR($LVS_REPORT, $LVS_SHOWSELALWAYS))
    $g_hList = GUICtrlGetHandle($g_idList)
    _GUICtrlListView_SetExtendedListViewStyle($g_hList, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
    _GUICtrlListView_SetColumnWidth($g_hList, 0, 190)
    _GUICtrlListView_SetColumnWidth($g_hList, 1, 365)
    _GUICtrlListView_SetColumnWidth($g_hList, 2, 90)
    _GUICtrlListView_SetColumnWidth($g_hList, 3, 95)
    _GUICtrlListView_SetColumnWidth($g_hList, 4, 55)
    _GUICtrlListView_SetColumnWidth($g_hList, 5, 125)

    GUICtrlCreateLabel("字幕保存目录", 18, 548, 100, 20)
    $g_idSaveDir = GUICtrlCreateInput(@ScriptDir & "\Subtitles", 18, 571, 735, 27)
    $g_idBrowseDir = GUICtrlCreateButton("选择目录...", 762, 571, 95, 27)
    $g_idOpenDir = GUICtrlCreateButton("打开目录", 862, 571, 120, 27)

    $g_idDownload = GUICtrlCreateButton("下载所选字幕", 18, 612, 150, 32, $BS_DEFPUSHBUTTON)
    $g_idOpenPage = GUICtrlCreateButton("打开字幕来源页面", 180, 612, 165, 32)
    $g_idClear = GUICtrlCreateButton("清空结果", 357, 612, 100, 32)
    $g_idStatus = GUICtrlCreateLabel("就绪。可搜索单个视频，或先批量搜索目录，再单独执行批量下载。", 475, 616, 505, 32, $SS_LEFT)
    GUICtrlCreateLabel("进度", 18, 654, 42, 20)
    $g_idProgress = GUICtrlCreateProgress(65, 654, 918, 18)
    GUICtrlSetData($g_idProgress, 0)

    GUISetState(@SW_SHOW, $g_hGUI)

    While 1
        Local $iMsg = GUIGetMsg()
        Switch $iMsg
            Case $GUI_EVENT_CLOSE
                If $g_bBatchRunning Then
                    $g_bCancelBatch = True
                    $g_bCloseRequested = True
                    _SetStatus("正在停止批量任务并关闭窗口...")
                Else
                    ExitLoop
                EndIf
            Case $g_idBrowseVideo
                _BrowseVideo()
            Case $g_idSearch
                _DoSearch()
            Case $g_idBrowseBatchFolder
                _BrowseBatchFolder()
            Case $g_idBatchSearch
                _BatchSearch()
            Case $g_idBatchDownload
                _BatchDownload()
            Case $g_idBatchStop
                $g_bCancelBatch = True
                _SetStatus("正在停止批量任务，请等待当前请求取消...")
            Case $g_idBrowseDir
                _BrowseSaveDir()
            Case $g_idDownload
                _DownloadSelected()
            Case $g_idOpenDir
                _OpenSaveDir()
            Case $g_idOpenPage
                _OpenSelectedPage()
            Case $g_idClear
                _ClearResults()
        EndSwitch
        If $g_bCloseRequested Then ExitLoop
    WEnd

    GUIDelete($g_hGUI)
EndFunc

Func _ComErrorHandler($oError)
    $g_sLastError = "COM 错误：" & Hex($oError.number, 8) & " - " & $oError.windescription
    Return
EndFunc

; ------------------------------- GUI 操作 -----------------------------------

Func _BrowseVideo()
    Local $sPath = FileOpenDialog("选择视频文件", @ScriptDir, _VideoFileFilter(), 1)
    If @error Or $sPath = "" Then Return

    Local $sName = _GetFileName($sPath)
    $g_sCurrentVideoPath = $sPath
    GUICtrlSetData($g_idTitle, _BuildSearchTitle($sPath))
    _SetStatus("已载入文件名：" & $sName)
EndFunc

Func _BrowseBatchFolder()
    Local $sDir = FileSelectFolder("选择需要批量搜索的视频目录（包含子文件夹）", "", 1, GUICtrlRead($g_idBatchFolder))
    If @error Or $sDir = "" Then Return
    GUICtrlSetData($g_idBatchFolder, $sDir)
    _SetStatus("已选择批量目录：" & $sDir)
EndFunc

Func _BrowseSaveDir()
    Local $sDir = FileSelectFolder("选择字幕保存目录", "", 1, GUICtrlRead($g_idSaveDir))
    If @error Or $sDir = "" Then Return
    GUICtrlSetData($g_idSaveDir, $sDir)
EndFunc

Func _OpenSaveDir()
    Local $sDir = StringStripWS(GUICtrlRead($g_idSaveDir), 3)
    If $sDir = "" Then Return
    If Not FileExists($sDir) Then DirCreate($sDir)
    If FileExists($sDir) Then ShellExecute($sDir)
EndFunc

Func _OpenSelectedPage()
    Local $aSelectedRows = _GUICtrlListView_GetSelectedIndices($g_idList, True)
    If Not IsArray($aSelectedRows) Then
        MsgBox($MB_ICONWARNING, $APP_TITLE, "无法读取列表选择状态，请重新选择字幕。")
        Return
    EndIf
    If $aSelectedRows[0] <= 0 Then
        MsgBox($MB_ICONINFORMATION, $APP_TITLE, "请先选择一条字幕结果。")
        Return
    EndIf
    Local $iIndex = _GetResultIndexForListRow($aSelectedRows[1])
    If $iIndex < 0 Then
        MsgBox($MB_ICONWARNING, $APP_TITLE, "所选列表行无法关联到字幕搜索结果。")
        Return
    EndIf

    Local $sURL = $g_aResults[$iIndex][4]
    If StringLeft($sURL, 7) = "http://" Or StringLeft($sURL, 8) = "https://" Then
        ShellExecute($sURL)
    Else
        ShellExecute($SITE_URL & "/" & $sURL)
    EndIf
EndFunc

Func _ClearResults()
    _GUICtrlListView_DeleteAllItems($g_hList)
    ReDim $g_aResults[0][10]
    $g_iResultCount = 0
    $g_iResultCapacity = 0
    $g_iCurrentVideoFirstResult = 0
    $g_iListViewRows = 0
    ReDim $g_aListRowResultIndex[0]
    $g_iListRowMapCount = 0
    $g_iListRowMapCapacity = 0
    ReDim $g_aBatchVideos[0][3]
    $g_iBatchVideoCount = 0
    $g_bBatchSearchComplete = False
    $g_iBatchHiddenResultCount = 0
    If $g_idProgress <> 0 Then GUICtrlSetData($g_idProgress, 0)
    If $g_idBatchDownload <> 0 Then GUICtrlSetState($g_idBatchDownload, $GUI_DISABLE)
    _SetStatus("已清空搜索结果。")
EndFunc

Func _SetStatus($sText)
    GUICtrlSetData($g_idStatus, $sText)
    Local $hStatus = GUICtrlGetHandle($g_idStatus)
    If $hStatus <> 0 Then DllCall("user32.dll", "bool", "UpdateWindow", "hwnd", $hStatus)
EndFunc

Func _UpdateProgress($iCurrent, $iTotal)
    Local $iPercent = 0
    If $iTotal > 0 Then $iPercent = Int(($iCurrent * 100) / $iTotal)
    If $iPercent < 0 Then $iPercent = 0
    If $iPercent > 100 Then $iPercent = 100
    If $g_idProgress <> 0 Then GUICtrlSetData($g_idProgress, $iPercent)
    Return $iPercent
EndFunc

Func _VideoFileFilter()
    Return "视频文件 (*.mp4;*.mkv;*.avi;*.wmv;*.flv;*.webm;*.mov;*.ts;*.m2ts;*.rmvb;*.mpg;*.mpeg;*.divx;*.3gp;*.vob;*.asf;*.m4v;*.rm;*.ogm;*.ogv)|所有文件 (*.*)"
EndFunc

; --------------------------------- 搜索 -------------------------------------

Func _DoSearch()
    $g_bCancelBatch = False
    Local $sRawTitle = StringStripWS(GUICtrlRead($g_idTitle), 3)
    If $sRawTitle = "" Then
        MsgBox($MB_ICONWARNING, $APP_TITLE, "请先选择视频文件或输入影片标题。")
        Return
    EndIf

    Local $bUseCat = (BitAND(GUICtrlRead($g_idUseCat), $GUI_CHECKED) = $GUI_CHECKED)
    Local $bUseXunlei = (BitAND(GUICtrlRead($g_idUseXunlei), $GUI_CHECKED) = $GUI_CHECKED)
    If Not $bUseCat And Not $bUseXunlei Then
        MsgBox($MB_ICONWARNING, $APP_TITLE, "请至少勾选一个字幕来源。")
        Return
    EndIf

    Local $sTitle = _BuildSearchTitle($sRawTitle)
    If $sTitle = "" Then
        MsgBox($MB_ICONWARNING, $APP_TITLE, "无法从输入内容中识别有效标题。")
        Return
    EndIf

    Local $iCatSearchCount = Int(GUICtrlRead($g_idCatSearchCount))
    Local $iXunleiSearchCount = Int(GUICtrlRead($g_idXunleiSearchCount))
    If $iCatSearchCount < 1 Or $iCatSearchCount > 10 Then $iCatSearchCount = 5
    If $iXunleiSearchCount < 1 Or $iXunleiSearchCount > 10 Then $iXunleiSearchCount = 5

    _ClearResults()
    $g_iCurrentVideoFirstResult = 0
    _SetStatus("正在搜索：" & $sTitle & "；SubtitleCat " & $iCatSearchCount & " 条 / 迅雷 " & $iXunleiSearchCount & " 条")

    Local $iCatCount = 0
    Local $iXunleiCount = 0
    If $bUseCat Then $iCatCount = _SearchSubtitleCat($sTitle, $iCatSearchCount)
    If Not $g_bCloseRequested And Not $g_bCancelBatch And $bUseXunlei Then $iXunleiCount = _SearchXunlei($sTitle, $iXunleiSearchCount)
    If $g_bCloseRequested Then Return

    Local $iTotal = $g_iResultCount
    If $iTotal = 0 Then
        _SetStatus("搜索完成：没有找到符合条件的简体中文字幕。")
        MsgBox($MB_ICONINFORMATION, $APP_TITLE, "没有找到简体中文字幕。" & @CRLF & @CRLF & _SourceSummary($bUseCat, $iCatCount, $bUseXunlei, $iXunleiCount))
    Else
        _SetStatus("搜索完成：共找到 " & $iTotal & " 条字幕（SubtitleCat " & $iCatCount & "/" & $iCatSearchCount & "；迅雷 " & $iXunleiCount & "/" & $iXunleiSearchCount & "）。")
    EndIf
EndFunc


; ------------------------------ 批量扫描处理 ---------------------------------

Func _BatchSearch()
    Local $sFolder = StringStripWS(GUICtrlRead($g_idBatchFolder), 3)
    If $sFolder = "" Or Not FileExists($sFolder) Then
        MsgBox($MB_ICONWARNING, $APP_TITLE, "请先选择一个有效的视频目录。")
        Return
    EndIf

    Local $bUseCat = (BitAND(GUICtrlRead($g_idUseCat), $GUI_CHECKED) = $GUI_CHECKED)
    Local $bUseXunlei = (BitAND(GUICtrlRead($g_idUseXunlei), $GUI_CHECKED) = $GUI_CHECKED)
    If Not $bUseCat And Not $bUseXunlei Then
        MsgBox($MB_ICONWARNING, $APP_TITLE, "请至少勾选一个字幕来源。")
        Return
    EndIf
    Local $iCatSearchCount = Int(GUICtrlRead($g_idCatSearchCount))
    Local $iXunleiSearchCount = Int(GUICtrlRead($g_idXunleiSearchCount))
    If $iCatSearchCount < 1 Or $iCatSearchCount > 10 Then $iCatSearchCount = 5
    If $iXunleiSearchCount < 1 Or $iXunleiSearchCount > 10 Then $iXunleiSearchCount = 5

    ; 递归扫描前先锁定界面，扫描期间仍可通过停止按钮中断。
    Local $aFiles[256]
    $g_iScanFileCount = 0
    $g_iScanFileCapacity = 256
    $g_bCancelBatch = False
    GUICtrlSetData($g_idProgress, 0)
    _SetBatchUIState(True)
    _SetStatus("正在递归扫描目录：" & $sFolder)
    _CollectVideoFiles($sFolder, $aFiles)
    If $g_bCancelBatch Or $g_bCloseRequested Then
        _SetBatchUIState(False)
        _SetStatus("目录扫描已取消。")
        Return
    EndIf
    If $g_iScanFileCount = 0 Then
        _SetBatchUIState(False)
        MsgBox($MB_ICONINFORMATION, $APP_TITLE, "所选目录及其子文件夹中没有找到支持的视频文件。")
        Return
    EndIf
    ReDim $aFiles[$g_iScanFileCount]
    Local $iFileCount = $g_iScanFileCount
    _SetBatchUIState(False)

    Local $iConfirm = MsgBox(BitOR($MB_ICONQUESTION, $MB_YESNO), $APP_TITLE, _
            "扫描到 " & $iFileCount & " 个视频文件。" & @CRLF & @CRLF & _
            "程序将逐个搜索 SubtitleCat 和迅雷字幕库，并保留可用结果。" & @CRLF & _
            "本阶段只搜索，不会下载字幕。搜索完成后可单独点击“批量下载”。" & @CRLF & _
            "本次搜索数量：SubtitleCat " & $iCatSearchCount & " 条 / 视频；迅雷 " & $iXunleiSearchCount & " 条 / 视频。" & @CRLF & _
            "只收录简体中文字幕。" & @CRLF & @CRLF & "是否开始搜索？")
    If $iConfirm <> $IDYES Then Return

    _ClearResults()
    $g_iBatchHiddenResultCount = 0
    ReDim $g_aBatchVideos[$iFileCount][3]
    $g_iBatchVideoCount = $iFileCount
    $g_bCancelBatch = False
    _SetBatchUIState(True)

    Local $iFoundVideo = 0
    Local $iNoMatch = 0
    Local $iTotalCat = 0
    Local $iTotalXunlei = 0
    Local $iProcessedVideos = 0

    For $i = 0 To $iFileCount - 1
        If $g_bCancelBatch Then ExitLoop
        $g_sCurrentVideoPath = $aFiles[$i]
        $g_aBatchVideos[$i][0] = $aFiles[$i]
        $g_aBatchVideos[$i][1] = $g_iResultCount
        $g_aBatchVideos[$i][2] = 0
        $g_iCurrentVideoFirstResult = $g_iResultCount

        Local $sTitle = _BuildSearchTitle($aFiles[$i])
        _SetStatus("批量搜索 " & ($i + 1) & "/" & $iFileCount & "：" & _GetFileName($aFiles[$i]) & _
                "；搜索标题：" & $sTitle)

        Local $iCatAdded = 0
        Local $iXunleiAdded = 0
        If $sTitle <> "" Then
            ; 下拉框是单个搜索和批量搜索共用的唯一收录数量上限。
            If $bUseCat Then $iCatAdded = _SearchSubtitleCat($sTitle, $iCatSearchCount, 3000)
            If Not $g_bCancelBatch And $bUseXunlei Then $iXunleiAdded = _SearchXunlei($sTitle, $iXunleiSearchCount)
        EndIf

        ; 即使用户在当前视频的第二个数据源请求期间停止，也保留已经收集到的候选。
        Local $iNewResults = $g_iResultCount - $g_aBatchVideos[$i][1]
        $g_aBatchVideos[$i][2] = $iNewResults
        $iProcessedVideos = $i + 1
        _UpdateProgress($iProcessedVideos, $iFileCount)
        $iTotalCat += $iCatAdded
        $iTotalXunlei += $iXunleiAdded
        If $iNewResults > 0 Then
            $iFoundVideo += 1
        Else
            $iNoMatch += 1
        EndIf

        If Mod($i + 1, 5) = 0 Or $i = $iFileCount - 1 Then
            _SetStatus("批量搜索进度 " & ($i + 1) & "/" & $iFileCount & "；找到字幕的视频 " & $iFoundVideo & " 个。")
        EndIf
        If $g_bCancelBatch Then ExitLoop
        Sleep(10)
    Next

    Local $bWasCancelled = $g_bCancelBatch
    ; 若取消，未处理视频从队列中移除，仅保留已经完成搜索的记录。
    If $bWasCancelled Then $g_iBatchVideoCount = $iProcessedVideos
    $g_sCurrentVideoPath = ""
    $g_bBatchSearchComplete = True
    _SetBatchUIState(False)

    Local $sBatchState = "完成。"
    If $bWasCancelled Then $sBatchState = "已停止（已保留已完成部分的搜索结果）。"
    Local $sSummary = "批量搜索" & $sBatchState & @CRLF & @CRLF & _
            "扫描视频：" & $iFileCount & " 个" & @CRLF & _
            "已完成搜索：" & $iProcessedVideos & " 个" & @CRLF & _
            "找到字幕的视频：" & $iFoundVideo & " 个" & @CRLF & _
            "未找到字幕：" & $iNoMatch & " 个" & @CRLF & _
            "SubtitleCat 候选：" & $iTotalCat & " 条" & @CRLF & _
            "迅雷候选：" & $iTotalXunlei & " 条" & @CRLF & _
            "搜索数量：SubtitleCat " & $iCatSearchCount & " 条 / 视频；迅雷 " & $iXunleiSearchCount & " 条 / 视频" & @CRLF & _
            "搜索结果总数：" & $g_iResultCount & " 条" & @CRLF & _
            "界面显示结果：最多 " & $BATCH_LISTVIEW_LIMIT & " 条；隐藏结果仍会参与批量下载。" & @CRLF & @CRLF & _
            "下一步：检查结果后，点击“批量下载”开始下载。"
    _SetStatus("批量搜索" & $sBatchState & "：处理 " & $iProcessedVideos & "/" & $iFileCount & _
            " 个视频，找到字幕的视频 " & $iFoundVideo & " 个。")
    If Not $g_bCloseRequested Then MsgBox($MB_ICONINFORMATION, $APP_TITLE, $sSummary)
EndFunc

Func _BatchDownload()
    If Not $g_bBatchSearchComplete Or $g_iBatchVideoCount <= 0 Then
        MsgBox($MB_ICONINFORMATION, $APP_TITLE, "请先执行“批量搜索”。")
        Return
    EndIf

    Local $sSaveDir = StringStripWS(GUICtrlRead($g_idSaveDir), 3)
    If $sSaveDir = "" Then
        MsgBox($MB_ICONWARNING, $APP_TITLE, "请设置字幕保存目录。")
        Return
    EndIf
    If Not FileExists($sSaveDir) Then DirCreate($sSaveDir)
    If Not FileExists($sSaveDir) Then
        MsgBox($MB_ICONERROR, $APP_TITLE, "无法创建保存目录：" & $sSaveDir)
        Return
    EndIf

    Local $iPending = _CountPendingBatchDownloads()
    If $iPending <= 0 Then
        MsgBox($MB_ICONINFORMATION, $APP_TITLE, "没有待下载的字幕结果。所有已找到的候选可能都已下载成功。")
        Return
    EndIf
    Local $iConfirm = MsgBox(BitOR($MB_ICONQUESTION, $MB_YESNO), $APP_TITLE, _
            "当前有 " & $iPending & " 条字幕候选尚未下载。" & @CRLF & @CRLF & _
            "批量下载将尝试所有已收录的字幕候选，不再限制每个视频的下载数量。" & @CRLF & _
            "每条候选独立记录下载状态；成功的跳过，失败的可再次重试。" & @CRLF & _
            "保存目录：" & $sSaveDir & @CRLF & @CRLF & "是否开始批量下载？")
    If $iConfirm <> $IDYES Then Return

    $g_bCancelBatch = False
    GUICtrlSetData($g_idProgress, 0)
    _SetBatchUIState(True)
    Local $iSuccess = 0
    Local $iFailed = 0
    Local $iSkipped = 0
    Local $sFailureList = ""
    Local $iAttempted = 0
    Local $iDownloadProgress = 0

    For $i = 0 To $g_iBatchVideoCount - 1
        If $g_bCancelBatch Then ExitLoop
        If $g_aBatchVideos[$i][2] <= 0 Then ContinueLoop

        Local $sVideoPath = $g_aBatchVideos[$i][0]
        Local $iStartResult = $g_aBatchVideos[$i][1]
        Local $iVideoResultCount = $g_aBatchVideos[$i][2]
        Local $sBaseName = _GetFileBaseName($sVideoPath)
        $g_sCurrentVideoPath = $sVideoPath

        For $j = $iStartResult To $iStartResult + $iVideoResultCount - 1
            If $g_bCancelBatch Then ExitLoop
            If $g_aResults[$j][9] = 1 Then
                $iSkipped += 1
                ContinueLoop
            EndIf

            _SetStatus("批量下载 " & ($i + 1) & "/" & $g_iBatchVideoCount & "：" & _GetFileName($sVideoPath) & _
                    "；字幕候选 " & ($j - $iStartResult + 1) & "/" & $iVideoResultCount)
            Local $sTryError = ""
            If _DownloadResult($j, $sSaveDir, $sBaseName, True, $sTryError) Then
                $iSuccess += 1
            Else
                $iFailed += 1
                If $iFailed <= 20 Then $sFailureList &= _GetFileName($sVideoPath) & " / " & $g_aResults[$j][0] & "：" & $sTryError & @CRLF
            EndIf
            $iAttempted += 1
            $iDownloadProgress += 1
            Local $iDownloadPercent = _UpdateProgress($iDownloadProgress, $iPending)
            _SetStatus("批量下载进度 " & $iDownloadProgress & "/" & $iPending & "（" & $iDownloadPercent & "%）；成功 " & $iSuccess & " 条，失败 " & $iFailed & " 条。")
            Sleep(10)
        Next
    Next

    Local $bWasCancelled = $g_bCancelBatch
    $g_sCurrentVideoPath = ""
    _SetBatchUIState(False)
    Local $sBatchState = "完成。"
    If $bWasCancelled Then $sBatchState = "已停止；已成功下载的字幕已记录，再次点击可继续未完成项目。"

    Local $sSummary = "批量下载" & $sBatchState & @CRLF & @CRLF & _
            "本次尝试：" & $iAttempted & " 条" & @CRLF & _
            "本次成功：" & $iSuccess & " 条" & @CRLF & _
            "本次失败：" & $iFailed & " 条" & @CRLF & _
            "此前已下载并跳过：" & $iSkipped & " 条" & @CRLF & _
            "仍待处理：" & _CountPendingBatchDownloads() & " 条" & @CRLF & @CRLF & _
            "保存目录：" & $sSaveDir
    If $sFailureList <> "" Then $sSummary &= @CRLF & @CRLF & "失败详情（最多显示 20 条，可再次点击批量下载重试）:" & @CRLF & $sFailureList
    _SetStatus("批量下载" & $sBatchState & "：成功 " & $iSuccess & " 条，失败 " & $iFailed & " 条。")
    If Not $g_bCloseRequested Then MsgBox($MB_ICONINFORMATION, $APP_TITLE, $sSummary)
EndFunc

Func _CountPendingBatchDownloads()
    Local $iPending = 0
    For $i = 0 To $g_iBatchVideoCount - 1
        Local $iStartResult = $g_aBatchVideos[$i][1]
        Local $iVideoResultCount = $g_aBatchVideos[$i][2]
        For $j = $iStartResult To $iStartResult + $iVideoResultCount - 1
            If $g_aResults[$j][9] <> 1 Then $iPending += 1
        Next
    Next
    Return $iPending
EndFunc

Func _SetBatchUIState($bRunning)
    $g_bBatchRunning = $bRunning
    If $bRunning Then
        GUICtrlSetState($g_idBatchSearch, $GUI_HIDE)
        GUICtrlSetState($g_idBatchDownload, $GUI_HIDE)
        GUICtrlSetState($g_idBatchStop, $GUI_SHOW)
        GUICtrlSetState($g_idTitle, $GUI_DISABLE)
        GUICtrlSetState($g_idSearch, $GUI_DISABLE)
        GUICtrlSetState($g_idBrowseVideo, $GUI_DISABLE)
        GUICtrlSetState($g_idBatchFolder, $GUI_DISABLE)
        GUICtrlSetState($g_idBrowseBatchFolder, $GUI_DISABLE)
        GUICtrlSetState($g_idSaveDir, $GUI_DISABLE)
        GUICtrlSetState($g_idBrowseDir, $GUI_DISABLE)
        GUICtrlSetState($g_idOpenDir, $GUI_DISABLE)
        GUICtrlSetState($g_idDownload, $GUI_DISABLE)
        GUICtrlSetState($g_idOpenPage, $GUI_DISABLE)
        GUICtrlSetState($g_idClear, $GUI_DISABLE)
        GUICtrlSetState($g_idList, $GUI_DISABLE)
        GUICtrlSetState($g_idUseCat, $GUI_DISABLE)
        GUICtrlSetState($g_idUseXunlei, $GUI_DISABLE)
        GUICtrlSetState($g_idCatSearchCount, $GUI_DISABLE)
        GUICtrlSetState($g_idXunleiSearchCount, $GUI_DISABLE)
    Else
        GUICtrlSetState($g_idBatchStop, $GUI_HIDE)
        GUICtrlSetState($g_idBatchSearch, $GUI_SHOW)
        GUICtrlSetState($g_idBatchDownload, $GUI_SHOW)
        GUICtrlSetState($g_idTitle, $GUI_ENABLE)
        GUICtrlSetState($g_idSearch, $GUI_ENABLE)
        GUICtrlSetState($g_idBrowseVideo, $GUI_ENABLE)
        GUICtrlSetState($g_idBatchFolder, $GUI_ENABLE)
        GUICtrlSetState($g_idBrowseBatchFolder, $GUI_ENABLE)
        GUICtrlSetState($g_idSaveDir, $GUI_ENABLE)
        GUICtrlSetState($g_idBrowseDir, $GUI_ENABLE)
        GUICtrlSetState($g_idOpenDir, $GUI_ENABLE)
        GUICtrlSetState($g_idDownload, $GUI_ENABLE)
        GUICtrlSetState($g_idOpenPage, $GUI_ENABLE)
        GUICtrlSetState($g_idClear, $GUI_ENABLE)
        GUICtrlSetState($g_idList, $GUI_ENABLE)
        GUICtrlSetState($g_idUseCat, $GUI_ENABLE)
        GUICtrlSetState($g_idUseXunlei, $GUI_ENABLE)
        GUICtrlSetState($g_idCatSearchCount, $GUI_ENABLE)
        GUICtrlSetState($g_idXunleiSearchCount, $GUI_ENABLE)
        If $g_bBatchSearchComplete And _CountPendingBatchDownloads() > 0 Then
            GUICtrlSetState($g_idBatchDownload, $GUI_ENABLE)
        Else
            GUICtrlSetState($g_idBatchDownload, $GUI_DISABLE)
        EndIf
    EndIf
EndFunc

Func _PumpBackgroundMessages()
    Local $iMsg = GUIGetMsg()
    Switch $iMsg
        Case $GUI_EVENT_CLOSE
            $g_bCloseRequested = True
            $g_bCancelBatch = True
            _SetStatus("正在取消当前操作并关闭窗口...")
        Case $g_idBatchStop
            $g_bCancelBatch = True
            _SetStatus("正在停止批量任务，请等待当前网络请求结束...")
    EndSwitch
EndFunc

Func _CollectVideoFiles($sFolder, ByRef $aFiles)
    If $g_bCancelBatch Then Return
    Local $hSearch = FileFindFirstFile($sFolder & "\*")
    If $hSearch = -1 Then Return

    Local $iVisited = 0
    While 1
        Local $sName = FileFindNextFile($hSearch)
        If @error Then ExitLoop
        If $sName = "." Or $sName = ".." Then ContinueLoop

        $iVisited += 1
        If Mod($iVisited, 50) = 0 Then
            _SetStatus("正在扫描目录：已发现 " & $g_iScanFileCount & " 个视频文件；当前位置：" & $sFolder)
            _PumpBackgroundMessages()
            If $g_bCancelBatch Then ExitLoop
        EndIf

        Local $sFullPath = $sFolder & "\" & $sName
        Local $sAttrib = FileGetAttrib($sFullPath)
        If @error Then ContinueLoop

        If StringInStr($sAttrib, "D") > 0 Then
            ; 跳过目录联接 / 符号链接，避免递归环路。
            If StringInStr($sAttrib, "L") = 0 Then _CollectVideoFiles($sFullPath, $aFiles)
        Else
            If _IsVideoExtension(_GetFileExtension($sName)) Then
                If $g_iScanFileCount >= $g_iScanFileCapacity Then
                    $g_iScanFileCapacity *= 2
                    ReDim $aFiles[$g_iScanFileCapacity]
                EndIf
                $aFiles[$g_iScanFileCount] = $sFullPath
                $g_iScanFileCount += 1
            EndIf
        EndIf
        If $g_bCancelBatch Then ExitLoop
    WEnd
    FileClose($hSearch)
EndFunc

Func _GetFileExtension($sFileName)
    Local $iDot = StringInStr($sFileName, ".", 0, -1)
    If $iDot <= 0 Then Return ""
    Return StringLower(StringTrimLeft($sFileName, $iDot))
EndFunc

Func _GetFileBaseName($sPath)
    Local $sName = _GetFileName($sPath)
    Local $iDot = StringInStr($sName, ".", 0, -1)
    If $iDot > 0 Then Return StringLeft($sName, $iDot - 1)
    Return $sName
EndFunc

Func _SourceSummary($bCat, $iCat, $bXunlei, $iXunlei)
    Local $s = ""
    If $bCat Then $s &= "SubtitleCat：" & $iCat & " 条" & @CRLF
    If $bXunlei Then $s &= "迅雷：" & $iXunlei & " 条"
    Return $s
EndFunc

Func _SearchSubtitleCat($sTitle, $iSearchCount = 5, $iDetailTimeout = 6000)
    Local $sURL = $SITE_URL & "/index.php?search=" & _UrlEncodeUTF8($sTitle)
    Local $iStatus = 0
    Local $sError = ""
    _SetStatus("正在请求 SubtitleCat 搜索页...")
    Local $sHTML = _HttpGetText($sURL, $iStatus, $sError)
    If $sHTML = "" Or $iStatus < 200 Or $iStatus >= 300 Then
        _SetStatus("SubtitleCat 暂不可用，继续搜索迅雷...")
        Return 0
    EndIf

    ; 搜索页链接形如 href="subs/xxxx.html"。不设原始详情页检查数量上限；
    ; 逐个检查，直到收录数量达到下拉框设定值，或搜索页中的详情链接全部检查完毕。
    Local $aCandidates[64][2]
    Local $iCandidateCount = 0
    Local $iCandidateCapacity = 64
    Local $iPos = 1
    While 1
        If $g_bCancelBatch Then ExitLoop
        Local $iFound = StringInStr($sHTML, "href=" & Chr(34) & "subs/", 0, 1, $iPos)
        If $iFound = 0 Then ExitLoop

        Local $iHrefStart = $iFound + 6
        Local $iHrefEnd = StringInStr($sHTML, Chr(34), 0, 1, $iHrefStart)
        If $iHrefEnd = 0 Then ExitLoop

        Local $sHref = StringMid($sHTML, $iHrefStart, $iHrefEnd - $iHrefStart)
        Local $iTagEnd = StringInStr($sHTML, ">", 0, 1, $iHrefEnd)
        If $iTagEnd = 0 Then
            $iPos = $iHrefEnd + 1
            ContinueLoop
        EndIf
        Local $iTextEnd = StringInStr($sHTML, "</a>", 0, 1, $iTagEnd + 1)
        If $iTextEnd = 0 Then
            $iPos = $iHrefEnd + 1
            ContinueLoop
        EndIf

        Local $sSubTitle = StringMid($sHTML, $iTagEnd + 1, $iTextEnd - $iTagEnd - 1)
        $sSubTitle = _HtmlDecode(StringRegExpReplace($sSubTitle, "(?is)<[^>]*>", ""))
        $sSubTitle = StringStripWS($sSubTitle, 3)
        If $sHref <> "" And $sSubTitle <> "" Then
            If $iCandidateCount >= $iCandidateCapacity Then
                $iCandidateCapacity *= 2
                ReDim $aCandidates[$iCandidateCapacity][2]
            EndIf
            $aCandidates[$iCandidateCount][0] = $sHref
            $aCandidates[$iCandidateCount][1] = $sSubTitle
            $iCandidateCount += 1
        EndIf
        $iPos = $iHrefEnd + 1
    WEnd

    If $iCandidateCount = 0 Then Return 0
    ReDim $aCandidates[$iCandidateCount][2]

    Local $iAdded = 0
    Local $iChecked = 0
    For $i = 0 To $iCandidateCount - 1
        If $g_bCancelBatch Then ExitLoop
        If $iAdded >= $iSearchCount Then ExitLoop
        $iChecked += 1
        _SetStatus("检查 SubtitleCat 字幕详情：已检查 " & $iChecked & " 个；有效收录 " & $iAdded & "/" & $iSearchCount)
        Local $sDetailURL = $SITE_URL & "/" & $aCandidates[$i][0]
        Local $iDetailStatus = 0
        Local $sDetailError = ""
        Local $sDetailHTML = _HttpGetText($sDetailURL, $iDetailStatus, $sDetailError, $iDetailTimeout)
        If $sDetailHTML = "" Or $iDetailStatus < 200 Or $iDetailStatus >= 300 Then ContinueLoop

        Local $sLang = ""
        ; 仅接受简体中文字幕轨；不再检查或收录繁体中文。
        If StringInStr($sDetailHTML, "-zh-CN.srt") > 0 Then $sLang = "zh-CN"
        If $sLang = "" Then ContinueLoop

        Local $sSubtitleURL = _FindSubtitleCatFileURL($sDetailHTML, $sLang)
        ; 没有提取到真实 HTTP(S) 字幕直链的项目不收录，也不占用搜索数量。
        If Not _IsHttpURL($sSubtitleURL) Then ContinueLoop
        ; 同一视频、同一来源的重复下载地址不重复收录，也不占用搜索数量。
        If _ResultURLExists("SubtitleCat", $sSubtitleURL) Then ContinueLoop

        Local $iSubtitleSize = -1
        If $g_iListViewRows < $BATCH_LISTVIEW_LIMIT Then $iSubtitleSize = _GetRemoteFileSize($sSubtitleURL)
        _AddResult($aCandidates[$i][1], "SubtitleCat", $sLang, "srt", $aCandidates[$i][0], _SafeFileName($aCandidates[$i][1]) & ".srt", $sSubtitleURL, $iSubtitleSize)
        $iAdded += 1
    Next
    Return $iAdded
EndFunc

Func _SearchXunlei($sTitle, $iSearchCount = 5)
    Local $sURL = $XUNLEI_API_URL & "?gcid=&cid=&name=" & _UrlEncodeUTF8($sTitle)
    Local $iStatus = 0
    Local $sError = ""
    _SetStatus("正在请求迅雷字幕库...")
    Local $sJSON = _HttpGetText($sURL, $iStatus, $sError)
    If $sJSON = "" Or $iStatus < 200 Or $iStatus >= 300 Then Return 0

    Local $sData = _JsonExtractArray($sJSON, "data")
    If $sData = "" Then Return 0
    Local $aObjects = _JsonSplitObjects($sData)
    Local $iAdded = 0

    For $i = 0 To UBound($aObjects) - 1
        If $g_bCancelBatch Then ExitLoop
        If $iSearchCount > 0 And $iAdded >= $iSearchCount Then ExitLoop
        Local $sDownloadURL = _JsonGetString($aObjects[$i], "url")
        Local $sExt = _JsonGetString($aObjects[$i], "ext")
        Local $sName = _JsonGetString($aObjects[$i], "name")
        ; 若迅雷接口返回语言字段，则过滤明确标记为繁体中文的候选。
        Local $sApiLanguage = _JsonGetString($aObjects[$i], "lang")
        If $sApiLanguage = "" Then $sApiLanguage = _JsonGetString($aObjects[$i], "language")
        If StringRegExp($sApiLanguage, "(?i)(zh[-_ ]?tw|zh[-_ ]?hant|traditional|繁体)") Then ContinueLoop
        If Not _IsHttpURL($sDownloadURL) Or $sExt = "" Then ContinueLoop
        If _ResultURLExists("迅雷", $sDownloadURL) Then ContinueLoop

        $sExt = StringRegExpReplace($sExt, "^\.", "")
        If Not StringRegExp($sExt, "(?i)^[a-z0-9]{1,8}$") Then ContinueLoop
        If $sName = "" Then $sName = $sTitle
        If StringLower(StringRight($sName, StringLen("." & $sExt))) = StringLower("." & $sExt) Then
            $sName = StringLeft($sName, StringLen($sName) - StringLen("." & $sExt))
        EndIf

        Local $sDisplayName = $sName & "（迅雷）"
        Local $iXunleiSize = -1
        If $g_iListViewRows < $BATCH_LISTVIEW_LIMIT Then $iXunleiSize = _GetRemoteFileSize($sDownloadURL)
        _AddResult($sDisplayName, "迅雷", "zh-CN", StringLower($sExt), $sDownloadURL, $sDisplayName & "." & StringLower($sExt), $sDownloadURL, $iXunleiSize)
        $iAdded += 1
    Next
    Return $iAdded
EndFunc

Func _IsHttpURL($sURL)
    $sURL = StringStripWS($sURL, 3)
    If $sURL = "" Then Return False
    Return (StringLeft(StringLower($sURL), 7) = "http://" Or StringLeft(StringLower($sURL), 8) = "https://")
EndFunc

Func _ResultURLExists($sSource, $sDirectURL)
    ; 仅在同一视频、同一字幕来源内去重；批量目录中的不同视频不互相影响。
    Local $sCurrentURL = StringStripWS($sDirectURL, 3)
    Local $iStart = $g_iCurrentVideoFirstResult
    If $iStart < 0 Or $iStart > $g_iResultCount Then $iStart = 0
    For $i = $iStart To $g_iResultCount - 1
        If $g_aResults[$i][1] <> $sSource Then ContinueLoop
        If $g_aResults[$i][6] <> $g_sCurrentVideoPath Then ContinueLoop
        ; URL 路径区分大小写，因此只去除首尾空白，不把整条 URL 转为小写。
        If StringStripWS($g_aResults[$i][7], 3) = $sCurrentURL Then Return True
    Next
    Return False
EndFunc

Func _AddResult($sTitle, $sSource, $sLang, $sFormat, $sURL, $sFileName, $sDirectURL = "", $iFileSize = -1)
    If $g_iResultCount >= $g_iResultCapacity Then
        Local $iNewCapacity = 64
        If $g_iResultCapacity > 0 Then $iNewCapacity = $g_iResultCapacity * 2
        ReDim $g_aResults[$iNewCapacity][10]
        $g_iResultCapacity = $iNewCapacity
    EndIf
    Local $iIndex = $g_iResultCount
    $g_iResultCount += 1
    $g_aResults[$iIndex][0] = $sTitle
    $g_aResults[$iIndex][1] = $sSource
    $g_aResults[$iIndex][2] = $sLang
    $g_aResults[$iIndex][3] = $sFormat
    $g_aResults[$iIndex][4] = $sURL
    $g_aResults[$iIndex][5] = $sFileName
    $g_aResults[$iIndex][6] = $g_sCurrentVideoPath
    $g_aResults[$iIndex][7] = $sDirectURL
    $g_aResults[$iIndex][8] = $iFileSize
    $g_aResults[$iIndex][9] = 0

    ; 限制界面控件行数，但保留完整候选数组，供后续独立的“批量下载”使用。
    If $g_bBatchRunning And $g_iListViewRows >= $BATCH_LISTVIEW_LIMIT Then
        $g_iBatchHiddenResultCount += 1
        Return
    EndIf

    Local $sLangText = "简体中文"
    Local $sDisplayTitle = StringReplace($sTitle, "|", "｜")
    Local $sVideoName = "手动搜索"
    If $g_sCurrentVideoPath <> "" Then $sVideoName = _GetFileName($g_sCurrentVideoPath)
    GUICtrlCreateListViewItem($sVideoName & "|" & $sDisplayTitle & "|" & $sSource & "|" & $sLangText & "|" & StringUpper($sFormat) & "|" & _FormatFileSize($iFileSize), $g_idList)
    Local $iRow = _GUICtrlListView_GetItemCount($g_hList) - 1
    If $iRow >= 0 Then _RegisterListRowResult($iRow, $iIndex)
    $g_iListViewRows += 1
EndFunc

Func _RegisterListRowResult($iRow, $iResultIndex)
    If $iRow < 0 Then Return False
    If $iRow >= $g_iListRowMapCapacity Then
        Local $iNewCapacity = 64
        If $g_iListRowMapCapacity > 0 Then $iNewCapacity = $g_iListRowMapCapacity
        While $iNewCapacity <= $iRow
            $iNewCapacity *= 2
        WEnd
        ReDim $g_aListRowResultIndex[$iNewCapacity]
        $g_iListRowMapCapacity = $iNewCapacity
    EndIf
    $g_aListRowResultIndex[$iRow] = $iResultIndex
    If $iRow >= $g_iListRowMapCount Then $g_iListRowMapCount = $iRow + 1
    Return True
EndFunc

Func _GetResultIndexForListRow($iRow)
    If $iRow < 0 Or $iRow >= $g_iListRowMapCount Then Return -1
    Local $iResultIndex = Int($g_aListRowResultIndex[$iRow])
    If $iResultIndex < 0 Or $iResultIndex >= $g_iResultCount Then Return -1
    Return $iResultIndex
EndFunc

; --------------------------------- 下载 -------------------------------------

Func _DownloadSelected()
    $g_bCancelBatch = False

    ; GetSelectedIndices 返回 [0]=选中数量、[1..n]=列表行索引。
    ; 使用控件 ID，不再通过 ListView 的 lParam 保存业务索引。
    Local $aSelectedRows = _GUICtrlListView_GetSelectedIndices($g_idList, True)
    If Not IsArray($aSelectedRows) Then
        MsgBox($MB_ICONWARNING, $APP_TITLE, "无法读取列表选择状态，请重新选择字幕。")
        Return
    EndIf
    Local $iSelectedCount = $aSelectedRows[0]
    If $iSelectedCount <= 0 Then
        MsgBox($MB_ICONINFORMATION, $APP_TITLE, "请先在结果列表中选择一条或多条字幕。")
        Return
    EndIf

    Local $sSaveDir = StringStripWS(GUICtrlRead($g_idSaveDir), 3)
    If $sSaveDir = "" Then
        MsgBox($MB_ICONWARNING, $APP_TITLE, "请设置字幕保存目录。")
        Return
    EndIf
    If Not FileExists($sSaveDir) Then DirCreate($sSaveDir)
    If Not FileExists($sSaveDir) Then
        MsgBox($MB_ICONERROR, $APP_TITLE, "无法创建保存目录：" & $sSaveDir)
        Return
    EndIf

    Local $iSuccess = 0
    Local $iFailed = 0
    Local $sErrors = ""
    Local $iProcessed = 0
    For $i = 1 To $iSelectedCount
        If $g_bCancelBatch Or $g_bCloseRequested Then ExitLoop

        Local $iRow = $aSelectedRows[$i]
        $iProcessed += 1
        Local $iIndex = _GetResultIndexForListRow($iRow)
        If $iIndex < 0 Then
            $iFailed += 1
            If $iFailed <= 10 Then $sErrors &= "列表第 " & ($iRow + 1) & " 行：无法关联到字幕搜索结果。" & @CRLF
            ContinueLoop
        EndIf

        Local $sError = ""
        _SetStatus("正在下载所选字幕 " & $i & "/" & $iSelectedCount & "：" & $g_aResults[$iIndex][0])
        If _DownloadResult($iIndex, $sSaveDir, "", ($iSelectedCount > 1), $sError) Then
            $iSuccess += 1
        Else
            $iFailed += 1
            If $iFailed <= 10 Then $sErrors &= $g_aResults[$iIndex][0] & "：" & $sError & @CRLF
        EndIf
    Next

    If $iSelectedCount = 1 And $iSuccess = 1 Then
        Local $iOpen = MsgBox(BitOR($MB_ICONINFORMATION, $MB_YESNO), $APP_TITLE, "字幕已下载。" & @CRLF & "是否打开保存目录？")
        If $iOpen = $IDYES Then ShellExecute($sSaveDir)
    Else
        Local $sSummary = "所选字幕下载处理完成。" & @CRLF & @CRLF & _
                "选中：" & $iSelectedCount & " 条" & @CRLF & _
                "已处理：" & $iProcessed & " 条" & @CRLF & _
                "成功：" & $iSuccess & " 条" & @CRLF & _
                "失败：" & $iFailed & " 条"
        If $g_bCancelBatch Then $sSummary &= @CRLF & "任务已停止。"
        If $sErrors <> "" Then $sSummary &= @CRLF & @CRLF & "失败详情（最多显示 10 项）：" & @CRLF & $sErrors
        MsgBox($MB_ICONINFORMATION, $APP_TITLE, $sSummary)
    EndIf
    _SetStatus("所选字幕处理完成：成功 " & $iSuccess & " 条，失败 " & $iFailed & " 条。")
EndFunc

Func _DownloadResult($iIndex, $sSaveDir, $sOverrideBase, $bAvoidOverwrite, ByRef $sError)
    $sError = ""
    If $iIndex < 0 Or $iIndex >= $g_iResultCount Then
        $sError = "无效的字幕结果索引。"
        Return False
    EndIf

    Local $sFileName = ""
    If $sOverrideBase <> "" Then
        $sFileName = _SafeFileName($sOverrideBase)
        If $g_aResults[$iIndex][1] = "迅雷" Then $sFileName &= "（迅雷）"
        $sFileName &= "." & StringLower($g_aResults[$iIndex][3])
    Else
        $sFileName = _SafeFileName($g_aResults[$iIndex][5])
        If $sFileName = "" Then $sFileName = "subtitle." & $g_aResults[$iIndex][3]
    EndIf

    If $sFileName = "" Then $sFileName = "subtitle." & $g_aResults[$iIndex][3]
    Local $sTarget = $sSaveDir & "\" & $sFileName
    If $bAvoidOverwrite Then $sTarget = _GetUniqueTargetPath($sSaveDir, $sFileName)

    _SetStatus("正在下载：" & $sFileName)
    Local $vBody = Binary("")
    Local $iStatus = 0
    Local $sHTTPError = ""
    If $g_aResults[$iIndex][1] = "迅雷" Then
        Local $iBinaryTimeout = 12000
        If $g_bBatchRunning Then $iBinaryTimeout = 7000
        $vBody = _HttpGetBinary($g_aResults[$iIndex][4], $iStatus, $sHTTPError, $iBinaryTimeout)
    Else
        Local $iDetailTimeout = 8000
        Local $iSubtitleTimeout = 12000
        If $g_bBatchRunning Then
            $iDetailTimeout = 3000
            $iSubtitleTimeout = 7000
        EndIf
        $vBody = _DownloadSubtitleCat($g_aResults[$iIndex][4], $g_aResults[$iIndex][2], $iStatus, $sHTTPError, $iDetailTimeout, $iSubtitleTimeout, $g_aResults[$iIndex][7])
    EndIf

    If $iStatus < 200 Or $iStatus >= 300 Or BinaryLen($vBody) = 0 Then
        $sError = "HTTP " & $iStatus & " " & $sHTTPError
        Return False
    EndIf

    If Not _SaveBinary($vBody, $sTarget) Then
        $sError = "保存失败：" & $sTarget & " " & $g_sLastError
        Return False
    EndIf

    ; 使用本地落盘文件的准确大小校正搜索阶段获取的远程大小。
    Local $iSavedSize = FileGetSize($sTarget)
    If Not @error And $iSavedSize > 0 Then
        $g_aResults[$iIndex][8] = $iSavedSize
        _UpdateResultSizeInList($iIndex, $iSavedSize)
    EndIf
    ; 逐条记录下载状态。批量下载中同一视频的其他候选仍会继续下载。
    $g_aResults[$iIndex][9] = 1

    Return True
EndFunc

Func _GetUniqueTargetPath($sDir, $sFileName)
    Local $sTarget = $sDir & "\" & $sFileName
    If Not FileExists($sTarget) Then Return $sTarget

    Local $iDot = StringInStr($sFileName, ".", 0, -1)
    Local $sBase = $sFileName
    Local $sExt = ""
    If $iDot > 0 Then
        $sBase = StringLeft($sFileName, $iDot - 1)
        $sExt = StringTrimLeft($sFileName, $iDot - 1)
    EndIf

    Local $iSuffix = 2
    While FileExists($sDir & "\" & $sBase & " (" & $iSuffix & ")" & $sExt)
        $iSuffix += 1
    WEnd
    Return $sDir & "\" & $sBase & " (" & $iSuffix & ")" & $sExt
EndFunc

Func _DownloadSubtitleCat($sDetailPath, $sLang, ByRef $iStatus, ByRef $sError, $iDetailTimeout = 8000, $iBinaryTimeout = 12000, $sKnownFileURL = "")
    If $sKnownFileURL <> "" Then Return _HttpGetBinary($sKnownFileURL, $iStatus, $sError, $iBinaryTimeout)

    Local $sDetailURL = $SITE_URL & "/" & $sDetailPath
    Local $sHTML = _HttpGetText($sDetailURL, $iStatus, $sError, $iDetailTimeout)
    If $sHTML = "" Or $iStatus < 200 Or $iStatus >= 300 Then Return Binary("")

    Local $sFileURL = _FindSubtitleCatFileURL($sHTML, $sLang)
    If $sFileURL <> "" Then Return _HttpGetBinary($sFileURL, $iStatus, $sError, $iBinaryTimeout)

    $iStatus = 404
    $sError = "详情页中没有找到所选语言（" & $sLang & "）的 SRT 下载链接。"
    Return Binary("")
EndFunc

Func _FindSubtitleCatFileURL($sHTML, $sLang)
    ; 从详情页提取所选中文语言的实际 SRT 文件直链。
    Local $sNeedle = "href=" & Chr(34) & "/subs/"
    Local $iPos = 1
    While 1
        Local $iFound = StringInStr($sHTML, $sNeedle, 0, 1, $iPos)
        If $iFound = 0 Then ExitLoop
        Local $iURLStart = $iFound + 6
        Local $iURLEnd = StringInStr($sHTML, Chr(34), 0, 1, $iURLStart)
        If $iURLEnd = 0 Then ExitLoop
        Local $sPath = StringMid($sHTML, $iURLStart, $iURLEnd - $iURLStart)
        If StringInStr($sPath, "-" & $sLang & ".srt") > 0 Then Return $SITE_URL & $sPath
        $iPos = $iURLEnd + 1
    WEnd
    Return ""
EndFunc

; ----------------------------- 标题清理逻辑 ---------------------------------

Func _BuildSearchTitle($sInput)
    Local $sFileName = _GetFileName($sInput)
    Local $sTitle = _CleanTitle($sFileName)
    Local $aSeason = StringRegExp($sFileName, "(?i)S(\d{1,2})E(\d{1,3})", 1)
    If IsArray($aSeason) Then
        If UBound($aSeason) < 2 Then Return StringStripWS($sTitle, 3)
        Local $iSeason = Int($aSeason[0])
        Local $iEpisode = Int($aSeason[1])
        $sTitle = StringRegExpReplace($sTitle, "(?i)[ ._\-]*S\d{1,2}E\d{1,3}.*$", "")
        $sTitle = StringStripWS($sTitle, 3)
        If $sTitle <> "" Then $sTitle &= " "
        $sTitle &= "S" & StringFormat("%02d", $iSeason) & "E" & StringFormat("%02d", $iEpisode)
    EndIf
    Return StringStripWS($sTitle, 3)
EndFunc

Func _CleanTitle($sTitle)
    $sTitle = _HtmlDecode($sTitle)

    ; 先在原始文件名中识别 JAV 番号，允许番号出现在方括号、括号或其他后缀附近。
    Local $aRawCode = StringRegExp(StringUpper($sTitle), "(?i)(?:^|[^A-Z0-9])([A-Z]{3,4}-\d{3,5})(?:$|[^A-Z0-9])", 1)
    If IsArray($aRawCode) And UBound($aRawCode) > 0 Then Return StringUpper($aRawCode[0])

    ; 移除 [...] 及其中内容。
    $sTitle = StringRegExpReplace($sTitle, "\[[^\]]*\]", "")

    ; 移除网站前缀（第一个 @ 之前的部分）。
    Local $iAt = StringInStr($sTitle, "@")
    If $iAt > 0 Then $sTitle = StringTrimLeft($sTitle, $iAt)

    ; 移除已知视频扩展名。
    Local $iDot = StringInStr($sTitle, ".", 0, -1)
    If $iDot > 0 Then
        Local $sExt = StringLower(StringTrimLeft($sTitle, $iDot))
        If _IsVideoExtension($sExt) Then $sTitle = StringLeft($sTitle, $iDot - 1)
    EndIf

    ; 循环移除末尾清晰度 / 画质标签。
    While StringRegExp($sTitle, "(?i)(?:_|-)(?:4k|2k|8k|720p|1080p|2160p|480p|360p|hd|fhd|uhd|sd)$")
        $sTitle = StringRegExpReplace($sTitle, "(?i)(?:_|-)(?:4k|2k|8k|720p|1080p|2160p|480p|360p|hd|fhd|uhd|sd)$", "")
    WEnd

    $sTitle = StringRegExpReplace($sTitle, "[_\-]+$", "")
    $sTitle = StringStripWS($sTitle, 3)

    ; JAV 番号识别：文件名中出现 3-4 位英文字母 + 连字符 + 3-5 位数字时，视为番号。
    ; 示例：ssis-698 -> SSIS-698；abc-123 -> ABC-123。要求保留连字符，避免误判普通字母数字串。
    Local $aCode = StringRegExp(StringUpper($sTitle), "(?i)(?:^|[^A-Z0-9])([A-Z]{3,4}-\d{3,5})(?:$|[^A-Z0-9])", 1)
    If IsArray($aCode) And UBound($aCode) > 0 Then Return StringUpper($aCode[0])
    Return $sTitle
EndFunc

Func _IsVideoExtension($sExt)
    Return StringRegExp(StringLower($sExt), "^(mp4|mkv|avi|wmv|flv|webm|mov|ts|m2ts|rmvb|mpg|mpeg|divx|3gp|vob|asf|m4v|rm|ogm|ogv)$")
EndFunc

Func _GetFileName($sPath)
    Local $iSlash1 = StringInStr($sPath, "\", 0, -1)
    Local $iSlash2 = StringInStr($sPath, "/", 0, -1)
    Local $iSlash = $iSlash1
    If $iSlash2 > $iSlash Then $iSlash = $iSlash2
    If $iSlash > 0 Then Return StringTrimLeft($sPath, $iSlash)
    Return $sPath
EndFunc

Func _FormatFileSize($iBytes)
    If Not IsNumber($iBytes) Or $iBytes <= 0 Then Return "未知"
    If $iBytes < 1024 Then Return $iBytes & " B"
    If $iBytes < 1048576 Then Return StringFormat("%.1f KB", $iBytes / 1024)
    If $iBytes < 1073741824 Then Return StringFormat("%.2f MB", $iBytes / 1048576)
    Return StringFormat("%.2f GB", $iBytes / 1073741824)
EndFunc

Func _UpdateResultSizeInList($iResultIndex, $iBytes)
    If $iResultIndex < 0 Or $iResultIndex >= $g_iResultCount Then Return
    For $iRow = 0 To $g_iListRowMapCount - 1
        If $g_aListRowResultIndex[$iRow] = $iResultIndex Then
            _GUICtrlListView_SetItemText($g_hList, $iRow, _FormatFileSize($iBytes), 5)
            Return
        EndIf
    Next
EndFunc

Func _GetRemoteFileSize($sURL)
    ; 使用 HEAD 只读取响应头，不下载字幕主体；服务器不支持或未返回长度时显示“未知”。
    If StringLeft($sURL, 7) <> "http://" And StringLeft($sURL, 8) <> "https://" Then Return -1
    $g_sLastError = ""
    Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
    If Not IsObj($oHTTP) Then Return -1

    $oHTTP.Open("HEAD", $sURL, True)
    $oHTTP.SetTimeouts(500, 500, 700, 900)
    $oHTTP.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0 Safari/537.36")
    $oHTTP.SetRequestHeader("Accept", "*/*")
    $oHTTP.SetRequestHeader("Accept-Encoding", "identity")
    $oHTTP.Send()

    If Not _WaitForHttpResponse($oHTTP, 2200) Then Return -1
    Local $iStatus = $oHTTP.Status
    If $iStatus < 200 Or $iStatus >= 400 Then Return -1

    Local $sHeaders = $oHTTP.GetAllResponseHeaders()
    Local $aLength = StringRegExp($sHeaders, "(?im)^Content-Length:\s*(\d+)\s*$", 1)
    If IsArray($aLength) And UBound($aLength) > 0 Then
        Local $iLength = Number($aLength[0])
        If $iLength > 0 Then Return $iLength
    EndIf

    ; 部分 CDN 在 HEAD 响应中使用 Content-Range 提供对象总大小。
    Local $aRange = StringRegExp($sHeaders, "(?im)^Content-Range:.*?/(\d+)\s*$", 1)
    If IsArray($aRange) And UBound($aRange) > 0 Then
        Local $iRangeSize = Number($aRange[0])
        If $iRangeSize > 0 Then Return $iRangeSize
    EndIf
    Return -1
EndFunc

; -------------------------------- HTTP ---------------------------------------

Func _HttpGetText($sURL, ByRef $iStatus, ByRef $sError, $iReceiveTimeout = 8000)
    $iStatus = 0
    $sError = ""
    $g_sLastError = ""
    Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
    If Not IsObj($oHTTP) Then
        $sError = "无法创建 WinHTTP 请求对象。"
        Return ""
    EndIf

    $oHTTP.Open("GET", $sURL, True) ; 异步模式，等待期间持续处理窗口消息。
    $oHTTP.SetTimeouts(3000, 3000, 4000, $iReceiveTimeout)
    $oHTTP.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0 Safari/537.36")
    $oHTTP.SetRequestHeader("Accept", "text/html,application/json,text/plain,*/*")
    $oHTTP.Send()
    If Not _WaitForHttpResponse($oHTTP, 10000 + $iReceiveTimeout) Then
        If $g_bCancelBatch Then
            $sError = "用户取消。"
        Else
            $sError = $g_sLastError
            If $sError = "" Then $sError = "网络请求超时。"
        EndIf
        Return ""
    EndIf

    $iStatus = $oHTTP.Status
    If $iStatus >= 200 And $iStatus < 300 Then Return $oHTTP.ResponseText
    If $iStatus = 0 And $g_sLastError <> "" Then
        $sError = $g_sLastError
    Else
        $sError = "HTTP " & $iStatus
    EndIf
    Return ""
EndFunc

Func _HttpGetBinary($sURL, ByRef $iStatus, ByRef $sError, $iReceiveTimeout = 12000)
    $iStatus = 0
    $sError = ""
    $g_sLastError = ""
    Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
    If Not IsObj($oHTTP) Then
        $sError = "无法创建 WinHTTP 请求对象。"
        Return Binary("")
    EndIf

    $oHTTP.Open("GET", $sURL, True)
    $oHTTP.SetTimeouts(2500, 2500, 3000, $iReceiveTimeout)
    $oHTTP.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0 Safari/537.36")
    $oHTTP.SetRequestHeader("Accept", "*/*")
    $oHTTP.Send()
    If Not _WaitForHttpResponse($oHTTP, 8000 + $iReceiveTimeout) Then
        If $g_bCancelBatch Then
            $sError = "用户取消。"
        Else
            $sError = $g_sLastError
            If $sError = "" Then $sError = "下载请求超时。"
        EndIf
        Return Binary("")
    EndIf

    $iStatus = $oHTTP.Status
    If $iStatus >= 200 And $iStatus < 300 Then Return $oHTTP.ResponseBody
    If $iStatus = 0 And $g_sLastError <> "" Then
        $sError = $g_sLastError
    Else
        $sError = "HTTP " & $iStatus
    EndIf
    Return Binary("")
EndFunc

Func _WaitForHttpResponse(ByRef $oHTTP, $iMaxWaitMs)
    Local $hTimer = TimerInit()
    While 1
        _PumpBackgroundMessages()
        If $g_bCancelBatch Or $g_bCloseRequested Then
            $oHTTP.Abort()
            Return False
        EndIf

        Local $bReady = $oHTTP.WaitForResponse(1)
        If @error Then
            $g_sLastError = "等待 HTTP 响应失败。"
            Return False
        EndIf
        If $bReady Then Return True

        If TimerDiff($hTimer) > $iMaxWaitMs Then
            $oHTTP.Abort()
            $g_sLastError = "网络请求超时。"
            Return False
        EndIf
    WEnd
EndFunc

Func _SaveBinary($vData, $sPath)
    $g_sLastError = ""
    Local $oStream = ObjCreate("ADODB.Stream")
    If Not IsObj($oStream) Then
        $g_sLastError = "无法创建 ADODB.Stream 对象。"
        Return False
    EndIf

    $oStream.Type = 1 ; adTypeBinary
    $oStream.Open()
    $oStream.Write($vData)
    $oStream.SaveToFile($sPath, 2) ; adSaveCreateOverWrite
    $oStream.Close()
    Return FileExists($sPath) And FileGetSize($sPath) > 0
EndFunc

Func _UrlEncodeUTF8($sText)
    Local $bData = StringToBinary($sText, 4)
    Local $sHex = Hex($bData)
    If StringLeft($sHex, 2) = "0x" Then $sHex = StringTrimLeft($sHex, 2)
    Local $iBytes = BinaryLen($bData)
    Local $sOut = ""

    For $i = 1 To $iBytes
        Local $sByteHex = StringMid($sHex, ($i - 1) * 2 + 1, 2)
        Local $iByte = Dec($sByteHex)
        If ($iByte >= 48 And $iByte <= 57) Or ($iByte >= 65 And $iByte <= 90) Or _
                ($iByte >= 97 And $iByte <= 122) Or $iByte = 45 Or $iByte = 46 Or $iByte = 95 Or $iByte = 126 Then
            $sOut &= Chr($iByte)
        Else
            $sOut &= "%" & $sByteHex
        EndIf
    Next
    Return $sOut
EndFunc

; --------------------------- HTML / JSON 辅助 -------------------------------

Func _HtmlDecode($sText)
    $sText = StringReplace($sText, "&quot;", Chr(34))
    $sText = StringReplace($sText, "&#039;", "'")
    $sText = StringReplace($sText, "&#39;", "'")
    $sText = StringReplace($sText, "&lt;", "<")
    $sText = StringReplace($sText, "&gt;", ">")
    $sText = StringReplace($sText, "&rsquo;", "'")
    $sText = StringReplace($sText, "&nbsp;", " ")

    Local $aDec = StringRegExp($sText, "&#(\d{1,7});", 3)
    If IsArray($aDec) Then
        For $i = 0 To UBound($aDec) - 1
            $sText = StringReplace($sText, "&#" & $aDec[$i] & ";", ChrW(Int($aDec[$i])))
        Next
    EndIf
    Local $aHex = StringRegExp($sText, "(?i)&#x([0-9a-f]{1,6});", 3)
    If IsArray($aHex) Then
        For $i = 0 To UBound($aHex) - 1
            $sText = StringRegExpReplace($sText, "(?i)&#x" & $aHex[$i] & ";", ChrW(Dec($aHex[$i])))
        Next
    EndIf
    $sText = StringReplace($sText, "&amp;", "&")
    Return $sText
EndFunc

Func _JsonExtractArray($sJSON, $sKey)
    Local $sNeedle = Chr(34) & $sKey & Chr(34)
    Local $iKey = StringInStr($sJSON, $sNeedle)
    If $iKey = 0 Then Return ""
    Local $iOpen = StringInStr($sJSON, "[", 0, 1, $iKey + StringLen($sNeedle))
    If $iOpen = 0 Then Return ""

    Local $iDepth = 0
    Local $bInString = False
    Local $bEscape = False
    For $i = $iOpen To StringLen($sJSON)
        Local $c = StringMid($sJSON, $i, 1)
        If $bInString Then
            If $bEscape Then
                $bEscape = False
            ElseIf $c = "\" Then
                $bEscape = True
            ElseIf $c = Chr(34) Then
                $bInString = False
            EndIf
        Else
            If $c = Chr(34) Then
                $bInString = True
            ElseIf $c = "[" Then
                $iDepth += 1
            ElseIf $c = "]" Then
                $iDepth -= 1
                If $iDepth = 0 Then Return StringMid($sJSON, $iOpen + 1, $i - $iOpen - 1)
            EndIf
        EndIf
    Next
    Return ""
EndFunc

Func _JsonSplitObjects($sArray)
    Local $aObjects[0]
    Local $iDepth = 0
    Local $iStart = 0
    Local $bInString = False
    Local $bEscape = False

    For $i = 1 To StringLen($sArray)
        Local $c = StringMid($sArray, $i, 1)
        If $bInString Then
            If $bEscape Then
                $bEscape = False
            ElseIf $c = "\" Then
                $bEscape = True
            ElseIf $c = Chr(34) Then
                $bInString = False
            EndIf
        Else
            If $c = Chr(34) Then
                $bInString = True
            ElseIf $c = "{" Then
                If $iDepth = 0 Then $iStart = $i
                $iDepth += 1
            ElseIf $c = "}" Then
                $iDepth -= 1
                If $iDepth = 0 And $iStart > 0 Then
                    Local $n = UBound($aObjects)
                    ReDim $aObjects[$n + 1]
                    $aObjects[$n] = StringMid($sArray, $iStart, $i - $iStart + 1)
                    $iStart = 0
                EndIf
            EndIf
        EndIf
    Next
    Return $aObjects
EndFunc

Func _JsonGetString($sObject, $sKey)
    Local $q = Chr(34)
    Local $sPattern = $q & $sKey & $q & "\s*:\s*" & $q & "((?:\\.|[^" & $q & "\\])*)" & $q
    Local $aMatch = StringRegExp($sObject, $sPattern, 1)
    If Not IsArray($aMatch) Then Return ""
    If UBound($aMatch) = 0 Then Return ""
    Return _JsonUnescape($aMatch[0])
EndFunc

Func _JsonUnescape($sText)
    Local $sOut = ""
    Local $i = 1
    While $i <= StringLen($sText)
        Local $c = StringMid($sText, $i, 1)
        If $c <> "\" Or $i = StringLen($sText) Then
            $sOut &= $c
            $i += 1
            ContinueLoop
        EndIf

        Local $n = StringMid($sText, $i + 1, 1)
        Switch $n
            Case Chr(34)
                $sOut &= Chr(34)
                $i += 2
            Case "\"
                $sOut &= "\"
                $i += 2
            Case "/"
                $sOut &= "/"
                $i += 2
            Case "b"
                $sOut &= Chr(8)
                $i += 2
            Case "f"
                $sOut &= Chr(12)
                $i += 2
            Case "n"
                $sOut &= @LF
                $i += 2
            Case "r"
                $sOut &= @CR
                $i += 2
            Case "t"
                $sOut &= @TAB
                $i += 2
            Case "u"
                If $i + 5 <= StringLen($sText) Then
                    Local $sHex = StringMid($sText, $i + 2, 4)
                    If StringRegExp($sHex, "(?i)^[0-9a-f]{4}$") Then
                        $sOut &= ChrW(Dec($sHex))
                        $i += 6
                    Else
                        $sOut &= $c
                        $i += 1
                    EndIf
                Else
                    $sOut &= $c
                    $i += 1
                EndIf
            Case Else
                $sOut &= $n
                $i += 2
        EndSwitch
    WEnd
    Return $sOut
EndFunc

Func _SafeFileName($sName)
    $sName = StringRegExpReplace($sName, "[\\/:*?""<>|]", "_")
    $sName = StringStripWS($sName, 3)
    While StringLen($sName) > 0 And (StringRight($sName, 1) = "." Or StringRight($sName, 1) = " ")
        $sName = StringTrimRight($sName, 1)
    WEnd
    Return $sName
EndFunc
