#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <FontConstants.au3>
#include <GDIPlus.au3>
#include <WinAPIHObj.au3>
#include <WinAPISysInternals.au3>
#include <WinAPISys.au3>

; DPI 感知设置
If @OSVersion = "WIN_10" Or @OSVersion = "WIN_11" Then
    Local Const $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = -4
    DllCall("user32.dll", "bool", "SetProcessDpiAwarenessContext", "handle", $DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)
EndIf

; ======================================
Opt("MustDeclareVars", 1)
Opt("TrayIconHide", 1) ; 隐藏右下角托盘图标

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

_GDIPlus_Startup()

; 分辨率为 1600x900
Global $g_hGui = GUICreate("命名模板快捷复制", 1600, 900, -1, -1, BitOR($WS_CAPTION, $WS_MINIMIZEBOX, $WS_SYSMENU), $WS_EX_COMPOSITED)
GUISetBkColor($COLOR_BG, $g_hGui)

; 头部设计
GUICtrlCreateLabel("", 30, 22, 8, 70)
GUICtrlSetBkColor(-1, $COLOR_PRIMARY)
Global $g_idTitle = GUICtrlCreateLabel("命名模板快捷复制", 55, 20, 400, 50)
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
Global $g_hMovie = GUICreate("", 750, 650, 30, 160, $WS_CHILD, $WS_EX_CONTROLPARENT, $g_hGui)
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
Global $g_hTv = GUICreate("", 750, 650, 820, 160, $WS_CHILD, $WS_EX_CONTROLPARENT, $g_hGui)
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
GUISwitch($g_hGui)
$g_idToast = GUICtrlCreateLabel("", 575, 825, 450, 42, BitOR($SS_CENTER, $SS_CENTERIMAGE))
GUICtrlSetFont($g_idToast, 13, $FW_BOLD, 0, "Microsoft YaHei UI")
GUICtrlSetColor($g_idToast, $COLOR_CARD)
GUICtrlSetBkColor($g_idToast, $COLOR_TEXT)
GUICtrlSetState($g_idToast, $GUI_HIDE)
GUISetState(@SW_SHOW, $g_hGui)

While 1
    Local $aMsg = GUIGetMsg(1)
    Switch $aMsg[0]
        Case $GUI_EVENT_CLOSE
            If $aMsg[1] = $g_hGui Then ExitLoop
        Case Else
            _HandleClick($aMsg[0])
    EndSwitch
    _UpdateTransientState()
    Sleep(20)
WEnd

_DisposePanelBitmap($g_idMoviePicture, $g_hMovieBitmap)
_DisposePanelBitmap($g_idTvPicture, $g_hTvBitmap)
GUIDelete($g_hMovie)
GUIDelete($g_hTv)
GUIDelete($g_hGui)
_GDIPlus_Shutdown()
Exit

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

Func _HandleClick($nMsg)
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
EndFunc

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
