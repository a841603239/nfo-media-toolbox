#NoTrayIcon
#AutoIt3Wrapper_UseX64=N
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <ListBoxConstants.au3>
#include <ListViewConstants.au3>
#include <ComboConstants.au3>
#include <GUIListView.au3>
#include <GuiComboBox.au3>
#include <GuiListBox.au3>
#include <Array.au3>
#include <StructureConstants.au3>
#include "MetroGUI\MetroThemes.au3"
#include "MetroGUI\MetroUDF-Required\StringSize.au3"
#include "MetroGUI\MetroUDF-Required\SSCtrlHover.au3"
#include "MetroGUI\MetroGUI_UDF.au3"

; ============================================================================
; NFO 编辑器 - AutoIt3 版本
; ============================================================================

; ==================== 主题配色 ====================
Global Const $CLR_CARD_BG        = 0xF8F9FA   ; 极浅灰白底
Global Const $CLR_SURFACE        = 0xDCE4EC   ; 输入框/卡片灰（与底色差 1.22，保证边界可见）
Global Const $CLR_BORDER         = 0xD1D9E0   ; 分割线灰蓝
Global Const $CLR_PRIMARY        = 0x5B6ABF   ; 柔和靛蓝
Global Const $CLR_SUCCESS        = 0x2E8B57   ; 森林绿
Global Const $CLR_ERROR          = 0xD9534F   ; 温和红
Global Const $CLR_WARNING        = 0xB45309   ; 琥珀橙
Global Const $CLR_INFO           = 0x0F766E   ; 深青绿
Global Const $CLR_TEXT_PRIMARY   = 0x1E293B   ; 深灰（正文）
Global Const $CLR_TEXT_SECONDARY = 0x475569   ; 中灰（标签）
Global Const $CLR_TEXT_MUTED     = 0x64748B   ; 中浅灰（辅助文字，对底色 4.51 达 AA）
Global Const $CLR_TEXT_ON_ACCENT = 0xFFFFFF

; 状态指示灯配色：灰=就绪/已保存，橙=有未保存修改，红=失败
Global Const $CLR_STATUS_READY    = 0x9CA3AF
Global Const $CLR_STATUS_MODIFIED = 0xF59E0B
Global Const $CLR_STATUS_ERROR    = 0xBE123C

; ==================== 全局变量 ====================
Global $g_hMainGui = 0
Global $g_hActorDialog = 0
Global $g_aMetroControlButtons
Global $g_aActorDialogButtons
Global $g_idAccelSave = 0 ; Ctrl+S 快捷键关联的 Dummy 控件
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

Global $g_sSettingsFile = @ScriptDir & "\nfo_editor_settings.ini"
Global $g_sDeepSeekApiUrl = $DEFAULT_DEEPSEEK_API_URL
Global $g_sDeepSeekApiKey = ""
Global $g_sDeepSeekModel = $DEFAULT_DEEPSEEK_MODEL
Global $g_sLocalizePrompt = $DEFAULT_LOCALIZE_PROMPT

; 文件元数据缓存: [relative_path, country, languages, full_path]
Global $g_aFileMetadata[1][4]
Global $g_iFileCount = 0

; 主 GUI 控件 ID
Global $g_idBtnOpen, $g_idBtnSave, $g_idBtnSaveAs, $g_idBtnRefresh
Global $g_idList, $g_idFileSearch, $g_idCountryFilter, $g_idLanguageFilter
Global $g_idBtnCheckAll, $g_idBtnCheckNone, $g_idBtnBatchLocalize
; 文件列表 ListView 的句柄，用于在 WM_NOTIFY 中识别来源控件
Global $g_hFileList = 0
; ListView 选择变更在 WM_NOTIFY 中只置标记，由主循环处理：
; 通知回调里直接弹 MsgBox（_ConfirmDiscardChanges）会阻塞消息处理并可能重入。
Global $g_bPendingFileSelect = False
Global $g_idBtnSelectDir, $g_idBtnPrev, $g_idBtnNext, $g_idDirLabel
Global $g_idStatusBar, $g_idStatusDot, $g_idTab
Global $g_idCurrentFileLabel, $g_idFileCountLabel

; 字段映射: 基本信息 [label, xml_tag, control_id, is_multiline]；视频 [label, xml_tag, control_id]；音频 [label, xml_tag, control_id, is_combo]
Global $g_aBasicFields[13][4] = [ _
    ["标题", "title", 0, 0], ["原标题", "originaltitle", 0, 0], _
    ["编号", "num", 0, 0], ["发行日期", "premiered", 0, 0], ["发行说明", "tagline", 0, 0], _
    ["年份", "year", 0, 0], ["时长/分钟", "runtime", 0, 0], ["国家代码", "countrycode", 0, 0], _
    ["制片商", "studio", 0, 0], ["系列", "series", 0, 0], ["DMM 地址", "dmmid", 0, 0], _
    ["JavDB ID", "javdbsearchid", 0, 0], ["剧情简介", "plot", 0, 0]]
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

; MetroGUI 控制按钮数组索引
Global Const $METRO_BTN_CLOSE = 0
Global Const $METRO_BTN_MINIMIZE = 3

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

; 用大小和最后写入时间检测文件是否在编辑器外被修改。
Func _GetNfoFileSignature($sFilePath)
    If Not FileExists($sFilePath) Then Return ""
    Local $vTime = FileGetTime($sFilePath, 0, 1)
    If @error Then Return String(FileGetSize($sFilePath))
    Return String(FileGetSize($sFilePath)) & "|" & String($vTime)
EndFunc

Func _HasLanguageToken($sLanguages, $sWanted)
    If $sWanted = "" Then Return True
    Local $aLanguages = StringSplit($sLanguages, ",")
    If @error Then Return False
    For $i = 1 To $aLanguages[0]
        If StringStripWS($aLanguages[$i], 3) = $sWanted Then Return True
    Next
    Return False
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

; 在块内替换单个标签内容；标签不存在时不做改动（由调用方决定是否新增）
Func _ReplaceTagInBlock($sBlockText, $sTag, $sNewValue)
    Local $sPattern = '(<' & $sTag & '(?:\s[^>]*)?>)([\s\S]*?)(</' & $sTag & '>)'
    Local $sReplacement = '${1}' & _EscapeReplacement($sNewValue) & '${3}'
    Return StringRegExpReplace($sBlockText, $sPattern, $sReplacement, 1)
EndFunc

; 在块内更新单个标签：仅当块内已有该标签时替换内容，否则忽略。
; 按设计，编辑器不为块补充原本没有的子字段（例如不给只有 <name> 的
; <actor> 补出 <role>、<tmdbid>）。
Func _UpdateTagInBlockIfPresent($sBlockText, $sTag, $sNewValue)
    If StringRegExp($sBlockText, '<' & $sTag & '(?:\s[^>]*)?>[\s\S]*?</' & $sTag & '>') Then
        Return _ReplaceTagInBlock($sBlockText, $sTag, $sNewValue)
    EndIf
    Return $sBlockText
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
                $sBlockToUse = _UpdateTagInBlockIfPresent($sBlockToUse, $aFieldOrder[$j], $aItems[$i][$j])
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

Func _CallDeepSeekLocalize($sTitle, $sPlot)
    Local $sApiUrl = _NormalizeChatCompletionsUrl($g_sDeepSeekApiUrl)
    Local $sApiKey = StringStripWS($g_sDeepSeekApiKey, 3)
    Local $sModel = StringStripWS($g_sDeepSeekModel, 3)

    If $sApiUrl = "" Then Return SetError(1, 0, "请先在设置页填写 API URL")
    If $sApiKey = "" Then Return SetError(2, 0, "请先在设置页填写 API Key")
    If $sModel = "" Then $sModel = $DEFAULT_DEEPSEEK_MODEL

    Local $sPrompt = _BuildLocalizePrompt($sTitle, $sPlot)
    Local $sBody = '{"model":"' & _JsonEscape($sModel) & '","messages":[{"role":"user","content":"' & _JsonEscape($sPrompt) & '"}],"temperature":0.7,"stream":false}'

    Local $oHttp = ObjCreate("WinHttp.WinHttpRequest.5.1")
    If Not IsObj($oHttp) Then Return SetError(3, 0, "无法创建 WinHttp 请求对象")

    $oHttp.SetTimeouts(10000, 10000, 30000, 60000)
    $oHttp.Open("POST", $sApiUrl, False)
    $oHttp.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
    $oHttp.SetRequestHeader("Authorization", "Bearer " & $sApiKey)
    Local $vBody = _StringToUtf8Binary($sBody)
    If @error Then Return SetError(6, 0, "无法创建 UTF-8 请求体")

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
    Local $sApiUrl = _NormalizeChatCompletionsUrl($g_sDeepSeekApiUrl)
    Local $sApiKey = StringStripWS($g_sDeepSeekApiKey, 3)
    Local $sModel = StringStripWS($g_sDeepSeekModel, 3)

    If $sApiUrl = "" Then Return SetError(1, 0, "请先在设置页填写 API URL")
    If $sApiKey = "" Then Return SetError(2, 0, "请先在设置页填写 API Key")
    If $sModel = "" Then $sModel = $DEFAULT_DEEPSEEK_MODEL

    Local $sPrompt = _BuildLocalizePrompt($sTitle, $sPlot)
    Local $sBody = '{"model":"' & _JsonEscape($sModel) & '","messages":[{"role":"user","content":"' & _JsonEscape($sPrompt) & '"}],"temperature":0.7,"stream":false}'

    Local $oHttp = ObjCreate("WinHttp.WinHttpRequest.5.1")
    If Not IsObj($oHttp) Then Return SetError(3, 0, "无法创建 WinHttp 请求对象")

    Local $vBody = _StringToUtf8Binary($sBody)
    If @error Then Return SetError(6, 0, "无法创建 UTF-8 请求体")

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

; ==================== 控件样式与创建 ====================

; 字段标签统一样式
Func _StyleFieldLabel($idLabel)
    GUICtrlSetColor($idLabel, $CLR_TEXT_SECONDARY)
    GUICtrlSetBkColor($idLabel, $CLR_CARD_BG)
    GUICtrlSetFont($idLabel, 10, 400, 0, "Microsoft YaHei UI")
EndFunc

; 输入类控件统一样式：浅灰底把可编辑区从白色卡片底中区分出来，
; 不再依赖成片的面板背景 Label 来划分区域。
Func _StyleFieldInput($idInput)
    GUICtrlSetBkColor($idInput, $CLR_SURFACE)
    GUICtrlSetColor($idInput, $CLR_TEXT_PRIMARY)
    GUICtrlSetFont($idInput, 10, 400, 0, "Microsoft YaHei UI")
EndFunc

; 次要文字标签统一样式（文件名、目录名、计数、状态栏等）
Func _StyleMutedLabel($idLabel)
    GUICtrlSetColor($idLabel, $CLR_TEXT_MUTED)
    GUICtrlSetBkColor($idLabel, $CLR_CARD_BG)
    GUICtrlSetFont($idLabel, 10, 400, 0, "Microsoft YaHei UI")
EndFunc

Func _CreateLabeledInput($iX, $iY, $sLabel, $iLabelW, $iInputW, $bMultiline = False, $iInputH = 28)
    Local $idLabel = GUICtrlCreateLabel($sLabel, $iX, $iY, $iLabelW, 20)
    _StyleFieldLabel($idLabel)

    Local $idInput
    If $bMultiline Then
        ; $ES_WANTRETURN：否则回车会触发窗口默认按钮而不是换行，多行框无法手工输入换行
        $idInput = GUICtrlCreateEdit("", $iX + $iLabelW, $iY - 3, $iInputW, $iInputH, _
            BitOR($ES_MULTILINE, $ES_WANTRETURN, $ES_AUTOVSCROLL, $WS_VSCROLL))
    Else
        $idInput = GUICtrlCreateInput("", $iX + $iLabelW, $iY - 3, $iInputW, $iInputH)
    EndIf
    _StyleFieldInput($idInput)

    Return $idInput
EndFunc

; 统一创建 Metro 风格操作按钮
Func _CreateAppButton($sText, $iX, $iY, $iWidth, $iHeight, $iBgColor = $CLR_SURFACE, $iFontSize = 10)
    Local $iTextColor = $CLR_TEXT_PRIMARY
    Switch $iBgColor
        Case $CLR_PRIMARY, $CLR_SUCCESS, $CLR_ERROR, $CLR_WARNING, $CLR_INFO
            $iTextColor = $CLR_TEXT_ON_ACCENT
    EndSwitch

    Return _Metro_CreateButtonEx2($sText, $iX, $iY, $iWidth, $iHeight, $iBgColor, $iTextColor, _
        "Microsoft YaHei UI", $iFontSize, 0, $iBgColor)
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
    GUICtrlSetTip($g_idBtnOpen, "打开单个 NFO 文件")
    GUICtrlSetTip($g_idBtnSave, "保存当前文件（Ctrl+S）")
    GUICtrlSetTip($g_idBtnSaveAs, "将当前内容保存为新的 NFO 文件")
    GUICtrlSetTip($g_idBtnRefresh, "重新扫描当前目录")
    GUICtrlSetTip($g_idBtnSelectDir, "选择 NFO 文件目录，包含子目录")
    GUICtrlSetTip($g_idBtnPrev, "切换到上一个文件")
    GUICtrlSetTip($g_idBtnNext, "切换到下一个文件")
    GUICtrlSetTip($g_idFileSearch, "按文件名或相对路径实时筛选")
    GUICtrlSetTip($g_idCountryFilter, "按国家筛选文件")
    GUICtrlSetTip($g_idLanguageFilter, "按语言筛选文件")
    GUICtrlSetTip($g_idList, "双击或选择文件以加载 NFO")
    GUICtrlSetTip($g_idBtnAddActor, "添加演员信息")
    GUICtrlSetTip($g_idBtnRemoveActor, "删除选中的演员")
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

; ==================== 创建主窗口 ====================
Func _CreateMainGui()
    ; 主窗口采用固定画布，避免绝对坐标控件在缩放后留白或被裁切。
    $g_hMainGui = _Metro_CreateGUI("NFO编辑器", 1225, 700, -1, -1, False)
    _Metro_SetGUIOption($g_hMainGui, True, False)
    ; 窗口通体白底：不再为工具栏、左栏单独铺背景 Label，层级更少，
    ; 也避免任何 Label 覆盖右上角的窗口控制按钮。
    GUISetBkColor($CLR_CARD_BG, $g_hMainGui)

    ; 窗口标题：MetroGUI 是无边框窗口，拦截了 WM_NCCALCSIZE/WM_NCPAINT，
    ; 系统标题栏不会绘制，_Metro_CreateGUI 的标题只存在于窗口文本里（任务栏可见）。
    ; 因此标题必须像演员对话框那样自己画一个 Label 出来。
    Local $idAppTitle = GUICtrlCreateLabel("NFO编辑器", 12, 19, 112, 24)
    GUICtrlSetColor($idAppTitle, $CLR_TEXT_PRIMARY)
    GUICtrlSetBkColor($idAppTitle, $CLR_CARD_BG)
    GUICtrlSetFont($idAppTitle, 12, 700, 0, "Microsoft YaHei UI")

    ; ---- 顶部工具栏：4 个常用操作，始终可见 ----
    $g_idBtnOpen = _CreateAppButton("打开文件", 136, 13, 94, 36, $CLR_PRIMARY)
    $g_idBtnSave = _CreateAppButton("保存", 238, 13, 80, 36, $CLR_SUCCESS)
    $g_idBtnSaveAs = _CreateAppButton("另存为", 326, 13, 88, 36, $CLR_WARNING)
    $g_idBtnRefresh = _CreateAppButton("刷新", 422, 13, 78, 36, $CLR_INFO)

    ; 当前文件名：右上角两个窗口控制按钮占 1133 起的区域，此处留出余量
    $g_idCurrentFileLabel = GUICtrlCreateLabel("未打开文件", 664, 22, 456, 18)
    _StyleMutedLabel($g_idCurrentFileLabel)

    _Metro_AddHSeperator(0, 59, 1225, 1, $CLR_BORDER)

    ; 最小化与关闭按钮。窗口内没有任何控件覆盖该区域，因此始终可见。
    $g_aMetroControlButtons = _Metro_AddControlButtons(True, False, True, False, False, $CLR_CARD_BG, $CLR_TEXT_PRIMARY)

    ; ---- 左栏：搜索、筛选、导航、文件列表 ----
    Local $idSearchLbl = GUICtrlCreateLabel("搜索", 12, 74, 40, 22)
    _StyleFieldLabel($idSearchLbl)
    $g_idFileSearch = GUICtrlCreateInput("", 56, 71, 229, 25)
    _StyleFieldInput($g_idFileSearch)

    Local $idCountryLbl = GUICtrlCreateLabel("国家", 12, 106, 40, 22)
    _StyleFieldLabel($idCountryLbl)
    $g_idCountryFilter = GUICtrlCreateCombo("全部", 56, 103, 229, 25, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
    _StyleFieldInput($g_idCountryFilter)

    Local $idLangLbl = GUICtrlCreateLabel("语言", 12, 138, 40, 22)
    _StyleFieldLabel($idLangLbl)
    $g_idLanguageFilter = GUICtrlCreateCombo("全部", 56, 135, 229, 25, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
    _StyleFieldInput($g_idLanguageFilter)

    $g_idBtnSelectDir = _CreateAppButton("选择目录", 12, 168, 273, 28, $CLR_SURFACE)
    $g_idBtnPrev = _CreateAppButton("上一个", 12, 202, 132, 28, $CLR_SURFACE)
    $g_idBtnNext = _CreateAppButton("下一个", 153, 202, 132, 28, $CLR_SURFACE)

    $g_idDirLabel = GUICtrlCreateLabel("", 12, 238, 273, 18)
    _StyleMutedLabel($g_idDirLabel)
    _UpdateDirectoryLabel()

    $g_idFileCountLabel = GUICtrlCreateLabel("0 / 0 个文件", 12, 258, 273, 18)
    _StyleMutedLabel($g_idFileCountLabel)

    ; 全选/全不选与批量汉化：勾选范围即批量操作范围
    $g_idBtnCheckAll = _CreateAppButton("全选", 12, 282, 87, 26, $CLR_SURFACE)
    $g_idBtnCheckNone = _CreateAppButton("全不选", 105, 282, 87, 26, $CLR_SURFACE)
    $g_idBtnBatchLocalize = _CreateAppButton("批量汉化", 198, 282, 87, 26, $CLR_PRIMARY)

    ; 文件列表改用带复选框的 ListView：ListBox 无法承载勾选状态。
    ; 单列宽度略小于控件宽度，留出竖向滚动条的位置。
    $g_idList = GUICtrlCreateListView("文件", 12, 314, 273, 340, _
        BitOR($LVS_REPORT, $LVS_SINGLESEL, $LVS_SHOWSELALWAYS, $LVS_NOSORTHEADER), _
        BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT))
    _GUICtrlListView_SetColumnWidth($g_idList, 0, 248)
    _StyleFieldInput($g_idList)

    ; 左栏与右侧工作区之间只用一条细线分隔
    _Metro_AddVSeperator(295, 68, 586, 1, $CLR_BORDER)

    ; ---- 右侧标签页 ----
    $g_idTab = GUICtrlCreateTab(305, 65, 915, 595)
    GUICtrlSetBkColor($g_idTab, $CLR_CARD_BG)

    _CreateBasicInfoTab()
    _CreateActorsTab()
    _CreateMediaInfoTab()
    _CreateXmlTab()
    _CreateSettingsTab()

    GUICtrlCreateTabItem("")

    ; ---- 底部状态栏 ----
    _Metro_AddHSeperator(0, 665, 1225, 1, $CLR_BORDER)
    ; 恒定位置的状态指示灯：灰=就绪/已保存、橙=有未保存修改、红=失败，
    ; 颜色由 _SetAppStatus 的 $iDotColor 参数统一维护，不需要读文字判断状态。
    $g_idStatusDot = GUICtrlCreateLabel("", 12, 675, 10, 10)
    GUICtrlSetBkColor($g_idStatusDot, $CLR_STATUS_READY)
    $g_idStatusBar = GUICtrlCreateLabel("就绪", 30, 671, 1182, 20)
    _StyleMutedLabel($g_idStatusBar)

    ; ---- 创建演员对话框（隐藏） ----
    _CreateActorDialog()
    ; _Metro_CreateGUI 会把"当前 GUI"切到演员对话框，必须切回主窗口，
    ; 否则之后创建的 Dummy 控件会挂在对话框上，Ctrl+S 快捷键不生效。
    GUISwitch($g_hMainGui)

    _SetControlTips()
    _CacheEditControlHandles()
    $g_hFileList = GUICtrlGetHandle($g_idList)
    GUIRegisterMsg($WM_COMMAND, "_OnEditChange")
    GUIRegisterMsg($WM_NOTIFY, "_OnListViewNotify")
    _SetAppStatus("就绪", $CLR_STATUS_READY)

    ; 注册 Ctrl+S 快捷键
    $g_idAccelSave = GUICtrlCreateDummy()
    Local $aAccelKeys[1][2] = [["^s", $g_idAccelSave]]
    GUISetAccelerators($aAccelKeys, $g_hMainGui)

    GUISetState(@SW_SHOW, $g_hMainGui)
EndFunc

; ==================== 基本信息 Tab ====================
Func _CreateBasicInfoTab()
    GUICtrlCreateTabItem("基本信息")

    ; 不再铺任何面板背景：白底 + 浅灰输入框已足够区分层次，
    ; 分组靠小标题和留白表达。
    _CreateSectionLabel("标题", 320, 100)
    $g_aBasicFields[0][2] = _CreateLabeledInput(320, 126, $g_aBasicFields[0][0], 80, 795)
    $g_aBasicFields[1][2] = _CreateLabeledInput(320, 158, $g_aBasicFields[1][0], 80, 795)

    ; 左列：常用字段
    _CreateSectionLabel("常用字段", 320, 202)
    $g_aBasicFields[2][2] = _CreateLabeledInput(320, 228, $g_aBasicFields[2][0], 88, 310)
    $g_aBasicFields[3][2] = _CreateLabeledInput(320, 260, $g_aBasicFields[3][0], 88, 310)
    $g_aBasicFields[4][2] = _CreateLabeledInput(320, 292, $g_aBasicFields[4][0], 88, 310)
    $g_aBasicFields[5][2] = _CreateLabeledInput(320, 324, $g_aBasicFields[5][0], 88, 310)
    $g_aBasicFields[6][2] = _CreateLabeledInput(320, 356, $g_aBasicFields[6][0], 88, 310)
    $g_aBasicFields[7][2] = _CreateLabeledInput(320, 388, $g_aBasicFields[7][0], 88, 310)
    $g_aBasicFields[8][2] = _CreateLabeledInput(320, 420, $g_aBasicFields[8][0], 88, 310)
    $g_idSetName = _CreateLabeledInput(320, 452, "合集", 88, 310)
    $g_aBasicFields[9][2] = _CreateLabeledInput(320, 484, $g_aBasicFields[9][0], 88, 310)

    ; 右列：剧情简介与外部链接
    _CreateSectionLabel("剧情简介", 760, 202)
    $g_aBasicFields[12][2] = _CreateLabeledInput(760, 228, "", 0, 445, True, 170)
    _CreateSectionLabel("外部链接", 760, 420)
    $g_aBasicFields[10][2] = _CreateLabeledInput(760, 452, $g_aBasicFields[10][0], 80, 365)
    $g_aBasicFields[11][2] = _CreateLabeledInput(760, 484, $g_aBasicFields[11][0], 80, 365)

    ; 底部：分类信息（每行一个值）
    _CreateSectionLabel("分类信息（每行一项）", 320, 528)
    $g_idTagText = _CreateLabeledInput(320, 554, "标签", 88, 310, True, 88)
    $g_idGenreText = _CreateLabeledInput(760, 554, "类型", 80, 365, True, 88)
EndFunc

Func _CreateSectionLabel($sText, $iX, $iY)
    Local $idLabel = GUICtrlCreateLabel($sText, $iX, $iY, 400, 22)
    GUICtrlSetColor($idLabel, $CLR_PRIMARY)
    GUICtrlSetBkColor($idLabel, $CLR_CARD_BG)
    ; 11pt/700 对比字段标签的 10pt/400，靠字号加粗重差表达层级，不再只靠颜色
    GUICtrlSetFont($idLabel, 11, 700, 0, "Microsoft YaHei UI")
EndFunc

; ==================== 演员 Tab ====================
Func _CreateActorsTab()
    GUICtrlCreateTabItem("演员")

    $g_idBtnAddActor = _CreateAppButton("添加演员", 320, 100, 116, 32, $CLR_SUCCESS)
    $g_idBtnRemoveActor = _CreateAppButton("删除选中", 446, 100, 116, 32, $CLR_ERROR)

    ; 列宽与表格宽度对齐，优先为姓名和角色保留浏览空间。
    $g_idActorList = GUICtrlCreateListView("#|姓名|角色|类型|TMDB ID", 320, 142, 885, 502, _
        BitOR($LVS_REPORT, $LVS_SINGLESEL, $LVS_SHOWSELALWAYS), BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES))
    _GUICtrlListView_SetColumnWidth($g_idActorList, 0, 50)
    _GUICtrlListView_SetColumnWidth($g_idActorList, 1, 265)
    _GUICtrlListView_SetColumnWidth($g_idActorList, 2, 255)
    _GUICtrlListView_SetColumnWidth($g_idActorList, 3, 150)
    _GUICtrlListView_SetColumnWidth($g_idActorList, 4, 165)
    _StyleFieldInput($g_idActorList)
EndFunc

; ==================== 媒体信息 Tab ====================
Func _CreateMediaInfoTab()
    GUICtrlCreateTabItem("媒体信息")

    _CreateSectionLabel("视频", 320, 100)
    _CreateSectionLabel("音频", 760, 100)
    ; 两列之间只用一条细线分隔，不再铺面板背景
    _Metro_AddVSeperator(745, 100, 220, 1, $CLR_BORDER)

    ; 视频字段（两列、四行）
    For $i = 0 To 7
        Local $iColumn = Mod($i, 2)
        Local $iX = 320 + $iColumn * 205
        Local $iY = 132 + Int($i / 2) * 46
        $g_aVideoFields[$i][2] = _CreateLabeledInput($iX, $iY, $g_aVideoFields[$i][0], 130, 65)
    Next

    ; 音频字段（单列，保证语言与编码值可完整阅读）
    Local $sLangOptions = "zh|en|de|ru|ja|ko|und"
    For $i = 0 To 4
        Local $iY = 132 + $i * 38

        If $g_aAudioFields[$i][3] = 1 Then
            ; 语言 → ComboBox
            Local $idLabel = GUICtrlCreateLabel($g_aAudioFields[$i][0], 760, $iY, 135, 20)
            _StyleFieldLabel($idLabel)

            $g_aAudioFields[$i][2] = GUICtrlCreateCombo("", 895, $iY - 3, 270, 25, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
            GUICtrlSetData($g_aAudioFields[$i][2], $sLangOptions, "")
            _StyleFieldInput($g_aAudioFields[$i][2])
            ; ComboBox 发送 CBN_SELCHANGE 而非 EN_CHANGE，_OnEditChange 捕获不到，
            ; 记下控件 ID 以便主循环单独置脏。
            $g_idAudioLangCombo = $g_aAudioFields[$i][2]
        Else
            $g_aAudioFields[$i][2] = _CreateLabeledInput(760, $iY, $g_aAudioFields[$i][0], 135, 270)
        EndIf
    Next
EndFunc

; ==================== XML 源码 Tab ====================
Func _CreateXmlTab()
    GUICtrlCreateTabItem("XML 源码")

    $g_idBtnSync = _CreateAppButton("同步到表单", 320, 100, 130, 32, $CLR_SUCCESS)
    $g_idBtnRefreshXml = _CreateAppButton("刷新读取", 460, 100, 130, 32, $CLR_SURFACE)

    $g_idXmlText = GUICtrlCreateEdit("", 320, 142, 885, 502, _
        BitOR($ES_MULTILINE, $ES_WANTRETURN, $ES_AUTOVSCROLL, $ES_AUTOHSCROLL, $WS_VSCROLL, $WS_HSCROLL))
    GUICtrlSetBkColor($g_idXmlText, $CLR_SURFACE)
    GUICtrlSetColor($g_idXmlText, $CLR_TEXT_PRIMARY)
    GUICtrlSetFont($g_idXmlText, 10, 400, 0, "Consolas")
EndFunc

; ==================== 设置 Tab ====================
Func _CreateSettingsTab()
    GUICtrlCreateTabItem("设置")

    _CreateSectionLabel("DeepSeek API", 320, 100)
    $g_idSettingsApiUrl = _CreateLabeledInput(320, 128, "API URL", 90, 775)
    GUICtrlSetData($g_idSettingsApiUrl, $g_sDeepSeekApiUrl)
    GUICtrlSetTip($g_idSettingsApiUrl, "可填写 API 根地址、/v1 地址或完整的 /chat/completions 地址")

    Local $idKeyLabel = GUICtrlCreateLabel("API Key", 320, 162, 90, 20)
    _StyleFieldLabel($idKeyLabel)
    $g_idSettingsApiKey = GUICtrlCreateInput($g_sDeepSeekApiKey, 410, 159, 775, 28, $ES_PASSWORD)
    _StyleFieldInput($g_idSettingsApiKey)

    $g_idSettingsModel = _CreateLabeledInput(320, 196, "模型", 90, 300)
    GUICtrlSetData($g_idSettingsModel, $g_sDeepSeekModel)

    _CreateSectionLabel("汉化 Prompt（可用占位符 {title}、{plot}）", 320, 240)
    $g_idSettingsPrompt = GUICtrlCreateEdit($g_sLocalizePrompt, 320, 268, 865, 296, _
        BitOR($ES_MULTILINE, $ES_WANTRETURN, $ES_AUTOVSCROLL, $WS_VSCROLL))
    _StyleFieldInput($g_idSettingsPrompt)

    $g_idBtnSaveSettings = _CreateAppButton("保存设置", 320, 580, 120, 32, $CLR_SUCCESS)
    $g_idBtnResetPrompt = _CreateAppButton("恢复默认 Prompt", 450, 580, 160, 32, $CLR_SURFACE)
    $g_idBtnTestApi = _CreateAppButton("测试 API", 620, 580, 110, 32, $CLR_PRIMARY)
EndFunc

; 创建带标题栏的无边框子窗口（白底 + 标题 + 分隔线），返回窗口句柄
Func _CreateSubWindow($sWinTitle, $iW, $iH, $sLabel, $iSepW)
    Local $hWin = _Metro_CreateGUI($sWinTitle, $iW, $iH, -1, -1, False, $g_hMainGui)
    _Metro_SetGUIOption($hWin, True, False)
    GUISetBkColor($CLR_CARD_BG, $hWin)
    Local $idTitle = GUICtrlCreateLabel($sLabel, 20, 16, 400, 26)
    GUICtrlSetColor($idTitle, $CLR_TEXT_PRIMARY)
    GUICtrlSetBkColor($idTitle, $CLR_CARD_BG)
    GUICtrlSetFont($idTitle, 13, 700, 0, "Microsoft YaHei UI")
    _Metro_AddHSeperator(20, 50, $iSepW, 1, $CLR_BORDER)
    Return $hWin
EndFunc

; ==================== 演员对话框 ====================
Func _CreateActorDialog()
    $g_hActorDialog = _CreateSubWindow("添加演员", 500, 280, "添加演员", 460)

    Local $idNameLbl = GUICtrlCreateLabel("姓名", 20, 70, 80, 22)
    _StyleFieldLabel($idNameLbl)
    $g_idActorName = GUICtrlCreateInput("", 100, 67, 370, 28)
    _StyleFieldInput($g_idActorName)

    Local $idRoleLbl = GUICtrlCreateLabel("角色", 20, 106, 80, 22)
    _StyleFieldLabel($idRoleLbl)
    $g_idActorRole = GUICtrlCreateInput("", 100, 103, 370, 28)
    _StyleFieldInput($g_idActorRole)

    Local $idTypeLbl = GUICtrlCreateLabel("类型", 20, 142, 80, 22)
    _StyleFieldLabel($idTypeLbl)
    $g_idActorType = GUICtrlCreateInput("Actor", 100, 139, 370, 28)
    _StyleFieldInput($g_idActorType)

    Local $idTmdbLbl = GUICtrlCreateLabel("TMDB ID", 20, 178, 80, 22)
    _StyleFieldLabel($idTmdbLbl)
    $g_idActorTmdbId = GUICtrlCreateInput("", 100, 175, 370, 28)
    _StyleFieldInput($g_idActorTmdbId)

    $g_idActorOk = _CreateAppButton("确定", 258, 220, 100, 32, $CLR_PRIMARY)
    $g_idActorCancel = _CreateAppButton("取消", 370, 220, 100, 32, $CLR_SURFACE)

    $g_aActorDialogButtons = _Metro_AddControlButtons(True, False, False, False, False, $CLR_CARD_BG, $CLR_TEXT_PRIMARY)

    GUISetState(@SW_HIDE, $g_hActorDialog)
EndFunc

; ==================== 数据加载 ====================

; 把 |a|b|c 形式的去重集合转成排序后的 ComboBox 候选项字符串（首位固定“全部”）
Func _TokenSetToComboItems($sSet)
    Local $sItems = "全部"
    If StringLen($sSet) > 1 Then
        Local $aTokens = StringSplit(StringTrimRight(StringTrimLeft($sSet, 1), 1), "|")
        _ArraySort($aTokens, 0, 1)
        For $i = 1 To $aTokens[0]
            $sItems &= "|" & $aTokens[$i]
        Next
    EndIf
    Return $sItems
EndFunc

; 递归加载目录中的 .nfo 文件并提取元数据
Func _LoadDirectoryFiles()
    Local $aFiles = _ScanNfoFiles($g_sCurrentDir)

    Local $iFileTotal = UBound($aFiles)
    If $iFileTotal = 0 Then
        ReDim $g_aFileMetadata[1][4]
        $g_iFileCount = 0
    Else
        ReDim $g_aFileMetadata[$iFileTotal][4]
        $g_iFileCount = $iFileTotal
    EndIf

    ; 收集国家与语言选项
    Local $sCountries = "|"
    Local $sLangs = "|"

    For $i = 0 To $iFileTotal - 1
        Local $sFullPath = $aFiles[$i]
        Local $sRelative = StringReplace($sFullPath, $g_sCurrentDir & "\", "")

        Local $sCountry = ""
        Local $sFileLangs = ""
        _ExtractMetadata($sFullPath, $sCountry, $sFileLangs)

        $g_aFileMetadata[$i][0] = $sRelative
        $g_aFileMetadata[$i][1] = $sCountry
        $g_aFileMetadata[$i][2] = $sFileLangs
        $g_aFileMetadata[$i][3] = $sFullPath

        If $sCountry <> "" And StringInStr($sCountries, "|" & $sCountry & "|") = 0 Then
            $sCountries &= $sCountry & "|"
        EndIf

        If $sFileLangs <> "" Then
            Local $aSplit = StringSplit($sFileLangs, ",")
            For $j = 1 To $aSplit[0]
                Local $sLang = StringStripWS($aSplit[$j], 3)
                If $sLang <> "" And StringInStr($sLangs, "|" & $sLang & "|") = 0 Then
                    $sLangs &= $sLang & "|"
                EndIf
            Next
        EndIf
    Next

    If $g_iFileCount > 0 Then
        _ArraySort($g_aFileMetadata, 0, 0, 0, 0)
    EndIf

    GUICtrlSetData($g_idCountryFilter, _TokenSetToComboItems($sCountries), "全部")
    GUICtrlSetData($g_idLanguageFilter, _TokenSetToComboItems($sLangs), "全部")

    _ApplyFilters()

    If $iFileTotal > 0 Then
        _SetAppStatus("扫描完成，找到 " & $iFileTotal & " 个 NFO 文件（包含子目录）", $CLR_STATUS_READY)
    Else
        _SetAppStatus("当前目录未找到 NFO 文件", $CLR_STATUS_READY)
    EndIf
EndFunc

; 应用筛选条件更新文件列表
Func _ApplyFilters()
    Local $sCountryFilter = GUICtrlRead($g_idCountryFilter)
    Local $sLangFilter = GUICtrlRead($g_idLanguageFilter)
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
        Local $sCountry = $g_aFileMetadata[$i][1]
        Local $sLanguages = $g_aFileMetadata[$i][2]

        Local $bCountryMatch = ($sCountryFilter = "全部" Or $sCountry = $sCountryFilter)
        Local $bLangMatch = ($sLangFilter = "全部" Or _HasLanguageToken($sLanguages, $sLangFilter))
        Local $bSearchMatch = ($sSearch = "" Or StringInStr(StringLower($sRelPath), $sSearch) > 0)

        If $bCountryMatch And $bLangMatch And $bSearchMatch Then
            _GUICtrlListView_AddItem($g_idList, $sRelPath)
            If StringInStr($sChecked, "|" & $sRelPath & "|", 2) > 0 Then
                _GUICtrlListView_SetItemChecked($g_idList, $iDisplayed, True)
            EndIf
            $iDisplayed += 1
        EndIf
    Next
    _GUICtrlListView_EndUpdate($g_idList)

    _UpdateFileCountLabel($iDisplayed, $g_iFileCount)
    If $sCountryFilter = "全部" And $sLangFilter = "全部" And $sSearch = "" Then
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
            Local $sValue = _XmlGetText($oAudio, $g_aAudioFields[$i][1])
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

; ==================== 数据保存 ====================

; 先写同目录临时文件再原子替换目标，避免写入失败时先截断原文件。
; 返回 True 表示替换成功；失败时临时文件已清理。
Func _WriteFileAtomic($sFilePath, $sText, $iEncoding)
    Local $sTempPath = $sFilePath & ".nfo_editor_tmp_" & @AutoItPID & "_" & @MSEC
    Local $hFile = FileOpen($sTempPath, BitOR(2, $iEncoding))
    If $hFile = -1 Then Return False
    Local $iWritten = FileWrite($hFile, $sText)
    FileClose($hFile)
    If $iWritten = 0 Or Not FileExists($sTempPath) Or FileGetSize($sTempPath) = 0 Then
        FileDelete($sTempPath)
        Return False
    EndIf
    If Not FileMove($sTempPath, $sFilePath, 1) Then
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
    Local Const $iPreviewW = 1320
    Local Const $iPreviewH = 720
    Local Const $iColumnW = 405
    Local Const $iColumnGap = 15
    Local Const $iCandidateX = 20
    Local Const $iCandidateY = 86

    ReDim $aSelections[$iCount]
    For $i = 0 To $iCount - 1
        $aSelections[$i] = -1
    Next

    Local $hPreview = _Metro_CreateGUI("汉化结果预览", $iPreviewW, $iPreviewH, -1, -1, False, $g_hMainGui)
    _Metro_SetGUIOption($hPreview, True, False)
    GUISetBkColor($CLR_CARD_BG, $hPreview)

    Local $idTitle = GUICtrlCreateLabel("汉化结果预览", 20, 16, 400, 26)
    GUICtrlSetColor($idTitle, $CLR_TEXT_PRIMARY)
    GUICtrlSetBkColor($idTitle, $CLR_CARD_BG)
    GUICtrlSetFont($idTitle, 13, 700, 0, "Microsoft YaHei UI")
    _Metro_AddHSeperator(20, 50, $iPreviewW - 40, 1, $CLR_BORDER)

    Local $idFileLabel = GUICtrlCreateLabel("", 20, 60, $iPreviewW - 40, 20)
    _StyleMutedLabel($idFileLabel)

    Local $aChoiceButtons[3][2], $aTitleControls[3], $aPlotControls[3]
    For $i = 0 To 2
        Local $iX = $iCandidateX + $i * ($iColumnW + $iColumnGap)
        If $i < 2 Then
            Local $idSeparator = GUICtrlCreateLabel("", $iX + $iColumnW + 7, $iCandidateY, 1, 552)
            GUICtrlSetBkColor($idSeparator, $CLR_BORDER)
        EndIf

        $aChoiceButtons[$i][0] = _CreateAppButton("选择候选 " & ($i + 1), $iX, $iCandidateY, $iColumnW, 40, $CLR_SURFACE)
        $aChoiceButtons[$i][1] = _CreateAppButton("已选择候选 " & ($i + 1), $iX, $iCandidateY, $iColumnW, 40, $CLR_PRIMARY)
        GUICtrlSetTip($aChoiceButtons[$i][0], "选择这一列的汉化结果")
        GUICtrlSetTip($aChoiceButtons[$i][1], "当前已选择这一列的汉化结果")

        Local $idTitleLabel = GUICtrlCreateLabel("标题", $iX, 138, 80, 20)
        _StyleFieldLabel($idTitleLabel)
        $aTitleControls[$i] = GUICtrlCreateEdit("", $iX, 160, $iColumnW, 58, _
            BitOR($ES_MULTILINE, $ES_WANTRETURN, $ES_AUTOVSCROLL, $WS_VSCROLL))
        _StyleFieldInput($aTitleControls[$i])

        Local $idPlotLabel = GUICtrlCreateLabel("简介（中文 + 原文）", $iX, 226, 180, 20)
        _StyleFieldLabel($idPlotLabel)
        $aPlotControls[$i] = GUICtrlCreateEdit("", $iX, 248, $iColumnW, 370, _
            BitOR($ES_MULTILINE, $ES_WANTRETURN, $ES_AUTOVSCROLL, $WS_VSCROLL))
        _StyleFieldInput($aPlotControls[$i])
    Next

    Local $idPrevious = _CreateAppButton("上一个 NFO", 20, 650, 112, 32, $CLR_SURFACE)
    Local $idNext = _CreateAppButton("下一个 NFO", 144, 650, 112, 32, $CLR_SURFACE)
    Local $idSave = _CreateAppButton("保存所选结果", 1070, 650, 130, 32, $CLR_SUCCESS)
    Local $idCancel = _CreateAppButton("取消", 1212, 650, 88, 32, $CLR_SURFACE)
    GUICtrlSetTip($idSave, "确认所有 NFO 的候选后再写入文件")
    GUICtrlSetTip($idCancel, "取消本次批量汉化，不修改文件")

    Local $aWindowButtons = _Metro_AddControlButtons(True, False, False, False, False, $CLR_CARD_BG, $CLR_TEXT_PRIMARY)
    Local $iPage = 0
    Local $bSave = False
    _SetLocalizationPreviewPage($iPage, $iCount, $aRel, $aTitles, $aPlots, $aSelections, _
        $aChoiceButtons, $aTitleControls, $aPlotControls, $idFileLabel, $idPrevious, $idNext)

    GUISetState(@SW_SHOW, $hPreview)
    WinActivate($hPreview)

    While 1
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

    _Metro_GUIDelete($hPreview)
    Return $bSave
EndFunc

; ==================== 批量汉化 ====================

; 在 NFO 所在目录下创建备份文件夹，返回备份目录路径；失败返回 "" 并置 @error
Func _CreateBackupFolder($sBaseDir, $sStamp)
    Local $sBackupRoot = $sBaseDir & "\nfo_backup"
    If Not FileExists($sBackupRoot) And Not DirCreate($sBackupRoot) Then Return SetError(1, 0, "")

    Local $sBackupDir = $sBackupRoot & "\" & $sStamp
    If Not FileExists($sBackupDir) And Not DirCreate($sBackupDir) Then Return SetError(1, 0, "")
    Return $sBackupDir
EndFunc

; 批量处理期间禁止编辑和切换文件，避免异步任务结束时覆盖用户新输入。
Func _SetBatchEditingEnabled($bEnabled)
    Local $iState = $GUI_ENABLE
    If Not $bEnabled Then $iState = $GUI_DISABLE

    ; 主工具栏、文件列表、表单按钮与文本区
    Local $aControls[30] = [$g_idList, $g_idFileSearch, $g_idCountryFilter, $g_idLanguageFilter, _
        $g_idBtnOpen, $g_idBtnSave, $g_idBtnSaveAs, $g_idBtnRefresh, _
        $g_idBtnSelectDir, $g_idBtnPrev, $g_idBtnNext, $g_idBtnCheckAll, $g_idBtnCheckNone, _
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

        ; 3) 让出时间片处理窗口消息，避免界面假死；ESC 可中止后续任务
        If $bAnyActive Then Sleep(120)
        Local $aPump = GUIGetMsg(1)
        If $aPump[0] = $GUI_EVENT_CLOSE Or _
           (IsArray($g_aMetroControlButtons) And $aPump[0] = $g_aMetroControlButtons[$METRO_BTN_CLOSE]) Then
            ; 关闭请求：停止派发新任务，但已在飞的请求等其结束，避免半写状态
            If $iNext < $iTotal Then
                $iCancelled = $iTotal - $iNext
                $iNext = $iTotal
            EndIf
        EndIf
    WEnd

    If $iResultCount = 0 Then
        Local $sNoResultMsg = "批量汉化完成，但没有可供选择的候选结果。" & @CRLF & @CRLF & _
            "共 " & $iTotal & " 个文件" & @CRLF & _
            "跳过 " & $iSkip & " 个" & @CRLF & _
            "失败 " & $iFail & " 个"
        If $iCancelled > 0 Then $sNoResultMsg &= @CRLF & "已取消 " & $iCancelled & " 个（未处理）"
        If $sFailReport <> "" Then $sNoResultMsg &= @CRLF & @CRLF & "明细：" & StringLeft($sFailReport, 1500)
        If $iFail > 0 Then
            _SetAppStatus("批量汉化失败，未生成可选结果", $CLR_STATUS_ERROR)
            MsgBox(48, "批量汉化结果", $sNoResultMsg)
        Else
            _SetAppStatus("批量汉化完成，未生成可选结果", $CLR_STATUS_READY)
            MsgBox(64, "批量汉化结果", $sNoResultMsg)
        EndIf
        _SetBatchEditingEnabled(True)
        Return
    EndIf

    _SetAppStatus("候选生成完成，请逐个选择汉化结果", $CLR_STATUS_MODIFIED)
    Local $aSelections[$iResultCount]
    If Not _ShowBatchLocalizationPreview($aResultRel, $aResultTitles, $aResultPlots, $iResultCount, $aSelections) Then
        _SetAppStatus("已取消选择汉化结果，未修改任何文件", $CLR_STATUS_READY)
        _SetBatchEditingEnabled(True)
        Return
    EndIf

    ; 用户确认后才创建备份目录并写回，预览或取消阶段不会改变文件。
    Local $sStamp = @YEAR & @MON & @MDAY & "_" & @HOUR & @MIN & @SEC & "_" & @MSEC & "_" & @AutoItPID
    Local $sBackupRoot = ""
    For $i = 0 To $iResultCount - 1
        If $sBackupRoot = "" Then
            $sBackupRoot = _CreateBackupFolder($g_sCurrentDir, $sStamp)
            If @error Then
                MsgBox(16, "错误", "无法创建备份目录：" & @CRLF & $g_sCurrentDir & @CRLF & @CRLF & "已中止批量汉化，未修改任何文件。")
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
    If $sFailReport <> "" Then
        $sMsg &= @CRLF & @CRLF & "明细：" & StringLeft($sFailReport, 1500)
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
        For $i = 0 To _GUICtrlListView_GetItemCount($g_idList) - 1
            If $g_sCurrentFile <> "" And _GetRelPathFullPath(_GUICtrlListView_GetItemText($g_idList, $i, 0)) = $g_sCurrentFile Then
                _GUICtrlListView_SetItemSelected($g_idList, $i, True, True)
                ExitLoop
            EndIf
        Next
        Return
    EndIf

    Local $sFullPath = _GetRelPathFullPath($sSelected)
    If $sFullPath <> "" Then _LoadNfoFile($sFullPath)
EndFunc

; 由相对路径反查完整路径
Func _GetRelPathFullPath($sRelPath)
    For $i = 0 To $g_iFileCount - 1
        If $g_aFileMetadata[$i][0] = $sRelPath Then Return $g_aFileMetadata[$i][3]
    Next
    Return ""
EndFunc

; 获取当前选中文件在列表中的索引
Func _GetCurrentFileIndex()
    Local $iIndex = _GUICtrlListView_GetSelectedIndices($g_idList)
    If $iIndex = "" Then Return -1
    Return Number($iIndex)
EndFunc

; 选中列表中指定索引的项并加载
Func _SelectListIndex($iIndex)
    _GUICtrlListView_SetItemSelected($g_idList, $iIndex, True, True)
    _GUICtrlListView_EnsureVisible($g_idList, $iIndex)
    _OnFileSelect()
EndFunc

; 上/下一个文件（$iDelta = -1 上一个，1 下一个）
Func _OnPrevNextFile($iDelta)
    Local $iIndex = _GetCurrentFileIndex()
    Local $iCount = _GUICtrlListView_GetItemCount($g_idList)

    If $iIndex = -1 Then
        If $iCount > 0 Then _SelectListIndex(0)
        Return
    EndIf

    Local $iTarget = $iIndex + $iDelta
    If $iTarget < 0 Or $iTarget >= $iCount Then
        Local $sMsg = "已经是最后一个文件"
        If $iDelta < 0 Then $sMsg = "已经是第一个文件"
        MsgBox(64, "提示", $sMsg)
        Return
    EndIf
    _SelectListIndex($iTarget)
EndFunc

Func _OnPreviousFile()
    _OnPrevNextFile(-1)
EndFunc

Func _OnNextFile()
    _OnPrevNextFile(1)
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

; ==================== 主函数 ====================
Func Main()
    ; COM 错误处理器：需保持引用存活，Main 贯穿整个程序生命周期
    Local $oErrorHandler = ObjEvent("AutoIt.Error", "_ComErrorHandler")

    _LoadSettings()
    _SetTheme("LightGray")
    _CreateMainGui()
    _LoadDirectoryFiles()

    ; 主消息循环
    While 1
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

        Switch $aMsg[0]
            Case $GUI_EVENT_CLOSE
                If $aMsg[1] = $g_hActorDialog Then
                    _OnActorDialogCancel()
                ElseIf Not _ConfirmDiscardChanges() Then
                    ContinueLoop
                Else
                    Exit
                EndIf

            Case $g_aMetroControlButtons[$METRO_BTN_CLOSE]
                If Not _ConfirmDiscardChanges() Then ContinueLoop
                _Metro_GUIDelete($g_hMainGui)
                Exit
            Case $g_aMetroControlButtons[$METRO_BTN_MINIMIZE]
                GUISetState(@SW_MINIMIZE, $g_hMainGui)
            Case $g_aActorDialogButtons[0]
                _OnActorDialogCancel()

            ; 主窗口控件
            Case $g_idAccelSave
                _OnSaveFile()
            Case $g_idBtnOpen
                _OnOpenFile()
            Case $g_idBtnSave
                _OnSaveFile()
            Case $g_idBtnSaveAs
                _OnSaveFileAs()
            Case $g_idBtnRefresh
                _LoadDirectoryFiles()
            Case $g_idBtnSelectDir
                _OnSelectDirectory()
            Case $g_idBtnPrev
                _OnPreviousFile()
            Case $g_idBtnNext
                _OnNextFile()
            Case $g_idCountryFilter
                _ApplyFilters()
            Case $g_idLanguageFilter
                _ApplyFilters()
            Case $g_idBtnCheckAll
                _SetAllChecked(True)
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
    WEnd
EndFunc

; ==================== 启动 ====================
Main()
