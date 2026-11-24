#pragma compile(FileDescription, "NFO影视刮削工具箱 - 媒体文件管理辅助工具")
#pragma compile(CompanyName, "Sorin开发")
#pragma compile(LegalCopyright, "Copyright © 2026")
#pragma compile(FileVersion, 1.1.0.0)         ; 文件版本

#Region ;**** AutoIt3Wrapper directives ****
#AutoIt3Wrapper_Outfile=NFO影视刮削工具箱.exe
#AutoIt3Wrapper_Icon=icon.ico
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_ProductName=NFO影视刮削工具箱
; 强制关闭 UPX 压缩
#AutoIt3Wrapper_UseUpx = N
#EndRegion
; ==========================================================
; 四合一工具整合菜单 (GDI+ 自绘 UI) - DPI 修复版
; ----------------------------------------------------------
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GDIPlus.au3>
#include <File.au3>
#include <Array.au3>
#include <GuiEdit.au3>
#include <ProgressConstants.au3>
#include <StaticConstants.au3>
#include <EditConstants.au3>
#include <ListViewConstants.au3>
#include <ComboConstants.au3>
#include <GUIListView.au3>
#include <GuiComboBox.au3>
#include <StructureConstants.au3>
#include <FontConstants.au3>
#include <WinAPIHObj.au3>
#include <WinAPISysInternals.au3>
#include <ButtonConstants.au3>
#include <MsgBoxConstants.au3>
#Region ;**** 主启动器（四合一菜单） ****
; ==========================================================
; 窗口常量
; ==========================================================
Global Const $WIN_W = 1366
Global Const $WIN_H = 768
Global Const $CARD_W = 310
Global Const $CARD_H = 600
Global Const $CARD_X0 = 28
Global Const $CARD_Y0 = 110
Global Const $CARD_GAP = 15
Global Const $CARD_R = 12

; GDI+ StringAlignment 枚举
Global Const $SA_NEAR = 0
Global Const $SA_CENTER = 1

; ==========================================================
; 配色（ARGB）
; ==========================================================
Global Const $CLR_BG_TOP = 0xFFF5F7FC
Global Const $CLR_BG_BOTTOM = 0xFFE9EDF5
Global Const $CLR_CARD = 0xFFFFFFFF
Global Const $CLR_TEXT_MAIN = 0xFF1B2534
Global Const $CLR_TEXT_SUB = 0xFF55637A
Global Const $CLR_DIVIDER = 0xFFEDF1F7
Global Const $CLR_CARD_BORDER = 0xFFE2E7EF
Global Const $CLR_SHADOW = 0x16000000
Global Const $CLR_SHADOW_HOVER = 0x2B000000

; 四个工具的主色
Global Const $ACCENT_1 = 0xFF2F6FED ; 蓝 - 备份工具
Global Const $ACCENT_2 = 0xFF6D28D9 ; 紫 - NFO 编辑器
Global Const $ACCENT_3 = 0xFF0E9F6E ; 绿 - 命名模板
Global Const $ACCENT_4 = 0xFFF05A28 ; 橙 - 中文字幕搜索

; ==========================================================
; 工具注册表
; ==========================================================
Global Const $aTools[4][9] = [ _
    ["/tool1", "工具1手动刮削批量备份工具", $ACCENT_1, "手动刮削批量备份", "SCRAPER BACKUP TOOL", "将刮削资源（NFO / 图片 / actors）批量备份到指定目录，支持排除规则与目录树导出。", "批量备份", "排除规则", "目录树"], _
    ["/tool2", "工具2nfo编辑器", $ACCENT_2, "NFO 编辑器", "NFO EDITOR & TRANSLATOR", "查看与编辑 NFO 元数据，支持 DeepSeek AI 翻译、批量汉化与多文件批量处理。", "NFO 编辑", "AI 翻译", "批量汉化"], _
    ["/tool3", "工具3媒体命名模板速查", $ACCENT_3, "TMM刮削命名模板", "NAMING TEMPLATE REFERENCE", "电影 / 剧集命名模板速查，支持多语言模板与变量预览，一键复制到剪贴板；适用于 tinyMediaManager。", "规范命名", "命名模板", "一键复制"], _
    ["/tool4", "工具4在线中文字幕搜索下载", $ACCENT_4, "在线字幕搜索下载", "SUBTITLE SEARCH & DOWNLOAD", "搜索 SubtitleCat 与迅雷字幕库，支持简体中文字幕、递归目录批量搜索、多选下载和进度跟踪。", "字幕搜索", "批量下载", "简体中文"] _
    ]

; ==========================================================
; 全局变量
; ==========================================================
Global $g_hGUI = 0
Global $g_hBuffer = 0
Global $g_iHoverCard = -1
Global $g_aCardRects[4]

; 字体与格式
Global $g_hFontFamily = 0, $g_hFontFamilyAa = 0
Global $g_hFontTitle = 0, $g_hFontSub = 0, $g_hFontCardTitle = 0, $g_hFontCardEn = 0
Global $g_hFontDesc = 0, $g_hFontChip = 0, $g_hFontPill = 0, $g_hFontAa = 0
Global $g_hFmtLeft = 0, $g_hFmtCC = 0

; ==========================================================
; 入口
; ==========================================================

Func _DispatchMode()
    Opt("TrayIconHide", 1)

    If @OSVersion = "WIN_10" Or @OSVersion = "WIN_11" Then
        Local Const $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = -4
        DllCall("user32.dll", "bool", "SetProcessDpiAwarenessContext", "handle", $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)
    EndIf

    Local $sMode = ""
    If $CmdLine[0] >= 1 Then $sMode = StringLower($CmdLine[1])

    _VerifyEventHandlers()

    Switch $sMode
        Case "/tool1"
            Tool1_Main()
        Case "/tool2"
            Tool2_Main()
        Case "/tool3"
            Tool3_Main()
        Case "/tool4"
            Tool4_Main()
        Case Else
            Launcher_Main()
    EndSwitch
EndFunc   ;==>_DispatchMode

; ==========================================================
; 事件回调编译期校验（请勿删除本函数！）
; ----------------------------------------------------------
; 本程序的事件回调全部以「函数名字符串」形式绑定给 AutoIt：
;   启动器 ：GUIRegisterMsg($WM_PAINT) / OnAutoItExitRegister("_OnExit")
;   工具1  ：窗口关闭 / 选择源目录 / 选择目标目录 / 开始备份
;   工具2  ：WM_DRAWITEM / WM_NCHITTEST / WM_COMMAND / WM_NOTIFY / COM 错误
; 编译器不校验字符串里的函数名 —— 一旦回调被改名或删除，程序照常编译、
; 照常启动，只是对应事件永久静默失效（表现为"点了没反应"，且无任何报错线索）。
;
; 下面 If False 里的调用永远不会执行，唯一作用是让编译器"看见"这些函数名：
; 只要某个回调被改名/删除，Au3Check 与 Aut2Exe 会立刻报 undefined function，
; 把运行时才暴露的问题提前到编译期。（注意：AutoIt 的 IsFunc() 只认函数
; 引用、对字符串恒返回 0，也无法用 Call() 探测——那会真的把回调执行一遍。）
;
; 【维护约定】新增事件回调 → 在此补一行；回调形参个数变更 → 同步这里实参个数。
; ==========================================================
Func _VerifyEventHandlers()
    If False Then
        _WM_PAINT(0, 0, 0, 0)
        _OnExit()
        _OnClose()
        _SelectSource()
        _SelectTarget()
        _StartBackup()
        _UI_WM_DRAWITEM(0, 0, 0, 0)
        _UI_WM_NCHITTEST(0, 0, 0, 0)
        _OnEditChange(0, 0, 0, 0)
        _OnListViewNotify(0, 0, 0, 0)
        _ComErrorHandler(0)
        Tool4_ComErrorHandler(0)
    EndIf
EndFunc   ;==>_VerifyEventHandlers

Func Launcher_Main()
    _GDIPlus_Startup()

    Local $iStyle = BitOR($WS_SYSMENU, $WS_CAPTION, $WS_MINIMIZEBOX)
    ; [修复点 2] 添加 $WS_EX_COMPOSITED 样式，优化高 DPI 下的双缓冲渲染
    Local $iExStyle = BitOR($WS_EX_APPWINDOW, $WS_EX_COMPOSITED)

    ; 将坐标参数设为 -1，AutoIt 会自动将窗口居中显示
    $g_hGUI = GUICreate("NFO影视刮削工具箱", $WIN_W, $WIN_H, -1, -1, $iStyle, $iExStyle)

    ; 卡片矩形区
    For $i = 0 To 3
        $g_aCardRects[$i] = _GDIPlus_RectFCreate($CARD_X0 + $i * ($CARD_W + $CARD_GAP), $CARD_Y0, $CARD_W, $CARD_H)
    Next

    $g_hBuffer = _GDIPlus_BitmapCreateFromScan0($WIN_W, $WIN_H)
    _CreateFonts()

    ; 仅注册重绘消息
    GUIRegisterMsg($WM_PAINT, "_WM_PAINT")
    OnAutoItExitRegister("_OnExit")

    GUISetState(@SW_SHOW)
    _RenderBuffer()

    ; 使用 GUIGetMsg 处理标准窗口事件
    Local $nMsg = 0
    While 1
        $nMsg = GUIGetMsg()
        Switch $nMsg
            Case $GUI_EVENT_CLOSE ; 点击右上角关闭按钮
                Exit
            Case $GUI_EVENT_PRIMARYDOWN ; 鼠标左键点击
                _HandleClick()
        EndSwitch

        _UpdateHover() ; 更新卡片悬停状态
        Sleep(20) ; 【优化】适当增加休眠时间，降低 CPU 占用，仅在状态改变时触发重绘
    WEnd
EndFunc   ;==>Launcher_Main

; ==========================================================
; 处理鼠标点击卡片事件
; ==========================================================
Func _HandleClick()
    Local $aCursor = GUIGetCursorInfo($g_hGUI)
    If @error Then Return

    For $i = 0 To 3
        If _PtInRect($g_aCardRects[$i], $aCursor[0], $aCursor[1]) Then
            _LaunchTool($i)
            ExitLoop
        EndIf
    Next
EndFunc

; ==========================================================
; 字体与文本格式初始化
; ==========================================================
Func _CreateFonts()
    ; 【优化】去除冗余的系统字体降级判断，现代 Windows 系统均自带雅黑
    $g_hFontFamily = _GDIPlus_FontFamilyCreate("Microsoft YaHei UI")
    $g_hFontFamilyAa = _GDIPlus_FontFamilyCreate("Segoe UI")

    Local $iPX = 2 ; GDI+ 单位：像素
    $g_hFontTitle = _GDIPlus_FontCreate($g_hFontFamily, 42, 1, $iPX)
    $g_hFontSub = _GDIPlus_FontCreate($g_hFontFamily, 15, 0, $iPX)
    $g_hFontCardTitle = _GDIPlus_FontCreate($g_hFontFamily, 24, 1, $iPX)
    $g_hFontCardEn = _GDIPlus_FontCreate($g_hFontFamily, 13, 1, $iPX)
    $g_hFontDesc = _GDIPlus_FontCreate($g_hFontFamily, 13, 0, $iPX)
    $g_hFontChip = _GDIPlus_FontCreate($g_hFontFamily, 13, 0, $iPX)
    $g_hFontPill = _GDIPlus_FontCreate($g_hFontFamily, 16, 1, $iPX)
    $g_hFontAa = _GDIPlus_FontCreate($g_hFontFamilyAa, 38, 1, $iPX)

    $g_hFmtLeft = _GDIPlus_StringFormatCreate()
    _GDIPlus_StringFormatSetAlign($g_hFmtLeft, $SA_NEAR)
    _GDIPlus_StringFormatSetLineAlign($g_hFmtLeft, $SA_NEAR)

    $g_hFmtCC = _GDIPlus_StringFormatCreate()
    _GDIPlus_StringFormatSetAlign($g_hFmtCC, $SA_CENTER)
    _GDIPlus_StringFormatSetLineAlign($g_hFmtCC, $SA_CENTER)
EndFunc   ;==>_CreateFonts

; ==========================================================
; 渲染整帧到内存缓冲
; ==========================================================
Func _RenderBuffer()
    Local $hGfx = _GDIPlus_ImageGetGraphicsContext($g_hBuffer)
    _GDIPlus_GraphicsSetSmoothingMode($hGfx, $GDIP_SMOOTHINGMODE_ANTIALIAS)
    _GDIPlus_GraphicsSetTextRenderingHint($hGfx, $GDIP_TEXTRENDERINGHINTCLEARTYPEGRIDFIT)

    ; --- 背景渐变 ---
    Local $hBrush = _GDIPlus_LineBrushCreate(0, 0, 0, $WIN_H, $CLR_BG_TOP, $CLR_BG_BOTTOM)
    _GDIPlus_GraphicsFillRect($hGfx, 0, 0, $WIN_W, $WIN_H, $hBrush)
    _GDIPlus_BrushDispose($hBrush)

    ; --- 顶部标题区 ---
    ; 1. 先绘制阴影（颜色为半透明黑色，Y坐标下移 1-2 像素）
    _DrawText($hGfx, "NFO影视刮削工具箱", $g_hFontTitle, $g_hFmtCC, 0, 28, $WIN_W, 70, 0x30000000)
    ; 2. 再绘制正文（覆盖在阴影上方）
    _DrawText($hGfx, "NFO影视刮削工具箱", $g_hFontTitle, $g_hFmtCC, 0, 26, $WIN_W, 70, $CLR_TEXT_MAIN)

    ; --- 四张工具卡片 ---
    For $i = 0 To 3
        _DrawCard($hGfx, $i)
    Next

    ; 【删除底部提示文字】

    _GDIPlus_GraphicsDispose($hGfx)
    _WinAPI_InvalidateRect($g_hGUI, 0, False)
EndFunc   ;==>_RenderBuffer

; ==========================================================
; 绘制一张工具卡片
; ==========================================================
Func _DrawCard($hGfx, $iIdx)
    Local $tR = $g_aCardRects[$iIdx]
    Local $x = DllStructGetData($tR, "X"), $y = DllStructGetData($tR, "Y")
    Local $w = DllStructGetData($tR, "Width"), $h = DllStructGetData($tR, "Height")
    Local $iAccent = $aTools[$iIdx][2]
    Local $bHover = ($g_iHoverCard = $iIdx)

    ; --- 阴影 ---
    Local $hPath = _RoundedRectPath($x + 2, $y + 5, $w, $h, $CARD_R)
    Local $hBrush
    If $bHover Then
        $hBrush = _GDIPlus_BrushCreateSolid($CLR_SHADOW_HOVER)
    Else
        $hBrush = _GDIPlus_BrushCreateSolid($CLR_SHADOW)
    EndIf
    _GDIPlus_GraphicsFillPath($hGfx, $hPath, $hBrush)
    _GDIPlus_BrushDispose($hBrush)
    _GDIPlus_PathDispose($hPath)

    ; --- 卡片主体 ---
    $hPath = _RoundedRectPath($x, $y, $w, $h, $CARD_R)
    $hBrush = _GDIPlus_BrushCreateSolid($CLR_CARD)
    _GDIPlus_GraphicsFillPath($hGfx, $hPath, $hBrush)
    _GDIPlus_BrushDispose($hBrush)

    Local $hPen
    If $bHover Then
        $hBrush = _GDIPlus_BrushCreateSolid(BitOR(0x0F000000, BitAND($iAccent, 0xFFFFFF)))
        _GDIPlus_GraphicsFillPath($hGfx, $hPath, $hBrush)
        _GDIPlus_BrushDispose($hBrush)
        $hPen = _GDIPlus_PenCreate($iAccent, 2)
    Else
        $hPen = _GDIPlus_PenCreate($CLR_CARD_BORDER, 1)
    EndIf
    _GDIPlus_GraphicsDrawPath($hGfx, $hPath, $hPen)
    _GDIPlus_PenDispose($hPen)
    _GDIPlus_PathDispose($hPath)

    ; --- 图标区 ---
    Local $cX = $x + 30, $cY = $y + 30, $cS = 90
    $hPath = _RoundedRectPath($cX, $cY, $cS, $cS, 16)
    $hBrush = _GDIPlus_BrushCreateSolid($iAccent)
    _GDIPlus_GraphicsFillPath($hGfx, $hPath, $hBrush)
    _GDIPlus_BrushDispose($hBrush)
    _GDIPlus_PathDispose($hPath)
    _DrawGlyph($hGfx, $iIdx, $cX, $cY, $cS, $cS)

    ; --- 右上角 TOOL 编号 ---
    Local $sBadge = "TOOL " & ($iIdx + 1)
    Local $iW = _TextWidth($hGfx, $sBadge, $g_hFontChip, $g_hFmtLeft)
    _DrawText($hGfx, $sBadge, $g_hFontChip, $g_hFmtLeft, $x + $w - 30 - $iW, $y + 42, $iW, 26, $iAccent)

    ; --- 标题 ---
    _DrawText($hGfx, $aTools[$iIdx][3], $g_hFontCardTitle, $g_hFmtLeft, $x + 30, $y + 135, $w - 60, 48, $CLR_TEXT_MAIN)

    ; --- 英文副标 ---
    _DrawText($hGfx, $aTools[$iIdx][4], $g_hFontCardEn, $g_hFmtLeft, $x + 30, $y + 165, $w - 60, 30, $iAccent)

    ; --- 分隔线 ---
    Local $hLine = _GDIPlus_PenCreate($CLR_DIVIDER, 1.2)
    _GDIPlus_GraphicsDrawLine($hGfx, $x + 30, $y + 195, $x + $w - 30, $y + 195, $hLine)
    _GDIPlus_PenDispose($hLine)

    ; --- 描述 ---
    _DrawText($hGfx, $aTools[$iIdx][5], $g_hFontDesc, $g_hFmtLeft, $x + 30, $y + 215, $w - 60, 110, $CLR_TEXT_SUB)

    ; --- 功能标签芯片 ---
    Local $iChipY = $y + 340
    Local $iChipX = $x + 30
    For $j = 6 To 8
        Local $sChip = $aTools[$iIdx][$j]
        Local $iCw = _TextWidth($hGfx, $sChip, $g_hFontChip, $g_hFmtLeft) + 24
        Local $hP = _RoundedRectPath($iChipX, $iChipY, $iCw, 28, 14)
        Local $hB = _GDIPlus_BrushCreateSolid(BitOR(0x12000000, BitAND($iAccent, 0xFFFFFF)))
        _GDIPlus_GraphicsFillPath($hGfx, $hP, $hB)
        _GDIPlus_BrushDispose($hB)
        _GDIPlus_PathDispose($hP)
        _DrawText($hGfx, $sChip, $g_hFontChip, $g_hFmtCC, $iChipX, $iChipY, $iCw, 28, $iAccent)
        $iChipX += $iCw + 10
    Next

    ; --- 底部启动按钮 ---
    Local $pX = $x + 30, $pY = $y + 490, $pW = $w - 60, $pH = 50
    $hPath = _RoundedRectPath($pX, $pY, $pW, $pH, 25)
    If $bHover Then
        $hBrush = _GDIPlus_BrushCreateSolid($iAccent)
        _GDIPlus_GraphicsFillPath($hGfx, $hPath, $hBrush)
        _DrawText($hGfx, "启动工具 →", $g_hFontPill, $g_hFmtCC, $pX, $pY, $pW, $pH, 0xFFFFFFFF)
        _GDIPlus_BrushDispose($hBrush)
    Else
        $hBrush = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)
        _GDIPlus_GraphicsFillPath($hGfx, $hPath, $hBrush)
        _GDIPlus_BrushDispose($hBrush)
        $hPen = _GDIPlus_PenCreate($iAccent, 1.5)
        _GDIPlus_GraphicsDrawPath($hGfx, $hPath, $hPen)
        _GDIPlus_PenDispose($hPen)
        _DrawText($hGfx, "启动工具 →", $g_hFontPill, $g_hFmtCC, $pX, $pY, $pW, $pH, $iAccent)
    EndIf
    _GDIPlus_PathDispose($hPath)
EndFunc   ;==>_DrawCard

; ==========================================================
; 绘制卡片图标
; ==========================================================
Func _DrawGlyph($hGfx, $iIdx, $gx, $gy, $gw, $gh)
    Local $cx = $gx + $gw / 2
    Local $s = $gw / 58
    Local $hPenW = _GDIPlus_PenCreate(0xFFFFFFFF, 2.2 * $s)

    Switch $iIdx
        Case 0 ; 备份箭头
            _GDIPlus_GraphicsDrawLine($hGfx, $cx, $gy + 14 * $s, $cx, $gy + 38 * $s, $hPenW)
            ; GDIPlus.au3 要求第 0 行保存点数，坐标从第 1 行开始。
            Local $aHead[4][2] = [ _
                    [3, 0], _
                    [$cx - 7 * $s, $gy + 35 * $s], _
                    [$cx + 7 * $s, $gy + 35 * $s], _
                    [$cx, $gy + 43 * $s] _
                    ]
            Local $hB = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)
            _GDIPlus_GraphicsFillPolygon($hGfx, $aHead, $hB)
            _GDIPlus_BrushDispose($hB)
            _GDIPlus_GraphicsDrawLine($hGfx, $gx + 15 * $s, $gy + 46 * $s, $gx + $gw - 15 * $s, $gy + 46 * $s, $hPenW)
        Case 1 ; NFO 文档
            Local $hP = _RoundedRectPath($gx + 15 * $s, $gy + 9 * $s, 28 * $s, 40 * $s, 4 * $s)
            Local $hPen = _GDIPlus_PenCreate(0xFFFFFFFF, 2 * $s)
            _GDIPlus_GraphicsDrawPath($hGfx, $hP, $hPen)
            _GDIPlus_PenDispose($hPen)
            _GDIPlus_PathDispose($hP)

            Local $hPenF = _GDIPlus_PenCreate(0xFFFFFFFF, 1.6 * $s)
            _GDIPlus_GraphicsDrawLine($hGfx, $gx + 36 * $s, $gy + 9 * $s, $gx + 36 * $s, $gy + 17 * $s, $hPenF)
            _GDIPlus_GraphicsDrawLine($hGfx, $gx + 36 * $s, $gy + 17 * $s, $gx + 43 * $s, $gy + 17 * $s, $hPenF)

            Local $hPenL = _GDIPlus_PenCreate(0xCCFFFFFF, 2 * $s)
            _GDIPlus_GraphicsDrawLine($hGfx, $gx + 20 * $s, $gy + 22 * $s, $gx + 38 * $s, $gy + 22 * $s, $hPenL)
            _GDIPlus_GraphicsDrawLine($hGfx, $gx + 20 * $s, $gy + 29 * $s, $gx + 38 * $s, $gy + 29 * $s, $hPenL)
            _GDIPlus_GraphicsDrawLine($hGfx, $gx + 20 * $s, $gy + 36 * $s, $gx + 31 * $s, $gy + 36 * $s, $hPenL)
            _GDIPlus_PenDispose($hPenL)
            _GDIPlus_PenDispose($hPenF)
        Case 2 ; 命名标签：缺角标签 + 穿孔 + 两行命名字段
            Local $aTag[6][2] = [ _
                    [5, 0], _
                    [$gx + 12 * $s, $gy + 16 * $s], _
                    [$gx + 35 * $s, $gy + 16 * $s], _
                    [$gx + 46 * $s, $gy + 29 * $s], _
                    [$gx + 35 * $s, $gy + 42 * $s], _
                    [$gx + 12 * $s, $gy + 42 * $s] _
                    ]
            Local $hPenTag = _GDIPlus_PenCreate(0xFFFFFFFF, 2.2 * $s)
            _GDIPlus_GraphicsDrawPolygon($hGfx, $aTag, $hPenTag)
            _GDIPlus_PenDispose($hPenTag)

            ; 标签穿孔
            Local $fHoleD = 5 * $s
            Local $hPenHole = _GDIPlus_PenCreate(0xFFFFFFFF, 1.8 * $s)
            _GDIPlus_GraphicsDrawEllipse($hGfx, $gx + 17.5 * $s - $fHoleD / 2, $gy + 29 * $s - $fHoleD / 2, $fHoleD, $fHoleD, $hPenHole)
            _GDIPlus_PenDispose($hPenHole)

            ; 标签上的两行字段
            Local $hPenTagL = _GDIPlus_PenCreate(0xCCFFFFFF, 2 * $s)
            _GDIPlus_GraphicsDrawLine($hGfx, $gx + 25 * $s, $gy + 25 * $s, $gx + 33 * $s, $gy + 25 * $s, $hPenTagL)
            _GDIPlus_GraphicsDrawLine($hGfx, $gx + 25 * $s, $gy + 33 * $s, $gx + 30 * $s, $gy + 33 * $s, $hPenTagL)
            _GDIPlus_PenDispose($hPenTagL)
        Case 3 ; 字幕气泡：带尾巴的对话气泡 + 两行字幕
            ; 轮廓用一条闭合路径画完（4 段圆角 + 底边断开处接尾巴），避免尾部和底边互相盖线
            Local $hBubPath = _GDIPlus_PathCreate()
            _GDIPlus_PathAddArc($hBubPath, $gx + 11 * $s, $gy + 15 * $s, 14 * $s, 14 * $s, 180, 90)
            _GDIPlus_PathAddArc($hBubPath, $gx + 33 * $s, $gy + 15 * $s, 14 * $s, 14 * $s, 270, 90)
            _GDIPlus_PathAddArc($hBubPath, $gx + 33 * $s, $gy + 27 * $s, 14 * $s, 14 * $s, 0, 90)
            _GDIPlus_PathAddLine($hBubPath, $gx + 40 * $s, $gy + 41 * $s, $gx + 28 * $s, $gy + 41 * $s)
            _GDIPlus_PathAddLine($hBubPath, $gx + 28 * $s, $gy + 41 * $s, $gx + 16 * $s, $gy + 49 * $s)
            _GDIPlus_PathAddLine($hBubPath, $gx + 16 * $s, $gy + 49 * $s, $gx + 20 * $s, $gy + 41 * $s)
            _GDIPlus_PathAddLine($hBubPath, $gx + 20 * $s, $gy + 41 * $s, $gx + 18 * $s, $gy + 41 * $s)
            _GDIPlus_PathAddArc($hBubPath, $gx + 11 * $s, $gy + 27 * $s, 14 * $s, 14 * $s, 90, 90)
            _GDIPlus_PathCloseFigure($hBubPath)

            Local $hPenBub = _GDIPlus_PenCreate(0xFFFFFFFF, 2.2 * $s)
            _GDIPlus_PenSetLineJoin($hPenBub, 2) ; 折角圆接，尾巴尖不扎
            _GDIPlus_GraphicsDrawPath($hGfx, $hBubPath, $hPenBub)
            _GDIPlus_PenDispose($hPenBub)
            _GDIPlus_PathDispose($hBubPath)

            ; 两行字幕
            Local $hPenCap = _GDIPlus_PenCreate(0xCCFFFFFF, 2 * $s)
            _GDIPlus_GraphicsDrawLine($hGfx, $gx + 17 * $s, $gy + 24 * $s, $gx + 41 * $s, $gy + 24 * $s, $hPenCap)
            _GDIPlus_GraphicsDrawLine($hGfx, $gx + 17 * $s, $gy + 31 * $s, $gx + 33 * $s, $gy + 31 * $s, $hPenCap)
            _GDIPlus_PenDispose($hPenCap)
    EndSwitch
    _GDIPlus_PenDispose($hPenW)
EndFunc   ;==>_DrawGlyph

; ==========================================================
; 辅助绘制文本
; ==========================================================
Func _DrawText($hGfx, $sText, $hFont, $hFormat, $x, $y, $w, $h, $iARGB)
    Local $tLayout = _GDIPlus_RectFCreate($x, $y, $w, $h)
    Local $hBrush = _GDIPlus_BrushCreateSolid($iARGB)
    _GDIPlus_GraphicsDrawStringEx($hGfx, $sText, $hFont, $tLayout, $hFormat, $hBrush)
    _GDIPlus_BrushDispose($hBrush)
EndFunc   ;==>_DrawText

Func _TextWidth($hGfx, $sText, $hFont, $hFormat)
    Local $tLayout = _GDIPlus_RectFCreate(0, 0, 600, 100)
    Local $aM = _GDIPlus_GraphicsMeasureString($hGfx, $sText, $hFont, $tLayout, $hFormat)
    If @error Or Not IsArray($aM) Then Return 20
    Return DllStructGetData($aM[0], "Width") + 2
EndFunc   ;==>_TextWidth

; ==========================================================
; 圆角矩形路径
; ==========================================================
Func _RoundedRectPath($x, $y, $w, $h, $r)
    Local $d = $r * 2
    Local $hPath = _GDIPlus_PathCreate()
    _GDIPlus_PathAddArc($hPath, $x, $y, $d, $d, 180, 90)
    _GDIPlus_PathAddArc($hPath, $x + $w - $d, $y, $d, $d, 270, 90)
    _GDIPlus_PathAddArc($hPath, $x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    _GDIPlus_PathAddArc($hPath, $x, $y + $h - $d, $d, $d, 90, 90)
    _GDIPlus_PathCloseFigure($hPath)
    Return $hPath
EndFunc   ;==>_RoundedRectPath

Func _PtInRect($tR, $px, $py)
    Local $x = DllStructGetData($tR, "X"), $y = DllStructGetData($tR, "Y")
    Local $w = DllStructGetData($tR, "Width"), $h = DllStructGetData($tR, "Height")
    Return ($px >= $x And $px <= $x + $w And $py >= $y And $py <= $y + $h)
EndFunc   ;==>_PtInRect

; ==========================================================
; 鼠标悬停轮询
; ==========================================================
Func _UpdateHover()
    Local $aCursor = GUIGetCursorInfo($g_hGUI)
    If @error Then Return

    Local $iX = $aCursor[0]
    Local $iY = $aCursor[1]
    Local $iNew = -1

    For $i = 0 To 3
        If _PtInRect($g_aCardRects[$i], $iX, $iY) Then
            $iNew = $i
            ExitLoop
        EndIf
    Next

    ; 【优化】仅在悬停状态发生改变时触发重绘
    If $iNew <> $g_iHoverCard Then
        $g_iHoverCard = $iNew
        If $iNew >= 0 Then
            GUISetCursor(13, 1, $g_hGUI) ; 手型
        Else
            GUISetCursor(2, 1, $g_hGUI) ; 标准箭头
        EndIf
        _RenderBuffer()
    EndIf
EndFunc   ;==>_UpdateHover

; ==========================================================
; 消息处理
; ==========================================================
Func _WM_PAINT($hWnd, $iMsg, $wParam, $lParam)
    If $g_hBuffer = 0 Then Return 0

    Local $tPS = DllStructCreate($tagPAINTSTRUCT)
    Local $hDC = _WinAPI_BeginPaint($hWnd, $tPS)

    Local $hGfx = _GDIPlus_GraphicsCreateFromHDC($hDC)
    _GDIPlus_GraphicsDrawImageRect($hGfx, $g_hBuffer, 0, 0, $WIN_W, $WIN_H)
    _GDIPlus_GraphicsDispose($hGfx)

    _WinAPI_EndPaint($hWnd, $tPS)
    Return 0
EndFunc   ;==>_WM_PAINT

; ==========================================================
; 启动工具
; ==========================================================
Func _LaunchTool($iIdx)
    Local $sMode = $aTools[$iIdx][0]
    Local $iPid

    If @Compiled Then
        $iPid = Run('"' & @ScriptFullPath & '" ' & $sMode, @ScriptDir)
    Else
        $iPid = Run('"' & @AutoItExe & '" /AutoIt3ExecuteScript "' & @ScriptFullPath & '" ' & $sMode, @ScriptDir)
    EndIf

    ; 启动失败就保持导航页原样，不要假隐藏
    If $iPid = 0 Then Return

    ; 工具接管前台：导航页隐藏（任务栏按钮一并消失）。
    ; 就在这里等到子进程结束——窗口已不可见，消息循环停在这里没有任何副作用，
    ; 比"记 PID + 主循环轮询 + 独立恢复函数"少一整套状态机。
    GUISetState(@SW_HIDE, $g_hGUI)
    While ProcessExists($iPid)
        Sleep(150)
    WEnd

    ; 工具已关闭：清掉离开时的悬停态，重绘一帧再把导航页浮回前台
    $g_iHoverCard = -1
    GUISetCursor(2, 1, $g_hGUI)
    _RenderBuffer()
    GUISetState(@SW_SHOW, $g_hGUI)
    WinActivate($g_hGUI)
EndFunc   ;==>_LaunchTool

; ==========================================================
; 退出清理
; ==========================================================
Func _OnExit()
    If $g_hFontTitle Then _GDIPlus_FontDispose($g_hFontTitle)
    If $g_hFontSub Then _GDIPlus_FontDispose($g_hFontSub)
    If $g_hFontCardTitle Then _GDIPlus_FontDispose($g_hFontCardTitle)
    If $g_hFontCardEn Then _GDIPlus_FontDispose($g_hFontCardEn)
    If $g_hFontDesc Then _GDIPlus_FontDispose($g_hFontDesc)
    If $g_hFontChip Then _GDIPlus_FontDispose($g_hFontChip)
    If $g_hFontPill Then _GDIPlus_FontDispose($g_hFontPill)
    If $g_hFontAa Then _GDIPlus_FontDispose($g_hFontAa)

    If $g_hFontFamily Then _GDIPlus_FontFamilyDispose($g_hFontFamily)
    If $g_hFontFamilyAa Then _GDIPlus_FontFamilyDispose($g_hFontFamilyAa)

    If $g_hFmtLeft Then _GDIPlus_StringFormatDispose($g_hFmtLeft)
    If $g_hFmtCC Then _GDIPlus_StringFormatDispose($g_hFmtCC)

    If $g_hBuffer Then _GDIPlus_BitmapDispose($g_hBuffer)

    _GDIPlus_Shutdown()
EndFunc   ;==>_OnExit
#EndRegion ;**** 主启动器（四合一菜单） ****

#Region ;**** 工具1：手动刮削批量备份工具 (tool-1) ****
; ==========================================================
; 手动刮削批量备份工具 - AutoIt3 版 (宽屏优化版)
; ==========================================================

; ==========================================================
; 全局变量
; ==========================================================
Global $g_hTool1GUI

; 控件 ID
Global $g_idSource, $g_idTarget
Global $g_idChkNfo, $g_idChkActor, $g_idChkImage, $g_idChkTree
Global $g_idProgress, $g_idProgressLabel
Global $g_idLog, $g_idStart

; 备份状态
Global $g_bRunning = False
Global $g_aFileList[1] ; [0]=count, [1..n]=full source path
Global $g_iTool1FileCount = 0
Global $g_iCurrentIndex = 1 ; 当前复制到的索引
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
; 主函数 - 构建 GUI (居中留白优化版)
; ==========================================================
Func Tool1_Main()
    Opt("GUIOnEventMode", 1)

    $g_hTool1GUI = GUICreate("手动刮削资源备份工具", 1600, 900, -1, -1)
    GUISetOnEvent($GUI_EVENT_CLOSE, "_OnClose")
        
    ; 定义内容区宽度与居中起始坐标
    Local $iContentWidth = 800
    Local $iLeftMargin = (1600 - $iContentWidth) / 2 

    ; --- 标题 ---
    GUICtrlCreateLabel("手动刮削资源备份工具", 0, 20, 1600, 50, $SS_CENTER)
    GUICtrlSetFont(-1, 24, 800, 0, "Microsoft YaHei")
    GUICtrlSetColor(-1, 0x2196F3)

    ; 分隔线
    GUICtrlCreateLabel("", $iLeftMargin, 85, $iContentWidth, 3, $SS_ETCHEDHORZ)

    ; --- 目录设置 ---
    GUICtrlCreateGroup("目录设置", $iLeftMargin, 100, $iContentWidth, 130)
    
    ; 源目录行
    GUICtrlCreateLabel("源目录：", $iLeftMargin + 20, 135, 100, 28)
    GUICtrlSetFont(-1, 12, 400, 0, "Microsoft YaHei")
    
    $g_idSource = GUICtrlCreateInput("", $iLeftMargin + 130, 132, 550, 32)
    GUICtrlSetFont(-1, 12, 400, 0, "Microsoft YaHei")
    GUICtrlSetTip($g_idSource, "选择要备份的源文件夹...")
    
    Local $idBtnSource = GUICtrlCreateButton("浏览...", $iLeftMargin + 690, 132, 100, 32)
    GUICtrlSetFont(-1, 11, 400, 0, "Microsoft YaHei")
    GUICtrlSetOnEvent($idBtnSource, "_SelectSource")

    ; 目标目录行
    GUICtrlCreateLabel("目标目录：", $iLeftMargin + 20, 180, 100, 28)
    GUICtrlSetFont(-1, 12, 400, 0, "Microsoft YaHei")
    
    $g_idTarget = GUICtrlCreateInput("", $iLeftMargin + 130, 177, 550, 32)
    GUICtrlSetFont(-1, 12, 400, 0, "Microsoft YaHei")
    GUICtrlSetTip($g_idTarget, "选择备份保存的目标文件夹...")
    
    Local $idBtnTarget = GUICtrlCreateButton("浏览...", $iLeftMargin + 690, 177, 100, 32)
    GUICtrlSetFont(-1, 11, 400, 0, "Microsoft YaHei")
    GUICtrlSetOnEvent($idBtnTarget, "_SelectTarget")

    ; --- 备份选项 ---
    GUICtrlCreateGroup("备份选项", $iLeftMargin, 250, $iContentWidth, 200)
    
    $g_idChkNfo = GUICtrlCreateCheckbox("排除 .nfo 文件", $iLeftMargin + 30, 285, 300, 30)
    GUICtrlSetFont(-1, 12, 400, 0, "Microsoft YaHei")
    GUICtrlSetTip($g_idChkNfo, "排除所有 .nfo 文件")
    GUICtrlSetState($g_idChkNfo, $GUI_CHECKED)
    
    $g_idChkActor = GUICtrlCreateCheckbox("排除 .actors 文件夹", $iLeftMargin + 30, 325, 300, 30)
    GUICtrlSetFont(-1, 12, 400, 0, "Microsoft YaHei")
    GUICtrlSetTip($g_idChkActor, "排除所有 .actors 的文件夹及其内容")
    GUICtrlSetState($g_idChkActor, $GUI_CHECKED)
    
    $g_idChkImage = GUICtrlCreateCheckbox("排除图片文件", $iLeftMargin + 30, 365, 350, 30)
    GUICtrlSetFont(-1, 12, 400, 0, "Microsoft YaHei")
    GUICtrlSetTip($g_idChkImage, "排除所有 .png、.jpg、.jpeg、.tga、.webp 等常见图片格式")
    GUICtrlSetState($g_idChkImage, $GUI_UNCHECKED)
    
    $g_idChkTree = GUICtrlCreateCheckbox("备份完成后导出目录树", $iLeftMargin + 30, 405, 350, 30)
    GUICtrlSetFont(-1, 12, 400, 0, "Microsoft YaHei")
    GUICtrlSetTip($g_idChkTree, "备份完成后将目录结构保存为目标目录下的 目录树.txt")
    GUICtrlSetState($g_idChkTree, $GUI_UNCHECKED)

    ; --- 进度条 ---
    $g_idProgress = GUICtrlCreateProgress($iLeftMargin, 470, $iContentWidth, 35, $PBS_SMOOTH)
    $g_idProgressLabel = GUICtrlCreateLabel("就绪", $iLeftMargin, 515, $iContentWidth, 25, $SS_CENTER)
    GUICtrlSetFont(-1, 12, 400, 0, "Microsoft YaHei")
    GUICtrlSetColor($g_idProgressLabel, 0x666666)

    ; --- 操作日志 ---
    GUICtrlCreateGroup("操作日志", $iLeftMargin, 550, $iContentWidth, 250)
    
    $g_idLog = GUICtrlCreateEdit("", $iLeftMargin + 10, 575, $iContentWidth - 20, 220, _
            BitOR($ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL, $ES_MULTILINE))
    GUICtrlSetFont(-1, 14, 400, 0, "Consolas") ; 字体加大到 14
    GUICtrlSetBkColor($g_idLog, 0xFAFAFA)

    ; --- 开始按钮 ---
    $g_idStart = GUICtrlCreateButton("开始备份", $iLeftMargin + 225, 820, 350, 55)
    GUICtrlSetFont(-1, 18, 800, 0, "Microsoft YaHei") ; 字体加大到 18
    GUICtrlSetBkColor(-1, 0x4CAF50)
    GUICtrlSetColor(-1, 0xFFFFFF)
    GUICtrlSetOnEvent($g_idStart, "_StartBackup")

    GUISetState(@SW_SHOW)

    ; --- 主循环 ---
    While 1
        Sleep(10)
        If $g_bRunning Then
            _ProcessBackupBatch()
        EndIf
    WEnd
EndFunc   ;==>Tool1_Main

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
EndFunc   ;==>_OnClose

Func _SelectSource()
    Local $sPath = FileSelectFolder("选择源文件夹", "")
    If $sPath <> "" Then
        GUICtrlSetData($g_idSource, $sPath)
    EndIf
EndFunc   ;==>_SelectSource

Func _SelectTarget()
    Local $sPath = FileSelectFolder("选择目标文件夹", "")
    If $sPath <> "" Then
        GUICtrlSetData($g_idTarget, $sPath)
    EndIf
EndFunc   ;==>_SelectTarget

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

    ; 规范化为绝对路径，并保留盘符根目录的反斜杠。
    $g_sSourceDir = _NormalizeDirectoryPath($sSource)
    $g_sTargetDir = _NormalizeDirectoryPath($sTarget)
    If $g_sSourceDir = "" Or $g_sTargetDir = "" Then
        _LogAppend("错误：无法识别源目录或目标目录")
        Return
    EndIf

    ; 源/目标必须是目录；目标可以尚不存在。
    If StringInStr(FileGetAttrib($g_sSourceDir), "D") = 0 Then
        _LogAppend("错误：源路径不是有效目录")
        Return
    EndIf
    If FileExists($g_sTargetDir) And StringInStr(FileGetAttrib($g_sTargetDir), "D") = 0 Then
        _LogAppend("错误：目标路径已存在，但不是目录")
        Return
    EndIf

    ; 拒绝相同目录以及互相包含的目录，防止备份递归扫描自身或发生覆盖混淆。
    If _IsSameOrChildDirectory($g_sTargetDir, $g_sSourceDir) Or _IsSameOrChildDirectory($g_sSourceDir, $g_sTargetDir) Then
        _LogAppend("错误：源目录和目标目录不能相同，也不能互相包含")
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
    $g_iTool1FileCount = 0
    ReDim $g_aFileList[1000] ; 初始容量 1000，不足时自动扩容
    _CollectFiles($g_sSourceDir)

    ; 裁剪数组到实际大小
    ReDim $g_aFileList[$g_iTool1FileCount + 1]
    $g_aFileList[0] = $g_iTool1FileCount

    $g_iTotalFiles = $g_iTool1FileCount
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
    GUICtrlSetData($g_idProgressLabel, "0 / " & $g_iTotalFiles & " (0%)")

    $g_bRunning = True
EndFunc   ;==>_StartBackup

; 规范化目录为绝对路径；保留盘符根目录（例如 C:\）。
Func _NormalizeDirectoryPath($sPath)
    $sPath = StringStripWS($sPath, 3)
    If $sPath = "" Then Return ""

    Local $sFullPath = _PathFull($sPath)
    If @error Or $sFullPath = "" Then Return ""
    $sFullPath = StringReplace($sFullPath, "/", "\")

    While StringRight($sFullPath, 1) = "\" And StringLen($sFullPath) > 3
        $sFullPath = StringTrimRight($sFullPath, 1)
    WEnd
    Return $sFullPath
EndFunc

; 判断 $sPath 是否等于 $sParent，或位于 $sParent 子目录中。
; 使用目录分隔符边界，避免 D:\Media2 被误判为 D:\Media 的子目录。
Func _IsSameOrChildDirectory($sPath, $sParent)
    Local $sChild = StringLower(_NormalizeDirectoryPath($sPath))
    Local $sBase = StringLower(_NormalizeDirectoryPath($sParent))
    If $sChild = "" Or $sBase = "" Then Return False
    If $sChild = $sBase Then Return True

    If StringRight($sBase, 1) <> "\" Then $sBase &= "\"
    Return StringLeft($sChild, StringLen($sBase)) = $sBase
EndFunc

; ==========================================================
; 递归收集文件
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
            $g_iTool1FileCount += 1
            If $g_iTool1FileCount >= UBound($g_aFileList) Then
                ReDim $g_aFileList[UBound($g_aFileList) * 2]
            EndIf
            $g_aFileList[$g_iTool1FileCount] = $sDir & "\" & $sFile
        EndIf
    WEnd
    FileClose($hSearch)
EndFunc   ;==>_CollectFiles

Func _IsImageExtension($sExt)
    Switch $sExt
        Case ".png", ".jpg", ".jpeg", ".jfif", ".gif", ".bmp", ".tga", ".webp", ".tif", ".tiff", ".ico", ".heic", ".heif", ".avif", ".apng", ".svg"
            Return True
    EndSwitch
    Return False
EndFunc   ;==>_IsImageExtension

; ==========================================================
; 分批复制
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

    ; 更新进度条
    Local $iPct = 0
    If $g_iTotalFiles > 0 Then
        $iPct = Round($g_iCopiedFiles / $g_iTotalFiles * 100)
    EndIf
    GUICtrlSetData($g_idProgress, $iPct)
    GUICtrlSetData($g_idProgressLabel, $g_iCopiedFiles & " / " & $g_iTotalFiles & " (" & $iPct & "%)")

    ; 全部完成
    If $g_iCurrentIndex > $g_iTotalFiles Then
        _LogAppend("备份完成！")
        If $g_bExportTree Then
            _ExportDirectoryTree()
        EndIf
        _FinishBackup()
    EndIf
EndFunc   ;==>_ProcessBackupBatch

; ==========================================================
; 导出目录树
; ==========================================================
Func _ExportDirectoryTree()
    _LogAppend("正在生成目录树...")
    Local $sTreeFile = $g_sTargetDir & "\目录树.txt"
    Local $hFile = FileOpen($sTreeFile, 2) ; 2 = 覆盖写入
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
EndFunc   ;==>_ExportDirectoryTree

Func _WriteTreeLevel($hFile, $sDir, $iLevel)
    ; 缩进
    Local $sIndent = ""
    For $i = 1 To $iLevel
        $sIndent &= "    "
    Next

    ; 目录名
    Local $sDirName = StringMid($sDir, StringInStr($sDir, "\", 0, -1) + 1)
    FileWriteLine($hFile, $sIndent & $sDirName & "/")

    ; 列出文件（排序）
    Local $aFiles = _FileListToArray($sDir, "*", 1)
    If Not @error And IsArray($aFiles) Then
        _ArraySort($aFiles, 0, 1)
        Local $sSubIndent = $sIndent & "    "
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
EndFunc   ;==>_WriteTreeLevel

; ==========================================================
; 工具函数
; ==========================================================
Func _LogAppend($sMsg)
    _GUICtrlEdit_AppendText($g_idLog, $sMsg & @CRLF)
EndFunc   ;==>_LogAppend

Func _FinishBackup()
    $g_bRunning = False
    GUICtrlSetState($g_idStart, $GUI_ENABLE)
    GUICtrlSetData($g_idStart, "开始备份")
    GUICtrlSetData($g_idProgress, 100)
    _LogAppend("任务结束。")
EndFunc   ;==>_FinishBackup
#EndRegion ;**** 工具1：手动刮削批量备份工具 (tool-1) ****

#Region ;**** 自绘无边框窗口与扁平圆角按钮引擎 ****
Global Const $UI_WM_DRAWITEM = 0x002B
Global Const $UI_WM_NCHITTEST = 0x0084
Global Const $UI_HTCAPTION = 2
Global Const $UI_BS_OWNERDRAW = 0x000B
Global Const $UI_ODT_BUTTON = 4
Global Const $UI_ODS_SELECTED = 0x0001
Global Const $UI_ODS_DISABLED = 0x0004

Global Const $UI_BTN_KIND_NORMAL = 0
Global Const $UI_BTN_KIND_CLOSE = 1
Global Const $UI_BTN_KIND_MIN = 2

; 按钮注册表: [hCtrl, hParent, idCtrl, sText, iBgColor, iTextColor, iFontSize, iParentBg, iKind]
Global $g_aUIButtons[1][9]
Global $g_iUIButtonCount = 0

; 无边框窗口注册表: [hGUI, iDragHeight, iWidth]
Global $g_aUIWindows[1][3]
Global $g_iUIWindowCount = 0

Global $g_hUIHoverCtrl = 0
Global $g_bUIGdiStarted = False
Global $g_hUIFontFamily = 0
Global $g_hUIStrFmtCenter = 0

Func _UI_Init()
    If Not $g_bUIGdiStarted Then
        _GDIPlus_Startup()
        $g_bUIGdiStarted = True
    EndIf
    If $g_hUIFontFamily = 0 Then
        $g_hUIFontFamily = _GDIPlus_FontFamilyCreate("Microsoft YaHei UI")
    EndIf
    If $g_hUIStrFmtCenter = 0 Then
        $g_hUIStrFmtCenter = _GDIPlus_StringFormatCreate()
        _GDIPlus_StringFormatSetAlign($g_hUIStrFmtCenter, 1)
        _GDIPlus_StringFormatSetLineAlign($g_hUIStrFmtCenter, 1)
    EndIf
    GUIRegisterMsg($UI_WM_DRAWITEM, "_UI_WM_DRAWITEM")
    GUIRegisterMsg($UI_WM_NCHITTEST, "_UI_WM_NCHITTEST")
EndFunc   ;==>_UI_Init

Func _UI_Shutdown()
    If $g_hUIStrFmtCenter <> 0 Then
        _GDIPlus_StringFormatDispose($g_hUIStrFmtCenter)
        $g_hUIStrFmtCenter = 0
    EndIf
    If $g_hUIFontFamily <> 0 Then
        _GDIPlus_FontFamilyDispose($g_hUIFontFamily)
        $g_hUIFontFamily = 0
    EndIf
    If $g_bUIGdiStarted Then
        _GDIPlus_Shutdown()
        $g_bUIGdiStarted = False
    EndIf
EndFunc   ;==>_UI_Shutdown

Func _UI_CreateGUI($sTitle, $iW, $iH, $iX = -1, $iY = -1, $hParent = 0, $iBgColor = 0xF8F9FA, $iBorderColor = 0xD1D9E0, $iDragHeight = 65)
    Local $iStyle, $iExStyle
    If $hParent = 0 Then
        $iStyle = BitOR($WS_POPUP, $WS_MINIMIZEBOX, $WS_SYSMENU)
        $iExStyle = $WS_EX_APPWINDOW
    Else
        $iStyle = $WS_POPUP
        $iExStyle = 0
    EndIf

    Local $hGUI = GUICreate($sTitle, $iW, $iH, $iX, $iY, $iStyle, $iExStyle, $hParent)
    GUISetBkColor($iBgColor, $hGUI)

    ; 1px 外边框（禁用状态，不拦截任何鼠标事件）
    Local $idTop = GUICtrlCreateLabel("", 0, 0, $iW, 1)
    GUICtrlSetBkColor($idTop, $iBorderColor)
    GUICtrlSetState($idTop, $GUI_DISABLE)
    Local $idBottom = GUICtrlCreateLabel("", 0, $iH - 1, $iW, 1)
    GUICtrlSetBkColor($idBottom, $iBorderColor)
    GUICtrlSetState($idBottom, $GUI_DISABLE)
    Local $idLeft = GUICtrlCreateLabel("", 0, 0, 1, $iH)
    GUICtrlSetBkColor($idLeft, $iBorderColor)
    GUICtrlSetState($idLeft, $GUI_DISABLE)
    Local $idRight = GUICtrlCreateLabel("", $iW - 1, 0, 1, $iH)
    GUICtrlSetBkColor($idRight, $iBorderColor)
    GUICtrlSetState($idRight, $GUI_DISABLE)

    $g_iUIWindowCount += 1
    ReDim $g_aUIWindows[$g_iUIWindowCount][3]
    $g_aUIWindows[$g_iUIWindowCount - 1][0] = $hGUI
    $g_aUIWindows[$g_iUIWindowCount - 1][1] = $iDragHeight
    $g_aUIWindows[$g_iUIWindowCount - 1][2] = $iW

    Return $hGUI
EndFunc   ;==>_UI_CreateGUI

Func _UI_GUIDelete($hGUI)
    If $hGUI = 0 Then Return

    ; 移除属于该窗口的按钮注册记录
    Local $iWrite = 0
    For $i = 0 To $g_iUIButtonCount - 1
        If $g_aUIButtons[$i][1] = $hGUI Then
            If $g_aUIButtons[$i][0] = $g_hUIHoverCtrl Then $g_hUIHoverCtrl = 0
            ContinueLoop
        EndIf
        If $iWrite <> $i Then
            For $c = 0 To 8
                $g_aUIButtons[$iWrite][$c] = $g_aUIButtons[$i][$c]
            Next
        EndIf
        $iWrite += 1
    Next
    $g_iUIButtonCount = $iWrite
    If $g_iUIButtonCount > 0 Then
        ReDim $g_aUIButtons[$g_iUIButtonCount][9]
    Else
        ReDim $g_aUIButtons[1][9]
    EndIf

    ; 移除窗口记录
    Local $iWinWrite = 0
    For $i = 0 To $g_iUIWindowCount - 1
        If $g_aUIWindows[$i][0] = $hGUI Then ContinueLoop
        If $iWinWrite <> $i Then
            $g_aUIWindows[$iWinWrite][0] = $g_aUIWindows[$i][0]
            $g_aUIWindows[$iWinWrite][1] = $g_aUIWindows[$i][1]
            $g_aUIWindows[$iWinWrite][2] = $g_aUIWindows[$i][2]
        EndIf
        $iWinWrite += 1
    Next
    $g_iUIWindowCount = $iWinWrite
    If $g_iUIWindowCount > 0 Then
        ReDim $g_aUIWindows[$g_iUIWindowCount][3]
    Else
        ReDim $g_aUIWindows[1][3]
    EndIf

    GUIDelete($hGUI)
EndFunc   ;==>_UI_GUIDelete

Func _UI_AddHSeperator($iX, $iY, $iW, $iH = 1, $iColor = 0xD1D9E0)
    Local $idSep = GUICtrlCreateLabel("", $iX, $iY, $iW, $iH)
    GUICtrlSetBkColor($idSep, $iColor)
    GUICtrlSetState($idSep, $GUI_DISABLE)
    Return $idSep
EndFunc   ;==>_UI_AddHSeperator

Func _UI_AddVSeperator($iX, $iY, $iH, $iW = 1, $iColor = 0xD1D9E0)
    Local $idSep = GUICtrlCreateLabel("", $iX, $iY, $iW, $iH)
    GUICtrlSetBkColor($idSep, $iColor)
    GUICtrlSetState($idSep, $GUI_DISABLE)
    Return $idSep
EndFunc   ;==>_UI_AddVSeperator

Func _UI_CreateButton($sText, $iX, $iY, $iW, $iH, $iBgColor, $iTextColor, $iFontSize = 11, $iParentBg = 0xF8F9FA, $iKind = $UI_BTN_KIND_NORMAL)
    ; 【关键】$BS_OWNERDRAW 不能通过 GUICtrlCreateButton 的 style 参数传入：
    ; 实测（AutoIt 3.3.18）该参数会把 0x0B 归一化成 BS_DEFPUSHBUTTON（0x1），
    ; 按钮退回 Windows 默认灰色外观，且父窗口收不到 WM_DRAWITEM —— 自绘完全失效。
    ; 必须创建后用 GUICtrlSetStyle 单独设置，样式位才会真正落到控件上。
    Local $idBtn = GUICtrlCreateButton($sText, $iX, $iY, $iW, $iH)
    GUICtrlSetStyle($idBtn, BitOR($UI_BS_OWNERDRAW, $WS_TABSTOP))
    GUICtrlSetCursor($idBtn, 0)

    Local $hCtrl = GUICtrlGetHandle($idBtn)
    Local $hParent = _WinAPI_GetParent($hCtrl)

    $g_iUIButtonCount += 1
    ReDim $g_aUIButtons[$g_iUIButtonCount][9]
    Local $idx = $g_iUIButtonCount - 1
    $g_aUIButtons[$idx][0] = $hCtrl
    $g_aUIButtons[$idx][1] = $hParent
    $g_aUIButtons[$idx][2] = $idBtn
    $g_aUIButtons[$idx][3] = $sText
    $g_aUIButtons[$idx][4] = $iBgColor
    $g_aUIButtons[$idx][5] = $iTextColor
    $g_aUIButtons[$idx][6] = $iFontSize
    $g_aUIButtons[$idx][7] = $iParentBg
    $g_aUIButtons[$idx][8] = $iKind

    Return $idBtn
EndFunc   ;==>_UI_CreateButton

Func _UI_AddControlButtons($iWinW, $bClose = True, $bMin = False, $iBgColor = 0xF8F9FA, $iTextColor = 0x1E293B)
    Local $aBtns[4] = [0, 0, 0, 0]
    Local $iRight = $iWinW - 1
    If $bClose Then
        $iRight -= 46
        $aBtns[0] = _UI_CreateButton("", $iRight, 1, 46, 36, $iBgColor, $iTextColor, 11, $iBgColor, $UI_BTN_KIND_CLOSE)
    EndIf
    If $bMin Then
        $iRight -= 46
        $aBtns[3] = _UI_CreateButton("", $iRight, 1, 46, 36, $iBgColor, $iTextColor, 11, $iBgColor, $UI_BTN_KIND_MIN)
    EndIf
    Return $aBtns
EndFunc   ;==>_UI_AddControlButtons

Func _UI_FindButtonIndex($hCtrl)
    If $hCtrl = 0 Then Return -1
    For $i = 0 To $g_iUIButtonCount - 1
        If $g_aUIButtons[$i][0] = $hCtrl Then Return $i
    Next
    Return -1
EndFunc   ;==>_UI_FindButtonIndex

Func _UI_IsLightColor($iRGB)
    Local $iR = BitAND(BitShift($iRGB, 16), 0xFF)
    Local $iG = BitAND(BitShift($iRGB, 8), 0xFF)
    Local $iB = BitAND($iRGB, 0xFF)
    Return (($iR * 299 + $iG * 587 + $iB * 114) / 1000) > 170
EndFunc   ;==>_UI_IsLightColor

Func _UI_AdjustColor($iRGB, $iDelta)
    Local $iR = BitAND(BitShift($iRGB, 16), 0xFF) + $iDelta
    Local $iG = BitAND(BitShift($iRGB, 8), 0xFF) + $iDelta
    Local $iB = BitAND($iRGB, 0xFF) + $iDelta
    If $iR < 0 Then $iR = 0
    If $iR > 255 Then $iR = 255
    If $iG < 0 Then $iG = 0
    If $iG > 255 Then $iG = 255
    If $iB < 0 Then $iB = 0
    If $iB > 255 Then $iB = 255
    Return BitOR(BitShift($iR, -16), BitShift($iG, -8), $iB)
EndFunc   ;==>_UI_AdjustColor

Func _UI_BlendColor($iRGB1, $iRGB2, $fRatio)
    Local $iR1 = BitAND(BitShift($iRGB1, 16), 0xFF)
    Local $iG1 = BitAND(BitShift($iRGB1, 8), 0xFF)
    Local $iB1 = BitAND($iRGB1, 0xFF)
    Local $iR2 = BitAND(BitShift($iRGB2, 16), 0xFF)
    Local $iG2 = BitAND(BitShift($iRGB2, 8), 0xFF)
    Local $iB2 = BitAND($iRGB2, 0xFF)
    Local $iR = Int($iR1 + ($iR2 - $iR1) * $fRatio)
    Local $iG = Int($iG1 + ($iG2 - $iG1) * $fRatio)
    Local $iB = Int($iB1 + ($iB2 - $iB1) * $fRatio)
    Return BitOR(BitShift($iR, -16), BitShift($iG, -8), $iB)
EndFunc   ;==>_UI_BlendColor

Func _UI_PollHover($hGUI)
    If $hGUI = 0 Then Return
    Local $aCur = GUIGetCursorInfo($hGUI)
    Local $hNew = 0
    If Not @error And IsArray($aCur) And $aCur[4] > 0 Then
        Local $hCand = GUICtrlGetHandle($aCur[4])
        If _UI_FindButtonIndex($hCand) >= 0 Then $hNew = $hCand
    EndIf

    If $hNew <> $g_hUIHoverCtrl Then
        Local $hOld = $g_hUIHoverCtrl
        $g_hUIHoverCtrl = $hNew
        If $hOld <> 0 And _UI_FindButtonIndex($hOld) >= 0 Then
            _WinAPI_InvalidateRect($hOld, 0, False)
        EndIf
        If $hNew <> 0 Then
            _WinAPI_InvalidateRect($hNew, 0, False)
        EndIf
    EndIf
EndFunc   ;==>_UI_PollHover

Func _UI_WM_NCHITTEST($hWnd, $iMsg, $wParam, $lParam)
    Local $iDragH = 0, $iWinW = 0
    For $i = 0 To $g_iUIWindowCount - 1
        If $g_aUIWindows[$i][0] = $hWnd Then
            $iDragH = $g_aUIWindows[$i][1]
            $iWinW = $g_aUIWindows[$i][2]
            ExitLoop
        EndIf
    Next
    If $iDragH = 0 Then Return $GUI_RUNDEFMSG

    ; 处理多显示器下可能出现的负坐标（有符号 16 位）
    Local $iScrX = BitAND($lParam, 0xFFFF)
    If $iScrX >= 0x8000 Then $iScrX -= 0x10000
    Local $iScrY = BitAND(BitShift($lParam, 16), 0xFFFF)
    If $iScrY >= 0x8000 Then $iScrY -= 0x10000

    Local $tPt = DllStructCreate("long X;long Y")
    DllStructSetData($tPt, "X", $iScrX)
    DllStructSetData($tPt, "Y", $iScrY)
    _WinAPI_ScreenToClient($hWnd, $tPt)

    Local $iCX = DllStructGetData($tPt, "X")
    Local $iCY = DllStructGetData($tPt, "Y")
    If $iCY >= 1 And $iCY < $iDragH And $iCX >= 1 And $iCX < $iWinW - 1 Then
        Return $UI_HTCAPTION
    EndIf
    Return $GUI_RUNDEFMSG
EndFunc   ;==>_UI_WM_NCHITTEST

Func _UI_WM_DRAWITEM($hWnd, $iMsg, $wParam, $lParam)
    Local $tDIS = DllStructCreate("uint CtlType;uint CtlID;uint itemID;uint itemAction;uint itemState;hwnd hwndItem;handle hDC;long Left;long Top;long Right;long Bottom;ulong_ptr itemData", $lParam)
    If DllStructGetData($tDIS, "CtlType") <> $UI_ODT_BUTTON Then Return $GUI_RUNDEFMSG

    Local $hCtrl = DllStructGetData($tDIS, "hwndItem")
    Local $idx = _UI_FindButtonIndex($hCtrl)
    If $idx < 0 Then Return $GUI_RUNDEFMSG

    Local $hDC = DllStructGetData($tDIS, "hDC")
    Local $iW = DllStructGetData($tDIS, "Right") - DllStructGetData($tDIS, "Left")
    Local $iH = DllStructGetData($tDIS, "Bottom") - DllStructGetData($tDIS, "Top")
    If $iW <= 0 Or $iH <= 0 Then Return True

    Local $iState = DllStructGetData($tDIS, "itemState")
    Local $bDisabled = (BitAND($iState, $UI_ODS_DISABLED) <> 0)
    Local $bPressed = (BitAND($iState, $UI_ODS_SELECTED) <> 0)
    Local $bHover = (Not $bDisabled And $hCtrl = $g_hUIHoverCtrl)

    Local $sText = $g_aUIButtons[$idx][3]
    Local $iBg = $g_aUIButtons[$idx][4]
    Local $iTxt = $g_aUIButtons[$idx][5]
    Local $iFontSize = $g_aUIButtons[$idx][6]
    Local $iParentBg = $g_aUIButtons[$idx][7]
    Local $iKind = $g_aUIButtons[$idx][8]

    Local $hGfx = _GDIPlus_GraphicsCreateFromHDC($hDC)
    _GDIPlus_GraphicsSetSmoothingMode($hGfx, $GDIP_SMOOTHINGMODE_ANTIALIAS)
    _GDIPlus_GraphicsSetTextRenderingHint($hGfx, $GDIP_TEXTRENDERINGHINTCLEARTYPEGRIDFIT)

    ; 先填满父背景色，确保圆角边缘平滑无毛刺
    Local $hBgBrush = _GDIPlus_BrushCreateSolid(BitOR(0xFF000000, $iParentBg))
    _GDIPlus_GraphicsFillRect($hGfx, 0, 0, $iW, $iH, $hBgBrush)
    _GDIPlus_BrushDispose($hBgBrush)

    If $iKind = $UI_BTN_KIND_CLOSE Or $iKind = $UI_BTN_KIND_MIN Then
        Local $iFill = $iBg
        Local $iGlyphClr = $iTxt
        If $iKind = $UI_BTN_KIND_CLOSE Then
            If $bPressed Then
                $iFill = 0xC42B1C
                $iGlyphClr = 0xFFFFFF
            ElseIf $bHover Then
                $iFill = 0xE81123
                $iGlyphClr = 0xFFFFFF
            EndIf
        Else
            If $bPressed Then
                $iFill = 0xCBD5E1
            ElseIf $bHover Then
                $iFill = 0xE2E8F0
            EndIf
        EndIf

        Local $hFillBrush = _GDIPlus_BrushCreateSolid(BitOR(0xFF000000, $iFill))
        _GDIPlus_GraphicsFillRect($hGfx, 0, 0, $iW, $iH, $hFillBrush)
        _GDIPlus_BrushDispose($hFillBrush)

        Local $hPen = _GDIPlus_PenCreate(BitOR(0xFF000000, $iGlyphClr), 1.5)
        Local $cx = $iW / 2, $cy = $iH / 2
        If $iKind = $UI_BTN_KIND_CLOSE Then
            _GDIPlus_GraphicsDrawLine($hGfx, $cx - 5, $cy - 5, $cx + 5, $cy + 5, $hPen)
            _GDIPlus_GraphicsDrawLine($hGfx, $cx + 5, $cy - 5, $cx - 5, $cy + 5, $hPen)
        Else
            _GDIPlus_GraphicsDrawLine($hGfx, $cx - 5, $cy, $cx + 5, $cy, $hPen)
        EndIf
        _GDIPlus_PenDispose($hPen)
    Else
        $iFill = $iBg
        Local $iTextClr = $iTxt
        Local $bLight = _UI_IsLightColor($iBg)

        If $bDisabled Then
            $iFill = _UI_BlendColor($iBg, $iParentBg, 0.55)
            $iTextClr = $bLight ? 0x94A3B8 : 0xE2E8F0
        ElseIf $bPressed Then
            $iFill = _UI_AdjustColor($iBg, -22)
        ElseIf $bHover Then
            $iFill = $bLight ? _UI_AdjustColor($iBg, -14) : _UI_AdjustColor($iBg, 22)
        EndIf

        Local $hPath = _RoundedRectPath(0.5, 0.5, $iW - 1, $iH - 1, 6)
        $hFillBrush = _GDIPlus_BrushCreateSolid(BitOR(0xFF000000, $iFill))
        _GDIPlus_GraphicsFillPath($hGfx, $hPath, $hFillBrush)
        _GDIPlus_BrushDispose($hFillBrush)

        If $bLight Then
            Local $hBorderPen = _GDIPlus_PenCreate(0xFFCBD5E1, 1)
            _GDIPlus_GraphicsDrawPath($hGfx, $hPath, $hBorderPen)
            _GDIPlus_PenDispose($hBorderPen)
        EndIf
        _GDIPlus_PathDispose($hPath)

        ; 绘制居中文字（单位 3 = Point，与 GUICtrlSetFont 字号一致）
        Local $hFont = _GDIPlus_FontCreate($g_hUIFontFamily, $iFontSize - 0.5, 0, 3)
        Local $tLayout = _GDIPlus_RectFCreate(0, 0, $iW, $iH)
        Local $hTxtBrush = _GDIPlus_BrushCreateSolid(BitOR(0xFF000000, $iTextClr))
        _GDIPlus_GraphicsDrawStringEx($hGfx, $sText, $hFont, $tLayout, $g_hUIStrFmtCenter, $hTxtBrush)
        _GDIPlus_BrushDispose($hTxtBrush)
        _GDIPlus_FontDispose($hFont)
    EndIf

    _GDIPlus_GraphicsDispose($hGfx)
    Return True
EndFunc   ;==>_UI_WM_DRAWITEM
#EndRegion ;**** 自绘无边框窗口与扁平圆角按钮引擎 ****

#Region ;**** 工具2：NFO 编辑器 (tool-2) ****
; ============================================================================
; NFO 编辑器 - AutoIt3 版本
; ============================================================================

#Region ;**** 配置与全局变量 ****
; ==================== 主题配色 ====================
Global Const $CLR_CARD_BG        = 0xF8F9FA   ; 极浅灰白底
Global Const $CLR_SURFACE        = 0xDCE4EC   ; 输入框/卡片灰（与底色差 1.22，保证边界可见）
Global Const $CLR_BORDER         = 0xD1D9E0   ; 分割线灰蓝
Global Const $CLR_PANEL_BG       = 0xF1F5F9   ; 面板背景（比卡片底色稍深，用于内容分组）
Global Const $CLR_PRIMARY        = 0x5B6ABF   ; 柔和靛蓝
Global Const $CLR_SUCCESS        = 0x2E8B57   ; 森林绿
Global Const $CLR_ERROR          = 0xD9534F   ; 温和红
Global Const $CLR_WARNING        = 0xB45309   ; 琥珀橙
Global Const $CLR_INFO           = 0x0F766E   ; 深青绿
Global Const $CLR_TEXT_PRIMARY   = 0x1E293B   ; 深灰（正文）
Global Const $CLR_TEXT_SECONDARY = 0x475569   ; 中灰（标签）
Global Const $CLR_TEXT_MUTED     = 0x64748B   ; 中浅灰（辅助文字，对底色 4.51 达 AA）
Global Const $CLR_TEXT_ON_ACCENT = 0xFFFFFF

; ==================== 按钮配色（8 色独立，色相环最大间距分布） ====================
; 每个按钮拥有独立色相，全部配白色文字，均通过 WCAG AA 对比度（≥4.5:1）
; Hover：自绘按钮自动浅色/深色反馈
; Disabled：自绘按钮自动灰显淡化
Global Const $CLR_BTN_OPEN     = 0x1D4ED8   ; 打开文件
Global Const $CLR_BTN_SAVE     = 0x15803D   ; 保存
Global Const $CLR_BTN_SAVE_AS  = 0x0F766E   ; 另存为
Global Const $CLR_BTN_REFRESH  = 0xB45309   ; 刷新
Global Const $CLR_BTN_SEL_DIR  = 0xBE185D   ; 选择目录
Global Const $CLR_BTN_CHK_ALL  = 0x64748B   ; 全选
Global Const $CLR_BTN_CHK_NONE = 0x64748B   ; 全不选
Global Const $CLR_BTN_BATCH    = 0x6D28D9   ; 批量汉化

; 状态指示灯配色：灰=就绪/已保存，橙=有未保存修改，红=失败
Global Const $CLR_STATUS_READY    = 0x9CA3AF
Global Const $CLR_STATUS_MODIFIED = 0xF59E0B
Global Const $CLR_STATUS_ERROR    = 0xBE123C

; ==================== 全局变量 ====================
Global $g_hMainGui = 0
Global $g_hActorDialog = 0
Global $g_aWindowControlButtons
Global $g_aActorDialogButtons
Global $g_idAccelSave = 0 ; Ctrl+S 快捷键关联的 Dummy 控件
Global $g_idAccelOpen = 0 ; Ctrl+O 打开文件
Global $g_idAccelSaveAs = 0 ; Ctrl+Shift+S 另存为
Global $g_idAccelRefresh = 0 ; F5 刷新目录
Global $g_idAccelCheckAll = 0 ; Ctrl+Shift+A 全选文件列表（避开 Ctrl+A 与编辑框全选冲突）
Global $g_sCurrentFile = ""
Global $g_sCurrentDir = @WorkingDir
Global $g_oXMLDoc = Null
Global $g_sOriginalXmlContent = ""
Global $g_bModified = False
Global $g_bLoading = False
Global $g_bXmlSourceModified = False
Global $g_iCurrentFileEncoding = 256 ; UTF-8 无 BOM；打开文件后会替换为实际编码
Global $g_sLoadedFileSignature = ""
Global $g_sCheckedRelPaths = ""

Global Const $DEFAULT_DEEPSEEK_API_URL = "https://api.deepseek.com/chat/completions"
Global Const $DEFAULT_DEEPSEEK_MODEL = "deepseek-chat"
Global Const $DEFAULT_LOCALIZE_PROMPT = "# JAV NFO 专业翻译 Prompt" & @CRLF & @CRLF & _
    "你是资深 JAV（日本成人影片）NFO 元数据翻译专家，服务对象是成人影片收藏者和媒体库管理工具（Jellyfin / Kodi / Emby）使用者。你的唯一任务：将 NFO 文件中的片名（Title）与剧情简介（Plot）翻译成简体中文，供媒体库展示与检索使用。翻译必须极致露骨、直白、贴切，让读者一看就懂、一看就硬。" & @CRLF & @CRLF & _
    "## 总原则（按优先级排序）" & @CRLF & _
    "1. **准确**：逐句完整翻译，不删减、不合并、不改写、不臆测、不添加。" & @CRLF & _
    "2. **露骨**：性场面用最直白粗俗的词直接写，拒绝隐喻、委婉语、书面语、学术词。" & @CRLF & _
    "3. **简洁**：标题有冲击力、易搜索；简介通顺自然、口语化，杜绝翻译腔。" & @CRLF & _
    "4. **一致**：同一人物、称呼、术语全文统一译法，禁止一处一词、另一处另一词。" & @CRLF & @CRLF & _
    "## 术语对照表（必须严格遵循，可在此基础上扩充）" & @CRLF & @CRLF & _
    "### 一、性行为与动作" & @CRLF & @CRLF & _
    "| 原文（日/英） | 标准译法 |" & @CRLF & _
    "|---|---|" & @CRLF & _
    "| チンポ / ペニス | 鸡巴 |" & @CRLF & _
    "| マンコ / 膣 | 屄 |" & @CRLF & _
    "| セックス / 性交 / H | 做爱 / 性交 |" & @CRLF & _
    "| フェラ | 含鸡巴 |" & @CRLF & _
    "| クンニ | 舔屄 |" & @CRLF & _
    "| パイズリ | 乳交 |" & @CRLF & _
    "| 手コキ | 打手枪 |" & @CRLF & _
    "| 足コキ | 足交 |" & @CRLF & _
    "| 素股 | 股间磨蹭（不插入） |" & @CRLF & _
    "| 顔射 | 颜射 |" & @CRLF & _
    "| 大量顔射 | 大量颜射 |" & @CRLF & _
    "| 中出し | 内射 |" & @CRLF & _
    "| 生ハメ | 无套干 |" & @CRLF & _
    "| 生中出し | 无套内射 |" & @CRLF & _
    "| ぶっかけ | 糊脸（往脸上喷精） |" & @CRLF & _
    "| ごっくん / 飲精 | 吞精 |" & @CRLF & _
    "| 精飲 | 饮精 |" & @CRLF & _
    "| 潮吹き | 潮吹 |" & @CRLF & _
    "| オナニー | 自慰（女）/ 打飞机（男） |" & @CRLF & _
    "| ヤる / 犯す | 干 / 操 |" & @CRLF & _
    "| やられる | 被干 |" & @CRLF & _
    "| レイプ / 強姦 | 强暴 / 强奸 |" & @CRLF & _
    "| 乱交 | 群交 |" & @CRLF & _
    "| 3P / 4P | 3P / 4P |" & @CRLF & _
    "| レズ | 女同 |" & @CRLF & _
    "| ハメ撮り | 实拍 |" & @CRLF & _
    "| 盗撮 | 偷拍 |" & @CRLF & _
    "| 覗き | 偷窥 |" & @CRLF & _
    "| 痴漢 | 痴汉 / 咸猪手 |" & @CRLF & _
    "| 露出 | 露出 |" & @CRLF & _
    "| 時間停止 | 时间停止 |" & @CRLF & _
    "| 催眠 | 催眠 |" & @CRLF & _
    "| 洗脳 | 洗脑 |" & @CRLF & _
    "| 憑依 | 附身 |" & @CRLF & _
    "| 射精 | 射精 |" & @CRLF & _
    "| 連続射精 | 连续射精 |" & @CRLF & _
    "| 射精管理 | 射精管理 |" & @CRLF & _
    "| 寸止め | 憋着不射 |" & @CRLF & _
    "| 一発 | 一发 / 一炮 |" & @CRLF & @CRLF & _
    "### 二、体位" & @CRLF & @CRLF & _
    "| 原文 | 标准译法 |" & @CRLF & _
    "|---|---|" & @CRLF & _
    "| 正常位 |男上 |" & @CRLF & _
    "| 騎乗位 | 骑乘位 |" & @CRLF & _
    "| バック | 后入 |" & @CRLF & _
    "| 立ちバック | 站立后入 |" & @CRLF & _
    "| 四つん這い | 跪趴 |" & @CRLF & _
    "| 対面座位 | 对面坐位 |" & @CRLF & _
    "| 背面座位 | 背面坐位 |" & @CRLF & _
    "| 側位 | 侧位 |" & @CRLF & _
    "| 屈曲位 | 屈曲位 |" & @CRLF & _
    "| 顔面騎乗 | 骑脸 |" & @CRLF & _
    "| 足コキ | 脚交 |" & @CRLF & @CRLF & _
    "### 三、身体部位" & @CRLF & @CRLF & _
    "| 原文 | 标准译法 |" & @CRLF & _
    "|---|---|" & @CRLF & _
    "| おっぱい / 乳 | 奶子 |" & @CRLF & _
    "| 乳首 | 奶头 |" & @CRLF & _
    "| 乳輪 | 乳晕 |" & @CRLF & _
    "| アナル / 尻穴 | 屁眼 |" & @CRLF & _
    "| クリトリス / クリ | 阴蒂 |" & @CRLF & _
    "| 膣内 / 膣 | 屄里 / 屄 |" & @CRLF & _
    "| 子宮 | 子宫 |" & @CRLF & _
    "| 睾丸 | 蛋蛋 |" & @CRLF & _
    "| 顔 | 脸 |" & @CRLF & _
    "| おしっこ | 尿 |" & @CRLF & _
    "| 便 | 大便 |" & @CRLF & @CRLF & _
    "### 四、体液" & @CRLF & @CRLF & _
    "| 原文 | 标准译法 |" & @CRLF & _
    "|---|---|" & @CRLF & _
    "| ザーメン / 精液 | 精液 / 精浆 |" & @CRLF & _
    "| 精子 | 精子 |" & @CRLF & _
    "| 白濁 | 白浊 |" & @CRLF & _
    "| 愛液 | 爱液 |" & @CRLF & _
    "| 淫汁 / まん汁 | 屄水 |" & @CRLF & _
    "| 唾液 | 口水 |" & @CRLF & _
    "| 汗 | 汗 |" & @CRLF & @CRLF & _
    "### 五、性玩具与道具" & @CRLF & @CRLF & _
    "| 原文 | 标准译法 |" & @CRLF & _
    "|---|---|" & @CRLF & _
    "| おもちゃ | 性玩具 |" & @CRLF & _
    "| バイブ | 震动棒 |" & @CRLF & _
    "| ローター / 電マ | 跳蛋 |" & @CRLF & _
    "| ディルド | 假阳具 |" & @CRLF & _
    "| アナルビーズ | 肛珠 |" & @CRLF & _
    "| 大人のおもちゃ | 成人玩具 |" & @CRLF & _
    "| 媚薬 | 媚药 |" & @CRLF & _
    "| コンドーム | 避孕套 |" & @CRLF & @CRLF & _
    "### 六、调教 / 凌辱类" & @CRLF & @CRLF & _
    "| 原文 | 标准译法 |" & @CRLF & _
    "|---|---|" & @CRLF & _
    "| 調教 | 调教 |" & @CRLF & _
    "| 陵辱 | 凌辱 |" & @CRLF & _
    "| 寝取られ / NTR | 寝取 / 绿帽 |" & @CRLF & _
    "| 近親相姦 | 乱伦 |" & @CRLF & _
    "| 拘束 | 束缚 |" & @CRLF & _
    "| 緊縛 | 紧缚 |" & @CRLF & _
    "| 縄 | 绳子 |" & @CRLF & _
    "| スパンキング | 打屁股 |" & @CRLF & _
    "| むち打ち | 鞭打 |" & @CRLF & _
    "| 浣腸 | 灌肠 |" & @CRLF & _
    "| 責め | 责玩 / 折磨 |" & @CRLF & _
    "| サンドバッグ | 沙袋 |" & @CRLF & @CRLF & _
    "### 七、人物与关系" & @CRLF & @CRLF & _
    "| 原文 | 标准译法 |" & @CRLF & _
    "|---|---|" & @CRLF & _
    "| 素人 | 素人 |" & @CRLF & _
    "| 人妻 | 人妻 |" & @CRLF & _
    "| 熟女 | 熟女 |" & @CRLF & _
    "| 娘 | 女儿 |" & @CRLF & _
    "| 母 | 妈妈 |" & @CRLF & _
    "| 姉 | 姐姐 |" & @CRLF & _
    "| 妹 | 妹妹 |" & @CRLF & _
    "| 叔母 | 婶婶 / 阿姨 |" & @CRLF & _
    "| 義母 | 继母 |" & @CRLF & _
    "| 義姉 | 继姐 |" & @CRLF & _
    "| 義妹 | 继妹 |" & @CRLF & _
    "| 幼馴染 | 青梅竹马 |" & @CRLF & _
    "| 旦那 | 老公 |" & @CRLF & _
    "| 妻 | 老婆 |" & @CRLF & _
    "| 彼氏 / 彼女 | 男朋友 / 女朋友 |" & @CRLF & _
    "| 夫婦 | 夫妇 |" & @CRLF & _
    "| 新婚 | 新婚 |" & @CRLF & _
    "| 学生 | 学生 |" & @CRLF & _
    "| 会社員 | 上班族 |" & @CRLF & _
    "| 金持ち | 有钱人 |" & @CRLF & _
    "| 童貞 | 处男 |" & @CRLF & _
    "| 処女 | 处女 |" & @CRLF & _
    "| 絶倫 | 猛男 |" & @CRLF & @CRLF & _
    "### 八、职业与角色扮演" & @CRLF & @CRLF & _
    "| 原文 | 标准译法 |" & @CRLF & _
    "|---|---|" & @CRLF & _
    "| 女教師 | 女教师 |" & @CRLF & _
    "| 家庭教師 | 家教 |" & @CRLF & _
    "| ナース / 看護師 | 护士 |" & @CRLF & _
    "| メイド | 女仆 |" & @CRLF & _
    "| 秘書 | 秘书 |" & @CRLF & _
    "| OL | 白领 |" & @CRLF & _
    "| キャビンアテンダント | 空姐 |" & @CRLF & _
    "| 寮母 | 宿管阿姨 |" & @CRLF & _
    "| 管理人 | 管理员 |" & @CRLF & _
    "| スチュワーデス | 空乘 |" & @CRLF & _
    "| コスプレ | 角色扮演 |" & @CRLF & _
    "| セーラー服 | 水手服 |" & @CRLF & _
    "| 制服 | 制服 |" & @CRLF & @CRLF & _
    "### 九、场景与地点" & @CRLF & @CRLF & _
    "| 原文 | 标准译法 |" & @CRLF & _
    "|---|---|" & @CRLF & _
    "| ベッド | 床 |" & @CRLF & _
    "| ソファ | 沙发 |" & @CRLF & _
    "| 浴室 / 風呂 | 浴室 / 浴缸 |" & @CRLF & _
    "| シャワー | 淋浴 |" & @CRLF & _
    "| 車内 | 车内 |" & @CRLF & _
    "| 野外 | 野外 |" & @CRLF & _
    "| 電車 | 电车 |" & @CRLF & _
    "| オフィス | 办公室 |" & @CRLF & _
    "| 教室 | 教室 |" & @CRLF & _
    "| 体育倉庫 | 体育仓库 |" & @CRLF & _
    "| トイレ | 厕所 |" & @CRLF & _
    "| 洗面所 | 洗手间 |" & @CRLF & _
    "| 玄関 | 玄关 |" & @CRLF & _
    "| 温泉 | 温泉 |" & @CRLF & _
    "| 旅館 | 旅馆 |" & @CRLF & _
    "| エステ | 美容院 |" & @CRLF & _
    "| マッサージ | 按摩 |" & @CRLF & _
    "| 出張 | 上门 |" & @CRLF & @CRLF & _
    "### 十、类型与题材" & @CRLF & @CRLF & _
    "| 原文 | 标准译法 |" & @CRLF & _
    "|---|---|" & @CRLF & _
    "| ドラマ | 剧情 |" & @CRLF & _
    "| モザイク | 打码 |" & @CRLF & _
    "| 無修正 | 无码 |" & @CRLF & _
    "| 単体 | 单体（独立出演） |" & @CRLF & _
    "| 共演 | 合演 |" & @CRLF & _
    "| ハーレム | 后宫 |" & @CRLF & _
    "| 逆ハーレム | 逆后宫 |" & @CRLF & _
    "| 巨乳 | 巨乳 |" & @CRLF & _
    "| 爆乳 | 爆乳 |" & @CRLF & _
    "| 美乳 | 美乳 |" & @CRLF & _
    "| 貧乳 | 贫乳 |" & @CRLF & _
    "| 美脚 | 美腿 |" & @CRLF & _
    "| 美尻 | 美臀 |" & @CRLF & _
    "| 色白 | 肤白 |" & @CRLF & _
    "| 童顔 | 童颜 |" & @CRLF & _
    "| 清楚 | 清纯 |" & @CRLF & _
    "| スレンダー | 苗条 |" & @CRLF & _
    "| グラマー | 丰满 |" & @CRLF & _
    "| ロリ | 萝莉 |" & @CRLF & _
    "| 年下 / 年上 | 年下 / 年上 |" & @CRLF & _
    "| いいなり | 百依百顺 |" & @CRLF & _
    "| 淫乱 | 淫乱 |" & @CRLF & _
    "| 敏感 | 敏感 |" & @CRLF & _
    "| 初撮り | 首拍 |" & @CRLF & _
    "| 初セックス / 初体験 | 初次做爱 / 初次体验 |" & @CRLF & _
    "| デビュー | 出道 |" & @CRLF & _
    "| 引退 | 引退 |" & @CRLF & _
    "| 復活 | 复出 |" & @CRLF & _
    "| 特典 | 特典 |" & @CRLF & _
    "| 完全版 | 完整版 |" & @CRLF & _
    "| 収録 | 收录 |" & @CRLF & @CRLF & _
    "### 十一、状态描写" & @CRLF & @CRLF & _
    "| 原文 | 标准译法 |" & @CRLF & _
    "|---|---|" & @CRLF & _
    "| 絶頂 | 高潮 |" & @CRLF & _
    "| イク | 去了 / 高潮 |" & @CRLF & _
    "| イキまくり | 连连高潮 |" & @CRLF & _
    "| 絶叫 | 浪叫 |" & @CRLF & _
    "| 痙攣 | 痉挛 |" & @CRLF & _
    "| 白目 | 翻白眼 |" & @CRLF & _
    "| 失神 | 失神 |" & @CRLF & _
    "| 発情 | 发情 |" & @CRLF & _
    "| 欲求不満 | 欲求不满 |" & @CRLF & _
    "| ムラムラ | 性欲上头 / 饥渴 |" & @CRLF & _
    "| ドキドキ | 心跳加速 |" & @CRLF & _
    "| 悶える | 难耐扭动 |" & @CRLF & _
    "| 酔っ払い | 喝醉 |" & @CRLF & @CRLF & _
    "## 片名翻译规则" & @CRLF & @CRLF & _
    "- 保留原文：番号（STARS-xxx 等）、演员名、片商/品牌名（S1、MOODYZ 等）、系列名、全部数字。" & @CRLF & _
    "- 中文部分简短有力、符合中文命名习惯，如「放課後」译「放学后」，不硬搬日语汉字。" & @CRLF & @CRLF & _
    "## 简介翻译规则" & @CRLF & @CRLF & _
    "- 逐字逐句完整翻译，任何细节不得遗漏：人物关系、地点、时间线、先后顺序、动作步骤、体位、过程、次数、数量。" & @CRLF & _
    "- 性行为、口交、乳交、颜射、内射、肛交、自慰、调教、性玩具等场景一律用最直白的词描述，身体部位用俗名直说（鸡巴、屄、奶子、屁眼）。" & @CRLF & _
    "- 人物称呼按原文如实翻译（妈妈、姐姐、女儿、侄女、老师、护士、女仆等），不回避、不美化、不文艺化。" & @CRLF & _
    "- 保留原文段落结构；原文若有 HTML/XML 标签（如 <br/>），原样保留不动。" & @CRLF & _
    "- 拿不准的词按字面直译，不猜不编。" & @CRLF & @CRLF & _
    "## 禁止事项" & @CRLF & @CRLF & _
    "- 不添加原文没有的内容、不臆测背景。" & @CRLF & _
    "- 不用「亲密」「缠绵」「交融」「鱼水之欢」等模糊或文艺表述。" & @CRLF & _
    "- 不翻译：URL、标签（genre）、番号、演员罗马音名。" & @CRLF & _
    "- 不输出任何解释、说明、备注。" & @CRLF & @CRLF & _
    "## 输出格式（严格照此顺序，只输出结果）" & @CRLF & @CRLF & _
    "```" & @CRLF & _
    "【中文标题】{翻译后的标题}" & @CRLF & @CRLF & _
    "{完整中文简介}" & @CRLF & @CRLF & _
    "原文：" & @CRLF & _
    "{原文标题}" & @CRLF & _
    "{原文简介，逐字保留，一字不落}" & @CRLF & _
    "```" & @CRLF & @CRLF & _
    "各部分之间空一行，其余不输出任何内容。" & @CRLF & @CRLF & _
    "## 输出前自查（在心中完成，不得外显）" & @CRLF & @CRLF & _
    "1. 原文每一句是否都有对应译文？" & @CRLF & _
    "2. 人物关系、动作、次数、时间线是否全部对得上？" & @CRLF & _
    "3. 是否所有性场面都用了最直白的词？" & @CRLF & _
    "4. 术语是否与对照表一致？" & @CRLF & @CRLF & _
    "---" & @CRLF & @CRLF & _
    "原始标题：{title}" & @CRLF & "原始简介：{plot}"

Global $g_sSettingsFile = @LocalAppDataDir & "\MediaResourceToolbox\nfo_editor_settings.ini"
Global $g_sDeepSeekApiUrl = $DEFAULT_DEEPSEEK_API_URL
Global $g_sDeepSeekApiKey = ""
Global $g_sDeepSeekModel = $DEFAULT_DEEPSEEK_MODEL
Global $g_sLocalizePrompt = $DEFAULT_LOCALIZE_PROMPT

; 文件元数据缓存: [relative_path, country, languages, full_path]
Global $g_aFileMetadata[1][4]
Global $g_iFileCount = 0

; 主 GUI 控件 ID
Global $g_idBtnOpen, $g_idBtnSave, $g_idBtnSaveAs, $g_idBtnRefresh
Global $g_idList, $g_idFileSearch
Global $g_idBtnCheckAll, $g_idBtnCheckNone, $g_idBtnBatchLocalize
; 文件列表 ListView 的句柄，用于在 WM_NOTIFY 中识别来源控件
Global $g_hFileList = 0
; ListView 选择变更在 WM_NOTIFY 中只置标记，由主循环处理：
; 通知回调里直接弹 MsgBox（_ConfirmDiscardChanges）会阻塞消息处理并可能重入。
Global $g_bPendingFileSelect = False
Global $g_idBtnSelectDir, $g_idDirLabel
Global $g_idStatusBar, $g_idStatusDot, $g_idTab
Global $g_idCurrentFileLabel, $g_idFileCountLabel
Global $g_idProgressBar = 0 ; 批量汉化进度条，平时隐藏

; 演员 ListView 的句柄缓存，用于在 WM_NOTIFY 中识别按键事件
Global $g_hActorList = 0
; 演员 ListView 的 Del 键事件标记，由主循环处理避免重入
Global $g_bPendingActorDelete = False

; 字段映射: 基本信息 [label, xml_tag, control_id]；视频 [label, xml_tag, control_id]；音频 [label, xml_tag, control_id, is_combo]
Global $g_aBasicFields[13][3] = [ _
    ["标题", "title", 0], ["原标题", "originaltitle", 0], _
    ["编号", "num", 0], ["发行日期", "premiered", 0], ["发行说明", "tagline", 0], _
    ["年份", "year", 0], ["时长/分钟", "runtime", 0], ["国家代码", "countrycode", 0], _
    ["制片商", "studio", 0], ["系列", "series", 0], ["DMM链接", "dmmid", 0], _
    ["JavDB链接", "javdbsearchid", 0], ["剧情简介", "plot", 0]]
Global $g_idSetName, $g_idTagText, $g_idGenreText

Global $g_aVideoFields[8][3] = [ _
    ["编码 (codec)", "codec", 0], ["码率 (bitrate)", "bitrate", 0], ["宽度 (width)", "width", 0], _
    ["高度 (height)", "height", 0], ["宽高比 (aspect)", "aspect", 0], ["帧率 (framerate)", "framerate", 0], _
    ["扫描类型 (scantype)", "scantype", 0], ["时长/分钟 (duration)", "duration", 0]]

Global $g_aAudioFields[5][4] = [ _
    ["编码 (codec)", "codec", 0, 0], ["码率 (bitrate)", "bitrate", 0, 0], _
    ["语言 (language)", "language", 0, 1], ["声道数 (channels)", "channels", 0, 0], _
    ["采样率 (samplingrate)", "samplingrate", 0, 0]]

; 演员 ListView
Global $g_idActorList, $g_idBtnAddActor, $g_idBtnRemoveActor

; XML 源码
Global $g_idXmlText, $g_idBtnSync, $g_idBtnRefreshXml

; 设置页
Global $g_idSettingsApiUrl, $g_idSettingsApiKey, $g_idSettingsModel, $g_idSettingsPrompt
Global $g_idBtnSaveSettings, $g_idBtnResetPrompt, $g_idBtnTestApi

; 演员对话框控件
Global $g_idActorName, $g_idActorRole, $g_idActorType, $g_idActorTmdbId
Global $g_idActorOk, $g_idActorCancel

; COM 错误处理
Global $g_bComError = False
Global $g_sComErrorDesc = ""

; 无边框窗口控制按钮数组索引
Global Const $UI_BTN_CLOSE = 0
Global Const $UI_BTN_MINIMIZE = 3

; 编辑控件句柄缓存（避免每次 EN_CHANGE 重复调用 GUICtrlGetHandle）
Global $g_hXmlText = 0
Global $g_hSetName = 0
Global $g_hTagText = 0
Global $g_hGenreText = 0
Global $g_hFileSearch = 0
Global $g_aBasicFieldHandles[0]
Global $g_aVideoFieldHandles[0]
Global $g_aAudioFieldHandles[0]

; 文件搜索防抖计时器
Global $g_iSearchDebounceTimer = 0
Global Const $DEBOUNCE_DELAY = 300 ; ms

; 音频语言下拉框（ComboBox 的变更不会触发 EN_CHANGE，需在主循环单独处理）
; 初值取 -1：GUIGetMsg 无事件时返回 0，若初值为 0 会被 Switch 误命中。
Global $g_idAudioLangCombo = -1

; 反转义占位符：使用 Unicode 私有区字符，避免 NUL 在经过 WinAPI 时截断字符串
Global Const $ESCAPE_SENTINEL = ChrW(0xE000)

#EndRegion ;**** 配置与全局变量 ****

#Region ;**** COM 错误与工具函数 ****
; ==================== COM 错误处理 ====================
Func _ComErrorHandler($oError)
    $g_bComError = True
    $g_sComErrorDesc = "COM 错误 #" & Hex($oError.number, 8) & ": " & $oError.description
EndFunc

Func _ResetComError()
    $g_bComError = False
    $g_sComErrorDesc = ""
EndFunc

; ==================== 工具函数 ====================

; 从完整路径提取文件名
Func _GetFileName($sPath)
    Return StringRegExpReplace($sPath, "^.*[\\/]", "")
EndFunc

Func _IniEncode($sText)
    $sText = StringReplace($sText, "\", "\\")
    $sText = StringReplace($sText, @CRLF, "\n")
    $sText = StringReplace($sText, @CR, "\n")
    $sText = StringReplace($sText, @LF, "\n")
    Return $sText
EndFunc

Func _IniDecode($sText)
    ; 使用私有区占位符避免 \n 与 \\n 冲突：先标记 \\，再解码 \n，最后恢复占位符
    $sText = StringReplace($sText, "\\", $ESCAPE_SENTINEL)
    $sText = StringReplace($sText, "\n", @CRLF)
    $sText = StringReplace($sText, $ESCAPE_SENTINEL, "\")
    Return $sText
EndFunc

Func _LoadSettings()
    $g_sDeepSeekApiUrl = IniRead($g_sSettingsFile, "DeepSeek", "ApiUrl", $DEFAULT_DEEPSEEK_API_URL)
    $g_sDeepSeekApiKey = IniRead($g_sSettingsFile, "DeepSeek", "ApiKey", "")
    $g_sDeepSeekModel = IniRead($g_sSettingsFile, "DeepSeek", "Model", $DEFAULT_DEEPSEEK_MODEL)
    $g_sLocalizePrompt = _IniDecode(IniRead($g_sSettingsFile, "DeepSeek", "Prompt", _IniEncode($DEFAULT_LOCALIZE_PROMPT)))

    If StringStripWS($g_sDeepSeekApiUrl, 3) = "" Then $g_sDeepSeekApiUrl = $DEFAULT_DEEPSEEK_API_URL
    If StringStripWS($g_sDeepSeekModel, 3) = "" Then $g_sDeepSeekModel = $DEFAULT_DEEPSEEK_MODEL
    If StringStripWS($g_sLocalizePrompt, 3) = "" Then $g_sLocalizePrompt = $DEFAULT_LOCALIZE_PROMPT
EndFunc

Func _SaveSettings()
    Local $bOk = True
    If IniWrite($g_sSettingsFile, "DeepSeek", "ApiUrl", $g_sDeepSeekApiUrl) = 0 Then $bOk = False
    ; API Key 按产品设计明文持久化，这里只补充写入结果检查。
    If IniWrite($g_sSettingsFile, "DeepSeek", "ApiKey", $g_sDeepSeekApiKey) = 0 Then $bOk = False
    If IniWrite($g_sSettingsFile, "DeepSeek", "Model", $g_sDeepSeekModel) = 0 Then $bOk = False
    If IniWrite($g_sSettingsFile, "DeepSeek", "Prompt", _IniEncode($g_sLocalizePrompt)) = 0 Then $bOk = False
    Return $bOk
EndFunc

; 返回文件实际编码；目标不存在或检测失败时使用回退值。
Func _GetNfoFileEncoding($sFilePath, $iFallback = 256)
    If Not FileExists($sFilePath) Then Return $iFallback
    Local $iEncoding = FileGetEncoding($sFilePath)
    If Not @error And $iEncoding > 0 Then Return $iEncoding

    ; 无 BOM 时依据 XML 声明识别 UTF-16/ANSI；未声明则按常见 NFO 的 UTF-8 处理。
    Local $hProbe = FileOpen($sFilePath, 16)
    If $hProbe <> -1 Then
        Local $sHeader = BinaryToString(FileRead($hProbe, 2048), 1)
        FileClose($hProbe)
        Local $aEncoding = StringRegExp($sHeader, '(?i)encoding\s*=\s*["'']([^"'']+)["'']', 1)
        If UBound($aEncoding) > 0 Then
            Local $sDeclared = StringLower(StringStripWS($aEncoding[0], 3))
            If StringInStr($sDeclared, "utf-16be") > 0 Then Return 64
            If StringInStr($sDeclared, "utf-16") > 0 Then Return 32
            If StringInStr($sDeclared, "utf-8") > 0 Then Return 256
            Return 512 ; 其他 XML 编码使用系统 ANSI 代码页读取，避免强制按 UTF-8 解码。
        EndIf
    EndIf
    Return $iFallback
EndFunc

; 元数据签名作为 SHA-256 不可用时的回退方案。
Func _GetNfoFallbackSignature($sFilePath)
    If Not FileExists($sFilePath) Then Return ""
    Local $iSize = FileGetSize($sFilePath)
    Local $vTime = FileGetTime($sFilePath, 0, 1)
    If @error Then Return "META|" & String($iSize)
    Return "META|" & String($iSize) & "|" & String($vTime)
EndFunc

; 以 SHA-256 内容哈希检测外部修改。
; 使用分块读取，避免将大 NFO 文件一次性载入内存；CryptoAPI 失败时回退到大小/时间签名。
Func _GetNfoFileSignature($sFilePath)
    If Not FileExists($sFilePath) Then Return ""

    Local $hFile = FileOpen($sFilePath, 16) ; Binary
    If $hFile = -1 Then Return _GetNfoFallbackSignature($sFilePath)

    ; PROV_RSA_AES = 24；CRYPT_VERIFYCONTEXT = 0xF0000000。
    Local $aAcquire = DllCall("Advapi32.dll", "bool", "CryptAcquireContextW", _
        "handle*", 0, "ptr", 0, "ptr", 0, "dword", 24, "dword", 0xF0000000)
    Local $iAcquireError = @error
    If $iAcquireError <> 0 Then
        FileClose($hFile)
        Return _GetNfoFallbackSignature($sFilePath)
    EndIf
    If Not IsArray($aAcquire) Then
        FileClose($hFile)
        Return _GetNfoFallbackSignature($sFilePath)
    EndIf
    If Not $aAcquire[0] Then
        FileClose($hFile)
        Return _GetNfoFallbackSignature($sFilePath)
    EndIf
    Local $hProvider = $aAcquire[1]

    ; CALG_SHA_256 = 0x0000800C。
    Local $aCreate = DllCall("Advapi32.dll", "bool", "CryptCreateHash", _
        "handle", $hProvider, "dword", 0x0000800C, "handle", 0, "dword", 0, "handle*", 0)
    Local $iCreateError = @error
    If $iCreateError <> 0 Then
        DllCall("Advapi32.dll", "bool", "CryptReleaseContext", "handle", $hProvider, "dword", 0)
        FileClose($hFile)
        Return _GetNfoFallbackSignature($sFilePath)
    EndIf
    If Not IsArray($aCreate) Then
        DllCall("Advapi32.dll", "bool", "CryptReleaseContext", "handle", $hProvider, "dword", 0)
        FileClose($hFile)
        Return _GetNfoFallbackSignature($sFilePath)
    EndIf
    If Not $aCreate[0] Then
        DllCall("Advapi32.dll", "bool", "CryptReleaseContext", "handle", $hProvider, "dword", 0)
        FileClose($hFile)
        Return _GetNfoFallbackSignature($sFilePath)
    EndIf
    Local $hHash = $aCreate[5]

    Local $bHashOk = True
    While 1
        Local $bChunk = FileRead($hFile, 1048576)
        Local $iReadError = @error
        If $iReadError Then
            $bHashOk = False
            ExitLoop
        EndIf

        Local $iChunkSize = BinaryLen($bChunk)
        If $iChunkSize = 0 Then ExitLoop

        Local $tChunk = DllStructCreate("byte[" & $iChunkSize & "]")
        If @error Then
            $bHashOk = False
            ExitLoop
        EndIf
        DllStructSetData($tChunk, 1, $bChunk)
        If @error Then
            $bHashOk = False
            ExitLoop
        EndIf

        Local $aHashData = DllCall("Advapi32.dll", "bool", "CryptHashData", _
            "handle", $hHash, "ptr", DllStructGetPtr($tChunk), "dword", $iChunkSize, "dword", 0)
        Local $iHashDataError = @error
        If $iHashDataError <> 0 Then
            $bHashOk = False
            ExitLoop
        EndIf
        If Not IsArray($aHashData) Then
            $bHashOk = False
            ExitLoop
        EndIf
        If Not $aHashData[0] Then
            $bHashOk = False
            ExitLoop
        EndIf
    WEnd

    Local $sSignature = ""
    If $bHashOk Then
        Local $tHash = DllStructCreate("byte[32]")
        Local $iHashSize = 32
        Local $aGetHash = DllCall("Advapi32.dll", "bool", "CryptGetHashParam", _
            "handle", $hHash, "dword", 0x0002, "ptr", DllStructGetPtr($tHash), "dword*", $iHashSize, "dword", 0)
        Local $iGetHashError = @error
        If $iGetHashError = 0 Then
            If IsArray($aGetHash) Then
                If $aGetHash[0] And Number($aGetHash[4]) = 32 Then
                    For $i = 1 To 32
                        $sSignature &= Hex(DllStructGetData($tHash, 1, $i), 2)
                    Next
                    $sSignature = "SHA256|" & $sSignature
                EndIf
            EndIf
        EndIf
    EndIf

    DllCall("Advapi32.dll", "bool", "CryptDestroyHash", "handle", $hHash)
    DllCall("Advapi32.dll", "bool", "CryptReleaseContext", "handle", $hProvider, "dword", 0)
    FileClose($hFile)

    If $sSignature = "" Then Return _GetNfoFallbackSignature($sFilePath)
    Return $sSignature
EndFunc

; XML 转义
Func _XmlEscape($sText)
    If $sText = "" Then Return ""
    $sText = StringReplace($sText, "&", "&amp;")
    $sText = StringReplace($sText, "<", "&lt;")
    $sText = StringReplace($sText, ">", "&gt;")
    Return $sText
EndFunc

; XML 反转义（&amp; 必须最后处理，否则 &amp;lt; 会被二次解码成 <）
Func _XmlUnescape($sText)
    If $sText = "" Then Return ""
    $sText = StringReplace($sText, "&lt;", "<")
    $sText = StringReplace($sText, "&gt;", ">")
    $sText = StringReplace($sText, "&quot;", '"')
    $sText = StringReplace($sText, "&apos;", "'")
    $sText = StringReplace($sText, "&amp;", "&")
    Return $sText
EndFunc

; 只保留 DMM 链接里的 id 参数，丢弃 i3_ref / i3_ord 等搜索页跟踪参数。
; 格式不符合预期（没有 ? 或没有 id=）时原样返回，不强行改动。
Func _CleanDmmId($sUrl)
    Local $sTrimmed = StringStripWS($sUrl, 3)
    If $sTrimmed = "" Then Return ""

    Local $iQueryPos = StringInStr($sTrimmed, "?")
    If $iQueryPos = 0 Then Return $sTrimmed

    Local $sBase = StringLeft($sTrimmed, $iQueryPos - 1)
    Local $sQuery = StringMid($sTrimmed, $iQueryPos + 1)

    Local $aId = StringRegExp($sQuery, "(?:^|&)id=([^&]+)", 1)
    If UBound($aId) = 0 Then Return $sTrimmed

    Return $sBase & "?id=" & $aId[0]
EndFunc

; 修复常见 NFO 中 URL 等文本里的未转义 ampersand，不改动已合法的 XML 实体。
Func _XmlRepairInvalidAmpersands($sText)
    If $sText = "" Then Return ""
    Return StringRegExpReplace($sText, "&(?!amp;|lt;|gt;|quot;|apos;|#\d+;|#x[0-9A-Fa-f]+;)", "&amp;")
EndFunc

; 创建 MSXML DOMDocument 对象（带降级）
Func _CreateXmlDoc()
    Local $oDoc = ObjCreate("Msxml2.DOMDocument.6.0")
    If Not IsObj($oDoc) Then
        $oDoc = ObjCreate("Msxml2.DOMDocument.3.0")
    EndIf
    If Not IsObj($oDoc) Then
        $oDoc = ObjCreate("Microsoft.XMLDOM")
    EndIf
    If IsObj($oDoc) Then
        $oDoc.async = False
        $oDoc.preserveWhiteSpace = True
        $oDoc.resolveExternals = False
    EndIf
    Return $oDoc
EndFunc

; 从 MSXML parseError 构造友好的解析错误详情（原因 + 行列）
Func _XmlParseErrorDetail($oDoc)
    Local $sDetail = ""
    Local $sReason = StringStripWS($oDoc.parseError.reason, 3)
    If $sReason = "" Then Return $sDetail
    $sDetail = @CRLF & "原因: " & $sReason
    If $oDoc.parseError.line > 0 Then
        $sDetail &= @CRLF & "位置: 第 " & $oDoc.parseError.line & " 行, 第 " & $oDoc.parseError.linepos & " 列"
    EndIf
    If StringStripWS($oDoc.parseError.srcText, 3) <> "" Then
        $sDetail &= @CRLF & "内容: " & $oDoc.parseError.srcText
    EndIf
    Return $sDetail
EndFunc

; 获取 XML 元素文本
Func _XmlGetText($oRoot, $sTagName, $sDefault = "")
    If Not IsObj($oRoot) Then Return $sDefault
    ; local-name() 同时兼容无命名空间和默认命名空间的 NFO。
    Local $oNode = $oRoot.selectSingleNode("*[local-name()='" & $sTagName & "']")
    If IsObj($oNode) Then
        Local $sText = $oNode.text
        If $sText <> "" Then Return $sText
    EndIf
    Return $sDefault
EndFunc

; 获取同名 XML 节点，并按行合并显示
Func _XmlGetJoinedText($oRoot, $sTagName, $sSeparator = @CRLF)
    If Not IsObj($oRoot) Then Return ""
    Local $oNodes = $oRoot.selectNodes("*[local-name()='" & $sTagName & "']")
    If Not IsObj($oNodes) Then Return ""

    Local $sResult = ""
    For $i = 0 To $oNodes.length - 1
        Local $sValue = StringStripWS($oNodes.item($i).text, 3)
        If $sValue <> "" Then
            If $sResult <> "" Then $sResult &= $sSeparator
            $sResult &= $sValue
        EndIf
    Next
    Return $sResult
EndFunc

; 获取 <set><name>...</name></set> 中的合集名称
Func _XmlGetSetName($oRoot)
    If Not IsObj($oRoot) Then Return ""
    Local $oName = $oRoot.selectSingleNode("*[local-name()='set']/*[local-name()='name']")
    If IsObj($oName) Then Return StringStripWS($oName.text, 3)
    Return ""
EndFunc

; 递归扫描目录中的 .nfo 文件
Func _ScanNfoFiles($sDir)
    Local $aFiles[0]
    _ScanNfoFilesRecursive($sDir, $aFiles)
    Return $aFiles
EndFunc

Func _ScanNfoFilesRecursive($sDir, ByRef $aFiles)
    Local $hSearch = FileFindFirstFile($sDir & "\*")
    If $hSearch = -1 Then Return

    While 1
        Local $sFile = FileFindNextFile($hSearch)
        If @error Then ExitLoop
        If @extended Then
            ; 目录 → 递归
            ; 工具生成的备份不属于可编辑源文件，避免刷新后重复出现在列表中。
            ; 新版备份统一放在 nfo_backup 下，精确排除该目录。
            If StringLower($sFile) = "nfo_backup" Then ContinueLoop
            If StringLeft(StringLower($sFile), StringLen("nfo备份_")) <> StringLower("nfo备份_") Then
                _ScanNfoFilesRecursive($sDir & "\" & $sFile, $aFiles)
            EndIf
        Else
            ; 文件 → 检查扩展名
            If StringLower(StringRight($sFile, 4)) = ".nfo" Then
                _ArrayAdd($aFiles, $sDir & "\" & $sFile)
            EndIf
        EndIf
    WEnd

    FileClose($hSearch)
EndFunc

; 从 NFO 文件提取国家与语言元数据
Func _ExtractMetadata($sFilePath, ByRef $sCountry, ByRef $sLanguages)
    $sCountry = ""
    $sLanguages = ""
    Local $oDoc = _CreateXmlDoc()
    If Not IsObj($oDoc) Then Return

    If $oDoc.load($sFilePath) Then
        Local $oRoot = $oDoc.documentElement
        If IsObj($oRoot) Then
            Local $oCountry = $oRoot.selectSingleNode("*[local-name()='country']")
            If Not IsObj($oCountry) Then $oCountry = $oRoot.selectSingleNode("*[local-name()='countrycode']")
            If IsObj($oCountry) Then $sCountry = StringStripWS($oCountry.text, 3)

            Local $oLangs = $oRoot.selectSingleNode("*[local-name()='languages']")
            If IsObj($oLangs) Then $sLanguages = StringStripWS($oLangs.text, 3)
        EndIf
    EndIf
EndFunc

#EndRegion ;**** COM 错误与工具函数 ****

#Region ;**** 正则标签替换引擎 ****
; ==================== 正则工具：差量写回 ====================
;
; 写回原则：编辑器只对 NFO 中【已存在】的标签做原地文本替换。
; - 原文件没有的标签，即使表单里填了值也不写入（不凭空造字段）。
; - 原文件有而编辑器未映射的标签（如 <rating>、<uniqueid>）原样保留，不做任何处理。
; - 已存在的标签清空后写成空内容（<studio></studio>），保留标签本身，不改变文档结构。
; 唯一的结构性增删发生在同类型标签的条目数量上（<tag>/<genre>/<actor>），
; 且仅当该标签类型在原文件中已经出现过。

; 转义正则替换串中的特殊字符。AutoIt 的替换串同时支持 \1 和 $1 两种反向引用，
; 因此反斜杠和美元符号都必须转义，否则值中的 "\1" 会被当作反向引用吞掉。
Func _EscapeReplacement($sText)
    $sText = StringReplace($sText, "\", "\\")
    $sText = StringReplace($sText, "$", "$$")
    Return $sText
EndFunc

; 推断 <movie> 直接子元素的缩进，用于新增同类型条目时保持排版一致
Func _DetectChildIndent($sText)
    Local $aIndent = StringRegExp($sText, '<movie(?:\s[^>]*)?>[ \t]*(?:\r\n|\n|\r)([ \t]+)<', 1)
    If UBound($aIndent) > 0 Then Return $aIndent[0]
    Return "  "
EndFunc

; 替换第一个 <tag>...</tag> 的内容（保留注释与属性）
Func _ReplaceSimpleTagOnce($sText, $sTag, $sNewValue)
    Local $sPattern = '(<!--[\s\S]*?-->\s*)?<' & $sTag & '(\s[^>]*)?>([\s\S]*?)</' & $sTag & '>'
    Local $sReplacement = '${1}<' & $sTag & '${2}>' & _EscapeReplacement($sNewValue) & '</' & $sTag & '>'
    Return StringRegExpReplace($sText, $sPattern, $sReplacement, 1)
EndFunc

; 写回单个标签：仅当标签已存在时原地替换内容。
; 不存在则整个跳过 —— 按设计，编辑器不为 NFO 添加原本没有的字段。
Func _UpdateSimpleTagIfPresent($sText, $sTag, $sNewValue)
    ; 成对标签：原地替换文本；值为空则写成空内容，保留标签本身
    If StringRegExp($sText, '<' & $sTag & '(?:\s[^>]*)?>[\s\S]*?</' & $sTag & '>') Then
        Return _ReplaceSimpleTagOnce($sText, $sTag, $sNewValue)
    EndIf

    ; 自闭合标签（部分刮削器会写出 <year/>）：有值时就地展开为成对标签，
    ; 这仍属于原地修改已有字段，不是新增。
    If StringRegExp($sText, '<' & $sTag & '(?:\s[^>]*)?/>') Then
        If $sNewValue = "" Then Return $sText
        Return StringRegExpReplace($sText, '<' & $sTag & '(?:\s[^>]*)?/>', _
            _EscapeReplacement("<" & $sTag & ">" & $sNewValue & "</" & $sTag & ">"), 1)
    EndIf

    ; 标签不存在 → 忽略
    Return $sText
EndFunc

; 更新多个同名标签，保留原始排版。
; 条目数可增可减，但仅在该标签类型原本就存在于 NFO 中时才处理；
; 原文件完全没有此类标签时整体跳过，不凭空创建。
Func _ReplaceRepeatedTagsPreserveLayout($sText, $sTag, $sValuesText)
    Local $sPattern = '<' & $sTag & '(?:\s[^>]*)?>[\s\S]*?</' & $sTag & '>'
    Local $aMatches = StringRegExp($sText, $sPattern, 3)
    Local $iExistingCount = UBound($aMatches)
    ; 原文件没有此类标签 → 忽略表单内容
    If $iExistingCount = 0 Then Return $sText

    Local $sNormalized = StringReplace($sValuesText, @CRLF, @LF)
    $sNormalized = StringReplace($sNormalized, @CR, @LF)

    ; 仅按换行切分。原实现同时按逗号切分，会把值内含逗号的标签
    ; （如 "寝取り?寝取られ?NTR, 特典"）拆成两个标签，往返不对称。
    Local $iValueCount = 0
    Local $aValues[0]
    If StringStripWS($sNormalized, 3) <> "" Then
        Local $aRaw = StringSplit($sNormalized, @LF, 2)
        For $i = 0 To UBound($aRaw) - 1
            Local $sTrimmed = StringStripWS($aRaw[$i], 3)
            If $sTrimmed <> "" Then
                ReDim $aValues[$iValueCount + 1]
                $aValues[$iValueCount] = $sTrimmed
                $iValueCount += 1
            EndIf
        Next
    EndIf

    ; 检测已有标签的缩进，供新增条目沿用
    Local $sIndent = _DetectChildIndent($sText)
    Local $iFirstPos = StringInStr($sText, $aMatches[0], 2)
    If $iFirstPos > 1 Then
        Local $aIndent = StringRegExp(StringMid($sText, 1, $iFirstPos - 1), "([ \t]+)$", 1)
        If UBound($aIndent) > 0 Then $sIndent = $aIndent[0]
    EndIf

    ; 按原始匹配位置逐个重建，避免每次都覆盖第一个同名节点
    Local $sResult = ""
    Local $iPos = 1
    Local $iLastTagEnd = 0
    For $i = 0 To $iExistingCount - 1
        Local $sMatch = $aMatches[$i]
        ; 使用区分大小写的查找（flag=2）
        Local $iMatchPos = StringInStr($sText, $sMatch, 2, 1, $iPos)
        If $iMatchPos = 0 Then ExitLoop

        $sResult &= StringMid($sText, $iPos, $iMatchPos - $iPos)
        If $i < $iValueCount Then
            $sResult &= _ReplaceTagInBlock($sMatch, $sTag, _XmlEscape($aValues[$i]))
        Else
            ; 条目变少 → 删除多余标签。只回退本行的前导换行与缩进，
            ; 保留标签后的换行，否则前后两行会被拼到一起。
            $sResult = StringRegExpReplace($sResult, '(?:\r\n|\n|\r)[ \t]*$', "")
        EndIf
        $iPos = $iMatchPos + StringLen($sMatch)
        ; 同步更新追加位置：删除分支回退了换行缩进，$sResult 长度已变化，
        ; 必须在此处重新取长度，否则后续追加新条目会插到错误位置。
        $iLastTagEnd = StringLen($sResult)
    Next

    Local $sTail = StringMid($sText, $iPos)

    ; 条目变多 → 紧跟在最后一个同名标签之后追加，保持同类标签聚集
    If $iValueCount > $iExistingCount And $iLastTagEnd > 0 Then
        Local $sExtra = ""
        For $i = $iExistingCount To $iValueCount - 1
            $sExtra &= @CRLF & $sIndent & "<" & $sTag & ">" & _XmlEscape($aValues[$i]) & "</" & $sTag & ">"
        Next
        $sResult = StringLeft($sResult, $iLastTagEnd) & $sExtra & StringMid($sResult, $iLastTagEnd + 1)
    EndIf

    Return $sResult & $sTail
EndFunc

; 更新 <set><name>...</name></set> 中的合集名称。
; 原文件没有 <set> 时忽略；有 <set> 且清空值时写成空内容，不删除标签。
Func _ReplaceSetNamePreserveLayout($sText, $sValue)
    Local $sValueEscaped = _XmlEscape(StringStripWS($sValue, 3))
    Local $sPattern = '<set(?:\s[^>]*)?>[\s\S]*?</set>'
    Local $aMatches = StringRegExp($sText, $sPattern, 3)
    ; 原文件没有 <set> → 忽略
    If UBound($aMatches) = 0 Then Return $sText

    Local $sBlock = $aMatches[0]
    Local $sNewBlock
    If StringRegExp($sBlock, '<name(?:\s[^>]*)?>[\s\S]*?</name>') Then
        $sNewBlock = _ReplaceTagInBlock($sBlock, "name", $sValueEscaped)
    Else
        ; 没有 <name> 时保持整个块不变，避免误删 overview、标识符或注释。
        Return $sText
    EndIf
    Return StringReplace($sText, $sBlock, $sNewBlock, 1)
EndFunc

; 在块内替换单个标签内容；标签不存在时不做改动（StringRegExpReplace
; 匹配不到时返回原串，不会产生副作用）。按设计，编辑器不为块补充
; 原本没有的子字段（例如不给只有 <name> 的 <actor> 补出 <role>、<tmdbid>）。
Func _ReplaceTagInBlock($sBlockText, $sTag, $sNewValue)
    Local $sPattern = '(<' & $sTag & '(?:\s[^>]*)?>)([\s\S]*?)(</' & $sTag & '>)'
    Local $sReplacement = '${1}' & _EscapeReplacement($sNewValue) & '${3}'
    Return StringRegExpReplace($sBlockText, $sPattern, $sReplacement, 1)
EndFunc

; 更新多个同名块（如 <actor>、<video>、<audio>）。
; 原文件没有该类型块时整体跳过，不凭空创建容器和块。
; $bAllowCountChange = True：块的条目数随表单增减（<actor> 需要该行为）。
; $bAllowCountChange = False：只更新第一个块，多余块原样保留 ——
;     <video>/<audio> 允许多条流而表单只映射第一条，删除会抹掉其余音轨。
Func _ReplaceBlocks($sText, $sBlockTag, ByRef $aItems, ByRef $aFieldOrder, $bAllowCountChange = True)
    Local $sPattern = '<' & $sBlockTag & '(?:\s[^>]*)?>[\s\S]*?</' & $sBlockTag & '>'
    Local $aMatches = StringRegExp($sText, $sPattern, 3)
    Local $iMatchCount = UBound($aMatches)
    ; 原文件没有此类块 → 忽略表单内容
    If $iMatchCount = 0 Then Return $sText

    Local $iItemCount = UBound($aItems, 1)
    If Not $bAllowCountChange And $iItemCount > 1 Then $iItemCount = 1

    ; 检测已有块的缩进，供新增条目沿用
    Local $sIndent = _DetectChildIndent($sText)
    Local $iFirstPos = StringInStr($sText, $aMatches[0], 2)
    If $iFirstPos > 1 Then
        Local $aIndent = StringRegExp(StringMid($sText, 1, $iFirstPos - 1), "([ \t]+)$", 1)
        If UBound($aIndent) > 0 Then $sIndent = $aIndent[0]
    EndIf

    ; 记录最后一个已有块的结束位置，作为追加新块的插入点
    Local $iLastBlockEnd = 0
    Local $sResult = ""
    Local $iPos = 1 ; 1-based

    ; 逐个处理已有块：替换、保留或删除
    For $i = 0 To $iMatchCount - 1
        Local $sBlock = $aMatches[$i]
        ; 使用区分大小写的查找（flag=2），XML 标签大小写敏感
        Local $iBlockPos = StringInStr($sText, $sBlock, 2, 1, $iPos)
        If $iBlockPos = 0 Then ExitLoop

        $sResult &= StringMid($sText, $iPos, $iBlockPos - $iPos)

        If $i < $iItemCount Then
            ; 替换块内已有字段；块内没有的子字段忽略
            Local $sBlockToUse = $sBlock
            For $j = 0 To UBound($aFieldOrder) - 1
                $sBlockToUse = _ReplaceTagInBlock($sBlockToUse, $aFieldOrder[$j], $aItems[$i][$j])
            Next
            $sResult &= $sBlockToUse
        ElseIf $bAllowCountChange Then
            ; 条目变少 → 删除多余块，并回退本行的前导换行与缩进，避免残留空行
            $sResult = StringRegExpReplace($sResult, '(?:\r\n|\n|\r)[ \t]*$', "")
        Else
            ; 保留多余块（多音轨 / 多视频流）
            $sResult &= $sBlock
        EndIf
        $iPos = $iBlockPos + StringLen($sBlock)
        $iLastBlockEnd = StringLen($sResult)
    Next

    Local $sTail = StringMid($sText, $iPos)

    ; 条目变多 → 紧跟在最后一个同类型块之后追加，保持同类标签聚集
    If $bAllowCountChange And $iItemCount > $iMatchCount And $iLastBlockEnd > 0 Then
        Local $sExtra = ""
        For $i = $iMatchCount To $iItemCount - 1
            $sExtra &= @CRLF & $sIndent & "<" & $sBlockTag & ">"
            For $j = 0 To UBound($aFieldOrder) - 1
                If $aItems[$i][$j] <> "" Then
                    $sExtra &= @CRLF & $sIndent & "  <" & $aFieldOrder[$j] & ">" & $aItems[$i][$j] & "</" & $aFieldOrder[$j] & ">"
                EndIf
            Next
            $sExtra &= @CRLF & $sIndent & "</" & $sBlockTag & ">"
        Next
        $sResult = StringLeft($sResult, $iLastBlockEnd) & $sExtra & StringMid($sResult, $iLastBlockEnd + 1)
    EndIf

    Return $sResult & $sTail
EndFunc

#EndRegion ;**** 正则标签替换引擎 ****

#Region ;**** DeepSeek API ****
; ==================== DeepSeek API ====================
Func _JsonEscape($sText)
    $sText = StringReplace($sText, "\", "\\")
    $sText = StringReplace($sText, '"', '\"')
    $sText = StringReplace($sText, @CRLF, "\n")
    $sText = StringReplace($sText, @CR, "\n")
    $sText = StringReplace($sText, @LF, "\n")
    $sText = StringReplace($sText, @TAB, "\t")
    Return $sText
EndFunc

Func _JsonUnescape($sText)
    $sText = _JsonDecodeUnicodeEscapes($sText)
    ; 使用私有区占位符避免 \\ 与 \n、\r、\t 冲突
    $sText = StringReplace($sText, "\\", $ESCAPE_SENTINEL)
    $sText = StringReplace($sText, "\r\n", @CRLF)
    $sText = StringReplace($sText, "\n", @CRLF)
    $sText = StringReplace($sText, "\r", @CR)
    $sText = StringReplace($sText, "\t", @TAB)
    $sText = StringReplace($sText, '\"', '"')
    $sText = StringReplace($sText, $ESCAPE_SENTINEL, "\")
    Return $sText
EndFunc

Func _JsonDecodeUnicodeEscapes($sText)
    Local $aMatches = StringRegExp($sText, "\\u([0-9A-Fa-f]{4})", 3)
    If UBound($aMatches) = 0 Then Return $sText

    For $i = 0 To UBound($aMatches) - 1
        Local $sHex = $aMatches[$i]
        $sText = StringReplace($sText, "\u" & $sHex, ChrW(Dec($sHex)))
    Next
    Return $sText
EndFunc

Func _ExtractJsonStringValue($sJson, $sName)
    Local $sPattern = '"' & $sName & '"\s*:\s*"((?:\\.|[^"\\])*)"'
    Local $aMatches = StringRegExp($sJson, $sPattern, 1)
    If UBound($aMatches) = 0 Then Return SetError(1, 0, "")
    Return _JsonUnescape($aMatches[0])
EndFunc

Func _StringToUtf8Binary($sText)
    Local $oStream = ObjCreate("ADODB.Stream")
    If Not IsObj($oStream) Then Return SetError(1, 0, $sText)

    $oStream.Type = 2
    $oStream.Charset = "utf-8"
    $oStream.Open()
    $oStream.WriteText($sText)
    $oStream.Position = 0
    $oStream.Type = 1
    ; ADODB.Stream 的 UTF-8 输出带有 EF BB BF，硅基流动会将 BOM 判为无效 JSON。
    $oStream.Position = 3
    Local $vBinary = $oStream.Read()
    $oStream.Close()
    Return $vBinary
EndFunc

Func _BuildLocalizePrompt($sTitle, $sPlot)
    Local $sPrompt = $g_sLocalizePrompt
    Local $bHasTitlePlaceholder = StringInStr($sPrompt, "{title}") > 0
    Local $bHasPlotPlaceholder = StringInStr($sPrompt, "{plot}") > 0

    $sPrompt = StringReplace($sPrompt, "{title}", $sTitle)
    $sPrompt = StringReplace($sPrompt, "{plot}", $sPlot)

    If Not $bHasTitlePlaceholder Then $sPrompt &= @CRLF & @CRLF & "原始标题：" & $sTitle
    If Not $bHasPlotPlaceholder Then $sPrompt &= @CRLF & "原始简介：" & $sPlot

    $sPrompt &= @CRLF & @CRLF & "请生成 3 个独立的汉化候选。三组都必须完整处理标题和简介，表达可以有区别，但不得添加原文没有的内容。每组简介必须先输出完整中文简介，再输出一行“原文：”，然后逐字保留原始标题和简介。除以下格式外不要输出任何解释，分隔符原样保留：" & @CRLF & _
        "<<<TITLE_1>>>" & @CRLF & _
        "候选 1 标题" & @CRLF & _
        "<<<PLOT_1>>>" & @CRLF & _
        "候选 1 简介" & @CRLF & _
        "<<<END_1>>>" & @CRLF & _
        "<<<TITLE_2>>>" & @CRLF & _
        "候选 2 标题" & @CRLF & _
        "<<<PLOT_2>>>" & @CRLF & _
        "候选 2 简介" & @CRLF & _
        "<<<END_2>>>" & @CRLF & _
        "<<<TITLE_3>>>" & @CRLF & _
        "候选 3 标题" & @CRLF & _
        "<<<PLOT_3>>>" & @CRLF & _
        "候选 3 简介" & @CRLF & _
        "<<<END_3>>>"

    Return $sPrompt
EndFunc

Func _NormalizeChatCompletionsUrl($sApiUrl)
    Local $sUrl = StringStripWS($sApiUrl, 3)
    If $sUrl = "" Then Return ""

    ; 完整接口地址保持不变；根地址和 /v1 地址自动补全兼容接口路径。
    If StringRegExp($sUrl, "(?i)/chat/completions(?:[/?#]|$)") Then Return $sUrl

    Local $sQuery = ""
    Local $iQueryPos = StringInStr($sUrl, "?")
    If $iQueryPos > 0 Then
        $sQuery = StringMid($sUrl, $iQueryPos)
        $sUrl = StringLeft($sUrl, $iQueryPos - 1)
    EndIf

    $sUrl = StringRegExpReplace($sUrl, "/+$", "")
    Return $sUrl & "/chat/completions" & $sQuery
EndFunc

; 准备 DeepSeek 请求的公共部分：URL 规范化、Key/Model 校验、Prompt/Body 构造、
; WinHttp 对象创建、UTF-8 转换。同步和异步调用方复用此函数。
; 成功返回 True，$oHttp/$sApiUrl/$sApiKey/$vBody 通过 ByRef 输出；
; 失败返回错误消息字符串并置 @error。
Func _PrepareDeepSeekRequest($sTitle, $sPlot, ByRef $oHttp, ByRef $sApiUrl, ByRef $sApiKey, ByRef $vBody)
    $sApiUrl = _NormalizeChatCompletionsUrl($g_sDeepSeekApiUrl)
    $sApiKey = StringStripWS($g_sDeepSeekApiKey, 3)
    Local $sModel = StringStripWS($g_sDeepSeekModel, 3)

    If $sApiUrl = "" Then Return SetError(1, 0, "请先在设置页填写 API URL")
    If $sApiKey = "" Then Return SetError(2, 0, "请先在设置页填写 API Key")
    If $sModel = "" Then $sModel = $DEFAULT_DEEPSEEK_MODEL

    Local $sPrompt = _BuildLocalizePrompt($sTitle, $sPlot)
    Local $sBody = '{"model":"' & _JsonEscape($sModel) & '","messages":[{"role":"user","content":"' & _JsonEscape($sPrompt) & '"}],"temperature":0.7,"stream":false}'

    $oHttp = ObjCreate("WinHttp.WinHttpRequest.5.1")
    If Not IsObj($oHttp) Then Return SetError(3, 0, "无法创建 WinHttp 请求对象")

    $vBody = _StringToUtf8Binary($sBody)
    If @error Then Return SetError(6, 0, "无法创建 UTF-8 请求体")

    Return True
EndFunc

Func _CallDeepSeekLocalize($sTitle, $sPlot)
    Local $oHttp, $sApiUrl, $sApiKey, $vBody
    Local $vPrep = _PrepareDeepSeekRequest($sTitle, $sPlot, $oHttp, $sApiUrl, $sApiKey, $vBody)
    If @error Then Return SetError(@error, 0, $vPrep)

    $oHttp.SetTimeouts(10000, 10000, 30000, 60000)
    $oHttp.Open("POST", $sApiUrl, False)
    $oHttp.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
    $oHttp.SetRequestHeader("Authorization", "Bearer " & $sApiKey)

    ; 强制主窗口重绘，避免 API 阻塞期间界面冻结
    If $g_hMainGui <> 0 Then
        DllCall("user32.dll", "int", "UpdateWindow", "hwnd", $g_hMainGui)
    EndIf

    _ResetComError()
    $oHttp.Send($vBody)
    If $g_bComError Then Return SetError(7, 0, "API 请求异常:" & @CRLF & $g_sComErrorDesc)

    Local $iStatus = $oHttp.Status
    Local $sResponse = $oHttp.ResponseText
    If $iStatus < 200 Or $iStatus >= 300 Then
        Local $sErrMsg = _ExtractJsonStringValue($sResponse, "message")
        If @error Or $sErrMsg = "" Then $sErrMsg = $sResponse
        If $iStatus = 404 Then $sErrMsg &= @CRLF & @CRLF & "实际请求地址：" & $sApiUrl
        Return SetError(4, $iStatus, "API 请求失败（HTTP " & $iStatus & "）:" & @CRLF & $sErrMsg)
    EndIf

    Local $sContent = _ExtractJsonStringValue($sResponse, "content")
    If @error Or $sContent = "" Then Return SetError(5, 0, "无法解析 API 返回内容:" & @CRLF & $sResponse)
    Return $sContent
EndFunc

; ==================== 异步 API 调用（供批量汉化并发使用） ====================
;
; 批量汉化需要同时跑多个请求，但 AutoIt 是单线程的，_CallDeepSeekLocalize
; 用的同步 Send 会独占执行流。这里改用 WinHttpRequest 的异步模式：
; Open 的第三个参数传 True 后 Send 立即返回，再用 WaitForResponse(0) 轮询，
; 这样多个请求对象可以同时在飞，主循环也还能刷界面。

; 发起一个异步请求，返回 WinHttp 对象供后续轮询；失败置 @error 并返回错误说明
Func _StartDeepSeekRequest($sTitle, $sPlot)
    Local $oHttp, $sApiUrl, $sApiKey, $vBody
    Local $vPrep = _PrepareDeepSeekRequest($sTitle, $sPlot, $oHttp, $sApiUrl, $sApiKey, $vBody)
    If @error Then Return SetError(@error, 0, $vPrep)

    _ResetComError()
    $oHttp.SetTimeouts(10000, 10000, 30000, 120000)
    ; 第三参数 True = 异步：Send 不阻塞，交由 WaitForResponse 轮询
    $oHttp.Open("POST", $sApiUrl, True)
    $oHttp.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
    $oHttp.SetRequestHeader("Authorization", "Bearer " & $sApiKey)
    $oHttp.Send($vBody)
    If $g_bComError Then Return SetError(7, 0, "API 请求异常:" & @CRLF & $g_sComErrorDesc)

    Return $oHttp
EndFunc

; 轮询一个异步请求。
; 返回：1=已完成（结果写入 $sContentOut）、0=仍在进行、-1=失败（原因写入 $sContentOut）
Func _PollDeepSeekRequest(ByRef $oHttp, ByRef $sContentOut)
    $sContentOut = ""
    If Not IsObj($oHttp) Then
        $sContentOut = "请求对象已失效"
        Return -1
    EndIf

    ; WaitForResponse(0)：超时 0 秒表示只探测状态、立即返回，不阻塞。
    ; 响应未就绪时返回 False，此时 COM 不算错误。
    _ResetComError()
    Local $bDone = $oHttp.WaitForResponse(0)
    If $g_bComError Then
        $sContentOut = "API 请求异常:" & @CRLF & $g_sComErrorDesc
        Return -1
    EndIf
    If Not $bDone Then Return 0

    _ResetComError()
    Local $iStatus = $oHttp.Status
    Local $sResponse = $oHttp.ResponseText
    If $g_bComError Then
        $sContentOut = "读取响应失败:" & @CRLF & $g_sComErrorDesc
        Return -1
    EndIf

    If $iStatus < 200 Or $iStatus >= 300 Then
        Local $sErrMsg = _ExtractJsonStringValue($sResponse, "message")
        If @error Or $sErrMsg = "" Then $sErrMsg = $sResponse
        $sContentOut = "HTTP " & $iStatus & "：" & StringLeft($sErrMsg, 300)
        Return -1
    EndIf

    Local $sContent = _ExtractJsonStringValue($sResponse, "content")
    If @error Or $sContent = "" Then
        $sContentOut = "无法解析 API 返回内容"
        Return -1
    EndIf

    $sContentOut = $sContent
    Return 1
EndFunc

; 解析一次请求返回的三个候选结果。
Func _ParseLocalizedCandidates($sContent, $sOriginalTitle, $sOriginalPlot, ByRef $aTitlesOut, ByRef $aPlotsOut)
    Local Const $iCandidateCount = 3
    ReDim $aTitlesOut[$iCandidateCount]
    ReDim $aPlotsOut[$iCandidateCount]

    For $i = 1 To $iCandidateCount
        Local $aMatches = StringRegExp($sContent, "(?is)<<<TITLE_" & $i & ">>>\s*([\s\S]*?)\s*<<<PLOT_" & $i & ">>>\s*([\s\S]*?)\s*<<<END_" & $i & ">>>", 1)
        If @error Or UBound($aMatches) < 2 Then Return False

        $aTitlesOut[$i - 1] = StringStripWS($aMatches[0], 3)
        $aPlotsOut[$i - 1] = StringStripWS($aMatches[1], 3)
        If $aTitlesOut[$i - 1] = "" And $aPlotsOut[$i - 1] = "" Then Return False

        ; 模型可能只返回中文部分，缺失时由程序把原始标题和简介补回候选中。
        Local $bHasOriginalTitle = $sOriginalTitle = "" Or StringInStr($aPlotsOut[$i - 1], $sOriginalTitle, 2) > 0
        Local $bHasOriginalPlot = $sOriginalPlot = "" Or StringInStr($aPlotsOut[$i - 1], $sOriginalPlot, 2) > 0
        If Not $bHasOriginalTitle Or Not $bHasOriginalPlot Then
            Local $sOriginalBlock = "原文：" & @CRLF
            If $sOriginalTitle <> "" Then $sOriginalBlock &= $sOriginalTitle & @CRLF
            If $sOriginalPlot <> "" Then $sOriginalBlock &= $sOriginalPlot
            $aPlotsOut[$i - 1] = StringStripWS($aPlotsOut[$i - 1], 3) & @CRLF & @CRLF & $sOriginalBlock
        EndIf
    Next

    Return True
EndFunc

#EndRegion ;**** DeepSeek API ****

#Region ;**** 控件样式与创建 ****
; ==================== 控件样式与创建 ====================

; 统一样式应用：设置前景色、背景色和字体。三个语义函数复用此函数，
; 避免字体设置（"Microsoft YaHei UI", 11, 400）在多处重复。
Func _ApplyStyle($idCtrl, $iColor, $iBgColor)
    GUICtrlSetColor($idCtrl, $iColor)
    GUICtrlSetBkColor($idCtrl, $iBgColor)
    GUICtrlSetFont($idCtrl, 11, 400, 0, "Microsoft YaHei UI")
EndFunc

; 字段标签统一样式
Func _StyleFieldLabel($idLabel, $iBgColor = $CLR_CARD_BG)
    _ApplyStyle($idLabel, $CLR_TEXT_SECONDARY, $iBgColor)
EndFunc

; 输入类控件统一样式：浅灰底把可编辑区从白色卡片底中区分出来，
; 不再依赖成片的面板背景 Label 来划分区域。
Func _StyleFieldInput($idInput)
    _ApplyStyle($idInput, $CLR_TEXT_PRIMARY, $CLR_SURFACE)
EndFunc

; 次要文字标签统一样式（文件名、目录名、计数、状态栏等）
Func _StyleMutedLabel($idLabel)
    _ApplyStyle($idLabel, $CLR_TEXT_MUTED, $CLR_CARD_BG)
EndFunc

Func _CreateLabeledInput($iX, $iY, $sLabel, $iLabelW, $iInputW, $bMultiline = False, $iInputH = 30, $iInputStyle = 0, $iLabelBgColor = $CLR_CARD_BG)
    Local $idLabel = GUICtrlCreateLabel($sLabel, $iX, $iY, $iLabelW, 22)
    _StyleFieldLabel($idLabel, $iLabelBgColor)

    Local $idInput
    If $bMultiline Then
        ; $ES_WANTRETURN：否则回车会触发窗口默认按钮而不是换行，多行框无法手工输入换行
        Local $iStyle = BitOR($ES_MULTILINE, $ES_WANTRETURN, $ES_AUTOVSCROLL, $WS_VSCROLL)
        If $iInputStyle <> 0 Then $iStyle = BitOR($iStyle, $iInputStyle)
        $idInput = GUICtrlCreateEdit("", $iX + $iLabelW, $iY - 3, $iInputW, $iInputH, $iStyle)
    Else
        $idInput = GUICtrlCreateInput("", $iX + $iLabelW, $iY - 3, $iInputW, $iInputH, $iInputStyle)
    EndIf
    _StyleFieldInput($idInput)

    Return $idInput
EndFunc

; 统一创建自绘扁平圆角操作按钮
; 所有按钮配色常量均配白色文字；Hover/Pressed/Disabled 由 _UI_WM_DRAWITEM 自绘渲染
Func _CreateAppButton($sText, $iX, $iY, $iWidth, $iHeight, $iBgColor = $CLR_BTN_CHK_NONE, $iFontSize = 11)
    Local $iTextColor = $CLR_TEXT_PRIMARY
    Switch $iBgColor
        Case $CLR_PRIMARY, $CLR_SUCCESS, $CLR_ERROR, $CLR_WARNING, $CLR_INFO, _
             $CLR_BTN_OPEN, $CLR_BTN_SAVE, $CLR_BTN_SAVE_AS, $CLR_BTN_REFRESH, _
             $CLR_BTN_SEL_DIR, $CLR_BTN_CHK_ALL, $CLR_BTN_CHK_NONE, $CLR_BTN_BATCH
            $iTextColor = $CLR_TEXT_ON_ACCENT
    EndSwitch

    Return _UI_CreateButton($sText, $iX, $iY, $iWidth, $iHeight, $iBgColor, $iTextColor, $iFontSize, $CLR_CARD_BG)
EndFunc

; $iDotColor：状态指示灯颜色（灰=就绪/已保存、橙=有未保存修改、红=失败）。
; 默认 -1 表示保持指示灯当前颜色不变（用于不涉及状态切换的中间提示）。
Func _SetAppStatus($sText, $iDotColor = -1)
    If $g_idStatusBar <> 0 Then GUICtrlSetData($g_idStatusBar, $sText)
    If $g_idStatusDot <> 0 And $iDotColor <> -1 Then GUICtrlSetBkColor($g_idStatusDot, $iDotColor)

    If $g_idCurrentFileLabel = 0 Then Return
    Local $sCurrent = "未打开文件"
    Local $sTip = "当前未打开 NFO 文件"
    If $g_sCurrentFile <> "" Then
        $sCurrent = _GetFileName($g_sCurrentFile)
        $sTip = $g_sCurrentFile
    EndIf
    If $g_bModified Then
        $sCurrent &= "  ·  未保存修改"
        GUICtrlSetColor($g_idCurrentFileLabel, $CLR_ERROR)
    Else
        GUICtrlSetColor($g_idCurrentFileLabel, $CLR_TEXT_MUTED)
    EndIf
    GUICtrlSetData($g_idCurrentFileLabel, $sCurrent)
    GUICtrlSetTip($g_idCurrentFileLabel, $sTip)
EndFunc

Func _UpdateFileCountLabel($iDisplayed, $iTotal)
    If $g_idFileCountLabel = 0 Then Return
    GUICtrlSetData($g_idFileCountLabel, $iDisplayed & " / " & $iTotal & " 个文件")
EndFunc

Func _UpdateDirectoryLabel()
    If $g_idDirLabel = 0 Then Return

    Local $sDirectoryName = _GetFileName($g_sCurrentDir)
    If $sDirectoryName = "" Then $sDirectoryName = $g_sCurrentDir
    GUICtrlSetData($g_idDirLabel, $sDirectoryName)
    GUICtrlSetTip($g_idDirLabel, $g_sCurrentDir)
EndFunc

Func _SetControlTips()
    GUICtrlSetTip($g_idBtnOpen, "打开单个 NFO 文件 (Ctrl+O)")
    GUICtrlSetTip($g_idBtnSave, "保存当前文件 (Ctrl+S)")
    GUICtrlSetTip($g_idBtnSaveAs, "将当前内容保存为新的 NFO 文件 (Ctrl+Shift+S)")
    GUICtrlSetTip($g_idBtnRefresh, "重新扫描当前目录 (F5)")
    GUICtrlSetTip($g_idBtnSelectDir, "选择 NFO 文件目录，包含子目录")
    GUICtrlSetTip($g_idFileSearch, "按文件名或相对路径实时筛选")
    GUICtrlSetTip($g_idList, "双击或选择文件以加载 NFO；Ctrl+Shift+A 全选")
    GUICtrlSetTip($g_idBtnAddActor, "添加演员信息")
    GUICtrlSetTip($g_idBtnRemoveActor, "删除选中的演员 (Del)")
    GUICtrlSetTip($g_idBtnSync, "将 XML 编辑器内容写入表单")
    GUICtrlSetTip($g_idBtnRefreshXml, "从当前 XML 数据刷新编辑器")
    GUICtrlSetTip($g_idBtnSaveSettings, "保存 API 和 Prompt 设置")
    GUICtrlSetTip($g_idBtnResetPrompt, "恢复 JAV NFO 默认汉化规则")
    GUICtrlSetTip($g_idBtnTestApi, "发送最小请求测试 API 配置")
EndFunc

; 从字段数组批量生成句柄缓存
Func _CacheFieldHandles(ByRef $aFields, ByRef $aHandles)
    ReDim $aHandles[UBound($aFields)]
    For $i = 0 To UBound($aFields) - 1
        $aHandles[$i] = GUICtrlGetHandle($aFields[$i][2])
    Next
EndFunc

; 缓存所有编辑控件的句柄，避免每次 EN_CHANGE 重复调用 GUICtrlGetHandle
Func _CacheEditControlHandles()
    $g_hXmlText = GUICtrlGetHandle($g_idXmlText)
    $g_hSetName = GUICtrlGetHandle($g_idSetName)
    $g_hTagText = GUICtrlGetHandle($g_idTagText)
    $g_hGenreText = GUICtrlGetHandle($g_idGenreText)
    $g_hFileSearch = GUICtrlGetHandle($g_idFileSearch)
    _CacheFieldHandles($g_aBasicFields, $g_aBasicFieldHandles)
    _CacheFieldHandles($g_aVideoFields, $g_aVideoFieldHandles)
    _CacheFieldHandles($g_aAudioFields, $g_aAudioFieldHandles)
EndFunc

Func _IsNfoEditControl($hControl)
    If $hControl = 0 Then Return False
    ; 直接比较缓存的句柄，无需每次调用 GUICtrlGetHandle
    If $g_hXmlText <> 0 And $hControl = $g_hXmlText Then Return True
    If $g_hSetName <> 0 And $hControl = $g_hSetName Then Return True
    If $g_hTagText <> 0 And $hControl = $g_hTagText Then Return True
    If $g_hGenreText <> 0 And $hControl = $g_hGenreText Then Return True

    For $i = 0 To UBound($g_aBasicFieldHandles) - 1
        If $g_aBasicFieldHandles[$i] <> 0 And $hControl = $g_aBasicFieldHandles[$i] Then Return True
    Next
    For $i = 0 To UBound($g_aVideoFieldHandles) - 1
        If $g_aVideoFieldHandles[$i] <> 0 And $hControl = $g_aVideoFieldHandles[$i] Then Return True
    Next
    For $i = 0 To UBound($g_aAudioFieldHandles) - 1
        If $g_aAudioFieldHandles[$i] <> 0 And $hControl = $g_aAudioFieldHandles[$i] Then Return True
    Next
    Return False
EndFunc

Func _OnEditChange($hWnd, $iMsg, $wParam, $lParam)
    If Not $g_bLoading And BitShift($wParam, 16) = $EN_CHANGE Then
        If $g_hFileSearch <> 0 And $lParam = $g_hFileSearch Then
            ; 防抖：延迟执行筛选，避免逐字符触发
            $g_iSearchDebounceTimer = TimerInit()
        ElseIf _IsNfoEditControl($lParam) Then
            $g_bModified = True
            If $g_hXmlText <> 0 And $lParam = $g_hXmlText Then $g_bXmlSourceModified = True
            _SetAppStatus("有未保存修改", $CLR_STATUS_MODIFIED)
        EndIf
    EndIf
    Return $GUI_RUNDEFMSG
EndFunc

Func _ConfirmDiscardChanges()
    If Not $g_bModified Then Return True

    Local $iChoice = MsgBox(0x33, "未保存修改", "当前 NFO 有未保存修改。是否先保存？")
    Switch $iChoice
        Case 6
            _OnSaveFile()
            Return Not $g_bModified
        Case 7
            Return True
        Case Else
            Return False
    EndSwitch
EndFunc

#EndRegion ;**** 控件样式与创建 ****

#Region ;**** 文件列表勾选 ****
; ==================== 文件列表勾选 ====================

; ListView 的选择变更通过 WM_NOTIFY 上报，不进入 GUIGetMsg，
; 因此列表点击必须在这里处理，否则单击文件不会加载。
Func _OnListViewNotify($hWnd, $iMsg, $wParam, $lParam)
    Local $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
    Local $hFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
    Local $iCode = DllStructGetData($tNMHDR, "Code")

    If $g_hFileList <> 0 And $hFrom = $g_hFileList Then
        Switch $iCode
            Case $LVN_ITEMCHANGED
                ; 仅在选中状态真正变化时加载，勾选复选框不触发加载
                Local $tNMLV = DllStructCreate($tagNMLISTVIEW, $lParam)
                Local $iNew = DllStructGetData($tNMLV, "NewState")
                Local $iOld = DllStructGetData($tNMLV, "OldState")
                ; LVIS_SELECTED = 2：由未选中变为选中
                If BitAND($iNew, 2) = 2 And BitAND($iOld, 2) = 0 Then
                    $g_bPendingFileSelect = True
                EndIf
        EndSwitch
    ElseIf $g_hActorList <> 0 And $hFrom = $g_hActorList Then
        ; 演员 ListView 的按键事件：Del 删除选中行。
        ; 不直接调用 _OnRemoveActor —— 通知回调里弹 MsgBox 会阻塞消息派发并可能重入，
        ; 与文件列表选择同理，只置标记由主循环处理。
        If $iCode = $LVN_KEYDOWN Then
            Local $iNMHDRSize = DllStructGetSize($tNMHDR)
            Local $tKey = DllStructCreate("word VKey", $lParam + $iNMHDRSize)
            Local $iVKey = DllStructGetData($tKey, "VKey")
            If $iVKey = 0x2E Then ; VK_DELETE
                $g_bPendingActorDelete = True
            EndIf
        EndIf
    EndIf
    Return $GUI_RUNDEFMSG
EndFunc

; 更新一个相对路径的持久勾选状态。
Func _RememberCheckedRelPath($sRelPath, $bChecked)
    If $sRelPath = "" Then Return
    ; 全局集合始终保持为 path1|path2，不保留首尾分隔符，避免 StringSplit 产生空项。
    Local $sCurrent = StringRegExpReplace($g_sCheckedRelPaths, "^\|+|\|+$", "")
    Local $sToken = "|" & $sRelPath & "|"
    If $bChecked Then
        If $sCurrent = "" Then
            $g_sCheckedRelPaths = $sRelPath
        ElseIf StringInStr("|" & $sCurrent & "|", $sToken, 2) = 0 Then
            $g_sCheckedRelPaths = $sCurrent & "|" & $sRelPath
        Else
            $g_sCheckedRelPaths = $sCurrent
        EndIf
    Else
        Local $sSet = "|" & $sCurrent & "|"
        $sSet = StringReplace($sSet, $sToken, "|", 0, 2)
        $g_sCheckedRelPaths = StringRegExpReplace($sSet, "^\|+|\|+$", "")
    EndIf
EndFunc

; 把当前可见列表同步回全局集合，不影响被筛选隐藏的条目。
Func _SyncVisibleCheckedRelPaths()
    If $g_idList = 0 Then Return
    Local $iCount = _GUICtrlListView_GetItemCount($g_idList)
    For $i = 0 To $iCount - 1
        _RememberCheckedRelPath(_GUICtrlListView_GetItemText($g_idList, $i, 0), _GUICtrlListView_GetItemChecked($g_idList, $i))
    Next
EndFunc

; 返回当前勾选项的相对路径，以 | 分隔
Func _GetCheckedRelPaths()
    _SyncVisibleCheckedRelPaths()
    Return $g_sCheckedRelPaths
EndFunc

; 全选 / 全不选当前列表中的所有条目
Func _SetAllChecked($bChecked)
    Local $iCount = _GUICtrlListView_GetItemCount($g_idList)
    If $iCount = 0 Then
        _SetAppStatus("列表为空，无可勾选的文件", $CLR_STATUS_READY)
        Return
    EndIf

    _GUICtrlListView_BeginUpdate($g_idList)
    For $i = 0 To $iCount - 1
        _GUICtrlListView_SetItemChecked($g_idList, $i, $bChecked)
    Next
    _GUICtrlListView_EndUpdate($g_idList)
    _SyncVisibleCheckedRelPaths()

    If $bChecked Then
        _SetAppStatus("已勾选 " & $iCount & " 个文件", $CLR_STATUS_READY)
    Else
        _SetAppStatus("已取消全部勾选", $CLR_STATUS_READY)
    EndIf
EndFunc

#EndRegion ;**** 文件列表勾选 ****

#Region ;**** 主窗口与 Tab 构建 ****
; ==================== 创建主窗口 ====================
Func _CreateMainGui()
    ; 主窗口采用固定画布，避免绝对坐标控件在缩放后留白或被裁切。
    $g_hMainGui = _UI_CreateGUI("NFO编辑器", 1600, 900, -1, -1, 0, $CLR_CARD_BG, $CLR_BORDER, 65)

    ; 左上角应用标题：徽标色块 + 标题文字（无边框窗口，标题栏区域可拖动）。
    ; GUICtrlCreateLabel("文本内容", 左边距, 顶边距, 宽度, 高度)
    Local $idLogo = GUICtrlCreateLabel("N", 14, 22, 28, 28, BitOR(0x01, 0x0200)) ; $SS_CENTER | $SS_CENTERIMAGE
    GUICtrlSetColor($idLogo, $CLR_TEXT_ON_ACCENT)
    GUICtrlSetBkColor($idLogo, $CLR_PRIMARY)
    GUICtrlSetFont($idLogo, 15, 700, 0, "Microsoft YaHei UI")

    Local $idAppTitle = GUICtrlCreateLabel("NFO编辑器", 50, 20, 150, 30)
    GUICtrlSetColor($idAppTitle, $CLR_TEXT_PRIMARY)
    GUICtrlSetBkColor($idAppTitle, $CLR_CARD_BG)
    GUICtrlSetFont($idAppTitle, 16, 700, 0, "Microsoft YaHei UI")

    ; 顶部工具栏的常用操作按钮已移至左栏，此处仅保留当前文件名显示
    ; 当前文件名：右上角窗口控制按钮区域约 x=1480 起，此处留出余量
    $g_idCurrentFileLabel = GUICtrlCreateLabel("未打开文件", 210, 24, 1250, 22)
    _StyleMutedLabel($g_idCurrentFileLabel)

    _UI_AddHSeperator(0, 65, 1600, 1, $CLR_BORDER)

    ; 最小化与关闭按钮。窗口内没有任何控件覆盖该区域，因此始终可见。
    $g_aWindowControlButtons = _UI_AddControlButtons(1600, True, True, $CLR_CARD_BG, $CLR_TEXT_PRIMARY)

    ; ---- 左栏：搜索、文件操作、导航、文件列表 ----
    Local $idSearchLbl = GUICtrlCreateLabel("搜索", 14, 82, 50, 24)
    _StyleFieldLabel($idSearchLbl)
    $g_idFileSearch = GUICtrlCreateInput("", 68, 79, 276, 27)
    _StyleFieldInput($g_idFileSearch)

    ; 文件操作按钮（2×2 网格，每按钮独立配色）
    $g_idBtnOpen = _CreateAppButton("打开文件", 14, 115, 159, 32, $CLR_BTN_OPEN)
    $g_idBtnSave = _CreateAppButton("保存", 185, 115, 159, 32, $CLR_BTN_SAVE)
    $g_idBtnSaveAs = _CreateAppButton("另存为", 14, 151, 159, 32, $CLR_BTN_SAVE_AS)
    $g_idBtnRefresh = _CreateAppButton("刷新", 185, 151, 159, 32, $CLR_BTN_REFRESH)

    $g_idBtnSelectDir = _CreateAppButton("选择目录", 14, 190, 330, 32, $CLR_BTN_SEL_DIR)

    $g_idDirLabel = GUICtrlCreateLabel("", 14, 230, 330, 22)
    _StyleMutedLabel($g_idDirLabel)
    _UpdateDirectoryLabel()

    $g_idFileCountLabel = GUICtrlCreateLabel("0 / 0 个文件", 14, 256, 330, 22)
    _StyleMutedLabel($g_idFileCountLabel)

    ; 全选/全不选与批量汉化：勾选范围即批量操作范围
    $g_idBtnCheckAll = _CreateAppButton("全选", 14, 286, 105, 30, $CLR_BTN_CHK_ALL)
    $g_idBtnCheckNone = _CreateAppButton("全不选", 127, 286, 105, 30, $CLR_BTN_CHK_NONE)
    $g_idBtnBatchLocalize = _CreateAppButton("批量汉化", 240, 286, 104, 30, $CLR_BTN_BATCH)

    ; 文件列表改用带复选框的 ListView：ListBox 无法承载勾选状态。
    ; 单列宽度略小于控件宽度，留出竖向滚动条的位置。
    $g_idList = GUICtrlCreateListView("文件", 14, 322, 330, 526, _
        BitOR($LVS_REPORT, $LVS_SINGLESEL, $LVS_SHOWSELALWAYS, $LVS_NOSORTHEADER), _
        BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT))
    _GUICtrlListView_SetColumnWidth($g_idList, 0, 305)
    _StyleFieldInput($g_idList)

    ; 左栏与右侧工作区之间只用一条细线分隔
    _UI_AddVSeperator(354, 72, 780, 1, $CLR_BORDER)

    ; ---- 右侧标签页 ----
    $g_idTab = GUICtrlCreateTab(364, 72, 1224, 780)
    GUICtrlSetBkColor($g_idTab, $CLR_CARD_BG)
    GUICtrlSetFont($g_idTab, 11, 700, 0, "Microsoft YaHei UI")

    _CreateBasicInfoTab()
    _CreateActorsTab()
    _CreateMediaInfoTab()
    _CreateXmlTab()
    _CreateSettingsTab()

    GUICtrlCreateTabItem("")

    ; ---- 底部状态栏 ----
    _UI_AddHSeperator(0, 860, 1600, 1, $CLR_BORDER)
    ; 恒定位置的状态指示灯：灰=就绪/已保存、橙=有未保存修改、红=失败，
    ; 颜色由 _SetAppStatus 的 $iDotColor 参数统一维护，不需要读文字判断状态。
    $g_idStatusDot = GUICtrlCreateLabel("", 14, 870, 12, 12)
    GUICtrlSetBkColor($g_idStatusDot, $CLR_STATUS_READY)
    ; 状态栏文字宽度留出进度条空间
    $g_idStatusBar = GUICtrlCreateLabel("就绪", 34, 866, 1100, 22)
    _StyleMutedLabel($g_idStatusBar)
    ; 批量汉化进度条：平时隐藏，批量汉化期间显示百分比
    $g_idProgressBar = GUICtrlCreateProgress(1150, 868, 300, 18)
    GUICtrlSetState($g_idProgressBar, $GUI_HIDE)

    ; ---- 创建演员对话框（隐藏） ----
    _CreateActorDialog()
    ; _UI_CreateGUI 会把"当前 GUI"切到演员对话框，必须切回主窗口，
    ; 否则之后创建的 Dummy 控件会挂在对话框上，Ctrl+S 快捷键不生效。
    GUISwitch($g_hMainGui)

    _SetControlTips()
    _CacheEditControlHandles()
    $g_hFileList = GUICtrlGetHandle($g_idList)
    $g_hActorList = GUICtrlGetHandle($g_idActorList)
    GUIRegisterMsg($WM_COMMAND, "_OnEditChange")
    GUIRegisterMsg($WM_NOTIFY, "_OnListViewNotify")
    _SetAppStatus("就绪", $CLR_STATUS_READY)

    ; 注册快捷键：Ctrl+S 保存、Ctrl+O 打开、Ctrl+Shift+S 另存为、F5 刷新、Ctrl+A 全选
    $g_idAccelSave = GUICtrlCreateDummy()
    $g_idAccelOpen = GUICtrlCreateDummy()
    $g_idAccelSaveAs = GUICtrlCreateDummy()
    $g_idAccelRefresh = GUICtrlCreateDummy()
    $g_idAccelCheckAll = GUICtrlCreateDummy()
    Local $aAccelKeys[5][2] = [ _
        ["^s", $g_idAccelSave], _
        ["^o", $g_idAccelOpen], _
        ["^+s", $g_idAccelSaveAs], _
        ["{F5}", $g_idAccelRefresh], _
        ["^+a", $g_idAccelCheckAll]]
    GUISetAccelerators($aAccelKeys, $g_hMainGui)

    GUISetState(@SW_SHOW, $g_hMainGui)
EndFunc

; ==================== 基本信息 Tab ====================
; 布局原则：输入框实际 y = $iY - 3，高 30，所以 y 间距 45 对应实际间距 15px；
; section 标签与首个字段间距 38px，避免视觉重叠。
Func _CreateBasicInfoTab()
    GUICtrlCreateTabItem("基本信息")

    ; 不再铺任何面板背景：白底 + 浅灰输入框已足够区分层次，
    ; 分组靠小标题和留白表达。
    _CreateSectionLabel("标题", 380, 105)
    $g_aBasicFields[0][2] = _CreateLabeledInput(380, 140, $g_aBasicFields[0][0], 90, 950)
    $g_aBasicFields[1][2] = _CreateLabeledInput(380, 180, $g_aBasicFields[1][0], 90, 950)

    ; 左列：常用字段
    _CreateSectionLabel("常用字段", 380, 240)
    $g_aBasicFields[2][2] = _CreateLabeledInput(380, 275, $g_aBasicFields[2][0], 100, 430)
    $g_aBasicFields[3][2] = _CreateLabeledInput(380, 315, $g_aBasicFields[3][0], 100, 430)
    $g_aBasicFields[4][2] = _CreateLabeledInput(380, 355, $g_aBasicFields[4][0], 100, 430)
    $g_aBasicFields[5][2] = _CreateLabeledInput(380, 395, $g_aBasicFields[5][0], 100, 430)
    $g_aBasicFields[6][2] = _CreateLabeledInput(380, 435, $g_aBasicFields[6][0], 100, 430)
    $g_aBasicFields[7][2] = _CreateLabeledInput(380, 475, $g_aBasicFields[7][0], 100, 430)
    $g_aBasicFields[8][2] = _CreateLabeledInput(380, 515, $g_aBasicFields[8][0], 100, 430)
    $g_idSetName = _CreateLabeledInput(380, 593, "合集", 100, 430)
    $g_aBasicFields[9][2] = _CreateLabeledInput(380, 638, $g_aBasicFields[9][0], 100, 430)

    ; 右列：剧情简介与外部链接
    _CreateSectionLabel("剧情简介", 940, 240)
    $g_aBasicFields[12][2] = _CreateLabeledInput(940, 278, "", 0, 630, True, 280)
    _CreateSectionLabel("外部链接", 940, 588)
    $g_aBasicFields[10][2] = _CreateLabeledInput(940, 626, $g_aBasicFields[10][0], 90, 540)
    $g_aBasicFields[11][2] = _CreateLabeledInput(940, 671, $g_aBasicFields[11][0], 90, 540)

    ; 底部：分类信息（每行一个值）
    _CreateSectionLabel("分类信息", 380, 698)
    $g_idTagText = _CreateLabeledInput(380, 735, "标签", 100, 430, True, 100)
    $g_idGenreText = _CreateLabeledInput(940, 735, "类型", 90, 540, True, 100)
EndFunc

; Section 标题：深色加粗标题（无竖条、无底部分隔线）
; $iBgColor 参数允许在面板背景上使用时匹配底色
Func _CreateSectionLabel($sText, $iX, $iY, $iBgColor = $CLR_CARD_BG)
    Local $idLabel = GUICtrlCreateLabel($sText, $iX, $iY, 390, 28)
    GUICtrlSetColor($idLabel, $CLR_TEXT_PRIMARY)
    GUICtrlSetBkColor($idLabel, $iBgColor)
    GUICtrlSetFont($idLabel, 13, 700, 0, "Microsoft YaHei UI")
EndFunc

; ==================== 演员 Tab ====================
Func _CreateActorsTab()
    GUICtrlCreateTabItem("演员")

    $g_idBtnAddActor = _CreateAppButton("添加演员", 380, 110, 130, 36, $CLR_SUCCESS)
    $g_idBtnRemoveActor = _CreateAppButton("删除选中", 520, 110, 130, 36, $CLR_ERROR)

    ; 列宽与表格宽度对齐，优先为姓名和角色保留浏览空间。
    $g_idActorList = GUICtrlCreateListView("#|姓名|角色|类型|TMDB ID", 380, 156, 1190, 690, _
        BitOR($LVS_REPORT, $LVS_SINGLESEL, $LVS_SHOWSELALWAYS), BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES))
    _GUICtrlListView_SetColumnWidth($g_idActorList, 0, 55)
    _GUICtrlListView_SetColumnWidth($g_idActorList, 1, 350)
    _GUICtrlListView_SetColumnWidth($g_idActorList, 2, 340)
    _GUICtrlListView_SetColumnWidth($g_idActorList, 3, 200)
    _GUICtrlListView_SetColumnWidth($g_idActorList, 4, 245)
    _StyleFieldInput($g_idActorList)
EndFunc

; ==================== 媒体信息 Tab ====================
Func _CreateMediaInfoTab()
    GUICtrlCreateTabItem("媒体信息")

    _CreateSectionLabel("视频", 380, 110)
    _CreateSectionLabel("音频", 940, 110)
    ; 两列之间只用一条细线分隔，不再铺面板背景
    _UI_AddVSeperator(925, 110, 700, 1, $CLR_BORDER)

    ; 视频字段（两列、四行）
    For $i = 0 To 7
        Local $iColumn = Mod($i, 2)
        Local $iX = 380 + $iColumn * 215
        Local $iY = 145 + Int($i / 2) * 46
        $g_aVideoFields[$i][2] = _CreateLabeledInput($iX, $iY, $g_aVideoFields[$i][0], 140, 70)
    Next

    ; 音频字段（单列，保证语言与编码值可完整阅读）
    Local $sLangOptions = "zh|en|de|ru|ja|ko|und"
    For $i = 0 To 4
        $iY = 145 + $i * 38

        If $g_aAudioFields[$i][3] = 1 Then
            ; 语言 → ComboBox
            Local $idLabel = GUICtrlCreateLabel($g_aAudioFields[$i][0], 940, $iY, 145, 22)
            _StyleFieldLabel($idLabel)

            $g_aAudioFields[$i][2] = GUICtrlCreateCombo("", 1085, $iY - 3, 310, 27, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
            GUICtrlSetData($g_aAudioFields[$i][2], $sLangOptions, "")
            _StyleFieldInput($g_aAudioFields[$i][2])
            ; ComboBox 发送 CBN_SELCHANGE 而非 EN_CHANGE，_OnEditChange 捕获不到，
            ; 记下控件 ID 以便主循环单独置脏。
            $g_idAudioLangCombo = $g_aAudioFields[$i][2]
        Else
            $g_aAudioFields[$i][2] = _CreateLabeledInput(940, $iY, $g_aAudioFields[$i][0], 145, 310)
        EndIf
    Next
EndFunc

; ==================== XML 源码 Tab ====================
Func _CreateXmlTab()
    GUICtrlCreateTabItem("XML 源码")

    $g_idBtnSync = _CreateAppButton("同步到表单", 380, 110, 140, 36, $CLR_SUCCESS)
    $g_idBtnRefreshXml = _CreateAppButton("刷新读取", 530, 110, 140, 36, $CLR_SURFACE)

    $g_idXmlText = GUICtrlCreateEdit("", 380, 156, 1190, 690, _
        BitOR($ES_MULTILINE, $ES_WANTRETURN, $ES_AUTOVSCROLL, $ES_AUTOHSCROLL, $WS_VSCROLL, $WS_HSCROLL))
    GUICtrlSetBkColor($g_idXmlText, $CLR_SURFACE)
    GUICtrlSetColor($g_idXmlText, $CLR_TEXT_PRIMARY)
    GUICtrlSetFont($g_idXmlText, 10, 400, 0, "Consolas")
EndFunc

; ==================== 设置 Tab ====================
Func _CreateSettingsTab()
    GUICtrlCreateTabItem("设置")

    _CreateSectionLabel("DeepSeek API", 380, 105)
    $g_idSettingsApiUrl = _CreateLabeledInput(380, 140, "API URL", 100, 1080)
    GUICtrlSetData($g_idSettingsApiUrl, $g_sDeepSeekApiUrl)
    GUICtrlSetTip($g_idSettingsApiUrl, "可填写 API 根地址、/v1 地址或完整的 /chat/completions 地址")

    $g_idSettingsApiKey = _CreateLabeledInput(380, 185, "API Key", 100, 1080, False, 30, $ES_PASSWORD)
    GUICtrlSetData($g_idSettingsApiKey, $g_sDeepSeekApiKey)

    $g_idSettingsModel = _CreateLabeledInput(380, 230, "模型", 100, 400)
    GUICtrlSetData($g_idSettingsModel, $g_sDeepSeekModel)

    _CreateSectionLabel("汉化 Prompt（可用占位符 {title}、{plot}）", 380, 275)
    $g_idSettingsPrompt = GUICtrlCreateEdit($g_sLocalizePrompt, 380, 313, 1190, 420, _
        BitOR($ES_MULTILINE, $ES_WANTRETURN, $ES_AUTOVSCROLL, $WS_VSCROLL))
    _StyleFieldInput($g_idSettingsPrompt)

    $g_idBtnSaveSettings = _CreateAppButton("保存设置", 380, 755, 130, 36, $CLR_SUCCESS)
    $g_idBtnResetPrompt = _CreateAppButton("恢复默认 Prompt", 520, 755, 170, 36, $CLR_SURFACE)
    $g_idBtnTestApi = _CreateAppButton("测试 API", 700, 755, 120, 36, $CLR_PRIMARY)
EndFunc

; ==================== 演员对话框 ====================
Func _CreateActorDialog()
    ; 创建带标题栏的无边框子窗口（白底 + 标题 + 分隔线）
    $g_hActorDialog = _UI_CreateGUI("添加演员", 580, 340, -1, -1, $g_hMainGui, $CLR_CARD_BG, $CLR_BORDER, 56)
    Local $idTitle = GUICtrlCreateLabel("添加演员", 24, 18, 400, 30)
    GUICtrlSetColor($idTitle, $CLR_TEXT_PRIMARY)
    GUICtrlSetBkColor($idTitle, $CLR_CARD_BG)
    GUICtrlSetFont($idTitle, 14, 700, 0, "Microsoft YaHei UI")
    _UI_AddHSeperator(24, 56, 532, 1, $CLR_BORDER)

    Local $idNameLbl = GUICtrlCreateLabel("姓名", 24, 82, 90, 24)
    _StyleFieldLabel($idNameLbl)
    $g_idActorName = GUICtrlCreateInput("", 120, 79, 436, 30)
    _StyleFieldInput($g_idActorName)

    Local $idRoleLbl = GUICtrlCreateLabel("角色", 24, 122, 90, 24)
    _StyleFieldLabel($idRoleLbl)
    $g_idActorRole = GUICtrlCreateInput("", 120, 119, 436, 30)
    _StyleFieldInput($g_idActorRole)

    Local $idTypeLbl = GUICtrlCreateLabel("类型", 24, 162, 90, 24)
    _StyleFieldLabel($idTypeLbl)
    $g_idActorType = GUICtrlCreateInput("Actor", 120, 159, 436, 30)
    _StyleFieldInput($g_idActorType)

    Local $idTmdbLbl = GUICtrlCreateLabel("TMDB ID", 24, 202, 90, 24)
    _StyleFieldLabel($idTmdbLbl)
    $g_idActorTmdbId = GUICtrlCreateInput("", 120, 199, 436, 30)
    _StyleFieldInput($g_idActorTmdbId)

    $g_idActorOk = _CreateAppButton("确定", 300, 252, 120, 36, $CLR_PRIMARY)
    $g_idActorCancel = _CreateAppButton("取消", 432, 252, 120, 36, $CLR_SURFACE)

    $g_aActorDialogButtons = _UI_AddControlButtons(580, True, False, $CLR_CARD_BG, $CLR_TEXT_PRIMARY)

    GUISetState(@SW_HIDE, $g_hActorDialog)
EndFunc

#EndRegion ;**** 主窗口与 Tab 构建 ****

#Region ;**** 数据加载 ****
; ==================== 数据加载 ====================

; 递归加载目录中的 .nfo 文件并提取元数据
Func _LoadDirectoryFiles()
    ; 切换目录/刷新时清空跨目录的勾选状态，避免旧目录的勾选项串扰到新目录
    ; （_ApplyFilters 会调用 _SyncVisibleCheckedRelPaths 同步可见项，
    ; 但被筛选隐藏的旧勾选会残留在 $g_sCheckedRelPaths 中）。
    $g_sCheckedRelPaths = ""

    Local $aFiles = _ScanNfoFiles($g_sCurrentDir)

    Local $iFileTotal = UBound($aFiles)
    If $iFileTotal = 0 Then
        ReDim $g_aFileMetadata[1][4]
        $g_iFileCount = 0
    Else
        ReDim $g_aFileMetadata[$iFileTotal][4]
        $g_iFileCount = $iFileTotal
    EndIf

    ; 目录刷新只建立相对路径索引，不逐个创建 COM DOM 解析 XML。
    ; 国家/语言字段目前未参与列表、筛选或批量操作；需要展示时再按需解析。
    Local $sBaseDir = $g_sCurrentDir
    If StringRight($sBaseDir, 1) <> "\" Then $sBaseDir &= "\"
    For $i = 0 To $iFileTotal - 1
        Local $sFullPath = $aFiles[$i]
        Local $sRelative = $sFullPath
        If StringLeft(StringLower($sFullPath), StringLen(StringLower($sBaseDir))) = StringLower($sBaseDir) Then
            $sRelative = StringTrimLeft($sFullPath, StringLen($sBaseDir))
        EndIf

        $g_aFileMetadata[$i][0] = $sRelative
        $g_aFileMetadata[$i][1] = ""
        $g_aFileMetadata[$i][2] = ""
        $g_aFileMetadata[$i][3] = $sFullPath
    Next

    If $g_iFileCount > 0 Then
        _ArraySort($g_aFileMetadata, 0, 0, 0, 0)
    EndIf

    _ApplyFilters()

    If $iFileTotal > 0 Then
        _SetAppStatus("扫描完成，找到 " & $iFileTotal & " 个 NFO 文件（包含子目录）", $CLR_STATUS_READY)
    Else
        _SetAppStatus("当前目录未找到 NFO 文件", $CLR_STATUS_READY)
    EndIf
EndFunc

; 应用筛选条件更新文件列表
Func _ApplyFilters()
    Local $sSearch = StringLower(StringStripWS(GUICtrlRead($g_idFileSearch), 3))

    ; 记住重建前的勾选项，筛选后仍在列表中的条目保持勾选，
    ; 否则用户勾好一批再改搜索词就会丢失全部选择。
    Local $sChecked = "|" & _GetCheckedRelPaths() & "|"

    ; 清空列表（ListView 需用专用函数，GUICtrlSetData 对其无效）
    _GUICtrlListView_BeginUpdate($g_idList)
    _GUICtrlListView_DeleteAllItems($g_idList)

    ; 筛选并显示
    Local $iDisplayed = 0
    For $i = 0 To $g_iFileCount - 1
        Local $sRelPath = $g_aFileMetadata[$i][0]

        Local $bSearchMatch = ($sSearch = "" Or StringInStr(StringLower($sRelPath), $sSearch) > 0)

        If $bSearchMatch Then
            _GUICtrlListView_AddItem($g_idList, $sRelPath)
            If StringInStr($sChecked, "|" & $sRelPath & "|", 2) > 0 Then
                _GUICtrlListView_SetItemChecked($g_idList, $iDisplayed, True)
            EndIf
            $iDisplayed += 1
        EndIf
    Next
    _GUICtrlListView_EndUpdate($g_idList)

    _UpdateFileCountLabel($iDisplayed, $g_iFileCount)
    If $sSearch = "" Then
        _SetAppStatus("显示 " & $iDisplayed & " 个 NFO 文件")
    Else
        _SetAppStatus("筛选显示 " & $iDisplayed & "/" & $g_iFileCount & " 个文件")
    EndIf
EndFunc

; 加载 NFO 文件
Func _LoadNfoFile($sFilePath)
    ; 读取原始文件内容到临时变量，解析成功后再更新全局状态
    Local $iFileEncoding = _GetNfoFileEncoding($sFilePath, 256)
    Local $hFile = FileOpen($sFilePath, $iFileEncoding)
    If $hFile = -1 Then
        MsgBox(16, "错误", "无法打开文件:" & @CRLF & $sFilePath)
        Return
    EndIf
    Local $sFileContent = FileRead($hFile)
    FileClose($hFile)

    ; 如果文件含 UTF-8 BOM，读取后可能残留为 U+FEFF 字符，去除之
    If StringLeft($sFileContent, 1) = ChrW(0xFEFF) Then
        $sFileContent = StringTrimLeft($sFileContent, 1)
    EndIf

    ; 解析 XML 到临时对象，成功后再替换全局对象
    Local $oNewDoc = _CreateXmlDoc()
    If Not IsObj($oNewDoc) Then
        MsgBox(16, "错误", "无法创建XML解析器")
        Return
    EndIf

    Local $sXmlContentForLoad = $sFileContent
    If Not $oNewDoc.load($sFilePath) Then
        ; 旧 NFO 常把 URL 中的 & 直接写入文本，先做无损的实体兼容修复再重试。
        Local $sRepairedXml = _XmlRepairInvalidAmpersands($sFileContent)
        If $sRepairedXml <> $sFileContent And $oNewDoc.loadXML($sRepairedXml) Then
            $sXmlContentForLoad = $sRepairedXml
        Else
            MsgBox(16, "错误", "XML解析失败:" & @CRLF & $sFilePath & _XmlParseErrorDetail($oNewDoc))
            Return
        EndIf
    EndIf

    Local $oRoot = $oNewDoc.documentElement
    If Not IsObj($oRoot) Then
        MsgBox(16, "错误", "无效的NFO文件格式：缺少根元素")
        Return
    EndIf

    ; 解析成功，更新全局状态
    $g_oXMLDoc = $oNewDoc
    $g_sOriginalXmlContent = $sXmlContentForLoad
    $g_sCurrentFile = $sFilePath
    $g_iCurrentFileEncoding = $iFileEncoding
    $g_sLoadedFileSignature = _GetNfoFileSignature($sFilePath)
    $g_bModified = False
    $g_bXmlSourceModified = False
    $g_bLoading = True

    _ClearAllFields()
    _LoadBasicInfo($oRoot)
    _LoadActors($oRoot)
    _LoadMediaInfo($oRoot)
    _LoadXmlSource()
    $g_bLoading = False

    _SetAppStatus("已加载: " & _GetFileName($sFilePath), $CLR_STATUS_READY)
    WinSetTitle($g_hMainGui, "", "NFO编辑器 - " & _GetFileName($sFilePath))
EndFunc

; 清空所有输入字段
Func _ClearAllFields()
    For $i = 0 To UBound($g_aBasicFields) - 1
        GUICtrlSetData($g_aBasicFields[$i][2], "")
    Next
    GUICtrlSetData($g_idSetName, "")
    GUICtrlSetData($g_idTagText, "")
    GUICtrlSetData($g_idGenreText, "")

    _GUICtrlListView_DeleteAllItems($g_idActorList)

    For $i = 0 To UBound($g_aVideoFields) - 1
        GUICtrlSetData($g_aVideoFields[$i][2], "")
    Next
    For $i = 0 To UBound($g_aAudioFields) - 1
        If $g_aAudioFields[$i][3] = 1 Then
            ; ComboBox：GUICtrlSetData(ctrl, "") 会清空全部候选项，
            ; 只能取消选中，否则下拉列表在第一次加载后就永久空掉。
            _GUICtrlComboBox_SetCurSel($g_aAudioFields[$i][2], -1)
        Else
            GUICtrlSetData($g_aAudioFields[$i][2], "")
        EndIf
    Next

    GUICtrlSetData($g_idXmlText, "")
EndFunc

; 加载基本信息到表单
Func _LoadBasicInfo($oRoot)
    For $i = 0 To UBound($g_aBasicFields) - 1
        Local $sValue = _XmlGetText($oRoot, $g_aBasicFields[$i][1])
        If $g_aBasicFields[$i][1] = "dmmid" Then $sValue = _CleanDmmId($sValue)
        GUICtrlSetData($g_aBasicFields[$i][2], $sValue)
    Next
    GUICtrlSetData($g_idSetName, _XmlGetSetName($oRoot))
    GUICtrlSetData($g_idTagText, _XmlGetJoinedText($oRoot, "tag"))
    GUICtrlSetData($g_idGenreText, _XmlGetJoinedText($oRoot, "genre"))
EndFunc

; 向演员 ListView 追加一行
Func _ActorAddRow($sName, $sRole, $sType, $sTmdbId)
    Local $iIndex = _GUICtrlListView_GetItemCount($g_idActorList)
    _GUICtrlListView_AddItem($g_idActorList, $iIndex + 1)
    _GUICtrlListView_AddSubItem($g_idActorList, $iIndex, $sName, 1)
    _GUICtrlListView_AddSubItem($g_idActorList, $iIndex, $sRole, 2)
    _GUICtrlListView_AddSubItem($g_idActorList, $iIndex, $sType, 3)
    _GUICtrlListView_AddSubItem($g_idActorList, $iIndex, $sTmdbId, 4)
EndFunc

; 加载演员列表
Func _LoadActors($oRoot)
    Local $oActors = $oRoot.selectNodes("*[local-name()='actor']")
    If Not IsObj($oActors) Then Return

    ; 批量更新：禁止重绘，避免大量演员时闪烁
    _GUICtrlListView_BeginUpdate($g_idActorList)

    For $i = 0 To $oActors.length - 1
        Local $oActor = $oActors.item($i)

        Local $sName = _XmlGetText($oActor, "name")
        Local $sRole = _XmlGetText($oActor, "role")
        Local $sType = _XmlGetText($oActor, "type")
        If $sType = "" Then $sType = "Actor"
        Local $sTmdbId = _XmlGetText($oActor, "tmdbid")

        _ActorAddRow($sName, $sRole, $sType, $sTmdbId)
    Next

    _GUICtrlListView_EndUpdate($g_idActorList)
EndFunc

; 加载媒体信息
Func _LoadMediaInfo($oRoot)
    Local $oFileinfo = $oRoot.selectSingleNode("*[local-name()='fileinfo']")
    If Not IsObj($oFileinfo) Then Return

    Local $oStreamdetails = $oFileinfo.selectSingleNode("*[local-name()='streamdetails']")
    If Not IsObj($oStreamdetails) Then Return

    ; 视频信息
    Local $oVideo = $oStreamdetails.selectSingleNode("*[local-name()='video']")
    If IsObj($oVideo) Then
        For $i = 0 To UBound($g_aVideoFields) - 1
            Local $sValue = _XmlGetText($oVideo, $g_aVideoFields[$i][1])
            GUICtrlSetData($g_aVideoFields[$i][2], $sValue)
        Next
    EndIf

    ; 音频信息
    Local $oAudio = $oStreamdetails.selectSingleNode("*[local-name()='audio']")
    If IsObj($oAudio) Then
        For $i = 0 To UBound($g_aAudioFields) - 1
            $sValue = _XmlGetText($oAudio, $g_aAudioFields[$i][1])
            If $g_aAudioFields[$i][3] = 1 Then
                ; ComboBox：候选项里没有的语言代码（如 jpn、chi）先追加再选中，
                ; 否则 SelectString 找不到项，读取时会返回空值并抹掉原始 language。
                If $sValue <> "" Then
                    If _GUICtrlComboBox_FindStringExact($g_aAudioFields[$i][2], $sValue) = -1 Then
                        _GUICtrlComboBox_AddString($g_aAudioFields[$i][2], $sValue)
                    EndIf
                    _GUICtrlComboBox_SelectString($g_aAudioFields[$i][2], $sValue)
                Else
                    _GUICtrlComboBox_SetCurSel($g_aAudioFields[$i][2], -1)
                EndIf
            Else
                GUICtrlSetData($g_aAudioFields[$i][2], $sValue)
            EndIf
        Next
    EndIf
EndFunc

; 加载 XML 源码到编辑器
Func _LoadXmlSource()
    If IsObj($g_oXMLDoc) Then
        Local $sXml = $g_oXMLDoc.xml
        $g_bLoading = True
        GUICtrlSetData($g_idXmlText, $sXml)
        $g_bLoading = False
        $g_bXmlSourceModified = False
    EndIf
EndFunc

; 刷新 XML 源码读取
Func _OnRefreshXmlSource()
    If Not IsObj($g_oXMLDoc) Then
        MsgBox(48, "提示", "当前没有加载任何NFO文件")
        Return
    EndIf

    If $g_bXmlSourceModified Then
        If MsgBox(0x34, "XML 源码有未同步修改", "当前 XML 编辑框有未同步内容。是否先同步到表单？") = 6 Then
            If Not _OnSyncFromXml() Then Return
        Else
            Return
        EndIf
    EndIf

    ; 表单已经修改时，先保存，避免从旧 DOM 刷新出旧数据。
    If $g_bModified Then
        If MsgBox(0x34, "未保存修改", "表单有未保存修改。是否先保存后刷新 XML？") <> 6 Then Return
        _OnSaveFile()
        If $g_bModified Then Return
    EndIf

    ; 刷新 XML 源码不应标记为已修改，设置 loading 标志抑制 EN_CHANGE
    $g_bLoading = True
    Local $sXml = $g_oXMLDoc.xml
    GUICtrlSetData($g_idXmlText, $sXml)
    $g_bLoading = False

    If $g_sCurrentFile <> "" Then
        _SetAppStatus("已刷新 XML 源码: " & _GetFileName($g_sCurrentFile), $CLR_STATUS_READY)
    Else
        _SetAppStatus("已刷新 XML 源码", $CLR_STATUS_READY)
    EndIf
EndFunc

#EndRegion ;**** 数据加载 ****

#Region ;**** 数据保存 ****
; ==================== 数据保存 ====================

; 先写同目录唯一临时文件，再通过 Windows 文件替换 API 提交。
; 目标已存在时使用 ReplaceFileW；目标不存在时使用 MoveFileExW。
; 返回 True 表示提交成功；失败时清理临时文件并保留原目标。
Func _WriteFileAtomic($sFilePath, $sText, $iEncoding)
    Local $sTempBase = $sFilePath & ".nfo_editor_tmp_" & @AutoItPID & "_" & _
        @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC & "_" & @MSEC
    Local $sTempPath = $sTempBase
    Local $iSuffix = 0
    While FileExists($sTempPath)
        $iSuffix += 1
        $sTempPath = $sTempBase & "_" & $iSuffix
    WEnd

    Local $hFile = FileOpen($sTempPath, BitOR(2, $iEncoding))
    If $hFile = -1 Then Return False
    Local $iWritten = FileWrite($hFile, $sText)
    Local $iWriteError = @error
    FileClose($hFile)

    If $iWriteError <> 0 Or $iWritten = 0 Or Not FileExists($sTempPath) Or FileGetSize($sTempPath) = 0 Then
        FileDelete($sTempPath)
        Return False
    EndIf

    Local $bReplaced = False
    If FileExists($sFilePath) Then
        ; ReplaceFileW 在同一卷内替换目标文件，不先删除原文件，并保留目标文件安全描述符。
        Local $aReplace = DllCall("Kernel32.dll", "bool", "ReplaceFileW", _
            "wstr", $sFilePath, "wstr", $sTempPath, "ptr", 0, "dword", 0, "ptr", 0, "ptr", 0)
        Local $iReplaceError = @error
        If $iReplaceError = 0 Then
            If IsArray($aReplace) Then
                If $aReplace[0] Then $bReplaced = True
            EndIf
        EndIf
    EndIf

    If Not $bReplaced And FileExists($sTempPath) Then
        ; ReplaceFileW 不受当前文件系统支持时，回退到同目录 MoveFileExW。
        ; 临时文件与目标同目录，处于同一卷；0x1=REPLACE_EXISTING，0x8=WRITE_THROUGH。
        Local $aMove = DllCall("Kernel32.dll", "bool", "MoveFileExW", _
            "wstr", $sTempPath, "wstr", $sFilePath, "dword", 0x00000009)
        Local $iMoveError = @error
        If $iMoveError = 0 Then
            If IsArray($aMove) Then
                If $aMove[0] Then $bReplaced = True
            EndIf
        EndIf
    EndIf

    If Not $bReplaced Then
        FileDelete($sTempPath)
        Return False
    EndIf
    Return True
EndFunc

; 差量写回：以原始文件文本为基底，只替换已存在标签的内容。
; 返回 True 表示写入成功；失败时置 @error 并返回错误说明。
Func _WriteNfoFile($sFilePath)
    ; 编辑器只做差量修改，没有原始文本就无从下手
    If $g_sOriginalXmlContent = "" Then Return SetError(1, 0, False)

    ; 防止覆盖编辑器打开后被其他程序修改的版本。
    If $g_sCurrentFile <> "" And StringLower($sFilePath) = StringLower($g_sCurrentFile) Then
        If $g_sLoadedFileSignature <> "" And _GetNfoFileSignature($sFilePath) <> $g_sLoadedFileSignature Then
            Return SetError(5, 0, "文件在打开后已被其他程序修改，请重新加载后再保存。")
        EndIf
    EndIf

    Local $sText = $g_sOriginalXmlContent

    ; 1) 基本字段：只更新 NFO 中已存在的标签，其余忽略
    For $i = 0 To UBound($g_aBasicFields) - 1
        Local $sRawValue = StringStripWS(GUICtrlRead($g_aBasicFields[$i][2]), 3)
        If $g_aBasicFields[$i][1] = "dmmid" Then $sRawValue = _CleanDmmId($sRawValue)
        Local $sValue = _XmlEscape($sRawValue)
        $sText = _UpdateSimpleTagIfPresent($sText, $g_aBasicFields[$i][1], $sValue)
    Next

    ; 2) 嵌套合集和分类信息（原文件没有 <set>/<tag>/<genre> 时各自跳过）
    $sText = _ReplaceSetNamePreserveLayout($sText, GUICtrlRead($g_idSetName))
    $sText = _ReplaceRepeatedTagsPreserveLayout($sText, "tag", GUICtrlRead($g_idTagText))
    $sText = _ReplaceRepeatedTagsPreserveLayout($sText, "genre", GUICtrlRead($g_idGenreText))

    ; 3) 演员列表：条目数随表单增减（原文件没有 <actor> 时跳过）
    Local $aActorFieldOrder[4] = ["name", "role", "type", "tmdbid"]
    Local $iActorCount = _GUICtrlListView_GetItemCount($g_idActorList)
    Local $aActorItems[$iActorCount][4]
    For $i = 0 To $iActorCount - 1
        For $j = 0 To 3
            $aActorItems[$i][$j] = _XmlEscape(_GUICtrlListView_GetItemText($g_idActorList, $i, $j + 1))
        Next
    Next
    $sText = _ReplaceBlocks($sText, "actor", $aActorItems, $aActorFieldOrder, True)

    ; 4) 视频信息：只更新第一条已有 <video> 流，多流文件其余部分保留；
    ;    原文件没有 <video> 时整体跳过。
    Local $aVideoFieldOrder[8] = ["codec", "bitrate", "width", "height", "aspect", "framerate", "scantype", "duration"]
    Local $aVideoItems[1][8]
    For $i = 0 To UBound($g_aVideoFields) - 1
        $aVideoItems[0][$i] = _XmlEscape(StringStripWS(GUICtrlRead($g_aVideoFields[$i][2]), 3))
    Next
    $sText = _ReplaceBlocks($sText, "video", $aVideoItems, $aVideoFieldOrder, False)

    ; 5) 音频信息：同上，只更新第一条已有 <audio> 流
    Local $aAudioFieldOrder[5] = ["codec", "bitrate", "language", "channels", "samplingrate"]
    Local $aAudioItems[1][5]
    For $i = 0 To UBound($g_aAudioFields) - 1
        $aAudioItems[0][$i] = _XmlEscape(StringStripWS(GUICtrlRead($g_aAudioFields[$i][2]), 3))
    Next
    $sText = _ReplaceBlocks($sText, "audio", $aAudioItems, $aAudioFieldOrder, False)

    ; 写回前校验：结果必须是合法 XML，避免正则替换产生损坏文件后覆盖原文件。
    ; 只有在「原文能解析、生成结果不能解析」时才拦截 —— 若两者都解析失败，
    ; 说明是原文件本身的问题，不应因此阻断保存。
    Local $oVerify = _CreateXmlDoc()
    If IsObj($oVerify) And Not $oVerify.loadXML($sText) Then
        Local $oBaseline = _CreateXmlDoc()
        If IsObj($oBaseline) And $oBaseline.loadXML($g_sOriginalXmlContent) Then
            Local $sMsg = "生成的 XML 不合法，已放弃写入以保护原文件。" & @CRLF & @CRLF & _
                "原因: " & StringStripWS($oVerify.parseError.reason, 3) & @CRLF & _
                "位置: 第 " & $oVerify.parseError.line & " 行"
            Return SetError(2, 0, $sMsg)
        EndIf
    EndIf

    ; 先写同目录临时文件，成功后再替换目标，避免写入失败时先截断原文件。
    Local $iEncoding = _GetNfoFileEncoding($sFilePath, $g_iCurrentFileEncoding)
    If Not _WriteFileAtomic($sFilePath, $sText, $iEncoding) Then Return SetError(3, 0, False)
    If Not FileExists($sFilePath) Or FileGetSize($sFilePath) = 0 Then Return SetError(4, 0, False)

    $g_sOriginalXmlContent = $sText
    $g_iCurrentFileEncoding = $iEncoding
    $g_sLoadedFileSignature = _GetNfoFileSignature($sFilePath)
    $g_bXmlSourceModified = False

    ; 保存成功后同步 DOM 和 XML 源码，避免“刷新读取”拿到打开时的旧快照。
    Local $oUpdatedDoc = _CreateXmlDoc()
    If IsObj($oUpdatedDoc) And $oUpdatedDoc.loadXML($sText) Then
        $g_oXMLDoc = $oUpdatedDoc
    Else
        Local $oPathDoc = _CreateXmlDoc()
        If IsObj($oPathDoc) And $oPathDoc.load($sFilePath) Then $g_oXMLDoc = $oPathDoc
    EndIf
    If IsObj($g_oXMLDoc) Then _LoadXmlSource()
    Return True
EndFunc

; 保存并返回可直接展示的失败原因
Func _SaveCurrentToFile($sFilePath)
    Local $vResult = _WriteNfoFile($sFilePath)
    Switch @error
        Case 0
            Return True
        Case 1
            Return SetError(1, 0, "请先打开一个 NFO 文件。编辑器只在已有文件的基础上修改，不新建 NFO。")
        Case 2
            Return SetError(1, 0, $vResult) ; 已携带 XML 校验说明
        Case 4
            Return SetError(1, 0, "保存失败：" & $sFilePath & @CRLF & @CRLF & "写入后校验失败，文件可能未正确落盘。")
        Case 5
            Return SetError(1, 0, $vResult)
        Case Else
            Return SetError(1, 0, "保存失败：" & $sFilePath & @CRLF & @CRLF & _
                "无法写入文件。请检查文件是否被其他程序占用、是否为只读，以及磁盘剩余空间。")
    EndSwitch
EndFunc

#EndRegion ;**** 数据保存 ****

#Region ;**** 事件处理 ****
; ==================== 事件处理 ====================

Func _ReadSettingsControls()
    If $g_idSettingsApiUrl = 0 Then Return
    $g_sDeepSeekApiUrl = StringStripWS(GUICtrlRead($g_idSettingsApiUrl), 3)
    $g_sDeepSeekApiKey = StringStripWS(GUICtrlRead($g_idSettingsApiKey), 3)
    $g_sDeepSeekModel = StringStripWS(GUICtrlRead($g_idSettingsModel), 3)
    $g_sLocalizePrompt = GUICtrlRead($g_idSettingsPrompt)

    If $g_sDeepSeekApiUrl = "" Then $g_sDeepSeekApiUrl = $DEFAULT_DEEPSEEK_API_URL
    If $g_sDeepSeekModel = "" Then $g_sDeepSeekModel = $DEFAULT_DEEPSEEK_MODEL
    If StringStripWS($g_sLocalizePrompt, 3) = "" Then $g_sLocalizePrompt = $DEFAULT_LOCALIZE_PROMPT
EndFunc

Func _OnSaveSettings()
    _ReadSettingsControls()
    If Not _SaveSettings() Then
        _SetAppStatus("DeepSeek 设置保存失败", $CLR_STATUS_ERROR)
        MsgBox(16, "保存失败", "无法写入设置文件：" & @CRLF & $g_sSettingsFile)
        Return
    EndIf

    GUICtrlSetData($g_idSettingsApiUrl, $g_sDeepSeekApiUrl)
    GUICtrlSetData($g_idSettingsModel, $g_sDeepSeekModel)
    GUICtrlSetData($g_idSettingsPrompt, $g_sLocalizePrompt)
    _SetAppStatus("DeepSeek 设置已保存", $CLR_STATUS_READY)
EndFunc

Func _OnResetPrompt()
    $g_sLocalizePrompt = $DEFAULT_LOCALIZE_PROMPT
    GUICtrlSetData($g_idSettingsPrompt, $g_sLocalizePrompt)
    _SetAppStatus("已恢复默认汉化 Prompt", $CLR_STATUS_READY)
EndFunc

Func _OnTestApi()
    _ReadSettingsControls()
    If StringStripWS($g_sDeepSeekApiKey, 3) = "" Then
        MsgBox(48, "提示", "请先在设置页填写 API Key")
        Return
    EndIf

    _SetAppStatus("正在测试 DeepSeek API...", $CLR_STATUS_READY)
    GUISetState(@SW_DISABLE, $g_hMainGui)
    Local $sResult = _CallDeepSeekLocalize("API 测试", "请只回复 OK")
    Local $iError = @error
    GUISetState(@SW_ENABLE, $g_hMainGui)
    WinActivate($g_hMainGui)

    If $iError Then
        _SetAppStatus("API 测试失败", $CLR_STATUS_ERROR)
        MsgBox(16, "API 测试失败", $sResult)
        Return
    EndIf

    _SetAppStatus("API 测试成功", $CLR_STATUS_READY)
    MsgBox(64, "API 测试成功", "DeepSeek API 连接和请求格式正常。")
EndFunc

Func _CaptureLocalizationPreviewPage($iPage, ByRef $aTitles, ByRef $aPlots, _
        ByRef $aTitleControls, ByRef $aPlotControls)
    For $i = 0 To 2
        $aTitles[$iPage][$i] = GUICtrlRead($aTitleControls[$i])
        $aPlots[$iPage][$i] = GUICtrlRead($aPlotControls[$i])
    Next
EndFunc

Func _GetLocalizationChoiceButtonIndex($idControl, ByRef $aChoiceButtons)
    For $i = 0 To 2
        If $idControl = $aChoiceButtons[$i][0] Or $idControl = $aChoiceButtons[$i][1] Then Return $i
    Next
    Return -1
EndFunc

Func _SetLocalizationChoiceButtons($iSelected, ByRef $aChoiceButtons)
    For $i = 0 To 2
        GUICtrlSetState($aChoiceButtons[$i][0], $GUI_SHOW)
        GUICtrlSetState($aChoiceButtons[$i][1], $GUI_HIDE)
    Next

    If $iSelected >= 0 And $iSelected <= 2 Then
        GUICtrlSetState($aChoiceButtons[$iSelected][0], $GUI_HIDE)
        GUICtrlSetState($aChoiceButtons[$iSelected][1], $GUI_SHOW)
    EndIf
EndFunc

Func _SetLocalizationPreviewPage($iPage, $iCount, ByRef $aRel, ByRef $aTitles, ByRef $aPlots, _
        ByRef $aSelections, ByRef $aChoiceButtons, ByRef $aTitleControls, ByRef $aPlotControls, _
        $idFileLabel, $idPrevious, $idNext)
    GUICtrlSetData($idFileLabel, "文件 " & ($iPage + 1) & " / " & $iCount & "    " & $aRel[$iPage])
    GUICtrlSetTip($idFileLabel, $aRel[$iPage])

    For $i = 0 To 2
        GUICtrlSetData($aTitleControls[$i], $aTitles[$iPage][$i])
        GUICtrlSetData($aPlotControls[$i], $aPlots[$iPage][$i])
    Next
    _SetLocalizationChoiceButtons($aSelections[$iPage], $aChoiceButtons)

    If $iPage = 0 Then
        GUICtrlSetState($idPrevious, $GUI_DISABLE)
    Else
        GUICtrlSetState($idPrevious, $GUI_ENABLE)
    EndIf
    If $iPage >= $iCount - 1 Then
        GUICtrlSetState($idNext, $GUI_DISABLE)
    Else
        GUICtrlSetState($idNext, $GUI_ENABLE)
    EndIf
EndFunc

; 按 NFO 逐页展示三个候选。返回 True 表示用户确认保存，False 表示取消且不修改文件。
Func _ShowBatchLocalizationPreview(ByRef $aRel, ByRef $aTitles, ByRef $aPlots, $iCount, ByRef $aSelections)
    Local Const $iPreviewW = 1500
    Local Const $iPreviewH = 800
    Local Const $iColumnW = 470
    Local Const $iColumnGap = 15
    Local Const $iCandidateX = 20
    Local Const $iCandidateY = 90

    ReDim $aSelections[$iCount]
    For $i = 0 To $iCount - 1
        $aSelections[$i] = -1
    Next

    Local $hPreview = _UI_CreateGUI("汉化结果预览", $iPreviewW, $iPreviewH, -1, -1, $g_hMainGui, $CLR_CARD_BG, $CLR_BORDER, 52)

    Local $idTitle = GUICtrlCreateLabel("汉化结果预览", 20, 16, 400, 28)
    GUICtrlSetColor($idTitle, $CLR_TEXT_PRIMARY)
    GUICtrlSetBkColor($idTitle, $CLR_CARD_BG)
    GUICtrlSetFont($idTitle, 14, 700, 0, "Microsoft YaHei UI")
    _UI_AddHSeperator(20, 52, $iPreviewW - 40, 1, $CLR_BORDER)

    Local $idFileLabel = GUICtrlCreateLabel("", 20, 62, $iPreviewW - 40, 22)
    _StyleMutedLabel($idFileLabel)

    Local $aChoiceButtons[3][2], $aTitleControls[3], $aPlotControls[3]
    For $i = 0 To 2
        Local $iX = $iCandidateX + $i * ($iColumnW + $iColumnGap)
        If $i < 2 Then
            Local $idSeparator = GUICtrlCreateLabel("", $iX + $iColumnW + 7, $iCandidateY, 1, 612)
            GUICtrlSetBkColor($idSeparator, $CLR_BORDER)
        EndIf

        $aChoiceButtons[$i][0] = _CreateAppButton("选择候选 " & ($i + 1), $iX, $iCandidateY, $iColumnW, 44, $CLR_SURFACE)
        $aChoiceButtons[$i][1] = _CreateAppButton("已选择候选 " & ($i + 1), $iX, $iCandidateY, $iColumnW, 44, $CLR_PRIMARY)
        GUICtrlSetTip($aChoiceButtons[$i][0], "选择这一列的汉化结果")
        GUICtrlSetTip($aChoiceButtons[$i][1], "当前已选择这一列的汉化结果")

        Local $idTitleLabel = GUICtrlCreateLabel("标题", $iX, 148, 80, 22)
        _StyleFieldLabel($idTitleLabel)
        $aTitleControls[$i] = GUICtrlCreateEdit("", $iX, 174, $iColumnW, 64, _
            BitOR($ES_MULTILINE, $ES_WANTRETURN, $ES_AUTOVSCROLL, $WS_VSCROLL))
        _StyleFieldInput($aTitleControls[$i])

        Local $idPlotLabel = GUICtrlCreateLabel("简介（中文 + 原文）", $iX, 246, 180, 22)
        _StyleFieldLabel($idPlotLabel)
        $aPlotControls[$i] = GUICtrlCreateEdit("", $iX, 272, $iColumnW, 430, _
            BitOR($ES_MULTILINE, $ES_WANTRETURN, $ES_AUTOVSCROLL, $WS_VSCROLL))
        _StyleFieldInput($aPlotControls[$i])
    Next

    Local $idPrevious = _CreateAppButton("上一个 NFO", 20, 730, 120, 36, $CLR_SURFACE)
    Local $idNext = _CreateAppButton("下一个 NFO", 150, 730, 120, 36, $CLR_SURFACE)
    Local $idSave = _CreateAppButton("保存所选结果", 1210, 730, 140, 36, $CLR_SUCCESS)
    Local $idCancel = _CreateAppButton("取消", 1360, 730, 100, 36, $CLR_SURFACE)
    GUICtrlSetTip($idSave, "确认所有 NFO 的候选后再写入文件")
    GUICtrlSetTip($idCancel, "取消本次批量汉化，不修改文件")

    Local $aWindowButtons = _UI_AddControlButtons($iPreviewW, True, False, $CLR_CARD_BG, $CLR_TEXT_PRIMARY)
    Local $iPage = 0
    Local $bSave = False
    _SetLocalizationPreviewPage($iPage, $iCount, $aRel, $aTitles, $aPlots, $aSelections, _
        $aChoiceButtons, $aTitleControls, $aPlotControls, $idFileLabel, $idPrevious, $idNext)

    GUISetState(@SW_SHOW, $hPreview)
    WinActivate($hPreview)

    While 1
        _UI_PollHover($hPreview)
        Local $aMsg = GUIGetMsg(1)
        If $aMsg[0] = 0 Then
            Sleep(20)
            ContinueLoop
        EndIf

        Local $iChoiceButton = _GetLocalizationChoiceButtonIndex($aMsg[0], $aChoiceButtons)
        If $iChoiceButton >= 0 Then
            _CaptureLocalizationPreviewPage($iPage, $aTitles, $aPlots, $aTitleControls, $aPlotControls)
            $aSelections[$iPage] = $iChoiceButton
            _SetLocalizationPreviewPage($iPage, $iCount, $aRel, $aTitles, $aPlots, $aSelections, _
                $aChoiceButtons, $aTitleControls, $aPlotControls, $idFileLabel, $idPrevious, $idNext)
            ContinueLoop
        EndIf

        Switch $aMsg[0]
            Case $GUI_EVENT_CLOSE, $aWindowButtons[0], $idCancel
                ExitLoop
            Case $idPrevious, $idNext
                _CaptureLocalizationPreviewPage($iPage, $aTitles, $aPlots, $aTitleControls, $aPlotControls)
                If $aSelections[$iPage] < 0 Then
                    MsgBox(48, "提示", "请先为当前 NFO 选择一个汉化结果。")
                    ContinueLoop
                EndIf
                If $aMsg[0] = $idPrevious Then
                    $iPage -= 1
                Else
                    $iPage += 1
                EndIf
                _SetLocalizationPreviewPage($iPage, $iCount, $aRel, $aTitles, $aPlots, $aSelections, _
                    $aChoiceButtons, $aTitleControls, $aPlotControls, $idFileLabel, $idPrevious, $idNext)
            Case $idSave
                _CaptureLocalizationPreviewPage($iPage, $aTitles, $aPlots, $aTitleControls, $aPlotControls)
                If $aSelections[$iPage] < 0 Then
                    MsgBox(48, "提示", "请先为当前 NFO 选择一个汉化结果。")
                    ContinueLoop
                EndIf

                Local $bAllSelected = True
                For $i = 0 To $iCount - 1
                    If $aSelections[$i] < 0 Or $aSelections[$i] > 2 Then
                        $bAllSelected = False
                        $iPage = $i
                        ExitLoop
                    EndIf
                Next
                If Not $bAllSelected Then
                    _SetLocalizationPreviewPage($iPage, $iCount, $aRel, $aTitles, $aPlots, $aSelections, _
                        $aChoiceButtons, $aTitleControls, $aPlotControls, $idFileLabel, $idPrevious, $idNext)
                    MsgBox(48, "提示", "请为每个 NFO 选择一个汉化结果后再保存。")
                    ContinueLoop
                EndIf
                $bSave = True
                ExitLoop
        EndSwitch
    WEnd

    _UI_GUIDelete($hPreview)
    Return $bSave
EndFunc

#EndRegion ;**** 事件处理 ****

#Region ;**** 批量汉化 ****
; ==================== 批量汉化 ====================

; 在 NFO 所在目录下创建备份文件夹，返回备份目录路径；失败返回 "" 并置 @error
Func _CreateBackupFolder($sBaseDir, $sStamp)
    Local $sBackupRoot = $sBaseDir & "\nfo_backup"
    If Not FileExists($sBackupRoot) And Not DirCreate($sBackupRoot) Then Return SetError(1, 0, "")

    Local $sBackupDir = $sBackupRoot & "\" & $sStamp
    If Not FileExists($sBackupDir) And Not DirCreate($sBackupDir) Then Return SetError(1, 0, "")
    Return $sBackupDir
EndFunc

; 把批量汉化的完整失败明细写入日志文件，避免 MsgBox 截断到 1500 字符。
; 优先写到备份目录下（与原文件备份放一起）；没有备份目录时写到当前目录。
; 返回日志文件完整路径；写入失败返回 ""。
Func _WriteBatchErrorLog($sFailReport, $sBackupRoot, $sStamp, $sCurrentDir)
    If StringStripWS($sFailReport, 3) = "" Then Return ""

    Local $sLogPath
    If $sBackupRoot <> "" And FileExists($sBackupRoot) Then
        $sLogPath = $sBackupRoot & "\errors.log"
    Else
        $sLogPath = $sCurrentDir & "\nfo_editor_errors_" & $sStamp & ".log"
    EndIf

    Local $hFile = FileOpen($sLogPath, BitOR(2, 256)) ; 覆盖写 + UTF-8 无 BOM
    If $hFile = -1 Then Return ""

    Local $sHeader = "NFO 编辑器 - 批量汉化错误明细" & @CRLF & _
        "时间戳: " & $sStamp & @CRLF & _
        "目录: " & $sCurrentDir & @CRLF & _
        StringReplace($sFailReport, @CRLF & "· ", @CRLF & "  · ") & @CRLF
    FileWrite($hFile, $sHeader)
    FileClose($hFile)
    Return $sLogPath
EndFunc

; 批量处理期间禁止编辑和切换文件，避免异步任务结束时覆盖用户新输入。
Func _SetBatchEditingEnabled($bEnabled)
    Local $iState = $GUI_ENABLE
    If Not $bEnabled Then $iState = $GUI_DISABLE

    ; 主工具栏、文件列表、表单按钮与文本区
    Local $aControls[26] = [$g_idList, $g_idFileSearch, _
        $g_idBtnOpen, $g_idBtnSave, $g_idBtnSaveAs, $g_idBtnRefresh, _
        $g_idBtnSelectDir, $g_idBtnCheckAll, $g_idBtnCheckNone, _
        $g_idBtnBatchLocalize, $g_idBtnAddActor, $g_idBtnRemoveActor, $g_idBtnSync, $g_idBtnRefreshXml, _
        $g_idBtnSaveSettings, $g_idBtnResetPrompt, $g_idBtnTestApi, $g_idXmlText, $g_idActorList, _
        $g_idSetName, $g_idTagText, $g_idGenreText, $g_idSettingsApiUrl, $g_idSettingsApiKey, _
        $g_idSettingsModel, $g_idSettingsPrompt]
    For $i = 0 To UBound($aControls) - 1
        If $aControls[$i] <> 0 Then GUICtrlSetState($aControls[$i], $iState)
    Next

    For $i = 0 To UBound($g_aBasicFields) - 1
        If $g_aBasicFields[$i][2] <> 0 Then GUICtrlSetState($g_aBasicFields[$i][2], $iState)
    Next
    For $i = 0 To UBound($g_aVideoFields) - 1
        If $g_aVideoFields[$i][2] <> 0 Then GUICtrlSetState($g_aVideoFields[$i][2], $iState)
    Next
    For $i = 0 To UBound($g_aAudioFields) - 1
        If $g_aAudioFields[$i][2] <> 0 Then GUICtrlSetState($g_aAudioFields[$i][2], $iState)
    Next
EndFunc

; 从 NFO 文本中读取单个简单标签的内容（未反转义），读不到返回 ""
Func _ReadTagText($sText, $sTag)
    Local $aMatch = StringRegExp($sText, "(?is)<" & $sTag & "(?:\s[^>]*)?>([\s\S]*?)</" & $sTag & ">", 1)
    If @error Or UBound($aMatch) < 1 Then Return ""
    Return _XmlUnescape(StringStripWS($aMatch[0], 3))
EndFunc

; 判断该 NFO 是否已由本工具汉化过。
; 默认 Prompt 要求简介保留“原文：”分隔符，因此它的存在是可靠的已处理标记。
Func _IsAlreadyLocalized($sPlot)
    Return StringInStr($sPlot, "原文：") > 0
EndFunc

Func _OnBatchLocalize()
    _ReadSettingsControls()

    Local $sChecked = _GetCheckedRelPaths()
    If $sChecked = "" Then
        MsgBox(48, "提示", "请先在文件列表中勾选需要汉化的 NFO 文件。" & @CRLF & @CRLF & "可使用“全选”按钮勾选当前筛选结果中的全部文件。")
        Return
    EndIf

    Local $aRel = StringSplit($sChecked, "|", 2)
    Local $iTotal = UBound($aRel)

    If StringStripWS($g_sDeepSeekApiKey, 3) = "" Then
        MsgBox(48, "提示", "请先在设置页填写 DeepSeek API Key。")
        Return
    EndIf

    ; 批量会改动多个文件且逐个消耗 token，动手前把代价讲清楚
    Local $iConfirm = MsgBox(0x23, "批量汉化确认", _
        "将对勾选的 " & $iTotal & " 个 NFO 文件进行汉化。" & @CRLF & @CRLF & _
        "· 每个文件调用一次 API，生成 3 个汉化候选" & @CRLF & _
        "· 简介中已含“原文：”的文件会自动跳过" & @CRLF & _
        "· 生成候选后逐个选择，确认后才写入文件" & @CRLF & _
        "· 原文件会备份到当前目录下的 nfo_backup\时间戳 文件夹" & @CRLF & @CRLF & _
        "是否继续？")
    If $iConfirm <> 6 Then
        _SetAppStatus("已取消批量汉化", $CLR_STATUS_READY)
        Return
    EndIf

    ; 当前文件有未保存修改时先落盘，否则批量写回会覆盖掉这些改动
    If Not _ConfirmDiscardChanges() Then
        _SetAppStatus("已取消批量汉化", $CLR_STATUS_READY)
        Return
    EndIf

    _BatchLocalizeRun($aRel)
EndFunc

; 批量汉化主流程。并发 2：AutoIt 单线程，靠异步 WinHttp + 轮询实现；
; 请求完成后先暂存三个候选，待用户逐个选择后才写回文件。
Func _BatchLocalizeRun($aRel)
    _SetBatchEditingEnabled(False)
    Local Const $iConcurrency = 2
    Local $iTotal = UBound($aRel)

    ; 显示进度条并初始化范围
    If $g_idProgressBar <> 0 Then
        GUICtrlSetData($g_idProgressBar, 0)
        GUICtrlSetState($g_idProgressBar, $GUI_SHOW)
    EndIf

    ; 批量汉化的时间戳，用于备份目录名和错误日志文件名
    Local $sStamp = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC & "_" & @MSEC & "_" & @AutoItPID

    Local $iOk = 0, $iSkip = 0, $iFail = 0, $iCancelled = 0
    Local $sFailReport = ""

    ; 请求成功的结果暂存为：相对路径、完整路径、原文、签名，以及三个标题/简介候选。
    Local $aResultRel[$iTotal], $aResultPath[$iTotal], $aResultText[$iTotal], $aResultSig[$iTotal]
    Local $aResultTitles[$iTotal][3], $aResultPlots[$iTotal][3]
    Local $iResultCount = 0

    ; 每个在飞任务：0=请求对象 1=完整路径 2=相对路径 3=原始文本
    Local $aSlotObj[$iConcurrency], $aSlotPath[$iConcurrency]
    Local $aSlotRel[$iConcurrency], $aSlotText[$iConcurrency], $aSlotSig[$iConcurrency]
    For $s = 0 To $iConcurrency - 1
        $aSlotObj[$s] = 0
    Next

    Local $iNext = 0, $iDone = 0, $iInFlight = 0
    Local $bCloseRequested = False

    ; 终止条件用「还有待派发」或「还有在飞」，不能用 $iDone < $iTotal：
    ; 中途取消时剩余文件不再计入 $iDone，那样会死循环。
    While $iNext < $iTotal Or $iInFlight > 0
        ; 1) 有空位就补新请求
        For $s = 0 To $iConcurrency - 1
            If $aSlotObj[$s] <> 0 Or $iNext >= $iTotal Then ContinueLoop

            Local $sRel = $aRel[$iNext]
            Local $sFull = _GetRelPathFullPath($sRel)
            $iNext += 1

            If $sFull = "" Or Not FileExists($sFull) Then
                $iFail += 1
                $iDone += 1
                $sFailReport &= @CRLF & "· " & $sRel & "：文件不存在"
                ContinueLoop
            EndIf

            ; 读原文（UTF8 无 BOM 模式，与 _LoadNfoFile 一致）
            Local $iFileEncoding = _GetNfoFileEncoding($sFull, 256)
            Local $hIn = FileOpen($sFull, $iFileEncoding)
            If $hIn = -1 Then
                $iFail += 1
                $iDone += 1
                $sFailReport &= @CRLF & "· " & $sRel & "：无法读取文件"
                ContinueLoop
            EndIf
            Local $sRaw = FileRead($hIn)
            FileClose($hIn)
            If StringLeft($sRaw, 1) = ChrW(0xFEFF) Then $sRaw = StringTrimLeft($sRaw, 1)

            Local $sOldTitle = _ReadTagText($sRaw, "title")
            Local $sOldPlot = _ReadTagText($sRaw, "plot")

            If $sOldTitle = "" And $sOldPlot = "" Then
                $iSkip += 1
                $iDone += 1
                $sFailReport &= @CRLF & "· " & $sRel & "：跳过（无 title/plot 标签）"
                ContinueLoop
            EndIf

            If _IsAlreadyLocalized($sOldPlot) Then
                $iSkip += 1
                $iDone += 1
                ContinueLoop
            EndIf

            Local $oReq = _StartDeepSeekRequest($sOldTitle, $sOldPlot)
            If @error Then
                $iFail += 1
                $iDone += 1
                $sFailReport &= @CRLF & "· " & $sRel & "：请求发起失败（错误码 " & @error & "）"
                ContinueLoop
            EndIf

            $aSlotObj[$s] = $oReq
            $aSlotPath[$s] = $sFull
            $aSlotRel[$s] = $sRel
            $aSlotText[$s] = $sRaw
            $aSlotSig[$s] = _GetNfoFileSignature($sFull)
            $iInFlight += 1
        Next

        ; 2) 轮询在飞请求
        Local $bAnyActive = ($iInFlight > 0)
        For $s = 0 To $iConcurrency - 1
            If $aSlotObj[$s] = 0 Then ContinueLoop

            Local $sOut = ""
            Local $iState = _PollDeepSeekRequest($aSlotObj[$s], $sOut)
            If $iState = 0 Then ContinueLoop

            If $iState = 1 Then
                Local $aNewTitles[3], $aNewPlots[3]
                Local $sOriginalTitle = _ReadTagText($aSlotText[$s], "title")
                Local $sOriginalPlot = _ReadTagText($aSlotText[$s], "plot")
                If _ParseLocalizedCandidates($sOut, $sOriginalTitle, $sOriginalPlot, $aNewTitles, $aNewPlots) Then
                    $aResultRel[$iResultCount] = $aSlotRel[$s]
                    $aResultPath[$iResultCount] = $aSlotPath[$s]
                    $aResultText[$iResultCount] = $aSlotText[$s]
                    $aResultSig[$iResultCount] = $aSlotSig[$s]
                    For $iCandidate = 0 To 2
                        $aResultTitles[$iResultCount][$iCandidate] = $aNewTitles[$iCandidate]
                        $aResultPlots[$iResultCount][$iCandidate] = $aNewPlots[$iCandidate]
                    Next
                    $iResultCount += 1
                Else
                    $iFail += 1
                    $sFailReport &= @CRLF & "· " & $aSlotRel[$s] & "：未能解析三个候选结果"
                EndIf
            Else
                $iFail += 1
                $sFailReport &= @CRLF & "· " & $aSlotRel[$s] & "：" & $sOut
            EndIf

            $aSlotObj[$s] = 0
            $iInFlight -= 1
            $iDone += 1
        Next

        _SetAppStatus("批量汉化中 " & $iDone & "/" & $iTotal & "（已生成 " & $iResultCount & " 个候选文件，跳过 " & $iSkip & " 失败 " & $iFail & "）", $CLR_STATUS_MODIFIED)
        ; 同步更新进度条（iDone / iTotal）
        If $g_idProgressBar <> 0 And $iTotal > 0 Then
            GUICtrlSetData($g_idProgressBar, Int($iDone * 100 / $iTotal))
        EndIf

        ; 3) 让出时间片处理窗口消息，避免界面假死；ESC 可中止后续任务
        If $bAnyActive Then Sleep(120)
        Local $aPump = GUIGetMsg(1)
        If $aPump[0] = $GUI_EVENT_CLOSE Or _
           (IsArray($g_aWindowControlButtons) And $aPump[0] = $g_aWindowControlButtons[$UI_BTN_CLOSE]) Then
            ; 关闭请求：停止派发新任务，但已在飞的请求等其结束；不进入候选预览或写回阶段。
            $bCloseRequested = True
            If $iNext < $iTotal Then
                $iCancelled = $iTotal - $iNext
                $iNext = $iTotal
            EndIf
        EndIf
    WEnd

    If $bCloseRequested Then
        ; 在途请求已全部结束，此时没有候选写回；直接走统一资源清理和退出路径。
        _OnAppExit()
        Return
    EndIf

    If $iResultCount = 0 Then
        Local $sNoResultMsg = "批量汉化完成，但没有可供选择的候选结果。" & @CRLF & @CRLF & _
            "共 " & $iTotal & " 个文件" & @CRLF & _
            "跳过 " & $iSkip & " 个" & @CRLF & _
            "失败 " & $iFail & " 个"
        If $iCancelled > 0 Then $sNoResultMsg &= @CRLF & "已取消 " & $iCancelled & " 个（未处理）"
        ; 完整失败明细写入日志文件，MsgBox 只提示路径，避免 1500 字符截断丢失信息
        Local $sLogPath = _WriteBatchErrorLog($sFailReport, "", $sStamp, $g_sCurrentDir)
        If $sLogPath <> "" Then
            $sNoResultMsg &= @CRLF & @CRLF & "完整明细已写入日志：" & @CRLF & $sLogPath
        ElseIf $sFailReport <> "" Then
            $sNoResultMsg &= @CRLF & @CRLF & "明细（日志写入失败，仅显示前 1500 字符）：" & StringLeft($sFailReport, 1500)
        EndIf
        If $iFail > 0 Then
            _SetAppStatus("批量汉化失败，未生成可选结果", $CLR_STATUS_ERROR)
            MsgBox(48, "批量汉化结果", $sNoResultMsg)
        Else
            _SetAppStatus("批量汉化完成，未生成可选结果", $CLR_STATUS_READY)
            MsgBox(64, "批量汉化结果", $sNoResultMsg)
        EndIf
        If $g_idProgressBar <> 0 Then GUICtrlSetState($g_idProgressBar, $GUI_HIDE)
    _SetBatchEditingEnabled(True)
        Return
    EndIf

    _SetAppStatus("候选生成完成，请逐个选择汉化结果", $CLR_STATUS_MODIFIED)
    Local $aSelections[$iResultCount]
    If Not _ShowBatchLocalizationPreview($aResultRel, $aResultTitles, $aResultPlots, $iResultCount, $aSelections) Then
        _SetAppStatus("已取消选择汉化结果，未修改任何文件", $CLR_STATUS_READY)
        If $g_idProgressBar <> 0 Then GUICtrlSetState($g_idProgressBar, $GUI_HIDE)
    _SetBatchEditingEnabled(True)
        Return
    EndIf

    ; 用户确认后才创建备份目录并写回，预览或取消阶段不会改变文件。
    Local $sBackupRoot = ""
    For $i = 0 To $iResultCount - 1
        If $sBackupRoot = "" Then
            $sBackupRoot = _CreateBackupFolder($g_sCurrentDir, $sStamp)
            If @error Then
                MsgBox(16, "错误", "无法创建备份目录：" & @CRLF & $g_sCurrentDir & @CRLF & @CRLF & "已中止批量汉化，未修改任何文件。")
                If $g_idProgressBar <> 0 Then GUICtrlSetState($g_idProgressBar, $GUI_HIDE)
                _SetBatchEditingEnabled(True)
                Return
            EndIf
        EndIf

        Local $iChoice = $aSelections[$i]
        Local $vResult = _ApplyLocalizedToFile($aResultPath[$i], $aResultText[$i], _
            $aResultTitles[$i][$iChoice], $aResultPlots[$i][$iChoice], $sBackupRoot, _
            $aResultRel[$i], $aResultSig[$i])
        If @error Then
            $iFail += 1
            $sFailReport &= @CRLF & "· " & $aResultRel[$i] & "：" & $vResult
        Else
            $iOk += 1
        EndIf
    Next

    Local $sMsg = "批量汉化完成。" & @CRLF & @CRLF & _
        "共 " & $iTotal & " 个文件" & @CRLF & _
        "进入预览 " & $iResultCount & " 个" & @CRLF & _
        "成功保存 " & $iOk & " 个" & @CRLF & _
        "跳过 " & $iSkip & " 个（已汉化或无可译字段）" & @CRLF & _
        "失败 " & $iFail & " 个"
    If $iCancelled > 0 Then $sMsg &= @CRLF & "已取消 " & $iCancelled & " 个（未处理）"
    If $sBackupRoot <> "" Then
        $sMsg &= @CRLF & @CRLF & "原文件备份目录：" & @CRLF & $sBackupRoot
    EndIf
    ; 完整失败明细写入日志文件（优先放备份目录），MsgBox 只提示路径
    If $sFailReport <> "" Then
        $sLogPath = _WriteBatchErrorLog($sFailReport, $sBackupRoot, $sStamp, $g_sCurrentDir)
        If $sLogPath <> "" Then
            $sMsg &= @CRLF & @CRLF & "完整明细已写入日志：" & @CRLF & $sLogPath
        Else
            $sMsg &= @CRLF & @CRLF & "明细（日志写入失败，仅显示前 1500 字符）：" & StringLeft($sFailReport, 1500)
        EndIf
    EndIf

    If $iFail > 0 Then
        _SetAppStatus("批量汉化完成，成功保存 " & $iOk & " 个，失败 " & $iFail & " 个", $CLR_STATUS_ERROR)
        MsgBox(48, "批量汉化结果", $sMsg)
    Else
        _SetAppStatus("批量汉化完成，成功保存 " & $iOk & " 个，跳过 " & $iSkip & " 个", $CLR_STATUS_READY)
        MsgBox(64, "批量汉化结果", $sMsg)
    EndIf

    ; 当前打开的文件可能已被批量改写，重新载入以免界面显示旧内容
    If $g_sCurrentFile <> "" And FileExists($g_sCurrentFile) And $iOk > 0 Then
        $g_bModified = False
        _LoadNfoFile($g_sCurrentFile)
    EndIf
    If $g_idProgressBar <> 0 Then GUICtrlSetState($g_idProgressBar, $GUI_HIDE)
    _SetBatchEditingEnabled(True)
EndFunc

; 备份原文件并把汉化结果写回。成功返回 True；失败置 @error 并返回可展示的原因。
; 不复用 _WriteNfoFile：那个函数从 GUI 控件取值，只适用于当前打开的文件。
Func _ApplyLocalizedToFile($sFullPath, $sRaw, $sNewTitle, $sNewPlot, $sBackupRoot, $sRelPath, $sExpectedSignature)
    ; 响应返回前若原文件已被外部修改，拒绝用旧快照覆盖新内容。
    If _GetNfoFileSignature($sFullPath) = "" Then Return SetError(1, 0, "原文件已不存在，已跳过写入")
    If $sExpectedSignature <> "" And _GetNfoFileSignature($sFullPath) <> $sExpectedSignature Then
        Return SetError(1, 0, "文件在请求期间已被其他程序修改，已跳过写入")
    EndIf

    Local $sText = _XmlRepairInvalidAmpersands($sRaw)
    If StringStripWS($sNewTitle, 3) <> "" Then
        $sText = _UpdateSimpleTagIfPresent($sText, "title", _XmlEscape(StringStripWS($sNewTitle, 3)))
    EndIf
    If StringStripWS($sNewPlot, 3) <> "" Then
        $sText = _UpdateSimpleTagIfPresent($sText, "plot", _XmlEscape(StringStripWS($sNewPlot, 3)))
    EndIf

    If $sText = $sRaw Then Return SetError(2, 0, "内容无变化，未写入")

    ; 写回前校验：结果必须合法，否则放弃写入以保护原文件。
    ; 与 _WriteNfoFile 一致 —— 原文本身不合法时不因此阻断。
    Local $oVerify = _CreateXmlDoc()
    If IsObj($oVerify) And Not $oVerify.loadXML($sText) Then
        Local $oBaseline = _CreateXmlDoc()
        If IsObj($oBaseline) And $oBaseline.loadXML($sRaw) Then
            Return SetError(3, 0, "生成的 XML 不合法，已放弃写入")
        EndIf
    EndIf

    ; 保留相对目录层级，避免 a\b.nfo 与 a_b.nfo 映射到同一备份文件。
    Local $sBackupRel = StringReplace($sRelPath, "/", "\")
    Local $sBackupPath = $sBackupRoot & "\" & $sBackupRel
    Local $sBackupDir = StringRegExpReplace($sBackupPath, "[\\/][^\\/]+$", "")
    If $sBackupDir <> $sBackupRoot And Not DirCreate($sBackupDir) Then
        Return SetError(1, 0, "无法创建备份子目录，已跳过写入")
    EndIf
    If Not FileCopy($sFullPath, $sBackupPath, 0) Then
        Return SetError(1, 0, "备份失败，已跳过写入")
    EndIf

    ; 批量写入也采用临时文件，避免失败时把原文件截断。
    Local $iEncoding = _GetNfoFileEncoding($sFullPath, 256)
    If Not _WriteFileAtomic($sFullPath, $sText, $iEncoding) Then Return SetError(4, 0, "无法写入文件（可能被占用或只读）")
    If FileGetSize($sFullPath) = 0 Then Return SetError(5, 0, "写入后校验失败，文件为空")

    Return True
EndFunc

; 文件列表选择事件
Func _OnFileSelect()
    Local $iIndex = _GUICtrlListView_GetSelectedIndices($g_idList)
    If $iIndex = "" Then Return
    Local $sSelected = _GUICtrlListView_GetItemText($g_idList, Number($iIndex), 0)
    If $sSelected = "" Then Return
    ; 重复点击同一个文件时不重新加载，避免把未保存修改冲掉
    If $g_sCurrentFile <> "" And _GetRelPathFullPath($sSelected) = $g_sCurrentFile Then Return
    If Not _ConfirmDiscardChanges() Then
        ; 用户取消切换时恢复列表选择，避免列表指向 B 而表单仍显示 A。
        Local $bFound = False
        For $i = 0 To _GUICtrlListView_GetItemCount($g_idList) - 1
            If $g_sCurrentFile <> "" And _GetRelPathFullPath(_GUICtrlListView_GetItemText($g_idList, $i, 0)) = $g_sCurrentFile Then
                _GUICtrlListView_SetItemSelected($g_idList, $i, True, True)
                $bFound = True
                ExitLoop
            EndIf
        Next
        ; 当前文件被筛选隐藏，列表中找不到 → 清空选择，
        ; 避免列表指向 B 而表单仍显示 A 的不一致。
        ; LVS_SINGLESEL 模式下最多只有一个选中项，逐个取消即可。
        If Not $bFound Then
            Local $sSel = _GUICtrlListView_GetSelectedIndices($g_idList, False)
            If $sSel <> "" Then
                Local $aSel = StringSplit($sSel, "|")
                For $i = 1 To $aSel[0]
                    _GUICtrlListView_SetItemSelected($g_idList, Number($aSel[$i]), False, False)
                Next
            EndIf
        EndIf
        Return
    EndIf

    Local $sFullPath = _GetRelPathFullPath($sSelected)
    If $sFullPath <> "" Then _LoadNfoFile($sFullPath)
EndFunc

; 将列表中的相对路径直接拼接到当前目录，避免每次选择/批量处理都线性扫描元数据数组。
Func _GetRelPathFullPath($sRelPath)
    $sRelPath = StringReplace(StringStripWS($sRelPath, 3), "/", "\")
    If $sRelPath = "" Or $g_sCurrentDir = "" Then Return ""

    ; 列表项必须是相对路径；拒绝盘符路径、UNC 路径和 .. 路径段。
    If StringLeft($sRelPath, 1) = "\" Or StringRegExp($sRelPath, "(?i)^[a-z]:") Then Return ""
    Local $aParts = StringSplit($sRelPath, "\")
    For $i = 1 To $aParts[0]
        If $aParts[$i] = ".." Then Return ""
    Next

    Local $sBase = $g_sCurrentDir
    If StringRight($sBase, 1) <> "\" Then $sBase &= "\"
    Return $sBase & $sRelPath
EndFunc

; 打开文件
Func _OnOpenFile()
    Local $sFile = FileOpenDialog("选择NFO文件", $g_sCurrentDir, "NFO文件 (*.nfo)|所有文件 (*.*)", 1)
    If $sFile <> "" Then
        If Not _ConfirmDiscardChanges() Then Return
        _LoadNfoFile($sFile)
    EndIf
EndFunc

; 选择目录
Func _OnSelectDirectory()
    Local $sDir = FileSelectFolder("选择NFO文件目录", "", 1, $g_sCurrentDir)
    If $sDir <> "" Then
        If Not _ConfirmDiscardChanges() Then Return
        $g_sCurrentDir = $sDir
        $g_sCurrentFile = ""
        $g_oXMLDoc = Null
        $g_sOriginalXmlContent = ""
        $g_sLoadedFileSignature = ""
        $g_bModified = False
        $g_bXmlSourceModified = False
        $g_sCheckedRelPaths = ""
        _ClearAllFields()
        _UpdateDirectoryLabel()
        _LoadDirectoryFiles()
    EndIf
EndFunc

; 保存文件
Func _OnSaveFile()
    If $g_bXmlSourceModified Then
        If Not _OnSyncFromXml() Then Return
    EndIf

    If $g_sCurrentFile = "" Then
        _OnSaveFileAs()
        Return
    EndIf

    Local $vResult = _SaveCurrentToFile($g_sCurrentFile)
    If @error Then
        ; 保存失败时保持脏标记，避免 _ConfirmDiscardChanges 误判为已保存而丢弃改动
        _SetAppStatus("保存失败: " & _GetFileName($g_sCurrentFile), $CLR_STATUS_ERROR)
        MsgBox(16, "保存失败", $vResult)
        Return
    EndIf

    $g_bModified = False
    _SetAppStatus("已保存: " & _GetFileName($g_sCurrentFile), $CLR_STATUS_READY)
EndFunc

; 另存为
Func _OnSaveFileAs()
    If $g_bXmlSourceModified Then
        If Not _OnSyncFromXml() Then Return
    EndIf

    Local $sFile = FileSaveDialog("另存为", $g_sCurrentDir, "NFO文件 (*.nfo)|所有文件 (*.*)", 16, "")
    If $sFile = "" Then Return

    ; 确保 .nfo 扩展名
    If StringLower(StringRight($sFile, 4)) <> ".nfo" Then
        $sFile &= ".nfo"
    EndIf

    Local $vResult = _SaveCurrentToFile($sFile)
    If @error Then
        _SetAppStatus("保存失败: " & _GetFileName($sFile), $CLR_STATUS_ERROR)
        MsgBox(16, "保存失败", $vResult)
        Return
    EndIf

    $g_sCurrentFile = $sFile
    $g_bModified = False
    _SetAppStatus("已保存: " & _GetFileName($sFile), $CLR_STATUS_READY)
    WinSetTitle($g_hMainGui, "", "NFO编辑器 - " & _GetFileName($sFile))
    _LoadDirectoryFiles()
EndFunc

; 添加演员
Func _OnAddActor()
    GUICtrlSetData($g_idActorName, "")
    GUICtrlSetData($g_idActorRole, "")
    GUICtrlSetData($g_idActorType, "Actor")
    GUICtrlSetData($g_idActorTmdbId, "")

    ; 显示对话框（模态）
    GUISetState(@SW_DISABLE, $g_hMainGui)
    GUISetState(@SW_SHOW, $g_hActorDialog)
    WinActivate($g_hActorDialog)
EndFunc

; 删除选中演员
Func _OnRemoveActor()
    Local $iSelected = _GUICtrlListView_GetSelectedIndices($g_idActorList)
    If $iSelected = "" Then
        MsgBox(48, "提示", "请先选择要删除的演员")
        Return
    EndIf

    ; 支持多选删除（从后往前删）
    Local $aSelected = StringSplit($iSelected, "|")
    For $i = $aSelected[0] To 1 Step -1
        _GUICtrlListView_DeleteItem($g_idActorList, Number($aSelected[$i]))
    Next

    Local $iCount = _GUICtrlListView_GetItemCount($g_idActorList)
    For $i = 0 To $iCount - 1
        _GUICtrlListView_SetItemText($g_idActorList, $i, $i + 1, 0)
    Next

    $g_bModified = True
    _SetAppStatus("演员已删除，请检查后保存", $CLR_STATUS_MODIFIED)
EndFunc

; 从 XML 源码同步到表单
Func _OnSyncFromXml()
    Local $sXmlContent = GUICtrlRead($g_idXmlText)
    If $sXmlContent = "" Then
        MsgBox(48, "提示", "XML源码为空")
        Return False
    EndIf

    Local $oNewDoc = _CreateXmlDoc()
    If Not IsObj($oNewDoc) Then
        MsgBox(16, "错误", "无法创建XML解析器")
        Return False
    EndIf

    If Not $oNewDoc.loadXML($sXmlContent) Then
        MsgBox(16, "错误", "同步失败: XML解析错误" & _XmlParseErrorDetail($oNewDoc))
        Return False
    EndIf

    Local $oRoot = $oNewDoc.documentElement
    If Not IsObj($oRoot) Then
        MsgBox(16, "错误", "同步失败: 无效的XML根元素")
        Return False
    EndIf

    ; 设置 loading 标志，抑制表单回填时的 EN_CHANGE 冗余处理
    $g_oXMLDoc = $oNewDoc
    ; 同步原始文本基底：否则保存仍以旧原文做差量替换，
    ; 用户在 XML 页新增节点、调整顺序、删除节点的改动会被静默丢弃。
    $g_sOriginalXmlContent = $sXmlContent
    $g_bLoading = True
    _ClearAllFields()
    _LoadBasicInfo($oRoot)
    _LoadActors($oRoot)
    _LoadMediaInfo($oRoot)
    $g_bLoading = False

    $g_bXmlSourceModified = False
    $g_bModified = True
    _SetAppStatus("已从 XML 源码同步到表单，请检查后保存", $CLR_STATUS_MODIFIED)
    Return True
EndFunc

; 演员对话框 - 确定
Func _OnActorDialogOk()
    Local $sName = StringStripWS(GUICtrlRead($g_idActorName), 3)
    If $sName = "" Then
        MsgBox(48, "提示", "请输入演员姓名")
        Return
    EndIf

    Local $sRole = StringStripWS(GUICtrlRead($g_idActorRole), 3)
    Local $sType = StringStripWS(GUICtrlRead($g_idActorType), 3)
    Local $sTmdbId = StringStripWS(GUICtrlRead($g_idActorTmdbId), 3)

    _ActorAddRow($sName, $sRole, $sType, $sTmdbId)

    $g_bModified = True
    _SetAppStatus("演员已添加，请检查后保存", $CLR_STATUS_MODIFIED)

    ; 关闭对话框
    _CloseActorDialog()
EndFunc

; 演员对话框 - 取消
Func _OnActorDialogCancel()
    _CloseActorDialog()
EndFunc

; 关闭演员对话框并恢复主窗口
Func _CloseActorDialog()
    GUISetState(@SW_HIDE, $g_hActorDialog)
    GUISetState(@SW_ENABLE, $g_hMainGui)
    WinActivate($g_hMainGui)
EndFunc

; 统一的应用退出路径：清理自绘 GUI 与 GDI+ 资源后退出。
Func _OnAppExit()
    If $g_hActorDialog <> 0 Then _UI_GUIDelete($g_hActorDialog)
    If $g_hMainGui <> 0 Then _UI_GUIDelete($g_hMainGui)
    _UI_Shutdown()
    Exit
EndFunc

#EndRegion ;**** 批量汉化 ****

#Region ;**** 主函数入口 ****
; ==================== 主函数 ====================
Func Tool2_Main()
    Opt("GUIOnEventMode", 0)

    Local $sSettingsDir = @LocalAppDataDir & "\MediaResourceToolbox"
    DirCreate($sSettingsDir)
    If Not FileExists($g_sSettingsFile) Then
        Local $sLegacySettings = @ScriptDir & "\nfo_editor_settings.ini"
        If Not FileExists($sLegacySettings) Then $sLegacySettings = @ScriptDir & "\工具2nfo编辑器\nfo_editor_settings.ini"
        If Not FileExists($sLegacySettings) Then $sLegacySettings = @ScriptDir & "\..\工具2nfo编辑器\nfo_editor_settings.ini"
        If FileExists($sLegacySettings) Then FileCopy($sLegacySettings, $g_sSettingsFile, 0)
    EndIf

    ; COM 错误处理器：需保持引用存活，Main 贯穿整个程序生命周期
    Local $oErrorHandler = ObjEvent("AutoIt.Error", "_ComErrorHandler")

    _LoadSettings()
    _UI_Init()
    _CreateMainGui()
    _LoadDirectoryFiles()

    ; 主消息循环
    While 1
        If $g_hActorDialog <> 0 And BitAND(WinGetState($g_hActorDialog), 2) Then
            _UI_PollHover($g_hActorDialog)
        Else
            _UI_PollHover($g_hMainGui)
        EndIf
        Local $aMsg = GUIGetMsg(1)

        ; 防抖：搜索筛选延迟执行（避免逐字符触发 _ApplyFilters）
        If $g_iSearchDebounceTimer <> 0 And TimerDiff($g_iSearchDebounceTimer) >= $DEBOUNCE_DELAY Then
            $g_iSearchDebounceTimer = 0
            _ApplyFilters()
        EndIf

        ; ListView 选择变更由 WM_NOTIFY 置标记，在主循环里处理：
        ; 通知回调中弹 MsgBox 会阻塞消息派发并可能重入。
        If $g_bPendingFileSelect Then
            $g_bPendingFileSelect = False
            _OnFileSelect()
        EndIf

        ; 演员 ListView 的 Del 键事件由 WM_NOTIFY 置标记，主循环处理避免重入
        If $g_bPendingActorDelete Then
            $g_bPendingActorDelete = False
            _OnRemoveActor()
        EndIf

        Switch $aMsg[0]
            Case $GUI_EVENT_CLOSE
                If $aMsg[1] = $g_hActorDialog Then
                    _OnActorDialogCancel()
                ElseIf Not _ConfirmDiscardChanges() Then
                    ContinueLoop
                Else
                    _OnAppExit()
                EndIf

            Case $g_aWindowControlButtons[$UI_BTN_CLOSE]
                If Not _ConfirmDiscardChanges() Then ContinueLoop
                _OnAppExit()
            Case $g_aWindowControlButtons[$UI_BTN_MINIMIZE]
                GUISetState(@SW_MINIMIZE, $g_hMainGui)
            Case $g_aActorDialogButtons[0]
                _OnActorDialogCancel()

            ; 主窗口控件（快捷键与对应按钮合并为同一 Case）
            Case $g_idAccelSave, $g_idBtnSave
                _OnSaveFile()
            Case $g_idAccelOpen, $g_idBtnOpen
                _OnOpenFile()
            Case $g_idAccelSaveAs, $g_idBtnSaveAs
                _OnSaveFileAs()
            Case $g_idAccelRefresh, $g_idBtnRefresh
                _LoadDirectoryFiles()
            Case $g_idAccelCheckAll, $g_idBtnCheckAll
                _SetAllChecked(True)
            Case $g_idBtnSelectDir
                _OnSelectDirectory()
            Case $g_idBtnCheckNone
                _SetAllChecked(False)
            Case $g_idBtnBatchLocalize
                _OnBatchLocalize()
            Case $g_idBtnAddActor
                _OnAddActor()
            Case $g_idBtnRemoveActor
                _OnRemoveActor()
            Case $g_idBtnSync
                _OnSyncFromXml()
            Case $g_idBtnRefreshXml
                _OnRefreshXmlSource()
            Case $g_idBtnSaveSettings
                _OnSaveSettings()
            Case $g_idBtnResetPrompt
                _OnResetPrompt()
            Case $g_idBtnTestApi
                _OnTestApi()

            ; 音频语言下拉框：CBN_SELCHANGE 不会经过 _OnEditChange，此处补置脏标记
            Case $g_idAudioLangCombo
                If Not $g_bLoading Then
                    $g_bModified = True
                    _SetAppStatus("有未保存修改", $CLR_STATUS_MODIFIED)
                EndIf
            ; 演员对话框控件
            Case $g_idActorOk
                _OnActorDialogOk()
            Case $g_idActorCancel
                _OnActorDialogCancel()
        EndSwitch

        ; 无待处理 GUI 消息时短暂让出 CPU；10ms 不影响常规交互响应。
        If $aMsg[0] = 0 Then Sleep(10)
    WEnd
EndFunc   ;==>Tool2_Main

#EndRegion ;**** 主函数入口 ****

#EndRegion ;**** 工具2：NFO 编辑器 (tool-2) ****

#Region ;**** 工具3：媒体命名模板速查 (tools-3) ****
; 常量定义
Global Const $PANEL_MOVIE = 0
Global Const $PANEL_TV = 1

; 颜色方案
Global Const $COLOR_BG = 0xF5F7FB
Global Const $COLOR_CARD = 0xFFFFFF
Global Const $COLOR_TEXT = 0x17202A
Global Const $COLOR_MUTED = 0x667085
Global Const $COLOR_BORDER = 0xE4E7EC
Global Const $COLOR_SURFACE = 0xF8F9FC
Global Const $COLOR_TABBAR = 0xEEF1F6
Global Const $COLOR_PRIMARY = 0x635BDB
Global Const $COLOR_VARIABLE = 0xC0267E
Global Const $COLOR_SUCCESS = 0x12B76A
Global Const $COLOR_PREVIEW_BG = 0xF0F4FF
Global Const $COLOR_PREVIEW_BORDER = 0xD9E1F8
Global Const $COLOR_PREVIEW_ICON = 0x7C8DB5

; 全局变量
Global $g_aButtons[1]
Global $g_aTemplates[1]
Global $g_aButtonPanels[1]
Global $g_aButtonCards[1]
Global $g_iButtonCount = 0
Global $g_aMovieTabs[5]
Global $g_aTvTabs[3]
Global $g_aMoviePageCtrls[5][12]
Global $g_aTvPageCtrls[3][22]
Global $g_aMoviePageCounts[5]
Global $g_aTvPageCounts[3]
Global $g_iMoviePage = 4
Global $g_iTvPage = 0
Global $g_iCopiedButton = 0
Global $g_iCopiedPanel = -1
Global $g_iCopiedCard = -1
Global $g_hCopyTimer = 0
Global $g_hToastTimer = 0
Global $g_idToast = 0
Global $g_idMoviePicture = 0
Global $g_idTvPicture = 0
Global $g_hMovieBitmap = 0
Global $g_hTvBitmap = 0

Func Tool3_Main()
Opt("MustDeclareVars", 1)
_GDIPlus_Startup()

; 分辨率为 1600x900
Global $g_hTool3Gui = GUICreate("媒体命名模板", 1600, 900, -1, -1, BitOR($WS_CAPTION, $WS_MINIMIZEBOX, $WS_SYSMENU), $WS_EX_COMPOSITED)
GUISetBkColor($COLOR_BG, $g_hTool3Gui)

; 头部设计
GUICtrlCreateLabel("", 30, 22, 8, 70)
GUICtrlSetBkColor(-1, $COLOR_PRIMARY)

Global $g_idTitle = GUICtrlCreateLabel("命名模板速查", 55, 20, 400, 50)
GUICtrlSetFont($g_idTitle, 25, $FW_BOLD, 0, "Microsoft YaHei UI")
GUICtrlSetColor($g_idTitle, $COLOR_TEXT)

Global $g_idEyebrow = GUICtrlCreateLabel("MEDIA TEMPLATE LIBRARY", 56, 70, 325, 28)
GUICtrlSetFont($g_idEyebrow, 10, $FW_BOLD, 0, "Segoe UI")
GUICtrlSetColor($g_idEyebrow, $COLOR_PRIMARY)

; 电影区域标题
; GUICtrlCreateLabel("文本内容", 左边距, 顶边距, 宽度, 高度)
Global $g_idMovieHeader = GUICtrlCreateLabel("电影", 30, 120, 60, 32)
GUICtrlSetFont($g_idMovieHeader, 16, $FW_BOLD, 0, "Microsoft YaHei UI")
GUICtrlSetColor($g_idMovieHeader, $COLOR_TEXT)

Global $g_idMovieMeta = GUICtrlCreateLabel("电影的媒体文件夹命名 / 文件命名", 100, 129, 325, 28)
GUICtrlSetFont($g_idMovieMeta, 11, $FW_NORMAL, 0, "Microsoft YaHei UI")
GUICtrlSetColor($g_idMovieMeta, $COLOR_MUTED)

; 电视剧区域标题
Global $g_idTvHeader = GUICtrlCreateLabel("电视剧", 820, 120, 90, 32)
GUICtrlSetFont($g_idTvHeader, 16, $FW_BOLD, 0, "Microsoft YaHei UI")
GUICtrlSetColor($g_idTvHeader, $COLOR_TEXT)

Global $g_idTvMeta = GUICtrlCreateLabel("剧集的主文件夹命名 / 季文件夹命名 / 文件命名", 920, 129, 450, 28)
GUICtrlSetFont($g_idTvMeta, 11, $FW_NORMAL, 0, "Microsoft YaHei UI")
GUICtrlSetColor($g_idTvMeta, $COLOR_MUTED)

; 电影面板
Global $g_hMovie = GUICreate("", 750, 650, 30, 160, $WS_CHILD, $WS_EX_CONTROLPARENT, $g_hTool3Gui)
GUISetBkColor($COLOR_CARD, $g_hMovie)
GUISwitch($g_hMovie)
$g_idMoviePicture = GUICtrlCreatePic("", 0, 0, 750, 650)
GUICtrlSetState($g_idMoviePicture, $GUI_DISABLE)
_WinAPI_SetWindowPos(GUICtrlGetHandle($g_idMoviePicture), $HWND_BOTTOM, 0, 0, 0, 0, BitOR($SWP_NOSIZE, $SWP_NOMOVE, $SWP_NOACTIVATE))

; 电影标签页
$g_aMovieTabs[0] = _CreateTabLabel(22, 135, "JP 日语")
$g_aMovieTabs[1] = _CreateTabLabel(162, 135, "CN 华语")
$g_aMovieTabs[2] = _CreateTabLabel(302, 135, "KR 韩语")
$g_aMovieTabs[3] = _CreateTabLabel(442, 135, "EN 欧美")
$g_aMovieTabs[4] = _CreateTabLabel(582, 135, "🚫 Porn")

; 电影卡片（优化预览显示）
_AddCard($PANEL_MOVIE, 0, 0, "文件夹", "${Title} (${year})", "预览：啊，海军 (1969)")
_AddCard($PANEL_MOVIE, 0, 1, "文件名", "[${originalTitle}].${year}.${mediaSource}.${videoFormat}.${videoCodec}.${audioCodec}", "预览：[あゝ海軍].1969.Web-DL.1080p.h265.EAC3.mkv")

_AddCard($PANEL_MOVIE, 1, 0, "文件夹", "${Title} (${year})", "预览：警察故事 (1985)")
_AddCard($PANEL_MOVIE, 1, 1, "文件名", "《${originalTitle}》.${year}.${mediaSource}.${videoFormat}.${videoCodec}.${audioCodec}", "预览：《警察故事》.1985.Blu-ray.1080p.h265.AC3.mkv")

_AddCard($PANEL_MOVIE, 2, 0, "文件夹", "${Title} (${year})", "预览：首尔之春 (2023)")
_AddCard($PANEL_MOVIE, 2, 1, "文件名", "${Title}.${originalTitle}.${year}.${mediaSource}.${videoFormat}.${videoCodec}.${audioCodec}", "预览：首尔之春.서울의 봄.2023.Web-DL.1080p.h264.AAC.mkv")

_AddCard($PANEL_MOVIE, 3, 0, "文件夹", "${Title} (${year})", "预览：阿甘正传 (1994)")
_AddCard($PANEL_MOVIE, 3, 1, "文件名", "${Title}.${originalTitle}.${year}.${mediaSource}.${videoFormat}.${videoCodec}.${audioCodec}", "预览：阿甘正传.Forrest Gump.1994.UHD Blu-ray.2160p.h265.FLAC.mkv")

_AddCard($PANEL_MOVIE, 4, 0, "JAV出品-命名格式", "[${first_actor}] ${number} (${year})", "预览：[葵つかさ] SONE-059 (2024)")
_AddCard($PANEL_MOVIE, 4, 1, "欧美大厂出品-命名格式", "[${number}]${originalTitle}", "预览：[Tushy.25.11.09]Petite Hottie Is Crazy For Anal")

_InitPageVisibility($PANEL_MOVIE, $g_iMoviePage)
_RenderPanel($PANEL_MOVIE, $g_iMoviePage, -1)
GUISetState(@SW_SHOW, $g_hMovie)

; 电视剧面板
Global $g_hTv = GUICreate("", 750, 650, 820, 160, $WS_CHILD, $WS_EX_CONTROLPARENT, $g_hTool3Gui)
GUISetBkColor($COLOR_CARD, $g_hTv)
GUISwitch($g_hTv)
$g_idTvPicture = GUICtrlCreatePic("", 0, 0, 750, 650)
GUICtrlSetState($g_idTvPicture, $GUI_DISABLE)
_WinAPI_SetWindowPos(GUICtrlGetHandle($g_idTvPicture), $HWND_BOTTOM, 0, 0, 0, 0, BitOR($SWP_NOSIZE, $SWP_NOMOVE, $SWP_NOACTIVATE))

; 电视剧标签页
$g_aTvTabs[0] = _CreateTabLabel(22, 225, "日韩")
$g_aTvTabs[1] = _CreateTabLabel(262, 225, "国产")
$g_aTvTabs[2] = _CreateTabLabel(502, 225, "欧美")

; 电视剧卡片（优化预览显示）
_AddCard($PANEL_TV, 0, 0, "主文件夹", "【NHK】${showOriginalTitle} (${showYear})", "预览：【NHK】太平記 (1991)")
_AddCard($PANEL_TV, 0, 1, "季文件夹", "Season ${seasonNr}", "预览：Season 1")
_AddCard($PANEL_TV, 0, 2, "文件名", "『${showTitle}』第${episodeNr}回：${Title}(${videoFormat})", "预览：『太平記』第22集：鎌倉炎上(1080p).mkv")
_AddCard($PANEL_TV, 0, 3, "总集篇", "『${showTitle}•总集篇』第${episodeNr}回：${originalTitle}(${videoFormat})", "预览：『草燃•总集篇』第1回：赖朝起兵(1080p).mp4")

_AddCard($PANEL_TV, 1, 0, "主文件夹", "[${showTitle}]$(${showYear})", "预览：[大明王朝1566](2007)")
_AddCard($PANEL_TV, 1, 1, "季文件夹", "Season ${seasonNr}", "预览：Season 1")
_AddCard($PANEL_TV, 1, 2, "文件名", "第${episodeNr}集：${originalTitle}(${videoFormat})", "预览：第3集：严世蕃端午汛毁堤淹田(1080p).mp4")

_AddCard($PANEL_TV, 2, 0, "主文件夹", "【美剧】${showTitle} (${showYear})", "预览：【美剧】毒枭 (2015)")
_AddCard($PANEL_TV, 2, 1, "季文件夹", "Season ${seasonNr}", "预览：Season 1")
_AddCard($PANEL_TV, 2, 2, "文件名", "[${showOriginalTitle}]S${seasonNr2}E${episodeNr2}：${originalTitle}（${title}）(${videoFormat})", "预览：[Narcos]S01E03：The Men of Always（一如既往）(1080p).mp4")

_InitPageVisibility($PANEL_TV, $g_iTvPage)
_RenderPanel($PANEL_TV, $g_iTvPage, -1)
GUISetState(@SW_SHOW, $g_hTv)

; 提示框
GUISwitch($g_hTool3Gui)
$g_idToast = GUICtrlCreateLabel("", 575, 825, 450, 42, BitOR($SS_CENTER, $SS_CENTERIMAGE))
GUICtrlSetFont($g_idToast, 13, $FW_BOLD, 0, "Microsoft YaHei UI")
GUICtrlSetColor($g_idToast, $COLOR_CARD)
GUICtrlSetBkColor($g_idToast, $COLOR_TEXT)
GUICtrlSetState($g_idToast, $GUI_HIDE)

GUISetState(@SW_SHOW, $g_hTool3Gui)

While 1
    Local $aMsg = GUIGetMsg(1)
    Switch $aMsg[0]
        Case $GUI_EVENT_CLOSE
            If $aMsg[1] = $g_hTool3Gui Then ExitLoop
        Case Else
            _Tool3_HandleClick($aMsg[0])
    EndSwitch
    _UpdateTransientState()
    Sleep(20)
WEnd

_DisposePanelBitmap($g_idMoviePicture, $g_hMovieBitmap)
_DisposePanelBitmap($g_idTvPicture, $g_hTvBitmap)
GUIDelete($g_hMovie)
GUIDelete($g_hTv)
GUIDelete($g_hTool3Gui)
_GDIPlus_Shutdown()
EndFunc   ;==>Tool3_Main

Func _CreateTabLabel($iX, $iW, $sText)
    Local $idTab = GUICtrlCreateLabel($sText, $iX, 15, $iW, 32, BitOR($SS_CENTER, $SS_CENTERIMAGE, $SS_NOTIFY))
    GUICtrlSetFont($idTab, 11, $FW_NORMAL, 0, "Microsoft YaHei UI")
    GUICtrlSetColor($idTab, $COLOR_MUTED)
    GUICtrlSetBkColor($idTab, $GUI_BKCOLOR_TRANSPARENT)
    Return $idTab
EndFunc

Func _AddCard($iPanel, $iPage, $iCard, $sLabel, $sTemplate, $sPreview)
    Local $iX = 15
    Local $iY = 72 + ($iCard * 145) ; 增加间距以容纳更美观的预览
    Local $iW = 720
    
    ; 标签
    Local $idLabel = GUICtrlCreateLabel($sLabel, $iX + 22, $iY + 11, $iW - 137, 25)
    GUICtrlSetFont($idLabel, 11, $FW_BOLD, 0, "Microsoft YaHei UI")
    GUICtrlSetColor($idLabel, $COLOR_TEXT)
    GUICtrlSetBkColor($idLabel, $GUI_BKCOLOR_TRANSPARENT)
    _RegisterPageControl($iPanel, $iPage, $idLabel)
    
    ; 模板框（增加高度和边距）
    Local $idTemplate = GUICtrlCreateLabel($sTemplate, $iX + 22, $iY + 44, 505, 35, $SS_CENTERIMAGE)
    GUICtrlSetFont($idTemplate, 11, $FW_NORMAL, 0, "Consolas")
    GUICtrlSetColor($idTemplate, $COLOR_VARIABLE)
    GUICtrlSetBkColor($idTemplate, $GUI_BKCOLOR_TRANSPARENT)
    _RegisterPageControl($iPanel, $iPage, $idTemplate)
    
    ; 预览框（美化：增加背景、边框和图标）
    Local $idPreviewIcon = GUICtrlCreateLabel("▶", $iX + 22, $iY + 85, 20, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE))
    GUICtrlSetFont($idPreviewIcon, 10, $FW_BOLD, 0, "Segoe UI Symbol")
    GUICtrlSetColor($idPreviewIcon, $COLOR_PREVIEW_ICON)
    GUICtrlSetBkColor($idPreviewIcon, $GUI_BKCOLOR_TRANSPARENT)
    _RegisterPageControl($iPanel, $iPage, $idPreviewIcon)
    
    Local $idPreview = GUICtrlCreateLabel($sPreview, $iX + 48, $iY + 82, $iW - 70, 28, BitOR($SS_CENTERIMAGE, $SS_NOPREFIX))
    GUICtrlSetFont($idPreview, 10, $FW_NORMAL, 0, "Microsoft YaHei UI")
    GUICtrlSetColor($idPreview, $COLOR_MUTED)
    GUICtrlSetBkColor($idPreview, $GUI_BKCOLOR_TRANSPARENT)
    _RegisterPageControl($iPanel, $iPage, $idPreview)
    
    ; 按钮
    Local $idButton = GUICtrlCreateLabel("复 制", $iX + $iW - 182, $iY + 39, 160, 38, BitOR($SS_CENTER, $SS_CENTERIMAGE, $SS_NOTIFY))
    GUICtrlSetFont($idButton, 11, $FW_BOLD, 0, "Microsoft YaHei UI")
    GUICtrlSetColor($idButton, $COLOR_CARD)
    GUICtrlSetBkColor($idButton, $GUI_BKCOLOR_TRANSPARENT)
    _RegisterPageControl($iPanel, $iPage, $idButton)
    
    ; 存储按钮信息
    $g_iButtonCount += 1
    ReDim $g_aButtons[$g_iButtonCount]
    ReDim $g_aTemplates[$g_iButtonCount]
    ReDim $g_aButtonPanels[$g_iButtonCount]
    ReDim $g_aButtonCards[$g_iButtonCount]
    $g_aButtons[$g_iButtonCount - 1] = $idButton
    $g_aTemplates[$g_iButtonCount - 1] = $sTemplate
    $g_aButtonPanels[$g_iButtonCount - 1] = $iPanel
    $g_aButtonCards[$g_iButtonCount - 1] = $iCard
EndFunc

Func _RegisterPageControl($iPanel, $iPage, $idControl)
    Local $iIndex
    If $iPanel = $PANEL_MOVIE Then
        $iIndex = $g_aMoviePageCounts[$iPage]
        $g_aMoviePageCtrls[$iPage][$iIndex] = $idControl
        $g_aMoviePageCounts[$iPage] += 1
    Else
        $iIndex = $g_aTvPageCounts[$iPage]
        $g_aTvPageCtrls[$iPage][$iIndex] = $idControl
        $g_aTvPageCounts[$iPage] += 1
    EndIf
EndFunc

Func _ShowPage($iPanel, $iPage)
    Local $i, $j, $iState
    _ResetCopyState()
    
    If $iPanel = $PANEL_MOVIE Then
        For $i = 0 To 4
            $iState = $GUI_HIDE
            If $i = $iPage Then $iState = $GUI_SHOW
            For $j = 0 To $g_aMoviePageCounts[$i] - 1
                GUICtrlSetState($g_aMoviePageCtrls[$i][$j], $iState)
            Next
            GUICtrlSetColor($g_aMovieTabs[$i], $COLOR_MUTED)
            GUICtrlSetFont($g_aMovieTabs[$i], 11, $FW_NORMAL, 0, "Microsoft YaHei UI")
        Next
        $g_iMoviePage = $iPage
        GUICtrlSetColor($g_aMovieTabs[$iPage], $COLOR_PRIMARY)
        GUICtrlSetFont($g_aMovieTabs[$iPage], 11, $FW_BOLD, 0, "Microsoft YaHei UI")
        _RenderPanel($PANEL_MOVIE, $iPage, -1)
    Else
        For $i = 0 To 2
            $iState = $GUI_HIDE
            If $i = $iPage Then $iState = $GUI_SHOW
            For $j = 0 To $g_aTvPageCounts[$i] - 1
                GUICtrlSetState($g_aTvPageCtrls[$i][$j], $iState)
            Next
            GUICtrlSetColor($g_aTvTabs[$i], $COLOR_MUTED)
            GUICtrlSetFont($g_aTvTabs[$i], 11, $FW_NORMAL, 0, "Microsoft YaHei UI")
        Next
        $g_iTvPage = $iPage
        GUICtrlSetColor($g_aTvTabs[$iPage], $COLOR_PRIMARY)
        GUICtrlSetFont($g_aTvTabs[$iPage], 11, $FW_BOLD, 0, "Microsoft YaHei UI")
        _RenderPanel($PANEL_TV, $iPage, -1)
    EndIf
EndFunc

Func _InitPageVisibility($iPanel, $iPage)
    Local $i, $j, $iState
    If $iPanel = $PANEL_MOVIE Then
        For $i = 0 To 4
            $iState = $GUI_HIDE
            If $i = $iPage Then $iState = $GUI_SHOW
            For $j = 0 To $g_aMoviePageCounts[$i] - 1
                GUICtrlSetState($g_aMoviePageCtrls[$i][$j], $iState)
            Next
            GUICtrlSetColor($g_aMovieTabs[$i], $COLOR_MUTED)
        Next
        GUICtrlSetColor($g_aMovieTabs[$iPage], $COLOR_PRIMARY)
        GUICtrlSetFont($g_aMovieTabs[$iPage], 11, $FW_BOLD, 0, "Microsoft YaHei UI")
    Else
        For $i = 0 To 2
            $iState = $GUI_HIDE
            If $i = $iPage Then $iState = $GUI_SHOW
            For $j = 0 To $g_aTvPageCounts[$i] - 1
                GUICtrlSetState($g_aTvPageCtrls[$i][$j], $iState)
            Next
            GUICtrlSetColor($g_aTvTabs[$i], $COLOR_MUTED)
        Next
        GUICtrlSetColor($g_aTvTabs[$iPage], $COLOR_PRIMARY)
        GUICtrlSetFont($g_aTvTabs[$iPage], 11, $FW_BOLD, 0, "Microsoft YaHei UI")
    EndIf
EndFunc

Func _Tool3_HandleClick($nMsg)
    If $nMsg = 0 Then Return
    
    Local $i
    For $i = 0 To 4
        If $nMsg = $g_aMovieTabs[$i] Then
            _ShowPage($PANEL_MOVIE, $i)
            Return
        EndIf
    Next
    
    For $i = 0 To 2
        If $nMsg = $g_aTvTabs[$i] Then
            _ShowPage($PANEL_TV, $i)
            Return
        EndIf
    Next
    
    For $i = 0 To $g_iButtonCount - 1
        If $nMsg = $g_aButtons[$i] Then
            _ResetCopyState()
            ClipPut($g_aTemplates[$i])
            $g_iCopiedButton = $g_aButtons[$i]
            $g_iCopiedPanel = $g_aButtonPanels[$i]
            $g_iCopiedCard = $g_aButtonCards[$i]
            GUICtrlSetData($g_iCopiedButton, "已复制")
            $g_hCopyTimer = TimerInit()
            
            If $g_iCopiedPanel = $PANEL_MOVIE Then
                _RenderPanel($PANEL_MOVIE, $g_iMoviePage, $g_iCopiedCard)
            Else
                _RenderPanel($PANEL_TV, $g_iTvPage, $g_iCopiedCard)
            EndIf
            
            GUICtrlSetData($g_idToast, "模板已复制到剪贴板")
            GUICtrlSetState($g_idToast, $GUI_SHOW)
            $g_hToastTimer = TimerInit()
            Return
        EndIf
    Next
EndFunc   ;==>_Tool3_HandleClick

Func _ResetCopyState()
    If $g_iCopiedButton = 0 Then Return
    Local $iOldPanel = $g_iCopiedPanel
    GUICtrlSetData($g_iCopiedButton, "复 制")
    $g_iCopiedButton = 0
    $g_iCopiedPanel = -1
    $g_iCopiedCard = -1
    If $iOldPanel = $PANEL_MOVIE Then
        _RenderPanel($PANEL_MOVIE, $g_iMoviePage, -1)
    ElseIf $iOldPanel = $PANEL_TV Then
        _RenderPanel($PANEL_TV, $g_iTvPage, -1)
    EndIf
EndFunc

Func _UpdateTransientState()
    If $g_iCopiedButton <> 0 And TimerDiff($g_hCopyTimer) > 1800 Then
        _ResetCopyState()
    EndIf
    If $g_hToastTimer <> 0 And TimerDiff($g_hToastTimer) > 2000 Then
        GUICtrlSetState($g_idToast, $GUI_HIDE)
        $g_hToastTimer = 0
    EndIf
EndFunc

Func _RenderPanel($iPanel, $iActiveTab, $iSuccessCard)
    Local $iCardCount = 2
    Local $iTabCount = 5
    Local $iTabWidth = 135
    Local $iTabGap = 5
    
    If $iPanel = $PANEL_TV Then
        $iCardCount = 3
        If $iActiveTab = 0 Then $iCardCount = 4
        $iTabCount = 3
        $iTabWidth = 225
        $iTabGap = 15
    EndIf
    
    ; 创建画布
    Local $hBitmap = _GDIPlus_BitmapCreateFromScan0(750, 650)
    Local $hGraphics = _GDIPlus_ImageGetGraphicsContext($hBitmap)
    _GDIPlus_GraphicsSetSmoothingMode($hGraphics, $GDIP_SMOOTHINGMODE_HIGHQUALITY)
    _GDIPlus_GraphicsClear($hGraphics, _Argb($COLOR_CARD))
    
    ; 绘制背景卡片
    _FillRoundRect($hGraphics, 0, 0, 749, 649, 10, $COLOR_CARD, $COLOR_BORDER)
    
    ; 绘制标签栏背景
    _FillRoundRect($hGraphics, 15, 10, 720, 45, 10, $COLOR_TABBAR)
    
    ; 绘制激活标签背景
    Local $iActiveX = 22 + ($iActiveTab * ($iTabWidth + $iTabGap))
    _FillRoundRect($hGraphics, $iActiveX, 12, $iTabWidth, 40, 9, $COLOR_CARD, $COLOR_BORDER)
    
    ; 绘制每个卡片
    Local $i, $iY, $iButtonColor
    For $i = 0 To $iCardCount - 1
        $iY = 72 + ($i * 145) ; 调整Y坐标以适应新高度
        
        ; 卡片阴影
        _FillRoundRect($hGraphics, 15, $iY + 4, 718, 130, 10, 0xE9ECF2)
        
        ; 卡片背景
        _FillRoundRect($hGraphics, 15, $iY, 720, 130, 10, $COLOR_CARD, $COLOR_BORDER)
        
        ; 模板文本框背景（美化：增加圆角和渐变效果）
        _FillRoundRect($hGraphics, 32, $iY + 39, 505, 40, 8, $COLOR_SURFACE, $COLOR_BORDER)
        
        ; 预览框背景（新增：美观的预览背景）
        _FillRoundRect($hGraphics, 32, $iY + 82, 680, 32, 6, $COLOR_PREVIEW_BG, $COLOR_PREVIEW_BORDER)
        
        ; 按钮
        $iButtonColor = $COLOR_PRIMARY
        If $i = $iSuccessCard Then $iButtonColor = $COLOR_SUCCESS
        _FillRoundRect($hGraphics, 552, $iY + 39, 160, 38, 9, $iButtonColor)
        

    Next
    
    _GDIPlus_GraphicsDispose($hGraphics)
    
    Local $hHBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hBitmap, _Argb($COLOR_CARD))
    _GDIPlus_BitmapDispose($hBitmap)
    
    Local $hOld
    If $iPanel = $PANEL_MOVIE Then
        $hOld = GUICtrlSendMsg($g_idMoviePicture, $STM_SETIMAGE, $IMAGE_BITMAP, $hHBitmap)
        If $hOld <> 0 Then _WinAPI_DeleteObject($hOld)
        $g_hMovieBitmap = $hHBitmap
        _BringPanelControlsToFront($PANEL_MOVIE, $iActiveTab)
    Else
        $hOld = GUICtrlSendMsg($g_idTvPicture, $STM_SETIMAGE, $IMAGE_BITMAP, $hHBitmap)
        If $hOld <> 0 Then _WinAPI_DeleteObject($hOld)
        $g_hTvBitmap = $hHBitmap
        _BringPanelControlsToFront($PANEL_TV, $iActiveTab)
    EndIf
EndFunc

Func _BringPanelControlsToFront($iPanel, $iActiveTab)
    Local $i, $j, $hControl
    
    If $iPanel = $PANEL_MOVIE Then
        For $i = 0 To 4
            If $i = $iActiveTab Then
                For $j = 0 To $g_aMoviePageCounts[$i] - 1
                    $hControl = GUICtrlGetHandle($g_aMoviePageCtrls[$i][$j])
                    If $hControl <> 0 Then
                        _WinAPI_SetWindowPos($hControl, $HWND_TOP, 0, 0, 0, 0, BitOR($SWP_NOSIZE, $SWP_NOMOVE, $SWP_NOACTIVATE))
                    EndIf
                Next
            EndIf
        Next
        For $i = 0 To 4
            $hControl = GUICtrlGetHandle($g_aMovieTabs[$i])
            If $hControl <> 0 Then
                _WinAPI_SetWindowPos($hControl, $HWND_TOP, 0, 0, 0, 0, BitOR($SWP_NOSIZE, $SWP_NOMOVE, $SWP_NOACTIVATE))
            EndIf
        Next
    Else
        For $i = 0 To 2
            If $i = $iActiveTab Then
                For $j = 0 To $g_aTvPageCounts[$i] - 1
                    $hControl = GUICtrlGetHandle($g_aTvPageCtrls[$i][$j])
                    If $hControl <> 0 Then
                        _WinAPI_SetWindowPos($hControl, $HWND_TOP, 0, 0, 0, 0, BitOR($SWP_NOSIZE, $SWP_NOMOVE, $SWP_NOACTIVATE))
                    EndIf
                Next
            EndIf
        Next
        For $i = 0 To 2
            $hControl = GUICtrlGetHandle($g_aTvTabs[$i])
            If $hControl <> 0 Then
                _WinAPI_SetWindowPos($hControl, $HWND_TOP, 0, 0, 0, 0, BitOR($SWP_NOSIZE, $SWP_NOMOVE, $SWP_NOACTIVATE))
            EndIf
        Next
    EndIf
EndFunc

Func _FillRoundRect($hGraphics, $iX, $iY, $iW, $iH, $iRadius, $iFillColor, $iBorderColor = -1)
    Local $iDiameter = $iRadius * 2
    Local $hPath = _GDIPlus_PathCreate()
    
    _GDIPlus_PathAddArc($hPath, $iX, $iY, $iDiameter, $iDiameter, 180, 90)
    _GDIPlus_PathAddArc($hPath, $iX + $iW - $iDiameter, $iY, $iDiameter, $iDiameter, 270, 90)
    _GDIPlus_PathAddArc($hPath, $iX + $iW - $iDiameter, $iY + $iH - $iDiameter, $iDiameter, $iDiameter, 0, 90)
    _GDIPlus_PathAddArc($hPath, $iX, $iY + $iH - $iDiameter, $iDiameter, $iDiameter, 90, 90)
    _GDIPlus_PathCloseFigure($hPath)
    
    Local $hBrush = _GDIPlus_BrushCreateSolid(_Argb($iFillColor))
    _GDIPlus_GraphicsFillPath($hGraphics, $hPath, $hBrush)
    _GDIPlus_BrushDispose($hBrush)
    
    If $iBorderColor >= 0 Then
        Local $hPen = _GDIPlus_PenCreate(_Argb($iBorderColor), 1)
        _GDIPlus_GraphicsDrawPath($hGraphics, $hPath, $hPen)
        _GDIPlus_PenDispose($hPen)
    EndIf
    
    _GDIPlus_PathDispose($hPath)
EndFunc

Func _Argb($iColor)
    Return BitOR(0xFF000000, $iColor)
EndFunc

Func _DisposePanelBitmap($idPicture, ByRef $hBitmap)
    If $hBitmap = 0 Then Return
    GUICtrlSendMsg($idPicture, $STM_SETIMAGE, $IMAGE_BITMAP, 0)
    _WinAPI_DeleteObject($hBitmap)
    $hBitmap = 0
EndFunc
#EndRegion ;**** 工具3：媒体命名模板速查 (tools-3) ****


#Region ;**** 工具4：在线中文字幕搜索下载 (tool-4, integrated from standalone v1.9) ****
; 本模块的全局变量统一使用 $T4_ 前缀，函数统一使用 Tool4_ 前缀，
; 与工具1-3隔离。工具4通过启动器的 /tool4 参数独立启动。
; 数据源：SubtitleCat.com + 迅雷字幕接口；不依赖 PotPlayer。

; ============================================================================
; SubtitleSearch AutoIt 独立版 v1.9
; 数据源：SubtitleCat.com + 迅雷字幕接口
; 不依赖 PotPlayer，不需要第三方 AutoIt UDF；使用 Windows 自带 WinHTTP / ADODB COM。
; ============================================================================

Global Const $T4_SITE_URL = "https://www.subtitlecat.com"
Global Const $T4_XUNLEI_API_URL = "https://api-shoulei-ssl.xunlei.com/oracle/subtitle"
Global Const $T4_APP_TITLE = "在线中文字幕搜索 - SubtitleCat + 迅雷"
Global Const $T4_APP_VERSION = "1.9"

Global $T4_g_hGUI = 0
Global $T4_g_idTitle = 0
Global $T4_g_idBrowseVideo = 0
Global $T4_g_idSearch = 0
Global $T4_g_idBatchFolder = 0
Global $T4_g_idBrowseBatchFolder = 0
Global $T4_g_idBatchSearch = 0
Global $T4_g_idBatchDownload = 0
Global $T4_g_idBatchStop = 0
Global $T4_g_idClear = 0
Global $T4_g_idUseCat = 0
Global $T4_g_idUseXunlei = 0
Global $T4_g_idCatSearchCount = 0
Global $T4_g_idXunleiSearchCount = 0
Global $T4_g_idProgress = 0
Global $T4_g_idList = 0
Global $T4_g_hList = 0
Global $T4_g_idSaveDir = 0
Global $T4_g_idBrowseDir = 0
Global $T4_g_idDownload = 0
Global $T4_g_idOpenDir = 0
Global $T4_g_idOpenPage = 0
Global $T4_g_idStatus = 0
Global $T4_g_sCurrentVideoPath = ""
Global $T4_g_iCurrentVideoFirstResult = 0 ; 当前视频在结果数组中的起始位置，用于局部去重
Global $T4_g_aResults[0][10] ; title, source, lang, format, URL/detail ID, filename, related video path, direct file URL, file size bytes, downloaded flag
Global $T4_g_iResultCount = 0
Global $T4_g_iResultCapacity = 0
Global $T4_g_iListViewRows = 0
Global $T4_g_aListRowResultIndex[0] ; visible ListView row index -> $T4_g_aResults index
Global $T4_g_iListRowMapCount = 0
Global $T4_g_iListRowMapCapacity = 0
Global $T4_g_iBatchHiddenResultCount = 0
Global $T4_g_aBatchVideos[0][3] ; path, first result index, result count
Global $T4_g_iBatchVideoCount = 0
Global $T4_g_bBatchSearchComplete = False
Global Const $T4_BATCH_LISTVIEW_LIMIT = 1200
Global $T4_g_bBatchRunning = False
Global $T4_g_bCancelBatch = False
Global $T4_g_bCloseRequested = False
Global $T4_g_iScanFileCount = 0
Global $T4_g_iScanFileCapacity = 0
Global $T4_g_sLastError = ""
Global $T4_g_oComErrorHandler = 0
Func Tool4_Main()
    $T4_g_oComErrorHandler = ObjEvent("AutoIt.Error", "Tool4_ComErrorHandler")

    $T4_g_hGUI = GUICreate($T4_APP_TITLE & " v" & $T4_APP_VERSION, 1366, 768, -1, -1, BitOR($GUI_SS_DEFAULT_GUI, $WS_MINIMIZEBOX))
    GUISetFont(11, 400, 0, "Microsoft YaHei UI", $T4_g_hGUI)

    GUICtrlCreateLabel("单个视频 / 手动搜索标题", 25, 10, 301, 24)
    $T4_g_idTitle = GUICtrlCreateInput("", 25, 37, 467, 31)
    $T4_g_idBrowseVideo = GUICtrlCreateButton("选择视频...", 500, 37, 109, 31)
    GUICtrlSetTip($T4_g_idBrowseVideo, "JAV 番号自动识别：ABCD-123 / ABC-123；支持 MP4、MOV、MKV 等格式。")
    $T4_g_idSearch = GUICtrlCreateButton("搜索字幕", 617, 37, 109, 31, $BS_DEFPUSHBUTTON)
    GUICtrlSetFont($T4_g_idSearch, 11, $FW_BOLD, 0, "Microsoft YaHei UI")

    GUICtrlCreateLabel("批量视频目录（自动包含所有子文件夹）", 25, 76, 410, 24)
    $T4_g_idBatchFolder = GUICtrlCreateInput("", 25, 103, 467, 31)
    $T4_g_idBrowseBatchFolder = GUICtrlCreateButton("选择目录...", 500, 103, 109, 31)
    GUICtrlSetTip($T4_g_idBrowseBatchFolder, "JAV 番号自动识别：ABCD-123 / ABC-123；支持 MP4、MOV、MKV 等格式。")
    $T4_g_idBatchSearch = GUICtrlCreateButton("批量搜索", 617, 103, 109, 31)
    $T4_g_idBatchDownload = GUICtrlCreateButton("批量下载", 734, 103, 109, 31)
    $T4_g_idBatchStop = GUICtrlCreateButton("停止批量", 851, 103, 109, 31)
    GUICtrlSetState($T4_g_idBatchDownload, $GUI_DISABLE)
    GUICtrlSetState($T4_g_idBatchStop, $GUI_HIDE)

    $T4_g_idUseCat = GUICtrlCreateCheckbox("SubtitleCat", 969, 26, 118, 24)
    $T4_g_idUseXunlei = GUICtrlCreateCheckbox("迅雷字幕", 969, 58, 118, 24)
    GUICtrlSetFont($T4_g_idUseCat, 10, 400, 0, "Microsoft YaHei UI")
    GUICtrlSetFont($T4_g_idUseXunlei, 10, 400, 0, "Microsoft YaHei UI")
    GUICtrlSetState($T4_g_idUseCat, $GUI_CHECKED)
    GUICtrlSetState($T4_g_idUseXunlei, $GUI_CHECKED)

    GUICtrlCreateLabel("SubtitleCat 搜索数量", 1095, 28, 170, 22)
    GUICtrlSetFont(-1, 10, 400, 0, "Microsoft YaHei UI")
    $T4_g_idCatSearchCount = GUICtrlCreateCombo("", 1273, 25, 54, 27, $CBS_DROPDOWNLIST)
    GUICtrlSetData($T4_g_idCatSearchCount, "1|2|3|4|5|6|7|8|9|10", "5")
    GUICtrlSetFont($T4_g_idCatSearchCount, 10, 400, 0, "Microsoft YaHei UI")
    GUICtrlCreateLabel("迅雷搜索数量", 1095, 60, 170, 22)
    GUICtrlSetFont(-1, 10, 400, 0, "Microsoft YaHei UI")
    $T4_g_idXunleiSearchCount = GUICtrlCreateCombo("", 1273, 57, 54, 27, $CBS_DROPDOWNLIST)
    GUICtrlSetData($T4_g_idXunleiSearchCount, "1|2|3|4|5|6|7|8|9|10", "5")
    GUICtrlSetFont($T4_g_idXunleiSearchCount, 10, 400, 0, "Microsoft YaHei UI")
    ; ---- 设置区边框：实线 1px，上边框在标题处断开，做成带小标题的面板 ----
    Local $aT4Box[5]
    $aT4Box[0] = GUICtrlCreateLabel("", 957, 13, 8, 1)      ; 上边框（标题左）
    $aT4Box[1] = GUICtrlCreateLabel("", 1045, 13, 294, 1)   ; 上边框（标题右）
    $aT4Box[2] = GUICtrlCreateLabel("", 957, 95, 383, 1)    ; 下边框
    $aT4Box[3] = GUICtrlCreateLabel("", 957, 13, 1, 83)     ; 左边框
    $aT4Box[4] = GUICtrlCreateLabel("", 1339, 13, 1, 83)    ; 右边框
    For $iT4Box = 0 To 4
        GUICtrlSetBkColor($aT4Box[$iT4Box], 0x909090)
        GUICtrlSetState($aT4Box[$iT4Box], $GUI_DISABLE)
    Next

    ; 小标题压在上边框的断口里（透明底，不需要跟窗口底色对齐）
    Local $idT4BoxTitle = GUICtrlCreateLabel("搜索设置", 965, 2, 76, 20)
    GUICtrlSetFont($idT4BoxTitle, 10, $FW_BOLD, 0, "Microsoft YaHei UI")
    GUICtrlSetColor($idT4BoxTitle, 0x6A6A6A)
    GUICtrlSetBkColor($idT4BoxTitle, $GUI_BKCOLOR_TRANSPARENT)

    GUICtrlCreateLabel("搜索结果（批量搜索后可执行批量下载；也可按 Ctrl / Shift 多选手动下载）", 25, 148, 848, 24)
    GUICtrlSetFont(-1, 11, $FW_BOLD, 0, "Microsoft YaHei UI")
    $T4_g_idList = GUICtrlCreateListView("关联视频|字幕名称|来源|语言|格式|文件大小", 25, 175, 1318, 415, BitOR($LVS_REPORT, $LVS_SHOWSELALWAYS))
    $T4_g_hList = GUICtrlGetHandle($T4_g_idList)
    GUICtrlSetFont($T4_g_idList, 10, 400, 0, "Microsoft YaHei UI")
    _GUICtrlListView_SetExtendedListViewStyle($T4_g_hList, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
    _GUICtrlListView_SetColumnWidth($T4_g_hList, 0, 260)
    _GUICtrlListView_SetColumnWidth($T4_g_hList, 1, 520)
    _GUICtrlListView_SetColumnWidth($T4_g_hList, 2, 130)
    _GUICtrlListView_SetColumnWidth($T4_g_hList, 3, 140)
    _GUICtrlListView_SetColumnWidth($T4_g_hList, 4, 80)
    _GUICtrlListView_SetColumnWidth($T4_g_hList, 5, 165)

    GUICtrlCreateLabel("字幕保存目录", 25, 600, 137, 24)
    $T4_g_idSaveDir = GUICtrlCreateInput(@ScriptDir & "\Subtitles", 25, 626, 467, 30)
    $T4_g_idBrowseDir = GUICtrlCreateButton("选择目录...", 500, 626, 109, 30)
    $T4_g_idOpenDir = GUICtrlCreateButton("打开目录", 617, 626, 109, 30)

    $T4_g_idDownload = GUICtrlCreateButton("下载所选字幕", 25, 671, 144, 35, $BS_DEFPUSHBUTTON)
    GUICtrlSetFont($T4_g_idDownload, 11, $FW_BOLD, 0, "Microsoft YaHei UI")
    $T4_g_idOpenPage = GUICtrlCreateButton("打开字幕来源页面", 177, 671, 176, 35)
    $T4_g_idClear = GUICtrlCreateButton("清空结果", 361, 671, 109, 35)
    $T4_g_idStatus = GUICtrlCreateLabel("就绪。可搜索单个视频，或先批量搜索目录，再单独执行批量下载。", 478, 671, 865, 44, $SS_LEFT)
    GUICtrlCreateLabel("进度", 25, 726, 48, 24)
    $T4_g_idProgress = GUICtrlCreateProgress(89, 728, 1254, 18)
    GUICtrlSetData($T4_g_idProgress, 0)

    GUISetState(@SW_SHOW, $T4_g_hGUI)

    While 1
        Local $iMsg = GUIGetMsg()
        Switch $iMsg
            Case $GUI_EVENT_CLOSE
                If $T4_g_bBatchRunning Then
                    $T4_g_bCancelBatch = True
                    $T4_g_bCloseRequested = True
                    Tool4_SetStatus("正在停止批量任务并关闭窗口...")
                Else
                    ExitLoop
                EndIf
            Case $T4_g_idBrowseVideo
                Tool4_BrowseVideo()
            Case $T4_g_idSearch
                Tool4_DoSearch()
            Case $T4_g_idBrowseBatchFolder
                Tool4_BrowseBatchFolder()
            Case $T4_g_idBatchSearch
                Tool4_BatchSearch()
            Case $T4_g_idBatchDownload
                Tool4_BatchDownload()
            Case $T4_g_idBatchStop
                $T4_g_bCancelBatch = True
                Tool4_SetStatus("正在停止批量任务，请等待当前请求取消...")
            Case $T4_g_idBrowseDir
                Tool4_BrowseSaveDir()
            Case $T4_g_idDownload
                Tool4_DownloadSelected()
            Case $T4_g_idOpenDir
                Tool4_OpenSaveDir()
            Case $T4_g_idOpenPage
                Tool4_OpenSelectedPage()
            Case $T4_g_idClear
                Tool4_ClearResults()
        EndSwitch
        If $T4_g_bCloseRequested Then ExitLoop
    WEnd

    GUIDelete($T4_g_hGUI)
EndFunc

Func Tool4_ComErrorHandler($oError)
    $T4_g_sLastError = "COM 错误：" & Hex($oError.number, 8) & " - " & $oError.windescription
    Return
EndFunc

; ------------------------------- GUI 操作 -----------------------------------

Func Tool4_BrowseVideo()
    Local $sPath = FileOpenDialog("选择视频文件", @ScriptDir, Tool4_VideoFileFilter(), 1)
    If @error Or $sPath = "" Then Return

    Local $sName = Tool4_GetFileName($sPath)
    $T4_g_sCurrentVideoPath = $sPath
    GUICtrlSetData($T4_g_idTitle, Tool4_BuildSearchTitle($sPath))
    Tool4_SetStatus("已载入文件名：" & $sName)
EndFunc

Func Tool4_BrowseBatchFolder()
    Local $sDir = FileSelectFolder("选择需要批量搜索的视频目录（包含子文件夹）", "", 1, GUICtrlRead($T4_g_idBatchFolder))
    If @error Or $sDir = "" Then Return
    GUICtrlSetData($T4_g_idBatchFolder, $sDir)
    Tool4_SetStatus("已选择批量目录：" & $sDir)
EndFunc

Func Tool4_BrowseSaveDir()
    Local $sDir = FileSelectFolder("选择字幕保存目录", "", 1, GUICtrlRead($T4_g_idSaveDir))
    If @error Or $sDir = "" Then Return
    GUICtrlSetData($T4_g_idSaveDir, $sDir)
EndFunc

Func Tool4_OpenSaveDir()
    Local $sDir = StringStripWS(GUICtrlRead($T4_g_idSaveDir), 3)
    If $sDir = "" Then Return
    If Not FileExists($sDir) Then DirCreate($sDir)
    If FileExists($sDir) Then ShellExecute($sDir)
EndFunc

Func Tool4_OpenSelectedPage()
    Local $aSelectedRows = _GUICtrlListView_GetSelectedIndices($T4_g_idList, True)
    If Not IsArray($aSelectedRows) Then
        MsgBox($MB_ICONWARNING, $T4_APP_TITLE, "无法读取列表选择状态，请重新选择字幕。")
        Return
    EndIf
    If $aSelectedRows[0] <= 0 Then
        MsgBox($MB_ICONINFORMATION, $T4_APP_TITLE, "请先选择一条字幕结果。")
        Return
    EndIf
    Local $iIndex = Tool4_GetResultIndexForListRow($aSelectedRows[1])
    If $iIndex < 0 Then
        MsgBox($MB_ICONWARNING, $T4_APP_TITLE, "所选列表行无法关联到字幕搜索结果。")
        Return
    EndIf

    Local $sURL = $T4_g_aResults[$iIndex][4]
    If StringLeft($sURL, 7) = "http://" Or StringLeft($sURL, 8) = "https://" Then
        ShellExecute($sURL)
    Else
        ShellExecute($T4_SITE_URL & "/" & $sURL)
    EndIf
EndFunc

Func Tool4_ClearResults()
    _GUICtrlListView_DeleteAllItems($T4_g_hList)
    ReDim $T4_g_aResults[0][10]
    $T4_g_iResultCount = 0
    $T4_g_iResultCapacity = 0
    $T4_g_iCurrentVideoFirstResult = 0
    $T4_g_iListViewRows = 0
    ReDim $T4_g_aListRowResultIndex[0]
    $T4_g_iListRowMapCount = 0
    $T4_g_iListRowMapCapacity = 0
    ReDim $T4_g_aBatchVideos[0][3]
    $T4_g_iBatchVideoCount = 0
    $T4_g_bBatchSearchComplete = False
    $T4_g_iBatchHiddenResultCount = 0
    If $T4_g_idProgress <> 0 Then GUICtrlSetData($T4_g_idProgress, 0)
    If $T4_g_idBatchDownload <> 0 Then GUICtrlSetState($T4_g_idBatchDownload, $GUI_DISABLE)
    Tool4_SetStatus("已清空搜索结果。")
EndFunc

Func Tool4_SetStatus($sText)
    GUICtrlSetData($T4_g_idStatus, $sText)
    Local $hStatus = GUICtrlGetHandle($T4_g_idStatus)
    If $hStatus <> 0 Then DllCall("user32.dll", "bool", "UpdateWindow", "hwnd", $hStatus)
EndFunc

Func Tool4_UpdateProgress($iCurrent, $iTotal)
    Local $iPercent = 0
    If $iTotal > 0 Then $iPercent = Int(($iCurrent * 100) / $iTotal)
    If $iPercent < 0 Then $iPercent = 0
    If $iPercent > 100 Then $iPercent = 100
    If $T4_g_idProgress <> 0 Then GUICtrlSetData($T4_g_idProgress, $iPercent)
    Return $iPercent
EndFunc

Func Tool4_VideoFileFilter()
    Return "视频文件 (*.mp4;*.mkv;*.avi;*.wmv;*.flv;*.webm;*.mov;*.ts;*.m2ts;*.rmvb;*.mpg;*.mpeg;*.divx;*.3gp;*.vob;*.asf;*.m4v;*.rm;*.ogm;*.ogv)|所有文件 (*.*)"
EndFunc

; --------------------------------- 搜索 -------------------------------------

Func Tool4_DoSearch()
    $T4_g_bCancelBatch = False
    Local $sRawTitle = StringStripWS(GUICtrlRead($T4_g_idTitle), 3)
    If $sRawTitle = "" Then
        MsgBox($MB_ICONWARNING, $T4_APP_TITLE, "请先选择视频文件或输入影片标题。")
        Return
    EndIf

    Local $bUseCat = (BitAND(GUICtrlRead($T4_g_idUseCat), $GUI_CHECKED) = $GUI_CHECKED)
    Local $bUseXunlei = (BitAND(GUICtrlRead($T4_g_idUseXunlei), $GUI_CHECKED) = $GUI_CHECKED)
    If Not $bUseCat And Not $bUseXunlei Then
        MsgBox($MB_ICONWARNING, $T4_APP_TITLE, "请至少勾选一个字幕来源。")
        Return
    EndIf

    Local $sTitle = Tool4_BuildSearchTitle($sRawTitle)
    If $sTitle = "" Then
        MsgBox($MB_ICONWARNING, $T4_APP_TITLE, "无法从输入内容中识别有效标题。")
        Return
    EndIf

    Local $iCatSearchCount = Int(GUICtrlRead($T4_g_idCatSearchCount))
    Local $iXunleiSearchCount = Int(GUICtrlRead($T4_g_idXunleiSearchCount))
    If $iCatSearchCount < 1 Or $iCatSearchCount > 10 Then $iCatSearchCount = 5
    If $iXunleiSearchCount < 1 Or $iXunleiSearchCount > 10 Then $iXunleiSearchCount = 5

    Tool4_ClearResults()
    $T4_g_iCurrentVideoFirstResult = 0
    Tool4_SetStatus("正在搜索：" & $sTitle & "；SubtitleCat " & $iCatSearchCount & " 条 / 迅雷 " & $iXunleiSearchCount & " 条")

    Local $iCatCount = 0
    Local $iXunleiCount = 0
    If $bUseCat Then $iCatCount = Tool4_SearchSubtitleCat($sTitle, $iCatSearchCount)
    If Not $T4_g_bCloseRequested And Not $T4_g_bCancelBatch And $bUseXunlei Then $iXunleiCount = Tool4_SearchXunlei($sTitle, $iXunleiSearchCount)
    If $T4_g_bCloseRequested Then Return

    Local $iTotal = $T4_g_iResultCount
    If $iTotal = 0 Then
        Tool4_SetStatus("搜索完成：没有找到符合条件的简体中文字幕。")
        MsgBox($MB_ICONINFORMATION, $T4_APP_TITLE, "没有找到简体中文字幕。" & @CRLF & @CRLF & Tool4_SourceSummary($bUseCat, $iCatCount, $bUseXunlei, $iXunleiCount))
    Else
        Tool4_SetStatus("搜索完成：共找到 " & $iTotal & " 条字幕（SubtitleCat " & $iCatCount & "/" & $iCatSearchCount & "；迅雷 " & $iXunleiCount & "/" & $iXunleiSearchCount & "）。")
    EndIf
EndFunc


; ------------------------------ 批量扫描处理 ---------------------------------

Func Tool4_BatchSearch()
    Local $sFolder = StringStripWS(GUICtrlRead($T4_g_idBatchFolder), 3)
    If $sFolder = "" Or Not FileExists($sFolder) Then
        MsgBox($MB_ICONWARNING, $T4_APP_TITLE, "请先选择一个有效的视频目录。")
        Return
    EndIf

    Local $bUseCat = (BitAND(GUICtrlRead($T4_g_idUseCat), $GUI_CHECKED) = $GUI_CHECKED)
    Local $bUseXunlei = (BitAND(GUICtrlRead($T4_g_idUseXunlei), $GUI_CHECKED) = $GUI_CHECKED)
    If Not $bUseCat And Not $bUseXunlei Then
        MsgBox($MB_ICONWARNING, $T4_APP_TITLE, "请至少勾选一个字幕来源。")
        Return
    EndIf
    Local $iCatSearchCount = Int(GUICtrlRead($T4_g_idCatSearchCount))
    Local $iXunleiSearchCount = Int(GUICtrlRead($T4_g_idXunleiSearchCount))
    If $iCatSearchCount < 1 Or $iCatSearchCount > 10 Then $iCatSearchCount = 5
    If $iXunleiSearchCount < 1 Or $iXunleiSearchCount > 10 Then $iXunleiSearchCount = 5

    ; 递归扫描前先锁定界面，扫描期间仍可通过停止按钮中断。
    Local $aFiles[256]
    $T4_g_iScanFileCount = 0
    $T4_g_iScanFileCapacity = 256
    $T4_g_bCancelBatch = False
    GUICtrlSetData($T4_g_idProgress, 0)
    Tool4_SetBatchUIState(True)
    Tool4_SetStatus("正在递归扫描目录：" & $sFolder)
    Tool4_CollectVideoFiles($sFolder, $aFiles)
    If $T4_g_bCancelBatch Or $T4_g_bCloseRequested Then
        Tool4_SetBatchUIState(False)
        Tool4_SetStatus("目录扫描已取消。")
        Return
    EndIf
    If $T4_g_iScanFileCount = 0 Then
        Tool4_SetBatchUIState(False)
        MsgBox($MB_ICONINFORMATION, $T4_APP_TITLE, "所选目录及其子文件夹中没有找到支持的视频文件。")
        Return
    EndIf
    ReDim $aFiles[$T4_g_iScanFileCount]
    Local $iFileCount = $T4_g_iScanFileCount
    Tool4_SetBatchUIState(False)

    Local $iConfirm = MsgBox(BitOR($MB_ICONQUESTION, $MB_YESNO), $T4_APP_TITLE, _
            "扫描到 " & $iFileCount & " 个视频文件。" & @CRLF & @CRLF & _
            "程序将逐个搜索 SubtitleCat 和迅雷字幕库，并保留可用结果。" & @CRLF & _
            "本阶段只搜索，不会下载字幕。搜索完成后可单独点击“批量下载”。" & @CRLF & _
            "本次搜索数量：SubtitleCat " & $iCatSearchCount & " 条 / 视频；迅雷 " & $iXunleiSearchCount & " 条 / 视频。" & @CRLF & _
            "只收录简体中文字幕。" & @CRLF & @CRLF & "是否开始搜索？")
    If $iConfirm <> $IDYES Then Return

    Tool4_ClearResults()
    $T4_g_iBatchHiddenResultCount = 0
    ReDim $T4_g_aBatchVideos[$iFileCount][3]
    $T4_g_iBatchVideoCount = $iFileCount
    $T4_g_bCancelBatch = False
    Tool4_SetBatchUIState(True)

    Local $iFoundVideo = 0
    Local $iNoMatch = 0
    Local $iTotalCat = 0
    Local $iTotalXunlei = 0
    Local $iProcessedVideos = 0

    For $i = 0 To $iFileCount - 1
        If $T4_g_bCancelBatch Then ExitLoop
        $T4_g_sCurrentVideoPath = $aFiles[$i]
        $T4_g_aBatchVideos[$i][0] = $aFiles[$i]
        $T4_g_aBatchVideos[$i][1] = $T4_g_iResultCount
        $T4_g_aBatchVideos[$i][2] = 0
        $T4_g_iCurrentVideoFirstResult = $T4_g_iResultCount

        Local $sTitle = Tool4_BuildSearchTitle($aFiles[$i])
        Tool4_SetStatus("批量搜索 " & ($i + 1) & "/" & $iFileCount & "：" & Tool4_GetFileName($aFiles[$i]) & _
                "；搜索标题：" & $sTitle)

        Local $iCatAdded = 0
        Local $iXunleiAdded = 0
        If $sTitle <> "" Then
            ; 下拉框是单个搜索和批量搜索共用的唯一收录数量上限。
            If $bUseCat Then $iCatAdded = Tool4_SearchSubtitleCat($sTitle, $iCatSearchCount, 3000)
            If Not $T4_g_bCancelBatch And $bUseXunlei Then $iXunleiAdded = Tool4_SearchXunlei($sTitle, $iXunleiSearchCount)
        EndIf

        ; 即使用户在当前视频的第二个数据源请求期间停止，也保留已经收集到的候选。
        Local $iNewResults = $T4_g_iResultCount - $T4_g_aBatchVideos[$i][1]
        $T4_g_aBatchVideos[$i][2] = $iNewResults
        $iProcessedVideos = $i + 1
        Tool4_UpdateProgress($iProcessedVideos, $iFileCount)
        $iTotalCat += $iCatAdded
        $iTotalXunlei += $iXunleiAdded
        If $iNewResults > 0 Then
            $iFoundVideo += 1
        Else
            $iNoMatch += 1
        EndIf

        If Mod($i + 1, 5) = 0 Or $i = $iFileCount - 1 Then
            Tool4_SetStatus("批量搜索进度 " & ($i + 1) & "/" & $iFileCount & "；找到字幕的视频 " & $iFoundVideo & " 个。")
        EndIf
        If $T4_g_bCancelBatch Then ExitLoop
        Sleep(10)
    Next

    Local $bWasCancelled = $T4_g_bCancelBatch
    ; 若取消，未处理视频从队列中移除，仅保留已经完成搜索的记录。
    If $bWasCancelled Then $T4_g_iBatchVideoCount = $iProcessedVideos
    $T4_g_sCurrentVideoPath = ""
    $T4_g_bBatchSearchComplete = True
    Tool4_SetBatchUIState(False)

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
            "搜索结果总数：" & $T4_g_iResultCount & " 条" & @CRLF & _
            "界面显示结果：最多 " & $T4_BATCH_LISTVIEW_LIMIT & " 条；隐藏结果仍会参与批量下载。" & @CRLF & @CRLF & _
            "下一步：检查结果后，点击“批量下载”开始下载。"
    Tool4_SetStatus("批量搜索" & $sBatchState & "：处理 " & $iProcessedVideos & "/" & $iFileCount & _
            " 个视频，找到字幕的视频 " & $iFoundVideo & " 个。")
    If Not $T4_g_bCloseRequested Then MsgBox($MB_ICONINFORMATION, $T4_APP_TITLE, $sSummary)
EndFunc

Func Tool4_BatchDownload()
    If Not $T4_g_bBatchSearchComplete Or $T4_g_iBatchVideoCount <= 0 Then
        MsgBox($MB_ICONINFORMATION, $T4_APP_TITLE, "请先执行“批量搜索”。")
        Return
    EndIf

    Local $sSaveDir = StringStripWS(GUICtrlRead($T4_g_idSaveDir), 3)
    If $sSaveDir = "" Then
        MsgBox($MB_ICONWARNING, $T4_APP_TITLE, "请设置字幕保存目录。")
        Return
    EndIf
    If Not FileExists($sSaveDir) Then DirCreate($sSaveDir)
    If Not FileExists($sSaveDir) Then
        MsgBox($MB_ICONERROR, $T4_APP_TITLE, "无法创建保存目录：" & $sSaveDir)
        Return
    EndIf

    Local $iPending = Tool4_CountPendingBatchDownloads()
    If $iPending <= 0 Then
        MsgBox($MB_ICONINFORMATION, $T4_APP_TITLE, "没有待下载的字幕结果。所有已找到的候选可能都已下载成功。")
        Return
    EndIf
    Local $iConfirm = MsgBox(BitOR($MB_ICONQUESTION, $MB_YESNO), $T4_APP_TITLE, _
            "当前有 " & $iPending & " 条字幕候选尚未下载。" & @CRLF & @CRLF & _
            "批量下载将尝试所有已收录的字幕候选，不再限制每个视频的下载数量。" & @CRLF & _
            "每条候选独立记录下载状态；成功的跳过，失败的可再次重试。" & @CRLF & _
            "保存目录：" & $sSaveDir & @CRLF & @CRLF & "是否开始批量下载？")
    If $iConfirm <> $IDYES Then Return

    $T4_g_bCancelBatch = False
    GUICtrlSetData($T4_g_idProgress, 0)
    Tool4_SetBatchUIState(True)
    Local $iSuccess = 0
    Local $iFailed = 0
    Local $iSkipped = 0
    Local $sFailureList = ""
    Local $iAttempted = 0
    Local $iDownloadProgress = 0

    For $i = 0 To $T4_g_iBatchVideoCount - 1
        If $T4_g_bCancelBatch Then ExitLoop
        If $T4_g_aBatchVideos[$i][2] <= 0 Then ContinueLoop

        Local $sVideoPath = $T4_g_aBatchVideos[$i][0]
        Local $iStartResult = $T4_g_aBatchVideos[$i][1]
        Local $iVideoResultCount = $T4_g_aBatchVideos[$i][2]
        Local $sBaseName = Tool4_GetFileBaseName($sVideoPath)
        $T4_g_sCurrentVideoPath = $sVideoPath

        For $j = $iStartResult To $iStartResult + $iVideoResultCount - 1
            If $T4_g_bCancelBatch Then ExitLoop
            If $T4_g_aResults[$j][9] = 1 Then
                $iSkipped += 1
                ContinueLoop
            EndIf

            Tool4_SetStatus("批量下载 " & ($i + 1) & "/" & $T4_g_iBatchVideoCount & "：" & Tool4_GetFileName($sVideoPath) & _
                    "；字幕候选 " & ($j - $iStartResult + 1) & "/" & $iVideoResultCount)
            Local $sTryError = ""
            If Tool4_DownloadResult($j, $sSaveDir, $sBaseName, True, $sTryError) Then
                $iSuccess += 1
            Else
                $iFailed += 1
                If $iFailed <= 20 Then $sFailureList &= Tool4_GetFileName($sVideoPath) & " / " & $T4_g_aResults[$j][0] & "：" & $sTryError & @CRLF
            EndIf
            $iAttempted += 1
            $iDownloadProgress += 1
            Local $iDownloadPercent = Tool4_UpdateProgress($iDownloadProgress, $iPending)
            Tool4_SetStatus("批量下载进度 " & $iDownloadProgress & "/" & $iPending & "（" & $iDownloadPercent & "%）；成功 " & $iSuccess & " 条，失败 " & $iFailed & " 条。")
            Sleep(10)
        Next
    Next

    Local $bWasCancelled = $T4_g_bCancelBatch
    $T4_g_sCurrentVideoPath = ""
    Tool4_SetBatchUIState(False)
    Local $sBatchState = "完成。"
    If $bWasCancelled Then $sBatchState = "已停止；已成功下载的字幕已记录，再次点击可继续未完成项目。"

    Local $sSummary = "批量下载" & $sBatchState & @CRLF & @CRLF & _
            "本次尝试：" & $iAttempted & " 条" & @CRLF & _
            "本次成功：" & $iSuccess & " 条" & @CRLF & _
            "本次失败：" & $iFailed & " 条" & @CRLF & _
            "此前已下载并跳过：" & $iSkipped & " 条" & @CRLF & _
            "仍待处理：" & Tool4_CountPendingBatchDownloads() & " 条" & @CRLF & @CRLF & _
            "保存目录：" & $sSaveDir
    If $sFailureList <> "" Then $sSummary &= @CRLF & @CRLF & "失败详情（最多显示 20 条，可再次点击批量下载重试）:" & @CRLF & $sFailureList
    Tool4_SetStatus("批量下载" & $sBatchState & "：成功 " & $iSuccess & " 条，失败 " & $iFailed & " 条。")
    If Not $T4_g_bCloseRequested Then MsgBox($MB_ICONINFORMATION, $T4_APP_TITLE, $sSummary)
EndFunc

Func Tool4_CountPendingBatchDownloads()
    Local $iPending = 0
    For $i = 0 To $T4_g_iBatchVideoCount - 1
        Local $iStartResult = $T4_g_aBatchVideos[$i][1]
        Local $iVideoResultCount = $T4_g_aBatchVideos[$i][2]
        For $j = $iStartResult To $iStartResult + $iVideoResultCount - 1
            If $T4_g_aResults[$j][9] <> 1 Then $iPending += 1
        Next
    Next
    Return $iPending
EndFunc

Func Tool4_SetBatchUIState($bRunning)
    $T4_g_bBatchRunning = $bRunning
    If $bRunning Then
        GUICtrlSetState($T4_g_idBatchSearch, $GUI_HIDE)
        GUICtrlSetState($T4_g_idBatchDownload, $GUI_HIDE)
        GUICtrlSetState($T4_g_idBatchStop, $GUI_SHOW)
        GUICtrlSetState($T4_g_idTitle, $GUI_DISABLE)
        GUICtrlSetState($T4_g_idSearch, $GUI_DISABLE)
        GUICtrlSetState($T4_g_idBrowseVideo, $GUI_DISABLE)
        GUICtrlSetState($T4_g_idBatchFolder, $GUI_DISABLE)
        GUICtrlSetState($T4_g_idBrowseBatchFolder, $GUI_DISABLE)
        GUICtrlSetState($T4_g_idSaveDir, $GUI_DISABLE)
        GUICtrlSetState($T4_g_idBrowseDir, $GUI_DISABLE)
        GUICtrlSetState($T4_g_idOpenDir, $GUI_DISABLE)
        GUICtrlSetState($T4_g_idDownload, $GUI_DISABLE)
        GUICtrlSetState($T4_g_idOpenPage, $GUI_DISABLE)
        GUICtrlSetState($T4_g_idClear, $GUI_DISABLE)
        GUICtrlSetState($T4_g_idList, $GUI_DISABLE)
        GUICtrlSetState($T4_g_idUseCat, $GUI_DISABLE)
        GUICtrlSetState($T4_g_idUseXunlei, $GUI_DISABLE)
        GUICtrlSetState($T4_g_idCatSearchCount, $GUI_DISABLE)
        GUICtrlSetState($T4_g_idXunleiSearchCount, $GUI_DISABLE)
    Else
        GUICtrlSetState($T4_g_idBatchStop, $GUI_HIDE)
        GUICtrlSetState($T4_g_idBatchSearch, $GUI_SHOW)
        GUICtrlSetState($T4_g_idBatchDownload, $GUI_SHOW)
        GUICtrlSetState($T4_g_idTitle, $GUI_ENABLE)
        GUICtrlSetState($T4_g_idSearch, $GUI_ENABLE)
        GUICtrlSetState($T4_g_idBrowseVideo, $GUI_ENABLE)
        GUICtrlSetState($T4_g_idBatchFolder, $GUI_ENABLE)
        GUICtrlSetState($T4_g_idBrowseBatchFolder, $GUI_ENABLE)
        GUICtrlSetState($T4_g_idSaveDir, $GUI_ENABLE)
        GUICtrlSetState($T4_g_idBrowseDir, $GUI_ENABLE)
        GUICtrlSetState($T4_g_idOpenDir, $GUI_ENABLE)
        GUICtrlSetState($T4_g_idDownload, $GUI_ENABLE)
        GUICtrlSetState($T4_g_idOpenPage, $GUI_ENABLE)
        GUICtrlSetState($T4_g_idClear, $GUI_ENABLE)
        GUICtrlSetState($T4_g_idList, $GUI_ENABLE)
        GUICtrlSetState($T4_g_idUseCat, $GUI_ENABLE)
        GUICtrlSetState($T4_g_idUseXunlei, $GUI_ENABLE)
        GUICtrlSetState($T4_g_idCatSearchCount, $GUI_ENABLE)
        GUICtrlSetState($T4_g_idXunleiSearchCount, $GUI_ENABLE)
        If $T4_g_bBatchSearchComplete And Tool4_CountPendingBatchDownloads() > 0 Then
            GUICtrlSetState($T4_g_idBatchDownload, $GUI_ENABLE)
        Else
            GUICtrlSetState($T4_g_idBatchDownload, $GUI_DISABLE)
        EndIf
    EndIf
EndFunc

Func Tool4_PumpBackgroundMessages()
    Local $iMsg = GUIGetMsg()
    Switch $iMsg
        Case $GUI_EVENT_CLOSE
            $T4_g_bCloseRequested = True
            $T4_g_bCancelBatch = True
            Tool4_SetStatus("正在取消当前操作并关闭窗口...")
        Case $T4_g_idBatchStop
            $T4_g_bCancelBatch = True
            Tool4_SetStatus("正在停止批量任务，请等待当前网络请求结束...")
    EndSwitch
EndFunc

Func Tool4_CollectVideoFiles($sFolder, ByRef $aFiles)
    If $T4_g_bCancelBatch Then Return
    Local $hSearch = FileFindFirstFile($sFolder & "\*")
    If $hSearch = -1 Then Return

    Local $iVisited = 0
    While 1
        Local $sName = FileFindNextFile($hSearch)
        If @error Then ExitLoop
        If $sName = "." Or $sName = ".." Then ContinueLoop

        $iVisited += 1
        If Mod($iVisited, 50) = 0 Then
            Tool4_SetStatus("正在扫描目录：已发现 " & $T4_g_iScanFileCount & " 个视频文件；当前位置：" & $sFolder)
            Tool4_PumpBackgroundMessages()
            If $T4_g_bCancelBatch Then ExitLoop
        EndIf

        Local $sFullPath = $sFolder & "\" & $sName
        Local $sAttrib = FileGetAttrib($sFullPath)
        If @error Then ContinueLoop

        If StringInStr($sAttrib, "D") > 0 Then
            ; 跳过目录联接 / 符号链接，避免递归环路。
            If StringInStr($sAttrib, "L") = 0 Then Tool4_CollectVideoFiles($sFullPath, $aFiles)
        Else
            If Tool4_IsVideoExtension(Tool4_GetFileExtension($sName)) Then
                If $T4_g_iScanFileCount >= $T4_g_iScanFileCapacity Then
                    $T4_g_iScanFileCapacity *= 2
                    ReDim $aFiles[$T4_g_iScanFileCapacity]
                EndIf
                $aFiles[$T4_g_iScanFileCount] = $sFullPath
                $T4_g_iScanFileCount += 1
            EndIf
        EndIf
        If $T4_g_bCancelBatch Then ExitLoop
    WEnd
    FileClose($hSearch)
EndFunc

Func Tool4_GetFileExtension($sFileName)
    Local $iDot = StringInStr($sFileName, ".", 0, -1)
    If $iDot <= 0 Then Return ""
    Return StringLower(StringTrimLeft($sFileName, $iDot))
EndFunc

Func Tool4_GetFileBaseName($sPath)
    Local $sName = Tool4_GetFileName($sPath)
    Local $iDot = StringInStr($sName, ".", 0, -1)
    If $iDot > 0 Then Return StringLeft($sName, $iDot - 1)
    Return $sName
EndFunc

Func Tool4_SourceSummary($bCat, $iCat, $bXunlei, $iXunlei)
    Local $s = ""
    If $bCat Then $s &= "SubtitleCat：" & $iCat & " 条" & @CRLF
    If $bXunlei Then $s &= "迅雷：" & $iXunlei & " 条"
    Return $s
EndFunc

Func Tool4_SearchSubtitleCat($sTitle, $iSearchCount = 5, $iDetailTimeout = 6000)
    Local $sURL = $T4_SITE_URL & "/index.php?search=" & Tool4_UrlEncodeUTF8($sTitle)
    Local $iStatus = 0
    Local $sError = ""
    Tool4_SetStatus("正在请求 SubtitleCat 搜索页...")
    Local $sHTML = Tool4_HttpGetText($sURL, $iStatus, $sError)
    If $sHTML = "" Or $iStatus < 200 Or $iStatus >= 300 Then
        Tool4_SetStatus("SubtitleCat 暂不可用，继续搜索迅雷...")
        Return 0
    EndIf

    ; 搜索页链接形如 href="subs/xxxx.html"。不设原始详情页检查数量上限；
    ; 逐个检查，直到收录数量达到下拉框设定值，或搜索页中的详情链接全部检查完毕。
    Local $aCandidates[64][2]
    Local $iCandidateCount = 0
    Local $iCandidateCapacity = 64
    Local $iPos = 1
    While 1
        If $T4_g_bCancelBatch Then ExitLoop
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
        $sSubTitle = Tool4_HtmlDecode(StringRegExpReplace($sSubTitle, "(?is)<[^>]*>", ""))
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
        If $T4_g_bCancelBatch Then ExitLoop
        If $iAdded >= $iSearchCount Then ExitLoop
        $iChecked += 1
        Tool4_SetStatus("检查 SubtitleCat 字幕详情：已检查 " & $iChecked & " 个；有效收录 " & $iAdded & "/" & $iSearchCount)
        Local $sDetailURL = $T4_SITE_URL & "/" & $aCandidates[$i][0]
        Local $iDetailStatus = 0
        Local $sDetailError = ""
        Local $sDetailHTML = Tool4_HttpGetText($sDetailURL, $iDetailStatus, $sDetailError, $iDetailTimeout)
        If $sDetailHTML = "" Or $iDetailStatus < 200 Or $iDetailStatus >= 300 Then ContinueLoop

        Local $sLang = ""
        ; 仅接受简体中文字幕轨；不再检查或收录繁体中文。
        If StringInStr($sDetailHTML, "-zh-CN.srt") > 0 Then $sLang = "zh-CN"
        If $sLang = "" Then ContinueLoop

        Local $sSubtitleURL = Tool4_FindSubtitleCatFileURL($sDetailHTML, $sLang)
        ; 没有提取到真实 HTTP(S) 字幕直链的项目不收录，也不占用搜索数量。
        If Not Tool4_IsHttpURL($sSubtitleURL) Then ContinueLoop
        ; 同一视频、同一来源的重复下载地址不重复收录，也不占用搜索数量。
        If Tool4_ResultURLExists("SubtitleCat", $sSubtitleURL) Then ContinueLoop

        Local $iSubtitleSize = -1
        If $T4_g_iListViewRows < $T4_BATCH_LISTVIEW_LIMIT Then $iSubtitleSize = Tool4_GetRemoteFileSize($sSubtitleURL)
        Tool4_AddResult($aCandidates[$i][1], "SubtitleCat", $sLang, "srt", $aCandidates[$i][0], Tool4_SafeFileName($aCandidates[$i][1]) & ".srt", $sSubtitleURL, $iSubtitleSize)
        $iAdded += 1
    Next
    Return $iAdded
EndFunc

Func Tool4_SearchXunlei($sTitle, $iSearchCount = 5)
    Local $sURL = $T4_XUNLEI_API_URL & "?gcid=&cid=&name=" & Tool4_UrlEncodeUTF8($sTitle)
    Local $iStatus = 0
    Local $sError = ""
    Tool4_SetStatus("正在请求迅雷字幕库...")
    Local $sJSON = Tool4_HttpGetText($sURL, $iStatus, $sError)
    If $sJSON = "" Or $iStatus < 200 Or $iStatus >= 300 Then Return 0

    Local $sData = Tool4_JsonExtractArray($sJSON, "data")
    If $sData = "" Then Return 0
    Local $aObjects = Tool4_JsonSplitObjects($sData)
    Local $iAdded = 0

    For $i = 0 To UBound($aObjects) - 1
        If $T4_g_bCancelBatch Then ExitLoop
        If $iSearchCount > 0 And $iAdded >= $iSearchCount Then ExitLoop
        Local $sDownloadURL = Tool4_JsonGetString($aObjects[$i], "url")
        Local $sExt = Tool4_JsonGetString($aObjects[$i], "ext")
        Local $sName = Tool4_JsonGetString($aObjects[$i], "name")
        ; 若迅雷接口返回语言字段，则过滤明确标记为繁体中文的候选。
        Local $sApiLanguage = Tool4_JsonGetString($aObjects[$i], "lang")
        If $sApiLanguage = "" Then $sApiLanguage = Tool4_JsonGetString($aObjects[$i], "language")
        If StringRegExp($sApiLanguage, "(?i)(zh[-_ ]?tw|zh[-_ ]?hant|traditional|繁体)") Then ContinueLoop
        If Not Tool4_IsHttpURL($sDownloadURL) Or $sExt = "" Then ContinueLoop
        If Tool4_ResultURLExists("迅雷", $sDownloadURL) Then ContinueLoop

        $sExt = StringRegExpReplace($sExt, "^\.", "")
        If Not StringRegExp($sExt, "(?i)^[a-z0-9]{1,8}$") Then ContinueLoop
        If $sName = "" Then $sName = $sTitle
        If StringLower(StringRight($sName, StringLen("." & $sExt))) = StringLower("." & $sExt) Then
            $sName = StringLeft($sName, StringLen($sName) - StringLen("." & $sExt))
        EndIf

        Local $sDisplayName = $sName & "（迅雷）"
        Local $iXunleiSize = -1
        If $T4_g_iListViewRows < $T4_BATCH_LISTVIEW_LIMIT Then $iXunleiSize = Tool4_GetRemoteFileSize($sDownloadURL)
        Tool4_AddResult($sDisplayName, "迅雷", "zh-CN", StringLower($sExt), $sDownloadURL, $sDisplayName & "." & StringLower($sExt), $sDownloadURL, $iXunleiSize)
        $iAdded += 1
    Next
    Return $iAdded
EndFunc

Func Tool4_IsHttpURL($sURL)
    $sURL = StringStripWS($sURL, 3)
    If $sURL = "" Then Return False
    Return (StringLeft(StringLower($sURL), 7) = "http://" Or StringLeft(StringLower($sURL), 8) = "https://")
EndFunc

Func Tool4_ResultURLExists($sSource, $sDirectURL)
    ; 仅在同一视频、同一字幕来源内去重；批量目录中的不同视频不互相影响。
    Local $sCurrentURL = StringStripWS($sDirectURL, 3)
    Local $iStart = $T4_g_iCurrentVideoFirstResult
    If $iStart < 0 Or $iStart > $T4_g_iResultCount Then $iStart = 0
    For $i = $iStart To $T4_g_iResultCount - 1
        If $T4_g_aResults[$i][1] <> $sSource Then ContinueLoop
        If $T4_g_aResults[$i][6] <> $T4_g_sCurrentVideoPath Then ContinueLoop
        ; URL 路径区分大小写，因此只去除首尾空白，不把整条 URL 转为小写。
        If StringStripWS($T4_g_aResults[$i][7], 3) = $sCurrentURL Then Return True
    Next
    Return False
EndFunc

Func Tool4_AddResult($sTitle, $sSource, $sLang, $sFormat, $sURL, $sFileName, $sDirectURL = "", $iFileSize = -1)
    If $T4_g_iResultCount >= $T4_g_iResultCapacity Then
        Local $iNewCapacity = 64
        If $T4_g_iResultCapacity > 0 Then $iNewCapacity = $T4_g_iResultCapacity * 2
        ReDim $T4_g_aResults[$iNewCapacity][10]
        $T4_g_iResultCapacity = $iNewCapacity
    EndIf
    Local $iIndex = $T4_g_iResultCount
    $T4_g_iResultCount += 1
    $T4_g_aResults[$iIndex][0] = $sTitle
    $T4_g_aResults[$iIndex][1] = $sSource
    $T4_g_aResults[$iIndex][2] = $sLang
    $T4_g_aResults[$iIndex][3] = $sFormat
    $T4_g_aResults[$iIndex][4] = $sURL
    $T4_g_aResults[$iIndex][5] = $sFileName
    $T4_g_aResults[$iIndex][6] = $T4_g_sCurrentVideoPath
    $T4_g_aResults[$iIndex][7] = $sDirectURL
    $T4_g_aResults[$iIndex][8] = $iFileSize
    $T4_g_aResults[$iIndex][9] = 0

    ; 限制界面控件行数，但保留完整候选数组，供后续独立的“批量下载”使用。
    If $T4_g_bBatchRunning And $T4_g_iListViewRows >= $T4_BATCH_LISTVIEW_LIMIT Then
        $T4_g_iBatchHiddenResultCount += 1
        Return
    EndIf

    Local $sLangText = "简体中文"
    Local $sDisplayTitle = StringReplace($sTitle, "|", "｜")
    Local $sVideoName = "手动搜索"
    If $T4_g_sCurrentVideoPath <> "" Then $sVideoName = Tool4_GetFileName($T4_g_sCurrentVideoPath)
    GUICtrlCreateListViewItem($sVideoName & "|" & $sDisplayTitle & "|" & $sSource & "|" & $sLangText & "|" & StringUpper($sFormat) & "|" & Tool4_FormatFileSize($iFileSize), $T4_g_idList)
    Local $iRow = _GUICtrlListView_GetItemCount($T4_g_hList) - 1
    If $iRow >= 0 Then Tool4_RegisterListRowResult($iRow, $iIndex)
    $T4_g_iListViewRows += 1
EndFunc

Func Tool4_RegisterListRowResult($iRow, $iResultIndex)
    If $iRow < 0 Then Return False
    If $iRow >= $T4_g_iListRowMapCapacity Then
        Local $iNewCapacity = 64
        If $T4_g_iListRowMapCapacity > 0 Then $iNewCapacity = $T4_g_iListRowMapCapacity
        While $iNewCapacity <= $iRow
            $iNewCapacity *= 2
        WEnd
        ReDim $T4_g_aListRowResultIndex[$iNewCapacity]
        $T4_g_iListRowMapCapacity = $iNewCapacity
    EndIf
    $T4_g_aListRowResultIndex[$iRow] = $iResultIndex
    If $iRow >= $T4_g_iListRowMapCount Then $T4_g_iListRowMapCount = $iRow + 1
    Return True
EndFunc

Func Tool4_GetResultIndexForListRow($iRow)
    If $iRow < 0 Or $iRow >= $T4_g_iListRowMapCount Then Return -1
    Local $iResultIndex = Int($T4_g_aListRowResultIndex[$iRow])
    If $iResultIndex < 0 Or $iResultIndex >= $T4_g_iResultCount Then Return -1
    Return $iResultIndex
EndFunc

; --------------------------------- 下载 -------------------------------------

Func Tool4_DownloadSelected()
    $T4_g_bCancelBatch = False

    ; GetSelectedIndices 返回 [0]=选中数量、[1..n]=列表行索引。
    ; 使用控件 ID，不再通过 ListView 的 lParam 保存业务索引。
    Local $aSelectedRows = _GUICtrlListView_GetSelectedIndices($T4_g_idList, True)
    If Not IsArray($aSelectedRows) Then
        MsgBox($MB_ICONWARNING, $T4_APP_TITLE, "无法读取列表选择状态，请重新选择字幕。")
        Return
    EndIf
    Local $iSelectedCount = $aSelectedRows[0]
    If $iSelectedCount <= 0 Then
        MsgBox($MB_ICONINFORMATION, $T4_APP_TITLE, "请先在结果列表中选择一条或多条字幕。")
        Return
    EndIf

    Local $sSaveDir = StringStripWS(GUICtrlRead($T4_g_idSaveDir), 3)
    If $sSaveDir = "" Then
        MsgBox($MB_ICONWARNING, $T4_APP_TITLE, "请设置字幕保存目录。")
        Return
    EndIf
    If Not FileExists($sSaveDir) Then DirCreate($sSaveDir)
    If Not FileExists($sSaveDir) Then
        MsgBox($MB_ICONERROR, $T4_APP_TITLE, "无法创建保存目录：" & $sSaveDir)
        Return
    EndIf

    Local $iSuccess = 0
    Local $iFailed = 0
    Local $sErrors = ""
    Local $iProcessed = 0
    For $i = 1 To $iSelectedCount
        If $T4_g_bCancelBatch Or $T4_g_bCloseRequested Then ExitLoop

        Local $iRow = $aSelectedRows[$i]
        $iProcessed += 1
        Local $iIndex = Tool4_GetResultIndexForListRow($iRow)
        If $iIndex < 0 Then
            $iFailed += 1
            If $iFailed <= 10 Then $sErrors &= "列表第 " & ($iRow + 1) & " 行：无法关联到字幕搜索结果。" & @CRLF
            ContinueLoop
        EndIf

        Local $sError = ""
        Tool4_SetStatus("正在下载所选字幕 " & $i & "/" & $iSelectedCount & "：" & $T4_g_aResults[$iIndex][0])
        If Tool4_DownloadResult($iIndex, $sSaveDir, "", ($iSelectedCount > 1), $sError) Then
            $iSuccess += 1
        Else
            $iFailed += 1
            If $iFailed <= 10 Then $sErrors &= $T4_g_aResults[$iIndex][0] & "：" & $sError & @CRLF
        EndIf
    Next

    If $iSelectedCount = 1 And $iSuccess = 1 Then
        Local $iOpen = MsgBox(BitOR($MB_ICONINFORMATION, $MB_YESNO), $T4_APP_TITLE, "字幕已下载。" & @CRLF & "是否打开保存目录？")
        If $iOpen = $IDYES Then ShellExecute($sSaveDir)
    Else
        Local $sSummary = "所选字幕下载处理完成。" & @CRLF & @CRLF & _
                "选中：" & $iSelectedCount & " 条" & @CRLF & _
                "已处理：" & $iProcessed & " 条" & @CRLF & _
                "成功：" & $iSuccess & " 条" & @CRLF & _
                "失败：" & $iFailed & " 条"
        If $T4_g_bCancelBatch Then $sSummary &= @CRLF & "任务已停止。"
        If $sErrors <> "" Then $sSummary &= @CRLF & @CRLF & "失败详情（最多显示 10 项）：" & @CRLF & $sErrors
        MsgBox($MB_ICONINFORMATION, $T4_APP_TITLE, $sSummary)
    EndIf
    Tool4_SetStatus("所选字幕处理完成：成功 " & $iSuccess & " 条，失败 " & $iFailed & " 条。")
EndFunc

Func Tool4_DownloadResult($iIndex, $sSaveDir, $sOverrideBase, $bAvoidOverwrite, ByRef $sError)
    $sError = ""
    If $iIndex < 0 Or $iIndex >= $T4_g_iResultCount Then
        $sError = "无效的字幕结果索引。"
        Return False
    EndIf

    Local $sFileName = ""
    If $sOverrideBase <> "" Then
        $sFileName = Tool4_SafeFileName($sOverrideBase)
        If $T4_g_aResults[$iIndex][1] = "迅雷" Then $sFileName &= "（迅雷）"
        $sFileName &= "." & StringLower($T4_g_aResults[$iIndex][3])
    Else
        $sFileName = Tool4_SafeFileName($T4_g_aResults[$iIndex][5])
        If $sFileName = "" Then $sFileName = "subtitle." & $T4_g_aResults[$iIndex][3]
    EndIf

    If $sFileName = "" Then $sFileName = "subtitle." & $T4_g_aResults[$iIndex][3]
    Local $sTarget = $sSaveDir & "\" & $sFileName
    If $bAvoidOverwrite Then $sTarget = Tool4_GetUniqueTargetPath($sSaveDir, $sFileName)

    Tool4_SetStatus("正在下载：" & $sFileName)
    Local $vBody = Binary("")
    Local $iStatus = 0
    Local $sHTTPError = ""
    If $T4_g_aResults[$iIndex][1] = "迅雷" Then
        Local $iBinaryTimeout = 12000
        If $T4_g_bBatchRunning Then $iBinaryTimeout = 7000
        $vBody = Tool4_HttpGetBinary($T4_g_aResults[$iIndex][4], $iStatus, $sHTTPError, $iBinaryTimeout)
    Else
        Local $iDetailTimeout = 8000
        Local $iSubtitleTimeout = 12000
        If $T4_g_bBatchRunning Then
            $iDetailTimeout = 3000
            $iSubtitleTimeout = 7000
        EndIf
        $vBody = Tool4_DownloadSubtitleCat($T4_g_aResults[$iIndex][4], $T4_g_aResults[$iIndex][2], $iStatus, $sHTTPError, $iDetailTimeout, $iSubtitleTimeout, $T4_g_aResults[$iIndex][7])
    EndIf

    If $iStatus < 200 Or $iStatus >= 300 Or BinaryLen($vBody) = 0 Then
        $sError = "HTTP " & $iStatus & " " & $sHTTPError
        Return False
    EndIf

    If Not Tool4_SaveBinary($vBody, $sTarget) Then
        $sError = "保存失败：" & $sTarget & " " & $T4_g_sLastError
        Return False
    EndIf

    ; 使用本地落盘文件的准确大小校正搜索阶段获取的远程大小。
    Local $iSavedSize = FileGetSize($sTarget)
    If Not @error And $iSavedSize > 0 Then
        $T4_g_aResults[$iIndex][8] = $iSavedSize
        Tool4_UpdateResultSizeInList($iIndex, $iSavedSize)
    EndIf
    ; 逐条记录下载状态。批量下载中同一视频的其他候选仍会继续下载。
    $T4_g_aResults[$iIndex][9] = 1

    Return True
EndFunc

Func Tool4_GetUniqueTargetPath($sDir, $sFileName)
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

Func Tool4_DownloadSubtitleCat($sDetailPath, $sLang, ByRef $iStatus, ByRef $sError, $iDetailTimeout = 8000, $iBinaryTimeout = 12000, $sKnownFileURL = "")
    If $sKnownFileURL <> "" Then Return Tool4_HttpGetBinary($sKnownFileURL, $iStatus, $sError, $iBinaryTimeout)

    Local $sDetailURL = $T4_SITE_URL & "/" & $sDetailPath
    Local $sHTML = Tool4_HttpGetText($sDetailURL, $iStatus, $sError, $iDetailTimeout)
    If $sHTML = "" Or $iStatus < 200 Or $iStatus >= 300 Then Return Binary("")

    Local $sFileURL = Tool4_FindSubtitleCatFileURL($sHTML, $sLang)
    If $sFileURL <> "" Then Return Tool4_HttpGetBinary($sFileURL, $iStatus, $sError, $iBinaryTimeout)

    $iStatus = 404
    $sError = "详情页中没有找到所选语言（" & $sLang & "）的 SRT 下载链接。"
    Return Binary("")
EndFunc

Func Tool4_FindSubtitleCatFileURL($sHTML, $sLang)
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
        If StringInStr($sPath, "-" & $sLang & ".srt") > 0 Then Return $T4_SITE_URL & $sPath
        $iPos = $iURLEnd + 1
    WEnd
    Return ""
EndFunc

; ----------------------------- 标题清理逻辑 ---------------------------------

Func Tool4_BuildSearchTitle($sInput)
    Local $sFileName = Tool4_GetFileName($sInput)
    Local $sTitle = Tool4_CleanTitle($sFileName)
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

Func Tool4_CleanTitle($sTitle)
    $sTitle = Tool4_HtmlDecode($sTitle)

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
        If Tool4_IsVideoExtension($sExt) Then $sTitle = StringLeft($sTitle, $iDot - 1)
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

Func Tool4_IsVideoExtension($sExt)
    Return StringRegExp(StringLower($sExt), "^(mp4|mkv|avi|wmv|flv|webm|mov|ts|m2ts|rmvb|mpg|mpeg|divx|3gp|vob|asf|m4v|rm|ogm|ogv)$")
EndFunc

Func Tool4_GetFileName($sPath)
    Local $iSlash1 = StringInStr($sPath, "\", 0, -1)
    Local $iSlash2 = StringInStr($sPath, "/", 0, -1)
    Local $iSlash = $iSlash1
    If $iSlash2 > $iSlash Then $iSlash = $iSlash2
    If $iSlash > 0 Then Return StringTrimLeft($sPath, $iSlash)
    Return $sPath
EndFunc

Func Tool4_FormatFileSize($iBytes)
    If Not IsNumber($iBytes) Or $iBytes <= 0 Then Return "未知"
    If $iBytes < 1024 Then Return $iBytes & " B"
    If $iBytes < 1048576 Then Return StringFormat("%.1f KB", $iBytes / 1024)
    If $iBytes < 1073741824 Then Return StringFormat("%.2f MB", $iBytes / 1048576)
    Return StringFormat("%.2f GB", $iBytes / 1073741824)
EndFunc

Func Tool4_UpdateResultSizeInList($iResultIndex, $iBytes)
    If $iResultIndex < 0 Or $iResultIndex >= $T4_g_iResultCount Then Return
    For $iRow = 0 To $T4_g_iListRowMapCount - 1
        If $T4_g_aListRowResultIndex[$iRow] = $iResultIndex Then
            _GUICtrlListView_SetItemText($T4_g_hList, $iRow, Tool4_FormatFileSize($iBytes), 5)
            Return
        EndIf
    Next
EndFunc

Func Tool4_GetRemoteFileSize($sURL)
    ; 使用 HEAD 只读取响应头，不下载字幕主体；服务器不支持或未返回长度时显示“未知”。
    If StringLeft($sURL, 7) <> "http://" And StringLeft($sURL, 8) <> "https://" Then Return -1
    $T4_g_sLastError = ""
    Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
    If Not IsObj($oHTTP) Then Return -1

    $oHTTP.Open("HEAD", $sURL, True)
    $oHTTP.SetTimeouts(500, 500, 700, 900)
    $oHTTP.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0 Safari/537.36")
    $oHTTP.SetRequestHeader("Accept", "*/*")
    $oHTTP.SetRequestHeader("Accept-Encoding", "identity")
    $oHTTP.Send()

    If Not Tool4_WaitForHttpResponse($oHTTP, 2200) Then Return -1
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

Func Tool4_HttpGetText($sURL, ByRef $iStatus, ByRef $sError, $iReceiveTimeout = 8000)
    $iStatus = 0
    $sError = ""
    $T4_g_sLastError = ""
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
    If Not Tool4_WaitForHttpResponse($oHTTP, 10000 + $iReceiveTimeout) Then
        If $T4_g_bCancelBatch Then
            $sError = "用户取消。"
        Else
            $sError = $T4_g_sLastError
            If $sError = "" Then $sError = "网络请求超时。"
        EndIf
        Return ""
    EndIf

    $iStatus = $oHTTP.Status
    If $iStatus >= 200 And $iStatus < 300 Then Return $oHTTP.ResponseText
    If $iStatus = 0 And $T4_g_sLastError <> "" Then
        $sError = $T4_g_sLastError
    Else
        $sError = "HTTP " & $iStatus
    EndIf
    Return ""
EndFunc

Func Tool4_HttpGetBinary($sURL, ByRef $iStatus, ByRef $sError, $iReceiveTimeout = 12000)
    $iStatus = 0
    $sError = ""
    $T4_g_sLastError = ""
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
    If Not Tool4_WaitForHttpResponse($oHTTP, 8000 + $iReceiveTimeout) Then
        If $T4_g_bCancelBatch Then
            $sError = "用户取消。"
        Else
            $sError = $T4_g_sLastError
            If $sError = "" Then $sError = "下载请求超时。"
        EndIf
        Return Binary("")
    EndIf

    $iStatus = $oHTTP.Status
    If $iStatus >= 200 And $iStatus < 300 Then Return $oHTTP.ResponseBody
    If $iStatus = 0 And $T4_g_sLastError <> "" Then
        $sError = $T4_g_sLastError
    Else
        $sError = "HTTP " & $iStatus
    EndIf
    Return Binary("")
EndFunc

Func Tool4_WaitForHttpResponse(ByRef $oHTTP, $iMaxWaitMs)
    Local $hTimer = TimerInit()
    While 1
        Tool4_PumpBackgroundMessages()
        If $T4_g_bCancelBatch Or $T4_g_bCloseRequested Then
            $oHTTP.Abort()
            Return False
        EndIf

        Local $bReady = $oHTTP.WaitForResponse(1)
        If @error Then
            $T4_g_sLastError = "等待 HTTP 响应失败。"
            Return False
        EndIf
        If $bReady Then Return True

        If TimerDiff($hTimer) > $iMaxWaitMs Then
            $oHTTP.Abort()
            $T4_g_sLastError = "网络请求超时。"
            Return False
        EndIf
    WEnd
EndFunc

Func Tool4_SaveBinary($vData, $sPath)
    $T4_g_sLastError = ""
    Local $oStream = ObjCreate("ADODB.Stream")
    If Not IsObj($oStream) Then
        $T4_g_sLastError = "无法创建 ADODB.Stream 对象。"
        Return False
    EndIf

    $oStream.Type = 1 ; adTypeBinary
    $oStream.Open()
    $oStream.Write($vData)
    $oStream.SaveToFile($sPath, 2) ; adSaveCreateOverWrite
    $oStream.Close()
    Return FileExists($sPath) And FileGetSize($sPath) > 0
EndFunc

Func Tool4_UrlEncodeUTF8($sText)
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

Func Tool4_HtmlDecode($sText)
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

Func Tool4_JsonExtractArray($sJSON, $sKey)
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

Func Tool4_JsonSplitObjects($sArray)
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

Func Tool4_JsonGetString($sObject, $sKey)
    Local $q = Chr(34)
    Local $sPattern = $q & $sKey & $q & "\s*:\s*" & $q & "((?:\\.|[^" & $q & "\\])*)" & $q
    Local $aMatch = StringRegExp($sObject, $sPattern, 1)
    If Not IsArray($aMatch) Then Return ""
    If UBound($aMatch) = 0 Then Return ""
    Return Tool4_JsonUnescape($aMatch[0])
EndFunc

Func Tool4_JsonUnescape($sText)
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

Func Tool4_SafeFileName($sName)
    $sName = StringRegExpReplace($sName, "[\\/:*?""<>|]", "_")
    $sName = StringStripWS($sName, 3)
    While StringLen($sName) > 0 And (StringRight($sName, 1) = "." Or StringRight($sName, 1) = " ")
        $sName = StringTrimRight($sName, 1)
    WEnd
    Return $sName
EndFunc

#EndRegion ;**** 工具4：在线中文字幕搜索下载 (tool-4) ****

; ==========================================================
; 程序主入口（位于所有模块全局变量初始化之后）
; ==========================================================
_DispatchMode()
