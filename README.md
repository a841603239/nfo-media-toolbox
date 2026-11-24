# NFO 影视刮削工具箱（四合一）

> 面向本地媒体库整理的 Windows 桌面工具箱，集成 **刮削资源批量备份**、**NFO 编辑器与 AI 翻译**、**TMM 命名模板速查**、**在线中文字幕搜索下载** 四个模块。

[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%2F%2011%20x64-0078D4.svg)](#系统要求)
[![Language](https://img.shields.io/badge/language-AutoIt3-1B72BE.svg)](https://www.autoitscript.com/)
[![Version](https://img.shields.io/badge/version-1.1.0.0-2F6FED.svg)](#版本)
[![License](https://img.shields.io/badge/license-MIT-0E9F6E.svg)](#许可证)

---

## 项目简介

整理本地影视库通常要在多个工具之间来回切换：备份刮削资源、核对 NFO 元数据、确认命名是否符合刮削器规范、补齐中文字幕。本项目把这四件高频事项整合进一个启动器，共用一致的界面风格与操作习惯，减少窗口切换与重复输入。

技术实现基于 **AutoIt3 + GDI+ 自绘界面**，网络请求与 XML 处理全部使用 Windows 内置 COM 组件（`WinHttp.WinHttpRequest.5.1`、`Msxml2.DOMDocument`、`ADODB.Stream`），**无需安装 .NET 运行时或任何第三方运行库**，发布形态为单个可执行文件。

---

## 功能模块

启动器为 1366×768 的四卡片主菜单，点击卡片或通过命令行参数进入对应模块。

### 1. 手动刮削资源批量备份

将源目录下的刮削资源递归复制到目标目录，适合在重建媒体库或迁移硬盘前做一次干净的快照。

- **递归扫描**：按目录层级完整复制，保留原目录结构
- **排除规则**：可选排除 `.nfo` 文件、`.actors` 文件夹、常见图片格式（`.png` / `.jpg` / `.jpeg` / `.tga` / `.webp` 等）
- **目录树导出**：备份完成后生成 `目录树.txt`，便于核对资源完整性
- **安全校验**：拒绝源目录与目标目录相同或互相包含，避免递归扫描自身与覆盖混淆
- **实时反馈**：进度条显示 `已复制 / 总数（百分比）`，日志区逐条记录处理结果

### 2. NFO 编辑器与 AI 翻译

查看与编辑 Kodi / Emby / Jellyfin 兼容的 `.nfo` 元数据，并借助 DeepSeek 完成标题与剧情简介的汉化。

- **五个编辑页**：基本信息、演员、媒体信息、XML 源码、设置
- **XML 源码页**：直接查看与修改原始 XML，便于处理结构异常的文件
- **AI 翻译**：调用 DeepSeek Chat Completions 接口，把 `title` / `plot` 译为简体中文
- **批量汉化**：左栏勾选多个文件后一次执行；受 AutoIt 单线程限制，采用异步 WinHttp + 轮询实现并发 2 路请求
- **目录遍历与筛选**：选择目录后列出全部 NFO，支持关键字搜索（带输入防抖）与全选 / 全不选
- **状态指示**：底部指示灯区分就绪 / 有未保存修改 / 失败三种状态

### 3. TMM 命名模板速查

针对 **tinyMediaManager** 的命名规范速查面板，避免因命名不符导致刮削失败。

- **电影 / 电视剧**双栏布局，分别覆盖文件夹、季文件夹、文件名三级命名
- **多语言标签页**：日语 / 华语 / 韩语 / 欧美等分类，切换即切换整套模板
- **变量与预览**：每条模板同时给出变量写法与渲染后的示例，如
  `[${originalTitle}].${year}.${mediaSource}.${videoFormat}.${videoCodec}.${audioCodec}` → `[あゝ海軍].1969.Web-DL.1080p.h265.EAC3.mkv`
- **一键复制**：点击卡片直接写入剪贴板

### 4. 在线中文字幕搜索下载

聚合 **SubtitleCat** 与 **迅雷字幕库** 两个公开来源，按影片标题检索简体中文字幕。

- **双来源并行检索**：可分别勾选来源，并独立设置每个来源的搜索数量（1–10 条）
- **番号识别**：从文件名中自动提取 `ABCD-123` / `ABC-123` 形式的编号作为搜索词
- **批量模式**：指定目录后递归收集全部视频（MP4 / MKV / MOV 等），批量搜索后再执行批量下载，支持中断
- **结果表格**：展示关联视频、字幕名称、来源、语言、格式、文件大小
- **下载控制**：支持 Ctrl / Shift 多选手动下载、同名文件自动改名避让、可自定义保存目录（默认 `程序目录\Subtitles`）

---

## 系统要求

| 项目 | 要求 |
| --- | --- |
| 操作系统 | Windows 10 / 11，64 位 |
| 运行库 | 无（依赖 Windows 内置 COM 组件） |
| 显示 | 建议 1920×1080 及以上；主界面按 1600×900 / 1366×768 固定画布设计 |
| 字体 | Microsoft YaHei UI（Windows 简体中文版默认自带） |
| 网络 | 模块 2 的 AI 翻译需访问 `api.deepseek.com`；模块 4 需访问 `subtitlecat.com` 与迅雷字幕接口 |
| 源码编译 | AutoIt3 3.3.16.1 及以上 + AutoIt3Wrapper（建议配合 SciTE4AutoIt3） |

> 主界面已处理高 DPI 缩放（`SetProcessDpiAwarenessContext`，Per-Monitor V2），在 125% / 150% 缩放下不会出现模糊拉伸。

---

## 快速开始

### 方式一：直接运行发布版

1. 前往 [Releases](../../releases) 下载最新的 `NFO影视刮削工具箱.exe`（或 `四合一.exe`）。
2. 放到任意目录双击运行（**建议单独建一个文件夹**，模块 4 的默认字幕目录会创建在程序同级）。
3. 若 Windows SmartScreen 提示未知发布者，选择「更多信息」→「仍要运行」。本程序未做代码签名。

### 方式二：从源码编译

```bash
git clone https://github.com/<your-username>/<repo-name>.git
cd <repo-name>
```

1. 安装 [AutoIt3](https://www.autoitscript.com/site/autoit/downloads/) 与 SciTE4AutoIt3。
2. 用 SciTE 打开 `四合一.au3`。
3. 确认 `icon.ico` 与 `四合一.au3` 位于同一目录。源码已通过 `#AutoIt3Wrapper_Icon=icon.ico` 引用该图标，缺失会导致编译中断。
4. 按 `F7` 编译，或通过 AutoIt3Wrapper 使用内置指令直接产出可执行文件：

```autoit
#AutoIt3Wrapper_Outfile=NFO影视刮削工具箱.exe
#AutoIt3Wrapper_Icon=icon.ico
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_UseUpx=N
```

> 本项目在编译指令中**显式关闭了 UPX 压缩**。UPX 压缩后的 AutoIt 程序极易被杀毒软件误报，保持未压缩可显著降低误杀率。

---

## 命令行参数

启动器支持通过参数直达指定模块，便于创建桌面快捷方式或脚本调用：

| 参数 | 模块 |
| --- | --- |
| `/tool1` | 手动刮削资源批量备份 |
| `/tool2` | NFO 编辑器与 AI 翻译 |
| `/tool3` | TMM 命名模板速查 |
| `/tool4` | 在线中文字幕搜索下载 |

不带参数时进入四卡片主菜单。子模块通过重新拉起自身进程并附加参数的方式实现，因此各模块拥有独立的窗口与生命周期。

---

## 配置文件

NFO 编辑器的设置（含 API Key）保存在用户目录，不写入程序目录，避免便携场景下泄露：

```
%LOCALAPPDATA%\MediaResourceToolbox\nfo_editor_settings.ini
```

| 键 | 说明 | 默认值 |
| --- | --- | --- |
| `DeepSeek.ApiUrl` | Chat Completions 接口地址 | `https://api.deepseek.com/chat/completions` |
| `DeepSeek.ApiKey` | DeepSeek API Key | 空（需在设置页填写） |
| `DeepSeek.Model` | 模型名称 | `deepseek-chat` |
| `DeepSeek.Prompt` | 汉化提示词（INI 安全编码后存储） | 内置默认提示词 |

首次运行时，若程序目录或旧的 `工具2nfo编辑器` 子目录中存在 `nfo_editor_settings.ini`，会自动迁移到上述用户目录。

> **安全提示**：API Key 以明文形式保存在本机 INI 文件中，仅适用于个人电脑。请勿提交包含真实 Key 的配置文件，也不要把它放在共享或同步目录中。

---

## 项目结构

```
.
├── 四合一.au3              # 主源码，含启动器与四个模块（约 6,900 行）
├── icon.ico                # 程序图标，由 #AutoIt3Wrapper_Icon 引用
├── README.md
├── LICENSE
├── .gitignore
├── docs/
│   └── legacy/             # 整合前的单模块历史版本，仅作对照参考
│       ├── TMM规范命名模板.au3
│       ├── 字幕批量搜索.au3
│       ├── nfo编辑器.rar
│       └── 手动刮削批量备份工具.rar
├── _local/                 # 本地工作区（AutoIt3Wrapper 快捷方式），已 gitignore
├── 四合一.exe              # 编译产物，已 gitignore，见 Releases
```

**关于 `docs/legacy/`**：四个模块整合前的独立源码与打包产物，功能已被 `四合一.au3` 完全覆盖，保留用于行为对照与回溯。其中的 `.rar` 通过 `.gitignore` 排除，不入库。

**关于 `_local/`**：存放指向本机 AutoIt 安装目录的编译快捷方式（`Au3Check.exe.lnk` 等）。这些文件含绝对路径、无移植价值，整个目录被排除在版本控制之外，仅方便本地一键编译。

> 运行时的 `Subtitles` 目录与 `nfo_editor_settings.ini` 迁移逻辑均基于 **exe 所在目录**（`@ScriptDir`），与源码位置无关；因此上述目录调整不影响已编译程序的既有行为。

---

## 常见问题

**Q：杀毒软件报毒怎么办？**
AutoIt 编译的程序因常被用于编写自动化脚本，存在较高的启发式误报率。本项目已关闭 UPX 压缩并保持 X64 原生编译。若仍被拦截，将程序目录加入白名单，或按上文步骤自行编译。

**Q：AI 翻译提示「请先在设置页填写 API Key」？**
进入 NFO 编辑器 → 设置页，填入 DeepSeek API Key 后保存。Key 可在 [DeepSeek 开放平台](https://platform.deepseek.com/) 申请。填写后无需重启，下次翻译即生效。

**Q：批量模式提示「没有找到支持的视频文件」？**
批量模式仅扫描指定目录及其子目录下的视频文件（MP4 / MKV / MOV 等）。请确认路径正确，且目录中确实存在视频文件而非快捷方式。

**Q：字幕下载后播放器不加载？**
检查文件名是否与视频主名一致。本工具默认以「视频主名 + 原字幕扩展名」命名，若播放器要求特定后缀（如 `.chs.srt`），请手动调整。

**Q：模块 4 搜不到字幕？**
字幕来源为第三方公开站点，其可用性、检索结果与站点策略相关，非本项目可控。建议同时勾选两个来源，并尝试使用原始标题或番号作为搜索词。

**Q：能在 macOS / Linux 上运行吗？**
不能。界面依赖 Win32 GDI+ 与 Windows 专有 COM 组件，仅支持 Windows。

---

## 已知限制

- **单线程架构**：AutoIt 无原生多线程，批量汉化与批量下载通过异步 HTTP + 消息轮询模拟并发，实际并发度为 2，大批量任务耗时较长。
- **固定画布布局**：界面按绝对坐标设计，不支持自由缩放；在 4K 显示器上建议配合系统缩放使用。
- **第三方依赖脆弱性**：模块 4 依赖 SubtitleCat 与迅雷字幕接口的页面结构与 API 形态，对方调整后可能需要同步修改解析逻辑。
- **无自动更新**：版本升级需手动下载替换。

---

## 免责声明

1. 本工具仅用于**个人本地媒体库的整理与管理**，不提供、不分发、不存储任何影视或字幕内容。
2. 模块 4 仅检索第三方站点的公开搜索结果并下载用户主动选择的文件，内容版权归原权利人所有。使用者应自行确认其行为符合所在地法律法规及目标站点的服务条款。
3. 模块 2 的 AI 翻译功能会将影片标题与剧情简介发送至 DeepSeek 接口，请知悉该数据流向。
4. 使用本工具产生的一切后果由使用者自行承担。

---

## 许可证

本项目基于 [MIT License](LICENSE) 开源。

---

## 致谢

- [AutoIt3](https://www.autoitscript.com/) — 桌面自动化与 GUI 开发
- [DeepSeek](https://www.deepseek.com/) — 汉化翻译接口
- [tinyMediaManager](https://www.tinymediamanager.org/) — 命名规范参考
- [SubtitleCat](https://www.subtitlecat.com/)、迅雷字幕库 — 字幕检索来源

---

**版本**：1.1.0.0 ｜ **作者**：Sorin ｜ **Copyright © 2026**
