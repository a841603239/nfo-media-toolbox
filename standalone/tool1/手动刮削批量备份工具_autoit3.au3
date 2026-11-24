#NoTrayIcon
#AutoIt3Wrapper_UseX64=n
; ==========================================================
; 手动刮削批量备份工具 - AutoIt3 版
; ==========================================================

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <File.au3>
#include <Array.au3>
#include <GuiEdit.au3>
#include <ProgressConstants.au3>
#include <StaticConstants.au3>
#include <EditConstants.au3>

Opt("GUIOnEventMode", 1)

; ==========================================================
; 全局变量
; ==========================================================
Global $g_hGUI

; 控件 ID
Global $g_idSource, $g_idTarget
Global $g_idChkNfo, $g_idChkActor, $g_idChkImage, $g_idChkTree
Global $g_idProgress, $g_idProgressLabel
Global $g_idLog, $g_idStart

; 备份状态
Global $g_bRunning = False
Global $g_aFileList[1]        ; [0]=count, [1..n]=full source path
Global $g_iFileCount = 0
Global $g_iCurrentIndex = 1   ; 当前复制到的索引
Global $g_iTotalFiles = 0
Global $g_iCopiedFiles = 0

; 备份参数
Global $g_sSourceDir = ""
Global $g_sTargetDir = ""
Global $g_bExcludeNfo = False
Global $g_bExcludeActor = False
Global $g_bExcludeImage = False
Global $g_bExportTree = False

; 每轮循环复制的文件数（平衡响应性与速度）
Global Const $BATCH_SIZE = 10

; ==========================================================
; 入口
; ==========================================================
Main()

; ==========================================================
; 主函数 - 构建 GUI
; ==========================================================
Func Main()
    $g_hGUI = GUICreate("手动刮削资源备份工具", 700, 650, -1, -1)
    GUISetOnEvent($GUI_EVENT_CLOSE, "_OnClose")

    ; --- 标题 ---
    GUICtrlCreateLabel("手动刮削资源备份工具", 0, 15, 700, 35, $SS_CENTER)
    GUICtrlSetFont(-1, 16, 800, 0, "Microsoft YaHei")
    GUICtrlSetColor(-1, 0x2196F3)

    ; 分隔线
    GUICtrlCreateLabel("", 20, 55, 660, 2, $SS_ETCHEDHORZ)

    ; --- 目录设置 ---
    GUICtrlCreateGroup("目录设置", 20, 70, 660, 110)

    GUICtrlCreateLabel("源目录：", 35, 100, 80, 25)
    $g_idSource = GUICtrlCreateInput("", 115, 97, 490, 28)
    GUICtrlSetTip($g_idSource, "选择要备份的源文件夹...")
    Local $idBtnSource = GUICtrlCreateButton("浏览...", 615, 97, 55, 28)
    GUICtrlSetOnEvent($idBtnSource, "_SelectSource")

    GUICtrlCreateLabel("目标目录：", 35, 140, 80, 25)
    $g_idTarget = GUICtrlCreateInput("", 115, 137, 490, 28)
    GUICtrlSetTip($g_idTarget, "选择备份保存的目标文件夹...")
    Local $idBtnTarget = GUICtrlCreateButton("浏览...", 615, 137, 55, 28)
    GUICtrlSetOnEvent($idBtnTarget, "_SelectTarget")

    ; --- 备份选项 ---
    GUICtrlCreateGroup("备份选项", 20, 195, 660, 165)

    $g_idChkNfo = GUICtrlCreateCheckbox("排除 .nfo 文件", 35, 225, 200, 25)
    GUICtrlSetTip($g_idChkNfo, "排除所有 .nfo 文件")
    GUICtrlSetState($g_idChkNfo, $GUI_CHECKED)

    $g_idChkActor = GUICtrlCreateCheckbox("排除 .actors 文件夹", 35, 255, 200, 25)
    GUICtrlSetTip($g_idChkActor, "排除所有 .actors 的文件夹及其内容")
    GUICtrlSetState($g_idChkActor, $GUI_CHECKED)

    $g_idChkImage = GUICtrlCreateCheckbox("排除图片文件", 35, 285, 250, 25)
    GUICtrlSetTip($g_idChkImage, "排除所有 .png、.jpg、.jpeg、.tga、.webp 等常见图片格式")
    GUICtrlSetState($g_idChkImage, $GUI_UNCHECKED)

    $g_idChkTree = GUICtrlCreateCheckbox("备份完成后导出目录树", 35, 315, 250, 25)
    GUICtrlSetTip($g_idChkTree, "备份完成后将目录结构保存为目标目录下的 目录树.txt")
    GUICtrlSetState($g_idChkTree, $GUI_UNCHECKED)

    ; --- 进度条 ---
    $g_idProgress = GUICtrlCreateProgress(20, 375, 660, 25, $PBS_SMOOTH)
    $g_idProgressLabel = GUICtrlCreateLabel("就绪", 20, 403, 660, 20, $SS_CENTER)
    GUICtrlSetColor($g_idProgressLabel, 0x666666)

    ; --- 操作日志 ---
    GUICtrlCreateGroup("操作日志", 20, 425, 660, 135)
    $g_idLog = GUICtrlCreateEdit("", 30, 450, 640, 100, _
        BitOR($ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL, $ES_MULTILINE))
    GUICtrlSetFont($g_idLog, 10, 400, 0, "Consolas")
    GUICtrlSetBkColor($g_idLog, 0xFAFAFA)

    ; --- 开始按钮 ---
    $g_idStart = GUICtrlCreateButton("开始备份", 270, 580, 160, 42)
    GUICtrlSetFont($g_idStart, 12, 800, 0, "Microsoft YaHei")
    GUICtrlSetBkColor($g_idStart, 0x4CAF50)
    GUICtrlSetColor($g_idStart, 0xFFFFFF)
    GUICtrlSetOnEvent($g_idStart, "_StartBackup")

    GUISetState(@SW_SHOW)

    ; --- 主循环 ---
    While 1
        Sleep(10)
        If $g_bRunning Then
            _ProcessBackupBatch()
        EndIf
    WEnd
EndFunc

; ==========================================================
; 事件处理
; ==========================================================

Func _OnClose()
    If $g_bRunning Then
        ; MB_YESNO(4) | MB_ICONQUESTION(0x20) | MB_DEFBUTTON2(0x100) = 0x124
        If MsgBox(0x124, "确认", "备份正在进行中，确定要退出吗？") = 6 Then Exit
    Else
        Exit
    EndIf
EndFunc

Func _SelectSource()
    Local $sPath = FileSelectFolder("选择源文件夹", "")
    If $sPath <> "" Then GUICtrlSetData($g_idSource, $sPath)
EndFunc

Func _SelectTarget()
    Local $sPath = FileSelectFolder("选择目标文件夹", "")
    If $sPath <> "" Then GUICtrlSetData($g_idTarget, $sPath)
EndFunc

Func _StartBackup()
    Local $sSource = GUICtrlRead($g_idSource)
    Local $sTarget = GUICtrlRead($g_idTarget)

    ; 校验输入
    If $sSource = "" Or $sTarget = "" Then
        _LogAppend("错误：请先设置源目录和目标目录")
        Return
    EndIf

    If Not FileExists($sSource) Then
        _LogAppend("错误：源目录不存在")
        Return
    EndIf

    ; 规范化路径（去掉末尾反斜杠）
    $g_sSourceDir = StringRegExpReplace($sSource, "\\+$", "")
    $g_sTargetDir = StringRegExpReplace($sTarget, "\\+$", "")

    ; 源目录 = 目标目录
    If StringLower($g_sSourceDir) = StringLower($g_sTargetDir) Then
        _LogAppend("错误：源目录和目标目录不能相同")
        Return
    EndIf

    ; 读取选项
    $g_bExcludeNfo = (GUICtrlRead($g_idChkNfo) = $GUI_CHECKED)
    $g_bExcludeActor = (GUICtrlRead($g_idChkActor) = $GUI_CHECKED)
    $g_bExcludeImage = (GUICtrlRead($g_idChkImage) = $GUI_CHECKED)
    $g_bExportTree = (GUICtrlRead($g_idChkTree) = $GUI_CHECKED)

    ; 禁用按钮，清空日志
    GUICtrlSetState($g_idStart, $GUI_DISABLE)
    GUICtrlSetData($g_idStart, "备份中...")
    GUICtrlSetData($g_idLog, "")
    _LogAppend("任务已启动...")

    ; 递归收集文件
    _LogAppend("正在统计文件...")
    $g_iFileCount = 0
    ReDim $g_aFileList[1000]   ; 初始容量 1000，不足时自动扩容

    _CollectFiles($g_sSourceDir)

    ; 裁剪数组到实际大小
    ReDim $g_aFileList[$g_iFileCount + 1]
    $g_aFileList[0] = $g_iFileCount
    $g_iTotalFiles = $g_iFileCount
    $g_iCurrentIndex = 1
    $g_iCopiedFiles = 0

    If $g_iTotalFiles = 0 Then
        _LogAppend("没有找到需要备份的文件。")
        _FinishBackup()
        Return
    EndIf

    _LogAppend("共发现 " & $g_iTotalFiles & " 个文件，开始备份...")
    GUICtrlSetLimit($g_idProgress, 100, 0)
    GUICtrlSetData($g_idProgress, 0)
    GUICtrlSetData($g_idProgressLabel, "0 / " & $g_iTotalFiles & "  (0%)")

    $g_bRunning = True
EndFunc

; ==========================================================
; 递归收集文件（对应 Python os.walk + 扩展名过滤）
; ==========================================================
Func _CollectFiles($sDir)
    Local $hSearch = FileFindFirstFile($sDir & "\*")
    If $hSearch = -1 Then Return

    While 1
        Local $sFile = FileFindNextFile($hSearch)
        Local $iErr = @error
        Local $iExt = @extended
        If $iErr Then ExitLoop

        ; @extended=1 表示目录
        If $iExt = 1 Then
            ; 排除 .actors 文件夹
            If $g_bExcludeActor And $sFile = ".actors" Then ContinueLoop
            _CollectFiles($sDir & "\" & $sFile)
        Else
            ; 获取扩展名（含点，小写）
            Local $iDotPos = StringInStr($sFile, ".", 0, -1)
            Local $sExt = ""
            If $iDotPos > 0 Then
                $sExt = StringLower(StringMid($sFile, $iDotPos))
            EndIf

            ; 始终排除视频文件
            If $sExt = ".mp4" Or $sExt = ".mkv" Then ContinueLoop

            ; 可选排除 .nfo
            If $g_bExcludeNfo And $sExt = ".nfo" Then ContinueLoop

            ; 可选排除常见图片文件
            If $g_bExcludeImage And _IsImageExtension($sExt) Then ContinueLoop

            ; 加入待复制列表
            $g_iFileCount += 1
            If $g_iFileCount >= UBound($g_aFileList) Then
                ReDim $g_aFileList[UBound($g_aFileList) * 2]
            EndIf
            $g_aFileList[$g_iFileCount] = $sDir & "\" & $sFile
        EndIf
    WEnd

    FileClose($hSearch)
EndFunc

Func _IsImageExtension($sExt)
    Switch $sExt
        Case ".png", ".jpg", ".jpeg", ".jfif", ".gif", ".bmp", ".tga", ".webp", ".tif", ".tiff", ".ico", ".heic", ".heif", ".avif", ".apng", ".svg"
            Return True
    EndSwitch
    Return False
EndFunc

; ==========================================================
; 分批复制（替代 QThread 后台线程）
; 每轮循环复制 BATCH_SIZE 个文件，期间 GUI 保持响应
; ==========================================================
Func _ProcessBackupBatch()
    Local $iBatch = 0

    While $iBatch < $BATCH_SIZE And $g_iCurrentIndex <= $g_iTotalFiles
        Local $sSrcFile = $g_aFileList[$g_iCurrentIndex]

        ; 计算相对路径 → 目标路径
        Local $sRelPath = StringTrimLeft($sSrcFile, StringLen($g_sSourceDir) + 1)
        Local $sDstFile = $g_sTargetDir & "\" & $sRelPath

        ; 复制（flag 9 = 覆盖 + 自动创建目录结构）
        If FileCopy($sSrcFile, $sDstFile, 9) Then
            $g_iCopiedFiles += 1
        Else
            _LogAppend("错误: " & $sRelPath & " - 复制失败")
        EndIf

        $g_iCurrentIndex += 1
        $iBatch += 1
    WEnd

    ; 更新进度条（使用百分比 0-100，避免大文件数时精度问题）
    Local $iPct = 0
    If $g_iTotalFiles > 0 Then
        $iPct = Round($g_iCopiedFiles / $g_iTotalFiles * 100)
    EndIf
    GUICtrlSetData($g_idProgress, $iPct)
    GUICtrlSetData($g_idProgressLabel, _
        $g_iCopiedFiles & " / " & $g_iTotalFiles & "  (" & $iPct & "%)")

    ; 全部完成
    If $g_iCurrentIndex > $g_iTotalFiles Then
        _LogAppend("备份完成！")
        If $g_bExportTree Then
            _ExportDirectoryTree()
        EndIf
        _FinishBackup()
    EndIf
EndFunc

; ==========================================================
; 导出目录树（对应 Python export_directory_tree）
; ==========================================================
Func _ExportDirectoryTree()
    _LogAppend("正在生成目录树...")
    Local $sTreeFile = $g_sTargetDir & "\目录树.txt"

    Local $hFile = FileOpen($sTreeFile, 2)   ; 2 = 覆盖写入
    If $hFile = -1 Then
        _LogAppend("导出目录树失败: 无法创建文件")
        Return
    EndIf

    FileWriteLine($hFile, "目录结构")
    FileWriteLine($hFile, "==================================================")
    FileWriteLine($hFile, "")

    _WriteTreeLevel($hFile, $g_sTargetDir, 0)

    FileClose($hFile)
    _LogAppend("目录树已导出到: " & $sTreeFile)
EndFunc

Func _WriteTreeLevel($hFile, $sDir, $iLevel)
    ; 缩进
    Local $sIndent = ""
    For $i = 1 To $iLevel
        $sIndent &= "  "
    Next

    ; 目录名
    Local $sDirName = StringMid($sDir, StringInStr($sDir, "\", 0, -1) + 1)
    FileWriteLine($hFile, $sIndent & $sDirName & "/")

    ; 列出文件（排序）
    Local $aFiles = _FileListToArray($sDir, "*", 1)
    If Not @error And IsArray($aFiles) Then
        _ArraySort($aFiles, 0, 1)
        Local $sSubIndent = $sIndent & "  "
        For $i = 1 To $aFiles[0]
            If $aFiles[$i] <> "目录树.txt" Then
                FileWriteLine($hFile, $sSubIndent & $aFiles[$i])
            EndIf
        Next
    EndIf

    ; 递归子目录
    Local $aDirs = _FileListToArray($sDir, "*", 2)
    If Not @error And IsArray($aDirs) Then
        For $i = 1 To $aDirs[0]
            If $g_bExcludeActor And $aDirs[$i] = ".actors" Then ContinueLoop
            _WriteTreeLevel($hFile, $sDir & "\" & $aDirs[$i], $iLevel + 1)
        Next
    EndIf
EndFunc

; ==========================================================
; 工具函数
; ==========================================================

Func _LogAppend($sMsg)
    _GUICtrlEdit_AppendText($g_idLog, $sMsg & @CRLF)
EndFunc

Func _FinishBackup()
    $g_bRunning = False
    GUICtrlSetState($g_idStart, $GUI_ENABLE)
    GUICtrlSetData($g_idStart, "开始备份")
    GUICtrlSetData($g_idProgress, 100)
    _LogAppend("任务结束。")
EndFunc
